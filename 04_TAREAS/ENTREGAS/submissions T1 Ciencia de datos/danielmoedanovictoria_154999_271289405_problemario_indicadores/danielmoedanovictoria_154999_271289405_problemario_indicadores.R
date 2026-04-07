library(tidyverse)
library(ggplot2)

indicadores_estatales <- read.csv("datos_problemario/indicadores_estatales.csv")
indicadores_municipales <- read.csv("datos_problemario/indicadores_municipales.csv")
metadatos_estatales <- read.csv("datos_problemario/metadatos_estatales.csv")
metadatos_municipales <- read.csv("datos_problemario/metadatos_municipales.csv")
cat_edos <- read.csv("datos_problemario/cat_edos.csv")
cat_mun <- read.csv("datos_problemario/cat_mun.csv")

#EJERCICIO 1
pobreza_2022 <- indicadores_estatales %>%
  filter(no == 921) %>%
  filter(year == 2022) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, valor)

pobreza_2022 <- left_join(pobreza_2022, cat_edos, by="cve_ent")

#¿Cuáles son los 3 estados con mayor pobreza en 2022?
pobreza_2022 %>%
  arrange(desc(valor)) %>%
  head(3)

#EJERCICIO 2 
esperanza <- indicadores_estatales %>%
  filter(no == 54) %>%
  filter(year == 2020) %>%
  filter(!cve_ent %in% c("00","33","34","99"))

esperanza <- left_join(esperanza, cat_edos, by="cve_ent")

top_5_ev <- esperanza %>%
  arrange(desc(valor)) %>%
  head(5)

bottom_5_ev <- esperanza %>%
  arrange(valor) %>%
  head(5)

max_ev <- max(esperanza$valor)
min_ev <- min(esperanza$valor)

#¿Cuántos años de diferencia hay entre el estado con mayor y menor esperanza de vida?
diferencia <- max_ev - min_ev

# EJERCICIO 3
cambio_celulares <- indicadores_estatales %>%
  filter(no == 98) %>%
  filter(year %in% c(2005, 2020)) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, year, valor)

cambio_celulares <- cambio_celulares %>%
  pivot_wider(names_from = year, values_from = valor)

cambio_celulares <- cambio_celulares %>%
  mutate(
    cambio_abs = `2020` - `2005`,
    cambio_pct = (cambio_abs / `2005`) * 100
  )

cambio_celulares <- left_join(cambio_celulares, cat_edos, by = "cve_ent")

# ¿Qué estado tuvo mayor crecimiento porcentual?
cambio_celulares %>%
  arrange(desc(cambio_pct)) %>%
  head(1)


#EJERCICIO 4:
vehiculos_decada <- indicadores_estatales %>% 
  filter(no == 156) %>%
  filter(cve_ent == "00") %>%
  mutate(decada = floor(year/10)*10) %>%
  
  #¿De cuanto es este promedio para la década con el valor más alto?
  group_by(decada) %>%
  summarise(promedio = mean(valor),
            desv_est = sd(valor)) 

#EJERCICIO 5: 
diabetes <- indicadores_estatales %>%
  filter(no == 36) %>%
  filter(year >= 2000) %>%
  filter(year <= 2023) 

diabetes <- left_join(diabetes, cat_edos, by="cve_ent")

diabetes <- diabetes %>%
  filter(entidad %in% c("Chiapas","Tabasco","Puebla",
                        "Nuevo León","Sonora"))

grafica_diabetes <- ggplot(data = diabetes,
                           aes(x = year, y = valor, color = entidad)) +
  geom_line() +
  labs(title="Mortalidad por diabetes",
       x="Año",
       y="Tasa por 100k") +
  theme_minimal() 

# EJERCICIO 6
satisfaccion <- indicadores_estatales %>%
  filter(no == 569) %>%
  filter(year == max(year)) %>%
  filter(!cve_ent %in% c("00","33","34","99"))

satisfaccion <- left_join(satisfaccion,
                          cat_edos %>% select(cve_ent, entidad),
                          by = "cve_ent")

grafica_satisfaccion <- ggplot(data = satisfaccion,
                               aes(x = reorder(entidad, valor),
                                   y = valor,
                                   fill = valor)) +
  geom_col() +
  coord_flip() +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(title = "Satisfacción con la vida por estado",
       x = "Estado",
       y = "Nivel de satisfacción") +
  theme_minimal()

# ¿Cuál fue el estado con mayor satisfacción?
satisfaccion %>%
  arrange(desc(valor)) %>%
  select(entidad, valor) %>%
  head(1)


# EJERCICIO 7
datos_pib_fec <- indicadores_estatales %>%
  filter(no %in% c(1266, 40)) %>%
  filter(year == 2020) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, no, valor)

datos_pib_fec <- datos_pib_fec %>%
  pivot_wider(names_from = no, values_from = valor)

datos_pib_fec <- left_join(datos_pib_fec, cat_edos, by = "cve_ent")

grafica_pib_fecundidad <- ggplot(data = datos_pib_fec,
                                 aes(x = `1266`,
                                     y = `40`)) +
  geom_point() +
  labs(title = "PIB per cápita y fecundidad adolescente (2020)",
       x = "PIB per cápita",
       y = "Fecundidad adolescente") +
  theme_minimal()

# EJERCICIO 8
diabetes <- indicadores_estatales %>%
  filter(no == 36) %>%
  filter(year >= 2000) %>%
  filter(year <= 2023) 

diabetes <- left_join(diabetes, cat_edos, by="cve_ent")

diabetes <- diabetes %>%
  filter(entidad %in% c("Chiapas","Tabasco","Puebla",
                        "Nuevo León","Sonora"))

grafica_diabetes <- ggplot(diabetes,
                           aes(x = year, y = valor, color = entidad)) +
  geom_line() +
  labs( title = "Mortalidad por diabetes (2000–2023)",
    subtitle = "Fuente: INEGI",
    caption = "Victoria Moedano",
    x = "Año",
    y = "Tasa por 100 mil") +
  theme_minimal()
  
  scale_color_manual(values = c(
    "Chiapas" = "green",
    "Tabasco" = "pink",
    "Puebla" = "brown",
    "Nuevo León" = "yellow",
    "Sonora" = "orange"))+

  geom_line() +
  labs(title="Mortalidad por diabetes",
       x="Año",
       y="Tasa por 100k") +
  theme_minimal() 

grafica_diabetes 


# EJERCICIO 9
lluvia <- indicadores_estatales %>%
  filter(no == 950) %>%
  filter(year >= 2002 & year <= 2024) %>%
  filter(!cve_ent %in% c("00","33","34","99"))


lluvia <- left_join(lluvia, cat_edos, by = "cve_ent")
lluvia <- lluvia %>%
  filter(entidad %in% c("Tabasco","Chihuahua","Jalisco",
                        "Yucatán","Ciudad de México","Baja California"))


grafica_lluvia <- ggplot(data = lluvia,
                         aes(x = year, y = valor)) +
  geom_line() +
  geom_smooth(method = "lm") +
  facet_wrap(~entidad, scales = "free_y") +
  labs(
    title = "Lluvia promedio anual por entidad (2002–2024)",
    x = "Año",
    y = "Lluvia promedio"
  ) +
  theme_minimal()

grafica_lluvia

#EJERCICIO 10

homicidios <- indicadores_estatales %>%
  filter(no == 173) %>%
  filter(year == 2020) %>% 
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, year, valor) %>%
  rename(valor_homicidios = valor)

satisfaccion <- indicadores_estatales %>%
  filter(no == 569) %>%
  filter(year == 2020) %>% 
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, year, valor) %>%
  rename(valor_satisfaccion = valor)

datos_join <- inner_join(homicidios, satisfaccion,
                         by = c("cve_ent","year"))

datos_join <- left_join(datos_join, cat_edos, by = "cve_ent")

# Gráfica
grafica_violencia_satisfaccion <- ggplot(data = datos_join,
                                         aes(x = valor_homicidios,
                                             y = valor_satisfaccion)) +
  geom_point() +
  labs(
    title = "Homicidios y satisfacción con la vida (2020)",
    x = "Homicidios",
    y = "Satisfacción con la vida"
  ) +
  theme_minimal()

grafica_violencia_satisfaccion

#EJERCICIO 11
indicadores_salud <- indicadores_estatales %>%
  left_join(metadatos_estatales, by = "no") %>%
  
  group_by(indicador, umedida) %>%
  summarise(n_registros = n(), .groups = "drop")

indicadores_salud

#EJERCICIO 12
fecundidad_mun <- indicadores_municipales %>%
  filter(Clave.de.indicador == 138) %>%
  left_join(cat_mun, by = c("Clave.de.municipio" = "cvegeo"))

zona_mty <- c("Apodaca","Cadereyta Jiménez","El Carmen","García",
              "San Pedro Garza García","General Escobedo","Guadalupe",
              "Juárez","Monterrey","Salinas Victoria",
              "San Nicolás de los Garza","Santa Catarina","Santiago")

fecundidad_mun <- fecundidad_mun %>%
  filter(Municipio %in% zona_mty)

anio_reciente <- max(fecundidad_mun$Año)

fecundidad_mun <- fecundidad_mun %>%
  filter(Año == anio_reciente)

grafica_fecundidad_mty <- ggplot(fecundidad_mun,
                                 aes(x = reorder(Municipio, Valor),
                                     y = Valor)) +
  geom_col() +
  coord_flip() +
  labs(title = "Fecundidad adolescente en la Zona Metropolitana de Monterrey",
       subtitle = paste("Indicador: Fecundidad adolescente | Año:", anio_reciente),
       x = "Municipio",
       y = "Tasa de fecundidad adolescente") +
  theme_minimal()

grafica_fecundidad_mty

#EJERCICIO 13
celulares <- indicadores_estatales %>%
  filter(no == 98) %>%
  filter(year %in% c(2000, 2005, 2010, 2015, 2020)) %>%
  filter(!cve_ent %in% c("00","33","34","99"))

celulares <- left_join(celulares, cat_edos, by = "cve_ent")
celulares_ancho <- celulares %>%
  select(cve_ent, entidad, year, valor) %>%
  pivot_wider(names_from = year, values_from = valor)

celulares_ancho

#EJERCICIO 14
celulares_largo <- celulares_ancho %>%
  pivot_longer(cols = -c(cve_ent, entidad),names_to = "year", values_to = "valor") %>%
  mutate(year = as.numeric(year))

celulares_largo

#EJERCICIO 15
ambiental <- indicadores_estatales %>%
  filter(no %in% c(564, 950, 628)) %>%
  filter(!cve_ent %in% c("00","33","34","99"))

ambiental <- left_join(ambiental, cat_edos, by = "cve_ent")
ambiental <- ambiental %>%
  filter(entidad == "Nuevo León")
ambiental <- left_join(ambiental, metadatos_estatales, by = "no")


grafica_ambiental <- ggplot(ambiental,
                            aes(x = year, y = valor)) +
  geom_line() +
  facet_wrap(~indicador, scales = "free_y") +
  theme_minimal()

grafica_ambiental




