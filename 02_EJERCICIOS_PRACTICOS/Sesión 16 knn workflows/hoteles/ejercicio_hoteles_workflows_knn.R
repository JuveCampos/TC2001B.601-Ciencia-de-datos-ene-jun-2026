
options(scipen = 999)

# Librerías
library(tidyverse)
library(tidymodels)
library(corrplot)
library(kknn)

tidymodels::tidymodels_prefer()

# Cargar los datos:
# (Convertimos cancelo a factor desde el inicio: las funciones de yardstick
# y de parsnip para clasificación lo requieren como factor; si lo dejamos
# como character, conf_mat(), roc_curve(), metric_set(), etc. fallan).
reservas <- read_csv("reservas_hotel.csv") %>%
  select(-id_reserva) %>%
  mutate(cancelo = factor(cancelo))

# 2. Para la variable y, cancelo, obtenga la proporción de verdaderos y falsos.
reservas %>%
  group_by(cancelo) %>%
  count() %>%
  ungroup() %>%
  mutate(porcentaje = 100*(n/sum(n)))

prop.table(table(reservas$cancelo))


# 3. Obtenga el numero de NAs por columna
summary(reservas)
# precio_total_mxn: 60 NAs
# descuento_aplicado_pct: 75 NAs

# 4. Remueva el id de la reserva, ya que no es un predictor (¿o sí?)

# Obtenga la matriz de correlación de las variables numéricas e
# inspeccione en búsqueda de colinealidad

matriz_correlacion <- reservas %>%
  select(where(is.numeric)) %>%
  drop_na() %>%
  cor() %>%
  round(2)

matriz_correlacion %>%
  corrplot(method = "circle", addCoef.col = "black")

# 6. Divida la base en base de entrenamiento y base de prueba,
# estratificando por la variable “cancelo”.
# Verifique si la proporción se mantuvo con la calculada en (2).

reservas_split <- initial_split(data = reservas, prop = 0.75, strata = cancelo)

# Base de entrenamiento:
reservas_entrenamiento <- reservas_split %>% training()
# Base de prueba
reservas_prueba <- reservas_split %>% testing()


table(reservas_entrenamiento$cancelo) %>% prop.table()
table(reservas_prueba$cancelo) %>% prop.table()

# Genere la receta para aplicar los siguientes pasos de feature engineering:
# (1) Imputar primero (los pasos siguientes no toleran NAs).
# (2) Quitar varianza casi nula.
# (3) Filtrar colinealidad sobre numericos.
# (4) Normalizar (z-score) ANTES de generar dummies.
# (5) Generar dummies.
# Aplique la receta. La fórmula de clasificación sería cancelo ~ .


# 1. Generar la receta:
receta_reservas <- recipe(cancelo ~ . , data = reservas_entrenamiento)

# 2. Voy añadiendo los pasos a la receta
# Nota: añadimos step_unknown() para que los NAs de las variables
# categoricas (p. ej. pais_origen) se conviertan en un nivel explicito
# "unknown" ANTES de step_dummy(). Si no, step_dummy() los trata como un
# nivel nuevo y al predecir el modelo descarta esas filas (rompiendo
# bind_cols mas adelante, especialmente con KNN).
receta_reservas <- receta_reservas %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_unknown(all_nominal_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_corr(all_numeric_predictors(), threshold = 0.7) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors()) %>%
  step_zv(all_predictors())   # remueve dummies vacios que deja step_unknown

# 3. Entrenar la receta
receta_reservas_prep <- receta_reservas %>%
  prep(training = reservas_entrenamiento)

# 4. Bake a la base de entrenamiento y a la base de prueba
reservas_entrenamiento_prep <-  receta_reservas_prep %>% bake(new_data = NULL)
reservas_prueba_prep        <-  receta_reservas_prep %>% bake(new_data = reservas_prueba)

# 8. Defina el modelo de regresión logística ----

modelo_logistico <- logistic_reg() %>%
  set_engine("glm") %>%
  set_mode("classification")

# 9. Ajuste el modelo de regresión logística.
logistic_fit <- modelo_logistico %>% fit(cancelo ~ . ,
                                         data = reservas_entrenamiento_prep)

logistic_fit

# 11. Para cada observación de la base de prueba, obtenga la clase predicha
# (canceló/no canceló) y la probabilidad de cancelar y no cancelar.
# Obtenga una tabla que contenga el valor real, el valor predicho,
# la probabilidad de cancelar y la probabilidad de no cancelar.

clases_predichas <- predict(logistic_fit, new_data = reservas_prueba_prep, type = "class")
probabilidades <- predict(logistic_fit, new_data = reservas_prueba_prep, type = "prob")

resultados_pred <- reservas_prueba_prep %>%
  select(cancelo) %>%
  bind_cols(clases_predichas, probabilidades)


# 12. Obtenga (y grafique) la matríz de confusión del modelo con los datos de prueba
conf_mat(resultados_pred, truth = cancelo, estimate = .pred_class) %>%
  autoplot(type = "heatmap") +
  labs(title = "Matríz de confusión") +
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(n = 10, name = "Reds")) +
  theme_minimal()

# 13. Obtenga las métricas de accuracy, sensibility y specificity
metricas_evaluacion <- metric_set(accuracy, sensitivity, yardstick::spec)
metricas_evaluacion(data = resultados_pred, truth = cancelo, estimate = .pred_class)

# 14. Obtenga la curva ROC y la medida de AUC.
# Interprete este valor para dar una calificación cualitativa del modelo.

roc_df <- resultados_pred %>%
  roc_curve(truth =cancelo, .pred_no)

roc_df %>%
  autoplot() +
  labs(title = "Curva ROC")

# Area bajo la curva de la curva ROC
roc_auc(resultados_pred, truth =cancelo, .pred_no)


# 15. Ajuste el threshold (umbral) de decisión a 0.8. ¿Qué tanto cambia la matríz de confusión?
resultados_pred_08 <- resultados_pred %>%
  mutate(pred_class_08 = ifelse(.pred_no >= 0.8, yes = "no", no = "si")) %>%
  mutate(pred_class_08 = factor(pred_class_08))


# 13. Obtenga las métricas de accuracy, sensibility y specificity
metricas_evaluacion <- metric_set(accuracy, sensitivity, yardstick::spec)
metricas_evaluacion(data = resultados_pred_08, truth = cancelo, estimate = pred_class_08)

# 14. Obtenga la curva ROC y la medida de AUC.
# Interprete este valor para dar una calificación cualitativa del modelo.

roc_df <- resultados_pred_08 %>%
  roc_curve(truth =cancelo, .pred_no)

roc_df %>%
  autoplot() +
  labs(title = "Curva ROC")

# Area bajo la curva de la curva ROC
roc_auc(resultados_pred_08, truth =cancelo, .pred_no)


# =============================================================================
# SECCIÓN (1): WORKFLOWS EN TIDYMODELS
# =============================================================================
#
# ¿Qué es un workflow?
# --------------------
# Hasta ahora hemos hecho el pipeline de modelado en pasos sueltos:
#   (a) definimos una receta (recipe) con el feature engineering,
#   (b) la preparamos con prep() sobre la base de entrenamiento,
#   (c) la aplicamos con bake() a entrenamiento y prueba,
#   (d) definimos el modelo (parsnip),
#   (e) ajustamos el modelo sobre los datos "horneados",
#   (f) predecimos sobre los datos de prueba "horneados".
#
# Esto funciona, pero es frágil: si nos olvidamos de aplicar bake() a la
# base de prueba antes de predecir, o si más adelante recibimos datos
# nuevos sin transformar, podemos romper el flujo o introducir bugs sutiles.
#
# Un workflow en tidymodels es un objeto que empaqueta en una sola pieza:
#   - la receta de preprocesamiento, y
#   - la especificación del modelo.
#
# Ventajas:
#   * fit() sobre el workflow se encarga internamente de prep + bake + fit.
#   * predict() sobre el workflow aplica el mismo preprocesamiento a los
#     datos nuevos automáticamente (no hay que recordar bake()).
#   * Es la pieza estándar que usaremos para hacer tuning de hiperparámetros
#     y validación cruzada en las secciones siguientes.

# 1. Reusamos la misma receta y la misma especificación del modelo logístico
#    (no las redefinimos; ya están declaradas arriba como receta_reservas y
#    modelo_logistico).

# 2. Armamos el workflow: receta + modelo
workflow_logistico <- workflow() %>%
  add_recipe(receta_reservas) %>%
  add_model(modelo_logistico)

workflow_logistico

# 3. Ajustamos el workflow directamente sobre la base de entrenamiento
#    SIN BAKE: el workflow hace prep+bake internamente.
workflow_logistico_fit <- workflow_logistico %>%
  fit(data = reservas_entrenamiento)

workflow_logistico_fit

# 4. Predecimos sobre la base de prueba SIN BAKE.
#    El workflow aplica el preprocesamiento a reservas_prueba por nosotros.
clases_predichas_wf  <- predict(workflow_logistico_fit,
                                new_data = reservas_prueba,
                                type = "class")
probabilidades_wf    <- predict(workflow_logistico_fit,
                                new_data = reservas_prueba,
                                type = "prob")

resultados_pred_wf <- reservas_prueba %>%
  select(cancelo) %>%
  bind_cols(clases_predichas_wf, probabilidades_wf)

# 5. Matriz de confusión, métricas y curva ROC con el workflow
conf_mat(resultados_pred_wf, truth = cancelo, estimate = .pred_class) %>%
  autoplot(type = "heatmap") +
  labs(title = "Matríz de confusión - Workflow Regresión Logística") +
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(n = 10, name = "Reds")) +
  theme_minimal()

metricas_evaluacion(data = resultados_pred_wf,
                    truth = cancelo,
                    estimate = .pred_class)

resultados_pred_wf %>%
  roc_curve(truth = cancelo, .pred_no) %>%
  autoplot() +
  labs(title = "Curva ROC - Workflow Regresión Logística")

roc_auc(resultados_pred_wf, truth = cancelo, .pred_no)

# Nota: los resultados deben coincidir (salvo diferencias numéricas mínimas)
# con los obtenidos arriba sin workflow. La ganancia no está en la métrica
# sino en la robustez y compacidad del código.


# =============================================================================
# SECCIÓN (2): MODELO KNN CON K ARBITRARIO
# =============================================================================
#
# ¿Qué es KNN (k-nearest neighbors)?
# ----------------------------------
# Es un modelo de clasificación basado en distancias: para predecir la
# clase de una observación nueva, busca las k observaciones más cercanas
# en la base de entrenamiento (usando una métrica de distancia, por defecto
# Minkowski/Euclidiana) y vota la clase mayoritaria entre esas k vecinas.
#
# Características importantes:
#   * NO entrena parámetros como la regresión logística; "memoriza" la base
#     de entrenamiento. Por eso a veces se le llama un modelo "perezoso".
#   * Es muy sensible a la escala de las variables: una variable con rango
#     grande domina la distancia. Por eso normalizar (step_normalize) es
#     prácticamente obligatorio antes de KNN.
#   * Es sensible a variables irrelevantes y a la dimensionalidad.
#   * El hiperparámetro k controla el sesgo-varianza:
#       - k pequeño  => modelo flexible, baja sesgo, alta varianza (overfit).
#       - k grande   => modelo rígido, alto sesgo, baja varianza (underfit).
#
# En esta sección fijamos k a un valor arbitrario (k = 7) sólo para
# comparar contra la regresión logística. En la siguiente sección haremos
# tuning para elegir k con datos.

# 1. Especificación del modelo KNN (parsnip), con k fijo
modelo_knn <- nearest_neighbor(neighbors = 7) %>%
  set_engine("kknn") %>%
  set_mode("classification")

# 2. Workflow: misma receta + modelo KNN
workflow_knn <- workflow() %>%
  add_recipe(receta_reservas) %>%
  add_model(modelo_knn)

# 3. Ajustar el workflow sobre la base de entrenamiento
workflow_knn_fit <- workflow_knn %>%
  fit(data = reservas_entrenamiento)

# 4. Predicciones sobre la base de prueba
clases_predichas_knn <- predict(workflow_knn_fit,
                                new_data = reservas_prueba,
                                type = "class")
probabilidades_knn   <- predict(workflow_knn_fit,
                                new_data = reservas_prueba,
                                type = "prob")

resultados_pred_knn <- reservas_prueba %>%
  select(cancelo) %>%
  bind_cols(clases_predichas_knn, probabilidades_knn)

# 5. Matriz de confusión
conf_mat(resultados_pred_knn, truth = cancelo, estimate = .pred_class) %>%
  autoplot(type = "heatmap") +
  labs(title = "Matríz de confusión - KNN (k = 7)") +
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(n = 10, name = "Blues")) +
  theme_minimal()

# 6. Métricas
metricas_evaluacion(data = resultados_pred_knn,
                    truth = cancelo,
                    estimate = .pred_class)

# 7. Curva ROC y AUC
resultados_pred_knn %>%
  roc_curve(truth = cancelo, .pred_no) %>%
  autoplot() +
  labs(title = "Curva ROC - KNN (k = 7)")

roc_auc(resultados_pred_knn, truth = cancelo, .pred_no)

# 8. Comparación lado a lado: regresión logística vs KNN (k = 7)
metricas_logistica <- metricas_evaluacion(resultados_pred_wf,
                                          truth = cancelo,
                                          estimate = .pred_class) %>%
  mutate(modelo = "logistica")

metricas_knn7 <- metricas_evaluacion(resultados_pred_knn,
                                     truth = cancelo,
                                     estimate = .pred_class) %>%
  mutate(modelo = "knn_k7")

auc_logistica <- roc_auc(resultados_pred_wf, truth = cancelo, .pred_no) %>%
  mutate(modelo = "logistica")

auc_knn7 <- roc_auc(resultados_pred_knn, truth = cancelo, .pred_no) %>%
  mutate(modelo = "knn_k7")

comparacion_logistica_vs_knn7 <- bind_rows(metricas_logistica,
                                           metricas_knn7,
                                           auc_logistica,
                                           auc_knn7) %>%
  select(modelo, .metric, .estimate) %>%
  pivot_wider(names_from = modelo, values_from = .estimate)

comparacion_logistica_vs_knn7


# =============================================================================
# SECCIÓN (3): TUNING DE HIPERPARÁMETROS PARA KNN
# =============================================================================
#
# ¿Qué es un hiperparámetro y por qué se "tunea"?
# -----------------------------------------------
# Un hiperparámetro es un parámetro que NO se aprende de los datos durante
# el entrenamiento del modelo, sino que lo fija el analista ANTES de
# entrenar (ej. k en KNN, la profundidad de un árbol, lambda en una
# regresión penalizada).
#
# Como no se aprende automáticamente, hay que elegirlo. Elegirlo "a ojo"
# (como hicimos arriba con k = 7) es arbitrario. Lo correcto es probar
# varios valores y quedarnos con el que da mejor desempeño estimado.
#
# IMPORTANTE: no podemos usar la base de prueba para elegir k, porque
# entonces la prueba dejaría de ser una evaluación honesta. La solución
# estándar es validación cruzada (k-fold cross-validation) SOLO sobre la
# base de entrenamiento:
#   * Partimos el entrenamiento en v folds (digamos v = 5).
#   * Para cada valor candidato de k, entrenamos en (v-1) folds y evaluamos
#     en el fold restante; repetimos v veces y promediamos la métrica.
#   * Elegimos el k con mejor promedio. Recién entonces re-entrenamos con
#     ese k sobre TODA la base de entrenamiento y evaluamos en la prueba.

# 1. Reespecificar el modelo KNN dejando neighbors como tune()
modelo_knn_tune <- nearest_neighbor(neighbors = tune()) %>%
  set_engine("kknn") %>%
  set_mode("classification")

# 2. Workflow con el modelo "tuneable"
workflow_knn_tune <- workflow() %>%
  add_recipe(receta_reservas) %>%
  add_model(modelo_knn_tune)

# 3. Folds de validación cruzada estratificada sobre el entrenamiento
set.seed(123)
folds_cv <- vfold_cv(data = reservas_entrenamiento,
                     v = 5,
                     strata = cancelo)

# 4. Grilla de valores candidatos de k
# Regla practica: si el mejor k cae en el borde de la grilla, conviene
# ampliarla para asegurarse de que no haya un k mejor mas alla.
grilla_k <- tibble(neighbors = c(3, 5, 7, 11, 15, 21, 31, 51, 75, 101, 151))

# 5. Métricas a vigilar durante el tuning
metricas_tuning <- metric_set(roc_auc, accuracy, sensitivity, yardstick::spec)

# 6. Ejecutar el tuning
resultados_tuning <- workflow_knn_tune %>%
  tune_grid(resamples = folds_cv,
            grid = grilla_k,
            metrics = metricas_tuning)

# 7. Inspeccionar los resultados
collect_metrics(resultados_tuning)

resultados_tuning %>%
  collect_metrics() %>%
  filter(.metric == "roc_auc") %>%
  ggplot(aes(x = neighbors, y = mean)) +
  geom_line() +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean - std_err,
                    ymax = mean + std_err),
                width = 0.5) +
  labs(title = "AUC promedio por valor de k (validación cruzada 5-fold)",
       x = "k (neighbors)",
       y = "AUC promedio") +
  theme_minimal()

# 8. Elegir el mejor k según AUC
mejor_k <- resultados_tuning %>% select_best(metric = "roc_auc")
mejor_k

# 9. Finalizar el workflow con ese k y reentrenar sobre TODO el entrenamiento
workflow_knn_final <- workflow_knn_tune %>%
  finalize_workflow(mejor_k)

workflow_knn_final_fit <- workflow_knn_final %>%
  fit(data = reservas_entrenamiento)

# 10. Predicciones sobre la base de prueba con el k óptimo
clases_predichas_knn_opt <- predict(workflow_knn_final_fit,
                                    new_data = reservas_prueba,
                                    type = "class")
probabilidades_knn_opt   <- predict(workflow_knn_final_fit,
                                    new_data = reservas_prueba,
                                    type = "prob")

resultados_pred_knn_opt <- reservas_prueba %>%
  select(cancelo) %>%
  bind_cols(clases_predichas_knn_opt, probabilidades_knn_opt)

# 11. Matriz de confusión y curva ROC del KNN tuneado
conf_mat(resultados_pred_knn_opt,
         truth = cancelo,
         estimate = .pred_class) %>%
  autoplot(type = "heatmap") +
  labs(title = paste0("Matríz de confusión - KNN tuneado (k = ",
                      mejor_k$neighbors, ")")) +
  scale_fill_gradientn(colors = RColorBrewer::brewer.pal(n = 10, name = "Greens")) +
  theme_minimal()

resultados_pred_knn_opt %>%
  roc_curve(truth = cancelo, .pred_no) %>%
  autoplot() +
  labs(title = paste0("Curva ROC - KNN tuneado (k = ",
                      mejor_k$neighbors, ")"))

# 12. Comparación final: logística vs KNN (k = 7) vs KNN tuneado
metricas_knn_opt <- metricas_evaluacion(resultados_pred_knn_opt,
                                        truth = cancelo,
                                        estimate = .pred_class) %>%
  mutate(modelo = "knn_tuneado")

auc_knn_opt <- roc_auc(resultados_pred_knn_opt,
                       truth = cancelo,
                       .pred_no) %>%
  mutate(modelo = "knn_tuneado")

comparacion_final <- bind_rows(metricas_logistica,
                               metricas_knn7,
                               metricas_knn_opt,
                               auc_logistica,
                               auc_knn7,
                               auc_knn_opt) %>%
  select(modelo, .metric, .estimate) %>%
  pivot_wider(names_from = modelo, values_from = .estimate)

comparacion_final

# Interpretación:
# - Si el KNN tuneado mejora claramente al KNN con k = 7, vemos en acción
#   el valor de tunear: el k arbitrario era subóptimo.
# - Si la regresión logística sigue ganando, eso también es información:
#   en este problema la frontera de decisión parece bien aproximada por
#   un modelo lineal y KNN no aporta valor adicional.
# - El AUC y la sensibilidad/especificidad son más informativos que el
#   accuracy cuando las clases están desbalanceadas.
