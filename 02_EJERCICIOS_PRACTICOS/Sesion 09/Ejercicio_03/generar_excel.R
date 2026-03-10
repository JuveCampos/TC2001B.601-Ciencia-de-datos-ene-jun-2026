# Script auxiliar para generar el archivo Excel con los datos
# Ejecutar UNA sola vez para crear "ventas_tiendas.xlsx"

library(tidyverse)
library(writexl)

set.seed(42)

ciudades <- c(
  "Monterrey", "Guadalajara", "CDMX",
  "Merida", "Puebla", "Tijuana"
)

datos_ventas <- expand.grid(
  ciudad = ciudades,
  anio = 2018:2025,
  trimestre = 1:4,
  stringsAsFactors = FALSE
) %>%
  as_tibble() %>%
  arrange(ciudad, anio, trimestre)

ventas_base <- c(
  "Monterrey" = 800, "Guadalajara" = 750, "CDMX" = 1200,
  "Merida" = 500, "Puebla" = 600, "Tijuana" = 650
)

datos_ventas <- datos_ventas %>%
  mutate(
    ventas = ventas_base[ciudad] +
      ((anio - 2018) * 4 + trimestre) * 15 +
      ifelse(trimestre == 4, 200, 0) +
      ifelse(trimestre == 1, -100, 0) +
      rnorm(n(), mean = 0, sd = 80),
    ventas = round(ventas, 1)
  )

write_xlsx(datos_ventas, "ventas_tiendas.xlsx")
print("Archivo ventas_tiendas.xlsx creado exitosamente.")
