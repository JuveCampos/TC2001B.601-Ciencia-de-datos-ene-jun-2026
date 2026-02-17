
# Librerías ----
library(readr)
library(readxl)
library(haven)
library(foreign)
library(sf)
library(arrow)
library(xml2)
library(RSQLite)
library(DBI)

# install.packages("xml2")

# Abrimos datos 
ventas_tienda = read_csv("Data/ventas_tienda.csv")

empleados <- read_excel("Data/empleados_empresa.xlsx")
empleados_empresa <- read_excel("Data/empleados_empresa.xlsx")

datos_climaticos <- read_rds("Data/datos_climaticos.rds")

acciones <- read_parquet("Data/datos_parquet.parquet")

xml <- read_xml("Data/catalogo_productos.xml")

encuesta <- read_dta("Data/encuesta_laboral.dta")

estudio_psicologico <- read_sav("Data/estudio_psicologico.sav")

ubicaciones_tienda <- st_read("Data/ubicaciones_tiendas.geojson")
ruta <- st_read("Data/puntos_gps_ruta.kml")
regiones_comerciales <- st_read("Data/shapefile/regiones_comerciales.shp")

plot(ubicaciones_tienda, max.plot = 1)

cn <- dbConnect(RSQLite::SQLite(), "Data/base_datos_clientes.sqlite")

# Eliminar objetos individuales 
rm(xml)
rm(acciones)

