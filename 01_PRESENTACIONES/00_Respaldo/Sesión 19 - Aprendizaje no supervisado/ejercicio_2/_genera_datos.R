# =============================================================================
# Generador de datos SINTÉTICOS — tipologías de municipios
# (uso interno: produce datos.csv; el alumno NO ejecuta este archivo)
# =============================================================================
# 400 municipios con nombres genéricos. La estructura latente tiene DOS factores
# casi independientes, cada uno reflejado por el MISMO número de variables (5),
# para que las 4 tipologías queden como las 4 ESQUINAS de un cuadrado y tanto
# k-means como el jerárquico las recuperen, con codo y silueta apuntando a 4.
#   f1 = DESARROLLO  (escolaridad, internet, PIB, agua altos; mortalidad baja)
#   f2 = ESTRUCTURA  (servicios/urbano vs. primario/rural)
#
# Detalle técnico: al estandarizar, la separación por variable se satura, así
# que lo que determina la distancia entre grupos es el NÚMERO de variables por
# eje. Por eso usamos 5 variables por eje (balanceadas). Todo es ficticio.
options(scipen = 999)
suppressMessages(library(tidyverse))

set.seed(2026)

tam <- c(A = 100, B = 90, C = 110, D = 100)
grupo <- rep(names(tam), times = tam)
n <- length(grupo)

# Factores latentes (±1) por grupo: las 4 esquinas ---------------------------
#   A: desarrollo +, servicios   | B: desarrollo +, primario
#   C: desarrollo -, servicios   | D: desarrollo -, primario
e1 <- c(A =  1, B =  1, C = -1, D = -1)[grupo]   # eje DESARROLLO
e2 <- c(A =  1, B = -1, C =  1, D = -1)[grupo]   # eje ESTRUCTURA

ruido <- function() rnorm(n, 0, 0.4)
clamp01 <- function(x) pmin(100, pmax(0, x))

datos <- tibble(
  municipio = sprintf("Municipio_%03d", 1:n),

  # --- Eje ESTRUCTURA (5 variables): servicios/urbano (+) vs primario (-) ---
  pct_urbano             = round(clamp01(55 + 30 * (e2 + ruido())), 1),
  pct_ocupados_primario  = round(clamp01(30 - 25 * (e2 + ruido())), 1),
  pct_ocupados_servicios = round(clamp01(50 + 24 * (e2 + ruido())), 1),
  densidad_pob_km2       = round(pmax(5, 800 + 680 * (e2 + ruido())), 1),
  pct_poblacion_indigena = round(clamp01(18 - 16 * (e2 + ruido())), 1),

  # --- Eje DESARROLLO (5 variables): bienestar alto (+) ---
  escolaridad_prom_anios = round(pmax(0, 9 + 2.3 * (e1 + ruido())), 1),
  pct_viviendas_internet = round(clamp01(48 + 26 * (e1 + ruido())), 1),
  pct_agua_entubada      = round(clamp01(82 + 13 * (e1 + ruido())), 1),
  tasa_mort_infantil     = round(pmax(1, 14 - 7 * (e1 + ruido())), 1),
  pib_per_capita_mxn     = round(pmax(20000, 140000 + 80000 * (e1 + ruido()))),

  # Gasto público: NO sigue ningún eje (programas sociales compensan a los
  # marginados). Aporta ruido casi independiente.
  gasto_pub_per_capita_mxn = round(pmax(3000, rnorm(n, 7500, 1200)))
)

# Índice de rezago social: COLINEAL (combina baja escolaridad, poca
# conectividad y baja agua: es casi una recombinación del eje DESARROLLO).
# Redundancia deliberada para discutirla en clase.
datos <- datos %>%
  mutate(
    indice_rezago_social = round(
      -scale(escolaridad_prom_anios)[, 1] * 0.4 -
        scale(pct_viviendas_internet)[, 1] * 0.4 -
        scale(pct_agua_entubada)[, 1] * 0.2 +
        rnorm(n, 0, 0.15),
      2)
  )

# ~4% de NAs en pib_per_capita_mxn (municipios sin dato económico reciente).
set.seed(11)
idx_na <- sample(n, size = round(0.04 * n))
datos$pib_per_capita_mxn[idx_na] <- NA

datos <- datos %>% slice_sample(prop = 1)

write_csv(datos, "ejercicio_2/datos.csv")

cat("datos.csv (municipios) generado:", nrow(datos), "filas x",
    ncol(datos), "columnas\n")
cat("NAs en pib_per_capita_mxn:", sum(is.na(datos$pib_per_capita_mxn)), "\n")
