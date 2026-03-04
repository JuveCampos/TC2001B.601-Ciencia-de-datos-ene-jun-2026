
library(tidyverse)

# unique(datos_estatales$no)

datos_estatales <- read_csv("datos_problemario/indicadores_estatales.csv") %>% filter(as.numeric(cve_ent) <= 32 & cve_ent != "00")
datos_municipales <- read_csv("datos_problemario/indicadores_municipales.csv")
catalogo_estados <- read_csv("datos_problemario/cat_edos.csv")

# Ejercicio 1: filter + select
# Indicador: % población en pobreza (no = 921)
# Filtra el indicador de pobreza para el año 2022, incluyendo solo las 32 entidades federativas (excluye cve_ent “00”, “33”, “34” y “99”). Selecciona las columnas cve_ent y valor. Une con cat_edos para obtener los nombres de los estados.
# Pregunta: ¿Cuáles son los 3 estados con mayor pobreza en 2022?
#   Pista: Usa filter() con condiciones múltiples separadas por coma. Puedes usar !cve_ent %in% c(...) para excluir.
# Variable resultado: pobreza_2022


datos_estatales %>% 
  filter(no == 921) %>% 
  filter(year == 2022) %>% 
  select(cve_ent, valor) %>% 
  left_join(catalogo_estados) %>% 
  arrange(-valor) %>% 
  head(3)


# Indicador: Esperanza de vida al nacer (no = 54)
# Obtener el top 5 y bottom 5 de estados por esperanza de vida en 2020. Excluir cve_ent “00”, “33”, “34” y “99”. Unir con cat_edos para nombres.
# Pregunta: ¿Cuántos años de diferencia hay entre el estado con mayor y menor esperanza de vida?
#   Pista: Combina arrange() con slice_head() y slice_tail(), o usa slice_min()/slice_max().
# Variables resultado: top_5_ev, bottom_5_ev

top_5_ev = datos_estatales %>% 
  filter(no == 54) %>% 
  filter(year == 2020) %>% 
  left_join(catalogo_estados) %>% 
  arrange(-valor) %>% 
  head(5)

bottom_5_ev = datos_estatales %>% 
  filter(no == 54) %>% 
  filter(year == 2020) %>% 
  left_join(catalogo_estados) %>% 
  arrange(valor) %>% 
  head(5)


# Ejercicio 3: mutate
# Indicador: Suscripciones celulares por 100 hab (no = 98)
# Filtrar los años 2005 y 2020 para las 32 entidades. Calcular el cambio absoluto y el cambio porcentual por estado entre esos dos años.
# Pregunta: ¿Qué estado tuvo el mayor crecimiento porcentual en adopción de celulares?
#   Pista: Necesitarás pivot_wider para poner 2005 y 2020 en columnas separadas, luego mutate() para calcular cambio_abs y cambio_pct.
# Variable resultado: cambio_celulares (columnas: cve_ent, entidad, valor_2005, valor_2020, cambio_abs, cambio_pct)

datos_estatales %>% 
  filter(no == 98) %>% 
  filter(year %in% c(2005, 2020)) %>% 
  arrange(cve_ent) %>% 
  arrange(cve_ent, year) %>% 
  group_by(cve_ent) %>% 
  summarise(dif = 100*(diff(valor)/first(valor)), 
            cambio_absoluto = diff(valor))

# Ejercicio 4: group_by + summarise
# Indicador: Vehículos por 1,000 hab (no = 156)
# Para el nivel nacional (cve_ent == "00"), crear una columna de década con mutate, luego calcular el promedio y la desviación estándar de vehículos por década.
# Pregunta: ¿En qué década se registra el mayor promedio de vehículos por 1000 habitantes?
#   Pista: Usa mutate(decada = floor(year / 10) * 10) para crear la columna de década.
# Variable resultado: vehiculos_decada (columnas: decada, promedio, desv_est)

datos_estatales <- read_csv("datos_problemario/indicadores_estatales.csv")

datos_estatales %>% filter(no == 156) %>% pull(year) %>% unique()

datos_estatales %>% 
  filter(no == 156) %>% 
  filter(cve_ent == "00") %>% 
  mutate(decada = case_when(year >= 1980 & year <= 1989 ~ "1980s", 
                            year >= 1990 & year <= 1999 ~ "1990s", 
                            year >= 2000 & year <= 2009 ~ "2000s", 
                            year >= 2010 & year <= 2019 ~ "2010s", 
                            year >= 2020 & year <= 2029 ~ "2020s", 
                            )) %>% 
  group_by(decada) %>% 
  summarise(desv_est = sd(valor), valor = mean(valor))


# Indicador: Mortalidad por diabetes por 100k (no = 36)
# Grafica la mortalidad por diabetes de 2000 a 2023 para cinco estados: Chiapas, Tabasco, Puebla, Nuevo León y Sonora. Usa líneas de colores, agrega labs() con título y etiquetas de ejes, y aplica un tema limpio.
# Pista: Filtra primero, une con cat_edos, luego usa ggplot + geom_line con color = entidad.
# Guardar como: grafica_diabetes

bd_plot <- datos_estatales %>% 
  filter(no == 36) %>% 
  left_join(catalogo_estados) %>% 
  filter(entidad %in% c( "Chiapas", "Tabasco", "Puebla", "Nuevo León" , "Sonora"))

bd_plot %>% 
  ggplot(aes(x = year, y = valor, group = entidad, color = entidad)) + 
  geom_line()
