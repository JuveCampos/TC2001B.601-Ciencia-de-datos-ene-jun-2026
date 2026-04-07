# ============================================================
# Analisis de Control Sintetico
# Metodo implementado manualmente (sin paquete Synth)
# Inspirado en Abadie, Diamond & Hainmueller (2010)
# ============================================================

# --- Cargar librerias ---
library(tidyverse)
library(quadprog)  # Para optimizacion cuadratica con restricciones

# ============================================================
# PASO 1: Cargar y explorar los datos
# ============================================================

datos <- read_csv("01_Datos/datos_control_sintetico.csv")

# Vista general de los datos
glimpse(datos)

# Identificar la unidad tratada y el pool de donantes
estado_tratado <- datos %>%
  filter(tratado == 1) %>%
  pull(estado) %>%
  unique()

estados_donantes <- datos %>%
  filter(tratado == 0) %>%
  pull(estado) %>%
  unique()

print(paste("Unidad tratada:", estado_tratado))
print(paste("Numero de donantes:", length(estados_donantes)))

# Anio de tratamiento
anio_tratamiento <- datos %>%
  filter(tratado == 1, post == 1) %>%
  pull(anio) %>%
  min()

print(paste("Anio de tratamiento:", anio_tratamiento))

# ============================================================
# PASO 2: Visualizacion exploratoria - Spaghetti plot
# ============================================================

# Grafica de espagueti: todas las trayectorias estatales
# con California resaltada en color
p1 <- ggplot() +
  # Lineas de los estados de control (en gris)
  geom_line(
    data = datos %>% filter(tratado == 0),
    aes(x = anio, y = consumo_cigarrillos, group = estado),
    color = "gray70", alpha = 0.5, linewidth = 0.4
  ) +
  # Linea del estado tratado (en rojo)
  geom_line(
    data = datos %>% filter(tratado == 1),
    aes(x = anio, y = consumo_cigarrillos),
    color = "#E41A1C", linewidth = 1.2
  ) +
  # Linea vertical en el anio de tratamiento
  geom_vline(
    xintercept = anio_tratamiento,
    linetype = "dashed", color = "black", linewidth = 0.6
  ) +
  annotate(
    "text", x = anio_tratamiento + 0.3,
    y = max(datos$consumo_cigarrillos) * 0.95,
    label = "Tratamiento", hjust = 0, fontface = "italic",
    size = 3.5
  ) +
  labs(
    title = "Consumo de cigarrillos per capita por estado",
    subtitle = paste(
      "Linea roja:", estado_tratado,
      "(tratado) | Lineas grises: estados de control"
    ),
    x = "Anio",
    y = "Consumo per capita (paquetes)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

print(p1)

ggsave(
  "03_Visualizaciones/01_spaghetti_plot.png", p1,
  width = 10, height = 6, dpi = 300
)

# ============================================================
# PASO 3: Construir el control sintetico
# ============================================================

# La idea es encontrar pesos w_j (no negativos, que sumen 1)
# para los estados donantes, de modo que la combinacion
# ponderada replique lo mejor posible la trayectoria de
# California en el periodo PRE-tratamiento.
#
# Matematicamente, minimizamos:
#   sum_t (Y_tratado_t - sum_j w_j * Y_j_t)^2
#   sujeto a: w_j >= 0, sum(w_j) = 1
#
# Esto es un problema de minimos cuadrados con restricciones,
# que podemos resolver con programacion cuadratica.

# --- Preparar las matrices de datos ---

# Periodos pre-tratamiento
anios_pre <- datos %>%
  filter(post == 0) %>%
  pull(anio) %>%
  unique() %>%
  sort()

# Vector de resultados del estado tratado (pre-tratamiento)
y_tratado <- datos %>%
  filter(tratado == 1, post == 0) %>%
  arrange(anio) %>%
  pull(consumo_cigarrillos)

# Matriz de resultados de los donantes (pre-tratamiento)
# Cada columna es un estado donante, cada fila un periodo
mat_donantes <- datos %>%
  filter(tratado == 0, post == 0) %>%
  select(estado, anio, consumo_cigarrillos) %>%
  pivot_wider(
    names_from = estado,
    values_from = consumo_cigarrillos
  ) %>%
  arrange(anio) %>%
  select(-anio) %>%
  as.matrix()

n_donantes <- ncol(mat_donantes)
n_periodos_pre <- length(anios_pre)

# --- Resolver el problema de optimizacion cuadratica ---
#
# El problema de minimizar ||y - X*w||^2 con restricciones
# w >= 0 y sum(w) = 1 se puede formular como:
#
#   min  0.5 * w' * (X'X) * w - (X'y)' * w
#   s.a. A' * w >= b
#
# donde las restricciones son:
#   1. sum(w) = 1   (igualdad, expresada como >= y <=)
#   2. w_j >= 0     (no negatividad)

# Matriz D (Hessiana): X'X
# Nota: sumamos un pequeno valor a la diagonal para
# asegurar que la matriz sea definida positiva
D_mat <- t(mat_donantes) %*% mat_donantes
D_mat <- D_mat + diag(1e-6, n_donantes)

# Vector d: X'y
d_vec <- t(mat_donantes) %*% y_tratado

# Restricciones:
# Fila 1: sum(w) = 1 (restriccion de igualdad)
# Filas 2 a n_donantes+1: w_j >= 0 (no negatividad)
A_mat <- cbind(
  rep(1, n_donantes),    # sum(w) = 1
  diag(n_donantes)       # w_j >= 0
)

b_vec <- c(1, rep(0, n_donantes))

# Resolver con solve.QP
# meq = 1 indica que la primera restriccion es de igualdad
resultado_qp <- solve.QP(
  Dmat = D_mat,
  dvec = d_vec,
  Amat = A_mat,
  bvec = b_vec,
  meq = 1
)

# Extraer los pesos optimos
pesos_optimos <- resultado_qp$solution

# Limpiar pesos muy pequenos (artefactos numericos)
pesos_optimos[pesos_optimos < 1e-4] <- 0
pesos_optimos <- pesos_optimos / sum(pesos_optimos)

# Crear un tibble con los pesos por estado donante
tabla_pesos <- tibble(
  estado = colnames(mat_donantes),
  peso = round(pesos_optimos, 4)
) %>%
  arrange(desc(peso))

# Mostrar estados con peso positivo
print("--- Pesos del control sintetico ---")
tabla_pesos %>%
  filter(peso > 0) %>%
  print(n = Inf)

print(paste(
  "Numero de donantes con peso positivo:",
  sum(tabla_pesos$peso > 0)
))

# ============================================================
# PASO 4: Calcular el control sintetico para todos los
#         periodos (pre y post tratamiento)
# ============================================================

# Matriz completa de donantes (todos los periodos)
mat_donantes_completa <- datos %>%
  filter(tratado == 0) %>%
  select(estado, anio, consumo_cigarrillos) %>%
  pivot_wider(
    names_from = estado,
    values_from = consumo_cigarrillos
  ) %>%
  arrange(anio)

anios_todos <- mat_donantes_completa$anio

mat_valores <- mat_donantes_completa %>%
  select(-anio) %>%
  as.matrix()

# El control sintetico es la combinacion ponderada
y_sintetico <- as.numeric(mat_valores %*% pesos_optimos)

# Trayectoria del estado tratado (todos los periodos)
y_tratado_completo <- datos %>%
  filter(tratado == 1) %>%
  arrange(anio) %>%
  pull(consumo_cigarrillos)

# Crear tibble con resultados
resultados <- tibble(
  anio = anios_todos,
  tratado = y_tratado_completo,
  sintetico = round(y_sintetico, 2),
  brecha = round(y_tratado_completo - y_sintetico, 2)
)

print("--- Trayectorias: Tratado vs. Sintetico ---")
print(resultados, n = Inf)

# ============================================================
# PASO 5: Grafica principal - Tratado vs. Control Sintetico
# ============================================================

p2 <- ggplot(resultados, aes(x = anio)) +
  geom_line(
    aes(y = tratado, color = "California (tratado)"),
    linewidth = 1.1
  ) +
  geom_line(
    aes(y = sintetico, color = "Control sintetico"),
    linewidth = 1.1, linetype = "dashed"
  ) +
  geom_vline(
    xintercept = anio_tratamiento,
    linetype = "dashed", color = "gray40", linewidth = 0.5
  ) +
  annotate(
    "text", x = anio_tratamiento - 0.3,
    y = max(resultados$tratado) * 1.02,
    label = "Tratamiento", hjust = 1, fontface = "italic",
    size = 3.5
  ) +
  scale_color_manual(
    values = c(
      "California (tratado)" = "#E41A1C",
      "Control sintetico" = "#377EB8"
    )
  ) +
  labs(
    title = "California vs. su control sintetico",
    subtitle = paste(
      "Consumo de cigarrillos per capita |",
      "Tratamiento:", anio_tratamiento
    ),
    x = "Anio",
    y = "Consumo per capita (paquetes)",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

print(p2)

ggsave(
  "03_Visualizaciones/02_tratado_vs_sintetico.png", p2,
  width = 10, height = 6, dpi = 300
)

# ============================================================
# PASO 6: Grafica de la brecha (gap plot)
# ============================================================

# La brecha es la diferencia entre el tratado y el sintetico.
# Antes del tratamiento, deberia ser cercana a cero.
# Despues del tratamiento, muestra el efecto causal estimado.

p3 <- ggplot(resultados, aes(x = anio, y = brecha)) +
  geom_line(color = "#E41A1C", linewidth = 1.1) +
  geom_hline(
    yintercept = 0,
    linetype = "solid", color = "gray50", linewidth = 0.4
  ) +
  geom_vline(
    xintercept = anio_tratamiento,
    linetype = "dashed", color = "gray40", linewidth = 0.5
  ) +
  annotate(
    "text", x = anio_tratamiento - 0.3, y = max(resultados$brecha),
    label = "Tratamiento", hjust = 1, fontface = "italic",
    size = 3.5
  ) +
  # Sombrear la zona post-tratamiento
  annotate(
    "rect",
    xmin = anio_tratamiento, xmax = max(anios_todos),
    ymin = -Inf, ymax = Inf,
    alpha = 0.1, fill = "#E41A1C"
  ) +
  labs(
    title = "Brecha: California - Control sintetico",
    subtitle = paste(
      "Diferencia en consumo per capita |",
      "Valores negativos = reduccion por tratamiento"
    ),
    x = "Anio",
    y = "Brecha (tratado - sintetico)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

print(p3)

ggsave(
  "03_Visualizaciones/03_brecha_gap.png", p3,
  width = 10, height = 6, dpi = 300
)

# ============================================================
# PASO 7: Calcular el efecto promedio post-tratamiento
# ============================================================

efecto_promedio <- resultados %>%
  filter(anio >= anio_tratamiento) %>%
  summarise(
    efecto_promedio = mean(brecha),
    efecto_mediana = median(brecha),
    efecto_min = min(brecha),
    efecto_max = max(brecha)
  )

print("--- Efecto estimado del tratamiento ---")
print(efecto_promedio)

# ============================================================
# PASO 8: Pruebas de placebo
# ============================================================

# Para cada estado donante, aplicamos el mismo metodo como
# si ESE estado hubiera sido el tratado. Esto nos da una
# distribucion de "efectos placebo" contra la cual comparar
# el efecto real de California.
#
# Si el efecto de California es mucho mas grande que los
# efectos placebo, tenemos evidencia estadistica de un
# efecto genuino.

# Funcion para calcular el control sintetico de una unidad
calcular_control_sintetico <- function(id_tratado, datos) {

  # Datos del estado "tratado" (placebo)
  y_trat <- datos %>%
    filter(estado_id == id_tratado, post == 0) %>%
    arrange(anio) %>%
    pull(consumo_cigarrillos)

  # Datos de los donantes (todos excepto el "tratado")
  mat_don <- datos %>%
    filter(estado_id != id_tratado, post == 0) %>%
    select(estado, anio, consumo_cigarrillos) %>%
    pivot_wider(
      names_from = estado,
      values_from = consumo_cigarrillos
    ) %>%
    arrange(anio) %>%
    select(-anio) %>%
    as.matrix()

  n_don <- ncol(mat_don)

  # Configurar y resolver la optimizacion cuadratica
  D <- t(mat_don) %*% mat_don + diag(1e-6, n_don)
  d <- t(mat_don) %*% y_trat
  A <- cbind(rep(1, n_don), diag(n_don))
  b <- c(1, rep(0, n_don))

  # Intentar resolver; si falla, devolver NA
  sol <- tryCatch(
    solve.QP(Dmat = D, dvec = d, Amat = A, bvec = b, meq = 1),
    error = function(e) NULL
  )

  if (is.null(sol)) {
    return(tibble(
      anio = sort(unique(datos$anio)),
      brecha = NA_real_
    ))
  }

  w <- sol$solution
  w[w < 1e-4] <- 0
  w <- w / sum(w)

  # Calcular sintetico para todos los periodos
  mat_don_full <- datos %>%
    filter(estado_id != id_tratado) %>%
    select(estado, anio, consumo_cigarrillos) %>%
    pivot_wider(
      names_from = estado,
      values_from = consumo_cigarrillos
    ) %>%
    arrange(anio)

  anios_full <- mat_don_full$anio

  y_sint <- as.numeric(
    mat_don_full %>% select(-anio) %>% as.matrix() %*% w
  )

  y_trat_full <- datos %>%
    filter(estado_id == id_tratado) %>%
    arrange(anio) %>%
    pull(consumo_cigarrillos)

  tibble(
    anio = anios_full,
    brecha = y_trat_full - y_sint
  )
}

# --- Ejecutar placebos para todos los estados ---
# (incluyendo el estado realmente tratado, id = 1)

ids_todos <- sort(unique(datos$estado_id))

# Funcion auxiliar para buscar el nombre del estado
nombres_estado_lookup <- function(id, datos) {
  datos %>%
    filter(estado_id == id) %>%
    pull(estado) %>%
    unique()
}

# Aplicar el metodo a cada estado
# Usamos lapply por claridad y compatibilidad
print("Ejecutando pruebas de placebo (puede tomar un momento)...")

resultados_placebo <- lapply(ids_todos, function(id) {
  res <- calcular_control_sintetico(id, datos)
  res$estado_id <- id
  res$estado <- nombres_estado_lookup(id, datos)
  res$es_tratado <- (id == 1)
  res
}) %>%
  bind_rows()

print("Pruebas de placebo completadas.")

# ============================================================
# PASO 9: Grafica de pruebas de placebo
# ============================================================

# Mostrar las brechas de todos los estados, con California
# resaltada. Si el efecto de California se destaca claramente
# del resto, es evidencia de significancia.

p4 <- ggplot() +
  # Lineas placebo (gris)
  geom_line(
    data = resultados_placebo %>% filter(!es_tratado),
    aes(x = anio, y = brecha, group = estado),
    color = "gray70", alpha = 0.4, linewidth = 0.3
  ) +
  # Linea del estado tratado (rojo)
  geom_line(
    data = resultados_placebo %>% filter(es_tratado),
    aes(x = anio, y = brecha),
    color = "#E41A1C", linewidth = 1.2
  ) +
  geom_hline(
    yintercept = 0,
    linetype = "solid", color = "gray50", linewidth = 0.4
  ) +
  geom_vline(
    xintercept = anio_tratamiento,
    linetype = "dashed", color = "gray40", linewidth = 0.5
  ) +
  annotate(
    "text", x = anio_tratamiento - 0.3,
    y = max(
      resultados_placebo$brecha, na.rm = TRUE
    ) * 0.9,
    label = "Tratamiento", hjust = 1, fontface = "italic",
    size = 3.5
  ) +
  labs(
    title = "Pruebas de placebo: brechas para todos los estados",
    subtitle = paste(
      "Linea roja: California (tratado) |",
      "Lineas grises: placebos"
    ),
    x = "Anio",
    y = "Brecha (estado - su control sintetico)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

print(p4)

ggsave(
  "03_Visualizaciones/04_pruebas_placebo.png", p4,
  width = 10, height = 6, dpi = 300
)

# ============================================================
# PASO 10: Calcular el valor p
# ============================================================

# Para cada estado, calculamos el efecto promedio
# post-tratamiento (brecha promedio post-tratamiento)

efectos_por_estado <- resultados_placebo %>%
  filter(anio >= anio_tratamiento) %>%
  group_by(estado_id, estado, es_tratado) %>%
  summarise(
    efecto_promedio = mean(brecha, na.rm = TRUE),
    .groups = "drop"
  )

# Efecto de California
efecto_california <- efectos_por_estado %>%
  filter(es_tratado) %>%
  pull(efecto_promedio)

print(paste(
  "Efecto promedio de California:",
  round(efecto_california, 2)
))

# Valor p: proporcion de placebos con efecto tan extremo
# o mas extremo que California (en valor absoluto)
n_total <- nrow(efectos_por_estado)
n_extremos <- sum(
  abs(efectos_por_estado$efecto_promedio) >=
    abs(efecto_california),
  na.rm = TRUE
)

valor_p <- n_extremos / n_total

print(paste("Valor p (prueba de placebo):", round(valor_p, 4)))
print(paste(
  "Interpretacion: de", n_total, "estados,",
  n_extremos,
  "tienen un efecto placebo tan grande o mayor que California"
))

# ============================================================
# PASO 11: Calcular valor p con razon MSPE
# ============================================================

# La razon MSPE es una medida mas refinada:
# MSPE_post / MSPE_pre
# Un valor alto indica un cambio grande post-tratamiento
# relativo al ajuste pre-tratamiento.

razones_mspe <- resultados_placebo %>%
  mutate(periodo = if_else(anio < anio_tratamiento,
    "pre", "post"
  )) %>%
  group_by(estado_id, estado, es_tratado, periodo) %>%
  summarise(
    mspe = mean(brecha^2, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = periodo,
    values_from = mspe,
    names_prefix = "mspe_"
  ) %>%
  mutate(
    razon_mspe = mspe_post / mspe_pre
  ) %>%
  arrange(desc(razon_mspe))

print("--- Razon MSPE (post/pre) por estado ---")
print(razones_mspe %>% select(estado, es_tratado, razon_mspe),
  n = 10
)

# Valor p basado en razon MSPE
razon_california <- razones_mspe %>%
  filter(es_tratado) %>%
  pull(razon_mspe)

n_extremos_mspe <- sum(
  razones_mspe$razon_mspe >= razon_california,
  na.rm = TRUE
)

valor_p_mspe <- n_extremos_mspe / nrow(razones_mspe)

print(paste(
  "Valor p (razon MSPE):",
  round(valor_p_mspe, 4)
))

# ============================================================
# PASO 12: Grafica de pesos de los donantes
# ============================================================

p5 <- tabla_pesos %>%
  filter(peso > 0) %>%
  mutate(estado = fct_reorder(estado, peso)) %>%
  ggplot(aes(x = estado, y = peso)) +
  geom_col(fill = "#377EB8", width = 0.7) +
  geom_text(
    aes(label = scales::percent(peso, accuracy = 0.1)),
    hjust = -0.1, size = 3.5
  ) +
  coord_flip() +
  scale_y_continuous(
    labels = scales::percent_format(),
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title = "Pesos de los estados donantes en el control sintetico",
    subtitle = "Solo estados con peso positivo",
    x = NULL,
    y = "Peso"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank()
  )

print(p5)

ggsave(
  "03_Visualizaciones/05_pesos_donantes.png", p5,
  width = 9, height = 5, dpi = 300
)

# ============================================================
# PASO 13: Calidad del ajuste pre-tratamiento
# ============================================================

resultados_pre <- resultados %>%
  filter(anio < anio_tratamiento)

mspe_pre <- mean((resultados_pre$tratado -
  resultados_pre$sintetico)^2)

print(paste(
  "MSPE pre-tratamiento:",
  round(mspe_pre, 4)
))

p6 <- ggplot(
  resultados %>% filter(anio < anio_tratamiento),
  aes(x = anio)
) +
  geom_line(
    aes(y = tratado, color = "California (observado)"),
    linewidth = 1.1
  ) +
  geom_line(
    aes(y = sintetico, color = "Control sintetico"),
    linewidth = 1.1, linetype = "dashed"
  ) +
  geom_point(
    aes(y = tratado), color = "#E41A1C",
    size = 2, alpha = 0.7
  ) +
  geom_point(
    aes(y = sintetico), color = "#377EB8",
    size = 2, alpha = 0.7, shape = 17
  ) +
  scale_color_manual(
    values = c(
      "California (observado)" = "#E41A1C",
      "Control sintetico" = "#377EB8"
    )
  ) +
  labs(
    title = "Calidad del ajuste pre-tratamiento",
    subtitle = paste(
      "MSPE pre-tratamiento:",
      round(mspe_pre, 2),
      "| Un valor bajo indica buen ajuste"
    ),
    x = "Anio",
    y = "Consumo per capita (paquetes)",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

print(p6)

ggsave(
  "03_Visualizaciones/06_ajuste_pre_tratamiento.png", p6,
  width = 10, height = 6, dpi = 300
)

# ============================================================
# RESUMEN FINAL
# ============================================================

print("====================================================")
print("RESUMEN DEL ANALISIS DE CONTROL SINTETICO")
print("====================================================")
print(paste("Unidad tratada:", estado_tratado))
print(paste("Anio de tratamiento:", anio_tratamiento))
print(paste(
  "Donantes con peso positivo:",
  sum(tabla_pesos$peso > 0), "de", nrow(tabla_pesos)
))
print(paste(
  "MSPE pre-tratamiento:",
  round(mspe_pre, 2)
))
print(paste(
  "Efecto promedio post-tratamiento:",
  round(efecto_california, 2), "paquetes per capita"
))
print(paste(
  "Valor p (placebo, efecto promedio):",
  round(valor_p, 4)
))
print(paste(
  "Valor p (razon MSPE):",
  round(valor_p_mspe, 4)
))
print("====================================================")

if (valor_p <= 0.1) {
  print(paste(
    "CONCLUSION: El efecto del tratamiento es",
    "estadisticamente significativo al nivel de 10%."
  ))
} else {
  print(paste(
    "NOTA: El efecto no es significativo al 10%.",
    "Considere revisar el pool de donantes."
  ))
}

if (valor_p <= 0.05) {
  print(paste(
    "El efecto tambien es significativo al nivel",
    "convencional de 5%."
  ))
}

print("====================================================")
print("Graficas guardadas:")
print("  01_spaghetti_plot.png")
print("  02_tratado_vs_sintetico.png")
print("  03_brecha_gap.png")
print("  04_pruebas_placebo.png")
print("  05_pesos_donantes.png")
print("  06_ajuste_pre_tratamiento.png")
print("====================================================")
