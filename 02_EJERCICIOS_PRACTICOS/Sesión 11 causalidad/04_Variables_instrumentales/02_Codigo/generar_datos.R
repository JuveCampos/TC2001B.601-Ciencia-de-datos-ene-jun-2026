# ============================================================================
# Generacion de datos sinteticos para Variables Instrumentales
# Inspirado en Angrist & Krueger (1991): efecto de educacion sobre ingresos
# ============================================================================

library(tidyverse)

set.seed(456)

# --- Parametros de la simulacion ---
n <- 2000

# --- Paso 1: Generar el instrumento (trimestre de nacimiento) ---
# El trimestre de nacimiento es esencialmente aleatorio
trimestre_nacimiento <- sample(1:4, n, replace = TRUE)

# --- Paso 2: Generar la variable omitida (habilidad) ---
# La habilidad NO esta correlacionada con el trimestre de nacimiento
# (el trimestre es aleatorio), pero SI afecta educacion e ingresos
habilidad <- rnorm(n, mean = 0, sd = 1)

# --- Paso 3: Generar la variable endogena (anios de educacion) ---
# La educacion depende de:
#   - Trimestre de nacimiento (instrumento): los nacidos en Q1 tienden
#     a tener MENOS educacion por las leyes de asistencia obligatoria
#   - Habilidad (variable omitida): personas con mas habilidad estudian mas
#   - Un componente aleatorio

# Efecto del trimestre sobre educacion:
# Q1 = menos educacion (pueden abandonar antes)
# Q4 = mas educacion (deben permanecer mas tiempo)
efecto_trimestre <- case_when(
  trimestre_nacimiento == 1 ~ -0.6,
  trimestre_nacimiento == 2 ~ -0.2,
  trimestre_nacimiento == 3 ~  0.2,
  trimestre_nacimiento == 4 ~  0.6
)

anios_educacion <- 12 +
  efecto_trimestre +        # Efecto del instrumento
  0.8 * habilidad +         # Efecto de habilidad (genera endogeneidad)
  rnorm(n, mean = 0, sd = 1)

# Asegurar valores razonables (entre 6 y 20 anios)
anios_educacion <- pmin(pmax(anios_educacion, 6), 20)

# --- Paso 4: Generar el resultado (log de ingresos) ---
# Los ingresos dependen de:
#   - Educacion (efecto causal verdadero = 0.08)
#   - Habilidad (variable omitida, genera sesgo en OLS)
#   - Un componente aleatorio

beta_verdadero <- 0.08  # Efecto causal real de un anio de educacion

log_ingresos <- 8.0 +
  beta_verdadero * anios_educacion +  # Efecto causal
  0.5 * habilidad +                   # Efecto de habilidad (omitida)
  rnorm(n, mean = 0, sd = 0.4)

# --- Paso 5: Construir el dataframe ---
datos_iv <- tibble(
  id = 1:n,
  trimestre_nacimiento = trimestre_nacimiento,
  anios_educacion = round(anios_educacion, 1),
  log_ingresos = round(log_ingresos, 4),
  # Incluimos habilidad para fines pedagogicos
  # (en la realidad, esta variable NO se observa)
  habilidad = round(habilidad, 4)
)

# --- Paso 6: Verificaciones rapidas ---
# Verificar que el instrumento es relevante
modelo_primera_etapa <- lm(
  anios_educacion ~ factor(trimestre_nacimiento),
  data = datos_iv
)
f_stat <- summary(modelo_primera_etapa)$fstatistic[1]
print(paste("Estadistico F de primera etapa:", round(f_stat, 2)))

# Verificar correlaciones
print(paste(
  "Corr(trimestre, educacion):",
  round(cor(datos_iv$trimestre_nacimiento, datos_iv$anios_educacion), 4)
))
print(paste(
  "Corr(habilidad, educacion):",
  round(cor(datos_iv$habilidad, datos_iv$anios_educacion), 4)
))
print(paste(
  "Corr(habilidad, log_ingresos):",
  round(cor(datos_iv$habilidad, datos_iv$log_ingresos), 4)
))
print(paste(
  "Corr(trimestre, habilidad):",
  round(cor(datos_iv$trimestre_nacimiento, datos_iv$habilidad), 4)
))

# --- Paso 7: Guardar los datos ---
write_csv(
  datos_iv,
  "01_Datos/datos_iv.csv"
)

# Confirmar
print(paste("Datos guardados: 01_Datos/datos_iv.csv con", nrow(datos_iv), "observaciones"))
print(paste("Efecto causal verdadero (beta):", beta_verdadero))
