
options(scipen = 999)

# =============================================================================
# SESIÓN 16 — KNN, WORKFLOWS, VALIDACIÓN CRUZADA Y TUNING
# Ejercicio 2: Potabilidad del agua
# =============================================================================
#
# Objetivo: a partir de parámetros fisicoquímicos de muestras de agua (pH,
# dureza, sólidos disueltos, sulfatos, etc.), predecir si una muestra es apta
# para consumo humano (potable si/no). Usaremos k-vecinos más cercanos (KNN)
# dentro de un workflow, elegiremos el número de vecinos con validación
# cruzada y mediremos el desempeño final en una base de prueba reservada.
#
# Este problema es un caso de libro para subrayar POR QUÉ KNN necesita
# normalización: todas las variables son numéricas pero viven en escalas
# muy distintas (pH va de 0 a 14, mientras que los sólidos disueltos llegan a
# decenas de miles de ppm).

# Librerías ----
library(tidyverse)
library(tidymodels)
library(corrplot)
library(kknn)

tidymodels::tidymodels_prefer()

# =============================================================================
# 1. CARGA DE DATOS Y CONVERSIÓN DEL OBJETIVO A FACTOR
# =============================================================================
#
# Leemos el CSV con read_csv (ruta relativa; el script vive en su carpeta).
# Este dataset no tiene columna identificadora, así que no removemos nada.
# Pasamos potable a factor de inmediato: yardstick y parsnip exigen que el
# objetivo de clasificación sea factor (de lo contrario conf_mat, roc_curve,
# metric_set, etc. fallan).

agua <- read_csv("datos.csv") %>%
  mutate(potable = factor(potable))

# =============================================================================
# 2. EXPLORACIÓN MÍNIMA
# =============================================================================

# Proporción de clases. Revisar esto siempre: si una clase fuera muy rara, el
# accuracy engañaría. Aquí está casi balanceado, con leve mayoría de muestras
# no potables (~55% no / ~45% si).
agua %>%
  group_by(potable) %>%
  count() %>%
  ungroup() %>%
  mutate(porcentaje = 100 * (n / sum(n)))

# NAs por columna: necesitamos saber dónde imputar. Aquí los faltantes se
# concentran en ph (~3%) y sulfatos_mg_l (~6%).
agua %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(),
               names_to = "variable",
               values_to = "n_na") %>%
  arrange(desc(n_na))

# Matriz de correlación. Como todo es numérico, esta inspección es directa.
# Atención a conductividad_us_cm y solidos_disueltos_ppm: ambas reflejan la
# carga iónica del agua, así que esperamos correlación alta. Dejar las dos
# haría que esa información cuente doble en la distancia de KNN; por eso la
# receta usará step_corr() para descartar una.
matriz_correlacion <- agua %>%
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
# Reservamos 25% de las muestras para prueba y entrenamos con el 75%
# restante. Estratificamos por potable para que la mezcla de clases sea la
# misma en ambas particiones. La prueba no se vuelve a tocar hasta el final.

set.seed(2026)
agua_split <- initial_split(data = agua,
                            prop = 0.75,
                            strata = potable)

agua_entrenamiento <- agua_split %>% training()
agua_prueba        <- agua_split %>% testing()

# Confirmamos que las proporciones se mantuvieron tras estratificar.
table(agua_entrenamiento$potable) %>% prop.table()
table(agua_prueba$potable) %>% prop.table()

# =============================================================================
# 4. RECETA DE FEATURE ENGINEERING
# =============================================================================
#
# Igual que siempre, el orden de los pasos no es opcional. Se imputa primero
# porque los pasos que siguen no aceptan NAs; después se limpia, se filtra
# colinealidad y se normaliza.
#
#   (1) step_impute_median: tapa los faltantes de ph y sulfatos_mg_l con la
#       mediana de cada variable (robusta a valores atípicos).
#   (2) step_nzv: quita predictores con varianza casi nula (sin poder
#       discriminante).
#   (3) step_corr: descarta uno de los predictores muy correlacionados
#       (umbral 0.7); aquí debería eliminar conductividad o sólidos disueltos.
#   (4) step_normalize: estandariza todos los predictores a media 0 y
#       desviación 1. EN ESTE EJERCICIO ES EL PASO DECISIVO: sin normalizar,
#       solidos_disueltos_ppm (en miles) y conductividad (en cientos)
#       dominarían el cálculo de distancia y el pH o la turbidez (de un solo
#       dígito) prácticamente no contarían. Normalizar pone a todas las
#       variables en igualdad de condiciones.
#
# Como todos los predictores son numéricos, no hace falta step_unknown ni
# step_dummy (no hay categóricas). Añadimos step_zv() como salvaguarda por si
# algún predictor quedara constante tras los pasos previos.

receta_agua <- recipe(potable ~ ., data = agua_entrenamiento) %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_corr(all_numeric_predictors(), threshold = 0.7) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_zv(all_predictors())

# Inspección opcional: vemos el resultado del preprocesamiento. Nótese que
# tras step_normalize todas las columnas quedan en la misma escala.
receta_agua %>%
  prep(training = agua_entrenamiento) %>%
  bake(new_data = NULL) %>%
  glimpse()

# =============================================================================
# 5. WORKFLOW + MODELO KNN CON k FIJO (ARBITRARIO)
# =============================================================================
#
# El workflow() une receta y modelo en un solo objeto. Al ajustarlo con
# fit(), corre prep+bake+fit por dentro; al predecir, aplica exactamente el
# mismo preprocesamiento a los datos nuevos. Esto evita el error clásico de
# olvidar transformar la base de prueba antes de predecir.
#
# Recordatorio de cómo funciona KNN: para clasificar una muestra de agua
# nueva, calcula su distancia a todas las muestras de entrenamiento, se queda
# con las k más cercanas y vota la clase mayoritaria entre ellas. No estima
# coeficientes: simplemente recuerda los datos (modelo "perezoso"). El número
# de vecinos k controla el equilibrio sesgo-varianza:
#   - k chico => frontera de decisión muy detallada, propensa a sobreajustar.
#   - k grande => frontera muy lisa, propensa a subajustar.
#
# Empezamos con k = 9 elegido arbitrariamente, solo como referencia.
#
# weight_func = "rectangular": KNN de VOTO MAYORITARIO no ponderado (los k
# vecinos pesan igual). Es la versión clásica y deja ver el equilibrio
# sesgo-varianza: con k muy grande la frontera se aplana y subajusta. El
# motor kknn por defecto pondera por distancia, lo que ocultaría ese efecto.
modelo_knn_fijo <- nearest_neighbor(neighbors = 9,
                                    weight_func = "rectangular") %>%
  set_engine("kknn") %>%
  set_mode("classification")

workflow_knn_fijo <- workflow() %>%
  add_recipe(receta_agua) %>%
  add_model(modelo_knn_fijo)

workflow_knn_fijo_fit <- workflow_knn_fijo %>%
  fit(data = agua_entrenamiento)

# Predicción sobre la prueba (clase y probabilidades) usando el workflow.
predicciones_knn_fijo <- agua_prueba %>%
  select(potable) %>%
  bind_cols(predict(workflow_knn_fijo_fit, agua_prueba, type = "class")) %>%
  bind_cols(predict(workflow_knn_fijo_fit, agua_prueba, type = "prob"))

# Métricas de referencia con k = 9.
metricas_clasificacion <- metric_set(accuracy, sensitivity, yardstick::spec)
metricas_clasificacion(predicciones_knn_fijo,
                       truth = potable,
                       estimate = .pred_class)

roc_auc(predicciones_knn_fijo, truth = potable, .pred_no)

# =============================================================================
# 6. TUNING DE k CON VALIDACIÓN CRUZADA
# =============================================================================
#
# El k que usamos arriba fue una corazonada. k es un hiperparámetro: el
# modelo no lo aprende solo, lo decidimos nosotros antes de entrenar. Para
# elegirlo bien probamos varios valores y nos quedamos con el de mejor
# desempeño estimado, pero SIN mirar la base de prueba (si la usáramos para
# elegir, se contaminaría y dejaría de ser un examen limpio).
#
# La herramienta es la validación cruzada sobre el entrenamiento. Un "fold"
# es una de las v porciones en que dividimos el entrenamiento. En cada
# iteración de la CV se aparta un fold como validación, se entrena con los
# v-1 restantes y se mide la métrica en el fold apartado; se rota hasta que
# cada fold haya sido validación una vez, y se promedian las v mediciones.
# Ese promedio (calculado para cada k candidato) es lo que comparamos.

# 6.1 Modelo KNN con neighbors a determinar (tune()). Mantenemos
# weight_func = "rectangular" para que el tuning muestre un k intermedio
# óptimo y la caída del AUC cuando k crece demasiado.
modelo_knn_tune <- nearest_neighbor(neighbors = tune(),
                                    weight_func = "rectangular") %>%
  set_engine("kknn") %>%
  set_mode("classification")

workflow_knn_tune <- workflow() %>%
  add_recipe(receta_agua) %>%
  add_model(modelo_knn_tune)

# 6.2 Cinco folds estratificados por potable, sobre el entrenamiento. El
# set.seed hace reproducible la división en folds.
set.seed(2026)
folds_cv <- vfold_cv(data = agua_entrenamiento,
                     v = 5,
                     strata = potable)

# 6.3 Grilla de candidatos de k. grid_regular() construye una cuadrícula
# uniforme dentro del rango indicado para neighbors(). Exploramos hasta k
# moderadamente grande para ver toda la curva sesgo-varianza y asegurarnos de
# que el óptimo no quede pegado al borde de la grilla.
grilla_k <- grid_regular(neighbors(range = c(1, 101)),
                         levels = 12)

# 6.4 Conjunto de métricas a observar en el tuning. roc_auc es la guía
# principal porque no depende de un umbral de corte; el resto la matiza.
metricas_tuning <- metric_set(roc_auc, accuracy, sensitivity, yardstick::spec)

# 6.5 Corremos el tuning: cada k se evalúa con la CV de 5 folds.
set.seed(2026)
resultados_tuning <- workflow_knn_tune %>%
  tune_grid(resamples = folds_cv,
            grid = grilla_k,
            metrics = metricas_tuning)

# 6.6 Resultados promediados por k.
collect_metrics(resultados_tuning)

# Gráfica AUC vs k. La leemos buscando dónde el AUC alcanza su máximo y se
# aplana: ese suele ser un buen k (ni tan chico que sobreajuste, ni tan
# grande que subajuste).
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

# 6.7 Seleccionamos el k con mejor AUC promedio.
# Recordatorio: si el k ganador queda en el extremo de la grilla, conviene
# ampliar el rango y volver a tunear, porque podría haber un k mejor afuera.
mejor_k <- resultados_tuning %>% select_best(metric = "roc_auc")
mejor_k

# =============================================================================
# 7. EVALUACIÓN FINAL CON last_fit()
# =============================================================================
#
# finalize_workflow() fija el k ganador en el workflow. Después last_fit()
# hace, de un solo golpe, dos cosas: reentrena el modelo con ese k usando
# TODO el entrenamiento y lo evalúa sobre la prueba reservada. Es la
# estimación honesta del desempeño en datos que el modelo nunca vio.

workflow_knn_final <- workflow_knn_tune %>%
  finalize_workflow(mejor_k)

ajuste_final <- workflow_knn_final %>%
  last_fit(split = agua_split,
           metrics = metricas_tuning)

# 7.1 Métricas finales sobre la prueba.
collect_metrics(ajuste_final)

# 7.2 Predicciones finales sobre la prueba.
predicciones_finales <- collect_predictions(ajuste_final)
predicciones_finales

# 7.3 Matriz de confusión final.
conf_mat(predicciones_finales,
         truth = potable,
         estimate = .pred_class) %>%
  autoplot(type = "heatmap") +
  labs(title = paste0("Matriz de confusión - KNN final (k = ",
                      mejor_k$neighbors, ")")) +
  theme_minimal()

# 7.4 Curva ROC y AUC final.
predicciones_finales %>%
  roc_curve(truth = potable, .pred_no) %>%
  autoplot() +
  labs(title = paste0("Curva ROC - KNN final (k = ", mejor_k$neighbors, ")"))

roc_auc(predicciones_finales, truth = potable, .pred_no)

# Interpretación:
# - El AUC final mide qué tan bien el modelo separa muestras potables de no
#   potables (0.5 sería como tirar una moneda). En un problema real de calidad
#   del agua nos interesaría especialmente la sensibilidad/especificidad según
#   qué error sea más costoso: clasificar como potable algo que no lo es es
#   peligroso, así que vigilaríamos de cerca esa tasa de falsos potables.
# - Si el k óptimo de la CV es distinto del 9 inicial, confirmamos que vale la
#   pena tunear en vez de adivinar. Y como normalizamos en la receta, el KNN
#   pudo aprovechar todas las variables y no solo las de mayor magnitud.
