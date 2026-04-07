# ==============================================================================
# Generacion de datos sinteticos para Regresion Discontinua (RDD)
# Inspirado en Angrist & Lavy (1999) - Regla de Maimonides
# ==============================================================================
# En Israel, la Regla de Maimonides establece que el tamano maximo de una clase
# es de 40 alumnos. Cuando la matricula supera 40, el grado se divide en dos
# clases, reduciendo dramaticamente el tamano de clase.
#
# Variable de asignacion (running variable): matricula de la escuela
# Punto de corte (cutoff): 40 estudiantes
# Tratamiento: clases mas pequenas (matricula > 40 -> 2 clases)
# Resultado: puntaje promedio en examen estandarizado
# ==============================================================================

library(tidyverse)

# Fijar semilla para reproducibilidad
set.seed(42)

# --- Parametros de la simulacion ---
n_escuelas <- 500
cutoff <- 40
efecto_tratamiento <- 5  # Puntos adicionales por tener clases mas pequenas

# --- Generar la variable de asignacion: matricula escolar ---
# Usamos una distribucion que genera valores alrededor del cutoff
# para tener suficientes observaciones de ambos lados
matricula <- round(runif(n_escuelas, min = 20, max = 60))

# --- Determinar el tamano de clase segun la Regla de Maimonides ---
# Si matricula <= 40: una sola clase (tamano = matricula)
# Si matricula > 40: dos clases (tamano = matricula / 2)
n_clases <- ifelse(matricula > cutoff, 2, 1)
tamano_clase <- matricula / n_clases

# --- Indicador de tratamiento (clases pequenas) ---
# El tratamiento es tener clases mas pequenas, lo cual ocurre
# cuando la matricula supera el umbral de 40
tratamiento <- as.integer(matricula > cutoff)

# --- Generar el resultado: puntaje en examen estandarizado ---
# El puntaje depende de:
# 1. Una relacion lineal con la matricula (escuelas mas grandes
#    pueden tener mas recursos)
# 2. El efecto del tratamiento (clases mas pequenas mejoran puntajes)
# 3. Ruido aleatorio

# Relacion base entre matricula y puntaje (tendencia suave)
puntaje_base <- 60 + 0.3 * (matricula - cutoff)

# Agregar el efecto del tratamiento
puntaje <- puntaje_base +
  efecto_tratamiento * tratamiento +
  rnorm(n_escuelas, mean = 0, sd = 3)

# --- Generar covariables adicionales (para tests de balance) ---
# Estas variables NO deberian mostrar discontinuidad en el cutoff
# porque son caracteristicas pre-tratamiento
pct_pobreza <- 30 + 0.1 * (matricula - cutoff) +
  rnorm(n_escuelas, mean = 0, sd = 5)
experiencia_docente <- 10 + 0.05 * (matricula - cutoff) +
  rnorm(n_escuelas, mean = 0, sd = 3)

# --- Construir el dataframe final ---
datos_rdd <- tibble(
  id_escuela = 1:n_escuelas,
  matricula = matricula,
  n_clases = n_clases,
  tamano_clase = tamano_clase,
  tratamiento = tratamiento,
  puntaje = round(puntaje, 1),
  pct_pobreza = round(pct_pobreza, 1),
  experiencia_docente = round(experiencia_docente, 1)
)

# --- Verificacion rapida ---
# Mostrar las primeras filas
print("Primeras observaciones del dataset:")
print(head(datos_rdd, 10))

# Estadisticas descriptivas por grupo
resumen <- datos_rdd %>%
  group_by(tratamiento) %>%
  summarise(
    n = n(),
    matricula_media = mean(matricula),
    tamano_clase_medio = mean(tamano_clase),
    puntaje_medio = mean(puntaje),
    .groups = "drop"
  )

print("Resumen por grupo de tratamiento:")
print(resumen)

# --- Guardar los datos ---
write_csv(
  datos_rdd,
  "01_Datos/datos_rdd.csv"
)

print("Datos guardados exitosamente en '01_Datos/datos_rdd.csv'")
print(paste("Total de escuelas:", n_escuelas))
print(paste("Escuelas control (matricula <= 40):", sum(tratamiento == 0)))
print(paste("Escuelas tratadas (matricula > 40):", sum(tratamiento == 1)))
