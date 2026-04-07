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

pobreza_2022 %>%
  arrange(desc(valor)) %>%
  head(3)
#Respuesta: Los 3 estados con mayor pobreza en 2022 son: CHIAPAS, GUERRERO y OAXACA.

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

diferencia <- max_ev - min_ev
#Respuesta: La diferencia entre el estado con mayor y menor esperanza de vida es de 7.34

#EJERCICIO 3:
cambio_celulares <- indicadores_estatales %>%
  filter(no == 98) %>%
  filter(year %in% c(2005,2020)) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, year, valor)

cambio_celulares <- cambio_celulares %>%
  pivot_wider(names_from = year, values_from = valor)

cambio_celulares <- cambio_celulares %>%
  mutate(cambio_abs = `2020` - `2005`,
         cambio_pct = (cambio_abs/`2005`)*100)

cambio_celulares <- left_join(cambio_celulares, cat_edos, by="cve_ent")

cambio_celulares %>%
  arrange(desc(cambio_pct)) %>%
  head(1)
#Respuesta: El estado con mayor crecimiento porcentual en adopción de celulares es DURANGO.

#EJERCICIO 4:
vehiculos_decada <- indicadores_estatales %>% 
  filter(no == 156) %>%
  filter(cve_ent == "00") %>%  # nivel nacional
  mutate(decada = floor(year/10)*10) %>%
  group_by(decada) %>%
  summarise(promedio = mean(valor),
            desv_est = sd(valor))
#Respuesta: La década con mayor promedio de vehículos es la del año 2020, con aproximadamente 420 vehículos por cada 1000 habitantes.

#EJERCICIO 5: 
grafica_diabetes <- indicadores_estatales %>%
  filter(no == 36) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad %in% c("Chiapas","Tabasco","Puebla","Nuevo León","Sonora")) %>%
  ggplot(aes(x = year, y = valor, color = entidad)) +
  geom_line(linewidth = 1) +
  labs(title = "Mortalidad por diabetes (2000-2023)",
       x = "Año",
       y = "Tasa por cada 100,000 habitantes") +
  theme_minimal()
grafica_diabetes

#EJERCICIO 6: 
satisfaccion <- indicadores_estatales %>%
  filter(no == 569) %>%
  filter(year == max(year)) %>%  
  filter(!cve_ent %in% c("00","33","34","99"))

satisfaccion <- left_join(satisfaccion, cat_edos, by = "cve_ent")
grafica_satisfaccion <- ggplot(satisfaccion,
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
grafica_satisfaccion

satisfaccion %>%
  arrange(desc(valor)) %>%
  select(entidad, valor) %>%
  head(1)
#Respuesta: El estado con mayor satisfacción con la vida es CHIHUAHUA.

#EJERCICIO 7:
pib <- indicadores_estatales %>%
  filter(no == 1266) %>%
  filter(year == 2020) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, valor) %>%
  rename(pib = valor)

fecundidad <- indicadores_estatales %>%
  filter(no == 40) %>%
  filter(year == 2020) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, valor) %>%
  rename(fecundidad = valor)

datos_scatter <- left_join(pib, fecundidad, by = "cve_ent")
datos_scatter <- left_join(datos_scatter, cat_edos, by = "cve_ent")
grafica_pib_fecundidad <- ggplot(datos_scatter,
                                 aes(x = pib, y = fecundidad)) +
  geom_point() +
  labs(title = "PIB per cápita vs Fecundidad adolescente (2020)",
       x = "PIB per cápita",
       y = "Fecundidad adolescente") +
  theme_minimal()
grafica_pib_fecundidad
#Respuesta:Se observa una relación negativa, puesto que los estados con mayor desarrollo economico (PIB per cápita) tienen una tendencia menor de fecundidad adolescente.

#EJERCICIO 8: 
diabetes <- indicadores_estatales %>%
  filter(no == 36) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad %in% c("Chiapas","Tabasco","Puebla","Nuevo León","Sonora"))

grafica_diabetes_final <- ggplot(data = diabetes,
                                 aes(x = year, y = valor, color = entidad)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Evolución de la mortalidad por diabetes en estados seleccionados (2000–2023)",
    subtitle = "Fuente: Indicadores Estatales - Mortalidad por diabetes (Indicador 36)",
    x = "Año",
    y = "Tasa de mortalidad por cada 100 mil habitantes",
    caption = "Elaborado por: Ilse Ramirez"
  ) +
  theme_minimal() +
  scale_color_manual(values = c(
    "Chiapas" = "darkgreen",
    "Tabasco" = "magenta",
    "Puebla" = "brown",
    "Nuevo León" = "purple",
    "Sonora" = "orange"
  )) +
  scale_y_continuous()

grafica_diabetes_final

#EJERCICIO 9:
lluvia <- indicadores_estatales %>%
  filter(no == 950) %>%
  filter(year >= 2002 & year <= 2024) %>%
  filter(!cve_ent %in% c("00","33","34","99"))

lluvia <- left_join(lluvia, cat_edos, by = "cve_ent")
lluvia <- lluvia %>%
  filter(entidad %in% c("Tabasco",
                        "Chihuahua",
                        "Jalisco",
                        "Yucatán",
                        "Ciudad de México",
                        "Baja California"))

grafica_lluvia <- ggplot(lluvia,
                         aes(x = year, y = valor)) +
  geom_line() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~entidad, scales = "free_y") +
  labs(title = "Lluvia promedio anual por entidad (2002–2024)",
       x = "Año",
       y = "Lluvia promedio") +
  theme_minimal()

grafica_lluvia

#EJERCICIO 10:
names(indicadores_municipales)

homicidios <- indicadores_estatales %>%
  filter(no == 173) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, year, valor) %>%
  rename(homicidios = valor)

satisfaccion <- indicadores_estatales %>%
  filter(no == 569) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, year, valor) %>%
  rename(satisfaccion = valor)

violencia_satisfaccion <- inner_join(homicidios, satisfaccion,
                                     by = c("cve_ent","year"))
violencia_satisfaccion <- violencia_satisfaccion %>%
  filter(year == 2020)

grafica_violencia_satisfaccion <- ggplot(violencia_satisfaccion,
                                         aes(x = homicidios,
                                             y = satisfaccion)) +
  geom_point() +
  labs(title = "Homicidios vs Satisfacción con la vida (2020)",
       x = "Homicidios",
       y = "Satisfacción con la vida") +
  theme_minimal()

grafica_violencia_satisfaccion
#Respuesta:Se observa cierta relación negativa, puesto que los estados con mayores niveles de homicidios tienden a presentar menor satisfacción con la vida, sin embargo la relación no es muy fuerte.

#EJERCICIO 11:
indicadores_salud <- indicadores_estatales %>%
  left_join(metadatos_estatales, by = "no") %>%
  group_by(indicador, umedida) %>%
  summarise(n_registros = n())

indicadores_salud

#EJERCICIO 12:
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

#EJERCICIO 13:
celulares_ancho <- indicadores_estatales %>%
  filter(no == 98) %>%
  filter(year %in% c(2000, 2005, 2010, 2015, 2020)) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  select(cve_ent, entidad, year, valor) %>%
  pivot_wider(names_from = year, values_from = valor)

celulares_ancho

#EJERCICIO 14:
celulares_largo <- celulares_ancho %>%
  pivot_longer(cols = -c(cve_ent, entidad),
               names_to = "year",
               values_to = "valor") %>%
  mutate(year = as.numeric(year))

celulares_largo

#EJERCICIO 15:
residuos <- indicadores_estatales %>%
  filter(no == 564) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad == "Nuevo León")

lluvia <- indicadores_estatales %>%
  filter(no == 950) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad == "Nuevo León")

incendios <- indicadores_estatales %>%
  filter(no == 628) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad == "Nuevo León")

ambiental <- bind_rows(residuos, lluvia, incendios)

ambiental <- ambiental %>%
  left_join(metadatos_estatales, by = "no")

grafica_ambiental <- ggplot(ambiental,
                            aes(x = year, y = valor)) +
  geom_line() +
  facet_wrap(~indicador, scales = "free_y") +
  labs(title = "Indicadores ambientales en Nuevo León",
       x = "Año",
       y = "Valor") +
  theme_minimal()

grafica_ambiental

#EJERCICIO 16:
apps <- read.csv("apps_uso.csv")
apps <- apps %>%
  mutate(dia = factor(dia,
                      levels = c("Lunes","Martes","Miércoles","Jueves","Viernes","Sábado","Domingo")))

grafica_apps <- ggplot(apps,
                       aes(x = dia,
                           y = horas,
                           fill = app)) +
  geom_col(position = "dodge") +
  labs(title = "Uso de aplicaciones móviles por día",
       subtitle = "Datos personales de uso semanal",
       x = "Día",
       y = "Horas de uso",
       caption = "Elaborado por: Ilse Ramirez") +
  theme_minimal()

grafica_apps