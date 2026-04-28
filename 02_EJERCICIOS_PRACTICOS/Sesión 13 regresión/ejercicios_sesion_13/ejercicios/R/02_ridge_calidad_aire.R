# 02_ridge_calidad_aire.R
# ------------------------------------------------------------
# Historia:
# Una secretaria ambiental quiere predecir PM2.5 diario en una ciudad.
# Hay predictores meteorologicos y de movilidad muy correlacionados:
# trafico, velocidad promedio, oxidos de nitrogeno y hora pico suelen moverse
# juntos. En ese contexto, OLS puede tener alta varianza y coeficientes
# inestables. Ridge ayuda encogiendo coeficientes sin llevarlos a cero.
#
# Fundamentos ISLR que se practican:
# - Problema de colinealidad
# - Ridge regression con penalizacion L2
# - Estandarizacion de predictores
# - Validacion cruzada para elegir lambda
# - Comparacion de error de prueba contra OLS
#
# Estilo tidymodels:
# - recipe() para dummies y normalizacion
# - vfold_cv() para validacion cruzada
# - linear_reg(penalty = tune(), mixture = 0) para ridge
# - tune_grid(), select_best(), finalize_workflow()
# ------------------------------------------------------------

library(tidyverse)
library(tidymodels)

tidymodels_prefer()
set.seed(2026)

if (!file.exists("data/calidad_aire_sintetica.csv") || !dir.exists("outputs")) {
  stop("Primero corre R/00_preparar_proyecto_y_datos.R desde el proyecto ejercicios.")
}

# 1) Leer datos --------------------------------------------------------------
# Metadatos:
# - Unidad de observacion: un dia de monitoreo ambiental urbano.
# - Variable respuesta: pm25_ug_m3, concentracion diaria de PM2.5.
# - Predictores meteorologicos: viento_kmh, humedad, temperatura_c, lluvia_mm,
#   estacion e inversion_termica.
# - Predictores de actividad urbana: indice_trafico, velocidad_promedio,
#   no2_ppb, co_ppm y entregas_urbanas.
# - dia es una marca temporal; se conserva al leer y se excluye del modelado.
calidad_aire <- read_csv("data/calidad_aire_sintetica.csv", show_col_types = FALSE) %>%
  mutate(
    dia = as.Date(dia),
    estacion = factor(estacion, levels = c("invierno", "primavera", "verano", "otono"))
  )

# 2) Entrenamiento/prueba ----------------------------------------------------
set.seed(2026)

split_aire <- initial_split(calidad_aire, prop = .75)
aire_train <- training(split_aire) %>% select(-dia)
aire_test <- testing(split_aire) %>% select(-dia)

# 3) Mirar colinealidad antes de modelar ------------------------------------
correlaciones <- aire_train %>%
  select(where(is.numeric), -pm25_ug_m3) %>%
  cor() %>%
  as.data.frame() %>%
  rownames_to_column("variable")

correlaciones %>%
  write_csv("outputs/02_correlaciones_predictores.csv")

# 4) Receta compartida -------------------------------------------------------
# step_normalize() deja todos los predictores numericos en la misma escala.
# Esto es importante en ridge/lasso porque la penalizacion depende de la
# magnitud de los coeficientes.
receta_aire <- recipe(pm25_ug_m3 ~ ., data = aire_train) %>%
  step_dummy(all_nominal_predictors()) %>%
  # ?step_zv
  step_zv(all_predictors()) %>%
  # ?step_normalize
  step_normalize(all_numeric_predictors())


# 5) OLS como punto de comparacion ------------------------------------------
wf_ols <- workflow() %>%
  add_model(linear_reg() %>% set_engine("lm")) %>%
  add_recipe(receta_aire)

ajuste_ols <- fit(wf_ols, data = aire_train)

metricas_ols <- predict(ajuste_ols, new_data = aire_test) %>%
  bind_cols(aire_test %>% select(pm25_ug_m3)) %>%
  metrics(truth = pm25_ug_m3, estimate = .pred) %>%
  filter(.metric %in% c("rmse", "rsq")) %>%
  select(.metric, .estimate) %>%
  pivot_wider(names_from = .metric, values_from = .estimate) %>%
  mutate(modelo = "OLS tidymodels", lambda = NA_real_)

# 6) Ridge con validacion cruzada -------------------------------------------
set.seed(2026)

folds_aire <- vfold_cv(aire_train, v = 10)

modelo_ridge <- linear_reg(penalty = tune(), mixture = 0) %>%
  set_engine("glmnet")

wf_ridge <- workflow() %>%
  add_model(modelo_ridge) %>%
  add_recipe(receta_aire)

grilla_lambda <- grid_regular(
  penalty(range = c(-3, 1)),
  levels = 50
)

set.seed(2026)

tune_ridge <- tune_grid(
  wf_ridge,
  resamples = folds_aire,
  grid = grilla_lambda,
  metrics = metric_set(rmse, rsq)
)

metricas_cv_ridge <- collect_metrics(tune_ridge)

mejor_lambda <- select_best(tune_ridge, metric = "rmse")

ridge_cv_rmse <- metricas_cv_ridge %>%
  filter(.metric == "rmse")

rmse_min <- ridge_cv_rmse %>%
  filter(mean == min(mean)) %>%
  slice(1)

# Regla de un error estandar:
# Elegimos el lambda mas grande cuyo RMSE promedio cae dentro de 1 SE del
# minimo. Es mas simple porque encoge mas fuerte.
lambda_1se <- ridge_cv_rmse %>%
  filter(mean <= rmse_min$mean + rmse_min$std_err) %>%
  arrange(desc(penalty)) %>%
  slice(1) %>%
  select(penalty)

ajuste_ridge_min <- finalize_workflow(wf_ridge, mejor_lambda) %>%
  fit(data = aire_train)

ajuste_ridge_1se <- finalize_workflow(wf_ridge, lambda_1se) %>%
  fit(data = aire_train)

metricas_ridge_test <- bind_rows(
  predict(ajuste_ridge_min, new_data = aire_test) %>%
    bind_cols(aire_test %>% select(pm25_ug_m3)) %>%
    metrics(truth = pm25_ug_m3, estimate = .pred) %>%
    filter(.metric %in% c("rmse", "rsq")) %>%
    select(.metric, .estimate) %>%
    pivot_wider(names_from = .metric, values_from = .estimate) %>%
    mutate(modelo = "Ridge lambda.min tidymodels", lambda = mejor_lambda$penalty),
  predict(ajuste_ridge_1se, new_data = aire_test) %>%
    bind_cols(aire_test %>% select(pm25_ug_m3)) %>%
    metrics(truth = pm25_ug_m3, estimate = .pred) %>%
    filter(.metric %in% c("rmse", "rsq")) %>%
    select(.metric, .estimate) %>%
    pivot_wider(names_from = .metric, values_from = .estimate) %>%
    mutate(modelo = "Ridge lambda.1se tidymodels", lambda = lambda_1se$penalty)
)

metricas_ridge <- bind_rows(metricas_ols, metricas_ridge_test) %>%
  transmute(modelo, lambda, rmse_test = rmse, mse_test = rmse^2, rsq_test = rsq)

metricas_ridge %>%
  write_csv("outputs/02_metricas_ridge.csv")

metricas_cv_ridge %>%
  write_csv("outputs/02_metricas_cv_ridge.csv")

print(metricas_ridge)

# 7) Comparar coeficientes ---------------------------------------------------
# Ridge no selecciona variables: los coeficientes se encogen, pero usualmente
# no son exactamente cero.
coeficientes_ridge <- tidy(ajuste_ridge_min) %>%
  filter(term != "(Intercept)") %>%
  arrange(desc(abs(estimate))) %>%
  rename(variable = term, coeficiente = estimate)

coeficientes_ridge %>%
  write_csv("outputs/02_coeficientes_ridge_lambda_min.csv")

# 8) Curva de validacion cruzada --------------------------------------------
grafico_cv_ridge <- metricas_cv_ridge %>%
  filter(.metric == "rmse") %>%
  ggplot(aes(x = penalty, y = mean)) +
  geom_line(color = "#2f6f73") +
  geom_point(size = 1.4, color = "#2f6f73") +
  geom_vline(xintercept = mejor_lambda$penalty, linetype = "dashed", color = "#7a4e9f") +
  geom_vline(xintercept = lambda_1se$penalty, linetype = "dotted", color = "#b85c38") +
  scale_x_log10() +
  labs(
    title = "Validacion cruzada para Ridge",
    x = "Lambda en escala log10",
    y = "RMSE promedio CV"
  ) +
  theme_minimal(base_size = 12)

grafico_cv_ridge

ggsave("outputs/02_cv_ridge.png", grafico_cv_ridge, width = 8, height = 5, dpi = 150)
