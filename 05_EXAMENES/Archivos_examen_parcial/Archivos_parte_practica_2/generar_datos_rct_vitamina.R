# Generador del dataset para Problema 1 (RCT) - Examen práctico 01
# TC2001B.601 - Ciencia de datos para la toma de decisiones I
# -----------------------------------------------------------------
# Escenario: ensayo controlado aleatorizado (RCT) que evalúa el
# efecto de una vitamina ("VitaEstudio") sobre el rendimiento
# académico de estudiantes universitarios durante un semestre.

library(tidyverse)
library(writexl)

set.seed(2026)

# Parámetros del experimento
n_tratamiento <- 200
n_control     <- 200
n_total       <- n_tratamiento + n_control

# Efecto REAL de la vitamina sobre la calificación final (puntos 0-10)
# Este es el "ground truth" que el estudiante debería aproximar en
# su estimación por diferencia de medias.
efecto_vitamina <- 0.6

# Covariables basales (iguales en distribución para ambos grupos por
# construcción, gracias a la aleatorización)
datos_rct <- tibble(
  id_alumno = 1:n_total,
  grupo = c(rep("tratamiento", n_tratamiento),
            rep("control",     n_control)),
  edad = round(rnorm(n_total, mean = 20, sd = 1.5)),
  horas_sueno = round(rnorm(n_total, mean = 7, sd = 1), 1),
  calificacion_previa = round(
    pmin(10, pmax(0, rnorm(n_total, mean = 7.2, sd = 1.1))), 1
  )
)

# Calificación final: función del desempeño previo, horas de sueño,
# ruido y el efecto del tratamiento.
datos_rct <- datos_rct %>%
  mutate(
    calificacion_final = 0.55 * calificacion_previa +
                         0.25 * horas_sueno +
                         if_else(grupo == "tratamiento",
                                 efecto_vitamina, 0) +
                         rnorm(n_total, mean = 0, sd = 0.9) +
                         1.4,
    calificacion_final = round(pmin(10, pmax(0, calificacion_final)), 1)
  ) %>%
  # Revolver filas para que no queden ordenadas por grupo
  slice_sample(prop = 1) %>%
  mutate(id_alumno = row_number())

# Resumen rápido de verificación
datos_rct %>%
  group_by(grupo) %>%
  summarise(
    n = n(),
    media_final   = mean(calificacion_final),
    media_previa  = mean(calificacion_previa),
    sd_final      = sd(calificacion_final),
    edad_media    = mean(edad),
    sueno_medio   = mean(horas_sueno)
  ) %>%
  print()

# Diferencia de medias (efecto promedio del tratamiento estimado)
dif <- datos_rct %>%
  group_by(grupo) %>%
  summarise(m = mean(calificacion_final)) %>%
  pivot_wider(names_from = grupo, values_from = m) %>%
  mutate(diferencia = tratamiento - control)

print(dif)

# Guardar archivo xlsx (consistencia con calificaciones_grupo.xlsx)
ruta_salida <- "datos_rct_vitamina.xlsx"
write_xlsx(datos_rct, ruta_salida)

# Mensaje con la ruta guardada
print(paste0("Archivo guardado en: ", ruta_salida))
