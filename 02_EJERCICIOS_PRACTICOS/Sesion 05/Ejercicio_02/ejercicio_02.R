
library(tidyverse)
library(readxl)

# Cargar los datos 
graproes <- read_excel("indicador_municipios_GRAPROES.xlsx")
pobreza <- read_excel("indicador_municipios_POBREZA.xlsx")
poblacion <- read_excel("indicador_municipios_PROY_POBLACION.xlsx")

# Primero, queremos quedarnos con los datos de 2020
graproes_2020 <- graproes %>% 
  filter(year == 2020) %>% 
  rename(grado_promedio = valor)

pobreza_2020 <- pobreza %>% 
  filter(year == 2020) %>% 
  rename(pobreza = valor)

poblacion_2020 = poblacion %>% 
  filter(year == 2020) %>% 
  rename(poblacion = valor)


