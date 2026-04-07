# ============================================================
# Analisis de Propensity Score Matching (PSM)
# ============================================================
# Este script implementa paso a paso el metodo de Propensity
# Score Matching para evaluar el efecto causal de un programa
# de capacitacion laboral sobre los ingresos, siguiendo la
# logica del estudio de Dehejia y Wahba (1999).
#
# Pasos:
#   1. Comparacion naive (sesgada)
#   2. Estimacion del propensity score
#   3. Verificacion de soporte comun
#   4. Emparejamiento manual (nearest neighbor)
#   5. Verificacion de balance
#   6. Estimacion del efecto del tratamiento
#   7. Analisis de sensibilidad
#
# NOTA: Implementamos el matching manualmente, sin depender
# del paquete MatchIt, para fines pedagogicos.
# ============================================================

# --- Cargar librerias ---
library(tidyverse)

# --- Leer datos ---
datos <- read_csv("01_Datos/datos_psm.csv",
  show_col_types = FALSE
)

# Vista rapida de los datos
glimpse(datos)

# ============================================================
# PASO 1: Comparacion naive (diferencia simple de medias)
# ============================================================
# Esta comparacion es SESGADA porque los grupos de tratamiento
# y control difieren en sus caracteristicas. La diferencia en
# ingresos refleja tanto el efecto del programa como las
# diferencias preexistentes entre los grupos.

comparacion_naive <- datos %>%
  group_by(tratamiento) %>%
  summarise(
    n = n(),
    re78_media = mean(re78),
    re78_sd = sd(re78),
    edad_media = mean(edad),
    educacion_media = mean(educacion),
    re74_media = mean(re74),
    re75_media = mean(re75),
    .groups = "drop"
  )

print(comparacion_naive)

efecto_naive <- comparacion_naive$re78_media[
  comparacion_naive$tratamiento == 1
] -
  comparacion_naive$re78_media[
    comparacion_naive$tratamiento == 0
  ]

cat("\n--- PASO 1: Comparacion naive ---\n")
cat("Diferencia naive en ingresos (re78):",
    round(efecto_naive, 0), "\n")
cat("ADVERTENCIA: Esta estimacion probablemente esta sesgada\n")
cat("porque los grupos no son comparables.\n\n")

# Veamos las diferencias en covariables entre grupos
# (evidencia del sesgo de seleccion)
cat("Diferencias en covariables entre grupos:\n")
datos %>%
  group_by(tratamiento) %>%
  summarise(
    across(
      c(edad, educacion, raza_negro, raza_hispano,
        casado, re74, re75),
      mean
    ),
    .groups = "drop"
  ) %>%
  print()

# ============================================================
# PASO 2: Estimacion del propensity score
# ============================================================
# El propensity score es la probabilidad de recibir el
# tratamiento dadas las covariables observadas.
# Lo estimamos con un modelo de regresion logistica.

cat("\n--- PASO 2: Estimacion del propensity score ---\n")

modelo_ps <- glm(
  tratamiento ~ edad + educacion + raza_negro +
    raza_hispano + casado + re74 + re75,
  data = datos,
  family = binomial(link = "logit")
)

summary(modelo_ps)

# Agregar el propensity score estimado a los datos
datos <- datos %>%
  mutate(ps = predict(modelo_ps, type = "response"))

# Resumen del propensity score por grupo
datos %>%
  group_by(tratamiento) %>%
  summarise(
    ps_media = mean(ps),
    ps_min = min(ps),
    ps_max = max(ps),
    ps_sd = sd(ps),
    .groups = "drop"
  ) %>%
  print()

# ============================================================
# VISUALIZACION 1: Distribucion del propensity score
# ============================================================

p1 <- ggplot(datos, aes(x = ps, fill = factor(tratamiento))) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(
    values = c("0" = "#2196F3", "1" = "#F44336"),
    labels = c("0" = "Control", "1" = "Tratamiento")
  ) +
  labs(
    title = "Distribucion del Propensity Score por grupo",
    subtitle = "Antes del emparejamiento",
    x = "Propensity Score (probabilidad estimada de tratamiento)",
    y = "Densidad",
    fill = "Grupo"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "top"
  )

print(p1)
ggsave("03_Visualizaciones/01_distribucion_propensity_score.png",
  p1, width = 8, height = 5, dpi = 300
)

# ============================================================
# VISUALIZACION 2: Soporte comun (common support)
# ============================================================
# El soporte comun es la region donde ambos grupos tienen
# representacion. Individuos fuera de esta region no tienen
# un "gemelo" comparable en el otro grupo.

cat("\n--- PASO 3: Verificacion de soporte comun ---\n")

ps_min_tratados <- min(datos$ps[datos$tratamiento == 1])
ps_max_tratados <- max(datos$ps[datos$tratamiento == 1])
ps_min_control <- min(datos$ps[datos$tratamiento == 0])
ps_max_control <- max(datos$ps[datos$tratamiento == 0])

soporte_comun_min <- max(ps_min_tratados, ps_min_control)
soporte_comun_max <- min(ps_max_tratados, ps_max_control)

cat("Rango PS tratados: [",
    round(ps_min_tratados, 4), ",",
    round(ps_max_tratados, 4), "]\n")
cat("Rango PS control:  [",
    round(ps_min_control, 4), ",",
    round(ps_max_control, 4), "]\n")
cat("Soporte comun:     [",
    round(soporte_comun_min, 4), ",",
    round(soporte_comun_max, 4), "]\n")

p2 <- ggplot(datos, aes(
  x = factor(tratamiento,
    labels = c("Control", "Tratamiento")
  ),
  y = ps
)) +
  geom_jitter(
    aes(color = factor(tratamiento)),
    width = 0.2, alpha = 0.4, size = 1.5
  ) +
  geom_hline(
    yintercept = c(soporte_comun_min, soporte_comun_max),
    linetype = "dashed", color = "darkgreen", linewidth = 0.8
  ) +
  annotate("rect",
    xmin = -Inf, xmax = Inf,
    ymin = soporte_comun_min, ymax = soporte_comun_max,
    alpha = 0.1, fill = "green"
  ) +
  scale_color_manual(
    values = c("0" = "#2196F3", "1" = "#F44336"),
    guide = "none"
  ) +
  labs(
    title = "Soporte comun del Propensity Score",
    subtitle = paste0(
      "Region de soporte comun: [",
      round(soporte_comun_min, 3), ", ",
      round(soporte_comun_max, 3), "]"
    ),
    x = "Grupo",
    y = "Propensity Score"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

print(p2)
ggsave("03_Visualizaciones/02_soporte_comun.png",
  p2, width = 7, height = 6, dpi = 300
)

# ============================================================
# PASO 4: Emparejamiento manual (Nearest Neighbor)
# ============================================================
# Implementamos el emparejamiento por vecino mas cercano
# de forma manual. Para cada individuo tratado, buscamos
# el individuo del grupo de control con el propensity score
# mas similar (sin reemplazo).

cat("\n--- PASO 4: Emparejamiento (nearest neighbor) ---\n")

# Separar tratados y controles
tratados <- datos %>%
  filter(tratamiento == 1) %>%
  arrange(ps)

controles <- datos %>%
  filter(tratamiento == 0)

# Vector para registrar los IDs de controles ya usados
controles_usados <- c()

# Para cada tratado, encontrar el control mas cercano
# (sin reemplazo)
emparejamientos <- lapply(seq_len(nrow(tratados)), function(i) {
  ps_tratado <- tratados$ps[i]
  id_tratado <- tratados$id[i]

  # Controles disponibles (excluir los ya usados)
  disponibles <- controles %>%
    filter(!(id %in% controles_usados))

  # Encontrar el control con el PS mas cercano
  distancias <- abs(disponibles$ps - ps_tratado)
  idx_mejor <- which.min(distancias)
  id_control <- disponibles$id[idx_mejor]

  # Marcar como usado (efecto lateral via superasignacion)
  controles_usados <<- c(controles_usados, id_control)

  tibble(
    id_tratado = id_tratado,
    id_control = id_control,
    ps_tratado = ps_tratado,
    ps_control = disponibles$ps[idx_mejor],
    distancia_ps = distancias[idx_mejor]
  )
}) %>%
  bind_rows()

cat("Emparejamientos realizados:", nrow(emparejamientos), "\n")
cat("Distancia promedio en PS:",
    round(mean(emparejamientos$distancia_ps), 4), "\n")
cat("Distancia maxima en PS:",
    round(max(emparejamientos$distancia_ps), 4), "\n")

# Construir la muestra emparejada
ids_emparejados <- c(
  emparejamientos$id_tratado,
  emparejamientos$id_control
)

datos_match <- datos %>%
  filter(id %in% ids_emparejados)

cat("Observaciones en muestra emparejada:",
    nrow(datos_match), "\n")
cat("Tratados:", sum(datos_match$tratamiento == 1), "\n")
cat("Control:", sum(datos_match$tratamiento == 0), "\n")

# ============================================================
# PASO 5: Verificacion de balance
# ============================================================
# Despues del emparejamiento, verificamos que las covariables
# esten balanceadas entre grupos. Calculamos la diferencia
# estandarizada de medias (SMD) antes y despues.

cat("\n--- PASO 5: Verificacion de balance ---\n")

# Funcion para calcular la diferencia estandarizada de medias
calcular_smd <- function(data, var,
                         trat_var = "tratamiento") {
  tratados_vals <- data[[var]][data[[trat_var]] == 1]
  controles_vals <- data[[var]][data[[trat_var]] == 0]
  media_t <- mean(tratados_vals, na.rm = TRUE)
  media_c <- mean(controles_vals, na.rm = TRUE)
  sd_pooled <- sqrt(
    (var(tratados_vals, na.rm = TRUE) +
      var(controles_vals, na.rm = TRUE)) / 2
  )
  smd <- (media_t - media_c) / sd_pooled
  return(smd)
}

# Variables a verificar
covariables <- c(
  "edad", "educacion", "raza_negro",
  "raza_hispano", "casado", "re74", "re75"
)

# Calcular SMD antes y despues del emparejamiento
balance <- tibble(
  variable = covariables,
  smd_antes = sapply(
    covariables,
    function(v) calcular_smd(datos, v)
  ),
  smd_despues = sapply(
    covariables,
    function(v) calcular_smd(datos_match, v)
  )
)

cat("\nDiferencias estandarizadas de medias (SMD):\n")
cat("(Valores < 0.1 indican buen balance)\n\n")
balance %>%
  mutate(
    smd_antes = round(smd_antes, 4),
    smd_despues = round(smd_despues, 4),
    mejora = ifelse(
      abs(smd_despues) < abs(smd_antes),
      "Si", "No"
    )
  ) %>%
  print()

# ============================================================
# VISUALIZACION 3: Love plot (balance antes y despues)
# ============================================================

balance_long <- balance %>%
  pivot_longer(
    cols = c(smd_antes, smd_despues),
    names_to = "momento",
    values_to = "smd"
  ) %>%
  mutate(
    momento = case_when(
      momento == "smd_antes" ~
        "Antes del emparejamiento",
      momento == "smd_despues" ~
        "Despues del emparejamiento"
    ),
    momento = factor(momento, levels = c(
      "Antes del emparejamiento",
      "Despues del emparejamiento"
    ))
  )

p3 <- ggplot(
  balance_long,
  aes(
    x = abs(smd),
    y = reorder(variable, abs(smd)),
    shape = momento, color = momento
  )
) +
  geom_point(size = 3.5) +
  geom_vline(
    xintercept = 0.1,
    linetype = "dashed", color = "red", linewidth = 0.7
  ) +
  geom_vline(
    xintercept = 0,
    linetype = "solid", color = "gray50"
  ) +
  scale_color_manual(values = c(
    "Antes del emparejamiento" = "#F44336",
    "Despues del emparejamiento" = "#4CAF50"
  )) +
  scale_shape_manual(values = c(
    "Antes del emparejamiento" = 17,
    "Despues del emparejamiento" = 16
  )) +
  labs(
    title = "Love Plot: Balance de covariables",
    subtitle = paste(
      "SMD antes y despues del emparejamiento",
      "(linea roja = umbral 0.1)"
    ),
    x = "|Diferencia estandarizada de medias|",
    y = "Variable",
    color = NULL,
    shape = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "top"
  )

print(p3)
ggsave("03_Visualizaciones/03_love_plot_balance.png",
  p3, width = 9, height = 6, dpi = 300
)

# ============================================================
# VISUALIZACION 4: Distribucion del resultado por grupo
# ============================================================

# Antes del emparejamiento
p4a <- ggplot(datos, aes(
  x = re78,
  fill = factor(tratamiento)
)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(
    values = c("0" = "#2196F3", "1" = "#F44336"),
    labels = c("0" = "Control", "1" = "Tratamiento")
  ) +
  labs(
    title = "Distribucion de ingresos (re78)",
    subtitle = "Antes del emparejamiento - Muestra completa",
    x = "Ingresos en 1978 (dolares)",
    y = "Densidad",
    fill = "Grupo"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "top"
  )

# Despues del emparejamiento
p4b <- ggplot(datos_match, aes(
  x = re78,
  fill = factor(tratamiento)
)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(
    values = c("0" = "#2196F3", "1" = "#F44336"),
    labels = c("0" = "Control", "1" = "Tratamiento")
  ) +
  labs(
    title = "Distribucion de ingresos (re78)",
    subtitle = "Despues del emparejamiento - Muestra emparejada",
    x = "Ingresos en 1978 (dolares)",
    y = "Densidad",
    fill = "Grupo"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "top"
  )

print(p4a)
print(p4b)

ggsave("03_Visualizaciones/04a_distribucion_re78_antes.png",
  p4a, width = 8, height = 5, dpi = 300
)
ggsave("03_Visualizaciones/04b_distribucion_re78_despues.png",
  p4b, width = 8, height = 5, dpi = 300
)

# ============================================================
# VISUALIZACION 5: Balance de covariables (barras)
# ============================================================

balance_detalle <- bind_rows(
  datos %>%
    group_by(tratamiento) %>%
    summarise(
      across(all_of(covariables), mean),
      .groups = "drop"
    ) %>%
    mutate(momento = "Antes"),
  datos_match %>%
    group_by(tratamiento) %>%
    summarise(
      across(all_of(covariables), mean),
      .groups = "drop"
    ) %>%
    mutate(momento = "Despues")
) %>%
  pivot_longer(
    cols = all_of(covariables),
    names_to = "variable",
    values_to = "media"
  ) %>%
  mutate(
    grupo = factor(tratamiento,
      labels = c("Control", "Tratamiento")
    ),
    momento = factor(momento,
      levels = c("Antes", "Despues")
    )
  )

p5 <- ggplot(
  balance_detalle,
  aes(x = variable, y = media, fill = grupo)
) +
  geom_col(position = "dodge", alpha = 0.8) +
  facet_wrap(~momento, ncol = 2) +
  scale_fill_manual(values = c(
    "Control" = "#2196F3",
    "Tratamiento" = "#F44336"
  )) +
  labs(
    title = "Medias de covariables por grupo",
    subtitle = "Antes y despues del emparejamiento",
    x = "Variable",
    y = "Media",
    fill = "Grupo"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "top"
  )

print(p5)
ggsave("03_Visualizaciones/05_balance_covariables_medias.png",
  p5, width = 10, height = 6, dpi = 300
)

# ============================================================
# PASO 6: Estimacion del efecto del tratamiento (ATT)
# ============================================================
# ATT = Average Treatment Effect on the Treated
# Es la diferencia promedio en el resultado entre los tratados
# y sus controles emparejados.

cat("\n--- PASO 6: Estimacion del efecto del tratamiento ---\n")

# Diferencia simple en la muestra emparejada
efecto_match <- datos_match %>%
  group_by(tratamiento) %>%
  summarise(
    re78_media = mean(re78),
    .groups = "drop"
  )

att_estimado <- efecto_match$re78_media[
  efecto_match$tratamiento == 1
] -
  efecto_match$re78_media[
    efecto_match$tratamiento == 0
  ]

cat("ATT estimado (diferencia de medias en muestra",
    "emparejada):", round(att_estimado, 0), "\n")

# Prueba t para verificar significancia estadistica
test_t <- t.test(
  re78 ~ tratamiento,
  data = datos_match
)

cat("\nPrueba t de diferencia de medias:\n")
cat("  Diferencia estimada:",
    round(diff(rev(test_t$estimate)), 0), "\n")
cat("  Estadistico t:", round(test_t$statistic, 3), "\n")
cat("  Valor p:", format.pval(test_t$p.value, digits = 4), "\n")

if (test_t$p.value < 0.05) {
  cat("\n*** El efecto es ESTADISTICAMENTE SIGNIFICATIVO",
      "al 5% ***\n")
} else {
  cat("\nEl efecto NO es estadisticamente significativo",
      "al 5%\n")
}

# Tambien estimamos con regresion lineal en la muestra
# emparejada, controlando por covariables residuales
# (doble robustez)
modelo_att <- lm(
  re78 ~ tratamiento + edad + educacion + raza_negro +
    raza_hispano + casado + re74 + re75,
  data = datos_match
)

cat("\nEstimacion con regresion en muestra emparejada:\n")
cat("  Coeficiente del tratamiento:",
    round(coef(modelo_att)["tratamiento"], 0), "\n")
cat("  Error estandar:",
    round(summary(modelo_att)$coefficients[
      "tratamiento", "Std. Error"
    ], 0), "\n")
cat("  Valor p:",
    format.pval(summary(modelo_att)$coefficients[
      "tratamiento", "Pr(>|t|)"
    ], digits = 4), "\n")

# ============================================================
# PASO 7: Analisis de sensibilidad
# ============================================================
# Evaluamos la robustez usando diferentes estrategias:
# a) Con caliper (limitando la distancia maxima)
# b) Con reemplazo
# c) Con regresion ponderada por propensity score (IPW)

cat("\n--- PASO 7: Analisis de sensibilidad ---\n")

# 7a. Emparejamiento con caliper (0.05)
cat("\n7a. Emparejamiento con caliper (0.05):\n")

caliper <- 0.05
emparejamientos_caliper <- emparejamientos %>%
  filter(distancia_ps <= caliper)

ids_caliper <- c(
  emparejamientos_caliper$id_tratado,
  emparejamientos_caliper$id_control
)
datos_caliper <- datos %>%
  filter(id %in% ids_caliper)

att_caliper <- mean(
  datos_caliper$re78[datos_caliper$tratamiento == 1]
) -
  mean(datos_caliper$re78[datos_caliper$tratamiento == 0])

cat("  Pares dentro del caliper:",
    nrow(emparejamientos_caliper), "\n")
cat("  ATT estimado:", round(att_caliper, 0), "\n")

test_caliper <- t.test(
  re78 ~ tratamiento, data = datos_caliper
)
cat("  Valor p:", format.pval(
  test_caliper$p.value, digits = 4
), "\n")

# 7b. Emparejamiento con reemplazo
cat("\n7b. Emparejamiento con reemplazo:\n")

emparejamientos_wr <- lapply(
  seq_len(nrow(tratados)),
  function(i) {
    ps_tratado <- tratados$ps[i]
    distancias <- abs(controles$ps - ps_tratado)
    idx_mejor <- which.min(distancias)

    tibble(
      id_tratado = tratados$id[i],
      id_control = controles$id[idx_mejor],
      ps_tratado = ps_tratado,
      ps_control = controles$ps[idx_mejor]
    )
  }
) %>%
  bind_rows()

# Calcular ATT con reemplazo
# (ponderar controles usados multiples veces)
att_pares <- lapply(
  seq_len(nrow(emparejamientos_wr)),
  function(i) {
    re78_t <- datos$re78[
      datos$id == emparejamientos_wr$id_tratado[i]
    ]
    re78_c <- datos$re78[
      datos$id == emparejamientos_wr$id_control[i]
    ]
    re78_t - re78_c
  }
) %>%
  unlist()

att_reemplazo <- mean(att_pares)
se_reemplazo <- sd(att_pares) / sqrt(length(att_pares))
t_reemplazo <- att_reemplazo / se_reemplazo
p_reemplazo <- 2 * pt(-abs(t_reemplazo),
  df = length(att_pares) - 1
)

cat("  ATT estimado:", round(att_reemplazo, 0), "\n")
cat("  Error estandar:", round(se_reemplazo, 0), "\n")
cat("  Valor p:", format.pval(p_reemplazo, digits = 4), "\n")

# 7c. Ponderacion por probabilidad inversa (IPW)
cat("\n7c. Ponderacion por probabilidad inversa (IPW):\n")

datos_ipw <- datos %>%
  filter(
    ps >= soporte_comun_min,
    ps <= soporte_comun_max
  ) %>%
  mutate(
    # Pesos IPW para el ATT
    peso_ipw = ifelse(
      tratamiento == 1,
      1,
      ps / (1 - ps)
    )
  )

att_ipw <- weighted.mean(
  datos_ipw$re78[datos_ipw$tratamiento == 1],
  datos_ipw$peso_ipw[datos_ipw$tratamiento == 1]
) -
  weighted.mean(
    datos_ipw$re78[datos_ipw$tratamiento == 0],
    datos_ipw$peso_ipw[datos_ipw$tratamiento == 0]
  )

cat("  ATT estimado (IPW):", round(att_ipw, 0), "\n")

# --- Resumen de resultados ---
cat("\n============================================\n")
cat("RESUMEN DE RESULTADOS\n")
cat("============================================\n")
cat("Comparacion naive (sesgada):",
    round(efecto_naive, 0), "\n")
cat("ATT - Nearest neighbor (sin reemplazo):",
    round(att_estimado, 0), "\n")
cat("ATT - Nearest neighbor (con caliper):",
    round(att_caliper, 0), "\n")
cat("ATT - Nearest neighbor (con reemplazo):",
    round(att_reemplazo, 0), "\n")
cat("ATT - IPW (prob. inversa):",
    round(att_ipw, 0), "\n")
cat("ATT - Regresion en muestra emparejada:",
    round(coef(modelo_att)["tratamiento"], 0), "\n")
cat("============================================\n")
cat("NOTA: El efecto verdadero del tratamiento en\n")
cat("los datos simulados es de 1,800 dolares.\n")
cat("============================================\n")
