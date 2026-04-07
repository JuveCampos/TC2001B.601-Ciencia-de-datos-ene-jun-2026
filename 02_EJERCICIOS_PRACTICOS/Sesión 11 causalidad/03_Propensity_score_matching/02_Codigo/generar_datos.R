# ============================================================
# Generacion de datos sinteticos para Propensity Score Matching
# ============================================================
# Datos inspirados en el estudio de Dehejia y Wahba (1999),
# que replica la evaluacion del programa de capacitacion
# laboral NSW (National Supported Work) de LaLonde (1986).
#
# Variables:
#   - edad: edad del individuo
#   - educacion: anios de educacion
#   - raza_negro: indicador de raza negra (1 = si)
#   - raza_hispano: indicador de raza hispana (1 = si)
#   - casado: indicador de estado civil (1 = casado)
#   - re74: ingresos en 1974 (pre-programa)
#   - re75: ingresos en 1975 (pre-programa)
#   - tratamiento: participacion en el programa (1 = si)
#   - re78: ingresos en 1978 (resultado post-programa)
# ============================================================

library(tidyverse)

set.seed(123)

# --- Parametros generales ---
n <- 1000

# --- Generar covariables ---
# Las distribuciones buscan reflejar la poblacion objetivo
# del programa NSW: personas con bajos ingresos y educacion

datos <- tibble(
  id = 1:n,
  edad = round(rnorm(n, mean = 28, sd = 7)) %>%
    pmax(18) %>%
    pmin(55),
  educacion = round(rnorm(n, mean = 10.5, sd = 2.5)) %>%
    pmax(4) %>%
    pmin(18),
  raza_negro = rbinom(n, 1, prob = 0.40),
  raza_hispano = ifelse(
    raza_negro == 1, 0,
    rbinom(n, 1, prob = 0.15)
  ),
  casado = rbinom(n, 1, prob = 0.20),
  # Ingresos previos: mezcla de ceros y log-normal
  # Muchos individuos tienen ingresos cero o muy bajos
  re74 = ifelse(
    rbinom(n, 1, prob = 0.30) == 1,
    0,
    round(exp(rnorm(n, mean = 8.5, sd = 1.2)), 0)
  ),
  re75 = ifelse(
    rbinom(n, 1, prob = 0.30) == 1,
    0,
    round(exp(rnorm(n, mean = 8.3, sd = 1.2)), 0)
  )
)

# --- Modelo de seleccion al tratamiento ---
# La seleccion NO es aleatoria: depende de las covariables.
# Personas con menos educacion, menores ingresos previos y
# de ciertos grupos demograficos tienen mayor probabilidad
# de participar en el programa (autoseleccion).

datos <- datos %>%
  mutate(
    # Puntaje latente de propension al tratamiento
    logit_propension = 0.5 +
      -0.03 * edad +
      -0.10 * educacion +
      0.80 * raza_negro +
      0.50 * raza_hispano +
      -0.40 * casado +
      -0.00005 * re74 +
      -0.00006 * re75,
    # Probabilidad de tratamiento
    prob_tratamiento = 1 / (1 + exp(-logit_propension)),
    # Asignar tratamiento segun la probabilidad
    tratamiento = rbinom(n, 1, prob = prob_tratamiento)
  )

# Verificar proporcion de tratados
cat("Proporcion de individuos tratados:",
    mean(datos$tratamiento), "\n")

# --- Generar resultado (ingresos post-programa) ---
# El resultado depende de las covariables y del tratamiento.
# El efecto causal verdadero del tratamiento es de ~1800 dolares
# (consistente con la estimacion de Dehejia y Wahba).

efecto_verdadero <- 1800

datos <- datos %>%
  mutate(
    # Componente base del ingreso (depende de covariables)
    ingreso_base = 2000 +
      50 * edad +
      400 * educacion +
      -1500 * raza_negro +
      -800 * raza_hispano +
      1200 * casado +
      0.15 * re74 +
      0.25 * re75 +
      rnorm(n, mean = 0, sd = 3000),
    # Ingresos en 1978: base + efecto del tratamiento
    re78 = round(pmax(0, ingreso_base +
      efecto_verdadero * tratamiento), 0)
  )

# --- Seleccionar columnas finales ---
datos_final <- datos %>%
  select(
    id, edad, educacion,
    raza_negro, raza_hispano, casado,
    re74, re75, tratamiento, re78
  )

# --- Resumen descriptivo ---
cat("\n--- Resumen de los datos generados ---\n")
cat("Total de observaciones:", nrow(datos_final), "\n")
cat("Tratados:", sum(datos_final$tratamiento), "\n")
cat("Control:", sum(datos_final$tratamiento == 0), "\n")

datos_final %>%
  group_by(tratamiento) %>%
  summarise(
    n = n(),
    edad_media = mean(edad),
    educacion_media = mean(educacion),
    re74_media = mean(re74),
    re75_media = mean(re75),
    re78_media = mean(re78),
    .groups = "drop"
  ) %>%
  print()

cat("\nEfecto verdadero del tratamiento:", efecto_verdadero, "\n")
cat("Diferencia naive en re78:",
    mean(datos_final$re78[datos_final$tratamiento == 1]) -
      mean(datos_final$re78[datos_final$tratamiento == 0]),
    "\n")

# --- Guardar datos ---
write_csv(datos_final, "01_Datos/datos_psm.csv")
cat("\nDatos guardados en '01_Datos/datos_psm.csv'\n")
