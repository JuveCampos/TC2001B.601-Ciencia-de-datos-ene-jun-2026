# ============================================================================
# RESPUESTAS A EJERCICIOS PROPUESTOS - PREPARACIÓN EXAMEN PRÁCTICO
# Curso: TC2001B.601 - Introducción a la Ciencia de Datos (Ene-Jun 2026)
# ============================================================================

# Carga de librerías (todas al inicio del script)
library(tidyverse)
library(scales)   # Para formatos de números en gráficas
library(plotly)   # Para hacer la gráfica interactiva del Ejercicio 1

# ============================================================================
# PRIMER EJERCICIO ----
# ============================================================================
# Problema:
# 1. Elabore una gráfica de líneas en la cual pueda ver la evolución de las
#    búsquedas en Google de ChatGPT en México. La columna `semana` muestra la
#    fecha del domingo con el que inicia cada semana; `chat_gpt_mexico` es el
#    índice de búsqueda (0 a 100).
# 2. Determine la semana en la cual se alcanzó el día con mayor búsquedas.
# 3. ¿En qué fechas se alcanzan los mínimos locales y qué información aportan?
#    Pista 1: use plotly::ggplotly para hacer interactiva la gráfica.
#    Pista 2: use scale_x_date() con breaks cada 3 semanas.
# ----------------------------------------------------------------------------

# (1) Cargamos los datos directamente desde internet
chatgpt <- read_csv("https://raw.githubusercontent.com/JuveCampos/TC2001B.601-Ciencia-de-datos-ene-jun-2026/refs/heads/main/05_EXAMENES/preparacion_examen_practico/chatgpt.csv") %>% 
  filter(chat_gpt_mexico > 0) # Eliminamos los datos de cuando no existía ChatGPT

# Gráfica base de líneas con la evolución de las búsquedas
grafica_chatgpt <- chatgpt %>%
  ggplot(aes(x = semana, y = chat_gpt_mexico)) +
  geom_line(color = "#1e4c7d", linewidth = 0.7) +
  geom_point(color = "#1e4c7d", size = 0.8) +
  scale_x_date(date_breaks = "3 weeks", date_labels = "%Y-%m-%d") +
  labs(
    title    = "Evolución de búsquedas de ChatGPT en México",
    subtitle = "Índice de búsqueda semanal (0 = mínimo, 100 = máximo histórico)",
    x        = "Semana (fecha del domingo)",
    y        = "Índice de búsqueda",
    caption  = "Fuente: Google Trends"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))

grafica_chatgpt

# (2) Semana con el mayor valor de búsquedas
semana_max <- chatgpt %>%
  filter(chat_gpt_mexico == max(chat_gpt_mexico, na.rm = TRUE))

print(semana_max)
# RESPUESTA: Las dos semanas en las que se alcanzó el valor máximo fueron la semana 
# del 28 de septiembre de 2025 y la semana del 19 de octubre del mismo año

# (3) Versión interactiva para identificar mínimos locales
grafica_interactiva <- ggplotly(grafica_chatgpt)
grafica_interactiva

# RESPUESTA / INTERPRETACIÓN:
# Al inspeccionar los mínimos locales con la gráfica interactiva, se observa
# que los picos hacia abajo tienden a caer en semanas que coinciden con:
#   - Diciembre (vacaciones de fin de año / Navidad)
#   - Semana Santa (marzo-abril)
#   - Periodos vacacionales de verano (julio)
# Esto sugiere que las búsquedas de ChatGPT están asociadas con actividad
# escolar y laboral: cuando la gente está de vacaciones, baja el interés.

# ============================================================================
# SEGUNDO EJERCICIO ----
# ============================================================================
# Problema:
# Replicar la gráfica de crecimiento acumulado por presidente (primeros 23
# trimestres de cada sexenio) usando los datos de crecimiento_presidente.csv.
# Incluir etiquetas y usar colores similares a la gráfica original.
# ----------------------------------------------------------------------------

crecimiento <- read_csv("https://raw.githubusercontent.com/JuveCampos/TC2001B.601-Ciencia-de-datos-ene-jun-2026/refs/heads/main/05_EXAMENES/preparacion_examen_practico/crecimiento_presidente.csv")

# Mapeo de colores de la paleta usada en la gráfica original
colores_presidente <- c(
  "verde oscuro" = "#2F4e43",
  "azul claro"   = "#97cce9",
  "café"         = "#98362e"
)

# Ordenamos a los presidentes en el orden cronológico (aparecen en el CSV)
crecimiento <- crecimiento %>%
  mutate(etiqueta = factor(etiqueta, levels = etiqueta))

# Replicamos la gráfica de barras
grafica_crecimiento <- crecimiento %>%
  ggplot(aes(x = etiqueta, y = crecimiento, fill = color)) +
  geom_col(width = 0.7) +
  geom_text(
    aes(label = paste0(crecimiento, "%")),
    vjust = -0.4, size = 4, fontface = "bold", family = "Ubuntu"
  ) +
  scale_fill_manual(values = colores_presidente, guide = "none") +
  scale_y_continuous(labels = scales::comma_format(suffix = "%"),
                     expand = expansion(mult = c(0, 0.1))) +
  labs(
    title    = "Crecimiento sexenal del PIB",
    subtitle = "Serie desestacionalizada y de tendencia ciclo.\nComparación primeros 23 trimestres de cada sexenio",
    x        = NULL,
    y        = NULL,
    caption  = "Elaborado por México, ¿Cómo vamos? con la serie desestacionalizada del PIB de INEGI"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 20, color = "#6552d3"),
    plot.subtitle = element_text(color = "gray50"),
    panel.grid.major = element_blank(),
    axis.text.x   = element_text(face = "bold"), 
    axis.line.x = element_line(), 
    text = element_text(family = "Ubuntu")
    
  )

grafica_crecimiento

# ============================================================================
# TERCER EJERCICIO ----
# ============================================================================
# Problema:
# Con los datos de ventas_tienda.csv:
# (1) Calcular por vendedor: n_transacciones, ingreso_total e ingreso_prom.
# (2) Gráfico de barras ordenado por ingreso_total con reorder() dentro de aes().
# (3) Agregar geom_text() con etiqueta del ingreso en formato con separador
#     de miles (usando prettyNum(..., big.mark = ",")).
# (4) Aplicar theme_minimal, título y caption con la fuente.
# ----------------------------------------------------------------------------

ventas <- read_csv("https://raw.githubusercontent.com/JuveCampos/TC2001B.601-Ciencia-de-datos-ene-jun-2026/refs/heads/main/02_EJERCICIOS_PRACTICOS/Sesion%2002/archivos%20carga/Data/ventas_tienda.csv")

# (1) Cálculo de métricas por vendedor
metricas_vendedor <- ventas %>%
  group_by(vendedor) %>%
  summarise(
    n_transacciones = n(), # Numero de renglones
    ingreso_total   = sum(cantidad * precio_unitario, na.rm = TRUE),
    ingreso_prom    = ingreso_total / n_transacciones
  ) %>%
  arrange(desc(ingreso_total))

print(metricas_vendedor)

# (2-4) Gráfica de barras ordenada con etiquetas y theme_minimal
grafica_vendedores <- metricas_vendedor %>%
  ggplot(aes(x = reorder(vendedor, -ingreso_total), y = ingreso_total)) +
  geom_col(fill = "#1e4c7d") +
  geom_text(
    aes(label = prettyNum(round(ingreso_total), big.mark = ",")),
    vjust = -0.4, size = 4
  ) +
  scale_y_continuous(
    labels = label_number(big.mark = ","),
    expand = expansion(mult = c(0, 0.12))
  ) +
  labs(
    title   = "Ingreso total por vendedor",
    x       = "Vendedor",
    y       = "Ingreso total",
    caption = "Fuente: Registros internos de ventas"
  ) +
  theme_minimal()

grafica_vendedores

# ============================================================================
# EJERCICIO 4 ----
# ============================================================================
# Problema:
# Fórmula: Grados Fahrenheit = ((9/5) * Grados Celsius) + 32
# (1) Generar una función que haga la conversión.
# (2) Obtener a cuántos grados Fahrenheit equivalen 40 grados Celsius.
# ----------------------------------------------------------------------------

# (1) Función de conversión
celsius_a_fahrenheit <- function(celsius) {
  ((9 / 5) * celsius) + 32
}

# (2) Conversión de 40 °C
resultado_f <- celsius_a_fahrenheit(40)
print(str_c("40 °C equivalen a ", resultado_f, " °F"))

# RESPUESTA: 40 grados Celsius equivalen a 104 grados Fahrenheit (calorcito).

# ============================================================================
# EJERCICIO 5 ----
# ============================================================================
# Problema:
# Encuesta de 40 trabajadores en CDMX con tiempo de traslado (minutos).
# (1) Cargar datos.
# (2) Calcular media, mediana, mínimo y máximo (usando na.rm = TRUE).
# (3) Identificar y manejar NAs (cuántos hay, usar is.na()).
# (4) Detectar outliers con el método IQR: reportar Q1, Q3, IQR, límites, IDs.
# (5) Generar un boxplot.
# ----------------------------------------------------------------------------

# (1) Carga de datos
traslado <- read_csv("https://raw.githubusercontent.com/JuveCampos/TC2001B.601-Ciencia-de-datos-ene-jun-2026/refs/heads/main/05_EXAMENES/preparacion_examen_practico/tiempo_traslado.csv")

# (2) Estadísticas descriptivas de la variable minutos (ignorando NAs)
estadisticas_traslado <- traslado %>%
  summarise(
    media   = mean(minutos, na.rm = TRUE),
    mediana = median(minutos, na.rm = TRUE),
    minimo  = min(minutos, na.rm = TRUE),
    maximo  = max(minutos, na.rm = TRUE)
  )

print(estadisticas_traslado)

# Tambien los pueden calcular por fuera: 
media_traslado <- mean(traslado$minutos, na.rm = T)
mediana_traslado <- median(traslado$minutos, na.rm = T)
min_traslado <- min(traslado$minutos, na.rm = T)
max_traslado <- max(traslado$minutos, na.rm = T)

# RESPUESTA / OBSERVACIÓN:
# Se observa algo raro: el máximo es mucho más grande que la media/mediana
# (ej. 150 min vs ~35-40 min de mediana). Esto sugiere la presencia de al
# menos un valor atípico (outlier) alto. También el mínimo (3 min) parece
# muy pequeño para un traslado de casa al trabajo en CDMX (otro atípico, pero para abajo).

# (3) Identificación y manejo de NAs
n_nas <- traslado %>%
  summarise(na_minutos = sum(is.na(minutos))) %>%
  pull(na_minutos)

print(paste0("Número de NAs en la columna minutos: ", n_nas))

# Eliminamos los NAs para los cálculos posteriores (conservando IDs)
traslado_limpio <- traslado %>%
  filter(!is.na(minutos))

# (4) Detección de outliers con el método IQR
q1   <- quantile(traslado_limpio$minutos, 0.25)
q3   <- quantile(traslado_limpio$minutos, 0.75)
iqr  <- q3 - q1
lim_inf <- q1 - 1.5 * iqr
lim_sup <- q3 + 1.5 * iqr

print(paste0("Q1 = ", q1, " | Q3 = ", q3, " | IQR = ", iqr))
print(paste0("Límite inferior = ", lim_inf, " | Límite superior = ", lim_sup))

# Identificamos los IDs outliers
outliers <- traslado_limpio %>%
  filter(minutos < lim_inf | minutos > lim_sup)
# Recordar que | representa "o"

print(outliers)

# Alternativa con between negado: 
outliers <- traslado_limpio %>%
  filter(!between(minutos, lim_inf, lim_sup))

print(outliers)

# RESPUESTA:
# Los outliers son las observaciones cuyo valor de minutos está por debajo
# del límite inferior o por encima del límite superior (Q1 - 1.5*IQR, Q3 +
# 1.5*IQR). Reportar los IDs que aparecen en el tibble 'outliers'. Estos
# registros podrían ser errores de captura (ej. 150 min podría ser real o
# un error) o casos genuinos extremos que merecen análisis aparte.

# (5) Boxplot de la variable minutos
traslado_limpio %>%
  ggplot(aes(y = minutos)) +
  geom_boxplot(fill = "#1e4c7d", alpha = 0.7, outlier.color = "red") +
  labs(
    title   = "Tiempo de traslado al trabajo (minutos)",
    y       = "Minutos",
    caption = "Fuente: Encuesta a 40 trabajadores en CDMX"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

# ============================================================================
# EJERCICIO 6 ----
# ============================================================================
# Problema:
# Replicar la gráfica de inversión pública y privada como % del PIB usando
# porcentaje_inversion_pib_4T.csv. Opcional: usar la plantilla INEGI de fondo.
# ----------------------------------------------------------------------------

inversion <- read_csv("https://raw.githubusercontent.com/JuveCampos/TC2001B.601-Ciencia-de-datos-ene-jun-2026/refs/heads/main/05_EXAMENES/preparacion_examen_practico/porcentaje_inversion_pib_4T.csv")

# Pasamos a formato largo (tidy) para poder graficar con ggplot
# Las columnas originales son "% Privada" y "% Pública" (con acentos)
inversion_long <- inversion %>%
  select(anio, `% Privada` , `% Pública`) %>%
  pivot_longer(
    cols      = c(`% Pública`, `% Privada`),
    names_to  = "tipo",
    values_to = "porcentaje"
  ) %>%
  mutate(
    tipo = factor(
      tipo,
      levels = c("% Privada", "% Pública"),
      labels = c("% Privada", "% Pública")
    )
  ) 

# Replicamos la gráfica con colores similares a los de MCV
grafica_inversion <- inversion_long %>%
  ggplot(aes(x = anio, y = porcentaje, fill = tipo)) +
  geom_col() +
  geom_text(aes(label = str_c(porcentaje, "%")), 
            color = "white", angle = 90, 
            hjust = 1.1,
            position = position_stack(),
            family = "Ubuntu") + 
  scale_fill_manual(values = c(
    "% Privada" = "#d75b99",
    "% Pública" = "#6552d4"
  )) +
  scale_x_continuous(breaks = 1993:2025) +
  scale_y_continuous(breaks = seq(0, 30, 5),
                     expand = expansion(c(0, 0.1)),
                     labels = scales::comma_format(suffix = "%")) +
  labs(
    title    = "Inversión como % del PIB",
    subtitle = "Como proporción del PIB - 4º trimestre de cada año",
    x        = NULL,
    y        = "Inversión como % del PIB",
    fill    = NULL,
    caption  = NULL
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title      = element_text(face = "bold", color = "#6552d4", size = 20),
    plot.subtitle      = element_text( color = "gray50", size = 16),
    legend.text = element_text(color = "gray50"),
    text = element_text(family= "Ubuntu"),
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
    panel.grid.minor = element_blank(), 
    plot.margin = margin(t = 0.4, r = 0.4, b = 1.2, l = 0.4, unit = "cm"), 
    panel.grid.major = element_blank()
  )

grafica_inversion

# Guardamos con plantilla en la carpeta
plt_impresion <- ggbackground(gg = grafica_inversion, background = "../preparacion_examen_practico/01_inegi.pdf")

ggsave(filename = "grafica_inversion.png", 
       plot = plt_impresion, device = "png", height = 6,
       width = 12)

# ============================================================================
# EJERCICIO 7 ----
# ============================================================================
# Problema:
# Empresa de logística con 4 rutas y 11 observaciones por ruta (km y tiempo).
# a) Calcular por ruta: media de km, media de tiempo, sd de km, sd de tiempo
#    y correlación entre km y tiempo. Presentar en una tabla. ¿Qué observas?
# b) Gráfico de dispersión km vs tiempo por ruta (facet_wrap) con recta de
#    regresión en cada panel.
# c) Escribir un párrafo sobre la importancia de la visualización.
# ----------------------------------------------------------------------------

rutas <- read_csv("https://raw.githubusercontent.com/JuveCampos/TC2001B.601-Ciencia-de-datos-ene-jun-2026/refs/heads/main/05_EXAMENES/nuevos_ejercicios_propuestos/rutas_entrega.csv")

# (a) Estadísticas por ruta
tabla_rutas <- rutas %>%
  group_by(ruta) %>%
  summarise(
    media_km      = mean(km),
    media_tiempo  = mean(tiempo),
    sd_km         = sd(km),
    sd_tiempo     = sd(tiempo),
    correlacion   = cor(km, tiempo)
  )

print(tabla_rutas)

# RESPUESTA / OBSERVACIÓN:
# ¡Las medias, desviaciones estándar y correlaciones son prácticamente
# idénticas entre las 4 rutas! Este dataset corresponde al "cuarteto de
# Anscombe" (Anscombe, 1973): 4 conjuntos de datos con estadísticas
# descriptivas casi iguales pero estructuras muy distintas. La lección:
# las estadísticas descriptivas NUNCA sustituyen la visualización.

# (b) Gráfico de dispersión por ruta con línea de regresión
grafica_rutas <- rutas %>%
  ggplot(aes(x = km, y = tiempo)) +
  geom_point(color = "#1e4c7d", size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "#C8102E") +
  facet_wrap(~ ruta) +
  labs(
    title    = "Relación entre kilómetros recorridos y tiempo de entrega",
    subtitle = "4 rutas de una empresa de logística (11 observaciones c/u)",
    x        = "Kilómetros",
    y        = "Tiempo (minutos)",
    caption  = "Fuente: Registros internos de la empresa"
  ) +
  theme_minimal()

grafica_rutas

# (c) Párrafo sobre la importancia de la visualización
# RESPUESTA:
# La visualización es crucial porque aun cuando las cuatro rutas presentan
# estadísticas descriptivas (media, desviación estándar y correlación)
# prácticamente idénticas, la gráfica de dispersión revela que cada una
# tiene un patrón muy diferente: una puede mostrar una relación lineal
# limpia, otra una curvatura, otra una línea con un outlier y otra un
# caso donde un solo punto extremo conduce toda la correlación. Si nos
# quedamos solo con los números, tomaríamos decisiones erróneas (por
# ejemplo, asumir que todas las rutas se comportan igual). La gráfica
# nos permite ver la estructura real de los datos, detectar outliers
# y validar supuestos antes de ajustar modelos de regresión.

# ============================================================================
# EJERCICIO 8 ----
# ============================================================================
# Problema:
# Dataset de 200 pacientes (salud.csv) con: edad, peso_kg, altura_cm,
# presion_sistolica, colesterol, horas_ejercicio_sem, glucosa.
# 1) Obtener los IDs de personas con altura outlier (método IQR).
# 2) Calcular promedio de presion_sistolica, colesterol, horas_ejercicio y
#    glucosa para 3 grupos: jóvenes (<=29), adultos (30-60), mayores (61+).
# 3) Gráfica de barras para cada variable (facetas o loop), con el orden
#    jóvenes -> adultos -> mayores.
# 4) Dispersión presion_sistolica vs edad + correlación e interpretación.
# ----------------------------------------------------------------------------

salud <- read_csv("https://raw.githubusercontent.com/JuveCampos/TC2001B.601-Ciencia-de-datos-ene-jun-2026/refs/heads/main/05_EXAMENES/nuevos_ejercicios_propuestos/salud.csv")

# (1) IDs con altura outlier (método IQR)
q1_alt   <- quantile(salud$altura_cm, 0.25, na.rm = TRUE)
q3_alt   <- quantile(salud$altura_cm, 0.75, na.rm = TRUE)
iqr_alt  <- q3_alt - q1_alt
lim_inf_alt <- q1_alt - 1.5 * iqr_alt
lim_sup_alt <- q3_alt + 1.5 * iqr_alt

outliers_altura <- salud %>%
  filter(altura_cm < lim_inf_alt | altura_cm > lim_sup_alt) %>%
  select(paciente_id, altura_cm)

print(paste0("Q1=", q1_alt, " | Q3=", q3_alt, " | IQR=", iqr_alt))
print(paste0("Límites de altura: [", lim_inf_alt, ", ", lim_sup_alt, "]"))
print(outliers_altura)

# RESPUESTA: Los IDs en outliers_altura corresponden a las personas cuya
# altura cae fuera del rango [Q1 - 1.5*IQR, Q3 + 1.5*IQR].

# (2) Promedios por grupo de edad
salud_grupos <- salud %>%
  mutate(
    grupo_edad = case_when(
      edad <= 29 ~ "Jóvenes (<=29)",
      edad <= 60 ~ "Adultos (30-60)",
      TRUE       ~ "Mayores (61+)"
    ),
    # Aseguramos el orden: jóvenes, adultos, mayores
    grupo_edad = factor(
      grupo_edad,
      levels = c("Jóvenes (<=29)", "Adultos (30-60)", "Mayores (61+)")
    )
  )

promedios_grupo <- salud_grupos %>%
  group_by(grupo_edad) %>%
  summarise(
    presion_sistolica  = mean(presion_sistolica, na.rm = TRUE),
    colesterol         = mean(colesterol, na.rm = TRUE),
    horas_ejercicio    = mean(horas_ejercicio_sem, na.rm = TRUE),
    glucosa            = mean(glucosa, na.rm = TRUE)
  )

print(promedios_grupo)

# (3) Gráfica de barras con facetas (una sola figura para las 4 variables)
# Pasamos a formato largo para poder facetar
promedios_largo <- promedios_grupo %>%
  pivot_longer(
    cols      = -grupo_edad,
    names_to  = "variable",
    values_to = "promedio"
  ) %>%
  mutate(
    variable = recode(variable,
      presion_sistolica = "Presión sistólica",
      colesterol        = "Colesterol",
      horas_ejercicio   = "Horas ejercicio/sem",
      glucosa           = "Glucosa"
    )
  )

# Hacemos la gráfica: 
promedios_largo %>%
  ggplot(aes(x = grupo_edad, y = promedio, fill = grupo_edad)) +
  geom_col() +
  geom_text(aes(label = round(promedio, 1)),
            vjust = -0.4, size = 3.5) +
  facet_wrap(~ variable, scales = "free_y") +
  scale_fill_manual(values = c("#4FC3F7", "#1e4c7d", "#C8102E"),
                    guide = "none") +
  labs(
    title   = "Promedios de variables de salud por grupo de edad",
    x       = NULL,
    y       = "Promedio",
    caption = "Fuente: Dataset salud.csv (200 pacientes)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

# (4) Dispersión presion_sistolica vs edad + correlación
correlacion_pe <- cor(salud$presion_sistolica, salud$edad,
                      use = "complete.obs")
print(paste0("Correlación presión sistólica ~ edad: ",
             round(correlacion_pe, 3)))

salud %>%
  ggplot(aes(x = edad, y = presion_sistolica)) +
  geom_point(color = "#1e4c7d", alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE, color = "#C8102E") +
  labs(
    title    = "Relación entre edad y presión sistólica",
    subtitle = paste0("Correlación de Pearson r = ",
                      round(correlacion_pe, 3)),
    x        = "Edad (años)",
    y        = "Presión sistólica (mmHg)",
    caption  = "Fuente: Dataset salud.csv"
  ) +
  theme_minimal()

# RESPUESTA / INTERPRETACIÓN:
# La correlación es positiva y relativamente alta, lo que tiene sentido
# clínicamente: la presión sistólica tiende a aumentar con la edad. La
# gráfica de dispersión confirma este patrón, con una nube de puntos
# claramente ascendente y una recta de regresión con pendiente positiva.
# Esto es consistente con la literatura biomédica: el endurecimiento
# arterial progresivo con la edad eleva la presión sistólica.
