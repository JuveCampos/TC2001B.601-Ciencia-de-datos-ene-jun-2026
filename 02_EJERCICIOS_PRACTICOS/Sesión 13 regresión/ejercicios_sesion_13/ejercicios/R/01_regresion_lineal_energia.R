# 01_regresion_lineal_energia.R
# ------------------------------------------------------------
# Historia:
# Una cooperativa energetica quiere explicar el consumo mensual de
# electricidad de hogares urbanos. El ejemplo esta inspirado en estudios
# reales de demanda residencial: clima, tamano de vivienda, ocupantes,
# eficiencia energetica y tipo de aislamiento suelen afectar el consumo.
#
# Fundamentos ISLR que se practican:
# - Regresion lineal multiple
# - Interpretacion "manteniendo fijos los demas predictores"
# - Variables dummy para predictores cualitativos
# - Terminos de interaccion
# - RSE, R^2, R^2 ajustado, RSS y RMSE de prueba
# - Diagnostico visual de residuos
#
# Estilo tidymodels:
# - initial_split(), training(), testing()
# - recipe() para preprocesamiento
# - linear_reg() + workflow()
# - fit(), predict(), metrics()
# ------------------------------------------------------------

library(tidyverse)
library(tidymodels)

tidymodels_prefer()
set.seed(2026)

if (!file.exists("data/energia_hogares_sintetica.csv") || !dir.exists("outputs")) {
  stop("Primero corre R/00_preparar_proyecto_y_datos.R desde el proyecto ejercicios.")
}

# 1) Leer datos --------------------------------------------------------------
# Metadatos:
# - Unidad de observacion: un hogar urbano durante un mes.
# - Variable respuesta: consumo_kwh, consumo electrico mensual en kWh.
# - Predictores climaticos y de vivienda: temp_promedio_c, grados_calor,
#   metros_cuadrados, ocupantes y antiguedad_anios.
# - Predictores cualitativos: aislamiento y tarifa_horaria.
# - hogar_id es solo un identificador; se elimina en la receta antes de modelar.
energia <- read_csv("data/energia_hogares_sintetica.csv", show_col_types = FALSE) %>%
  mutate(
    aislamiento = factor(aislamiento, levels = c("basico", "medio", "alto")),
    tarifa_horaria = factor(tarifa_horaria, levels = c("fija", "variable"))
  )

# 2) Separar entrenamiento y prueba con rsample -----------------------------
set.seed(2026)

split_energia <- initial_split(energia, prop = .75)
energia_train <- training(split_energia)
energia_test <- testing(split_energia)

# 3) Recetas: modelo base y modelo con interaccion --------------------------
# step_rm() evita usar el identificador del hogar como predictor.
# step_dummy() crea variables indicadoras para factores.
receta_base <- recipe(
  consumo_kwh ~ hogar_id + grados_calor + metros_cuadrados + ocupantes +
    antiguedad_anios + aislamiento + tarifa_horaria,
  data = energia_train
) %>%
  # ?step_rm
  step_rm(hogar_id) %>%
  step_dummy(all_nominal_predictors())

receta_interaccion <- recipe(
  consumo_kwh ~ hogar_id + grados_calor + metros_cuadrados + aislamiento +
    ocupantes + antiguedad_anios + tarifa_horaria,
  data = energia_train
) %>%
  step_rm(hogar_id) %>%
  step_dummy(all_nominal_predictors()) %>%
  # En recipes las interacciones se agregan como pasos explicitos.
  # El principio jerarquico se mantiene porque los efectos principales ya
  # estan en la receta antes de crear los productos.
  step_interact(terms = ~ metros_cuadrados:starts_with("aislamiento_"))

modelo_lm <- linear_reg() %>%
  set_engine("lm")

wf_base <- workflow() %>%
  add_model(modelo_lm) %>%
  add_recipe(receta_base)

wf_interaccion <- workflow() %>%
  add_model(modelo_lm) %>%
  add_recipe(receta_interaccion)

ajuste_base <- fit(wf_base, data = energia_train)
ajuste_interaccion <- fit(wf_interaccion, data = energia_train)

# 4) Revisar inferencia clasica desde el motor lm ---------------------------
# tidymodels organiza el flujo, pero podemos extraer el objeto lm cuando
# queremos summary(), anova(), residuos estudentizados o leverage.
lm_base <- extract_fit_engine(ajuste_base)
lm_interaccion <- extract_fit_engine(ajuste_interaccion)

summary(lm_base)
summary(lm_interaccion)
anova(lm_base, lm_interaccion)

# 5) Metricas de entrenamiento y prueba -------------------------------------
calcular_metricas_lm <- function(ajuste, datos_test, nombre_modelo) {
  lm_engine <- extract_fit_engine(ajuste)

  pred_test <- predict(ajuste, new_data = datos_test) %>%
    bind_cols(datos_test %>% select(consumo_kwh))

  rss_train <- sum(residuals(lm_engine)^2)
  n_train <- nobs(lm_engine)
  p_modelo <- length(coef(lm_engine)) - 1
  rse_train <- sqrt(rss_train / (n_train - p_modelo - 1))
  resumen_ajuste <- summary(lm_engine)

  pred_test %>%
    metrics(truth = consumo_kwh, estimate = .pred) %>%
    select(.metric, .estimate) %>%
    pivot_wider(names_from = .metric, values_from = .estimate) %>%
    transmute(
      modelo = nombre_modelo,
      rse_train = rse_train,
      r2_train = resumen_ajuste$r.squared,
      r2_ajustado_train = resumen_ajuste$adj.r.squared,
      mse_test = rmse^2,
      rmse_test = rmse,
      rsq_test = rsq
    )
}

metricas_lm <- bind_rows(
  calcular_metricas_lm(ajuste_base, energia_test, "OLS base tidymodels"),
  calcular_metricas_lm(ajuste_interaccion, energia_test, "OLS con interaccion tidymodels")
)

metricas_lm %>%
  write_csv("outputs/01_metricas_regresion_lineal.csv")

print(metricas_lm)

# 6) Diagnosticos visuales ---------------------------------------------------
diagnosticos <- energia_train %>%
  select(hogar_id, consumo_kwh) %>%
  bind_cols(
    tibble(
      ajustado = fitted(lm_interaccion),
      residuo = residuals(lm_interaccion),
      residuo_estudentizado = rstandard(lm_interaccion),
      leverage = hatvalues(lm_interaccion)
    )
  )

grafico_residuos <- diagnosticos %>%
  ggplot(aes(x = ajustado, y = residuo)) +
  geom_hline(yintercept = 0, linewidth = 0.6, color = "gray45") +
  geom_point(alpha = 0.65, color = "#2f6f73") +
  labs(
    title = "Residuos vs. valores ajustados",
    subtitle = "Buscar patrones: curvatura, embudo o puntos extremos",
    x = "Consumo ajustado por el modelo",
    y = "Residuo"
  ) +
  theme_minimal(base_size = 12)

grafico_residuos

ggsave("outputs/01_residuos_vs_ajustados.png", grafico_residuos, width = 8, height = 5, dpi = 150)

grafico_predicciones <- predict(ajuste_interaccion, new_data = energia_test) %>%
  bind_cols(energia_test %>% select(consumo_kwh)) %>%
  ggplot(aes(x = consumo_kwh, y = .pred)) +
  geom_abline(slope = 1, intercept = 0, linewidth = 0.7, color = "gray45") +
  geom_point(alpha = 0.70, color = "#7a4e9f") +
  coord_equal() +
  labs(
    title = "Prediccion en datos de prueba",
    x = "Consumo real kWh",
    y = "Consumo predicho kWh"
  ) +
  theme_minimal(base_size = 12)

grafico_predicciones

ggsave("outputs/01_predicciones_test.png", grafico_predicciones, width = 6, height = 6, dpi = 150)

diagnosticos %>%
  filter(abs(residuo_estudentizado) > 3 | leverage > 2 * mean(leverage)) %>%
  arrange(desc(abs(residuo_estudentizado))) %>%
  select(hogar_id, consumo_kwh, ajustado, residuo_estudentizado, leverage) %>%
  write_csv("outputs/01_puntos_a_revisar.csv")
