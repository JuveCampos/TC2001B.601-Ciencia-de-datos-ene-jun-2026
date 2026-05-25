
options(scipen = 999)

# =============================================================================
# SESIÓN 16 — KNN, WORKFLOWS, VALIDACIÓN CRUZADA Y TUNING
# Ejercicio 1: Aprobación de crédito
# =============================================================================
#
# Objetivo: predecir si una solicitud de crédito será aprobada (si/no) a
# partir del perfil financiero y sociodemográfico del solicitante, usando
# k-vecinos más cercanos (KNN). En el camino aprenderemos a empaquetar el
# preprocesamiento y el modelo en un workflow(), a elegir el mejor número de
# vecinos con validación cruzada y a evaluar honestamente sobre la base de
# prueba.

# Librerías ----
# Agrupamos todas las cargas al inicio. kknn es el motor que parsnip usa
# por detrás para el modelo de vecinos más cercanos.
library(tidyverse)
library(tidymodels)
library(corrplot)
library(kknn)

tidymodels::tidymodels_prefer()

# =============================================================================
# 1. CARGA DE DATOS Y CONVERSIÓN DEL OBJETIVO A FACTOR
# =============================================================================
#
# Cargamos el CSV (ruta relativa: el script se corre desde su propia
# carpeta). Removemos el identificador id_solicitud porque NO es un
# predictor: es una etiqueta única por fila y solo metería ruido en el
# cálculo de distancias de KNN. Convertimos aprobado a factor desde el
# inicio: las funciones de clasificación de yardstick y parsnip
# (conf_mat, roc_curve, metric_set, etc.) requieren que el objetivo sea
# factor; si lo dejamos como texto, fallan.

creditos <- read_csv("datos.csv") %>%
  select(-id_solicitud) %>%
  mutate(aprobado = factor(aprobado))

# =============================================================================
# 2. EXPLORACIÓN MÍNIMA
# =============================================================================

# Proporción de clases del objetivo. Importa porque, si estuviera muy
# desbalanceada, el accuracy dejaría de ser una métrica confiable. Aquí está
# casi balanceada (~52% si / ~48% no).
creditos %>%
  group_by(aprobado) %>%
  count() %>%
  ungroup() %>%
  mutate(porcentaje = 100 * (n / sum(n)))

# Conteo de NAs por columna. Esto guía qué pasos de imputación necesitamos.
# Esperamos faltantes en ingreso_mensual_mxn (~5%) y score_historial (~4%).
creditos %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(),
               names_to = "variable",
               values_to = "n_na") %>%
  arrange(desc(n_na))

# Matriz de correlación de las variables numéricas para detectar
# colinealidad. Esperamos correlación alta entre monto_solicitado_mxn,
# pago_mensual_estimado_mxn y pct_deuda_ingreso, porque unas se derivan de
# otras. Si dos variables miden casi lo mismo, en KNN esa información pesaría
# doble en la distancia: por eso más adelante la filtramos con step_corr().
matriz_correlacion <- creditos %>%
  select(where(is.numeric)) %>%
  drop_na() %>%
  cor() %>%
  round(2)

matriz_correlacion %>%
  corrplot(method = "circle", addCoef.col = "black")

# =============================================================================
# 3. PARTICIÓN ENTRENAMIENTO / PRUEBA (ESTRATIFICADA)
# =============================================================================
#
# Separamos los datos en entrenamiento (75%) y prueba (25%). Estratificamos
# por aprobado para que ambas particiones conserven la misma proporción de
# clases que el total. La base de prueba se "guarda en una caja fuerte": solo
# la tocamos al final, para una evaluación honesta del modelo ya elegido.

set.seed(2026)
creditos_split <- initial_split(data = creditos,
                                prop = 0.75,
                                strata = aprobado)

creditos_entrenamiento <- creditos_split %>% training()
creditos_prueba        <- creditos_split %>% testing()

# Verificamos que la estratificación preservó las proporciones.
table(creditos_entrenamiento$aprobado) %>% prop.table()
table(creditos_prueba$aprobado) %>% prop.table()

# =============================================================================
# 4. RECETA DE FEATURE ENGINEERING
# =============================================================================
#
# El ORDEN de los pasos importa. Imputamos PRIMERO porque los pasos
# posteriores (step_corr, step_normalize) no toleran NAs. Luego limpiamos
# variables sin información, filtramos colinealidad y normalizamos (clave
# para KNN). Todos los predictores son numéricos, así que no hace falta
# codificar categóricas.
#
#   (1) step_impute_median: rellena los NAs numéricos con la mediana
#       (robusta a valores extremos como ingresos muy altos).
#   (2) step_nzv: elimina predictores con varianza casi nula (casi
#       constantes), que no ayudan a discriminar.
#   (3) step_corr: descarta predictores numéricos redundantes por
#       colinealidad (umbral 0.7), para que la información no pese doble en
#       la distancia.
#   (4) step_normalize: estandariza (media 0, desviación 1) los predictores
#       numéricos. ES EL PASO CRÍTICO PARA KNN: sin él, una variable como
#       monto_solicitado_mxn (en miles de pesos) aplastaría a otras como
#       num_creditos_activos en el cálculo de distancias.
#   (5) step_zv: por seguridad, elimina cualquier variable que quedara con
#       varianza cero tras los pasos anteriores.

receta_creditos <- recipe(aprobado ~ ., data = creditos_entrenamiento) %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_corr(all_numeric_predictors(), threshold = 0.7) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_zv(all_predictors())

# Inspección opcional: preparamos la receta y "horneamos" el entrenamiento
# solo para ver cómo quedaron las variables tras el preprocesamiento.
receta_creditos %>%
  prep(training = creditos_entrenamiento) %>%
  bake(new_data = NULL) %>%
  glimpse()

# =============================================================================
# 5. WORKFLOW + MODELO KNN CON k FIJO (ARBITRARIO)
# =============================================================================
#
# ¿Qué es un workflow?
# Un workflow empaqueta en un solo objeto la receta de preprocesamiento y la
# especificación del modelo. Su ventaja: fit() hace internamente prep+bake
# +fit, y predict() aplica el mismo preprocesamiento a los datos nuevos sin
# que tengamos que recordar el bake() manual. Es la pieza estándar para
# tuning y validación cruzada.
#
# ¿Qué es KNN?
# Es un modelo basado en distancias: para clasificar una observación nueva,
# busca las k observaciones más parecidas de la base de entrenamiento y vota
# la clase mayoritaria entre esas k vecinas. No "aprende" parámetros como una
# regresión; memoriza el entrenamiento (es un modelo "perezoso"). El número
# de vecinos k gobierna el equilibrio sesgo-varianza:
#   - k pequeño  => frontera muy flexible, baja sesgo pero alta varianza
#                   (puede sobreajustar al ruido).
#   - k grande   => frontera muy suave, alto sesgo pero baja varianza
#                   (puede subajustar).
#
# Aquí fijamos k = 7 "a ojo", solo para tener un punto de partida. En la
# sección siguiente lo elegiremos con datos.

# weight_func = "rectangular": usamos KNN de VOTO MAYORITARIO no ponderado
# (los k vecinos pesan igual). Es la versión clásica de KNN y deja ver con
# claridad el equilibrio sesgo-varianza: con k muy grande la frontera se
# aplana y el modelo subajusta. El motor kknn por defecto pondera por
# distancia (los vecinos lejanos pesan poco), lo que disimularía ese
# subajuste y haría que "más k" casi nunca empeore.
modelo_knn_fijo <- nearest_neighbor(neighbors = 7,
                                    weight_func = "rectangular") %>%
  set_engine("kknn") %>%
  set_mode("classification")

workflow_knn_fijo <- workflow() %>%
  add_recipe(receta_creditos) %>%
  add_model(modelo_knn_fijo)

# Ajustamos el workflow sobre el entrenamiento (SIN bake manual).
workflow_knn_fijo_fit <- workflow_knn_fijo %>%
  fit(data = creditos_entrenamiento)

# Predecimos sobre la prueba (el workflow aplica el preprocesamiento solo).
predicciones_knn_fijo <- creditos_prueba %>%
  select(aprobado) %>%
  bind_cols(predict(workflow_knn_fijo_fit, creditos_prueba, type = "class")) %>%
  bind_cols(predict(workflow_knn_fijo_fit, creditos_prueba, type = "prob"))

# Métricas de referencia con k = 7.
metricas_clasificacion <- metric_set(accuracy, sensitivity, yardstick::spec)
metricas_clasificacion(predicciones_knn_fijo,
                       truth = aprobado,
                       estimate = .pred_class)

roc_auc(predicciones_knn_fijo, truth = aprobado, .pred_no)

# =============================================================================
# 6. TUNING DE k CON VALIDACIÓN CRUZADA
# =============================================================================
#
# k es un HIPERPARÁMETRO: no se aprende de los datos durante el
# entrenamiento, lo fija el analista antes. Elegirlo "a ojo" (como el k = 7
# de arriba) es arbitrario. Lo correcto es probar varios valores y quedarnos
# con el que mejor desempeño estimado da.
#
# NO podemos usar la base de prueba para elegir k: si la usáramos, dejaría de
# ser una evaluación honesta. La solución es validación cruzada SOLO sobre el
# entrenamiento.
#
# ¿Qué es un fold y qué pasa en cada iteración de la CV?
# Partimos el entrenamiento en v "folds" (porciones) del mismo tamaño. En
# cada iteración: usamos v-1 folds para entrenar y el fold restante para
# validar; rotamos cuál fold se deja fuera, de modo que cada porción sirve
# de validación exactamente una vez. Promediamos la métrica de validación a
# lo largo de los v folds. Repetimos todo para cada k candidato y elegimos el
# k con mejor promedio. Esto aprovecha todo el entrenamiento sin tocar la
# prueba.

# 6.1 Modelo KNN dejando neighbors como tune() (a determinar). Mantenemos
# weight_func = "rectangular" para que el tuning revele el k intermedio
# óptimo (con voto ponderado el AUC casi no bajaría al crecer k).
modelo_knn_tune <- nearest_neighbor(neighbors = tune(),
                                    weight_func = "rectangular") %>%
  set_engine("kknn") %>%
  set_mode("classification")

workflow_knn_tune <- workflow() %>%
  add_recipe(receta_creditos) %>%
  add_model(modelo_knn_tune)

# 6.2 Folds de validación cruzada estratificada (v = 5) sobre el
# entrenamiento. set.seed() para que la partición en folds sea reproducible.
set.seed(2026)
folds_cv <- vfold_cv(data = creditos_entrenamiento,
                     v = 5,
                     strata = aprobado)

# 6.3 Grilla de valores candidatos de k. Usamos grid_regular() sobre el
# parámetro neighbors(): genera una cuadrícula uniforme dentro de un rango.
# Probamos varios k para ver toda la curva sesgo-varianza.
# Regla práctica: si el mejor k cae justo en el borde de la grilla, conviene
# ampliarla, porque podría existir un k mejor más allá del rango probado.
grilla_k <- grid_regular(neighbors(range = c(1, 101)),
                         levels = 12)

# 6.4 Métricas a vigilar durante el tuning. roc_auc es la métrica principal
# (no depende de un umbral fijo); accuracy, sensibilidad y especificidad la
# complementan.
metricas_tuning <- metric_set(roc_auc, accuracy, sensitivity, yardstick::spec)

# 6.5 Ejecutar el tuning: para cada k de la grilla, corre la CV de 5 folds.
set.seed(2026)
resultados_tuning <- workflow_knn_tune %>%
  tune_grid(resamples = folds_cv,
            grid = grilla_k,
            metrics = metricas_tuning)

# 6.6 Inspeccionar los resultados promediados por k.
collect_metrics(resultados_tuning)

# Gráfica de AUC promedio vs k (con barras de error ±1 error estándar).
# Buscamos el k donde el AUC se estabiliza en su valor más alto.
resultados_tuning %>%
  collect_metrics() %>%
  filter(.metric == "roc_auc") %>%
  ggplot(aes(x = neighbors, y = mean)) +
  geom_line() +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean - std_err, ymax = mean + std_err),
                width = 1.5) +
  labs(title = "AUC promedio por valor de k (validación cruzada 5-fold)",
       x = "k (número de vecinos)",
       y = "AUC promedio") +
  theme_minimal()

# 6.7 Elegir el mejor k según AUC.
mejor_k <- resultados_tuning %>% select_best(metric = "roc_auc")
mejor_k

# =============================================================================
# 7. EVALUACIÓN FINAL CON last_fit()
# =============================================================================
#
# Finalizamos el workflow inyectando el k ganador con finalize_workflow().
# Luego usamos last_fit(), que en un solo paso: reentrena el modelo final
# sobre TODO el entrenamiento y lo evalúa sobre la base de prueba que habíamos
# reservado. Así obtenemos la estimación honesta del desempeño en datos no
# vistos.

workflow_knn_final <- workflow_knn_tune %>%
  finalize_workflow(mejor_k)

ajuste_final <- workflow_knn_final %>%
  last_fit(split = creditos_split,
           metrics = metricas_tuning)

# 7.1 Métricas finales sobre la prueba (incluye AUC y accuracy).
collect_metrics(ajuste_final)

# 7.2 Predicciones finales sobre la prueba.
predicciones_finales <- collect_predictions(ajuste_final)
predicciones_finales

# 7.3 Matriz de confusión final.
conf_mat(predicciones_finales,
         truth = aprobado,
         estimate = .pred_class) %>%
  autoplot(type = "heatmap") +
  labs(title = paste0("Matriz de confusión - KNN final (k = ",
                      mejor_k$neighbors, ")")) +
  theme_minimal()

# 7.4 Curva ROC y AUC final.
predicciones_finales %>%
  roc_curve(truth = aprobado, .pred_no) %>%
  autoplot() +
  labs(title = paste0("Curva ROC - KNN final (k = ", mejor_k$neighbors, ")"))

roc_auc(predicciones_finales, truth = aprobado, .pred_no)

# Interpretación:
# - El AUC final resume la capacidad del modelo de ordenar correctamente
#   aprobados vs rechazados (0.5 = azar; 1 = perfecto). Como las clases están
#   casi balanceadas, el accuracy también es informativo aquí.
# - Si el k óptimo elegido por CV difiere de 7, queda claro el valor de
#   tunear: el k arbitrario era subóptimo. El último paso (last_fit) garantiza
#   que esta cifra se midió en datos que el modelo nunca vio durante el
#   entrenamiento ni durante la selección de k.
# - Observa la curva de AUC vs k: el desempeño sube al pasar de k muy chico
#   (que sobreajusta al ruido) hacia un k intermedio, y vuelve a bajar con k
#   muy grande (que subajusta al promediar vecinos de más). Ese máximo
#   intermedio es justo el equilibrio sesgo-varianza que buscábamos, y por eso
#   el k óptimo queda dentro de la grilla, no en sus extremos.
