# =============================================================================
# Generador de datos sintéticos: deserción estudiantil (versión balanceada)
# -----------------------------------------------------------------------------
# Reescribe estudiantes.xlsx con una tasa de deserción ~35% (en vez del ~6%
# original), para que sea un ejemplo LIMPIO y didáctico de clasificación
# balanceada con regresión logística vs. KNN. La señal es realista: desertan
# más quienes tienen bajo promedio, baja asistencia, más reprobaciones, mayor
# distancia al campus, trabajan y tienen menor ingreso familiar.
# Reproducible con set.seed(2026).
# =============================================================================

library(tidyverse)
library(writexl)

set.seed(2026)
n <- 1000

# ---- Predictores ----
promedio_prepa <- round(pmin(pmax(rnorm(n, 8.3, 0.6), 6), 10), 2)
examen_admision <- round(pmin(pmax(rnorm(n, 1000, 150), 400), 1400))
horas_estudio_semanal <- round(pmin(pmax(rnorm(n, 14, 6), 0), 40), 1)
# Colinealidad intencional: la lectura se deriva en parte del estudio.
horas_lectura_semanal <- round(pmin(pmax(0.5 * horas_estudio_semanal +
                                           rnorm(n, 2, 2), 0), 30), 1)
asistencia_pct <- round(pmin(pmax(rnorm(n, 85, 13), 40), 100), 1)
reprobaciones <- pmin(rpois(n, 1.2), 8)
edad <- sample(18:25, n, replace = TRUE,
               prob = c(8, 9, 8, 6, 4, 3, 2, 1))
ingreso_familiar_miles <- round(pmin(pmax(rlnorm(n, log(30), 0.5), 6), 200), 1)
distancia_campus_km <- round(pmin(rexp(n, 1 / 10), 45), 1)
carrera <- sample(c("Ingenieria", "Negocios", "Humanidades", "Salud",
                    "Ciencias"), n, replace = TRUE)
tipo_beca <- sample(c("ninguna", "parcial", "completa"), n, replace = TRUE,
                    prob = c(0.5, 0.35, 0.15))
trabaja <- sample(c("si", "no"), n, replace = TRUE, prob = c(0.35, 0.65))
vive_con_familia <- sample(c("si", "no"), n, replace = TRUE,
                           prob = c(0.7, 0.3))
# Variable casi constante: sirve para ilustrar step_nzv.
inscrito_sistema <- sample(c("si", "no"), n, replace = TRUE,
                           prob = c(0.985, 0.015))

# ---- Proceso generador de la deserción (logístico) ----
z <- function(x) as.numeric(scale(x))
eta_sin_intercepto <-
  -1.05 * z(promedio_prepa) -
   1.20 * z(asistencia_pct) +
   1.05 * z(reprobaciones) +
   0.55 * z(distancia_campus_km) +
   0.60 * (trabaja == "si") -
   0.45 * z(ingreso_familiar_miles) -
   0.50 * z(horas_estudio_semanal) -
   0.30 * z(examen_admision)

# Calibramos el intercepto para una prevalencia objetivo de ~35%.
objetivo <- 0.35
b0 <- uniroot(function(b) mean(plogis(b + eta_sin_intercepto)) - objetivo,
              interval = c(-10, 10))$root
prob_desercion <- plogis(b0 + eta_sin_intercepto)
deserto <- ifelse(runif(n) < prob_desercion, "si", "no")

estudiantes <- tibble(
  promedio_prepa, examen_admision, horas_estudio_semanal,
  horas_lectura_semanal, asistencia_pct, reprobaciones, edad,
  ingreso_familiar_miles, distancia_campus_km, carrera, tipo_beca,
  trabaja, vive_con_familia, inscrito_sistema, deserto
)

# ---- Introducir algunos NAs (lección de imputación) ----
estudiantes$ingreso_familiar_miles[sample(n, round(0.05 * n))] <- NA
estudiantes$examen_admision[sample(n, round(0.03 * n))] <- NA

# Verificación
print(prop.table(table(estudiantes$deserto)))

write_xlsx(estudiantes, "estudiantes.xlsx")
