library(tidyverse)
library(ggplot2)

#Cargar archivos
cat_edos <- read_csv("datos_problemario/cat_edos.csv")

indicadores_estatales <- read_csv("datos_problemario/indicadores_estatales.csv")

metadatos_estatales <- read_csv("datos_problemario/metadatos_estatales.csv")

#Ejercicio 1 Filter + Select

ejercicio_1 <- indicadores_estatales %>% 
  filter(no == 921, year == 2022) %>% 
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>% 
  select(cve_ent, valor) %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  arrange(desc(valor))

#Reultado (Primeros 3)
head(ejercicio_1,3) 

# Ejercicio 2 Arrange + Slice 
ejercicio_2 <- indicadores_estatales %>% 
  filter(no == 54, year == 2022) %>% 
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>% 
  select(cve_ent, valor) %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  arrange(desc(valor))

#Reultado (Primeros 5)
head(ejercicio_2,5)
tail(ejercicio_2,5)


#Ejercicio 3: Mutate
tabla_cambio_celulares = indicadores_estatales %>%
  filter(no == 98, year %in% c(2005, 2020), !cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, year, valor) %>%
  pivot_wider(names_from = year, values_from = valor) %>%
  mutate(cambio_pct = (2020 - 2005) / 2005 * 100) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  arrange(desc(cambio_pct)) %>%
  head(1)

#Ejercicio 4:group_by + summarise
vehiculos_decada = indicadores_estatales %>%
  filter(no == 156) %>%
  filter(cve_ent %in% c("00","0","000")) %>%
  mutate(decada = paste0(floor(year/10)*10,"s")) %>%
  group_by(decada) %>%
  summarise(
    promedio = mean(valor, na.rm = TRUE),
    desv_est = sd(valor, na.rm = TRUE)
  )
vehiculos_decada %>%
  arrange(desc(promedio)) %>%
  head(1)


#Ejercicio 5:  geom_line
grafica_diabetes <- indicadores_estatales %>%
  filter(no == 36, year >= 2000, year <= 2023) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad %in% c("Chiapas","Tabasco","Puebla","Nuevo León","Sonora")) %>%
  ggplot(aes(x = year, y = valor, color = entidad)) +
  geom_line(size = 0.5) +
  labs(
    title = "Mortalidad por diabetes por 100,000 habitantes (2000–2023)",
    x = "Año",
    y = "Mortalidad por diabetes",
    color = "Estado"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 10),
    plot.title = element_text(face = "bold")
  )
grafica_diabetes

#Ejercicio 6: geom_col
grafica_satisfaccion <- indicadores_estatales %>%
  filter(no == 569) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  left_join(cat_edos, by = "cve_ent")

grafica_satisfaccion %>%   
  ggplot(aes(x = reorder(entidad, valor), y = valor, fill = valor)) +
  geom_col() +
  coord_flip() +
  scale_fill_gradient(low = "green", high = "darkgreen") +
  labs(
    title = "Satisfacción con la vida por estado",
    x = "Estado",
    y = "Satisfacción con la vida",
    fill = "Valor"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 10, color = "black"),
    plot.title = element_text(face = "bold", hjust = 0.5, color = "black"),
    axis.text.y = element_text(size = 5, color = "black"),
    axis.text.x = element_text(color = "black"),
    axis.title = element_text(color = "black"),
  )
grafica_satisfaccion


# Ejercicio 7: geom_point

# Filtrar para el año 2020
pib_fecundidad_2020 <- indicadores_estatales %>%
  filter(
    no %in% c(1266, 40),
    year == 2020,
    !cve_ent %in% c("00","33","34","99")
  ) %>%
  select(cve_ent, no, valor)

# Indicadores a columnas

tabla_pib_fecundidad <- pib_fecundidad_2020 %>%
  pivot_wider(names_from = no, values_from = valor) %>%
  left_join(cat_edos, by = "cve_ent")

# Hacer la scatter plot
grafica_pib_fecundidad <-
  tabla_pib_fecundidad %>%
  ggplot(aes(x = 1266, y = 40)) +
  geom_point() +
  labs(
    title = "PIB per cápita y fecundidad adolescente por estado",
    subtitle = "México, 2020",
    x = "PIB per cápita",
    y = "Fecundidad adolescente"
  ) +
  theme_minimal()

grafica_pib_fecundidad

# Ejercicio 8: Personalización de gráficas

# Crear vector de colores para los estados
colores_estados <- c(
  "Chiapas" = "pink",
  "Tabasco" = "blue",
  "Puebla" = "brown",
  "Nuevo León" = "yellow",
  "Sonora" = "red"
)


class(grafica_diabetes)
# Rehacer grafica de ejercicio 5
grafica_diabetes_final <- grafica_diabetes +
  # Escala de colores manual
  scale_color_manual(values = colores_estados) +
  scale_y_continuous(expand = expansion(c(0, 0.05))) +
  labs(
    title = "Evolución de la Mortalidad por Diabetes en México",
    subtitle = "Fuente: SALUD. Bases de datos de mortalidad (INEGI)",
    caption = "Elaborado por Salvador Gutiérrez",
    x = "Año",
    y = "Mortalidad por cada 100 mil habitantes",
    color = "Entidad Federativa"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10),
    legend.position = "bottom"
  )

# Visualizar el resultado
grafica_diabetes_final

colnames(indicadores_estatales)

#Ejercicio 9: facet_wrap

# Definimos los estados
estados_9 <- c("Tabasco", "Chihuahua", "Jalisco", 
               "Yucatán", "Ciudad de México", "Baja California")

# Generamos la gráfica
grafica_ejercicio_9 <- indicadores_estatales %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  filter(no == 950, 
         entidad %in% estados_9,
         year >= 2002 & year <= 2024) %>% 
  
  ggplot(aes(x = year, y = valor, color = entidad)) +
  geom_line(alpha = 0.4) +
  geom_point(size = 1) +
  
  # Tendencia lineal
  geom_smooth(method = "lm", color = "black", se = FALSE, linetype = "dashed") +
  
  # Paneles por nombre de estado
  facet_wrap(~entidad, scales = "free_y") +
  
  labs(
    title = "Tendencia de Lluvia Promedio Anual (2002-2024)",
    subtitle = "Paneles por entidad con regresión lineal",
    x = "Año",
    y = "Lluvia promedio",
    caption = "Elaborado por Salvador Gutiérrez"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# Mostrar gráfica
grafica_ejercicio_9
