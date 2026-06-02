# ============================================================================
# actualizar_rds.R
# Regenera el banco de preguntas (.rds) que consume la app a partir del Excel.
# Curso: TC2001B - Ciencia de datos para política pública | Tec de Monterrey
# ----------------------------------------------------------------------------
# Uso:
#   - Edita el Excel de preguntas (agrega/corrige reactivos).
#   - Corre este script desde la carpeta de la app:
#       Rscript actualizar_rds.R
#     o desde R/RStudio:  source("actualizar_rds.R")
# ============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
})

# ----------------------------------------------------------------------------
# Rutas (relativas a la carpeta de la app)
# ----------------------------------------------------------------------------
ruta_excel <- "../guia_opcion_multiple_temas_ml_v1.xlsx"
ruta_rds   <- "preguntas_guia_ml.rds"

stopifnot("No se encontró el Excel de preguntas" = file.exists(ruta_excel))

# ----------------------------------------------------------------------------
# Lectura y normalización
# ----------------------------------------------------------------------------
columnas_req <- c("tema", "pregunta", "opcion_a", "opcion_b",
                  "opcion_c", "opcion_d", "opcion_correcta", "explicacion")

banco <- read_excel(ruta_excel) %>%
  mutate(across(everything(), as.character),
         opcion_correcta = toupper(trimws(opcion_correcta))) %>%
  filter(!is.na(pregunta), !is.na(tema))

# ----------------------------------------------------------------------------
# Validaciones
# ----------------------------------------------------------------------------
stopifnot("Faltan columnas requeridas en el Excel" =
            all(columnas_req %in% names(banco)))
stopifnot("Hay respuestas correctas fuera de {A, B, C, D}" =
            all(banco$opcion_correcta %in% c("A", "B", "C", "D")))

# Reserva solo las columnas que la app necesita, en orden
banco <- banco %>% select(all_of(columnas_req))

# ----------------------------------------------------------------------------
# Guardado
# ----------------------------------------------------------------------------
saveRDS(banco, ruta_rds)

# Reporte
print(sprintf("RDS actualizado: %s (%d preguntas)", ruta_rds, nrow(banco)))
print(table(banco$tema))
