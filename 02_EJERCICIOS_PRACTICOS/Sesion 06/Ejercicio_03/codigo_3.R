
options(scipen = 999)

# Librerias ----
library(tidyverse)
library(readxl)

pib <- read_excel("04_base_wide_pib_sectores.xlsx") 

names(pib)

tabla_long <- pib %>% 
  pivot_longer(cols = `1993-1`:`2025-4`,
               names_to = "periodo",
               values_to = "valores") %>% 
  separate(periodo, into = c("anio", "trimestre"), sep = "-")

tabla_crecimiento <- tabla_long %>% 
  filter((anio == 2019 & trimestre == 4) | (anio == 2025 & trimestre == 4)) %>% 
  group_by(sector) %>% 
  summarise(diferencia = diff(valores), 
            porcentaje = round(100*(diferencia/first(valores)), 1)) %>% 
  arrange(porcentaje)

