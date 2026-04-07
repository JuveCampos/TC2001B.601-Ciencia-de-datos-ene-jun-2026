# ==============================================================================
# Analisis de Regresion Discontinua (RDD)
# Basado en datos sinteticos inspirados en Angrist & Lavy (1999)
# ==============================================================================
# Este script realiza un analisis completo de regresion discontinua:
# 1. Exploracion de la variable de asignacion
# 2. Visualizacion de la discontinuidad
# 3. Test de manipulacion (densidad)
# 4. Estimacion del efecto RDD (parametrica)
# 5. Analisis de robustez con diferentes anchos de banda
# 6. Tests placebo en puntos de corte falsos
# ==============================================================================

# --- Cargar librerias ---
library(tidyverse)

# --- Leer los datos ---
datos <- read_csv("01_Datos/datos_rdd.csv")

# Definir el punto de corte
cutoff <- 40

# Centrar la variable de asignacion en el cutoff
# Esto facilita la interpretacion: valores negativos = control, positivos = tratados
datos <- datos %>%
  mutate(
    matricula_centrada = matricula - cutoff,
    arriba_cutoff = as.integer(matricula > cutoff)
  )

# ==============================================================================
# PASO 1: Exploracion de la variable de asignacion
# ==============================================================================
# Antes de hacer cualquier analisis, debemos entender la distribucion de la
# variable de asignacion (matricula) y como se relaciona con el tratamiento.

print("=== PASO 1: Exploracion de los datos ===")
print(paste("Numero total de escuelas:", nrow(datos)))
print(paste("Rango de matricula:", min(datos$matricula), "-", max(datos$matricula)))

# Estadisticas por grupo
datos %>%
  group_by(arriba_cutoff) %>%
  summarise(
    n = n(),
    matricula_media = mean(matricula),
    puntaje_medio = mean(puntaje),
    puntaje_sd = sd(puntaje),
    tamano_clase_medio = mean(tamano_clase),
    .groups = "drop"
  ) %>%
  print()

# ==============================================================================
# PASO 2: Visualizacion de la discontinuidad
# ==============================================================================
# La grafica mas importante en RDD: el scatter plot de la variable de resultado
# contra la variable de asignacion. Si hay un efecto causal, debemos ver un
# SALTO en el punto de corte.

# --- Grafica 1: Scatter plot con ajuste local ---
# Esta es la grafica principal del analisis RDD.
# Cada punto es una escuela. La linea muestra la tendencia a cada lado del corte.
grafica_scatter <- ggplot(
  datos,
  aes(x = matricula, y = puntaje, color = factor(arriba_cutoff))
) +
  geom_point(alpha = 0.5, size = 2) +
  geom_vline(
    xintercept = cutoff,
    linetype = "dashed",
    color = "black",
    linewidth = 0.8
  ) +
  geom_smooth(
    method = "lm",
    se = TRUE,
    linewidth = 1.2
  ) +
  scale_color_manual(
    values = c("0" = "#2196F3", "1" = "#F44336"),
    labels = c("Control (1 clase)", "Tratado (2 clases)")
  ) +
  labs(
    title = "Regresion Discontinua: Efecto del tamano de clase",
    subtitle = paste("Punto de corte en matricula =", cutoff,
                     "(Regla de Maimonides)"),
    x = "Matricula escolar",
    y = "Puntaje promedio en examen",
    color = "Grupo",
    caption = "Datos sinteticos inspirados en Angrist & Lavy (1999)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  ) +
  annotate(
    "text",
    x = cutoff + 0.5,
    y = max(datos$puntaje) - 1,
    label = paste("Cutoff =", cutoff),
    hjust = 0,
    fontface = "italic",
    size = 3.5
  )

print(grafica_scatter)

ggsave(
  "03_Visualizaciones/grafica_01_scatter_rdd.png",
  grafica_scatter,
  width = 10, height = 7, dpi = 300
)

# --- Grafica 2: Scatter plot con promedios por bin ---
# Para ver la discontinuidad de forma mas clara, agrupamos las escuelas
# en bins (intervalos) de matricula y calculamos el promedio de puntaje
# en cada bin. Esto reduce el ruido.

# Crear bins de 2 unidades de matricula
datos_bins <- datos %>%
  mutate(bin = cut(matricula, breaks = seq(18, 62, by = 2),
                   include.lowest = TRUE)) %>%
  group_by(bin) %>%
  summarise(
    matricula_media = mean(matricula),
    puntaje_medio = mean(puntaje),
    n = n(),
    se = sd(puntaje) / sqrt(n()),
    arriba_cutoff = as.integer(matricula_media > cutoff),
    .groups = "drop"
  )

grafica_bins <- ggplot(
  datos_bins,
  aes(
    x = matricula_media,
    y = puntaje_medio,
    color = factor(arriba_cutoff)
  )
) +
  geom_point(aes(size = n), alpha = 0.8) +
  geom_errorbar(
    aes(
      ymin = puntaje_medio - 1.96 * se,
      ymax = puntaje_medio + 1.96 * se
    ),
    width = 0.5
  ) +
  geom_vline(
    xintercept = cutoff,
    linetype = "dashed",
    color = "black",
    linewidth = 0.8
  ) +
  geom_smooth(
    data = datos,
    aes(x = matricula, y = puntaje, color = factor(arriba_cutoff)),
    method = "lm",
    se = FALSE,
    linewidth = 1,
    linetype = "solid"
  ) +
  scale_color_manual(
    values = c("0" = "#2196F3", "1" = "#F44336"),
    labels = c("Control (1 clase)", "Tratado (2 clases)")
  ) +
  labs(
    title = "Promedios por intervalo de matricula (binned scatter)",
    subtitle = "Cada punto es el promedio de un intervalo de 2 unidades",
    x = "Matricula escolar (promedio del bin)",
    y = "Puntaje promedio en examen",
    color = "Grupo",
    size = "N escuelas"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )

print(grafica_bins)

ggsave(
  "03_Visualizaciones/grafica_02_bins_rdd.png",
  grafica_bins,
  width = 10, height = 7, dpi = 300
)

# ==============================================================================
# PASO 3: Test de manipulacion
# ==============================================================================
# Un supuesto clave de RDD es que los individuos NO pueden manipular su
# posicion respecto al umbral. Si hubiera manipulacion, veriamos una
# acumulacion inusual de observaciones justo antes o despues del cutoff.
#
# Verificamos esto con un histograma de la variable de asignacion.
# La densidad deberia ser CONTINUA (suave) al cruzar el umbral.

grafica_densidad <- ggplot(datos, aes(x = matricula)) +
  geom_histogram(
    aes(y = after_stat(density)),
    binwidth = 2,
    fill = "steelblue",
    color = "white",
    alpha = 0.7
  ) +
  geom_density(
    color = "darkblue",
    linewidth = 1
  ) +
  geom_vline(
    xintercept = cutoff,
    linetype = "dashed",
    color = "red",
    linewidth = 1
  ) +
  labs(
    title = "Test de manipulacion: densidad de la variable de asignacion",
    subtitle = paste(
      "No deberia haber un salto en la densidad alrededor del cutoff =",
      cutoff
    ),
    x = "Matricula escolar",
    y = "Densidad",
    caption = paste(
      "Si la densidad es suave en el cutoff,",
      "no hay evidencia de manipulacion"
    )
  ) +
  annotate(
    "text",
    x = cutoff + 1,
    y = Inf,
    label = paste("Cutoff =", cutoff),
    vjust = 2,
    hjust = 0,
    color = "red",
    fontface = "bold"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

print(grafica_densidad)

ggsave(
  "03_Visualizaciones/grafica_03_densidad.png",
  grafica_densidad,
  width = 10, height = 6, dpi = 300
)

# Test formal: comparamos la cantidad de observaciones a cada lado del cutoff
# en una ventana estrecha
ventana_test <- 5
n_izquierda <- sum(
  datos$matricula >= (cutoff - ventana_test) &
    datos$matricula <= cutoff
)
n_derecha <- sum(
  datos$matricula > cutoff &
    datos$matricula <= (cutoff + ventana_test)
)

print("=== Test de manipulacion (densidad) ===")
print(paste("Observaciones en [", cutoff - ventana_test, ",", cutoff,
            "]:", n_izquierda))
print(paste("Observaciones en (", cutoff, ",", cutoff + ventana_test,
            "]:", n_derecha))

# Test binomial: bajo la hipotesis nula, la probabilidad de caer a cada
# lado es 50/50 (aproximadamente, si la densidad es uniforme)
test_binomial <- binom.test(n_izquierda, n_izquierda + n_derecha, p = 0.5)
print(paste("Test binomial p-valor:", round(test_binomial$p.value, 4)))

if (test_binomial$p.value > 0.05) {
  print("No hay evidencia de manipulacion (p > 0.05)")
} else {
  print("Posible evidencia de manipulacion (p <= 0.05)")
}

# ==============================================================================
# PASO 4: Estimacion del efecto RDD (parametrica)
# ==============================================================================
# Estimamos el efecto del tratamiento usando una regresion lineal con:
# - La variable de asignacion centrada
# - Un indicador de tratamiento (arriba del cutoff)
# - Terminos de interaccion (permiten pendientes diferentes a cada lado)
#
# Modelo: Y = a + tau * D + b1 * (X - c) + b2 * D * (X - c) + error
# donde tau es el efecto que queremos estimar

print("=== PASO 4: Estimacion del efecto RDD ===")

# Modelo con interaccion (permite pendientes diferentes a cada lado)
modelo_rdd <- lm(
  puntaje ~ arriba_cutoff * matricula_centrada,
  data = datos
)

print("--- Modelo RDD completo ---")
summary(modelo_rdd)

# El coeficiente de 'arriba_cutoff' es el efecto del tratamiento (tau)
coef_tau <- coef(modelo_rdd)["arriba_cutoff"]
ic_modelo <- confint(modelo_rdd)["arriba_cutoff", ]
pvalor <- summary(modelo_rdd)$coefficients["arriba_cutoff", "Pr(>|t|)"]

print(paste(
  "Efecto estimado (tau):",
  round(coef_tau, 3)
))
print(paste(
  "Intervalo de confianza al 95%: [",
  round(ic_modelo[1], 3), ",",
  round(ic_modelo[2], 3), "]"
))
print(paste("p-valor:", format(pvalor, digits = 4)))

if (pvalor < 0.05) {
  print("El efecto es ESTADISTICAMENTE SIGNIFICATIVO al 5%")
} else {
  print("El efecto NO es estadisticamente significativo al 5%")
}

# ==============================================================================
# PASO 5: Robustez - Diferentes anchos de banda
# ==============================================================================
# Un analisis RDD robusto debe mostrar que el resultado no depende
# crucialmente del ancho de banda elegido. Probamos multiples ventanas
# alrededor del cutoff.

print("=== PASO 5: Analisis de robustez (anchos de banda) ===")

# Definir diferentes anchos de banda para probar
bandwidths <- c(5, 8, 10, 12, 15, 20)

# Estimar el efecto para cada ancho de banda
resultados_bw <- lapply(bandwidths, function(bw) {
  # Filtrar datos dentro de la ventana
  datos_ventana <- datos %>%
    filter(abs(matricula_centrada) <= bw)

  # Estimar el modelo
  modelo_bw <- lm(
    puntaje ~ arriba_cutoff * matricula_centrada,
    data = datos_ventana
  )

  # Extraer resultados
  resumen <- summary(modelo_bw)
  coefs <- coef(resumen)
  ic <- confint(modelo_bw)

  tibble(
    bandwidth = bw,
    n_obs = nrow(datos_ventana),
    efecto = coefs["arriba_cutoff", "Estimate"],
    error_std = coefs["arriba_cutoff", "Std. Error"],
    ic_inf = ic["arriba_cutoff", 1],
    ic_sup = ic["arriba_cutoff", 2],
    p_valor = coefs["arriba_cutoff", "Pr(>|t|)"],
    significativo = coefs["arriba_cutoff", "Pr(>|t|)"] < 0.05
  )
})

# Combinar todos los resultados
tabla_robustez <- bind_rows(resultados_bw)

print("Resultados para diferentes anchos de banda:")
print(tabla_robustez)

# --- Grafica 4: Efecto estimado por ancho de banda ---
grafica_robustez <- ggplot(
  tabla_robustez,
  aes(x = factor(bandwidth), y = efecto)
) +
  geom_point(size = 4, color = "#1e4c7d") +
  geom_errorbar(
    aes(ymin = ic_inf, ymax = ic_sup),
    width = 0.3,
    color = "#1e4c7d",
    linewidth = 0.8
  ) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    color = "gray50"
  ) +
  geom_hline(
    yintercept = coef_tau,
    linetype = "dotted",
    color = "red",
    linewidth = 0.6
  ) +
  labs(
    title = "Robustez: efecto estimado para diferentes anchos de banda",
    subtitle = paste(
      "Linea roja punteada = estimacion con muestra completa (",
      round(coef_tau, 2), ")"
    ),
    x = "Ancho de banda (unidades de matricula alrededor del cutoff)",
    y = "Efecto estimado (puntos en examen)",
    caption = "Las barras representan intervalos de confianza al 95%"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

print(grafica_robustez)

ggsave(
  "03_Visualizaciones/grafica_04_robustez_bandwidth.png",
  grafica_robustez,
  width = 10, height = 6, dpi = 300
)

# ==============================================================================
# PASO 6: Tests placebo en puntos de corte falsos
# ==============================================================================
# Si el efecto que encontramos es genuino, NO deberiamos encontrar efectos
# significativos en otros puntos de corte donde no existe un cambio real
# en el tratamiento. Este es un test de falsificacion.

print("=== PASO 6: Tests placebo (cutoffs falsos) ===")

# Definir puntos de corte falsos (donde NO hay cambio de tratamiento)
# Solo usamos datos de un lado del cutoff real para evitar contaminar
cutoffs_placebo <- c(25, 30, 35, 45, 50, 55)

resultados_placebo <- lapply(cutoffs_placebo, function(c_falso) {
  # Usar datos dentro de una ventana razonable del cutoff falso
  # Excluimos observaciones del otro lado del cutoff REAL para no
  # contaminar el test
  if (c_falso < cutoff) {
    datos_sub <- datos %>% filter(matricula <= cutoff)
  } else {
    datos_sub <- datos %>% filter(matricula > cutoff)
  }

  datos_sub <- datos_sub %>%
    mutate(
      centrada_falso = matricula - c_falso,
      arriba_falso = as.integer(matricula > c_falso)
    )

  modelo_placebo <- lm(
    puntaje ~ arriba_falso * centrada_falso,
    data = datos_sub
  )

  resumen <- summary(modelo_placebo)
  coefs <- coef(resumen)

  tibble(
    cutoff_falso = c_falso,
    efecto = coefs["arriba_falso", "Estimate"],
    error_std = coefs["arriba_falso", "Std. Error"],
    p_valor = coefs["arriba_falso", "Pr(>|t|)"],
    significativo = coefs["arriba_falso", "Pr(>|t|)"] < 0.05
  )
})

tabla_placebo <- bind_rows(resultados_placebo)

# Agregar el cutoff real para comparar
tabla_placebo_completa <- bind_rows(
  tabla_placebo,
  tibble(
    cutoff_falso = cutoff,
    efecto = coef_tau,
    error_std = summary(modelo_rdd)$coefficients[
      "arriba_cutoff", "Std. Error"
    ],
    p_valor = pvalor,
    significativo = pvalor < 0.05
  )
) %>%
  arrange(cutoff_falso) %>%
  mutate(es_real = cutoff_falso == cutoff)

print("Resultados de tests placebo:")
print(tabla_placebo_completa)

# --- Grafica adicional: Resultados placebo ---
grafica_placebo <- ggplot(
  tabla_placebo_completa,
  aes(
    x = factor(cutoff_falso),
    y = efecto,
    color = es_real
  )
) +
  geom_point(size = 4) +
  geom_errorbar(
    aes(
      ymin = efecto - 1.96 * error_std,
      ymax = efecto + 1.96 * error_std
    ),
    width = 0.3,
    linewidth = 0.8
  ) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    color = "gray50"
  ) +
  scale_color_manual(
    values = c("FALSE" = "gray50", "TRUE" = "#F44336"),
    labels = c("Cutoff falso", "Cutoff real (40)")
  ) +
  labs(
    title = "Test placebo: efecto estimado en cutoffs falsos vs. real",
    subtitle = paste(
      "Solo el cutoff real (40) deberia mostrar un efecto significativo"
    ),
    x = "Punto de corte",
    y = "Efecto estimado",
    color = ""
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )

print(grafica_placebo)

ggsave(
  "03_Visualizaciones/grafica_05_placebo.png",
  grafica_placebo,
  width = 10, height = 6, dpi = 300
)

# ==============================================================================
# RESUMEN FINAL
# ==============================================================================
print("========================================")
print("       RESUMEN DEL ANALISIS RDD")
print("========================================")
print(paste(
  "Efecto estimado del tamano de clase sobre puntajes:",
  round(coef_tau, 2), "puntos"
))
print(paste(
  "Intervalo de confianza al 95%: [",
  round(ic_modelo[1], 2), ",",
  round(ic_modelo[2], 2), "]"
))
print(paste("p-valor:", format(pvalor, digits = 4)))
print("")
print("Interpretacion:")
print(paste(
  "Cuando la matricula supera los", cutoff, "estudiantes,",
  "las escuelas dividen"
))
print(
  "el grado en dos clases, reduciendo el tamano de clase a la mitad."
)
print(paste(
  "Este cambio genera un aumento de aproximadamente",
  round(coef_tau, 1),
  "puntos en el examen estandarizado."
))
print("")
print("Graficas guardadas:")
print("  - grafica_01_scatter_rdd.png")
print("  - grafica_02_bins_rdd.png")
print("  - grafica_03_densidad.png")
print("  - grafica_04_robustez_bandwidth.png")
print("  - grafica_05_placebo.png")
