# =============================================================================
# ESTADÍSTICA DESCRIPTIVA Y ANÁLISIS EXPLORATORIO (EDA)
# Ciencia de datos para la toma de decisiones I — Sesión 10
# Juvenal Campos Ferreira | juvenal@claveigualdad.org
# =============================================================================
# Dataset: datos_empleados.csv
# 300 observaciones, 12 variables
# Cubre: centralidad, dispersión, distribuciones, cuartiles, outliers,
#        correlación y manejo de NAs
# =============================================================================


# ── 0. LIBRERÍAS ──────────────────────────────────────────────────────────────

library(tidyverse)   # dplyr, ggplot2, readr, tidyr, forcats, stringr
library(moments)     # skewness(), kurtosis()
library(corrplot)    # corrplot() para visualizar matriz de correlación
library(naniar)      # vis_miss() para visualizar NAs


# ── 1. CARGA DE DATOS ─────────────────────────────────────────────────────────

# Usar readr::read_csv (tidyverse) en lugar de base read.csv
datos <- read_csv(
  "datos_empleados.csv",
  col_types = cols(
    id                  = col_integer(),
    edad                = col_integer(),
    genero              = col_factor(),
    region              = col_factor(),
    nivel_educacion     = col_factor(
      levels = c("Secundaria", "Preparatoria", "Licenciatura",
                 "Posgrado", "Doctorado"),
      ordered = TRUE
    ),
    departamento        = col_factor(),
    años_experiencia    = col_integer(),
    ingreso_mensual     = col_double(),
    gastos_mensual      = col_double(),
    score_desempeño     = col_double(),
    horas_extras_semana = col_double(),
    num_dependientes    = col_integer()
  )
)


# ── 2. EXPLORACIÓN INICIAL ────────────────────────────────────────────────────

# Vista rápida de las primeras y últimas filas
print("--- Primeras 6 filas ---")
print(head(datos))

print("--- Últimas 6 filas ---")
print(tail(datos))

# Estructura del tibble: tipos de cada columna
glimpse(datos)

# Dimensiones: filas x columnas
print(paste("Dimensiones:", nrow(datos), "filas x", ncol(datos), "columnas"))

# Nombres de columnas
print(names(datos))


# ── 3. FUNCIÓN summary(): VISTA GENERAL ───────────────────────────────────────
# summary() es el atajo más rápido del EDA.
# Para numéricos: Min, Q1, Mediana, Media, Q3, Máx y NAs.
# Para factores: conteo por categoría.

# 3a. Para todo el data frame
print("--- summary() de todo el dataset ---")
print(summary(datos))

# 3b. Para un solo vector numérico (ingreso_mensual)
print("--- summary() de ingreso_mensual ---")
print(summary(datos$ingreso_mensual))


# ── 4. MEDIDAS DE CENTRALIDAD ─────────────────────────────────────────────────
# ¿Hacia dónde está el "centro" de los datos?

# 4a. Media (mean) — sensible a outliers
media_ingreso <- mean(datos$ingreso_mensual, na.rm = TRUE)
print(paste("Media ingreso mensual: $", round(media_ingreso, 0)))

# 4b. Mediana (median) — robusta a outliers
mediana_ingreso <- median(datos$ingreso_mensual, na.rm = TRUE)
print(paste("Mediana ingreso mensual: $", round(mediana_ingreso, 0)))

# Comparar media vs mediana revela el sesgo: media >> mediana → sesgo derecho
print(paste(
  "Diferencia media - mediana:",
  round(media_ingreso - mediana_ingreso, 0),
  "(indica sesgo positivo/derecho)"
))

# 4c. Moda — se calcula manualmente (base R no tiene función directa)
# Para datos categóricos (región)
tabla_region <- table(datos$region)
moda_region  <- names(which.max(tabla_region))
print(paste("Moda de región:", moda_region))

# Para datos numéricos discretos (num_dependientes)
tabla_dep  <- table(datos$num_dependientes)
moda_dep   <- names(which.max(tabla_dep))
print(paste("Moda de dependientes:", moda_dep))

# 4d. Rango medio = (min + max) / 2
# Muy sensible a valores extremos
rango_min   <- min(datos$ingreso_mensual, na.rm = TRUE)
rango_max   <- max(datos$ingreso_mensual, na.rm = TRUE)
rango_medio <- (rango_min + rango_max) / 2
print(paste("Rango medio ingreso mensual: $", round(rango_medio, 0)))

# 4e. Tabla resumen de centralidad por variable numérica con dplyr
tabla_centralidad <- datos %>%
  summarise(
    across(
      c(edad, ingreso_mensual, score_desempeño, horas_extras_semana),
      list(
        media   = ~ mean(.x, na.rm = TRUE),
        mediana = ~ median(.x, na.rm = TRUE),
        min     = ~ min(.x, na.rm = TRUE),
        max     = ~ max(.x, na.rm = TRUE)
      ),
      .names = "{.col}__{.fn}"
    )
  ) %>%
  pivot_longer(
    everything(),
    names_to  = c("variable", "estadístico"),
    names_sep = "__"
  ) %>%
  pivot_wider(names_from = estadístico, values_from = value) %>%
  mutate(across(where(is.numeric), ~ round(.x, 1)))

print("--- Medidas de centralidad ---")
print(tabla_centralidad)


# ── 5. MEDIDAS DE DISPERSIÓN ──────────────────────────────────────────────────
# ¿Cuánta variabilidad hay en los datos?

# 5a. Varianza
varianza_ing <- var(datos$ingreso_mensual, na.rm = TRUE)
print(paste("Varianza ingreso: $²", format(round(varianza_ing), big.mark = ",")))

# 5b. Desviación estándar (mismas unidades que los datos)
sd_ing <- sd(datos$ingreso_mensual, na.rm = TRUE)
print(paste("Desviación estándar ingreso: $", round(sd_ing, 0)))

# 5c. Coeficiente de Variación (CV): permite comparar variabilidad
#     entre variables de distintas escalas
cv_ingreso <- sd_ing / media_ingreso
cv_score   <- sd(datos$score_desempeño, na.rm = TRUE) /
              mean(datos$score_desempeño, na.rm = TRUE)
print(paste("CV ingreso mensual:    ", round(cv_ingreso, 3)))
print(paste("CV score desempeño:    ", round(cv_score, 3)))
# CV alto (~1+) indica alta dispersión relativa; bajo (<0.3) es homogéneo

# 5d. Rango (max - min)
rango_ing <- diff(range(datos$ingreso_mensual, na.rm = TRUE))
print(paste("Rango ingreso mensual: $", format(rango_ing, big.mark = ",")))

# 5e. Desviación media: promedio de las distancias de cada dato a la media
#     = cuánto se aleja un valor típico de la media, en promedio
desv_media_ing <- datos %>%
  filter(!is.na(ingreso_mensual)) %>%
  summarise(dm = mean(abs(ingreso_mensual - mean(ingreso_mensual))))

print(paste("Desviación media ingreso: $", round(desv_media_ing$dm, 0)))

# 5f. Tabla comparativa de dispersión
tabla_dispersion <- datos %>%
  summarise(
    across(
      c(edad, ingreso_mensual, score_desempeño,
        horas_extras_semana, años_experiencia),
      list(
        sd    = ~ sd(.x, na.rm = TRUE),
        var   = ~ var(.x, na.rm = TRUE),
        cv    = ~ sd(.x, na.rm = TRUE) / mean(.x, na.rm = TRUE),
        rango = ~ diff(range(.x, na.rm = TRUE))
      ),
      .names = "{.col}__{.fn}"
    )
  ) %>%
  pivot_longer(
    everything(),
    names_to  = c("variable", "estadístico"),
    names_sep = "__"
  ) %>%
  pivot_wider(names_from = estadístico, values_from = value) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

print("--- Medidas de dispersión ---")
print(tabla_dispersion)


# ── 6. DISTRIBUCIONES DE DATOS ────────────────────────────────────────────────
# ¿Cómo se distribuyen los datos alrededor del centro?
# Las distribuciones a visualizar:
#   • edad              → Normal (campana)
#   • ingreso_mensual   → Sesgada derecha (log-normal)
#   • score_desempeño   → Sesgada izquierda (mayoría puntajes altos)
#   • horas_extras      → Bimodal (dos grupos)

# 6a. Visualización de las 4 distribuciones en un panel 2x2
datos_largo <- datos %>%
  select(edad, ingreso_mensual, score_desempeño, horas_extras_semana) %>%
  pivot_longer(
    everything(),
    names_to  = "variable",
    values_to = "valor"
  ) %>%
  mutate(
    variable = recode(variable,
      "edad"               = "Edad (Normal)",
      "ingreso_mensual"    = "Ingreso Mensual (Sesgada Derecha)",
      "score_desempeño"    = "Score Desempeño (Sesgada Izquierda)",
      "horas_extras_semana" = "Horas Extras (Bimodal)"
    )
  )

grafico_distribuciones <- ggplot(datos_largo, aes(x = valor)) +
  geom_histogram(
    aes(y = after_stat(density)),
    bins = 30,
    fill = "#2E86AB",
    color = "white",
    alpha = 0.85
  ) +
  geom_density(
    color = "#E84855",
    linewidth = 0.9,
    na.rm = TRUE
  ) +
  facet_wrap(~ variable, scales = "free", ncol = 2) +
  labs(
    title    = "Distribuciones de variables numéricas",
    subtitle = "Histograma + curva de densidad",
    x        = "Valor",
    y        = "Densidad"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold"),
    strip.text    = element_text(face = "bold", size = 9),
    panel.spacing = unit(1.2, "lines")
  )

print(grafico_distribuciones)
ggsave("plot_distribuciones.png", grafico_distribuciones,
       width = 10, height = 7, dpi = 150)

# 6b. Sesgo (skewness): negativo=izq, 0=simétrico, positivo=der
sesgo_vars <- datos %>%
  summarise(
    edad_sesgo       = skewness(edad, na.rm = TRUE),
    ingreso_sesgo    = skewness(ingreso_mensual, na.rm = TRUE),
    score_sesgo      = skewness(score_desempeño, na.rm = TRUE),
    horas_sesgo      = skewness(horas_extras_semana, na.rm = TRUE)
  )
print("--- Sesgo (skewness) de variables ---")
print(round(sesgo_vars, 3))

# 6c. QQ-plot para evaluar normalidad de 'edad'
grafico_qq <- datos %>%
  filter(!is.na(edad)) %>%
  ggplot(aes(sample = edad)) +
  stat_qq(color = "#2E86AB", alpha = 0.6) +
  stat_qq_line(color = "#E84855", linewidth = 1) +
  labs(
    title    = "QQ-Plot: Edad vs. Distribución Normal Teórica",
    subtitle = "Los puntos sobre la línea indican distribución normal",
    x        = "Cuantiles teóricos",
    y        = "Cuantiles observados (edad)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

print(grafico_qq)
ggsave("plot_qqplot_edad.png", grafico_qq, width = 7, height = 5, dpi = 150)


# ── 7. CUARTILES Y PERCENTILES ────────────────────────────────────────────────
# Dividen los datos ordenados en secciones del 25%

# 7a. Cuartiles de ingreso_mensual
cuartiles_ing <- quantile(datos$ingreso_mensual, na.rm = TRUE)
print("--- Cuartiles de ingreso_mensual ---")
print(cuartiles_ing)

# Interpretar cada cuartil
print(paste("Q1 = $", cuartiles_ing["25%"],
            "→ 25% de empleados ganan menos de esta cifra"))
print(paste("Q2 = $", cuartiles_ing["50%"],
            "→ Mediana: mitad gana más, mitad menos"))
print(paste("Q3 = $", cuartiles_ing["75%"],
            "→ 75% de empleados ganan menos de esta cifra"))

# 7b. Rango Intercuartílico (IQR) = Q3 - Q1
iqr_ing <- IQR(datos$ingreso_mensual, na.rm = TRUE)
print(paste("IQR ingreso mensual: $", iqr_ing))

# 7c. Percentiles arbitrarios (ej. 10, 90)
percentiles_ing <- quantile(
  datos$ingreso_mensual,
  probs = c(0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99),
  na.rm = TRUE
)
print("--- Percentiles clave de ingreso_mensual ---")
print(round(percentiles_ing, 0))

# 7d. Boxplot — visualiza cuartiles, IQR y outliers de todas las variables
datos_box <- datos %>%
  select(ingreso_mensual, gastos_mensual,
         score_desempeño, horas_extras_semana) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "valor") %>%
  mutate(
    variable = recode(variable,
      "ingreso_mensual"    = "Ingreso mensual",
      "gastos_mensual"     = "Gastos mensual",
      "score_desempeño"    = "Score desempeño",
      "horas_extras_semana" = "Horas extras/sem"
    )
  )

grafico_box <- ggplot(datos_box, aes(x = variable, y = valor, fill = variable)) +
  geom_boxplot(outlier.colour = "#E84855", outlier.size = 2, alpha = 0.7) +
  facet_wrap(~ variable, scales = "free", ncol = 2) +
  scale_fill_manual(values = c(
    "Ingreso mensual"  = "#2E86AB",
    "Gastos mensual"   = "#A23B72",
    "Score desempeño"  = "#F18F01",
    "Horas extras/sem" = "#44BBA4"
  )) +
  labs(
    title    = "Boxplots: Cuartiles, IQR y Outliers",
    subtitle = "Caja = Q1-Q3 | Línea = Mediana | Puntos rojos = outliers",
    x        = NULL,
    y        = "Valor"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    plot.title  = element_text(face = "bold"),
    axis.text.x = element_blank()
  )

print(grafico_box)
ggsave("plot_boxplots.png", grafico_box, width = 10, height = 7, dpi = 150)


# ── 8. DETECCIÓN Y MANEJO DE OUTLIERS ────────────────────────────────────────

# ── Método 1: Regla de 1.5 × IQR (Tukey) ─────────────────────────────────────
Q1_ing <- quantile(datos$ingreso_mensual, 0.25, na.rm = TRUE)
Q3_ing <- quantile(datos$ingreso_mensual, 0.75, na.rm = TRUE)
IQR_ing <- Q3_ing - Q1_ing

limite_inf_ing <- Q1_ing - 1.5 * IQR_ing
limite_sup_ing <- Q3_ing + 1.5 * IQR_ing

outliers_iqr <- datos %>%
  filter(
    !is.na(ingreso_mensual),
    ingreso_mensual < limite_inf_ing | ingreso_mensual > limite_sup_ing
  ) %>%
  select(id, nivel_educacion, departamento, ingreso_mensual)

print(paste(
  "Outliers por IQR en ingreso_mensual:",
  nrow(outliers_iqr), "registros"
))
print(outliers_iqr)

# ── Método 2: ±3 Desviaciones Estándar ────────────────────────────────────────
media_ing <- mean(datos$ingreso_mensual, na.rm = TRUE)
sd_ing_2  <- sd(datos$ingreso_mensual, na.rm = TRUE)

outliers_sd <- datos %>%
  filter(
    !is.na(ingreso_mensual),
    abs(ingreso_mensual - media_ing) > 3 * sd_ing_2
  ) %>%
  select(id, nivel_educacion, ingreso_mensual)

print(paste(
  "Outliers por ±3 SD en ingreso_mensual:",
  nrow(outliers_sd), "registros"
))
print(outliers_sd)

# ── Visualizar outliers con colores ───────────────────────────────────────────
datos_outlier_flag <- datos %>%
  filter(!is.na(ingreso_mensual)) %>%
  mutate(
    es_outlier = case_when(
      ingreso_mensual < limite_inf_ing |
        ingreso_mensual > limite_sup_ing ~ "Outlier",
      TRUE                               ~ "Normal"
    )
  )

grafico_outlier <- ggplot(
  datos_outlier_flag,
  aes(x = reorder(nivel_educacion, ingreso_mensual),
      y = ingreso_mensual,
      color = es_outlier)
) +
  geom_jitter(width = 0.25, alpha = 0.7, size = 2) +
  scale_color_manual(
    values = c("Normal" = "#2E86AB", "Outlier" = "#E84855"),
    name   = NULL
  ) +
  scale_y_continuous(
    labels = scales::label_dollar(
      prefix = "$", suffix = "", big.mark = ","
    )
  ) +
  labs(
    title    = "Ingreso mensual por nivel educativo",
    subtitle = "Método IQR: puntos rojos = outliers (fuera de 1.5 × IQR)",
    x        = "Nivel de educación",
    y        = "Ingreso mensual ($)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold"),
    legend.position = "top"
  )

print(grafico_outlier)
ggsave("plot_outliers.png", grafico_outlier, width = 9, height = 6, dpi = 150)

# ── Decisión sobre outliers: 3 opciones ───────────────────────────────────────

# Opción A: Eliminar outliers
datos_sin_outliers <- datos %>%
  filter(
    is.na(ingreso_mensual) |
    (ingreso_mensual >= limite_inf_ing & ingreso_mensual <= limite_sup_ing)
  )
print(paste("Filas tras eliminar outliers:", nrow(datos_sin_outliers)))

# Opción B: Imputar con la mediana (más robusta que la media ante outliers)
datos_imputado <- datos %>%
  mutate(
    ingreso_imputado = if_else(
      is.na(ingreso_mensual) |
        ingreso_mensual < limite_inf_ing |
        ingreso_mensual > limite_sup_ing,
      median(ingreso_mensual, na.rm = TRUE),
      ingreso_mensual
    )
  )

# Opción C: Mantener y documentar (cuando los valores son reales)
# Sólo marcamos la columna flag para usarla luego en modelos
datos_con_flag <- datos %>%
  mutate(
    outlier_ingreso = ingreso_mensual > limite_sup_ing |
                      ingreso_mensual < limite_inf_ing
  )


# ── 9. ANÁLISIS DE CORRELACIÓN ────────────────────────────────────────────────
# ¿Se mueven juntas dos variables?

# 9a. Correlación entre dos variables específicas
cor_ing_exp <- cor(
  datos$ingreso_mensual,
  datos$años_experiencia,
  use = "complete.obs"   # maneja NAs
)
print(paste(
  "Correlación ingreso ~ años experiencia:", round(cor_ing_exp, 3)
))

# 9b. Matriz de correlación (entre todas las variables numéricas)
# Seleccionar sólo numéricas y eliminar NAs
datos_num <- datos %>%
  select(
    edad, años_experiencia, ingreso_mensual,
    gastos_mensual, score_desempeño, horas_extras_semana, num_dependientes
  )

matriz_cor <- cor(datos_num, use = "pairwise.complete.obs")
print("--- Matriz de correlación ---")
print(round(matriz_cor, 2))

# 9c. Visualizar la matriz de correlación
png("plot_correlacion.png", width = 800, height = 700, res = 150)
corrplot(
  matriz_cor,
  method   = "color",
  type     = "upper",
  order    = "hclust",
  tl.col   = "black",
  tl.cex   = 0.8,
  addCoef.col = "black",
  number.cex  = 0.65,
  col      = colorRampPalette(c("#E84855", "white", "#2E86AB"))(200),
  title    = "Matriz de correlación",
  mar      = c(0, 0, 2, 0)
)
dev.off()

# 9d. Scatter plot: ingreso vs. gastos (correlación positiva esperada)
grafico_scatter <- datos %>%
  filter(!is.na(ingreso_mensual)) %>%
  ggplot(aes(x = ingreso_mensual, y = gastos_mensual, color = nivel_educacion)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(
    method = "lm", se = FALSE,
    color = "#E84855", linewidth = 1
  ) +
  scale_x_continuous(
    labels = scales::label_dollar(prefix = "$", suffix = "", big.mark = ",")
  ) +
  scale_y_continuous(
    labels = scales::label_dollar(prefix = "$", suffix = "", big.mark = ",")
  ) +
  scale_color_viridis_d(name = "Educación") +
  labs(
    title    = "Correlación: Ingreso mensual vs. Gastos mensuales",
    subtitle = paste0("r = ", round(
      cor(datos$ingreso_mensual, datos$gastos_mensual,
          use = "complete.obs"), 2
    )),
    x = "Ingreso mensual ($)",
    y = "Gastos mensuales ($)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

print(grafico_scatter)
ggsave("plot_scatter_ingreso_gastos.png", grafico_scatter,
       width = 9, height = 6, dpi = 150)


# ── 10. DETECCIÓN Y MANEJO DE DATOS FALTANTES (NAs) ──────────────────────────

# ── 10a. Detectar NAs ─────────────────────────────────────────────────────────

# Vector lógico de NAs en una columna
na_edad_vector <- is.na(datos$edad)

# Conteo de NAs por columna (dos formas equivalentes)
na_por_columna <- colSums(is.na(datos))
print("--- NAs por columna (conteo absoluto) ---")
print(na_por_columna)

# Porcentaje de NAs por columna (más informativo)
pct_na <- datos %>%
  summarise(across(everything(), ~ mean(is.na(.x)) * 100)) %>%
  pivot_longer(everything(),
               names_to  = "variable",
               values_to = "pct_na") %>%
  arrange(desc(pct_na)) %>%
  mutate(pct_na = round(pct_na, 1))

print("--- % de NAs por columna ---")
print(pct_na)

# ── 10b. Visualización de patrón de NAs ───────────────────────────────────────
grafico_miss <- vis_miss(datos, warn_large_data = FALSE) +
  labs(
    title    = "Mapa de datos faltantes por columna",
    subtitle = "Negro = presente | Gris = ausente (NA)"
  ) +
  theme(plot.title = element_text(face = "bold"))

print(grafico_miss)
ggsave("plot_mapa_nas.png", grafico_miss, width = 10, height = 6, dpi = 150)

# ── 10c. Diagnóstico del tipo de NA ──────────────────────────────────────────
# El tipo de NA importa porque determina la estrategia de manejo.

# MCAR (Missing Completely At Random) → edad
# Verificación: comparar medias del resto de variables entre con/sin NA en edad
comparar_mcar <- datos %>%
  mutate(falta_edad = is.na(edad)) %>%
  group_by(falta_edad) %>%
  summarise(
    media_ingreso = mean(ingreso_mensual, na.rm = TRUE),
    media_exp     = mean(años_experiencia, na.rm = TRUE),
    n             = n()
  )
print("--- Comparación grupos NA en edad (MCAR?) ---")
print(comparar_mcar)
# Si las medias son similares → patrón MCAR (aleatorio)

# MAR (Missing At Random) → ingreso_mensual según educación
comparar_mar <- datos %>%
  mutate(falta_ingreso = is.na(ingreso_mensual)) %>%
  group_by(nivel_educacion, falta_ingreso) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = falta_ingreso,
              values_from = n,
              values_fill = 0) %>%
  rename(con_ingreso = `FALSE`, sin_ingreso = `TRUE`) %>%
  mutate(pct_faltante = round(sin_ingreso / (con_ingreso + sin_ingreso) * 100, 1))

print("--- % faltante en ingreso_mensual por nivel edu (MAR?) ---")
print(comparar_mar)
# Si % faltante varía mucho entre grupos → patrón MAR

# MNAR (Missing Not At Random) → score_desempeño
# Los valores bajos son más proclives a ser NA (sesgo de no respuesta)
# Evidencia indirecta: comparar score promedio en otros campos
comparar_mnar <- datos %>%
  mutate(falta_score = is.na(score_desempeño)) %>%
  group_by(falta_score) %>%
  summarise(
    media_horas = mean(horas_extras_semana, na.rm = TRUE),
    media_exp   = mean(años_experiencia, na.rm = TRUE),
    n           = n()
  )
print("--- Perfil de quienes faltan score (MNAR?) ---")
print(comparar_mnar)

# ── 10d. Estrategias de manejo ─────────────────────────────────────────────────

# Opción 1: Eliminar filas con cualquier NA (completo caso)
datos_completos <- na.omit(datos)
print(paste("Filas con caso completo:", nrow(datos_completos)))

# Opción 2: Imputar con la MEDIA (para variables simétricas, < 5% NA)
# Útil si MCAR; sensible a outliers
datos_imp_media <- datos %>%
  mutate(
    edad = if_else(is.na(edad), round(mean(edad, na.rm = TRUE)), edad)
  )

# Opción 3: Imputar con la MEDIANA (más robusta — preferida en variables sesgadas)
datos_imp_mediana <- datos %>%
  mutate(
    ingreso_mensual = if_else(
      is.na(ingreso_mensual),
      median(ingreso_mensual, na.rm = TRUE),
      ingreso_mensual
    )
  )

# Opción 4: Imputar con la MEDIANA por grupo (más precisa)
# Imputa ingreso según nivel_educacion
datos_imp_grupo <- datos %>%
  group_by(nivel_educacion) %>%
  mutate(
    ingreso_mensual = if_else(
      is.na(ingreso_mensual),
      median(ingreso_mensual, na.rm = TRUE),
      ingreso_mensual
    )
  ) %>%
  ungroup()

print("--- Filas con NA en ingreso antes vs. después de imputar por grupo ---")
print(paste(
  "Antes:", sum(is.na(datos$ingreso_mensual)),
  "| Después:", sum(is.na(datos_imp_grupo$ingreso_mensual))
))

# ── 10e. Verificar imputación: comparar distribuciones antes/después ───────────
comparar_imp <- bind_rows(
  datos %>%
    select(ingreso_mensual) %>%
    mutate(version = "Original (con NA)"),
  datos_imp_grupo %>%
    select(ingreso_mensual) %>%
    mutate(version = "Imputada (mediana por grupo)")
)

grafico_imp <- ggplot(comparar_imp, aes(x = ingreso_mensual, fill = version)) +
  geom_density(alpha = 0.5, na.rm = TRUE) +
  scale_x_continuous(
    labels = scales::label_dollar(prefix = "$", suffix = "", big.mark = ",")
  ) +
  scale_fill_manual(
    values = c("Original (con NA)" = "#2E86AB",
               "Imputada (mediana por grupo)" = "#F18F01"),
    name = NULL
  ) +
  labs(
    title    = "Distribución de ingreso_mensual: antes vs. después de imputar",
    subtitle = "Una imputación razonable no distorsiona la distribución",
    x        = "Ingreso mensual ($)",
    y        = "Densidad"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold"),
    legend.position = "top"
  )

print(grafico_imp)
ggsave("plot_imputacion.png", grafico_imp, width = 9, height = 6, dpi = 150)


# ── 11. EDA INTEGRAL: ANÁLISIS POR GRUPOS ─────────────────────────────────────
# Combinando lo visto: describir una variable según grupos categóricos

resumen_por_region <- datos %>%
  group_by(region) %>%
  summarise(
    n              = n(),
    media_ingreso  = mean(ingreso_mensual, na.rm = TRUE),
    median_ingreso = median(ingreso_mensual, na.rm = TRUE),
    sd_ingreso     = sd(ingreso_mensual, na.rm = TRUE),
    cv_ingreso     = sd_ingreso / media_ingreso,
    pct_outliers   = mean(
      !is.na(ingreso_mensual) &
        (ingreso_mensual < limite_inf_ing | ingreso_mensual > limite_sup_ing),
      na.rm = TRUE
    ) * 100,
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

print("--- Resumen de ingreso por región ---")
print(resumen_por_region)

# Boxplot por grupo: ingreso por nivel educativo
grafico_grupo <- datos %>%
  filter(!is.na(ingreso_mensual)) %>%
  ggplot(aes(
    x    = nivel_educacion,
    y    = ingreso_mensual,
    fill = nivel_educacion
  )) +
  geom_boxplot(outlier.colour = "#E84855", outlier.size = 1.5, alpha = 0.75) +
  scale_y_log10(
    labels = scales::label_dollar(prefix = "$", suffix = "", big.mark = ",")
  ) +
  scale_fill_viridis_d() +
  labs(
    title    = "Distribución de ingreso mensual por nivel educativo",
    subtitle = "Escala logarítmica para manejar el sesgo derecho",
    x        = "Nivel educativo",
    y        = "Ingreso mensual (escala log)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    plot.title      = element_text(face = "bold"),
    axis.text.x     = element_text(angle = 15, hjust = 1)
  )

print(grafico_grupo)
ggsave("plot_ingreso_por_educacion.png", grafico_grupo,
       width = 9, height = 6, dpi = 150)


# ── 12. RESUMEN FINAL INTEGRADO ───────────────────────────────────────────────
# Un solo tibble con los estadísticos clave de todas las variables numéricas

resumen_final <- datos %>%
  summarise(
    across(
      c(edad, años_experiencia, ingreso_mensual,
        gastos_mensual, score_desempeño, horas_extras_semana,
        num_dependientes),
      list(
        n       = ~ sum(!is.na(.x)),
        na      = ~ sum(is.na(.x)),
        media   = ~ mean(.x, na.rm = TRUE),
        mediana = ~ median(.x, na.rm = TRUE),
        sd      = ~ sd(.x, na.rm = TRUE),
        cv      = ~ sd(.x, na.rm = TRUE) / mean(.x, na.rm = TRUE),
        min     = ~ min(.x, na.rm = TRUE),
        q1      = ~ quantile(.x, 0.25, na.rm = TRUE),
        q3      = ~ quantile(.x, 0.75, na.rm = TRUE),
        max     = ~ max(.x, na.rm = TRUE),
        iqr     = ~ IQR(.x, na.rm = TRUE),
        sesgo   = ~ skewness(.x, na.rm = TRUE)
      ),
      .names = "{.col}__{.fn}"
    )
  ) %>%
  pivot_longer(
    everything(),
    names_to  = c("variable", "estadístico"),
    names_sep = "__"
  ) %>%
  pivot_wider(names_from = estadístico, values_from = value) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

print("=== RESUMEN ESTADÍSTICO FINAL ===")
print(resumen_final)

# Guardar resumen final como CSV
write_csv(resumen_final, "resumen_estadistico.csv")

# =============================================================================
# FIN DEL SCRIPT
# Archivos generados:
#   plot_distribuciones.png          — 4 distribuciones (panel)
#   plot_qqplot_edad.png             — QQ-plot normalidad de edad
#   plot_boxplots.png                — Boxplots con IQR y outliers
#   plot_outliers.png                — Outliers en ingreso por educación
#   plot_correlacion.png             — Matriz de correlación (corrplot)
#   plot_scatter_ingreso_gastos.png  — Scatter ingreso vs. gastos
#   plot_mapa_nas.png                — Mapa visual de NAs
#   plot_imputacion.png              — Comparativa antes/después imputación
#   plot_ingreso_por_educacion.png   — Boxplot ingreso por nivel educativo
#   resumen_estadistico.csv          — Tabla de estadísticos completa
# =============================================================================

