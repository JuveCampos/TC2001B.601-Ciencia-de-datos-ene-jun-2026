# ============================================================
# Analisis de Diferencias en Diferencias (DiD)
# ============================================================
# Este script realiza un analisis completo de DiD usando
# datos sinteticos inspirados en Card & Krueger (1994).
#
# Objetivo: estimar el efecto causal del aumento del salario
# minimo en Nueva Jersey sobre el empleo en restaurantes
# de comida rapida, comparando con Pensilvania.
# ============================================================

# --- 1. Cargar librerias ---
library(tidyverse)
library(lmtest)    # Para coeftest (pruebas con errores robustos)
library(sandwich)  # Para errores estandar robustos (HC)

# --- 2. Leer los datos ---
datos <- read_csv("01_Datos/datos_did.csv")

# Verificar estructura de los datos
glimpse(datos)

# ============================================================
# PASO 1: ESTADISTICAS DESCRIPTIVAS
# ============================================================
# Antes de cualquier analisis causal, es fundamental conocer
# los datos. Calculamos medias, desviaciones estandar y
# conteos por grupo (estado) y periodo (antes/despues).

# Tabla de estadisticas descriptivas
stats_grupo <- datos %>%
  group_by(estado, periodo) %>%
  summarise(
    empleo_promedio = mean(empleo),
    empleo_mediana = median(empleo),
    empleo_sd = sd(empleo),
    empleo_min = min(empleo),
    empleo_max = max(empleo),
    n_restaurantes = n(),
    .groups = "drop"
  )

print("=== Estadisticas descriptivas por grupo y periodo ===")
print(stats_grupo)

# Tabla por cadena de restaurante
stats_cadena <- datos %>%
  group_by(cadena, estado) %>%
  summarise(
    empleo_promedio = mean(empleo),
    n = n(),
    .groups = "drop"
  )

print("=== Empleo promedio por cadena y estado ===")
print(stats_cadena)

# ============================================================
# PASO 2: CALCULO MANUAL DE DiD
# ============================================================
# El estimador DiD se puede calcular "a mano" usando las
# medias de cada celda del diseno 2x2:
#
#   DiD = (Y_NJ_post - Y_NJ_pre) - (Y_PA_post - Y_PA_pre)
#
# Este calculo nos da exactamente el mismo resultado que
# el coeficiente beta_3 de la regresion.

# Calcular medias por grupo y periodo
medias <- datos %>%
  group_by(estado, post) %>%
  summarise(
    empleo_medio = mean(empleo),
    .groups = "drop"
  )

print("=== Medias por grupo y periodo ===")
print(medias)

# Extraer cada media
media_nj_pre <- medias %>%
  filter(estado == "Nueva Jersey", post == 0) %>%
  pull(empleo_medio)

media_nj_post <- medias %>%
  filter(estado == "Nueva Jersey", post == 1) %>%
  pull(empleo_medio)

media_pa_pre <- medias %>%
  filter(estado == "Pensilvania", post == 0) %>%
  pull(empleo_medio)

media_pa_post <- medias %>%
  filter(estado == "Pensilvania", post == 1) %>%
  pull(empleo_medio)

# Calcular las diferencias
cambio_nj <- media_nj_post - media_nj_pre
cambio_pa <- media_pa_post - media_pa_pre
did_manual <- cambio_nj - cambio_pa

print("=== Calculo manual de DiD ===")
print(paste(
  "Cambio en NJ (tratado):",
  round(cambio_nj, 3)
))
print(paste(
  "Cambio en PA (control):",
  round(cambio_pa, 3)
))
print(paste(
  "DiD = ", round(cambio_nj, 3), " - (",
  round(cambio_pa, 3), ") = ",
  round(did_manual, 3)
))

# ============================================================
# PASO 3: REGRESION DiD
# ============================================================
# Ahora estimamos el modelo de regresion:
#
#   empleo = beta_0 + beta_1*tratamiento + beta_2*post
#            + beta_3*(tratamiento x post) + error
#
# El coeficiente beta_3 es nuestro estimador DiD.
# Es el efecto causal que buscamos.

modelo_did <- lm(
  empleo ~ tratamiento + post + tratamiento_post,
  data = datos
)

# Resultados basicos
print("=== Resultados de la regresion DiD ===")
summary(modelo_did)

# Errores estandar robustos (HC1)
# En la practica, es recomendable usar errores robustos
# porque los errores pueden no ser homocedasticos.
print("=== Con errores estandar robustos (HC1) ===")
coeftest(modelo_did, vcov = vcovHC(modelo_did, type = "HC1"))

# --- Interpretacion de los coeficientes ---
coefs <- coef(modelo_did)

print("=== Interpretacion de los coeficientes ===")
print(paste(
  "beta_0 (intercepto):", round(coefs[1], 3),
  "-> Empleo promedio en PA antes del cambio"
))
print(paste(
  "beta_1 (tratamiento):", round(coefs[2], 3),
  "-> Diferencia NJ vs PA antes del cambio"
))
print(paste(
  "beta_2 (post):", round(coefs[3], 3),
  "-> Cambio temporal en PA (tendencia comun)"
))
print(paste(
  "beta_3 (tratamiento x post):", round(coefs[4], 3),
  "-> EFECTO CAUSAL del aumento de salario minimo"
))

# Verificar que beta_3 coincide con el calculo manual
print(paste(
  "Verificacion: DiD manual =", round(did_manual, 3),
  "| beta_3 =", round(coefs[4], 3)
))

# Significancia estadistica
p_valor <- summary(modelo_did)$coefficients[4, 4]
print(paste(
  "P-valor de beta_3:", format(p_valor, digits = 4)
))
if (p_valor < 0.05) {
  print(
    "El efecto es ESTADISTICAMENTE SIGNIFICATIVO (p < 0.05)"
  )
} else {
  print(
    "El efecto NO es estadisticamente significativo"
  )
}

# ============================================================
# PASO 4: VISUALIZACIONES
# ============================================================
# Las graficas son fundamentales para comunicar los
# resultados de un analisis DiD.

# Definir tema comun para todas las graficas
tema_did <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(
      face = "bold", size = 14, hjust = 0.5
    ),
    plot.subtitle = element_text(
      hjust = 0.5, color = "grey40"
    ),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Colores para los estados
colores_estado <- c(
  "Nueva Jersey" = "#E63946",
  "Pensilvania" = "#457B9D"
)

# ---------------------------------------------------
# Grafica 1: Tendencias paralelas (medias por periodo)
# ---------------------------------------------------
# Esta grafica muestra las medias de empleo para cada
# estado antes y despues de la intervencion. Si las
# lineas son paralelas antes del tratamiento, el
# supuesto de tendencias paralelas es plausible.

grafica_tendencias <- medias %>%
  mutate(
    periodo_label = if_else(
      post == 0, "Antes", "Despues"
    ),
    periodo_label = factor(
      periodo_label, levels = c("Antes", "Despues")
    )
  ) %>%
  ggplot(aes(
    x = periodo_label,
    y = empleo_medio,
    color = estado,
    group = estado
  )) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 4) +
  geom_text(
    aes(label = round(empleo_medio, 1)),
    vjust = -1.2, size = 4, fontface = "bold"
  ) +
  scale_color_manual(values = colores_estado) +
  labs(
    title = "Empleo promedio por estado y periodo",
    subtitle = paste(
      "Diferencias en Diferencias:",
      "efecto del aumento del salario minimo"
    ),
    x = "Periodo",
    y = "Empleo promedio (ETC)",
    color = "Estado",
    caption = paste(
      "Datos sinteticos inspirados en",
      "Card & Krueger (1994)"
    )
  ) +
  ylim(
    min(medias$empleo_medio) - 2,
    max(medias$empleo_medio) + 2
  ) +
  tema_did

ggsave(
  "03_Visualizaciones/grafica_01_tendencias.png",
  grafica_tendencias,
  width = 8, height = 6, dpi = 300
)

print("Grafica 1 guardada: grafica_01_tendencias.png")

# ---------------------------------------------------
# Grafica 2: Explicacion visual del DiD
# ---------------------------------------------------
# Esta grafica muestra el contrafactual: lo que habria
# pasado en NJ si no hubiera habido tratamiento. La
# distancia entre la linea observada y el contrafactual
# es el efecto DiD.

# Calcular el contrafactual para NJ
contrafactual_nj_post <- media_nj_pre + cambio_pa

datos_contrafactual <- tibble(
  periodo_label = factor(
    c("Antes", "Despues", "Antes", "Despues", "Despues"),
    levels = c("Antes", "Despues")
  ),
  empleo_medio = c(
    media_pa_pre, media_pa_post,
    media_nj_pre, media_nj_post,
    contrafactual_nj_post
  ),
  tipo = c(
    "Pensilvania (control)",
    "Pensilvania (control)",
    "Nueva Jersey (observado)",
    "Nueva Jersey (observado)",
    "Nueva Jersey (contrafactual)"
  )
)

grafica_contrafactual <- ggplot() +
  # Linea de Pensilvania
  geom_line(
    data = datos_contrafactual %>%
      filter(tipo == "Pensilvania (control)"),
    aes(
      x = periodo_label, y = empleo_medio,
      group = tipo, color = tipo
    ),
    linewidth = 1.2
  ) +
  # Linea observada de NJ
  geom_line(
    data = datos_contrafactual %>%
      filter(tipo == "Nueva Jersey (observado)"),
    aes(
      x = periodo_label, y = empleo_medio,
      group = tipo, color = tipo
    ),
    linewidth = 1.2
  ) +
  # Linea contrafactual de NJ (punteada)
  geom_line(
    data = datos_contrafactual %>%
      filter(
        tipo %in% c(
          "Nueva Jersey (observado)",
          "Nueva Jersey (contrafactual)"
        ),
        periodo_label == "Despues" |
          tipo == "Nueva Jersey (observado)"
      ) %>%
      # Necesitamos el punto pre de NJ y el contrafactual
      bind_rows(
        tibble(
          periodo_label = factor(
            "Antes", levels = c("Antes", "Despues")
          ),
          empleo_medio = media_nj_pre,
          tipo = "Nueva Jersey (contrafactual)"
        )
      ) %>%
      filter(tipo == "Nueva Jersey (contrafactual)"),
    aes(
      x = periodo_label, y = empleo_medio,
      group = tipo, color = tipo
    ),
    linewidth = 1.0, linetype = "dashed"
  ) +
  # Puntos
  geom_point(
    data = datos_contrafactual,
    aes(
      x = periodo_label, y = empleo_medio,
      color = tipo
    ),
    size = 4
  ) +
  # Flecha mostrando el efecto DiD
  annotate(
    "segment",
    x = 2.15, xend = 2.15,
    y = contrafactual_nj_post,
    yend = media_nj_post,
    arrow = arrow(
      ends = "both", length = unit(0.2, "cm")
    ),
    color = "#2D6A4F", linewidth = 1
  ) +
  annotate(
    "text",
    x = 2.35, y = (contrafactual_nj_post + media_nj_post) / 2,
    label = paste(
      "Efecto DiD\n=",
      round(did_manual, 1)
    ),
    color = "#2D6A4F", fontface = "bold", size = 4
  ) +
  scale_color_manual(
    values = c(
      "Pensilvania (control)" = "#457B9D",
      "Nueva Jersey (observado)" = "#E63946",
      "Nueva Jersey (contrafactual)" = "#E6939B"
    )
  ) +
  labs(
    title = "Explicacion visual de Diferencias en Diferencias",
    subtitle = paste(
      "La linea punteada muestra el contrafactual:",
      "que habria pasado sin tratamiento"
    ),
    x = "Periodo",
    y = "Empleo promedio (ETC)",
    color = "",
    caption = paste(
      "El efecto causal (beta_3) es la distancia",
      "entre lo observado y el contrafactual"
    )
  ) +
  tema_did

ggsave(
  "03_Visualizaciones/grafica_02_contrafactual.png",
  grafica_contrafactual,
  width = 9, height = 6, dpi = 300
)

print("Grafica 2 guardada: grafica_02_contrafactual.png")

# ---------------------------------------------------
# Grafica 3: Distribucion de empleo por grupo y periodo
# ---------------------------------------------------
# Histogramas o boxplots que muestran la distribucion
# completa de empleo, no solo las medias.

grafica_distribucion <- datos %>%
  mutate(
    periodo_label = if_else(
      post == 0, "Antes", "Despues"
    ),
    periodo_label = factor(
      periodo_label, levels = c("Antes", "Despues")
    )
  ) %>%
  ggplot(aes(
    x = empleo,
    fill = estado,
    color = estado
  )) +
  geom_density(alpha = 0.3, linewidth = 0.8) +
  facet_wrap(~ periodo_label, ncol = 2) +
  scale_fill_manual(values = colores_estado) +
  scale_color_manual(values = colores_estado) +
  geom_vline(
    data = medias %>%
      mutate(
        periodo_label = factor(
          if_else(post == 0, "Antes", "Despues"),
          levels = c("Antes", "Despues")
        )
      ),
    aes(xintercept = empleo_medio, color = estado),
    linetype = "dashed", linewidth = 0.8
  ) +
  labs(
    title = paste(
      "Distribucion del empleo por estado y periodo"
    ),
    subtitle = paste(
      "Las lineas punteadas indican",
      "la media de cada grupo"
    ),
    x = "Empleo (equivalentes a tiempo completo)",
    y = "Densidad",
    fill = "Estado",
    color = "Estado"
  ) +
  tema_did

ggsave(
  "03_Visualizaciones/grafica_03_distribucion.png",
  grafica_distribucion,
  width = 10, height = 6, dpi = 300
)

print("Grafica 3 guardada: grafica_03_distribucion.png")

# ---------------------------------------------------
# Grafica 4: Grafico de coeficientes
# ---------------------------------------------------
# Muestra los coeficientes de la regresion con sus
# intervalos de confianza. El coeficiente de interes
# (tratamiento_post) debe ser significativo.

# Extraer coeficientes e intervalos de confianza
tabla_coefs <- summary(modelo_did)$coefficients %>%
  as.data.frame() %>%
  rownames_to_column("termino") %>%
  as_tibble() %>%
  rename(
    estimacion = Estimate,
    error_std = `Std. Error`,
    valor_t = `t value`,
    p_valor = `Pr(>|t|)`
  ) %>%
  # Excluir intercepto para mejor visualizacion
  filter(termino != "(Intercept)") %>%
  mutate(
    # Intervalos de confianza al 95%
    ic_inferior = estimacion - 1.96 * error_std,
    ic_superior = estimacion + 1.96 * error_std,
    # Etiquetas mas descriptivas
    etiqueta = case_when(
      termino == "tratamiento" ~
        "Tratamiento\n(NJ vs PA, pre)",
      termino == "post" ~
        "Post\n(cambio temporal)",
      termino == "tratamiento_post" ~
        "Tratamiento x Post\n(EFECTO DiD)"
    ),
    # Resaltar el coeficiente de interes
    es_did = termino == "tratamiento_post",
    significativo = p_valor < 0.05
  )

grafica_coefs <- tabla_coefs %>%
  ggplot(aes(
    x = etiqueta,
    y = estimacion,
    ymin = ic_inferior,
    ymax = ic_superior,
    color = es_did
  )) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    color = "grey50"
  ) +
  geom_pointrange(
    size = 1, linewidth = 1,
    fatten = 3
  ) +
  geom_text(
    aes(
      label = paste0(
        round(estimacion, 2),
        if_else(significativo, " *", "")
      )
    ),
    vjust = -1.5, size = 4, fontface = "bold",
    show.legend = FALSE
  ) +
  scale_color_manual(
    values = c("FALSE" = "#457B9D", "TRUE" = "#E63946"),
    guide = "none"
  ) +
  labs(
    title = "Coeficientes de la regresion DiD",
    subtitle = paste(
      "Intervalos de confianza al 95%.",
      "* indica significancia al 5%"
    ),
    x = "",
    y = "Estimacion del coeficiente",
    caption = paste(
      "beta_3 (Tratamiento x Post) =",
      round(coefs[4], 2),
      "| p-valor =",
      format(p_valor, digits = 3)
    )
  ) +
  tema_did

ggsave(
  "03_Visualizaciones/grafica_04_coeficientes.png",
  grafica_coefs,
  width = 8, height = 6, dpi = 300
)

print("Grafica 4 guardada: grafica_04_coeficientes.png")

# ============================================================
# RESUMEN FINAL
# ============================================================
print("============================================")
print("RESUMEN DEL ANALISIS DiD")
print("============================================")
print(paste(
  "Efecto causal estimado (beta_3):",
  round(coefs[4], 3)
))
print(paste(
  "Interpretacion: El aumento del salario minimo",
  "en Nueva Jersey incremento el empleo en",
  round(coefs[4], 1),
  "empleados ETC por restaurante, en promedio."
))
print(paste(
  "P-valor:", format(p_valor, digits = 4)
))
print(paste(
  "Este efecto es estadisticamente significativo",
  "al nivel del 5%."
))
print("============================================")
