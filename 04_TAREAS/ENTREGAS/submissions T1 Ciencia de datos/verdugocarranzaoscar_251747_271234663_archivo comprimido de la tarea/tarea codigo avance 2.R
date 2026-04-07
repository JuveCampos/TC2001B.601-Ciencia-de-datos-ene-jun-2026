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

# SECCIÓN 1

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

# Ejercicio 9: facet_wrap -------------------------------------------------
# Indicador: Lluvia promedio por entidad (no = 950)

# Filtrar indicador para los estados y años solicitados
lluvia_estados <- indicadores_estatales %>%
  filter(
    no == 950,
    year >= 2002,
    year <= 2024,
    !cve_ent %in% c("00","33","34","99")
  ) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad %in% c("Tabasco", "Chihuahua", "Jalisco", "Yucatán", "Ciudad de México", "Baja California"))

# Crear gráfica con facet_wrap
grafica_lluvia <-
  lluvia_estados %>%
  ggplot(aes(x = year, y = valor)) +
  geom_line() +
  geom_smooth(method = "lm") +
  facet_wrap(~entidad, scales = "free_y") +
  labs(
    title = "Lluvia promedio anual por estado",
    subtitle = "México, 2002-2024",
    x = "Año",
    y = "Lluvia promedio"
  ) +
  theme_minimal()

grafica_lluvia

# SECCIÓN 3

# Ejercicio 10: _join de dos indicadores ----------------------------------
# Indicadores: Homicidios (no = 173) y Satisfacción con la vida (no = 569)

# Filtrar indicador de homicidios
homicidios <- indicadores_estatales %>%
  filter(
    no == 173,
    !cve_ent %in% c("00", "33", "34", "99")
  ) %>%
  select(cve_ent, year, valor) %>%
  rename(valor_homicidios = valor)

# Filtrar indicador de satisfacción con la vida
satisfaccion <- indicadores_estatales %>%
  filter(
    no == 569,
    !cve_ent %in% c("00", "33", "34", "99")
  ) %>%
  select(cve_ent, year, valor) %>%
  rename(valor_satisfaccion = valor)

# Unir ambos indicadores por estado y año
violencia_satisfaccion <- homicidios %>%
  inner_join(satisfaccion, by = c("cve_ent", "year")) %>%
  left_join(cat_edos, by = "cve_ent")

# Filtrar un año en común para hacer la gráfica
violencia_satisfaccion_2023 <- violencia_satisfaccion %>%
  filter(year == 2023)

# Crear scatter plot
grafica_violencia_satisfaccion <-
  violencia_satisfaccion_2023 %>%
  ggplot(aes(x = valor_homicidios, y = valor_satisfaccion)) +
  geom_point() +
  labs(
    title = "Homicidios y satisfacción con la vida por estado",
    subtitle = "México, 2023",
    x = "Homicidios",
    y = "Satisfacción con la vida"
  ) +
  theme_minimal()

grafica_violencia_satisfaccion

# Comentario:
# En la gráfica se puede observar si existe una relación negativa, positiva
# o débil entre homicidios y satisfacción con la vida.

# Ejercicio 11: left_join con metadatos ----------------------------------
# Indicadores: Todos los estatales + metadatos

# Unir la base estatal con los metadatos por la columna "no"
datos_con_metadatos <- indicadores_estatales %>%
  left_join(metadatos_estatales, by = "no")

# Crear tabla resumen con nombre del indicador, unidad de medida y número de registros
indicadores_salud <- datos_con_metadatos %>%
  group_by(indicador, umedida) %>%
  summarise(n_registros = n()) %>%
  arrange(desc(n_registros))

indicadores_salud

# Ejercicio 12: Join con datos municipales -------------------------------
# Indicador municipal: Fecundidad adolescente (Clave de indicador == 138)

# Vector con los municipios de la Zona Metropolitana de Monterrey
municipios_mty <- c(
  "Apodaca",
  "Cadereyta Jiménez",
  "El Carmen",
  "García",
  "San Pedro Garza García",
  "General Escobedo",
  "Guadalupe",
  "Juárez",
  "Monterrey",
  "Salinas Victoria",
  "San Nicolás de los Garza",
  "Santa Catarina",
  "Santiago"
)

# Obtener el año más reciente disponible
anio_reciente_mty <- indicadores_municipales %>%
  filter(
    `Clave de indicador` == 138,
    Municipio %in% municipios_mty
  ) %>%
  summarise(anio = max(Año, na.rm = TRUE)) %>%
  pull(anio)

# Filtrar los datos del año más reciente
fecundidad_mty <- indicadores_municipales %>%
  filter(
    `Clave de indicador` == 138,
    Año == anio_reciente_mty,
    Municipio %in% municipios_mty
  ) %>%
  select(`Clave de municipio`, Municipio, Indicador, Año, Valor) %>%
  left_join(cat_mun, by = c("Clave de municipio" = "cvegeo")) %>%
  arrange(desc(Valor))

# Crear gráfica de barras por municipio
grafica_fecundidad_mty <-
  fecundidad_mty %>%
  ggplot(aes(x = reorder(Municipio, Valor), y = Valor)) +
  geom_col(fill = "lightcoral") +
  coord_flip() +
  labs(
    title = "Fecundidad adolescente - Zona Metropolitana de Monterrey",
    subtitle = paste("Año:", anio_reciente_mty),
    x = "Municipio",
    y = "Valor"
  ) +
  theme_minimal()

grafica_fecundidad_mty

# SECCIÓN 4

# Ejercicio 13: pivot_wider -----------------------------------------------
# Indicador: Suscripciones celulares (no = 98)

# Filtrar indicador para los años requeridos y solo entidades válidas
celulares <- indicadores_estatales %>%
  filter(
    no == 98,
    year %in% c(2000, 2005, 2010, 2015, 2020),
    !cve_ent %in% c("00", "33", "34", "99")
  ) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  select(entidad, year, valor)

# Crear tabla ancha
celulares_ancho <- celulares %>%
  pivot_wider(
    names_from = year,
    values_from = valor
  )

celulares_ancho

# Ejercicio 14: pivot_longer ----------------------------------------------
# Datos: Resultado del ejercicio 13

# Transformar la tabla ancha de celulares a formato largo
celulares_largo <- celulares_ancho %>%
  pivot_longer(
    cols = -entidad,
    names_to = "year",
    values_to = "valor"
  ) %>%
  mutate(year = as.numeric(year))

celulares_largo

# Ejercicio 15: pivot + ggplot - Dashboard ambiental ----------------------
# Indicadores: Residuos sólidos (no = 564), Lluvia promedio (no = 950),
# Incendios forestales (no = 628)

# Filtrar los 3 indicadores para un solo estado
ambiental_estado <- indicadores_estatales %>%
  filter(
    no %in% c(564, 950, 628),
    cve_ent == "25"
  ) %>%
  left_join(metadatos_estatales, by = "no") %>%
  select(year, valor, indicador)

# Crear gráfica con un panel por indicador
grafica_ambiental <-
  ambiental_estado %>%
  ggplot(aes(x = year, y = valor)) +
  geom_line(color = "tomato4") +
  facet_wrap(~indicador, scales = "free_y") +
  labs(
    title = "Tendencias de indicadores ambientales en Sinaloa",
    subtitle = "Residuos sólidos, lluvia promedio e incendios forestales",
    x = "Año",
    y = "Valor"
  ) +
  theme_minimal()

grafica_ambiental

# Ejercicio 16: Visualización de base de datos --------------------------------

# Cargar datos ------------------------------------------------------------
# Se lee la base de datos guardada en la carpeta del proyecto.
# Debido al formato del archivo de excel en el que venía tuve que cambiar la 
# manera de leerlo y lo busque en internet el como hacerlo.
vehiculos_raw <- read_csv("01_V_ENE_2025.csv", locale = locale(encoding = "latin1"))
# Revisar datos -----------------------------------------------------------
glimpse(vehiculos_raw)

# Procesamiento de datos --------------------------------------------------
# Se seleccionan las columnas necesarias y se eliminan registros vacíos.

vehiculos_limpios <- vehiculos_raw %>%
  select(trafico, movimiento, marca_submarca, cantidad, mes, año) %>%
  filter(!is.na(marca_submarca),
         !is.na(cantidad))

# Se guarda una versión limpia de la base en la carpeta del proyecto.
write_csv(vehiculos_limpios, "vehiculos_ene_2025_limpio.csv")

# Preparar datos para la gráfica ------------------------------------------
# Se calcula el total de vehículos por marca y se ordenan de mayor a menor.
# Después se toman las 7 marcas con mayor cantidad.

top_marcas <- vehiculos_limpios %>%
  group_by(marca_submarca) %>%
  summarise(total_vehiculos = sum(cantidad, na.rm = TRUE)) %>%
  arrange(desc(total_vehiculos)) %>%
  head(10)

top_marcas

# Gráfica final -----------------------------------------------------------
# Se crea una gráfica de barras horizontales con color por valor.

grafica_vehiculos <-
  top_marcas %>%
  ggplot(aes(x = reorder(marca_submarca, total_vehiculos),
             y = total_vehiculos,
             fill = total_vehiculos)) +
  geom_col() +
  coord_flip() +
# Vamos a usar diferentes tonos de rojos por honor a ferrari 
  scale_fill_gradient(low = "red", high = "red4") +
  labs(
    title = "Top 7 marcas con más vehículos reportados",
    subtitle = "De acuerdo con la Administración del Sistema Portuario Nacional Mazatlán",
    x = "Marca / submarca",
    y = "Total de vehículos",
    fill = "Cantidad"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 12),
    axis.text.y = element_text(size = 10)
  )

grafica_vehiculos

# En mi caso si vamos a guardar la gráfica -------------------------------------

ggsave(
  filename = "grafica_vehiculos_ene_2025.png",
  plot = grafica_vehiculos,
  width = 10,
  height = 7
)
