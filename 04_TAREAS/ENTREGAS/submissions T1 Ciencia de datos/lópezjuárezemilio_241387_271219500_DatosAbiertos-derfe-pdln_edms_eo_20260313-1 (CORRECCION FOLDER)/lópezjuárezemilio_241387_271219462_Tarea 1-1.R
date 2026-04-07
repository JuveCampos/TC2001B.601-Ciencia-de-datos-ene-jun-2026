
# Problemario_indicadores -----------------------------------------------
library(tidyverse)
library(readxl)
library(readr)
library(tidyr)
library(ggplot2)

datos_estatales <- read.csv("datos_problemario/indicadores_estatales.csv")
datos_significado_edos <- read.csv("datos_problemario/metadatos_estatales.csv")
datos_municipales <- read.csv("datos_problemario/indicadores_municipales.csv")
datos_significado_mun <- read.csv("datos_problemario/indicadores_municipales.csv")
catalogo_edos <- read.csv("datos_problemario/cat_edos.csv")
catalogo_mun <- read.csv("datos_problemario/cat_mun.csv")
padron_electoral <- read_xlsx("DatosAbiertos-derfe-pdln_edms_eo_20260313.xlsx")


# 1er ejercicio
pobreza_edos <- datos_estatales %>%
  left_join(datos_significado_edos) %>%
  left_join(catalogo_edos) %>% 
  filter(year == 2020) %>% 
  as_tibble() %>% 
  mutate(no = indicador) %>% 
  rename(nombre = no) %>% 
  select(nombre, valor, cve_ent, entidad) %>% 
  filter(nombre == "Porcentaje de población en situación de pobreza") %>% 
  filter(!cve_ent%in% c("00", "33", "34", "99")) %>%
  arrange(-valor) %>%
  head(3)

# 2do ejercicio
esperanza_vida <- datos_estatales %>% 
  left_join(catalogo_edos) %>% 
  left_join(datos_significado_edos) %>% 
  filter(!cve_ent%in% c("00", "33", "34", "99")) %>%
  filter(no == 54) %>% 
  filter(year == 2020) %>% 
  select(no, valor, cve_ent, entidad) %>% 
  arrange(-valor) %>% 
  head(5) %>% 
  arrange(valor) %>% 
  head(5)

rango <- max(esperanza_vida$valor) - min(esperanza_vida$valor)

# 3er ejercicio

suscripcion_cel <- datos_estatales %>% 
  left_join(catalogo_edos) %>% 
  left_join(datos_significado_edos) %>% 
  filter(!cve_ent%in% c("00", "33", "34", "99")) %>%
  filter(no == 98) %>% 
  filter(year %in% c("2005", "2020")) %>% 
  select(no, valor, entidad, year)%>% 
  pivot_wider(id_cols = "entidad", names_from = "year",
              values_from = "valor")


celulares <- suscripcion_cel %>% mutate(
  cambio_abs =`2020` - `2005`,
  cambio_pct = ((`2020`- `2005`)/ `2005`)*100) %>% 
  arrange(desc(cambio_pct))


# Ejercicio 4 -------------------------------------------------------------
carros <- datos_estatales %>% 
  left_join(catalogo_edos) %>% 
  left_join(datos_significado_edos) %>% 
  filter(!entidad%in% c("Nacional", "Federal", "Promedido estatal", "Otras entidades")) %>% 
  filter(no == 156) %>% 
  select(no, year, entidad, valor) %>% 
  mutate(decada = case_when(year <= 1989~ 1980, 
                            year <= 1999~ 1990,
                            year <= 2009~ 2000,
                            year <= 2019~ 2010,
                            year <= 2023~ 2020,)) %>% 
  arrange(-decada) %>% 
  group_by(decada) %>% 
  summarise(media=mean(valor),
                  desv_est=sd(valor)) #2020 es la decada con más carros con 416 carros por cada 1000 habitantes



# Ejercicio 5 -------------------------------------------------------------

mort_diab <- datos_estatales %>% 
  left_join(catalogo_edos) %>% 
  left_join(datos_significado_edos) %>% 
  filter(!cve_ent%in% c("00", "33", "34", "99")) %>%
  filter(no==36, year >= 2000 & year <= 2023) %>% 
  filter(entidad %in% c("Chiapas", "Tabasco", "Puebla", "Nuevo León", "Sonora"))

ggplot(mort_diab, aes(x = year, y = valor, color = entidad)) +
  geom_line(linewidth = 1) +
  labs(x = "Año",
    y = "Mortalidad por cada 100k habitantes",
    color = "Estado") +
  theme_minimal() +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"))

# Ejercicio 6 -------------------------------------------------------------

satisfaccion <- datos_estatales %>% 
  left_join(catalogo_edos) %>% 
  left_join(datos_significado_edos) %>% 
  filter(!cve_ent%in% c("00", "33", "34", "99")) %>% 
  filter(no == 569) %>% 
  filter(year==2024)

ggplot(satisfaccion, aes(x = reorder(entidad, valor), y = valor, fill = valor)) +
  geom_col() +
  coord_flip() +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(title = "Satisfacción con la vida por estado (2024)",
    x = "Estado",
    y = "Nivel de satisfacción",
    fill = "Valor") +
  theme_minimal()

# Ejercicio 7 -------------------------------------------------------------

fecundidad_dinero <- datos_estatales %>% 
  left_join(catalogo_edos) %>% 
  left_join(datos_significado_edos) %>% 
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>% 
  filter(no %in% c(1266, 40)) %>%    
  filter(year == 2020) %>% 
  select(year, valor, entidad, no) %>% 
  pivot_wider(names_from = no, values_from = valor) %>%
  rename(pib = `1266`, fecundidad = `40`) r

ggplot(fecundidad_dinero, aes(x = pib, y = fecundidad)) +
  geom_point(color = "steelblue", size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, color = "red", linetype = "dashed") +
  labs(
    title = "Relación entre PIB per cápita y Fecundidad Adolescente (2020)",
    x = "PIB per capita",
    y = "Tasa de fecundidad adolescente",
    caption = "Fuente: Excel, datos del INEGI"
  ) +
  theme_minimal()

# Ejercicio 8 -------------------------------------------------------------

mort_diab <- datos_estatales %>%
  left_join(catalogo_edos) %>% 
  mutate(entidad = str_trim(entidad)) %>% 
  filter(no == 36, year >= 2000 & year <= 2023) %>% 
  filter(entidad %in% c("Chiapas", "Tabasco", "Puebla", "Nuevo León", "Sonora"))

grafica_diabetes_final <- ggplot(mort_diab, aes(x = year, y = valor, color = entidad)) +
  geom_line(size = 1.2) +
  theme_minimal() +
  labs(title = "Evolución de la Mortalidad por Diabetes (2000-2023)",
    subtitle = "Fuente: Metadatos del Sistema de Salud / INEGI",
    caption = "Fuente: INEGI",
    x = "Año de registro",
    y = "Tasa por cada 100k hab.",
    color = "Estados") +
  scale_color_manual(values = c(
    "Puebla" = "brown",
    "Chiapas" = "orange",
    "Tabasco" = "darkgreen",
    "Nuevo León" = "steelblue",
    "Sonora" = "darkred")) +
  scale_y_continuous(breaks = seq(0, 150, by = 25)) + 
  theme(plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom")
grafica_diabetes_final

# Ejercicio 9 -------------------------------------------------------------

grafica_lluvia <- datos_estatales %>%
  left_join(catalogo_edos) %>% 
  mutate(entidad = str_trim(entidad)) %>% 
  filter(no == 950, year >= 2002 & year <= 2024) %>% 
  filter(entidad %in% c("Tabasco", "Chihuahua", "Jalisco", "Yucatán", "Ciudad de México", "Baja California"))

ggplot(grafica_lluvia, aes(x = year, y = valor, color = entidad)) +
  geom_line(size = 1) +                   # Línea de tiempo
  geom_smooth(method = "lm", color = "black", linetype = "dashed", size = 0.5) + 
  facet_wrap(~entidad, scales = "free_y") + 
  labs(title = "Lluvia Promedio Anual por Entidad (2002-2024)",
    subtitle = "Tendencia lineal marcada en negro",
    x = "Año",
    y = "Lluvia promedio",
    caption = "Elaborado con facet_wrap y escalas libres")+
  theme_minimal() +
  theme(legend.position = "none")

# Ejercicio 10 ------------------------------------------------------------

homicidios <- datos_estatales %>%
  filter(no == 173) %>%
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
  select(cve_ent, year, valor_homicidios = valor)


satisfaccion <- datos_estatales %>%
  filter(no == 569) %>%
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
  select(cve_ent, year, valor_satisfaccion = valor) 


grafica_violencia_satisfaccion <- homicidios %>%
  inner_join(satisfaccion, by = c("cve_ent", "year")) %>%
  left_join(catalogo_edos, by = "cve_ent") 

grafica_violencia_satisfaccion %>% 
  filter(year == 2023) %>% 
  ggplot(aes(x = valor_homicidios, y = valor_satisfaccion)) +
  geom_point() +
  geom_smooth(method = "lm") + 
  labs(title = "Relación Violencia vs Felicidad",
       x = "Homicidios",
       y = "Satisfacción con la vida")
# Se puede concluir que el nivel de homicidios disminuye tu nivel de vida,
# ya que los niveles de violencia más bajos tienen mayor felicidad.

# Ejercicio 11

indicadores_salud <- datos_estatales %>% 
  left_join(datos_significado_edos, by = "no") %>% 
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>% 
  group_by(indicador, umedida) %>% 
  summarise(n_registros = n(), .groups = "drop") %>% 
  select(indicador, umedida, n_registros)

# Ejercicio 12 ------------------------------------------------------------

grafica_fecundidad_mty <- datos_municipales %>% 
  filter(Clave.de.indicador == 138, 
         Nombre.de.la.metrópoli == "Monterrey") %>% 
  filter(Año == max(Año))

ggplot(grafica_fecundidad_mty, 
       aes(x = reorder(Municipio, Valor), y = Valor)) + # <--- AQUÍ ESTÁ EL TRUCO
  geom_col(fill = "darkred") + 
  coord_flip() + 
  labs(
    title = "Fecundidad Adolescente",
    subtitle = "Zona Metropolitana de Monterrey | Año más reciente",
    x = "Municipio",
    y = "Tasa (Indicador 138)"
  ) +
  theme_minimal()

# Ejercicio 13 ------------------------------------------------------------

celulares_ancho <- datos_estatales %>% 
  filter(no == 98) %>% 
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>% 
  left_join(catalogo_edos, by = "cve_ent") %>% 
  select(cve_ent, entidad, year, valor) %>% 
  filter(year %in% c(2000, 2005, 2010, 2015, 2020)) %>% 
  pivot_wider(names_from = year, values_from = valor)

# Ejercicio 14 ------------------------------------------------------------

celulares_largo <- celulares_ancho %>% 
  pivot_longer(cols = -c(cve_ent, entidad), 
               names_to = "year", 
               values_to = "valor") %>% 
  mutate(year = as.numeric(year))

# Ejercicio 15 ------------------------------------------------------------

ambiental <- datos_estatales %>% 
  filter(no %in% c(564, 950, 628), 
         cve_ent == "19")

ambiental_con_nombres <- ambiental %>% 
  left_join(datos_significado_edos, by = "no") 

ggplot(ambiental_con_nombres, aes(x = year, y = valor, color = indicador)) +
  geom_line() +
  geom_point() + 
  facet_wrap(~indicador, scales = "free_y") + 
  theme_minimal() +
  labs(title = "Indicadores Ambientales - Nuevo León")

# Ejercicio 16 ------------------------------------------------------------

participacion_jalisco <- padron_electoral %>% 
  filter(`NOMBRE\r\nENTIDAD` == "JALISCO") %>% 
  mutate(total_padron = PAD87 + PAD88) %>% 
  arrange(desc(total_padron)) %>% 
  head(15) #Elegimos al padrón electoral de Jalisco, los 15 primeros y los ordena

ggplot(participacion_jalisco, 
       aes(x = reorder(`NOMBRE\r\nMUNICIPIO`, total_padron), y = total_padron)) +
  geom_col(fill = "firebrick") + 
  coord_flip() + 
  labs(
    title = "Municipios con mayor Padrón Electoral en Jalisco",
    subtitle = "Suma de columnas n87 (H) y n88 (M)",
    x = "Municipio",
    y = "Número de Ciudadanos"
  ) +
  theme_minimal() # Hace la gráfica de barras para el padrón electoral




