
options(scipen = 999)

# Librerías ----
library(tidyverse)
library(tidymodels)

# 1. Cargue los datos del objeto home_sales.rds
home_prices <- readRDS("home_sales.rds")

# Utilizando initial_split(), divida la muestra en base de entrenamiento y base de prueba.

home_split <- initial_split(data = home_prices,
              prop = 0.7,
              strata = selling_price)

# Crear base de entrenamiento
home_training <- home_split %>% training()

# Crear base de prueba
home_test <- home_split %>% testing()

# 3. La variable y va a ser la variable selling_price. Obtenga, para la base de entrenamiento y la base de prueba, las estadísticas descriptivas de esta variable (min, max, desviación estándar, media). ¿Son diferentes?

set.seed(19910708)

home_training %>%
  summarise(media_precio = mean(selling_price, na.rm = T),
            min_precio = min(selling_price, na.rm = T),
            max_precio = max(selling_price, na.rm = T),
            sd_precio = sd(selling_price, na.rm = T))

home_test %>%
  summarise(media_precio = mean(selling_price, na.rm = T),
            min_precio = min(selling_price, na.rm = T),
            max_precio = max(selling_price, na.rm = T),
            sd_precio = sd(selling_price, na.rm = T))

# 4. Defina un modelo de regresión lineal, utilizando el engine “lm” y el modo “regression”.

linear_model <- linear_reg() %>%
  set_engine("lm") %>%
  set_mode("regression")

# Tomando como variables X a las variables home_age y sqft_living, ajuste un modelo de regresión sobre la base de entrenamiento. ¿Cuál es la fórmula de la recta de regresión correspondiente?

lm_fit <- linear_model %>%
  fit(formula = selling_price ~ home_age + sqft_living,
      data = home_training)
lm_fit

# 6. Utilice este modelo con la base de prueba utilizando la función predict. “Péguele”  la columna de valores predichos a la base de prueba.

home_predictions <- predict(lm_fit, new_data = home_test)

home_test_results <- home_test %>%
  select(selling_price, home_age, sqft_living) %>%
  bind_cols(home_predictions)

# 7. Con estos datos en una sola tabla (reales y predichos por el modelo) obtenga el RMSE (Raíz del error cuadrático medio) y la R^2

home_test_results %>%
  rmse(truth = selling_price, estimate = .pred)

mean(home_test_results$selling_price)

home_test_results %>%
  rsq(truth = selling_price, estimate = .pred)


# 8. Grafique los valores reales contra los valores predichos.

home_test_results %>%
  ggplot(aes( x = selling_price, y = .pred)) +
  geom_point(alpha = 0.2, color = "red") +
  geom_abline(color = "blue", linetype = 2) +
  scale_x_continuous(labels = scales::comma_format()) +
  scale_y_continuous(labels = scales::comma_format()) +
  coord_obs_pred() +
  labs(x = "Precio real", y = "Precio predicho",
       title = "Precios real vs predicho")+
  theme_minimal()

# Replique el problema, pero ahora tomando en cuenta todas las variables en X. ----

# Tomando como variables X a las variables home_age y sqft_living, ajuste un modelo de regresión sobre la base de entrenamiento. ¿Cuál es la fórmula de la recta de regresión correspondiente?

lm_fit <- linear_model %>%
  fit(formula = selling_price ~ .,
      data = home_training)
lm_fit



# 6. Utilice este modelo con la base de prueba utilizando la función predict. “Péguele”  la columna de valores predichos a la base de prueba.

home_predictions <- predict(lm_fit, new_data = home_test)

home_test_results <- home_test %>%
  select(selling_price, home_age, sqft_living) %>%
  bind_cols(home_predictions)

# 7. Con estos datos en una sola tabla (reales y predichos por el modelo) obtenga el RMSE (Raíz del error cuadrático medio) y la R^2

home_test_results %>%
  rmse(truth = selling_price, estimate = .pred)

mean(home_test_results$selling_price)

home_test_results %>%
  rsq(truth = selling_price, estimate = .pred)


# 8. Grafique los valores reales contra los valores predichos.

home_test_results %>%
  ggplot(aes( x = selling_price, y = .pred)) +
  geom_point(alpha = 0.2, color = "red") +
  geom_abline(color = "blue", linetype = 2) +
  scale_x_continuous(labels = scales::comma_format()) +
  scale_y_continuous(labels = scales::comma_format()) +
  coord_obs_pred() +
  labs(x = "Precio real", y = "Precio predicho",
       title = "Precios real vs predicho")+
  theme_minimal()

