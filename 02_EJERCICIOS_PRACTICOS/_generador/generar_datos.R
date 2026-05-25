# =============================================================================
# GENERADOR DE DATASETS SINTETICOS (NO SE ENTREGA AL ESTUDIANTE)
# Produce los 8 datasets de las sesiones 16-19 y copia los 3 reutilizados
# en la sesion 20. Escribe directo a las carpetas distribuidas.
# Cada bloque usa set.seed para reproducibilidad.
# =============================================================================
options(scipen = 999)
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

base_dir <- "/Users/jorgejuvenalcamposferreira/Documents/GitHub/TC2001B.601-Ciencia-de-datos-ene-jun-2026/02_EJERCICIOS_PRACTICOS"

inv_logit <- function(x) 1 / (1 + exp(-x))

# Helper para inyectar NAs a una proporcion dada
poner_na <- function(x, prop) {
  n <- length(x)
  idx <- sample(seq_len(n), size = floor(prop * n))
  x[idx] <- NA
  x
}

# =============================================================================
# S16 - EJ1: APROBACION DE CREDITO (clasificacion binaria)
# =============================================================================
set.seed(1601)
n <- 950
edad <- round(runif(n, 18, 75))
antiguedad_empleo_anios <- pmin(round(rgamma(n, shape = 2, scale = 3), 1), edad - 17)
antiguedad_empleo_anios <- pmax(antiguedad_empleo_anios, 0)
ingreso_mensual_mxn <- round(rlnorm(n, meanlog = 10.0, sdlog = 0.55))
ingreso_mensual_mxn <- pmin(ingreso_mensual_mxn, 250000)
score_historial <- round(pmin(pmax(rnorm(n, 650, 90), 300), 850))
num_creditos_activos <- rpois(n, 1.6)
plazo_meses <- sample(c(6, 12, 24, 36, 48, 60), n, replace = TRUE,
                      prob = c(.1, .2, .3, .2, .1, .1))
monto_solicitado_mxn <- round(ingreso_mensual_mxn * runif(n, 1.5, 8) / 1000) * 1000
# Variable colineal intencional: pago mensual estimado = monto / plazo
pago_mensual_estimado_mxn <- round(monto_solicitado_mxn / plazo_meses)
pct_deuda_ingreso <- round(pmin(pago_mensual_estimado_mxn / ingreso_mensual_mxn, 1.5), 3)
# Señal latente NO lineal: la decisión de crédito depende de casi todas las
# variables numéricas (distancia informativa para KNN) con curvatura
# (cuadráticas e interacciones tipo bolsa local), de modo que un k intermedio
# es óptimo. Todos los predictores son numéricos: ideal para KNN.
zs <- as.numeric(scale(score_historial))
zd <- as.numeric(scale(pct_deuda_ingreso))
zi <- as.numeric(scale(ingreso_mensual_mxn))
za <- as.numeric(scale(antiguedad_empleo_anios))
ze <- as.numeric(scale(edad))
zm <- as.numeric(scale(monto_solicitado_mxn))
zpl <- as.numeric(scale(plazo_meses))
eta <- 1.9 -
  0.9 * zs^2 - 0.7 * zd^2 - 0.4 * ze^2 +
  2.0 * cos(2.0 * zs) * cos(2.0 * zd) +
  1.7 * cos(2.0 * zi) * cos(2.0 * za) +
  1.4 * cos(2.0 * zm) * cos(2.0 * zpl) +
  0.4 * zs - 0.3 * zd
prob_aprob <- inv_logit(eta)
aprobado <- ifelse(runif(n) < prob_aprob, "si", "no")

credito <- tibble(
  id_solicitud = sprintf("CR%04d", seq_len(n)),
  edad,
  ingreso_mensual_mxn = poner_na(ingreso_mensual_mxn, 0.05),
  monto_solicitado_mxn,
  plazo_meses,
  pago_mensual_estimado_mxn,
  pct_deuda_ingreso,
  score_historial = poner_na(score_historial, 0.04),
  num_creditos_activos,
  antiguedad_empleo_anios,
  aprobado
)
write_csv(credito, file.path(base_dir, "Sesión 16 knn workflows/ejercicio_1/datos.csv"))
cat("S16-ej1 credito:", nrow(credito), "filas | aprobado:\n")
print(prop.table(table(credito$aprobado)))

# =============================================================================
# S16 - EJ2: POTABILIDAD DEL AGUA (clasificacion binaria) - PROBLEMA NUEVO
# =============================================================================
set.seed(1602)
n <- 820
ph <- rnorm(n, 7.0, 1.4)
dureza_mg_l <- rnorm(n, 196, 33)
solidos_disueltos_ppm <- rnorm(n, 22000, 8700)
cloraminas_ppm <- rnorm(n, 7.1, 1.6)
sulfatos_mg_l <- rnorm(n, 333, 41)
# conductividad colineal con solidos disueltos
conductividad_us_cm <- solidos_disueltos_ppm * 0.019 + rnorm(n, 0, 25)
carbono_organico_ppm <- rnorm(n, 14, 3.3)
trihalometanos_ug_l <- rnorm(n, 66, 16)
turbidez_ntu <- rnorm(n, 3.97, 0.78)

# Potabilidad NO lineal: óptimo en valores centrales de pH y turbidez, con
# estructura local repartida en casi todas las variables fisicoquímicas
# (distancia informativa) para que KNN tenga un k óptimo intermedio.
zp <- as.numeric(scale(ph))
zt <- as.numeric(scale(trihalometanos_ug_l))
zu <- as.numeric(scale(turbidez_ntu))
zc <- as.numeric(scale(carbono_organico_ppm))
zs <- as.numeric(scale(solidos_disueltos_ppm))
zd <- as.numeric(scale(dureza_mg_l))
zcl <- as.numeric(scale(cloraminas_ppm))
zsf <- as.numeric(scale(sulfatos_mg_l))
eta <- 2.2 -
  1.5 * zp^2 - 1.2 * zu^2 - 0.7 * zt^2 +
  2.0 * cos(2.0 * zp) * cos(2.0 * zt) +
  1.6 * cos(1.9 * zu) * cos(1.9 * zc) +
  0.6 * zd - 0.5 * zs + 0.5 * zcl - 0.4 * zsf - 0.6 * zt - 0.5 * zu
prob_pot <- inv_logit(eta)
potable <- ifelse(runif(n) < prob_pot, "si", "no")

agua <- tibble(
  ph = round(poner_na(ph, 0.03), 2),
  dureza_mg_l = round(dureza_mg_l, 1),
  solidos_disueltos_ppm = round(solidos_disueltos_ppm, 0),
  cloraminas_ppm = round(cloraminas_ppm, 2),
  sulfatos_mg_l = round(poner_na(sulfatos_mg_l, 0.06), 1),
  conductividad_us_cm = round(conductividad_us_cm, 1),
  carbono_organico_ppm = round(carbono_organico_ppm, 2),
  trihalometanos_ug_l = round(trihalometanos_ug_l, 1),
  turbidez_ntu = round(turbidez_ntu, 2),
  potable
)
write_csv(agua, file.path(base_dir, "Sesión 16 knn workflows/ejercicio_2/datos.csv"))
cat("\nS16-ej2 agua:", nrow(agua), "filas | potable:\n")
print(prop.table(table(agua$potable)))

# =============================================================================
# S17 - CLASIFICACION: APROBACION DE POLIZA DE SEGURO DE VIDA (binaria)
# =============================================================================
set.seed(1701)
n <- 880
edad <- round(runif(n, 18, 70))
sexo <- sample(c("F", "M"), n, replace = TRUE)
imc <- rnorm(n, 27.5, 4.8)
fumador <- ifelse(runif(n) < 0.2, "si", "no")
num_padecimientos_previos <- rpois(n, 0.8)
presion_sistolica <- rnorm(n, 122, 14) + 0.3 * (edad - 40)
colesterol_mg_dl <- rnorm(n, 195, 35) + 0.4 * (edad - 40) + 8 * (fumador == "si")
antecedente_familiar <- ifelse(runif(n) < 0.3, "si", "no")
meses_como_cliente <- round(rgamma(n, shape = 2, scale = 18))
region <- sample(c("norte", "centro", "sur", "bajio"), n, replace = TRUE)

# Aprobación NO lineal: perfil de bajo riesgo, óptimo en valores centrales de
# imc y edad, con estructura local en variables clínicas (distancia
# informativa) para que KNN tenga un k óptimo intermedio.
zedad <- as.numeric(scale(edad))
zi <- as.numeric(scale(imc))
zp <- as.numeric(scale(presion_sistolica))
zc <- as.numeric(scale(colesterol_mg_dl))
eta <- 3.2 -
  1.5 * zi^2 - 1.2 * zedad^2 +
  2.0 * cos(2.0 * zedad) * cos(2.0 * zi) +
  1.6 * cos(1.9 * zp) * cos(1.9 * zc) -
  1.6 * (fumador == "si") - 0.5 * num_padecimientos_previos -
  0.7 * (antecedente_familiar == "si") - 0.7 * zi
prob_apr <- inv_logit(eta)
aprobada <- ifelse(runif(n) < prob_apr, "si", "no")

seguro <- tibble(
  id_solicitante = sprintf("PZ%04d", seq_len(n)),
  edad,
  sexo,
  imc = round(imc, 1),
  fumador,
  num_padecimientos_previos,
  presion_sistolica = round(presion_sistolica, 0),
  colesterol_mg_dl = round(poner_na(colesterol_mg_dl, 0.05), 0),
  antecedente_familiar,
  meses_como_cliente,
  region,
  aprobada
)
write_csv(seguro, file.path(base_dir, "Sesión 17 ML +IA/clasificacion/datos.csv"))
cat("\nS17-clasif seguro:", nrow(seguro), "filas | aprobada:\n")
print(prop.table(table(seguro$aprobada)))

# =============================================================================
# S17 - REGRESION: COSTO MEDICO ANUAL (regresion, Y sesgada -> log)
# =============================================================================
set.seed(1702)
n <- 1050
edad <- round(runif(n, 18, 70))
sexo <- sample(c("F", "M"), n, replace = TRUE)
imc <- rnorm(n, 28, 5.5)
hijos <- rpois(n, 1.1)
fumador <- ifelse(runif(n) < 0.2, "si", "no")
region <- sample(c("norte", "centro", "sur", "bajio"), n, replace = TRUE)
actividad_fisica_hrs_sem <- pmax(round(rnorm(n, 3, 2), 1), 0)
num_consultas_anio <- rpois(n, 2.5)

# Costo log-normal: fumar y edad disparan el costo
log_costo <- 8.9 +
  0.030 * edad +
  0.045 * (imc - 28) +
  0.9 * (fumador == "si") +
  0.06 * num_consultas_anio +
  0.05 * hijos -
  0.02 * actividad_fisica_hrs_sem +
  rnorm(n, 0, 0.35)
costo_anual_mxn <- round(exp(log_costo))

costos <- tibble(
  id_paciente = sprintf("PA%05d", seq_len(n)),
  edad,
  sexo,
  imc = round(poner_na(imc, 0.04), 1),
  hijos,
  fumador,
  region,
  actividad_fisica_hrs_sem,
  num_consultas_anio,
  costo_anual_mxn
)
write_csv(costos, file.path(base_dir, "Sesión 17 ML +IA/regresion/datos.csv"))
cat("\nS17-regres costos:", nrow(costos), "filas | costo (resumen):\n")
print(summary(costos$costo_anual_mxn))

# =============================================================================
# S18 - EJ1: PERFIL QUIMICO DE VINOS (clustering)
# =============================================================================
set.seed(1801)
n_por <- c(220, 200, 180)   # tres perfiles latentes
gen_vino <- function(n, mu) {
  tibble(
    acidez_fija = rnorm(n, mu[1], 0.8),
    acidez_volatil = rnorm(n, mu[2], 0.12),
    acido_citrico = rnorm(n, mu[3], 0.10),
    azucar_residual = rnorm(n, mu[4], 1.2),
    cloruros = rnorm(n, mu[5], 0.015),
    dioxido_azufre_libre = rnorm(n, mu[6], 6),
    densidad = rnorm(n, mu[7], 0.002),
    ph = rnorm(n, mu[8], 0.12),
    sulfatos = rnorm(n, mu[9], 0.12),
    alcohol = rnorm(n, mu[10], 0.8)
  )
}
v1 <- gen_vino(n_por[1], c(7.0, 0.30, 0.35, 2.0, 0.045, 30, 0.9945, 3.30, 0.65, 11.5))
v2 <- gen_vino(n_por[2], c(8.5, 0.55, 0.10, 2.6, 0.085, 16, 0.9968, 3.18, 0.58, 9.8))
v3 <- gen_vino(n_por[3], c(6.6, 0.28, 0.40, 7.5, 0.050, 45, 0.9955, 3.22, 0.50, 10.5))
vinos <- bind_rows(v1, v2, v3)
# dioxido total colineal con libre
vinos <- vinos %>%
  mutate(dioxido_azufre_total = dioxido_azufre_libre * 3.1 + rnorm(n(), 20, 8)) %>%
  relocate(dioxido_azufre_total, .after = dioxido_azufre_libre)
# desordenar filas para no revelar clusters
vinos <- vinos[sample(nrow(vinos)), ]
vinos <- vinos %>%
  mutate(across(everything(), ~ round(.x, 4)))
write_csv(vinos, file.path(base_dir, "Sesión 18 Aprendizaje no supervisado/ejercicio_1/datos.csv"))
cat("\nS18-ej1 vinos:", nrow(vinos), "filas,", ncol(vinos), "columnas\n")

# =============================================================================
# S18 - EJ2: MUNICIPIOS POR INDICADORES SOCIOECONOMICOS (clustering) - NUEVO MX
# =============================================================================
set.seed(1802)
# cuatro perfiles: urbano desarrollado, urbano medio, rural transicion, rural marginado
gen_mun <- function(n, p) {
  tibble(
    pct_pobreza = pmin(pmax(rnorm(n, p[1], 6), 1), 99),
    pct_carencia_educativa = pmin(pmax(rnorm(n, p[2], 5), 1), 95),
    pct_carencia_salud = pmin(pmax(rnorm(n, p[3], 6), 1), 95),
    ingreso_promedio_mxn = pmax(rnorm(n, p[4], 1500), 1500),
    pct_poblacion_rural = pmin(pmax(rnorm(n, p[5], 8), 0), 100),
    pct_acceso_internet = pmin(pmax(rnorm(n, p[6], 7), 1), 99),
    densidad_pob_km2 = pmax(rnorm(n, p[7], p[7] * 0.4), 1),
    tasa_alfabetizacion = pmin(pmax(rnorm(n, p[8], 4), 50), 100)
  )
}
m1 <- gen_mun(130, c(22, 12, 15, 14500, 12, 78, 1200, 97))  # urbano desarrollado
m2 <- gen_mun(140, c(42, 28, 32, 8200, 35, 52, 350, 90))    # urbano medio
m3 <- gen_mun(120, c(58, 45, 50, 5200, 68, 30, 90, 82))     # rural transicion
m4 <- gen_mun(110, c(78, 62, 66, 3300, 88, 14, 35, 70))     # rural marginado
municipios <- bind_rows(m1, m2, m3, m4)
# grado de marginacion colineal con pobreza
municipios <- municipios %>%
  mutate(grado_marginacion_idx = round(0.012 * pct_pobreza +
                                         0.010 * pct_carencia_educativa +
                                         rnorm(n(), 0, 0.05), 3))
municipios <- municipios[sample(nrow(municipios)), ]
municipios <- municipios %>%
  mutate(
    clave_municipio = sprintf("MUN%03d", seq_len(n())),
    ingreso_promedio_mxn = round(poner_na(ingreso_promedio_mxn, 0.04)),
    across(where(is.numeric) & !c(ingreso_promedio_mxn), ~ round(.x, 2))
  ) %>%
  relocate(clave_municipio)
write_csv(municipios, file.path(base_dir, "Sesión 18 Aprendizaje no supervisado/ejercicio_2/datos.csv"))
cat("\nS18-ej2 municipios:", nrow(municipios), "filas,", ncol(municipios), "columnas\n")

# =============================================================================
# S19 - EJ1: CLIENTES PROMETEDORES EN CASINO EN LINEA (desbalanceada ~93/7)
# =============================================================================
set.seed(1901)
n <- 2100
edad <- round(runif(n, 18, 70))
dias_desde_registro <- round(rgamma(n, shape = 2, scale = 120))
num_sesiones_mes <- rpois(n, 6)
num_juegos_distintos <- pmin(rpois(n, 3) + 1, 12)
monto_apostado_mensual_mxn <- round(rlnorm(n, 7.5, 1.0))
monto_deposito_promedio_mxn <- round(monto_apostado_mensual_mxn * runif(n, 0.2, 0.6))
usa_app_movil <- ifelse(runif(n) < 0.55, "si", "no")
bono_reclamado <- ifelse(runif(n) < 0.4, "si", "no")
tasa_retorno_pct <- round(rnorm(n, 92, 4), 1)

# prometedor: rara combinacion de alta frecuencia + alto deposito + multi-juego
eta <- -5.0 +
  0.12 * num_sesiones_mes +
  0.00045 * monto_deposito_promedio_mxn +
  0.22 * num_juegos_distintos +
  0.5 * (usa_app_movil == "si")
prob_prom <- inv_logit(eta)
prometedor <- ifelse(runif(n) < prob_prom, "si", "no")

casino <- tibble(
  id_cliente = sprintf("CL%05d", seq_len(n)),
  edad,
  dias_desde_registro,
  num_sesiones_mes,
  num_juegos_distintos,
  monto_apostado_mensual_mxn,
  monto_deposito_promedio_mxn = poner_na(monto_deposito_promedio_mxn, 0.05),
  usa_app_movil,
  bono_reclamado,
  tasa_retorno_pct,
  prometedor
)
write_csv(casino, file.path(base_dir, "Sesión 19 Clases desbalanceadas/ejercicio_1/datos.csv"))
cat("\nS19-ej1 casino:", nrow(casino), "filas | prometedor:\n")
print(prop.table(table(casino$prometedor)))

# =============================================================================
# S19 - EJ2: FRAUDE EN TRANSACCIONES CON TARJETA (desbalanceada ~96/4) - NUEVO
# =============================================================================
set.seed(1902)
n <- 2600
monto_promedio_historico_mxn <- round(rlnorm(n, 6.5, 0.7))
ratio_monto <- rlnorm(n, 0, 0.5)
monto_transaccion_mxn <- round(monto_promedio_historico_mxn * ratio_monto)
hora_del_dia <- sample(0:23, n, replace = TRUE)
dias_desde_ultima_compra <- round(rgamma(n, shape = 1.5, scale = 6))
num_transacciones_24h <- rpois(n, 3)
distancia_km_domicilio <- round(rgamma(n, shape = 1.4, scale = 30), 1)
es_compra_internacional <- ifelse(runif(n) < 0.08, "si", "no")
categoria_comercio <- sample(c("abarrotes", "electronica", "viajes", "entretenimiento",
                               "restaurantes", "servicios"), n, replace = TRUE)

# fraude: monto muy alto vs historico, internacional, horas raras, lejos, alta frecuencia
eta <- -4.7 +
  1.1 * (ratio_monto > 3) +
  1.4 * (es_compra_internacional == "si") +
  0.9 * (hora_del_dia >= 1 & hora_del_dia <= 5) +
  0.010 * distancia_km_domicilio +
  0.18 * num_transacciones_24h
prob_fraude <- inv_logit(eta)
fraude <- ifelse(runif(n) < prob_fraude, "si", "no")

transacciones <- tibble(
  id_transaccion = sprintf("TX%06d", seq_len(n)),
  monto_transaccion_mxn,
  monto_promedio_historico_mxn,
  hora_del_dia,
  dias_desde_ultima_compra,
  num_transacciones_24h,
  distancia_km_domicilio = poner_na(distancia_km_domicilio, 0.04),
  es_compra_internacional,
  categoria_comercio,
  fraude
)
write_csv(transacciones, file.path(base_dir, "Sesión 19 Clases desbalanceadas/ejercicio_2/datos.csv"))
cat("\nS19-ej2 fraude:", nrow(transacciones), "filas | fraude:\n")
print(prop.table(table(transacciones$fraude)))

cat("\n=== GENERACION COMPLETA ===\n")

# =============================================================================
# S20 - OTROS MODELOS: reutiliza datasets de sesiones previas (copias)
# =============================================================================
file.copy(
  file.path(base_dir, "Sesión 16 knn workflows/ejercicio_1/datos.csv"),
  file.path(base_dir, "Sesion 20 Otros modelos/clasificacion/datos.csv"),
  overwrite = TRUE)
file.copy(
  file.path(base_dir, "Sesión 17 ML +IA/regresion/datos.csv"),
  file.path(base_dir, "Sesion 20 Otros modelos/regresion/datos.csv"),
  overwrite = TRUE)
file.copy(
  file.path(base_dir, "Sesión 18 Aprendizaje no supervisado/ejercicio_2/datos.csv"),
  file.path(base_dir, "Sesion 20 Otros modelos/clustering/datos.csv"),
  overwrite = TRUE)
