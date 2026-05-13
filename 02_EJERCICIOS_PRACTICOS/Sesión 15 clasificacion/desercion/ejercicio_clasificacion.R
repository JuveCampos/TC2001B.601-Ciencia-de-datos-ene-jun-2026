# =============================================================================
# Ejercicio práctico: clasificación con recipes
# Caso de estudio: predicción de deserción estudiantil
# =============================================================================
# Una universidad quiere identificar de forma temprana a los estudiantes con
# mayor probabilidad de abandonar sus estudios durante el primer año, para
# canalizarlos a programas de tutoría y acompañamiento académico.
#
# Recetas aplicadas:
#   - Imputación             (step_impute_median, step_impute_mode)
#   - Varianza casi nula     (step_nzv)
#   - Filtro de colinealidad (step_corr)
#   - Normalización z-score  (step_normalize)
#   - Dummies                (step_dummy)
#
# Modelo: regresión logística con parsnip (sin workflows).
# Evaluación: matriz de confusión, accuracy, sens, spec, ROC, AUC.
# =============================================================================


# -----------------------------------------------------------------------------
# 1. Carga de paquetes
# -----------------------------------------------------------------------------
library(tidyverse)
library(tidymodels)

set.seed(2026)

estudiantes <- readxl::read_xlsx("estudiantes.xlsx")

# Distribución de la variable resultado
estudiantes %>%
  count(deserto) %>%
  mutate(prop = round(n / sum(n), 3))

# NAs por columna
estudiantes %>%
  summarise(across(everything(), ~ sum(is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_na") %>%
  arrange(desc(n_na))

# O como vimos en clase:
summary(estudiantes)

# -----------------------------------------------------------------------------
# 3. División en entrenamiento y prueba
# -----------------------------------------------------------------------------
# Estratificamos por deserto para conservar la misma proporción de clases en
# ambos conjuntos. Esto es crítico en clasificación, sobre todo con desbalance.

estudiantes_split <- initial_split(estudiantes, prop = 0.75,
                                   strata = deserto)

estudiantes_training <- estudiantes_split %>% training()
estudiantes_test     <- estudiantes_split %>% testing()

print(paste("Filas en entrenamiento:", nrow(estudiantes_training)))
print(paste("Filas en prueba:",        nrow(estudiantes_test)))

# Confirmamos que las proporciones se mantienen
estudiantes_training %>% count(deserto) %>% mutate(prop = n / sum(n))
estudiantes_test     %>% count(deserto) %>% mutate(prop = n / sum(n))


# -----------------------------------------------------------------------------
# 4. Exploración previa
# -----------------------------------------------------------------------------

# 4.1 Predictores correlacionados
# Esperamos correlación alta entre horas_estudio_semanal y horas_lectura_semanal
corr <- estudiantes_training %>%
  select(where(is.numeric)) %>%
  drop_na() %>%
  cor() %>%
  round(2)

corrplot::corrplot(corr, addCoef.col = "black")

# Visualización de la colinealidad esperada
ggplot(estudiantes_training,
       aes(x = horas_estudio_semanal, y = horas_lectura_semanal)) +
  geom_point(alpha = 0.4) +
  labs(title = "Horas de lectura vs. horas de estudio (colinealidad esperada)",
       x = "Horas de estudio semanal",
       y = "Horas de lectura semanal")

# 4.2 Variable con varianza casi nula
estudiantes_training %>%
  count(inscrito_sistema) %>%
  mutate(prop = n / sum(n))

# -----------------------------------------------------------------------------
# 5. Receta de preprocesamiento
# -----------------------------------------------------------------------------
# Orden recomendado:
#   1. Imputar primero (los pasos siguientes no toleran NAs).
#   2. Quitar varianza casi nula.
#   3. Filtrar colinealidad sobre numéricos.
#   4. Normalizar (z-score) ANTES de generar dummies.
#   5. Generar dummies.

receta_estudiantes <- recipe(deserto ~ ., data = estudiantes_training) %>%
  # 1. Imputación
  step_impute_median(all_numeric_predictors()) %>%
  step_impute_mode(all_nominal_predictors()) %>%
  # 2. Varianza casi nula
  step_nzv(all_predictors()) %>%
  # 3. Colinealidad
  step_corr(all_numeric_predictors(), threshold = 0.85) %>%
  # 4. Normalización z-score
  step_normalize(all_numeric_predictors()) %>%
  # 5. Dummies
  step_dummy(all_nominal_predictors())

receta_estudiantes


# 5.1 Entrenamiento de la receta
# prep() aprende las medianas, medias, desviaciones y umbrales únicamente
# sobre los datos de entrenamiento. Esto evita fugas de información (data
# leakage).
receta_estudiantes_prep <- receta_estudiantes %>%
  prep(training = estudiantes_training)

receta_estudiantes_prep

# 5.2 Aplicación a entrenamiento y prueba
estudiantes_training_prep <- receta_estudiantes_prep %>%
  bake(new_data = NULL)

estudiantes_test_prep <- receta_estudiantes_prep %>%
  bake(new_data = estudiantes_test)

glimpse(estudiantes_training_prep)

# Verificamos que ya no hay NAs
estudiantes_training_prep %>%
  summarise(across(everything(), ~ sum(is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_na") %>%
  filter(n_na > 0)


# -----------------------------------------------------------------------------
# 6. Especificación y entrenamiento del modelo
# -----------------------------------------------------------------------------
modelo_logistico <- logistic_reg() %>%
  set_engine("glm") %>%
  set_mode("classification")

logistic_fit <- modelo_logistico %>%
  fit(deserto ~ ., data = estudiantes_training_prep)

logistic_fit

# 6.1 Coeficientes del modelo, ordenados por significancia
# Coeficientes positivos aumentan la probabilidad de pertenecer a la clase
# positiva (si deserto), negativos la disminuyen.
tidy(logistic_fit) %>%
  arrange(p.value)


# -----------------------------------------------------------------------------
# 7. Predicción sobre el conjunto de prueba
# -----------------------------------------------------------------------------
# Para clasificación necesitamos dos tipos de predicción:
#   - type = "class": la clase predicha (si o no).
#   - type = "prob":  las probabilidades estimadas para cada clase
#                     (necesarias para la curva ROC).

class_preds <- predict(logistic_fit,
                       new_data = estudiantes_test_prep,
                       type = "class")

prob_preds <- predict(logistic_fit,
                      new_data = estudiantes_test_prep,
                      type = "prob")

# Combinamos resultados
resultados_test <- estudiantes_test_prep %>%
  select(deserto) %>%
  bind_cols(class_preds, prob_preds)

resultados_test


# -----------------------------------------------------------------------------
# 8. Evaluación del modelo
# -----------------------------------------------------------------------------

# 8.1 Matriz de confusión
conf_mat(resultados_test,
         truth    = deserto,
         estimate = .pred_class)

# Visualización tipo heatmap
conf_mat(resultados_test,
         truth    = deserto,
         estimate = .pred_class) %>%
  autoplot(type = "heatmap") +
  labs(title = "Matriz de confusión")


# 8.2 Métricas individuales
# Sensibilidad: de todos los estudiantes que efectivamente desertaron, qué
#   porcentaje detectó el modelo (queremos que sea alta para no dejar fuera a
#   quien necesita apoyo).
# Especificidad: de todos los estudiantes que NO desertaron, qué porcentaje el
#   modelo clasificó correctamente.
accuracy(resultados_test, truth = deserto, estimate = .pred_class)
sens(resultados_test,     truth = deserto, estimate = .pred_class)

# Usamos yardstick::spec para evitar conflicto de nombres con base R
yardstick::spec(resultados_test, truth = deserto, estimate = .pred_class)


# 8.3 Conjunto de métricas personalizado
metricas_clasificacion <- metric_set(accuracy, sens, yardstick::spec)

metricas_clasificacion(resultados_test,
                       truth    = deserto,
                       estimate = .pred_class)


# 8.4 Resumen completo desde la matriz de confusión
conf_mat(resultados_test,
         truth    = deserto,
         estimate = .pred_class) %>%
  summary()


# 8.5 Curva ROC y AUC
# Calculamos los puntos de la curva
roc_df <- resultados_test %>%
  roc_curve(truth = deserto, .pred_si)

roc_df

# Graficamos
roc_df %>%
  autoplot() +
  labs(title = "Curva ROC del modelo de deserción")

# Área bajo la curva
# Interpretación de AUC:
#   AUC = 0.5 -> modelo equivalente a azar.
#   AUC ~ 0.7 -> desempeño aceptable.
#   AUC ~ 0.8 -> buen desempeño.
#   AUC > 0.9 -> excelente desempeño.
roc_auc(resultados_test, truth = deserto, .pred_si)

