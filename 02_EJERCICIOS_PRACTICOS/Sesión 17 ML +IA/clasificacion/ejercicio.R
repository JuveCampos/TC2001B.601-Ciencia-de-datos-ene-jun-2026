
options(scipen = 999)

# =============================================================================
# Sesión 17 — ML + IA
# Solución de referencia: CLASIFICACIÓN binaria
# Problema: predecir si una póliza de seguro de vida será aprobada.
# Modelo: KNN con el número de vecinos (k) tuneado por validación cruzada.
# =============================================================================

# Librerías (todas al inicio) ------------------------------------------------
library(tidyverse)
library(tidymodels)
library(kknn)            # motor para el modelo KNN

tidymodels::tidymodels_prefer()

# -----------------------------------------------------------------------------
# 1. Cargar los datos
# -----------------------------------------------------------------------------
# Convertimos la variable objetivo (aprobada) a factor desde el inicio:
# yardstick (métricas, matriz de confusión, ROC) y parsnip en modo
# clasificación REQUIEREN que la y sea factor. Si la dejamos como texto,
# conf_mat(), roc_curve(), metric_set(), etc. fallan.
# También removemos id_solicitante: es un identificador, no un predictor;
# dejarlo podría inducir fuga de información (data leakage).
seguros <- read_csv("datos.csv") %>%
  select(-id_solicitante) %>%
  mutate(aprobada = factor(aprobada))

# -----------------------------------------------------------------------------
# 2. Explorar la variable objetivo: ¿qué tan balanceadas están las clases?
# -----------------------------------------------------------------------------
# Saber el balance importa porque el accuracy puede engañar cuando una clase
# domina. Aquí están razonablemente parejas (~54% sí / 46% no).
seguros %>%
  group_by(aprobada) %>%
  count() %>%
  ungroup() %>%
  mutate(porcentaje = 100 * (n / sum(n)))

# -----------------------------------------------------------------------------
# 3. Revisar valores faltantes (NAs) por columna
# -----------------------------------------------------------------------------
# summary() muestra los NAs al final de cada variable numérica.
# Esperamos ~44 NAs en colesterol_mg_dl (~5%). Los imputaremos en la receta.
summary(seguros)

# -----------------------------------------------------------------------------
# 4. Inspeccionar colinealidad entre variables numéricas
# -----------------------------------------------------------------------------
# Colinealidad alta entre predictores puede inflar varianza y dificultar la
# interpretación. Aquí esperamos correlación moderada de presion_sistolica
# y colesterol_mg_dl con la edad. drop_na() es solo para poder calcular la
# correlación (no modifica la base original).
matriz_correlacion <- seguros %>%
  select(where(is.numeric)) %>%
  drop_na() %>%
  cor() %>%
  round(2)

matriz_correlacion

# -----------------------------------------------------------------------------
# 5. Partición entrenamiento / prueba, estratificada por la objetivo
# -----------------------------------------------------------------------------
# Estratificamos por aprobada para que la proporción de clases se conserve
# en ambas particiones. set.seed() hace reproducible la partición aleatoria.
set.seed(123)
seguros_split <- initial_split(data = seguros, prop = 0.75,
                               strata = aprobada)

seguros_entrenamiento <- seguros_split %>% training()
seguros_prueba        <- seguros_split %>% testing()

# Verificamos que la proporción de clases se mantuvo en cada partición.
table(seguros_entrenamiento$aprobada) %>% prop.table()
table(seguros_prueba$aprobada) %>% prop.table()

# -----------------------------------------------------------------------------
# 6. Receta de preprocesamiento (feature engineering)
# -----------------------------------------------------------------------------
# El orden de los pasos importa:
#   (1) Imputar primero: los pasos posteriores no toleran NAs.
#   (2) step_unknown(): convierte cualquier NA categórico en un nivel
#       explícito "unknown" ANTES de crear dummies (evita que el modelo
#       descarte filas al predecir).
#   (3) step_nzv(): quita predictores con varianza casi nula (poco útiles).
#   (4) step_corr(): filtra predictores numéricos demasiado correlacionados
#       (umbral 0.7) para reducir colinealidad.
#   (5) step_normalize(): z-score sobre numéricos. INDISPENSABLE para KNN,
#       que se basa en distancias y es sensible a la escala.
#   (6) step_dummy(): codifica las categóricas como variables binarias.
#   (7) step_zv(): elimina columnas dummy que quedaron constantes.
receta_seguros <- recipe(aprobada ~ ., data = seguros_entrenamiento) %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_unknown(all_nominal_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_corr(all_numeric_predictors(), threshold = 0.7) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors()) %>%
  step_zv(all_predictors())

# -----------------------------------------------------------------------------
# 7. Especificación del modelo KNN con k tuneable
# -----------------------------------------------------------------------------
# Dejamos neighbors = tune(): no fijamos k "a ojo", lo elegiremos con datos
# mediante validación cruzada. KNN no aprende parámetros: "memoriza" el
# entrenamiento y vota la clase mayoritaria entre los k vecinos más cercanos.
# weight_func = "rectangular": voto mayoritario no ponderado (todos los k
# vecinos pesan igual). Es el KNN clásico y deja ver el equilibrio
# sesgo-varianza: con k muy grande la frontera se aplana y subajusta.
modelo_knn <- nearest_neighbor(neighbors = tune(),
                               weight_func = "rectangular") %>%
  set_engine("kknn") %>%
  set_mode("classification")

# -----------------------------------------------------------------------------
# 8. Workflow: empaqueta receta + modelo en una sola pieza
# -----------------------------------------------------------------------------
# Ventaja: fit() hace prep + bake + fit internamente, y predict() aplica el
# mismo preprocesamiento a datos nuevos automáticamente. Menos errores.
workflow_knn <- workflow() %>%
  add_recipe(receta_seguros) %>%
  add_model(modelo_knn)

# -----------------------------------------------------------------------------
# 9. Validación cruzada y tuning del hiperparámetro k
# -----------------------------------------------------------------------------
# Creamos 5 folds estratificados SOLO sobre el entrenamiento. NUNCA usamos la
# prueba para elegir k (eso contaminaría la evaluación final).
set.seed(123)
folds_cv <- vfold_cv(data = seguros_entrenamiento, v = 5,
                     strata = aprobada)

# Grilla de valores candidatos de k. Probamos desde k chico (frontera muy
# flexible, riesgo de SOBREAJUSTE) hasta k grande (frontera muy lisa, riesgo
# de SUBAJUSTE) para ver toda la curva sesgo-varianza y ubicar el k óptimo.
# REGLA PRÁCTICA: si el mejor k cae justo en el borde de la grilla, conviene
# ampliarla, porque podría existir un k mejor más allá del rango probado.
grilla_k <- tibble(neighbors = c(1, 3, 5, 9, 15, 21, 31, 45, 61, 81, 101))

# Métricas a vigilar durante el tuning. roc_auc es la métrica principal.
metricas_tuning <- metric_set(roc_auc, accuracy, sensitivity, yardstick::spec)

# Ejecutamos el tuning: para cada k, entrena en 4 folds y evalúa en el
# restante, repite 5 veces y promedia.
resultados_tuning <- workflow_knn %>%
  tune_grid(resamples = folds_cv,
            grid = grilla_k,
            metrics = metricas_tuning)

# Inspeccionamos las métricas promediadas por valor de k.
collect_metrics(resultados_tuning)

# Visualizamos el AUC promedio por k (con barras de error).
resultados_tuning %>%
  collect_metrics() %>%
  filter(.metric == "roc_auc") %>%
  ggplot(aes(x = neighbors, y = mean)) +
  geom_line() +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean - std_err, ymax = mean + std_err),
                width = 0.5) +
  labs(title = "AUC promedio por valor de k (validación cruzada 5-fold)",
       x = "k (vecinos)",
       y = "AUC promedio") +
  theme_minimal()

# -----------------------------------------------------------------------------
# 10. Elegir el mejor k y finalizar el workflow
# -----------------------------------------------------------------------------
# select_best() toma el k con mejor AUC promedio en validación cruzada.
mejor_k <- resultados_tuning %>% select_best(metric = "roc_auc")
mejor_k

# finalize_workflow() inserta ese k en el workflow tuneable.
workflow_knn_final <- workflow_knn %>%
  finalize_workflow(mejor_k)

# -----------------------------------------------------------------------------
# 11. last_fit(): reentrena con TODO el entrenamiento y evalúa en la prueba
# -----------------------------------------------------------------------------
# last_fit() ajusta el workflow finalizado sobre toda la base de
# entrenamiento y predice de una vez sobre la base de prueba. Es la
# evaluación honesta final, sobre datos nunca vistos.
set.seed(123)
ajuste_final <- workflow_knn_final %>%
  last_fit(split = seguros_split,
           metrics = metric_set(roc_auc, accuracy, sensitivity,
                                 yardstick::spec))

# Métricas finales sobre la base de prueba (AUC, accuracy, sens, spec).
collect_metrics(ajuste_final)

# Predicciones sobre la base de prueba (clase y probabilidades).
predicciones_finales <- collect_predictions(ajuste_final)
predicciones_finales

# -----------------------------------------------------------------------------
# 12. Matriz de confusión sobre la base de prueba
# -----------------------------------------------------------------------------
predicciones_finales %>%
  conf_mat(truth = aprobada, estimate = .pred_class) %>%
  autoplot(type = "heatmap") +
  labs(title = paste0("Matriz de confusión - KNN tuneado (k = ",
                      mejor_k$neighbors, ")")) +
  theme_minimal()

# -----------------------------------------------------------------------------
# 13. Curva ROC y AUC sobre la base de prueba
# -----------------------------------------------------------------------------
# Para la curva usamos la probabilidad de la clase de referencia. Por defecto
# el primer nivel del factor es el "evento"; aquí los niveles son no/si en
# orden alfabético, así que .pred_no es la columna de referencia.
predicciones_finales %>%
  roc_curve(truth = aprobada, .pred_no) %>%
  autoplot() +
  labs(title = paste0("Curva ROC - KNN tuneado (k = ",
                      mejor_k$neighbors, ")"))

# AUC explícito (mismo valor que en collect_metrics).
predicciones_finales %>%
  roc_auc(truth = aprobada, .pred_no)

# -----------------------------------------------------------------------------
# Interpretación:
# - El AUC resume la capacidad de discriminación: 0.5 es azar, 1.0 perfecto.
# - Con clases balanceadas, accuracy es informativo, pero sensibilidad y
#   especificidad nos dicen en qué clase fallamos más.
# - El k elegido por validación cruzada equilibra sesgo y varianza: k chico
#   sobreajusta, k grande subajusta.
# =============================================================================
