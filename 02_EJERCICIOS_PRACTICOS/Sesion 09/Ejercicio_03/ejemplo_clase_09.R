# =============================================================
# Ejemplo integrador - Clase 09: Facetas y programacion
# Ciencia de datos para la toma de decisiones I
# TC2001B.601
# =============================================================
#
# CONTEXTO:
# Tienes un archivo Excel ("ventas_tiendas.xlsx") con datos
# de ventas trimestrales (en miles de pesos) de una cadena
# de tiendas en 6 ciudades de Mexico: Monterrey, Guadalajara,
# CDMX, Merida, Puebla y Tijuana, del 2018 al 2025.
#
# Columnas del archivo:
#   - ciudad:    nombre de la ciudad
#   - anio:      anio del registro (2018-2025)
#   - trimestre: trimestre del anio (1-4)
#   - ventas:    ventas en miles de pesos
#
# =============================================================
# PREGUNTAS A RESOLVER:
# =============================================================
#
# 1. Lea el archivo "ventas_tiendas.xlsx" y explore su
#    estructura. Cuantas filas y columnas tiene?
#
# 2. Filtre los registros donde las ventas sean mayores
#    a 1,000 (miles de pesos). Cuantos registros cumplen
#    esta condicion?
#
# 3. Filtre los registros de las ciudades del norte
#    (Monterrey y Tijuana) que sean del cuarto trimestre
#    Y que tengan ventas >= 1,000. Use operadores logicos.
#
# 4. Filtre TODAS las ciudades EXCEPTO CDMX y Guadalajara.
#    Use el operador %in% con negacion (!).
#
# 5. Cree una nueva columna llamada "desempeno" que
#    clasifique cada registro segun sus ventas:
#      - ventas >= 1200 -> "Excelente"
#      - ventas >= 900  -> "Bueno"
#      - ventas >= 600  -> "Regular"
#      - ventas < 600   -> "Bajo"
#
# 6. Escriba una funcion llamada clasificar_region() que
#    reciba el nombre de una ciudad y devuelva su region:
#      - Monterrey, Tijuana      -> "Norte"
#      - CDMX, Puebla            -> "Centro"
#      - Guadalajara             -> "Occidente"
#      - Merida                  -> "Sureste"
#    Aplique esta funcion para crear la columna "region".
#
# 7. Use un bucle for para imprimir el promedio y maximo
#    de ventas de cada ciudad. Si el promedio es > 900,
#    agregue la etiqueta "[ALTO]" al mensaje.
#
# 8. Escriba una funcion generar_grafica_ciudad() que
#    reciba los datos y el nombre de una ciudad, y
#    devuelva un ggplot de lineas+puntos para esa ciudad.
#    Use un bucle for para generar una grafica por ciudad.
#
# 9. Genere una grafica de espagueti (todas las ciudades
#    en un solo grafico) y discuta sus limitaciones.
#
# 10. Use facet_wrap(~ciudad) para generar un panel por
#     cada ciudad. Experimente con ncol y scales = "free_y".
#
# 11. Use facet_wrap(~region) para generar un panel por
#     cada region (usando la columna creada en la pregunta 6).
#
# =============================================================

# --- Librerias ---
library(tidyverse)
library(readxl)

# =============================================================
# PREGUNTA 1: Lectura de datos desde Excel
# =============================================================

datos_ventas <- read_excel("ventas_tiendas.xlsx")

# Exploramos la estructura del dataset
glimpse(datos_ventas)
print(paste(
  "Filas:", nrow(datos_ventas),
  "| Columnas:", ncol(datos_ventas)
))

# Creamos un indice temporal para las graficas
datos_ventas <- datos_ventas %>%
  mutate(t = (anio - 2018) * 4 + trimestre)

# =============================================================
# PREGUNTA 2: Operadores de comparacion (>)
# =============================================================

ventas_altas <- datos_ventas %>%
  filter(ventas > 1000)

print(paste(
  "Registros con ventas > 1000:",
  nrow(ventas_altas)
))

# =============================================================
# PREGUNTA 3: Operadores logicos (&, %in%, >=)
# =============================================================
# Ciudades del norte, en Q4, con ventas altas

norte_q4_alto <- datos_ventas %>%
  filter(
    ciudad %in% c("Monterrey", "Tijuana") &
      trimestre == 4 &
      ventas >= 1000
  )

print(paste(
  "Registros norte, Q4, ventas >= 1000:",
  nrow(norte_q4_alto)
))

# =============================================================
# PREGUNTA 4: Negacion con ! y %in%
# =============================================================

ciudades_pequenas <- datos_ventas %>%
  filter(
    !(ciudad %in% c("CDMX", "Guadalajara"))
  )

print(paste(
  "Registros sin CDMX ni Guadalajara:",
  nrow(ciudades_pequenas)
))

# =============================================================
# PREGUNTA 5: Condicionales con case_when
# =============================================================

datos_ventas <- datos_ventas %>%
  mutate(
    desempeno = case_when(
      ventas >= 1200 ~ "Excelente",
      ventas >= 900  ~ "Bueno",
      ventas >= 600  ~ "Regular",
      TRUE           ~ "Bajo"
    )
  )

# Conteo por categoria de desempeno
datos_ventas %>%
  count(desempeno) %>%
  print()

# =============================================================
# PREGUNTA 6: Funcion propia - clasificar_region()
# =============================================================

clasificar_region <- function(ciudad) {
  # Valida que el argumento sea texto
  stopifnot(is.character(ciudad))

  if (ciudad %in% c("Monterrey", "Tijuana")) {
    return("Norte")
  } else if (ciudad %in% c("CDMX", "Puebla")) {
    return("Centro")
  } else if (ciudad == "Guadalajara") {
    return("Occidente")
  } else if (ciudad == "Merida") {
    return("Sureste")
  } else {
    return("Otra")
  }
}

# Aplicamos la funcion con sapply (vectorizacion via apply)
datos_ventas <- datos_ventas %>%
  mutate(region = sapply(ciudad, clasificar_region))

# =============================================================
# PREGUNTA 7: Bucle for con condicional if/else
# =============================================================

print("--- Resumen de ventas por ciudad ---")

ciudades <- unique(datos_ventas$ciudad)

for (cd in ciudades) {
  ventas_cd <- datos_ventas %>%
    filter(ciudad == cd) %>%
    pull(ventas)

  promedio <- round(mean(ventas_cd), 1)
  maximo <- max(ventas_cd)

  if (promedio > 900) {
    etiqueta <- " [ALTO]"
  } else {
    etiqueta <- ""
  }

  print(paste0(
    cd, ": promedio = ", promedio,
    ", max = ", maximo, etiqueta
  ))
}

# =============================================================
# PREGUNTA 8: Funcion para graficas individuales + bucle for
# =============================================================
# Esta es la respuesta a: "si tuviera que generar una grafica
# individual para cada ciudad, que tendria que hacer?"

generar_grafica_ciudad <- function(datos,
                                   ciudad_elegida,
                                   guardar = FALSE) {
  # Validaciones
  stopifnot(is.data.frame(datos))
  stopifnot(ciudad_elegida %in% datos$ciudad)

  datos_filtrados <- datos %>%
    filter(ciudad == ciudad_elegida)

  grafica <- ggplot(
    datos_filtrados,
    aes(x = t, y = ventas)
  ) +
    geom_line(
      color = "#2C3E50",
      linewidth = 1
    ) +
    geom_point(
      aes(color = desempeno),
      size = 2.5
    ) +
    scale_color_manual(
      values = c(
        "Excelente" = "#27AE60",
        "Bueno" = "#3498DB",
        "Regular" = "#F39C12",
        "Bajo" = "#E74C3C"
      )
    ) +
    labs(
      title = paste(
        "Ventas trimestrales:", ciudad_elegida
      ),
      subtitle = "2018-2025 (miles de pesos)",
      x = "Trimestre (indice)",
      y = "Ventas (miles MXN)",
      color = "Desempeno"
    ) +
    theme_minimal(base_size = 13)

  if (guardar) {
    nombre_archivo <- paste0(
      "grafica_", tolower(ciudad_elegida), ".png"
    )
    ggsave(nombre_archivo, grafica,
           width = 8, height = 5)
    print(paste("Guardada:", nombre_archivo))
  }

  return(grafica)
}

# Generamos una grafica individual de ejemplo
grafica_mty <- generar_grafica_ciudad(
  datos_ventas, "Monterrey"
)
print(grafica_mty)

# Bucle for para generar TODAS las graficas individuales
for (cd in ciudades) {
  g <- generar_grafica_ciudad(
    datos_ventas, cd, guardar = FALSE
  )
  print(g)
}

# =============================================================
# PREGUNTA 9: Grafica de espagueti
# =============================================================
# Todas las ciudades en un solo grafico.
# Limitacion: cuando hay muchas lineas se vuelve dificil
# distinguir patrones individuales ("grafica de espagueti").

grafica_espagueti <- ggplot(
  datos_ventas,
  aes(
    x = t, y = ventas,
    color = ciudad
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.2, alpha = 0.6) +
  scale_color_brewer(palette = "Set2") +
  labs(
    title = "Ventas trimestrales por ciudad",
    subtitle = "Todas las ciudades | 2018-2025",
    x = "Trimestre (indice)",
    y = "Ventas (miles MXN)",
    color = "Ciudad"
  ) +
  theme_minimal(base_size = 13)

print(grafica_espagueti)

# =============================================================
# PREGUNTA 10: facet_wrap por ciudad
# =============================================================
# Solucion al problema de la grafica de espagueti:
# separar en paneles individuales con facet_wrap

grafica_facetas <- ggplot(
  datos_ventas,
  aes(x = t, y = ventas, color = region)
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.2) +
  facet_wrap(
    ~ciudad,
    ncol = 3,
    scales = "free_y"
  ) +
  scale_color_brewer(palette = "Set1") +
  labs(
    title = "Ventas trimestrales por ciudad",
    subtitle = paste(
      "2018-2025 | Un panel por ciudad |",
      "Escala Y libre"
    ),
    x = "Trimestre (indice)",
    y = "Ventas (miles MXN)",
    color = "Region"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(
      angle = 45, hjust = 1
    ),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom"
  )

print(grafica_facetas)

# =============================================================
# PREGUNTA 11: facet_wrap por region
# =============================================================
# Facetamos por la region creada con nuestra funcion propia

grafica_por_region <- ggplot(
  datos_ventas,
  aes(x = t, y = ventas, color = ciudad)
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1) +
  facet_wrap(~region, ncol = 2) +
  scale_color_brewer(palette = "Dark2") +
  labs(
    title = "Ventas por region geografica",
    subtitle = "Regiones clasificadas con funcion propia",
    x = "Trimestre (indice)",
    y = "Ventas (miles MXN)",
    color = "Ciudad"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    strip.text = element_text(
      face = "bold", size = 12
    ),
    legend.position = "bottom"
  )

print(grafica_por_region)
