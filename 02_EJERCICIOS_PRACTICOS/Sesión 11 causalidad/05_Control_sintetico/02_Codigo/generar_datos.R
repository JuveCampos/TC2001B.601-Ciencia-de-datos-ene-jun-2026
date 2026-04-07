# ============================================================
# Generacion de datos sinteticos para Control Sintetico
# Inspirado en Abadie, Diamond & Hainmueller (2010)
# Tema: efecto de legislacion anti-tabaco sobre ventas de
# cigarrillos per capita
# ============================================================

library(tidyverse)

set.seed(789)

# --- Parametros del panel ---
n_estados <- 31        # 1 tratado + 30 controles
n_anios <- 20          # 10 pre-tratamiento + 10 post-tratamiento
anio_inicio <- 1980
anio_tratamiento <- 1990  # El tratamiento ocurre en 1990
anios <- anio_inicio:(anio_inicio + n_anios - 1)

# --- Nombres de los estados ---
# Estado 1 es el tratado (similar a California)
nombres_estados <- c(
  "California",
  paste0("Estado_", sprintf("%02d", 1:30))
)

# --- Generar efectos fijos por estado ---
# Cada estado tiene un nivel base de consumo diferente
efecto_fijo_estado <- c(
  120,  # California: consumo base alto
  rnorm(30, mean = 110, sd = 15)
)

# --- Generar tendencias especificas por estado ---
# Cada estado tiene una tendencia temporal ligeramente diferente
tendencia_estado <- c(
  -1.5,  # California: tendencia decreciente moderada
  rnorm(30, mean = -1.0, sd = 0.4)
)

# --- Generar factores latentes (para que algunos estados se
#     parezcan mas a California que otros) ---
# Factor 1: nivel de urbanizacion (correlacionado con consumo)
factor_urbano <- c(
  0.85,  # California: muy urbano
  runif(30, min = 0.3, max = 0.9)
)

# Factor 2: ingreso per capita relativo
factor_ingreso <- c(
  0.80,  # California: ingreso alto
  runif(30, min = 0.2, max = 0.95)
)

# --- Construir el panel ---
datos <- expand_grid(
  estado_id = 1:n_estados,
  anio = anios
) %>%
  mutate(
    estado = nombres_estados[estado_id],
    # Indicador de tratamiento
    tratado = as.integer(estado_id == 1),
    post = as.integer(anio >= anio_tratamiento),
    # Tiempo relativo al inicio
    t = anio - anio_inicio + 1
  )

# --- Generar la variable de resultado ---
datos <- datos %>%
  mutate(
    # Componente base: efecto fijo + tendencia temporal
    y_base = efecto_fijo_estado[estado_id] +
      tendencia_estado[estado_id] * t,
    # Componente de factores latentes
    y_factores = 10 * factor_urbano[estado_id] *
      sin(t / 5) +
      5 * factor_ingreso[estado_id] * cos(t / 7),
    # Ruido idiosincratico (relativamente pequeno para buen
    # ajuste pre-tratamiento)
    ruido = rnorm(n(), mean = 0, sd = 2.5),
    # Efecto del tratamiento: solo para California, solo
    # post-tratamiento. El efecto crece con el tiempo
    efecto_tratamiento = case_when(
      tratado == 1 & post == 1 ~
        -15 - 2.0 * (anio - anio_tratamiento),
      TRUE ~ 0
    ),
    # Variable de resultado final
    consumo_cigarrillos = y_base + y_factores + ruido +
      efecto_tratamiento
  ) %>%
  # Redondear y asegurar valores positivos
  mutate(
    consumo_cigarrillos = round(
      pmax(consumo_cigarrillos, 10), 1
    )
  )

# --- Seleccionar columnas finales ---
datos_final <- datos %>%
  select(
    estado_id,
    estado,
    anio,
    consumo_cigarrillos,
    tratado,
    post
  ) %>%
  arrange(estado_id, anio)

# --- Resumen rapido para verificar ---
# Promedio pre y post para California
datos_final %>%
  filter(tratado == 1) %>%
  group_by(post) %>%
  summarise(
    promedio_consumo = mean(consumo_cigarrillos),
    .groups = "drop"
  ) %>%
  print()

# Numero de estados y periodos
print(
  paste(
    "Estados:", n_distinct(datos_final$estado),
    "| Periodos:", n_distinct(datos_final$anio)
  )
)

# --- Guardar datos ---
write_csv(
  datos_final,
  "01_Datos/datos_control_sintetico.csv"
)

# Confirmacion
print("Datos guardados en 01_Datos/datos_control_sintetico.csv")
