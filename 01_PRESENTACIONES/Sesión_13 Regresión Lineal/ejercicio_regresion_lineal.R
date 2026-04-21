# =============================================================
# Ejercicio Práctico: Regresión Lineal
# Ciencia de Datos para las Ciencias Sociales (TC2001B.601)
# Tecnológico de Monterrey
# Profesor: Jorge Juvenal Campos Ferreira
# Fecha: 2026-03-23
# =============================================================
# Este script cubre regresión lineal simple, múltiple,
# diagnósticos, predicción y regularización (Ridge/Lasso)
# usando datos simulados de municipios mexicanos.
# =============================================================

# ----- 1. SETUP: Carga de librerías -------------------------
library(tidyverse)
library(broom)
library(glmnet)
library(caret)

# ----- 2. SIMULACIÓN DE DATOS --------------------------------
# Simulamos datos de 500 municipios mexicanos con variables
# socioeconómicas que podrían predecir el ingreso municipal.

set.seed(42)
n <- 500

municipios <- tibble(
  id_municipio = 1:n,

  # Región del país (categórica)
  region = sample(
    c("norte", "centro", "sur"),
    n, replace = TRUE,
    prob = c(0.3, 0.4, 0.3)
  ),

  # Género predominante del jefe de hogar (categórica)
  genero_jefe = sample(
    c("hombre", "mujer"),
    n, replace = TRUE,
    prob = c(0.65, 0.35)
  ),

  # Tasa de educación superior (%)
  tasa_educacion = rnorm(n, mean = 25, sd = 10) %>%
    pmax(2) %>% pmin(60),

  # Índice de ocupación formal (%)
  indice_ocupacion = rnorm(n, mean = 55, sd = 15) %>%
    pmax(10) %>% pmin(95),

  # Población urbana (%)
  pob_urbana = rnorm(n, mean = 60, sd = 20) %>%
    pmax(5) %>% pmin(99),

  # Acceso a servicios básicos (índice 0-100)
  acceso_servicios = rnorm(n, mean = 65, sd = 18) %>%
    pmax(0) %>% pmin(100),

  # Gasto estatal en inversión (millones de pesos)
  gasto_estatal = rnorm(n, mean = 150, sd = 50) %>%
    pmax(20)
)

# Creamos la variable dependiente: ingreso municipal
# con efectos conocidos para poder verificar el modelo
municipios <- municipios %>%
  mutate(
    # Efecto de región
    efecto_region = case_when(
      region == "norte"  ~  15,
      region == "centro" ~   5,
      region == "sur"    ~ -10
    ),
    # Efecto de género del jefe de hogar
    efecto_genero = if_else(
      genero_jefe == "mujer", -8, 0
    ),
    # Variable dependiente: ingreso municipal (millones)
    ingreso_municipal = 50 +
      1.8  * tasa_educacion +
      0.9  * indice_ocupacion +
      0.5  * pob_urbana +
      0.3  * acceso_servicios +
      0.15 * gasto_estatal +
      efecto_region +
      efecto_genero +
      rnorm(n, 0, 12)
  ) %>%
  # Eliminamos columnas auxiliares
  select(-efecto_region, -efecto_genero)

# Introducimos valores faltantes deliberadamente (~5%)
set.seed(123)
indices_na <- sample(1:n, 25)
municipios$tasa_educacion[indices_na[1:8]] <- NA
municipios$indice_ocupacion[indices_na[9:15]] <- NA
municipios$acceso_servicios[indices_na[16:20]] <- NA
municipios$gasto_estatal[indices_na[21:25]] <- NA

# Vistazo rápido a los datos
glimpse(municipios)

# ----- 3. ANÁLISIS EXPLORATORIO ------------------------------

# 3.1 Estadísticas descriptivas
summary(municipios)

# Resumen por región
municipios %>%
  group_by(region) %>%
  summarise(
    n = n(),
    ingreso_media = mean(ingreso_municipal, na.rm = TRUE),
    ingreso_sd = sd(ingreso_municipal, na.rm = TRUE),
    educacion_media = mean(tasa_educacion, na.rm = TRUE),
    .groups = "drop"
  )

# 3.2 Matriz de correlación (solo variables numéricas)
vars_numericas <- municipios %>%
  select(where(is.numeric), -id_municipio) %>%
  drop_na()

cor_matrix <- cor(vars_numericas)
print(round(cor_matrix, 2))

# 3.3 Scatter plots exploratorios
ggplot(municipios, aes(x = tasa_educacion,
                       y = ingreso_municipal)) +
  geom_point(alpha = 0.5, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE,
              color = "firebrick") +
  labs(
    title = "Educación vs Ingreso Municipal",
    x = "Tasa de educación superior (%)",
    y = "Ingreso municipal (millones)"
  ) +
  theme_minimal()

ggplot(municipios, aes(x = indice_ocupacion,
                       y = ingreso_municipal,
                       color = region)) +
  geom_point(alpha = 0.5) +
  labs(
    title = "Ocupación vs Ingreso por Región",
    x = "Índice de ocupación formal (%)",
    y = "Ingreso municipal (millones)"
  ) +
  theme_minimal()

# ----- 4. PREPARACIÓN DE DATOS -------------------------------

# 4.1 Revisar valores faltantes
municipios %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(),
               names_to = "variable",
               values_to = "n_na") %>%
  filter(n_na > 0)

# Opción A: Eliminar filas con NA (na.omit)
datos_completos_a <- municipios %>% drop_na()
# Se pierden filas:
print(paste("Filas originales:", nrow(municipios),
            "| Filas completas:", nrow(datos_completos_a)))

# Opción B: Imputar con la mediana (más conservador)
datos <- municipios %>%
  mutate(across(
    where(is.numeric),
    ~if_else(is.na(.), median(., na.rm = TRUE), .)
  ))

# Verificar que ya no hay NAs
sum(is.na(datos))

# 4.2 Convertir categóricas a factor
datos <- datos %>%
  mutate(
    region = factor(region,
                    levels = c("centro", "norte", "sur")),
    genero_jefe = factor(genero_jefe,
                         levels = c("hombre", "mujer"))
  )

# Revisamos los niveles de referencia
# "centro" será la referencia para región
# "hombre" será la referencia para género
levels(datos$region)
levels(datos$genero_jefe)

# 4.3 División entrenamiento / prueba (80/20)
set.seed(2026)
indices_train <- createDataPartition(
  datos$ingreso_municipal, p = 0.8, list = FALSE
)
train <- datos[indices_train, ]
test  <- datos[-indices_train, ]

print(paste("Entrenamiento:", nrow(train),
            "| Prueba:", nrow(test)))

# ----- 5. REGRESIÓN LINEAL SIMPLE ----------------------------
# Predecimos ingreso municipal usando solo tasa de educación

modelo_simple <- lm(
  ingreso_municipal ~ tasa_educacion,
  data = train
)

# Resumen completo del modelo
summary(modelo_simple)

# Interpretación del summary():
# - (Intercept) = valor esperado de ingreso cuando
#   tasa_educacion = 0
# - tasa_educacion = por cada punto porcentual adicional
#   de educación, el ingreso aumenta en ~X millones
# - Pr(>|t|) = p-value; si < 0.05, la variable es
#   estadísticamente significativa
# - Multiple R-squared = proporción de varianza explicada

# Visualización de la regresión simple
ggplot(train, aes(x = tasa_educacion,
                  y = ingreso_municipal)) +
  geom_point(alpha = 0.4, color = "gray40") +
  geom_smooth(method = "lm", se = TRUE,
              color = "dodgerblue", fill = "lightblue") +
  labs(
    title = "Regresión Simple: Educación → Ingreso",
    subtitle = paste(
      "R² =",
      round(summary(modelo_simple)$r.squared, 3)
    ),
    x = "Tasa de educación superior (%)",
    y = "Ingreso municipal (millones)"
  ) +
  theme_minimal()

# ----- 6. REGRESIÓN LINEAL MÚLTIPLE --------------------------
# Incluimos todas las variables predictoras

modelo_multiple <- lm(
  ingreso_municipal ~ tasa_educacion +
    indice_ocupacion + pob_urbana +
    acceso_servicios + gasto_estatal +
    genero_jefe + region,
  data = train
)

summary(modelo_multiple)

# Interpretación de coeficientes:
# - Variables numéricas: cada coeficiente indica el cambio
#   en ingreso por unidad de aumento, manteniendo las
#   demás variables constantes (ceteris paribus).
# - genero_jefemujer: diferencia promedio en ingreso
#   cuando el jefe de hogar es mujer vs hombre (ref.)
# - regionnorte: diferencia promedio vs centro (ref.)
# - regionsur: diferencia promedio vs centro (ref.)

# ----- 7. ENTENDIENDO EL OUTPUT DE summary() -----------------

resumen <- summary(modelo_multiple)

# 7.1 Residuales: diferencia entre valor real y predicho
# Un buen modelo tiene residuales simétricos alrededor de 0
resumen$residuals %>% summary()

# 7.2 Coeficientes: la tabla principal
# Columnas:
#   Estimate   = valor estimado del coeficiente (beta)
#   Std. Error = error estándar del estimador
#   t value    = Estimate / Std. Error (prueba t)
#   Pr(>|t|)   = p-value bilateral
#   Estrellas  = '***' p<0.001, '**' p<0.01,
#                '*' p<0.05, '.' p<0.1
coeficientes <- resumen$coefficients
print(round(coeficientes, 4))

# 7.3 Error estándar residual
# Desviación estándar promedio de los residuales
# Unidad: misma que la variable dependiente (millones)
print(paste("Error estándar residual:",
            round(resumen$sigma, 3)))

# 7.4 R² y R² ajustado
print(paste("R²:",
            round(resumen$r.squared, 4)))
print(paste("R² ajustado:",
            round(resumen$adj.r.squared, 4)))
# R² ajustado penaliza por agregar variables que no
# aportan; úsalo cuando compares modelos con diferente
# número de predictores.

# 7.5 Estadístico F
# Prueba la hipótesis nula de que TODOS los coeficientes
# (excepto el intercepto) son cero simultáneamente.
# Si p-value < 0.05, el modelo en conjunto es significativo.
print(paste("F-statistic:",
            round(resumen$fstatistic[1], 2),
            "| p-value:",
            format.pval(
              pf(resumen$fstatistic[1],
                 resumen$fstatistic[2],
                 resumen$fstatistic[3],
                 lower.tail = FALSE),
              digits = 3
            )))

# ----- 8. R-CUADRADA: CÁLCULO MANUAL -------------------------

y_real <- train$ingreso_municipal
y_pred <- predict(modelo_multiple, newdata = train)
y_media <- mean(y_real)

# SST = Sum of Squares Total (variabilidad total)
sst <- sum((y_real - y_media)^2)

# SSR = Sum of Squares Regression (explicada por modelo)
ssr <- sum((y_pred - y_media)^2)

# SSE = Sum of Squares Error (residual, no explicada)
sse <- sum((y_real - y_pred)^2)

# Verificación: SST = SSR + SSE
print(paste("SST:", round(sst, 2),
            "| SSR + SSE:", round(ssr + sse, 2)))

# R² = SSR / SST = 1 - SSE / SST
r2_manual <- 1 - sse / sst
print(paste("R² calculado manualmente:",
            round(r2_manual, 4)))
print(paste("R² de summary():",
            round(resumen$r.squared, 4)))

# R² ajustado: penaliza por número de predictores (p)
n_obs <- nrow(train)
p <- length(coef(modelo_multiple)) - 1  # sin intercepto
r2_adj_manual <- 1 - (1 - r2_manual) *
  (n_obs - 1) / (n_obs - p - 1)
print(paste("R² ajustado manual:",
            round(r2_adj_manual, 4)))

# ----- 9. DIAGNÓSTICOS DEL MODELO ----------------------------

# Creamos tibble de diagnósticos
diagnosticos <- tibble(
  fitted  = fitted(modelo_multiple),
  resid   = residuals(modelo_multiple),
  std_res = rstandard(modelo_multiple)
)

# 9.1 Residuales vs valores ajustados
# Buscamos: dispersión homogénea sin patrones
ggplot(diagnosticos, aes(x = fitted, y = resid)) +
  geom_point(alpha = 0.4, color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dashed",
             color = "red") +
  geom_smooth(method = "loess", se = FALSE,
              color = "orange") +
  labs(
    title = "Residuales vs Valores Ajustados",
    subtitle = "Verificar homocedasticidad",
    x = "Valores ajustados",
    y = "Residuales"
  ) +
  theme_minimal()

# 9.2 Q-Q Plot de residuales
# Verificar normalidad: puntos deben seguir la línea
ggplot(diagnosticos, aes(sample = std_res)) +
  stat_qq(alpha = 0.4, color = "steelblue") +
  stat_qq_line(color = "red") +
  labs(
    title = "Q-Q Plot de Residuales Estandarizados",
    subtitle = "Verificar normalidad de residuales",
    x = "Cuantiles teóricos",
    y = "Cuantiles observados"
  ) +
  theme_minimal()

# 9.3 Verificar heterocedasticidad
# Scale-Location: raíz de residuales estandarizados
ggplot(diagnosticos,
       aes(x = fitted,
           y = sqrt(abs(std_res)))) +
  geom_point(alpha = 0.4, color = "steelblue") +
  geom_smooth(method = "loess", se = FALSE,
              color = "orange") +
  labs(
    title = "Scale-Location",
    subtitle = "Línea plana = homocedasticidad",
    x = "Valores ajustados",
    y = expression(sqrt("|Residuales estandarizados|"))
  ) +
  theme_minimal()

# ----- 10. PREDICCIÓN -----------------------------------------

# 10.1 Predicciones en el conjunto de prueba
predicciones <- predict(
  modelo_multiple, newdata = test
)

# 10.2 Intervalos de confianza vs predicción
# Intervalo de confianza: incertidumbre sobre la MEDIA
ic <- predict(modelo_multiple, newdata = test,
              interval = "confidence", level = 0.95) %>%
  as_tibble()

# Intervalo de predicción: incertidumbre sobre un
# VALOR INDIVIDUAL (siempre más ancho)
ip <- predict(modelo_multiple, newdata = test,
              interval = "prediction", level = 0.95) %>%
  as_tibble()

# Comparar anchos promedio
print(paste(
  "Ancho medio IC:",
  round(mean(ic$upr - ic$lwr), 2),
  "| Ancho medio IP:",
  round(mean(ip$upr - ip$lwr), 2)
))

# 10.3 Métricas de evaluación en test
resultados_test <- tibble(
  real = test$ingreso_municipal,
  predicho = predicciones
)

rmse_test <- sqrt(mean(
  (resultados_test$real - resultados_test$predicho)^2
))
mae_test <- mean(
  abs(resultados_test$real - resultados_test$predicho)
)
r2_test <- 1 - sum(
  (resultados_test$real - resultados_test$predicho)^2
) / sum(
  (resultados_test$real - mean(resultados_test$real))^2
)

print(paste("RMSE en test:", round(rmse_test, 3)))
print(paste("MAE en test:", round(mae_test, 3)))
print(paste("R² en test:", round(r2_test, 4)))

# ----- 11. VISUALIZACIONES FINALES ---------------------------

# 11.1 Línea de regresión con banda de confianza
# (regresión simple para facilitar la visualización)
ggplot(train, aes(x = tasa_educacion,
                  y = ingreso_municipal)) +
  geom_point(alpha = 0.3, color = "gray50") +
  geom_smooth(method = "lm", se = TRUE,
              color = "dodgerblue",
              fill = "lightblue") +
  labs(
    title = "Regresión con Banda de Confianza",
    x = "Tasa de educación (%)",
    y = "Ingreso municipal (millones)"
  ) +
  theme_minimal()

# 11.2 Valores reales vs predichos (test)
ggplot(resultados_test, aes(x = real, y = predicho)) +
  geom_point(alpha = 0.5, color = "steelblue") +
  geom_abline(slope = 1, intercept = 0,
              linetype = "dashed", color = "red") +
  labs(
    title = "Valores Reales vs Predichos (Test)",
    subtitle = paste("R² =", round(r2_test, 3)),
    x = "Ingreso real (millones)",
    y = "Ingreso predicho (millones)"
  ) +
  coord_equal() +
  theme_minimal()

# 11.3 Distribución de residuales
ggplot(diagnosticos, aes(x = resid)) +
  geom_histogram(bins = 30, fill = "steelblue",
                 color = "white", alpha = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed",
             color = "red") +
  labs(
    title = "Distribución de Residuales",
    x = "Residuales",
    y = "Frecuencia"
  ) +
  theme_minimal()

# 11.4 Gráfica de coeficientes
coef_df <- tidy(modelo_multiple, conf.int = TRUE) %>%
  filter(term != "(Intercept)")

ggplot(coef_df, aes(x = estimate,
                    y = reorder(term, estimate))) +
  geom_point(color = "steelblue", size = 3) +
  geom_errorbarh(aes(xmin = conf.low,
                     xmax = conf.high),
                 height = 0.2, color = "steelblue") +
  geom_vline(xintercept = 0, linetype = "dashed",
             color = "red") +
  labs(
    title = "Coeficientes del Modelo Múltiple",
    subtitle = "Con intervalos de confianza al 95%",
    x = "Estimación del coeficiente",
    y = "Variable"
  ) +
  theme_minimal()

# ----- 12. RIDGE Y LASSO -------------------------------------
# Regularización: métodos que penalizan coeficientes
# grandes para evitar sobreajuste.

# Preparar matrices para glmnet
# glmnet requiere matriz numérica (sin intercepto)
x_train <- model.matrix(
  ingreso_municipal ~ tasa_educacion +
    indice_ocupacion + pob_urbana +
    acceso_servicios + gasto_estatal +
    genero_jefe + region,
  data = train
)[, -1]  # Quitar columna de intercepto

y_train <- train$ingreso_municipal

x_test <- model.matrix(
  ingreso_municipal ~ tasa_educacion +
    indice_ocupacion + pob_urbana +
    acceso_servicios + gasto_estatal +
    genero_jefe + region,
  data = test
)[, -1]

y_test <- test$ingreso_municipal

# 12.1 Ridge Regression (alpha = 0)
# Penaliza la suma de coeficientes al cuadrado (L2)
# Encoge coeficientes pero NO los hace exactamente cero
set.seed(2026)
cv_ridge <- cv.glmnet(
  x_train, y_train, alpha = 0, nfolds = 10
)

# Lambda óptimo (mínimo error de CV)
print(paste("Lambda óptimo Ridge:",
            round(cv_ridge$lambda.min, 4)))

# Predicciones Ridge
pred_ridge <- predict(
  cv_ridge, s = "lambda.min", newx = x_test
)
rmse_ridge <- sqrt(mean((y_test - pred_ridge)^2))

# 12.2 Lasso Regression (alpha = 1)
# Penaliza la suma de valores absolutos (L1)
# Puede hacer coeficientes EXACTAMENTE cero (selección)
set.seed(2026)
cv_lasso <- cv.glmnet(
  x_train, y_train, alpha = 1, nfolds = 10
)

print(paste("Lambda óptimo Lasso:",
            round(cv_lasso$lambda.min, 4)))

# Predicciones Lasso
pred_lasso <- predict(
  cv_lasso, s = "lambda.min", newx = x_test
)
rmse_lasso <- sqrt(mean((y_test - pred_lasso)^2))

# 12.3 Coeficientes Lasso: selección de variables
coef_lasso <- coef(cv_lasso, s = "lambda.min")
print("Coeficientes Lasso (lambda.min):")
print(coef_lasso)

# Variables que Lasso eliminó (coeficiente = 0)
coef_lasso_df <- as.matrix(coef_lasso) %>%
  as.data.frame() %>%
  rownames_to_column("variable") %>%
  as_tibble() %>%
  rename(coeficiente = s1)

variables_eliminadas <- coef_lasso_df %>%
  filter(coeficiente == 0, variable != "(Intercept)")

if (nrow(variables_eliminadas) > 0) {
  print("Variables eliminadas por Lasso:")
  print(variables_eliminadas$variable)
} else {
  # Todas las variables fueron retenidas
  print("Lasso retuvo todas las variables.")
}

# 12.4 Comparación OLS vs Ridge vs Lasso
comparacion <- tibble(
  Modelo = c("OLS", "Ridge", "Lasso"),
  RMSE = c(rmse_test, rmse_ridge, rmse_lasso)
)
print(comparacion)

ggplot(comparacion, aes(x = Modelo, y = RMSE,
                        fill = Modelo)) +
  geom_col(width = 0.5, show.legend = FALSE) +
  geom_text(aes(label = round(RMSE, 2)),
            vjust = -0.5) +
  labs(
    title = "Comparación de Modelos: RMSE en Test",
    y = "RMSE (millones)"
  ) +
  theme_minimal() +
  scale_fill_brewer(palette = "Set2")

# ----- 13. REPORTE DE RESULTADOS -----------------------------
# El paquete broom facilita extraer resultados en formato
# tidy (tibble) para reportar o exportar.

# 13.1 broom::tidy() - Tabla de coeficientes
tabla_coeficientes <- tidy(
  modelo_multiple, conf.int = TRUE
)
print(tabla_coeficientes)

# 13.2 broom::glance() - Métricas globales del modelo
metricas_modelo <- glance(modelo_multiple)
print(metricas_modelo)

# 13.3 Formato para reporte
# Tabla resumida lista para exportar
reporte <- tabla_coeficientes %>%
  mutate(
    across(where(is.numeric), ~round(., 3)),
    significancia = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01  ~ "**",
      p.value < 0.05  ~ "*",
      p.value < 0.1   ~ ".",
      TRUE            ~ ""
    )
  ) %>%
  select(term, estimate, std.error, statistic,
         p.value, significancia, conf.low, conf.high)

print(reporte)

# 13.4 Redacción de resultados en texto
# Ejemplo de cómo reportar en un artículo:
r2 <- round(resumen$r.squared, 3)
r2_adj <- round(resumen$adj.r.squared, 3)
f_stat <- round(resumen$fstatistic[1], 2)
f_df1 <- resumen$fstatistic[2]
f_df2 <- resumen$fstatistic[3]

print(paste0(
  "El modelo de regresión múltiple explicó el ",
  r2 * 100, "% de la varianza del ingreso municipal ",
  "(R² = ", r2, ", R² ajustado = ", r2_adj,
  ", F(", f_df1, ", ", f_df2, ") = ", f_stat,
  ", p < 0.001). ",
  "La tasa de educación fue el predictor más fuerte ",
  "(β = ",
  round(
    tabla_coeficientes$estimate[
      tabla_coeficientes$term == "tasa_educacion"
    ], 3
  ),
  ", p < 0.001)."
))

# =============================================================
# RESUMEN FINAL
# =============================================================
# En este ejercicio aprendimos a:
# 1. Simular datos con estructura conocida
# 2. Explorar datos antes de modelar
# 3. Ajustar regresiones simples y múltiples con lm()
# 4. Interpretar CADA elemento del summary()
# 5. Calcular R² manualmente (SST, SSR, SSE)
# 6. Diagnosticar supuestos con gráficas de residuales
# 7. Predecir y evaluar con RMSE, MAE, R²
# 8. Aplicar regularización (Ridge y Lasso)
# 9. Reportar resultados con broom
# =============================================================
