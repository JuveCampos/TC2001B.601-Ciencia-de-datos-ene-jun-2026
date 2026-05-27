
options(scipen = 999)

# Librerías
library(tidyverse)
library(tidymodels)
library(corrplot)

tidymodels::tidymodels_prefer()

# Cargar los datos:
reservas <- read_csv("reservas_hotel.csv") %>%
  select(-id_reserva)

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
receta_reservas <- receta_reservas %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_corr(all_numeric_predictors(), threshold = 0.7) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors())

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
