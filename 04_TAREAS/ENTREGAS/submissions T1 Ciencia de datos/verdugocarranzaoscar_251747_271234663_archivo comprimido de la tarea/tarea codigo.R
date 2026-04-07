# Actividad M1.1: Fundamentos de programación -----------------------------
options(scipen = 999)
# Cargar bibliotecas ------------------------------------------------------
library(tidyverse)
library(ggplot2)

# Cargar datos ------------------------------------------------------------
# Se cargan los datos de la carpeta datos_problemario usando rutas relativas

indicadores_estatales <- read_csv("datos_problemario/indicadores_estatales.csv")
indicadores_municipales <- read_csv("datos_problemario/indicadores_municipales.csv")
metadatos_estatales <- read_csv("datos_problemario/metadatos_estatales.csv")
metadatos_municipales <- read_csv("datos_problemario/metadatos_municipales.csv")
cat_edos <- read_csv("datos_problemario/cat_edos.csv")
cat_mun <- read_csv("datos_problemario/cat_mun.csv")

# Ejercicio 1: filter + select --------------------------------------------
# Indicador: % población en pobreza (no = 921)

# Se filtra el indicador de pobreza para el año 2022 y solo para las 32
# entidades federativas. Después se seleccionan las columnas necesarias.
pobreza_2022 <- indicadores_estatales %>%
  filter(
    no == 921,
    year == 2022,
    !cve_ent %in% c("00", "33", "34", "99")
  ) %>%
  select(cve_ent, valor)

# Se une con el catálogo de estados para obtener el nombre de cada entidad.
pobreza_estados_2022 <- pobreza_2022 %>%
  left_join(cat_edos, by = "cve_ent")

# Se ordenan los estados de mayor a menor valor y se toman los primeros 3.
top3_pobreza_2022 <- pobreza_estados_2022 %>%
  arrange(desc(valor)) %>%
  head(3)

top3_pobreza_2022

# Ejercicio 2: arrange + slice --------------------------------------------
# Indicador: Esperanza de vida al nacer (no = 54)

# Se filtra el indicador para el año 2020 y solo para las 32 entidades.
esperanza_vida_2020 <- indicadores_estatales %>%
  filter(
    no == 54,
    year == 2020,
    !cve_ent %in% c("00", "33", "34", "99")
  ) %>%
  select(cve_ent, valor)

# Se une con el catálogo de estados para agregar los nombres.
ev_estados_2020 <- esperanza_vida_2020 %>%
  left_join(cat_edos, by = "cve_ent")

# Se obtienen los 5 estados con mayor esperanza de vida.
top_5_ev <- ev_estados_2020 %>%
  arrange(desc(valor)) %>%
  head(5)

# Se obtienen los 5 estados con menor esperanza de vida.
bottom_5_ev <- ev_estados_2020 %>%
  arrange(valor) %>%
  head(5)

# Se calcula la diferencia entre el valor máximo y el mínimo.
diferencia_ev <- ev_estados_2020 %>%
  summarise(diferencia = max(valor) - min(valor))

top_5_ev
bottom_5_ev
diferencia_ev

# Ejercicio 3: mutate -----------------------------------------------------
# Indicador: Suscripciones celulares por 100 hab (no = 98)

# Se filtra el indicador para los años 2005 y 2020 y solo para las 32
# entidades federativas.
celulares_2005_2020 <- indicadores_estatales %>%
  filter(
    no == 98,
    year %in% c(2005, 2020),
    !cve_ent %in% c("00", "33", "34", "99")
  ) %>%
  select(cve_ent, year, valor)

# Se transforman los años en columnas para poder comparar ambos valores.
# Después se calcula el cambio absoluto y el cambio porcentual.
cambio_celulares <- celulares_2005_2020 %>%
  pivot_wider(names_from = year, values_from = valor) %>%
  mutate(
    cambio_abs = `2020` - `2005`,
    cambio_pct = ((`2020` - `2005`) / `2005`) * 100
  ) %>%
  left_join(cat_edos, by = "cve_ent")

# Se ordena la tabla de mayor a menor crecimiento porcentual.
cambio_celulares_ordenado <- cambio_celulares %>%
  arrange(desc(cambio_pct))

cambio_celulares
cambio_celulares_ordenado

# Ejercicio 4: group_by + summarise ---------------------------------------
# Indicador: Vehículos por 1,000 hab (no = 156)

# Se filtra el indicador para el nivel nacional.
vehiculos_nacional <- indicadores_estatales %>%
  filter(
    no == 156,
    cve_ent == "00"
  ) %>%
  select(year, valor)

# Se crea la columna de década y después se calcula el promedio y la
# desviación estándar de vehículos por década.
vehiculos_decada <- vehiculos_nacional %>%
  mutate(decada = paste0(floor(year / 10) * 10, "s")) %>%
  group_by(decada) %>%
  summarise(
    promedio = mean(valor, na.rm = TRUE),
    desv_est = sd(valor, na.rm = TRUE)
  ) %>%
  arrange(desc(promedio))

vehiculos_decada

# SECCIÓN 2

# Ejercicio 5: geom_line --------------------------------------------------
# Indicador: Mortalidad por diabetes por 100k (no = 36)

# Se filtran los estados y el indicador requerido entre 2000 y 2023
diabetes_estados <- indicadores_estatales %>%
  filter(
    no == 36,
    year >= 2000,
    year <= 2023,
    !cve_ent %in% c("00","33","34","99")
  ) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad %in% c("Chiapas", "Tabasco", "Puebla", "Nuevo León", "Sonora"))

# Se crea la gráfica de líneas
grafica_diabetes <-
  diabetes_estados %>%
  ggplot(aes(x = year,
             y = valor,
             color = entidad,
             group = entidad)) +
  geom_line(linewidth = 1.2) +
  labs(
    title = "Mortalidad por diabetes por cada 100 mil habitantes",
    subtitle = "Estados seleccionados, 2000-2023",
    x = "Año",
    y = "Mortalidad por 100 mil habitantes",
    color = "Estado"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "bottom"
  )

grafica_diabetes

# Ejercicio 6: geom_col ---------------------------------------------------
# Indicador: Satisfacción con la vida (no = 569)

# Filtrar indicador para el año 2024 y excluir claves que no son estados
satisfaccion_2024 <- indicadores_estatales %>%
  filter(
    no == 569,
    year == 2024,
    !cve_ent %in% c("00","33","34","99")
  ) %>%
  select(cve_ent, valor)

# Unir con el catálogo de estados
satisfaccion_estados <- satisfaccion_2024 %>%
  left_join(cat_edos, by = "cve_ent")

# Crear gráfica de barras horizontales
grafica_satisfaccion <-
  satisfaccion_estados %>%
  ggplot(aes(x = reorder(entidad, valor),
             y = valor,
             fill = valor)) +
  geom_col() +
  coord_flip() +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(
    title = "Satisfacción con la vida por estado",
    subtitle = "México, 2024",
    x = "Estado",
    y = "Nivel de satisfacción"
  ) +
  theme_minimal()

grafica_satisfaccion

# Ejercicio 7: geom_point (scatter plot) ----------------------------------
# Indicadores: PIB per cápita (no = 1266) y Fecundidad adolescente (no = 40)

# Filtrar los indicadores para el año 2020
pib_fecundidad_2020 <- indicadores_estatales %>%
  filter(
    no %in% c(1266, 40),
    year == 2020,
    !cve_ent %in% c("00","33","34","99")
  ) %>%
  select(cve_ent, no, valor)

# Pasar los indicadores a columnas
tabla_pib_fecundidad <- pib_fecundidad_2020 %>%
  pivot_wider(names_from = no, values_from = valor) %>%
  left_join(cat_edos, by = "cve_ent")

# Crear scatter plot
grafica_pib_fecundidad <-
  tabla_pib_fecundidad %>%
  ggplot(aes(x = `1266`, y = `40`)) +
  geom_point() +
  labs(
    title = "PIB per cápita y fecundidad adolescente por estado",
    subtitle = "México, 2020",
    x = "PIB per cápita",
    y = "Fecundidad adolescente"
  ) +
  theme_minimal()

grafica_pib_fecundidad

# Ejercicio 8: Personalización de gráficas --------------------------------
# Indicador: Mortalidad por diabetes (no = 36)

# Crear vector de colores para los estados
colores_estados <- c(
  "Chiapas" = "darkgreen",
  "Tabasco" = "red",
  "Puebla" = "brown",
  "Nuevo León" = "blue",
  "Sonora" = "orange"
)

# Mejorar la gráfica del ejercicio 5
grafica_diabetes_final <-
  diabetes_estados %>%
  ggplot(aes(x = year,
             y = valor,
             color = entidad,
             group = entidad)) +
  geom_line(linewidth = 1.2) +
  labs(
    title = "Mortalidad por diabetes por cada 100 mil habitantes en 
    cinco estados de México",
    subtitle = "Fuente: SALUD.  Base de datos del Subsistema de Información sobre Nacimientos. 
    SALUD.  Bases de datos de mortalidad. http://www.beta.inegi.org.mx/proyectos/registros
    /vitales/mortalidad/default.html
",
    caption = "Elaborado por OScar Verdugo",
    x = "Año",
    y = "Mortalidad por 100 mil habitantes",
    color = "Estado"
  ) +
  scale_color_manual(values = colores_estados) +
  scale_y_continuous(expand = expansion(c(0, 0.05))) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 9),
    legend.position = "bottom"
  )

grafica_diabetes_final

