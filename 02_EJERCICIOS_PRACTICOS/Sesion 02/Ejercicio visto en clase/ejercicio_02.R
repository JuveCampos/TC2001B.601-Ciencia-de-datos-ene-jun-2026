
# Librerias ----
library(tidyverse)
library(readxl)

# Cargar el primer archivo 
tiendas <- read_csv("ventas_tienda.csv")
tiendas$precio_unitario
mean(tiendas$precio_unitario)

trabajadores <- read_xlsx("empleados_empresa.xlsx")
