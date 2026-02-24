# Carga de librerías
library(readr)
library(readxl)
library(haven)
library(DBI)
library(RSQLite)
library(arrow)
library(xml2)
library(jsonlite)
library(sf)

# Ruta base
ruta <- getwd()

# CSV - ventas_tienda.csv
ventas <- read_csv(file.path(ruta, "ventas_tienda.csv"), show_col_types = FALSE)

# Excel - empleados_empresa.xlsx
empleados <- read_excel(file.path(ruta, "empleados_empresa.xlsx"))

# RDS - datos_climaticos.rds
clima <- readRDS(file.path(ruta, "datos_climaticos.rds"))

# Stata - encuesta_laboral.dta
encuesta <- read_dta(file.path(ruta, "encuesta_laboral.dta"))

# SPSS - estudio_psicologico.sav
estudio <- read_sav(file.path(ruta, "estudio_psicologico.sav"))

# SQLite - base_datos_clientes.sqlite
con <- dbConnect(SQLite(), file.path(ruta, "base_datos_clientes.sqlite"))
tablas <- dbListTables(con)
datos_sqlite <- list()
for (tabla in tablas) {
  datos_sqlite[[tabla]] <- dbReadTable(con, tabla)
}
dbDisconnect(con)

# Parquet - datos_parquet.parquet
datos_parquet <- read_parquet(file.path(ruta, "datos_parquet.parquet"))

# XML - catalogo_productos.xml
catalogo_xml <- read_xml(file.path(ruta, "catalogo_productos.xml"))
ns <- xml_ns(catalogo_xml)
productos_nodos <- xml_find_all(catalogo_xml, ".//d1:producto", ns)
catalogo <- data.frame(
  id             = xml_attr(productos_nodos, "id"),
  activo         = xml_attr(productos_nodos, "activo"),
  nombre         = xml_text(xml_find_first(productos_nodos, ".//d1:nombre", ns)),
  precio_venta   = as.numeric(xml_text(xml_find_first(productos_nodos, ".//d1:precio/d1:venta", ns))),
  stock          = as.integer(xml_text(xml_find_first(productos_nodos, ".//d1:stock_disponible", ns))),
  proveedor      = xml_text(xml_find_first(productos_nodos, ".//d1:proveedor/d1:nombre", ns)),
  stringsAsFactors = FALSE
)

# GeoJSON - ubicaciones_tiendas.geojson
tiendas_geo <- st_read(file.path(ruta, "ubicaciones_tiendas.geojson"), quiet = TRUE)

# KML - puntos_gps_ruta.kml
ruta_gps <- st_read(file.path(ruta, "puntos_gps_ruta.kml"), quiet = TRUE)

# Shapefile - regiones_comerciales (carpeta shapefile/)
regiones <- st_read(file.path(ruta, "shapefile", "regiones_comerciales.shp"), quiet = TRUE)
