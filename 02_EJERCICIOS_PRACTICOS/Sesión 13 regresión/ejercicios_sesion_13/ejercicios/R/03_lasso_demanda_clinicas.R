# 03_lasso_demanda_clinicas.R
# ------------------------------------------------------------
# Historia:
# Una red de clinicas comunitarias quiere anticipar consultas semanales de
# urgencias respiratorias. Hay muchas variables candidatas: clima, movilidad,
# busquedas web, contaminantes, calendario y senales administrativas. Solo
# algunas importan de verdad. Lasso es natural cuando esperamos esparsidad.
#
# Fundamentos ISLR que se practican:
# - Lasso con penalizacion L1
# - Seleccion automatica de variables
# - Validacion cruzada para lambda
# - Regla de un error estandar: modelo mas simple con error cercano al minimo
# - Comparacion con OLS cuando hay muchos predictores
#
# Estilo tidymodels:
# - initial_time_split() para separar pasado/futuro
# - recipe() para preprocesamiento
# - linear_reg(penalty = tune(), mixture = 1) para lasso
# - tune_grid(), finalize_workflow(), tidy()
# ------------------------------------------------------------

library(tidyverse)
library(tidymodels)

tidymodels_prefer()
set.seed(2026)

if (!file.exists("data/clinicas_respiratorias_sintetica.csv") || !dir.exists("outputs")) {
  stop("Primero corre R/00_preparar_proyecto_y_datos.R desde el proyecto ejercicios.")
}

# 1) Leer datos --------------------------------------------------------------
# Metadatos:
# - Unidad de observacion: una semana calendario en una red de clinicas.
# - Variable respuesta: consultas_respiratorias, conteo semanal de consultas.
# - Senales epidemiologicas y ambientales: frio, influenza_google,
#   busquedas_lag1, pm25, pm25_lag1, humedad, lluvia_mm y rezagos.
# - Senales operativas y calendario: movilidad_transporte, dias_feriados,
#   vacunacion_pct, school_in_session, tendencia y semana_del_anio.
# - Variables con posible ruido: llamadas_info, ocupacion_hospitalaria_general,
#   costo_transporte, ruido_redes_sociales y ruido_administrativo.
# - semana ordena el tiempo; se usa para la particion temporal y se excluye
#   del modelado.
clinicas <- read_csv("data/clinicas_respiratorias_sintetica.csv", show_col_types = FALSE) %>%
  mutate(semana = as.Date(semana))

# 2) Separacion temporal entrenamiento/prueba --------------------------------
# En problemas con tiempo, conviene evaluar en semanas futuras.
split_clinicas <- initial_time_split(clinicas, prop = .75)

clinicas_train <- training(split_clinicas) %>% select(-semana)
clinicas_test <- testing(split_clinicas) %>% select(-semana)

# 3) Receta compartida -------------------------------------------------------
receta_clinicas <- recipe(consultas_respiratorias ~ ., data = clinicas_train) %>%
  step_zv(all_predictors()) %>%
  step_normalize(all_numeric_predictors())
# ?step_zv
# 4) OLS como comparacion ----------------------------------------------------
wf_ols <- workflow() %>%
  add_model(linear_reg() %>% set_engine("lm")) %>%
  add_recipe(receta_clinicas)

ajuste_ols <- fit(wf_ols, data = clinicas_train)

metricas_ols <- predict(ajuste_ols, new_data = clinicas_test) %>%
  bind_cols(clinicas_test %>% select(consultas_respiratorias)) %>%
  metrics(truth = consultas_respiratorias, estimate = .pred) %>%
  filter(.metric %in% c("rmse", "rsq")) %>%
  select(.metric, .estimate) %>%
  pivot_wider(names_from = .metric, values_from = .estimate) %>%
  mutate(modelo = "OLS tidymodels", lambda = NA_real_)

# 5) Lasso con validacion cruzada -------------------------------------------
set.seed(2026)

folds_clinicas <- vfold_cv(clinicas_train, v = 10)

modelo_lasso <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")

wf_lasso <- workflow() %>%
  add_model(modelo_lasso) %>%
  add_recipe(receta_clinicas)

grilla_lambda <- grid_regular(
  penalty(range = c(-3, 1)),
  levels = 50
)

set.seed(2026)

tune_lasso <- tune_grid(
  wf_lasso,
  resamples = folds_clinicas,
  grid = grilla_lambda,
  metrics = metric_set(rmse, rsq)
)

metricas_cv_lasso <- collect_metrics(tune_lasso)
mejor_lambda <- select_best(tune_lasso, metric = "rmse")

lasso_cv_rmse <- metricas_cv_lasso %>%
  filter(.metric == "rmse")

rmse_min <- lasso_cv_rmse %>%
  filter(mean == min(mean)) %>%
  slice(1)

lambda_1se <- lasso_cv_rmse %>%
  filter(mean <= rmse_min$mean + rmse_min$std_err) %>%
  arrange(desc(penalty)) %>%
  slice(1) %>%
  select(penalty)

ajuste_lasso_min <- finalize_workflow(wf_lasso, mejor_lambda) %>%
  fit(data = clinicas_train)

ajuste_lasso_1se <- finalize_workflow(wf_lasso, lambda_1se) %>%
  fit(data = clinicas_train)

metricas_lasso_test <- bind_rows(
  predict(ajuste_lasso_min, new_data = clinicas_test) %>%
    bind_cols(clinicas_test %>% select(consultas_respiratorias)) %>%
    metrics(truth = consultas_respiratorias, estimate = .pred) %>%
    filter(.metric %in% c("rmse", "rsq")) %>%
    select(.metric, .estimate) %>%
    pivot_wider(names_from = .metric, values_from = .estimate) %>%
    mutate(modelo = "Lasso lambda.min tidymodels", lambda = mejor_lambda$penalty),
  predict(ajuste_lasso_1se, new_data = clinicas_test) %>%
    bind_cols(clinicas_test %>% select(consultas_respiratorias)) %>%
    metrics(truth = consultas_respiratorias, estimate = .pred) %>%
    filter(.metric %in% c("rmse", "rsq")) %>%
    select(.metric, .estimate) %>%
    pivot_wider(names_from = .metric, values_from = .estimate) %>%
    mutate(modelo = "Lasso lambda.1se tidymodels", lambda = lambda_1se$penalty)
)

metricas_lasso <- bind_rows(metricas_ols, metricas_lasso_test) %>%
  transmute(modelo, lambda, rmse_test = rmse, mse_test = rmse^2, rsq_test = rsq)

metricas_lasso %>%
  write_csv("outputs/03_metricas_lasso.csv")

metricas_cv_lasso %>%
  write_csv("outputs/03_metricas_cv_lasso.csv")

print(metricas_lasso)

# 6) Variables seleccionadas -------------------------------------------------
extraer_coeficientes <- function(ajuste, nombre_modelo) {
  tidy(ajuste) %>%
    filter(term != "(Intercept)") %>%
    transmute(
      modelo = nombre_modelo,
      variable = term,
      coeficiente = estimate
    ) %>%
    arrange(desc(abs(coeficiente)))
}

coef_lasso <- bind_rows(
  extraer_coeficientes(ajuste_lasso_min, "lambda.min"),
  extraer_coeficientes(ajuste_lasso_1se, "lambda.1se")
)

coef_lasso %>%
  write_csv("outputs/03_coeficientes_lasso.csv")

coef_lasso %>%
  filter(coeficiente != 0) %>%
  print(n = Inf)

# 7) Visualizar seleccion ----------------------------------------------------
grafico_coeficientes <- coef_lasso %>%
  filter(coeficiente != 0) %>%
  mutate(variable = fct_reorder(variable, abs(coeficiente))) %>%
  ggplot(aes(x = coeficiente, y = variable, fill = modelo)) +
  geom_col(position = "dodge") +
  labs(
    title = "Variables seleccionadas por Lasso",
    subtitle = "Coeficientes distintos de cero despues de la penalizacion L1",
    x = "Coeficiente",
    y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

grafico_coeficientes

ggsave("outputs/03_coeficientes_lasso.png", grafico_coeficientes, width = 8, height = 5, dpi = 150)

grafico_cv_lasso <- metricas_cv_lasso %>%
  filter(.metric == "rmse") %>%
  ggplot(aes(x = penalty, y = mean)) +
  geom_line(color = "#2f6f73") +
  geom_point(size = 1.4, color = "#2f6f73") +
  geom_vline(xintercept = mejor_lambda$penalty, linetype = "dashed", color = "#7a4e9f") +
  geom_vline(xintercept = lambda_1se$penalty, linetype = "dotted", color = "#b85c38") +
  scale_x_log10() +
  labs(
    title = "Validacion cruzada para Lasso",
    x = "Lambda en escala log10",
    y = "RMSE promedio CV"
  ) +
  theme_minimal(base_size = 12)

grafico_cv_lasso

ggsave("outputs/03_cv_lasso.png", grafico_cv_lasso, width = 8, height = 5, dpi = 150)
