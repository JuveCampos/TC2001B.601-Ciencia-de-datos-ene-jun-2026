# Tarea No. 1
# Autor: Gerardo Alberto Gómez Salazar | A01669213
# PROYECTO: INDICADORES SOCIOECONÓMICOS DE MÉXICO (TIDYVERSE + GGPLOT2)

# Carga de librerías necesarias
library(tidyverse)
library(readxl)

#Cargando todos los datos de la carpeta "datos_problemario"
metadatos_estatales <- read_csv("datos_problemario/metadatos_estatales.csv")
metadatos_municipales <- read_csv("datos_problemario/metadatos_municipales.csv")
indicadores_estatales <- read_csv("datos_problemario/indicadores_estatales.csv")
indicadores_municipales <- read_csv("datos_problemario/indicadores_municipales.csv")
catalogo_estados <- read_csv("datos_problemario/cat_edos.csv")
catalogo_municipales <- read_csv("datos_problemario/cat_mun.csv")

# SECCIÓN 1: VERBOS DEL TIDYVERSE -----------------------------------------

# Ejercicio 1: filter + select (Pobreza 2022) -----------------------------

pobreza_2022 <- indicadores_estatales %>%
# Filtramos para quedarnos con el indicador 921 y el año 2022
  filter(no == 921, year == 2022) %>%
# Excluimos “00”, “33”, “34” y “99” 
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
# Seleccionamos las columnas con las cuales nos queremos quedar
  select(cve_ent, valor) %>%
# Unimos con el catalogo de estados para saber el estado al que corresponde cve_ent
  left_join(catalogo_estados, by = "cve_ent") %>%
# Ordenamos la tabla de mayor a menor según el nivel de pobreza
  arrange(-valor)
pobreza_2022

# Pregunta: ¿Cuáles son los 3 estados con mayor pobreza en 2022?
# Respuesta: Los estados con mayor pobreza son Chiapas (67.4), Guerrero (60.4) y Oaxaca (58.4).


# Ejercicio 2: arrange + slice (Esperanza de vida 2020) -------------------

esperanza_vida_2020 <- indicadores_estatales %>% 
# Filtramos pora quedarnos solo con el indicador 54 y el año 2020
  filter(no == 54, year == 2020) %>%
# Excluimos “00”, “33”, “34” y “99”
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
# Unimos con el catalogo de estados para saber el estado al que corresponde cve_ent
  left_join(catalogo_estados, by = "cve_ent")

# Obtenemos top y bottom y con slice nos quedamos únicamente con los primeros 5
top_5_ev <- esperanza_vida_2020 %>% 
  arrange(-valor) %>% 
  slice(1:5) 
bottom_5_ev <- esperanza_vida_2020 %>% 
  arrange(valor) %>% 
  slice(1:5)
#calculamos la diferencia del valor máximo y el mínimo
diferencia_ev <- max(esperanza_vida_2020$valor) - min(esperanza_vida_2020$valor)
diferencia_ev
# Pregunta: ¿Cuántos años de diferencia hay entre el mayor y menor?
# Respuesta: 7.33 años


# Ejercicio 3: mutate (Suscripciones celulares) ---------------------------

tabla_cambio_celulares <- indicadores_estatales %>%
# Filtramos por el indicador 98, años 2005 y 2020 y excluimos “00”, “33”, “34” y “99”
  filter(no == 98, year %in% c(2005, 2020)) %>%
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
  left_join(catalogo_estados, by = "cve_ent") %>%
# Transforma los datos de formato "largo" a "ancho". Los valores del año 
# (2005 y 2020) se convierten en columnas nuevas llamadas anio_2020 y anio_2005 
# para calcular los cambios absolutos y porcentuales
  pivot_wider(names_from = year, values_from = valor, names_prefix = "anio_") %>%
# Crea nuevas columas a partir de las ya existentes
  mutate(cambio_abs = anio_2020 - anio_2005,
         cambio_pct = (cambio_abs / anio_2005) * 100) %>% 
# Ordena la tabla de forma descendente basándose en el crecimiento porcentual.
  arrange(-cambio_pct)
tabla_cambio_celulares

# Pregunta: ¿Qué estado tuvo el mayor crecimiento porcentual? 
# Respuesta: Durango con 390



# Ejercicio 4: group_by + summarise (Vehículos por década) ----------------

vehiculos_decada <- indicadores_estatales %>%
  # Filtramos por el indicador 156, y nos quedamos con los valores iguales “00”
  filter(no == 156, cve_ent == "00") %>%
# Hacemos una columna nueva llamada decada
  mutate(decada = (year %/% 10) * 10) %>%
# Agrupamos por decada para sacar el promedio y la desviación estandar
  group_by(decada) %>%
  summarise(promedio = mean(valor),
            desv_est = sd(valor)) %>% 
  arrange (-promedio)
vehiculos_decada
  
# Pregunta: ¿En qué década se registra el mayor promedio? 
# Respuesta: La década de 2020 presenta el promedio más alto con 420



# SECCIÓN 2: GRÁFICAS CON GGPLOT2 -----------------------------------------

# Ejercicio 5: geom_line (Diabetes), mortalidad diabetes para 5 es --------

grafica_diabetes <- indicadores_estatales %>%
# Filtramos por el indicador 36, y nos quedamos con los valores del año 2000 hasta el 2023
  filter(no == 36, year >= 2000 & year <= 2023) %>%
  left_join(catalogo_estados, by = "cve_ent") %>%
# Me quedo con 5 estados 
  filter(entidad %in% c("Chiapas", "Tabasco", "Puebla", "Nuevo León", "Oaxaca"))
# Genero la grafica
grafica_diabetes %>% 
# Definimos la estetica, con color definimo que los colores estan en funcion de la entidad
  ggplot(aes(x = year, y = valor, color = entidad)) +
# Dibuja las lineas con el grosor 1
  geom_line(linewidth = 1) +
# Ponemos las etiquetas al titulo, del eje de las x y y
  labs(title = "Mortalidad por Diabetes (2000-2023)",
       x = "Año", 
       y = "Tasa por 100k hab") +
# Aplicamos el tema minimal a la grafica
  theme_minimal() +
# Mueve la lista de estados (leyenda) a la parte de abajo,ajustamos alineacion,
# tipo de letra y tamaño
  theme(legend.position = "bottom",
        plot.title = element_text(hjust = 0,
        family = "Arial", 
        face = "bold", 
        size = 18))



# Ejercicio 6: geom_col (Satisfacción con la vida), Barras horizon --------

grafica_satisfaccion <- indicadores_estatales %>%
  # Filtramos por el indicador 569, el año mas reciente y excluimos “00”, “33”, “34” y “99”
  filter(no == 569) %>% 
  filter(year == max(year)) %>%
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
  left_join(catalogo_estados, by = "cve_ent")
grafica_satisfaccion %>%
# Le damos estetica y reordenamos las entidades segun nivel de satisfacción
  ggplot(aes(x = reorder(entidad, valor), 
             y = valor, 
             #El color de relleno de las barras dependerá de qué tan alto es el valor.
             fill = valor)) + 
  # Generamos una grafica de barras
  geom_col() + 
  # Gira la grafica para que ahora sea horizontal
  coord_flip() +
  # Hacemos un degradado de color dependiendo del valor
  scale_fill_gradient(low = "skyblue", high = "darkblue") +
  # Ponemos los nombres a las etiquetas
  labs(title = "Satisfacción con la vida por Estado", 
       x = "Estado", 
       y = "Nivel de Satisfacción")

# Pregunta: ¿Cuál fue el estado con la mayor satisfacción por la vida? 
# Respuesta: Chihuahua con 8.86



# Ejercicio 7: geom_point (PIB vs Fecundidad), relación entre desa --------

# Quitamos notación cientifica
options(scipen = 999) 
grafica_pib_fecundidad <- indicadores_estatales %>%
# Filtramos por el indicador 1266 y 40, el año 2020
  filter(no %in% c(1266, 40), year == 2020) %>%
# Pasamos de formato largo a formato ancho 
  pivot_wider(names_from = no, values_from = valor) %>%
# Renombramos las columnas 1266 y 40 por nombres mas faciles de entender
  rename(pib_capita = `1266`, fec_adol = `40`)

grafica_pib_fecundidad %>% 
# Le damos la estetica y definimos que valores van en el eje x y y
  ggplot(aes(x = pib_capita, y = fec_adol)) +
#Generamos una grafica de dispersión, con los puntos en rojo oscuro y tamaño 3
  geom_point(color = "darkred", size = 3) +
# Ponemos los nombres a las etiquetas
  labs(title = "Relación PIB per cápita y Fecundidad Adolescente (2020)",
       x = "PIB per cápita", 
       y = "Fecundidad Adolescente")

# Pregunta: ¿Qué relación observas? 
# Respuesta: Se observa una correlación negativa; a mayor PIB per cápita, 
# tiende a disminuir la fecundidad adolescente.



# Ejercicio 8: Personalización de graficas  -------------------------------

grafica_diabetes_final <- grafica_diabetes %>% 
# iniciamos la grafica y definimos los elementos esteticos
  ggplot(aes(x = year, 
             y = valor, 
             color = entidad)) + #creamos una linea de difernte colos para cada Estado
# decimos que queremos una grafica de linea con un grosor de 1
  geom_line(linewidth = 1) +
  # Aplicamos las personalizaciones
  labs(
    title = "Mortalidad por diabetes por 100k", 
    subtitle = "Fuente: Metadatos del Sistema de Indicadores", 
    caption = "Elaborado por: Gerardo Alberto Gómez Salazar",
    x = "Año",
    y = "Tasa por 100k hab"
  ) + 
# Aplicamos manualmente colores a cada estado
  scale_color_manual(values = c(
    "Chiapas" = "green", 
    "Tabasco" = "blue", 
    "Puebla" = "brown", 
    "Nuevo León" = "orange", 
    "Oaxaca" = "red" 
  )) + 
# Si los numeros son muy grandes con comma hacemos que les ponga una coma
  scale_y_continuous(labels = scales::comma) +
  theme_minimal()
grafica_diabetes_final


# Ejercicio 9: facet_wrap (Lluvia promedio por entidad mediante pa --------

grafica_lluvia <- indicadores_estatales %>%
# Filtramos por el indicador 950 y del año 2002 al año 2024
  filter(no == 950, year >= 2002 & year <= 2024) %>%
  left_join(catalogo_estados, by = "cve_ent") %>%
# Nos quedamos con Tabasco, Chihuahua, Jalisco, Yucatán, Ciudad de México y Baja California 
  filter(entidad %in% c("Tabasco", "Chihuahua", "Jalisco", "Yucatán", "Ciudad de México", "Baja California")) %>%
# Generamos la grafica  
  ggplot(aes(x = year, y = valor)) +
  geom_line() +
# Añadimos la líne de tendencia
  geom_smooth(method = "lm", formula = y ~ x, color = "blue", se = FALSE) +
# Realizamos una grafica por cada uno de las entidades liberando el eje de las y
  facet_wrap(~entidad, scales = "free_y") +
  theme_bw()
grafica_lluvia


# SECCIÓN 3: UNIÓN DE TABLAS – JOINS --------------------------------------

# Ejercicio 10: join de dos indicadores (Violencia vs Felicidad) ----------


# Declaramos homicidios y filtramos para quedarnos solo con homicidios (173)
homicidios <- indicadores_estatales %>% 
  filter(no == 173) %>% 
# Seleccionamos las columnas con las cuales nos queremos quedar y renombramos 
# valor por valor_homicidios
  select(cve_ent, year, valor_homicidios = valor)
# Declaramos felicidad y filtramos para quedarnos solo con felicidad (569)
felicidad <- indicadores_estatales %>% 
  filter(no == 569) %>% 
# Seleccionamos las columnas con las cuales nos queremos quedar y renombramos 
# valor por valor_satisfacción  
  select(cve_ent, year, valor_satisfacción = valor)
# Unimos los datos con (cve_ent) y (year) y los guardamos en una nueva variable
datos_combinados <- inner_join(homicidios, felicidad, by = c("cve_ent", "year"))
# Generamos la grafica
grafica_violencia_satisfaccion <- datos_combinados %>%
  ggplot(aes(x = valor_homicidios, y = valor_satisfacción)) +
# Creamos la grafica de dispersion 
  geom_point() +

  geom_smooth(method = "lm", formula = y ~ x) +
  labs(title = "Homicidios vs Satisfacción con la Vida")
grafica_violencia_satisfaccion

# Pregunta: ¿Los estados más violentos son menos felices?
# Respuesta: La gráfica muestra una correlación positiva débil entre la tasa de 
# homicidios y la satisfacción con la vida. Sorprendentemente, la tendencia 
# sugiere que niveles más altos de homicidios coinciden con niveles ligeramente 
# mayores de satisfacción. Podría deberse a factores externos (variables omitidas)
# o a que los estados con más violencia también tienen otros factores 
# (económicos o sociales) que mantienen alta la percepción de satisfacción.


# Ejercicio 11: left_join con metadatos, tabla resumen de indicado --------

indicadores_salud <- indicadores_estatales %>%
# Unimos con metadatos para saber qué significa cada número 'no'
  left_join(metadatos_estatales, by = "no") %>%
# Agrupamos indicador y umedida
  group_by(indicador, umedida) %>% 
# Sumamos para saber el nuemero de registros
  summarise(
    n_registros = n(),
# Para procesos posteriores dejamos de considerar las datos en grupos
    .groups = "drop"
  ) %>% 
# Ordenamos la tabla resultante de forma descendente con el signo
  arrange(- n_registros)
indicadores_salud


# Ejercicio 12: Join con datos municipales (ZM Monterrey)  ----------------

# Filtramos municipios específicos de la ZM Monterrey
lista_municipios <- c("Apodaca", "Cadereyta Jiménez", "El Carmen", "García", 
                      "San Pedro Garza García", "General Escobedo", "Guadalupe", 
                      "Juárez", "Monterrey", "Salinas Victoria", "San Nicolás de los Garza", 
                      "Santa Catarina", "Santiago")

grafica_fecundidad_mty <- indicadores_municipales %>%
# Filtramos para quedarnos con el indicador 138
  filter(`Clave de indicador` == 138) %>% 
# Filtramos para quedarnos con los municipios de nuestra lista
  filter(Municipio %in% lista_municipios) %>% 
# Agrupamos por municipio y obtenemos el registro más reciente
  group_by(Municipio) %>% 
  filter(Año == max(Año)) %>%
# Como en Juarez y Guadalupe me salia dos veces el año, con distinct hago que
# solo se quede con un registro
distinct(Municipio, .keep_all = TRUE) %>%
# Para procesos posteriores dejamos de considerar las datos en grupos, a diferencia de 
# .groups = "drop" que se usa dentro de un summarise
  ungroup() %>% 
# Generamos la gráfica y reordenamos de mayor a menor en lugar de por orden alfabtico
  ggplot(aes(x = reorder(Municipio, Valor), y = Valor)) +
# definimos una grafica de column as
  geom_col(fill = "steelblue") +
# Ponemos la etiqueta del año empleado y personalizamos
  geom_text(aes(label = Año), 
            hjust = 1.2, 
            color = "white", 
            size = 3.5, 
            fontface = "bold") +
# Giramos la grafica, las x pasan a ser las y
  coord_flip() +
  labs(
    title = "Fecundidad adolescente en la ZM Monterrey",
    subtitle = "Dato más reciente disponible por municipio",
    x = "Municipio", 
    y = "Tasa de fecundidad"
  ) +
  theme_minimal()
grafica_fecundidad_mty



# SECCIÓN 4: PIVOTEO DE DATOS ---------------------------------------------

# Ejercicio 13: pivot_wider (ormato ancho) suscripciones de celula --------

celulares_ancho <- indicadores_estatales %>%
# filtramos para quedarnos con el indicador 98 y los años indicados
  filter(no == 98, year %in% c(2000, 2005, 2010, 2015, 2020)) %>%
# filtramos para excluir "00", "33", "34", "99"
  filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
# unimos con el catalogo de estados
  left_join(catalogo_estados, by = "cve_ent") %>%
# seleccionamos las columnas con las cuales nos queremos quedar
  select(cve_ent, entidad, year, valor) %>%
# Cambiamos la estructura de la base de formato largo a ancho
  pivot_wider(names_from = year, values_from = valor)
celulares_ancho



# Ejercicio 14: pivot_longer (Formato largo) revertimos el proceso --------

celulares_largo <- celulares_ancho %>%
# transformamos la tabla de formato ancho a largo
  pivot_longer(cols = -c(cve_ent, entidad), 
               names_to = "year", 
               values_to = "valor") %>%
# Convierte la columna year nuevamente a numeros
  mutate(year = as.numeric(year))
celulares_largo


# Ejercicio 15: Dashboard ambiental, tendencias para un solo estad --------

grafica_ambiental <- indicadores_estatales %>%
# Filtramos para quedarnos con el indicador 564, 950 y 628
  filter(no %in% c(564, 950, 628)) %>%
# Unimos con el catalogo de estados
  left_join(catalogo_estados, by = "cve_ent") %>%
# Filtramos para quedarnos con Oaxaca
  filter(entidad == "Oaxaca") %>%
# Unimos con los metadatos
  left_join(metadatos_estatales, by = "no") %>%
# Generamos la grafica
  ggplot(aes(x = year, y = valor)) +
# Generamos una linea del tiempo
  geom_line(color = "darkgreen") +
# Generamos una grafica por cada indicador liberando el eje de las y
  facet_wrap(~indicador, scales = "free_y") +
  theme_light() +
  labs(title = "Dashboard Ambiental: Oaxaca")
grafica_ambiental


# SECCIÓN 5: INTEGRACIÓN --------------------------------------------------

# Ejercicio 16: Datos propios ---------------------------------------------


# Cargare un xlsx de los precios historicos de Tesla del 10-Mar.-2025 al 
# 9-Mar-2026 y generare su gráfica

library(tidyverse)
library(lubridate) #libreria util para el manejo de la fechas

# Carga de mi xlsx
tesla <- read_xlsx("datos_problemario/Tesla_Precios_historico.xlsx")

tesla_final <- tesla %>%
# Convertimos texto en fecha para asegurarnos que se lea correctamente
  mutate(Fecha = as.Date(Fecha)) %>%
# ordena las fechas más antiguos al principio y las más recientes al final
  arrange(Fecha)
# Generamos la grafica
grafica_tesla_final <- tesla_final %>%
  ggplot(aes(x = Fecha, y = Precio)) +
  # Usamos geom_line para una gráfica de líneas
  geom_line(color = "red", linewidth = 1) + 
  # Formatos y etiquetas
  scale_x_date(date_labels = "%b %Y", date_breaks = "2 months") +
  labs(
    title = "Evolución del precio de cierre de Tesla (TSLA)",
    subtitle = "Gráfica de líneas simple",
    caption = "Elaborado por: Gerardo Alberto Gómez Salazar",
    x = "Fecha",
    y = "Precio (USD)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(color = "gray30",
                                  hjust = 0,
                                  family = "Arial", 
                                  face = "bold", 
                                  size = 25
  ), 
  plot.subtitle = element_text(color = "#c2a827", 
                               hjust = 0,
                               family = "Arial", 
                               face = "bold", 
                               size = 16
  ), 
  plot.caption = element_text(color = "blue", 
                              hjust = 1,
                              family = "Arial", 
                              face = "bold", 
                              size = 7), 
  axis.text = element_text(size = 10)
  )

grafica_tesla_final

ggsave("Grafica_Tesla_GerardoGomez.png", 
       plot = grafica_tesla_final, 
       width = 10, 
       height = 6,)

