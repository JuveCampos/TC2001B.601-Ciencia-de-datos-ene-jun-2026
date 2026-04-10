# ============================================================================
# Analisis de Variables Instrumentales (IV)
# Estimacion del efecto causal de educacion sobre ingresos
# Inspirado en Angrist & Krueger (1991)
# ============================================================================

# --- Cargar librerias ---
library(tidyverse)
library(lmtest)    # Para coeftest con errores robustos
library(sandwich)  # Para matrices de varianza robustas

# --- Leer los datos ---
datos <- read_csv("01_Datos/datos_iv.csv")

# Vista rapida de los datos
glimpse(datos)

# ============================================================================
# PASO 1: Estimacion OLS (sesgada)
# ============================================================================
# Primero, estimamos la regresion por MCO sin controlar por habilidad.
# Este estimador esta SESGADO porque la habilidad (omitida) esta
# correlacionada tanto con educacion como con ingresos.

modelo_ols <- lm(log_ingresos ~ anios_educacion, data = datos)
summary(modelo_ols)

# Guardamos el coeficiente OLS para comparar despues
beta_ols <- coef(modelo_ols)["anios_educacion"]
se_ols <- summary(modelo_ols)$coefficients["anios_educacion", "Std. Error"]

print(paste(
  "Coeficiente OLS (sesgado):",
  round(beta_ols, 4)
))

# NOTA: El coeficiente OLS sobreestima el efecto causal verdadero (0.08)
# porque captura tanto el efecto de educacion como el de habilidad

# Para referencia: OLS controlando por habilidad (esto normalmente no
# es posible porque la habilidad no se observa)
modelo_ols_completo <- lm(
  log_ingresos ~ anios_educacion + habilidad,
  data = datos
)
summary(modelo_ols_completo)

print(paste(
  "Coeficiente OLS controlando habilidad:",
  round(coef(modelo_ols_completo)["anios_educacion"], 4)
))

# ============================================================================
# PASO 2: Verificar relevancia del instrumento (primera etapa)
# ============================================================================
# El instrumento (trimestre de nacimiento) debe predecir significativamente
# la variable endogena (anios de educacion).

# Usamos el trimestre como variable numerica para simplicidad
modelo_primera_etapa <- lm(
  anios_educacion ~ trimestre_nacimiento,
  data = datos
)
summary(modelo_primera_etapa)

# Estadistico F de la primera etapa
# Regla de oro: F > 10 para que el instrumento sea suficientemente fuerte
f_primera_etapa <- summary(modelo_primera_etapa)$fstatistic
print(paste(
  "Estadistico F de la primera etapa:",
  round(f_primera_etapa[1], 2)
))

if (f_primera_etapa[1] > 10) {
  print("El instrumento es FUERTE (F > 10). Podemos proceder con IV.")
} else {
  print("ADVERTENCIA: instrumento debil (F < 10). Resultados no confiables.")
}

# Educacion promedio por trimestre de nacimiento
educacion_por_trimestre <- datos %>%
  group_by(trimestre_nacimiento) %>%
  summarise(
    educacion_promedio = mean(anios_educacion),
    sd_educacion = sd(anios_educacion),
    n = n(),
    .groups = "drop"
  )

print(educacion_por_trimestre)

# ============================================================================
# PASO 3: Restriccion de exclusion (argumento conceptual)
# ============================================================================
# La restriccion de exclusion dice que el trimestre de nacimiento NO afecta
# los ingresos directamente, solo a traves de la educacion.
#
# Justificacion:
# - El trimestre de nacimiento es esencialmente aleatorio
# - No hay razon para pensar que nacer en enero vs. diciembre afecte
#   directamente la productividad laboral
# - El unico canal plausible es a traves de las leyes de asistencia
#   escolar obligatoria que generan diferencias en educacion
#
# NOTA: Esta condicion NO se puede verificar empiricamente de forma directa.
# Debe argumentarse con logica y conocimiento del contexto.

# Verificamos que el trimestre no esta correlacionado con la habilidad
# (en datos reales, no podriamos hacer esto)
cor_trimestre_habilidad <- cor(
  datos$trimestre_nacimiento,
  datos$habilidad
)
print(paste(
  "Correlacion trimestre-habilidad (debe ser cercana a 0):",
  round(cor_trimestre_habilidad, 4)
))

# ============================================================================
# PASO 4: MC2E Manual (Two-Stage Least Squares a mano)
# ============================================================================
# Realizamos el procedimiento de dos etapas manualmente para entender
# la mecanica. NOTA: los errores estandar de este metodo manual NO son
# correctos.

# --- Primera etapa ---
# Regresamos educacion sobre el instrumento
primera_etapa <- lm(
  anios_educacion ~ trimestre_nacimiento,
  data = datos
)

# Obtenemos los valores ajustados (educacion "predicha" por el instrumento)
datos <- datos %>%
  mutate(
    educacion_ajustada = fitted(primera_etapa)
  )

# --- Segunda etapa ---
# Regresamos ingresos sobre los valores ajustados de educacion
segunda_etapa <- lm(
  log_ingresos ~ educacion_ajustada,
  data = datos
)
summary(segunda_etapa)

beta_iv_manual <- coef(segunda_etapa)["educacion_ajustada"]
print(paste(
  "Coeficiente IV manual (2SLS a mano):",
  round(beta_iv_manual, 4)
))
print("NOTA: Los errores estandar de esta regresion NO son correctos.")

# ============================================================================
# PASO 5: MC2E con errores estandar correctos
# ============================================================================
# Los errores estandar de la segunda etapa deben calcularse
# usando los residuos de la regresion con la variable ORIGINAL
# (no la ajustada), pero los coeficientes de la segunda etapa.
#
# La correccion es: usar los coeficientes del 2SLS manual,
# pero recalcular los residuos como:
#   e = Y - X_original * beta_iv

beta_iv <- beta_iv_manual

# Residuos corregidos: usando educacion ORIGINAL, no ajustada
residuos_iv <- datos$log_ingresos -
  coef(segunda_etapa)["(Intercept)"] -
  beta_iv * datos$anios_educacion

# Varianza del error
n_obs <- nrow(datos)
sigma2_iv <- sum(residuos_iv^2) / (n_obs - 2)

# Varianza del coeficiente IV (formula correcta)
# Var(beta_iv) = sigma2 / (sum(educacion_ajustada - mean)^2)
educ_aj_centrada <- datos$educacion_ajustada -
  mean(datos$educacion_ajustada)
se_iv <- sqrt(sigma2_iv / sum(educ_aj_centrada^2))

print(paste(
  "Coeficiente IV (2SLS):", round(beta_iv, 4)
))
print(paste(
  "Error estandar IV (corregido):", round(se_iv, 4)
))

# Prueba de significancia
t_iv <- beta_iv / se_iv
p_iv <- 2 * pt(-abs(t_iv), df = n_obs - 2)
print(paste("Estadistico t:", round(t_iv, 4)))
print(paste("P-valor:", format(p_iv, scientific = TRUE)))

# ============================================================================
# PASO 6: Comparacion OLS vs IV
# ============================================================================

comparacion <- tibble(
  metodo = c("OLS (sesgado)", "IV (2SLS)", "Valor verdadero"),
  coeficiente = c(beta_ols, beta_iv, 0.08),
  error_estandar = c(se_ols, se_iv, NA),
  ic_inferior = c(
    beta_ols - 1.96 * se_ols,
    beta_iv - 1.96 * se_iv,
    NA
  ),
  ic_superior = c(
    beta_ols + 1.96 * se_ols,
    beta_iv + 1.96 * se_iv,
    NA
  )
)

print("--- Comparacion de estimaciones ---")
print(comparacion)

# El coeficiente OLS es mayor que el verdadero (sesgo positivo por habilidad)
# El coeficiente IV deberia estar mas cerca del valor verdadero (0.08)

# ============================================================================
# PASO 7: Prueba de instrumentos debiles (estadistico F)
# ============================================================================

# Ya calculamos el F de la primera etapa arriba
print(paste(
  "Estadistico F de primera etapa:",
  round(f_primera_etapa[1], 2),
  "- Regla de oro: debe ser > 10"
))

# ============================================================================
# PASO 8: Prueba de Hausman para endogeneidad
# ============================================================================
# La prueba de Hausman compara los estimadores OLS e IV.
# H0: OLS es consistente (no hay endogeneidad)
# H1: OLS es inconsistente (hay endogeneidad, IV es preferible)

# Metodo manual: incluir los residuos de la primera etapa en la regresion OLS
# Si son significativos, hay evidencia de endogeneidad
datos <- datos %>%
  mutate(
    residuos_primera_etapa = residuals(primera_etapa)
  )

hausman_manual <- lm(
  log_ingresos ~ anios_educacion + residuos_primera_etapa,
  data = datos
)
summary(hausman_manual)

p_hausman <- summary(hausman_manual)$coefficients[
  "residuos_primera_etapa", "Pr(>|t|)"
]

print(paste(
  "Prueba de Hausman - p-valor de residuos primera etapa:",
  round(p_hausman, 4)
))

if (p_hausman < 0.05) {
  print("Se rechaza H0: hay evidencia de endogeneidad. IV es preferible a OLS.")
} else {
  print("No se rechaza H0: no hay evidencia fuerte de endogeneidad.")
}

# ============================================================================
# VISUALIZACIONES
# ============================================================================

# Tema comun para todas las graficas
tema_iv <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.minor = element_blank()
  )

# --- Grafica 1: Educacion vs Ingresos (preocupacion por endogeneidad) ---
p1 <- ggplot(datos, aes(x = anios_educacion, y = log_ingresos)) +
  geom_point(alpha = 0.3, color = "steelblue", size = 1.5) +
  geom_smooth(
    method = "lm", se = TRUE,
    color = "red", linewidth = 1, linetype = "dashed"
  ) +
  labs(
    title = "Educacion vs. Ingresos (log)",
    subtitle = paste(
      "Pendiente OLS =", round(beta_ols, 4),
      " (sobreestima el efecto causal de", 0.08, ")"
    ),
    x = "Anios de educacion",
    y = "Log de ingresos"
  ) +
  annotate(
    "text", x = 8, y = max(datos$log_ingresos) - 0.2,
    label = "OLS esta sesgado por\nvariable omitida (habilidad)",
    color = "red", fontface = "italic", hjust = 0, size = 4
  ) +
  tema_iv

p1
ggsave(
  "03_Visualizaciones/01_educacion_vs_ingresos.png", p1,
  width = 8, height = 6, dpi = 300
)

# --- Grafica 2: Primera etapa (instrumento vs educacion por trimestre) ---
p2 <- educacion_por_trimestre %>%
  mutate(
    trimestre_label = paste0("Q", trimestre_nacimiento)
  ) %>%
  ggplot(aes(
    x = trimestre_label,
    y = educacion_promedio,
    fill = trimestre_label
  )) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_errorbar(
    aes(
      ymin = educacion_promedio - sd_educacion / sqrt(n),
      ymax = educacion_promedio + sd_educacion / sqrt(n)
    ),
    width = 0.2
  ) +
  scale_fill_brewer(palette = "Blues") +
  labs(
    title = "Primera etapa: Trimestre de nacimiento y educacion",
    subtitle = paste(
      "Estadistico F =",
      round(f_primera_etapa[1], 1),
      "- Los nacidos en Q1 tienen menos educacion"
    ),
    x = "Trimestre de nacimiento",
    y = "Anios de educacion (promedio)"
  ) +
  coord_cartesian(
    ylim = c(
      min(educacion_por_trimestre$educacion_promedio) - 0.5,
      max(educacion_por_trimestre$educacion_promedio) + 0.5
    )
  ) +
  tema_iv

p2
ggsave(
  "03_Visualizaciones/02_primera_etapa_trimestre.png", p2,
  width = 8, height = 6, dpi = 300
)

# --- Grafica 3: Comparacion de coeficientes OLS vs IV ---
comparacion_plot <- comparacion %>%
  filter(!is.na(error_estandar)) %>%
  bind_rows(
    tibble(
      metodo = "Valor verdadero",
      coeficiente = 0.08,
      error_estandar = 0,
      ic_inferior = 0.08,
      ic_superior = 0.08
    )
  )

p3 <- comparacion_plot %>%
  mutate(
    metodo = factor(
      metodo,
      levels = c("OLS (sesgado)", "IV (2SLS)", "Valor verdadero")
    )
  ) %>%
  ggplot(aes(
    x = metodo, y = coeficiente,
    color = metodo
  )) +
  geom_point(size = 4) +
  geom_errorbar(
    aes(ymin = ic_inferior, ymax = ic_superior),
    width = 0.15, linewidth = 1
  ) +
  geom_hline(
    yintercept = 0.08,
    linetype = "dashed", color = "darkgreen", linewidth = 0.8
  ) +
  scale_color_manual(
    values = c(
      "OLS (sesgado)" = "red",
      "IV (2SLS)" = "steelblue",
      "Valor verdadero" = "darkgreen"
    )
  ) +
  labs(
    title = "Comparacion de estimadores: OLS vs. IV",
    subtitle = "Intervalos de confianza al 95%",
    x = "",
    y = "Coeficiente estimado (efecto de educacion)",
    color = "Metodo"
  ) +
  annotate(
    "text",
    x = 0.6, y = 0.08,
    label = "Efecto causal\nverdadero = 0.08",
    color = "darkgreen", hjust = 0, fontface = "italic", size = 3.5
  ) +
  tema_iv +
  theme(legend.position = "none")

ggsave(
  "03_Visualizaciones/03_comparacion_ols_iv.png", p3,
  width = 8, height = 6, dpi = 300
)

# --- Grafica 4: Forma reducida (instrumento vs ingresos) ---
ingresos_por_trimestre <- datos %>%
  group_by(trimestre_nacimiento) %>%
  summarise(
    ingreso_promedio = mean(log_ingresos),
    sd_ingresos = sd(log_ingresos),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    trimestre_label = paste0("Q", trimestre_nacimiento)
  )

# Forma reducida: regresion de ingresos sobre el instrumento
modelo_forma_reducida <- lm(
  log_ingresos ~ trimestre_nacimiento,
  data = datos
)
summary(modelo_forma_reducida)

gamma_reducida <- coef(modelo_forma_reducida)["trimestre_nacimiento"]
print(paste(
  "Coeficiente de forma reducida (gamma):",
  round(gamma_reducida, 4)
))

pi_primera <- coef(primera_etapa)["trimestre_nacimiento"]
print(paste(
  "Coeficiente primera etapa (pi):",
  round(pi_primera, 4)
))

print(paste(
  "Ratio gamma/pi (debe ser aprox. igual al coeficiente IV):",
  round(gamma_reducida / pi_primera, 4)
))

p4 <- ingresos_por_trimestre %>%
  ggplot(aes(
    x = trimestre_label,
    y = ingreso_promedio,
    fill = trimestre_label
  )) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_errorbar(
    aes(
      ymin = ingreso_promedio - sd_ingresos / sqrt(n),
      ymax = ingreso_promedio + sd_ingresos / sqrt(n)
    ),
    width = 0.2
  ) +
  scale_fill_brewer(palette = "Oranges") +
  labs(
    title = "Forma reducida: Trimestre de nacimiento e ingresos",
    subtitle = paste(
      "Efecto del instrumento sobre Y:",
      "gamma =", round(gamma_reducida, 4)
    ),
    x = "Trimestre de nacimiento",
    y = "Log de ingresos (promedio)"
  ) +
  coord_cartesian(
    ylim = c(
      min(ingresos_por_trimestre$ingreso_promedio) - 0.15,
      max(ingresos_por_trimestre$ingreso_promedio) + 0.15
    )
  ) +
  tema_iv

p4
ggsave(
  "03_Visualizaciones/04_forma_reducida.png", p4,
  width = 8, height = 6, dpi = 300
)

# ============================================================================
# RESUMEN FINAL
# ============================================================================

print("========================================")
print("RESUMEN DEL ANALISIS DE VARIABLES INSTRUMENTALES")
print("========================================")
print(paste("Efecto causal verdadero:         ", 0.08))
print(paste("Estimacion OLS (sesgada):        ", round(beta_ols, 4)))
print(paste("Estimacion IV (2SLS):            ", round(beta_iv, 4)))
print(paste("F primera etapa:                 ", round(f_primera_etapa[1], 2)))
print(paste("Prueba Hausman (p-valor):        ", round(p_hausman, 4)))
print("========================================")
print("Conclusiones:")
print("1. OLS sobreestima el efecto por sesgo de variable omitida")
print("2. IV corrige el sesgo usando trimestre de nacimiento como instrumento")
print("3. El instrumento es fuerte (F > 10)")
print("4. La prueba de Hausman confirma la presencia de endogeneidad")
print("========================================")
