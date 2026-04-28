# 00_preparar_proyecto_y_datos.R
# ------------------------------------------------------------
# Proposito:
# Este script prepara el proyecto una sola vez:
# - Crea las carpetas data/ y outputs/
# - Genera los tres datasets sinteticos usados por los ejercicios
# - Guarda los CSV en data/
#
# Los scripts 01, 02 y 03 ya no simulan datos ni crean carpetas: solo leen
# estos CSV y realizan el analisis de regresion.
# ------------------------------------------------------------

library(tidyverse)

set.seed(2026)

dir.create("data", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)

# 1) Dataset: consumo electrico residencial ---------------------------------
n_hogares <- 420

energia <- tibble(
  hogar_id = str_c("H", str_pad(1:n_hogares, width = 4, pad = "0")),
  temp_promedio_c = rnorm(n_hogares, mean = 25, sd = 5),
  metros_cuadrados = rlnorm(n_hogares, meanlog = log(92), sdlog = 0.35),
  ocupantes = sample(1:6, n_hogares, replace = TRUE, prob = c(.12, .24, .27, .20, .11, .06)),
  antiguedad_anios = pmax(0, round(rnorm(n_hogares, mean = 24, sd = 13))),
  aislamiento = sample(c("basico", "medio", "alto"), n_hogares, replace = TRUE, prob = c(.35, .45, .20)),
  tarifa_horaria = sample(c("fija", "variable"), n_hogares, replace = TRUE, prob = c(.62, .38))
) %>%
  mutate(
    aislamiento = factor(aislamiento, levels = c("basico", "medio", "alto")),
    tarifa_horaria = factor(tarifa_horaria, levels = c("fija", "variable")),
    grados_calor = pmax(temp_promedio_c - 22, 0),
    efecto_aislamiento = case_when(
      aislamiento == "medio" ~ -38,
      aislamiento == "alto" ~ -82,
      TRUE ~ 0
    ),
    interaccion_alto_m2 = if_else(aislamiento == "alto", -0.20 * metros_cuadrados, 0),
    ruido = rnorm(n_hogares, mean = 0, sd = 48),
    consumo_kwh = 155 +
      8.5 * grados_calor +
      1.15 * metros_cuadrados +
      24 * ocupantes +
      1.8 * antiguedad_anios +
      efecto_aislamiento +
      interaccion_alto_m2 +
      if_else(tarifa_horaria == "variable", -22, 0) +
      ruido
  ) %>%
  select(
    hogar_id, consumo_kwh, temp_promedio_c, grados_calor, metros_cuadrados,
    ocupantes, antiguedad_anios, aislamiento, tarifa_horaria
  )

energia %>%
  write_csv("data/energia_hogares_sintetica.csv")

# 2) Dataset: calidad del aire ----------------------------------------------
n_dias <- 520

calidad_aire <- tibble(
  dia = seq.Date(from = as.Date("2024-01-01"), by = "day", length.out = n_dias),
  estacion = factor(
    case_when(
      lubridate::month(dia) %in% c(12, 1, 2) ~ "invierno",
      lubridate::month(dia) %in% c(3, 4, 5) ~ "primavera",
      lubridate::month(dia) %in% c(6, 7, 8) ~ "verano",
      TRUE ~ "otono"
    ),
    levels = c("invierno", "primavera", "verano", "otono")
  ),
  indice_trafico = rnorm(n_dias, mean = 70, sd = 12),
  viento_kmh = pmax(2, rnorm(n_dias, mean = 11, sd = 4)),
  humedad = pmin(95, pmax(20, rnorm(n_dias, mean = 62, sd = 13))),
  temperatura_c = rnorm(n_dias, mean = 21, sd = 5)
) %>%
  mutate(
    velocidad_promedio = 48 - 0.28 * indice_trafico + rnorm(n_dias, 0, 3.5),
    no2_ppb = 8 + 0.42 * indice_trafico + rnorm(n_dias, 0, 5),
    co_ppm = 0.25 + 0.011 * indice_trafico + rnorm(n_dias, 0, 0.08),
    entregas_urbanas = 1200 + 13 * indice_trafico + rnorm(n_dias, 0, 110),
    lluvia_mm = rgamma(n_dias, shape = 1.3, rate = 0.45),
    inversion_termica = rbinom(n_dias, size = 1, prob = if_else(estacion == "invierno", .35, .10)),
    efecto_estacion = case_when(
      estacion == "invierno" ~ 7,
      estacion == "otono" ~ 3,
      estacion == "verano" ~ -4,
      TRUE ~ 0
    ),
    pm25_ug_m3 = 12 +
      0.12 * indice_trafico +
      0.35 * no2_ppb +
      1.8 * co_ppm -
      0.75 * viento_kmh +
      0.08 * humedad -
      0.55 * lluvia_mm +
      6.5 * inversion_termica +
      efecto_estacion +
      rnorm(n_dias, 0, 5)
  ) %>%
  select(-efecto_estacion)

calidad_aire %>%
  write_csv("data/calidad_aire_sintetica.csv")

# 3) Dataset: consultas respiratorias ---------------------------------------
n_semanas <- 180

clinicas <- tibble(
  semana = seq.Date(from = as.Date("2022-01-03"), by = "week", length.out = n_semanas),
  temp_min_c = rnorm(n_semanas, mean = 12, sd = 6),
  humedad = pmin(98, pmax(25, rnorm(n_semanas, mean = 68, sd = 12))),
  pm25 = pmax(4, rnorm(n_semanas, mean = 22, sd = 8)),
  influenza_google = rgamma(n_semanas, shape = 2.2, rate = 0.18),
  movilidad_transporte = rnorm(n_semanas, mean = 100, sd = 14),
  dias_feriados = rbinom(n_semanas, size = 2, prob = .12),
  vacunacion_pct = pmin(95, pmax(35, 48 + seq_len(n_semanas) * .18 + rnorm(n_semanas, 0, 5))),
  lluvia_mm = rgamma(n_semanas, shape = 1.5, rate = 0.35),
  school_in_session = rbinom(n_semanas, size = 1, prob = .78)
) %>%
  mutate(
    frio = pmax(15 - temp_min_c, 0),
    busquedas_lag1 = dplyr::lag(influenza_google, default = first(influenza_google)),
    pm25_lag1 = dplyr::lag(pm25, default = first(pm25)),
    llamadas_info = rnorm(n_semanas, 250, 40),
    ocupacion_hospitalaria_general = rnorm(n_semanas, 72, 7),
    costo_transporte = rnorm(n_semanas, 1.2, .12),
    humedad_lag1 = dplyr::lag(humedad, default = first(humedad)),
    lluvia_lag1 = dplyr::lag(lluvia_mm, default = first(lluvia_mm)),
    tendencia = row_number(),
    semana_del_anio = as.integer(format(semana, "%U")),
    ruido_redes_sociales = rnorm(n_semanas),
    ruido_administrativo = rnorm(n_semanas),
    consultas_respiratorias = 95 +
      4.8 * frio +
      1.9 * busquedas_lag1 +
      0.9 * pm25_lag1 +
      12 * school_in_session -
      0.55 * vacunacion_pct -
      7.5 * dias_feriados +
      rnorm(n_semanas, 0, 18)
  ) %>%
  select(
    semana, consultas_respiratorias, temp_min_c, frio, humedad, humedad_lag1,
    pm25, pm25_lag1, influenza_google, busquedas_lag1, movilidad_transporte,
    dias_feriados, vacunacion_pct, lluvia_mm, lluvia_lag1, school_in_session,
    llamadas_info, ocupacion_hospitalaria_general, costo_transporte, tendencia,
    semana_del_anio, ruido_redes_sociales, ruido_administrativo
  )

clinicas %>%
  write_csv("data/clinicas_respiratorias_sintetica.csv")

message("Proyecto preparado: carpetas data/ y outputs/ creadas; CSV sinteticos guardados en data/.")
