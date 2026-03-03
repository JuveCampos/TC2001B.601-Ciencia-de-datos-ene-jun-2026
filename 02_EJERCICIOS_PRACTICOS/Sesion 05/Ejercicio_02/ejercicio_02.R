
# Librerias ----
library(tidyverse)
library(readxl)

# Cargar los datos 
graproes <- read_excel("indicador_municipios_GRAPROES.xlsx")
pobreza <- read_excel("indicador_municipios_POBREZA.xlsx")
poblacion <- read_excel("indicador_municipios_PROY_POBLACION.xlsx")

# Primero, queremos quedarnos con los datos de 2020
graproes_2020 <- graproes %>% 
  filter(year == 2020) %>% 
  rename(grado_promedio = valor) %>% 
  # select(cve_mun, year, grado_promedio)
  select(-c(no,ponderador))

pobreza_2020 <- pobreza %>% 
  filter(year == 2020) %>% 
  rename(pobreza = valor) %>% 
  select(-c(no,ponderador))

poblacion_2020 = poblacion %>% 
  filter(year == 2020) %>% 
  rename(poblacion = valor) %>% 
  select(-c(no,ponderador))

# Unir las tablas 
t1 <- left_join(graproes_2020, pobreza_2020, by = c("cve_mun", "year"))
t2 <- left_join(t1, poblacion_2020, by = c("cve_mun", "year"))

tabla_final <- t2 %>% 
  filter(pobreza > 30) %>% 
  filter(grado_promedio < 9) %>% 
  arrange(-poblacion) %>% 
  head(10)

cat_munis <- read_csv("https://raw.githubusercontent.com/JuveCampos/Shapes_Resiliencia_CDMX_CIDE/master/Datos/cat_mun_revisado.csv")

tabla_final2 <- left_join(tabla_final, cat_munis, 
          by = c("cve_mun" = "cvegeo")) %>% 
  select(-c(cve_mun, cve_ent, year)) %>% 
  select(nom_ent, nom_mun, grado_promedio, pobreza, poblacion)



