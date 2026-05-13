
options(scipen = 999)

# 1. Cargue las librerías correspondientes. Utilice la función tidymodels::tidymodels_prefer() para evitar conflictos de funciones.

# Librerías ----
library(tidyverse)
library(tidymodels)
library(readxl)
library(corrplot)

# Priorizamos las funciones de tidymodels
tidymodels_prefer()

# 2. Cargue los datos del archivo precio_viviendas_2.xlsx. Explore la base.
viviendas <- read_excel("precio_viviendas_2.xlsx")

# Obtenga la matriz de correlación y grafiquela con corrplot(). ¿Hay variables X con colinealidad?

matriz_de_correlacion <- viviendas %>%
  select(where(is.numeric)) %>%
  drop_na() %>%
  cor() %>%
  round(2)

# Graficarla:
matriz_de_correlacion %>%
  corrplot(method = "circle",
           lab_size = 3,
           addCoef.col = "black")

# Verifique si hay NAs entre las variables. ¿Cuál es la variable con más NAs, si tienen?

summary(viviendas)

# m2_terreno tiene 54 NAs
# anio_construccion tiene 37 NAs
# banos tiene 14 NAs

# Haga el resampleo en base de entrenamiento y base de prueba. Que la base de entrenamiento represente el 75% de la base. Utilice set.seed(20260512)

set.seed(20260512)

viviendas_split <- initial_split(data = viviendas,
                                 prop = 0.75,
                                 strata = precio)

# La base de entrenamiento
viviendas_training <- viviendas_split %>% training()

# La base de prueba
viviendas_test <- viviendas_split %>% testing()


# Genere una receta que le permita: (1) imputar con la mediana los valores numéricos faltantes, (2) imputar con la moda los valores nominales faltantes, (3) elimine las variables con colinealidad (correlación mayor a 0.85), (4) elimine las variables con varianza cero y (5) convierta las variables nominales a variables dummy. La fórmula de regresión será precio ~ .

# Paso 1. Generamos el objeto receta:
receta_viviendas <- recipe(precio ~ .,
                           data = viviendas_training)

# Paso 2. Añadimos los pasos de la receta:
receta_viviendas <- receta_viviendas %>%
  # (1) imputar con la mediana los valores numéricos faltantes
  step_impute_median(all_numeric_predictors()) %>%
  # (2) imputar con la moda los valores nominales faltantes
  step_impute_mode(all_nominal_predictors()) %>%
  # (3) elimine las variables con colinealidad (correlación mayor a 0.85)
  step_corr(all_numeric_predictors(), threshold = 0.85) %>%
  # (4) elimine las variables con varianza cero
  step_nzv() %>%
  # (5) convierta las variables nominales a variables dummy
  step_dummy(all_nominal_predictors())



# 7. Una vez terminada la receta, aplique a las bases de entrenamiento y las bases de prueba.

# Preparamos la receta
receta_viviendas_prep <- receta_viviendas %>%
  prep(training = viviendas_training)

# Hacemos bake a los datos:

# Preparar la base de entrenamiento:
viviendas_training_prep <- receta_viviendas_prep %>%
  bake(new_data = NULL)

# Preparar la base de prueba:
viviendas_test_prep <- receta_viviendas_prep %>%
  bake(new_data = viviendas_test)

# 8. Ya con las bases “horneadas” (sin colinealidad y todos esos problemas) ajuste el modelo de regresión con la función fit() y la fórmula correspondiente.

modelo_lineal <- linear_reg() %>%
  set_engine("lm") %>%
  set_mode("regression")

modelo_fit <- modelo_lineal %>%
  fit(precio ~ . ,
      data = viviendas_training_prep)

# 9. Una vez que tenga el modelo entrenado con la base de entrenamiento, prediga los valores de y con la base de prueba, usando la función predict().

predicciones <- predict(object = modelo_fit, new_data = viviendas_test_prep)

resultados_test <- viviendas_test_prep %>%
  select(precio) %>%
  bind_cols(predicciones)

# 10. Una vez que tenga los datos predichos y los datos reales de la base de prueba, obtenga el rmse, el rsq y el mae (Mean Average Error).

resultados_test %>% rmse(truth = precio, estimate = .pred)
resultados_test %>% rsq(truth = precio, estimate = .pred)
resultados_test %>% mae(truth = precio, estimate = .pred)

metricas_evaluacion <- metric_set(rmse, rsq, mae)
metricas_evaluacion
metricas_evaluacion(resultados_test, truth = precio, estimate = .pred)

# 11. Finalmente, genere una gráfica en ggplot como la de la clase pasada, donde tenga en el eje “X” los valores reales y en el eje “Y” los valores predichos. Agregue una línea diagonal con la capa geom_abline().

resultados_test %>%
  ggplot(aes(x =precio, y = .pred )) +
  geom_point(alpha = 0.3, color = "red") +
  geom_abline(color = "blue", linetype = 2)

