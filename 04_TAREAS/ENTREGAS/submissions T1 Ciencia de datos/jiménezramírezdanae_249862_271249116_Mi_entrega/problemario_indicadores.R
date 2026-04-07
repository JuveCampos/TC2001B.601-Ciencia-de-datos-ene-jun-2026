#Cargar librerías
library(tidyverse)
library(ggplot2)

#Cargar archivos 
datos = "datos_problemario/"
cat_edos = read_csv("datos_problemario/cat_edos.csv")
cat_mun = read_csv("datos_problemario/cat_mun.csv")
met_mun = read_csv("datos_problemario/metadatos_municipales.csv")
met_est = read_csv("datos_problemario/metadatos_estatales.csv")
ind_mun = read_csv("datos_problemario/indicadores_municipales.csv")
ind_est = read_csv("datos_problemario/indicadores_estatales.csv")

# Sección 1: Verbos del tidyverse -----------------------------------------

#Ejercicio 1: ¿Cuáles son los 3 estados con mayor pobreza en 2022?
# Filtrar el indicador de pobreza (no == 921)
top_3_pobreza = ind_est %>% 
  filter(no == 921) %>%  # Seleccionar indicador de pobreza
  filter(year == 2022) %>% # Filtrar año 2022
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>% # Eliminar números que no corresponden a estados válidos
  select(cve_ent, valor) %>%  # Seleccionar solo las columnas necesarias
  left_join(cat_edos, by = "cve_ent") %>% # Unir con el catálogo de estados para obtener nombres
  arrange(desc(valor)) %>%   # Ordenar de mayor a menor según el valor de pobreza
  head(3) # Tomar los 3 estados con mayor nivel de pobreza

#Ejercicio 2: ¿Cuántos años de diferencia hay entre el estado con mayor y menor esperanza de vida?
top_5_ev = ind_est %>% 
  filter(no == 54) %>% 
  filter(year == 2020) %>%   
  filter(!cve_ent %in% c("00","33","34","99")) %>%  
  select(cve_ent, valor) %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  arrange(desc(valor)) %>% 
  head(5)

bottom_5_ev <- ind_est %>% 
  filter(no == 54) %>%
  filter(year == 2020) %>% 
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, valor) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  arrange(valor) %>%
  head(5)

ev_dif <- ind_est %>% # Calcular la diferencia entre el valor máximo y mínimo de EV
  filter(no == 54) %>% # Filtrar el indicador EV (no == 54)
  filter(year == 2020) %>% # Filtrar únicamente el año 2020
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  summarise(diferencia = max(valor) - min(valor))   # Calcular la diferencia entre el valor máximo y mínimo

#Ejercicio 3: ¿Qué estado tuvo el mayor crecimiento porcentual en adopción de celulares?
tabla_cambio_resultados = ind_est %>% # Crear tabla con el cambio porcentual entre 2005 y 2020
  filter(no == 98, year %in% c(2005, 2020), !cve_ent %in% c("00","33","34","99")) %>%
  pivot_wider(names_from = year, values_from = valor) %>%  # Convertir los años en columnas (2005 y 2020)
  mutate(cambio_pct = (`2020` - `2005`) / `2005` * 100) %>% # Calcular el cambio porcentual entre 2005 y 2020
  left_join(cat_edos, by = "cve_ent") %>% # Unir con el catálogo de estados para obtener nombres
  arrange(desc(cambio_pct)) %>% # Ordenar de mayor a menor según el cambio porcentual
  head(1)

#Ejercicio 4: ¿En qué década se registra el mayor promedio de vehículos por 1000 habitantes? ¿De cuanto es este promedio para la década con el valor más alto?
vehiculos_decada = ind_est %>% # Agrupar los datos de vehículos por década y calcular estadísticas
  filter(no == 156) %>%   # Filtrar la clave correspondiente al total nacional
  filter(cve_ent %in% c("00","0","000")) %>%
  mutate(decada = paste0(floor(year/10)*10,"s")) %>%   # Crear una variable de década (ej. 1990s, 2000s)
  group_by(decada) %>%   # Agrupar por década
  summarise(
    promedio = mean(valor, na.rm = TRUE),
    desv_est = sd(valor, na.rm = TRUE)
  ) # Calcular promedio y desviación estándar por década
vehiculos_decada %>%
  arrange(desc(promedio)) %>%
  head(1) # Ordenar por promedio de mayor a menor y obtener la década con mayor valor

# Sección 2: Gráficas con ggplot2 -----------------------------------------

#Ejercicio 5: Gráfica mortalidad por diabetes por 100k (no = 36)
grafica_diabetes <- ind_est %>% # Crear gráfica de mortalidad por diabetes en ciertos estados
  filter(no == 36, year >= 2000, year <= 2023) %>% # Filtrar el indicador de diabetes (no == 36) y el rango de años 2000 a 2023
  left_join(cat_edos, by = "cve_ent") %>% # Unir con el catálogo de estados para obtener nombres
  filter(entidad %in% c("Chiapas","Tabasco","Puebla","Nuevo León","Sonora")) %>% # Filtrar solo los estados de interés
  # Crear la gráfica
  ggplot(aes(x = year, y = valor, color = entidad)) + 
  geom_line(size = 0.5)  +
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

#Ejercicio 6: Satisfacción con la vida (no = 569)
grafica_satisfaccion <- ind_est %>%
  filter(no == 569) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  left_join(cat_edos, by = "cve_ent")
  
grafica_satisfaccion %>%   
  ggplot(aes(x = reorder(entidad, valor), y = valor, fill = valor)) +
  geom_col() +
  coord_flip() +
  scale_fill_gradient(low = "palevioletred1", high = "maroon3") +
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

#Ejercicio 7: ¿Qué relación observas entre desarrollo económico y fecundidad adolescente?
grafica_pib_fecundidad <- ind_est %>%
  filter(no %in% c(1266, 40), year == 2020, !cve_ent %in% c("00", "33", "34", "99")) %>%
  pivot_wider(names_from = no, values_from = valor) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  ggplot(aes(x = `1266`, y = `40`)) +
  geom_point(size = 2, color = "red") +
  labs(
    title = "PIB per cápita y fecundidad adolescente por estado, 2020",
    x = "PIB per cápita",
    y = "Fecundidad adolescente"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    axis.text = element_text(color = "black"),
    axis.title = element_text(color = "black"),
    options(scipen = 999)
  )
grafica_pib_fecundidad

#Ejercicio 8: Mortalidad por diabetes (no = 36)
grafica_diabetes_final <- ind_est %>%
  filter(no == 36, year >= 2000, year <= 2023) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad %in% c("Chiapas","Tabasco","Puebla","Nuevo León","Sonora")) %>%
#Gráfica
  ggplot(aes(x = year, y = valor, color = entidad)) +
  geom_line(size = 0.5) +
  labs(
    title = "Mortalidad por diabetes por 100,000 habitantes (2000–2023)",
    subtitle = "SALUD. Base de datos del Subsistema de Información sobre Nacimientos. SALUD. Bases de datos de mortalidad. http://www.beta.inegi.org.mx/proyectos/registros/vitales/mortalidad/default.html",
    caption = "Danae Jiménez Ramírez",
    x = "Año",
    y = "Mortalidad por diabetes",
    color = "Estado"
  ) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 10),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(size = 10)
  ) +
  scale_color_manual( # Asignar colores específicos a cada estado
    values = c(
      "Chiapas" = "violetred",
      "Tabasco" = "dodgerblue",
      "Puebla" = "brown",
      "Nuevo León" = "palegreen",
      "Sonora" = "violet"
    )) +
  scale_y_continuous(expand = expansion(c(0, 0.15))) # Ajustar el eje Y para mejor visualización

grafica_diabetes_final

#Ejercicio 9: Lluvia promedio por entidad (no = 950)
grafica_lluvia <- ind_est %>%
  filter(no == 950, year >= 2002, year <= 2024) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad %in% c("Tabasco", "Chihuahua", "Jalisco", "Yucatán", "Ciudad de México", "Baja California")) %>% # Filtrar solo los estados que se quieren comparar
  ggplot(aes(x = year, y = valor)) +
  geom_line(color = "hotpink") + # Agregar la línea de comportamiento anual
  geom_smooth(method = "lm", se = FALSE, color = "skyblue") + # Agregar una línea de tendencia lineal
  facet_wrap(~entidad, scales = "free_y") +   # Separar la gráfica en paneles por entidad
  labs(
    title = "Lluvia promedio anual por entidad (2002–2024)",
    x = "Año",
    y = "Lluvia promedio",
    subtitle = "Estados seleccionados de distintas regiones de México"
  ) +
  theme (plot.title = element_text(face = "bold"))
grafica_lluvia

# Sección 3: Unión de tablas – joins --------------------------------------

#Ejercicio 10: ¿Los estados más violentos son menos felices? Describe en un comentario la relación que observas.
homicidios <- ind_est %>%
  filter(no == 173) %>%
  select(cve_ent, year, valor) %>%  # Seleccionar variables necesarias
  rename(valor_homicidios = valor) # Renombrar la variable de valor

satisfaccion <- ind_est %>%
  filter(no == 569) %>%
  select(cve_ent, year, valor) %>%
  rename(valor_satisfaccion = valor)

datos <- inner_join(homicidios, satisfaccion, by = c("cve_ent","year")) %>% # Unir ambas bases por estado y año
  left_join(cat_edos, by = "cve_ent") # Agregar nombres de estados

#Gráfica
grafica_violencia_satisfaccion <- datos %>%
  filter(year == 2023) %>%
  ggplot(aes(x = valor_homicidios, y = valor_satisfaccion)) +
  geom_point(color = "orchid1") + # Agregar puntos
  geom_smooth(method = "lm", se = FALSE, color = "olivedrab1") +
  labs(
    title = "Relación entre homicidios y satisfacción con la vida",
    subtitle = "Estados de México, 2023",
    x = "Homicidios",
    y = "Satisfacción con la vida"
  ) +
  theme_minimal() + 
  theme(plot.title = element_text(face = "bold"))  # Ajuste del título

grafica_violencia_satisfaccion

#Ejercicio 11: Todos los estatales + metadatos 
indicadores_salud <- ind_est %>%
  left_join( # Unir con la base de metadatos para obtener nombre del indicador, unidad y clasificación
    met_est %>% select(no, indicador, umedida, clasificacion),
    by = "no"
  ) %>% 
  group_by(indicador, umedida) %>% # Agrupar por nombre del indicador y unidad de medida
  summarise(n_registros = n(), .groups = "drop")  # Contar el número de registros por cada indicador

indicadores_salud

#Ejercicio 12: Fecundidad adolescente (`Clave de indicador`== 138)
municipios_monterrey <- c(
  "Apodaca", "Cadereyta Jiménez", "El Carmen", "García",
  "San Pedro Garza García", "General Escobedo", "Guadalupe",
  "Juárez", "Monterrey", "Salinas Victoria",
  "San Nicolás de los Garza", "Santa Catarina", "Santiago"
) # Crear un vector con los municipios de la Zona Metropolitana de Monterrey

año_reciente_mty <- ind_mun %>% 
  filter(`Clave de indicador` == 138,
         Municipio %in% municipios_monterrey) %>%
  summarise(año = max(Año, na.rm = TRUE)) %>%
  pull(año) # Obtener el año más reciente disponible para el indicador 138

fecundidad_mty <- ind_mun %>%
  filter(`Clave de indicador` == 138,
         Año == año_reciente_mty,
         Municipio %in% municipios_monterrey) %>%
  select(`Clave de municipio`, Municipio, Indicador, Año, Valor) %>%
  left_join(cat_mun, by = c("Clave de municipio" = "cvegeo")) %>%
  arrange(desc(Valor)) # Crear una base con los datos del indicador de fecundidad

#Gráfica
grafica_fecundidad_mty <- fecundidad_mty %>%
  ggplot(aes(x = reorder(Municipio, Valor), y = Valor)) +
  geom_col(fill = "plum1") +
  coord_flip() + # Girar la gráfica para que los nombres de municipios se lean mejor
  labs(title = paste(unique(fecundidad_mty$Indicador), "- Zona Metropolitana de Monterrey"),
       subtitle = paste("Año de la gráfica:", año_reciente_mty),
       x = "Municipio",
       y = "Valor")+
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5))

grafica_fecundidad_mty

# Sección 4: Pivoteo de datos ---------------------------------------------

#Ejercicio 13: pivot_wider
celulares_tabla_ancho <- ind_est %>%
  filter(no == 98) %>%  # Filtrar el indicador de celulares (no == 98)
  filter(year %in% c(2000, 2005, 2010, 2015, 2020)) %>% # Seleccionar años específicos de análisis
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  select(entidad, year, valor) %>%
  pivot_wider(names_from = year, values_from = valor) # Convertir la tabla a formato ancho (cada año como columna)

celulares_tabla_ancho # Mostrar la tabla final

#Ejercicio 14: pivot_longer
celulares_tabla_largo <- celulares_tabla_ancho %>%
  left_join(cat_edos, by = "entidad") %>%
  select(cve_ent, entidad, `2000`, `2005`, `2010`, `2015`, `2020`) %>%
  pivot_longer( # Convertir de formato ancho a largo
    cols = -c(cve_ent, entidad),
    names_to = "year",
    values_to = "valor"
  ) %>%
  mutate(year = as.numeric(year)) # Convertir el año a formato numérico

celulares_tabla_largo

#Ejercicio 15: pivot + ggplot – Dashboard ambiental
grafica_ambiental <- ind_est %>%
  filter(no %in% c(564, 950, 628)) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad == "Jalisco") %>%
  left_join(
    met_est %>% select(no, indicador),
    by = "no"
  ) %>%
  ggplot(aes(x = year, y = valor)) +
  geom_line(color = "sienna1") +
  facet_wrap(~indicador, scales = "free_y") +
  labs(
    title = "Indicadores ambientales Jalisco",
    subtitle = "Residuos sólidos, lluvia promedio e incendios forestales",
    x = "Año",
    y = "Valor"
  ) +
  theme_sub_axis() + # Aplicar estilo del eje secundario
  theme(
    plot.title = element_text(face = "bold") # Poner el título principal en negritas
  )

grafica_ambiental

# Sección 5: Integración --------------------------------------------------
datos_individual = read.csv("economia-y-turismo-en-el-centro-historico.csv") # Cargar la base de datos de establecimientos del Centro Histórico

conteo_por_tipo <- datos_individual %>% # Contar cuántos establecimientos hay por tipo
  count(tipo) %>% # Contar frecuencia de cada tipo
  arrange(desc(n)) # Ordenar de mayor a menor

grafica_establecimientos <- ggplot(conteo_por_tipo, aes(x = reorder(tipo, -n), y = n)) + # Crear gráfica de barras de establecimientos por tipo
  geom_col(fill = "firebrick1", width = 0.5) + # Crear barras
  geom_text(aes(label = n), vjust = -0.5, size = 5) +
  labs(
    title = "Distribución de establecimientos en el Centro Histórico",
    subtitle = "Cantidad de registros por tipo",
    caption = "Elaborado con datos de la Autoridad del Centro Histórico, 2021",
    x = "Tipo de establecimiento",
    y = "Número de registros"
  ) +
  theme_linedraw(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5),
    plot.subtitle = element_text(size = 12, color = "black", hjust = 0.5),
    axis.title = element_text(face = "bold"),
    axis.text.x = element_text(hjust = 0.5),
    plot.caption = element_text(size = 8)
  )

grafica_establecimientos











  




