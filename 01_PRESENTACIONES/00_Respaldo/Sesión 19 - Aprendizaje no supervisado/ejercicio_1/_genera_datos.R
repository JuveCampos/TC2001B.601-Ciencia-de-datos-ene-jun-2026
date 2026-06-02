# =============================================================================
# Generador de datos SINTÉTICOS — apostadores en línea
# (uso interno: produce datos.csv; el alumno NO ejecuta este archivo)
# =============================================================================
# Construye 500 cuentas de una plataforma de apuestas en línea con CUATRO
# perfiles latentes de comportamiento. El alumno NO conoce estos perfiles:
# debe redescubrirlos con PCA + clustering. Todo es ficticio.
options(scipen = 999)
suppressMessages(library(tidyverse))

set.seed(2026)

# Tamaño de cada perfil latente (la "verdad oculta") --------------------------
#   A: recreativo ocasional        (juega poco, apuesta poco, sin señales)
#   B: entusiasta controlado       (juega seguido pero retira y no persigue)
#   C: en riesgo / problemático     (madrugada, persigue pérdidas, no retira)
#   D: gran apostador ("ballena")   (montos enormes pero controlado)
tam <- c(A = 200, B = 150, C = 90, D = 60)
grupo <- rep(names(tam), times = tam)
n <- length(grupo)

# Función auxiliar: normal truncada a un mínimo (evita valores imposibles) ----
rnorm_min <- function(media, sd, minimo = 0) {
  pmax(minimo, rnorm(length(media), media, sd))
}

# Medias por perfil para cada indicador ---------------------------------------
m <- function(a, b, c, d) c(A = a, B = b, C = c, D = d)[grupo]

datos <- tibble(
  jugador_id = sprintf("JUG%04d", 1:n),

  # Frecuencia e intensidad de juego
  sesiones_semana       = round(rnorm_min(m(2, 5, 12, 4),   m(1, 1.5, 3, 1.5))),
  duracion_sesion_min   = round(rnorm_min(m(20, 45, 95, 60), m(8, 12, 22, 18))),
  velocidad_apuestas_min = round(rnorm_min(m(3, 6, 14, 8),  m(1, 1.5, 3, 2)), 1),
  num_juegos_distintos  = round(rnorm_min(m(2, 6, 5, 4),    m(1, 1.5, 1.5, 1.5), 1)),

  # Dinero (apuesta y depósitos)
  apuesta_promedio_mxn  = round(rnorm_min(m(40, 120, 250, 1200),
                                          m(15, 40, 80, 350))),
  num_depositos_mes     = round(rnorm_min(m(1.5, 3, 9, 4),  m(0.7, 1, 2.5, 1.5))),

  # Señales de comportamiento de riesgo
  pct_juego_madrugada   = round(rnorm_min(m(5, 12, 45, 10), m(3, 5, 12, 6)), 1),
  pct_incremento_tras_perdida = round(rnorm_min(m(2, 8, 40, 12),
                                                m(2, 4, 12, 6)), 1),
  retiros_mes           = round(rnorm_min(m(0.8, 2.5, 0.3, 2.0),
                                          m(0.5, 1, 0.4, 1)), 1),
  ratio_perdida_pct     = round(pmin(98, rnorm_min(m(30, 45, 75, 50),
                                                   m(10, 12, 12, 14))), 1),

  # Antigüedad de la cuenta (poco informativa: "ruido" deliberado)
  dias_desde_registro   = round(rnorm_min(m(400, 600, 300, 800),
                                          m(150, 200, 150, 250), 30))
)

# Depósito mensual: COLINEAL con apuesta y número de depósitos (redundancia
# deliberada para discutirla en clase). Se construye a partir de ellos + ruido.
datos <- datos %>%
  mutate(
    deposito_mensual_mxn = round(
      apuesta_promedio_mxn * num_depositos_mes * runif(n, 0.8, 1.2) +
        rnorm(n, 0, 200)
    ),
    deposito_mensual_mxn = pmax(0, deposito_mensual_mxn)
  )

# Introducimos ~3% de NAs en deposito_mensual_mxn (cuentas con registro
# incompleto), para motivar la imputación en el flujo.
set.seed(7)
idx_na <- sample(n, size = round(0.03 * n))
datos$deposito_mensual_mxn[idx_na] <- NA

# Desordenamos las filas para que los perfiles no queden contiguos ------------
datos <- datos %>% slice_sample(prop = 1)

# Guardamos SIN la etiqueta de perfil (es la estructura que el alumno descubre)
write_csv(datos, "ejercicio_1/datos.csv")

cat("datos.csv (apostadores) generado:", nrow(datos), "filas x",
    ncol(datos), "columnas\n")
cat("NAs en deposito_mensual_mxn:", sum(is.na(datos$deposito_mensual_mxn)), "\n")
