


# Librerias ---------------------------------------------------------------

library(tidyverse)
library(readr)
library(readxl)
library(ggthemes)
library(scales)
library(stringi)

# Datos -------------------------------------------------------------------

ruta <- "datos_problemario/"

indicadores_estatales <- read_csv(paste0(ruta,"indicadores_estatales.csv"))
indicadores_municipales <- read_csv(paste0(ruta,"indicadores_municipales.csv"))
metadatos_estatales <- read_csv(paste0(ruta,"metadatos_estatales.csv"))
metadatos_municipales <- read_csv(paste0(ruta,"metadatos_municipales.csv"))
cat_edos <- read_csv(paste0(ruta,"cat_edos.csv"))
cat_mun <- read_csv(paste0(ruta,"cat_mun.csv"))


# Ejericio 1 --------------------------------------------------------------


pobreza_2022 <- indicadores_estatales %>%
  filter(no == 921,
         year == 2022,
         !cve_ent %in% c("00","33","34","99")) %>% #filtramos solo el 2022 y eliminamos codigos no validos
  select(cve_ent, valor) %>%
  left_join(cat_edos, by="cve_ent") %>%
  arrange(desc(valor)) #seleccionamos las columnas de estado y valor, agregamos los nombres de los estados y ordenamos de amyor a menor 

top3_pobreza <- pobreza_2022 %>%
  slice(1:3) #selecionamos el top 3 mas pobre 
  
top3_pobreza

#PREGUNTA: los estados con mayor pobreza son chiapas, guerrero y oaxaca.


# Ejercicio 2 -------------------------------------------------------------

esperanza_vida <- indicadores_estatales %>%
  filter(no == 54,
         year == 2020,
         !cve_ent %in% c("00","33","34","99")) %>% #filtramos solo 2020
  left_join(cat_edos, by="cve_ent") %>%
  arrange(desc(valor))

top_5_ev <- esperanza_vida %>% #obtenemos el top 5 mas alto
  slice(1:5)

bottom_5_ev <- esperanza_vida %>% #obtenemos el top 5 mas bajo 
  arrange(valor) %>%
  slice(1:5) #ordenamos de mayor a menor y seleccionamos los 5 mas bajos


dif_ev <- max(esperanza_vida$valor) - min(esperanza_vida$valor) #calcuamos la diferencia entre valor maximo y  minimo 
#PREGUNTA: 7.3381


# Ejercicio 3 -------------------------------------------------------------

celulares <- indicadores_estatales %>%
  filter(no == 98,
         year %in% c(2005,2020),
         !cve_ent %in% c("00","33","34","99")) %>% #Filtrar datos para 2005 y 2020
  pivot_wider(names_from = year,
              values_from = valor) #convertir los años en columnas

cambio_celulares <- celulares %>% #guardar variable 
  mutate(
    cambio_abs = `2020` - `2005`,
    cambio_pct = ((`2020` - `2005`) / `2005`) * 100 #calculo del cambio %
  ) %>%
  left_join(cat_edos, by="cve_ent") %>%
  arrange(desc(cambio_pct)) #ordenar por mayor crecimiento

cambio_celulares
#PREGUNTA: Durango

# Ejericicio 4 ------------------------------------------------------------

vehiculos_decada <- indicadores_estatales %>%
  filter(no == 156,
         cve_ent == "00") %>% #Fitrar indicador a nivel nacional
  mutate(decada = floor(year/10)*10) %>%
  group_by(decada) %>%
  summarise(
    promedio = mean(valor, na.rm = TRUE),
    desv_est = sd(valor, na.rm = TRUE) #agrupacion de datos y calculo de promedio y desviaicon estandar por decada
  )

vehiculos_decada
#PREGUNTA: Se registra mayor promedio en la decada de 2020 con 420.11 

# Ejercicio 5 -------------------------------------------------------------


diabetes <- indicadores_estatales %>%
  filter(no == 36,
         year >= 2000,
         year <= 2023) %>% #filtro de años 2000 y 2023
  left_join(cat_edos, by="cve_ent") %>%
  filter(entidad %in% c("Chiapas","Tabasco","Puebla","Nuevo León","Sonora")) #seleccion de estos estados

grafica_diabetes <- ggplot(diabetes,
                           aes(x=year,y=valor,color=entidad)) + #definiciond e grafica y variables
  scale_color_manual(
    values = c("Chiapas" = "red",
               "Nuevo León" = "blue",
               "Puebla" = "green3",
               "Sonora" = "black",
               "Tabasco" = "yellow4"))+
  
  geom_line(size=1) +
  labs(
    title="Tasa de mortalidad a causa de diabetes en México",
    subtitle= "Del 2000 al 2020 5 estados registraron las mayores cifras de mortalidad a causa de diabetes",
    x="Año",
    y="Tasa por 100k habitantes"
  ) +
  theme_linedraw() #definicion de lineas, tamaño, titulos, ejes y etiquetas

grafica_diabetes

ggsave("output/grafica_diabetes.png", grafica_diabetes, width = 8, height = 6)

# Ejercicio 6 -------------------------------------------------------------

satisfaccion <- indicadores_estatales %>%
  filter(no == 569,
         !cve_ent %in% c("00","33","34","99")) %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  left_join(cat_edos, by="cve_ent") #filtra el indoicador mas reciete se satisfaccion

grafica_satisfaccion <- ggplot(satisfaccion,
                               aes(x=reorder(entidad,valor),
                                   y=valor,
                                   fill=valor)) +
  geom_col() +
  coord_flip() +
  scale_fill_gradient() +
  labs(
    title="Sentimiento de satisfacción con la vida por estado",
    subtitle = "En una escala de 1 a 10 se puntuo que tanto los habitantes de cada estado estan conformes con su situación",
    x="Estado",
    y="Valor"
  ) +
  theme_sub_axis_bottom() #crea la grafica 

grafica_satisfaccion
#PREGUNTA: El estado con mas satisfaccion fue chihuahua 
ggsave("output/grafica_satisfaccion.png", grafica_satisfaccion, width = 8, height = 6)

# Ejercicio 7 -------------------------------------------------------------

pib <- indicadores_estatales %>%
  filter(no == 1266,
         year == 2020,
         !cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, year, valor) %>%
  rename(pib = valor) #filtra los años pone nombre a estados y renombra variable para pib

fecundidad <- indicadores_estatales %>%
  filter(no == 40,
         year == 2020,
         !cve_ent %in% c("00","33","34","99")) %>%
  select(cve_ent, year, valor) %>%
  rename(fecundidad = valor) #filtra años seleciona columbas y renombra vaiable para feculdidad 

datos_scatter <- inner_join(pib, fecundidad,
                            by=c("cve_ent","year")) %>%
  left_join(cat_edos, by="cve_ent") #une los datos de pib y fecundidad 

grafica_pib_fecundidad <- ggplot(datos_scatter,
                                 aes(x=pib,y=fecundidad)) +
  geom_point() +
  scale_x_continuous(labels = comma) +
  labs(
    x="PIB per cápita",
    y="Fecundidad adolescente",
    title="Relación entre PIB y fecundidad adolescente"
  ) +
  theme_economist()

grafica_pib_fecundidad 
#PREGUNTA: Existe una tendendia dodne a mayor desarollo suele disminuir la tasa de fecundiad adolecente
ggsave("output/grafica_pib_fecundidad.png", grafica_pib_fecundidad, width = 8, height = 6)

# Ejercicio 8 -------------------------------------------------------------

grafica_diabetes_final <- ggplot(diabetes,
                                 aes(x=year,y=valor,color=entidad)) +
  geom_line(size=1.2) +
  scale_color_manual(values=c(
    "Chiapas"="red",
    "Tabasco"="blue",
    "Puebla"="brown",
    "Nuevo León"="green",
    "Sonora"="purple"
  )) +
  scale_y_continuous() +
  labs(
    title="Mortalidad por diabetes en México",
    subtitle="Fuente: consulta metadatos",
    caption="Hecho por: Arturo Valerio",
    x="Año",
    y="Tasa por 100k"
  ) +
  theme_economist_white() 

grafica_diabetes_final #se corrije la grafica anterior de diabetes 

ggsave("output/grafica_diabetes_final.png", grafica_diabetes_final, width = 8, height = 6)

# Ejericicio 9 ------------------------------------------------------------

lluvia <- indicadores_estatales %>%
  filter(no == 950,
         year >= 2002,
         year <= 2024) %>%
  left_join(cat_edos, by="cve_ent") %>%
  filter(entidad %in% c("Tabasco","Chihuahua","Jalisco",
                        "Yucatán","Ciudad de México",
                        "Baja California")) #filtra datos de lluvia en varios estados

grafica_lluvia <- ggplot(lluvia,
                         aes(x=year,y=valor)) +
  geom_line() +
  labs(
    x="Año",
    y="Valor"
  )+
  geom_smooth(method="lm") +
  
  facet_wrap(~entidad, scales="free_y") + #crea lineas de tendencia 
  theme_replace()

grafica_lluvia

ggsave("output/grafica_lluvia.png", grafica_lluvia, width = 10, height = 8)

# Ejericicio 10 -----------------------------------------------------------

homicidios <- indicadores_estatales %>%
  filter(no == 173) %>%
  rename(valor_homicidios = valor)

satisfaccion <- indicadores_estatales %>%
  filter(no == 569) %>%
  rename(valor_satisfaccion = valor)

violencia_satisfaccion <- inner_join(homicidios,
                                     satisfaccion,
                                     by=c("cve_ent","year")) #unifica homiciios y satisfacion en una sola tabla 

grafica_violencia_satisfaccion <- ggplot(
  violencia_satisfaccion %>% filter(year == 2020),
  aes(x = valor_homicidios, y = valor_satisfaccion)
) +
  geom_point() +
  geom_smooth(method = "lm", color = "firebrick", se = FALSE) + 
  labs(
    title = "¿Los estados más violentos son menos felices?",
    subtitle = "Relación entre Homicidios y Satisfacción con la Vida (2020)",
    caption = "Fuente: Consulta metadatos",
    x = "Tasa de Homicidios (por cada 100k habitantes)",  
    y = "Nivel de Satisfacción con la Vida"             
  ) +
  theme_light() #grafica su relacion con puntos y regrecion 

grafica_violencia_satisfaccion
#PREGUNTA: Se observa una ausencia de correlación clara entre ambas variables. A pesar de que se esperaría que a mayor violencia hubiera menor satisfacción
ggsave("output/grafica_violencia_satisfaccion.png", grafica_violencia_satisfaccion, width = 8, height = 6)

# Ejericicio 11 -----------------------------------------------------------

indicadores_salud <- indicadores_estatales %>% #une indicadores con metadatos 
  left_join(metadatos_estatales,
            by="no") %>%
  group_by(indicador, umedida) %>%
  summarise(
    n_registros = n() #cuenta cuantos registros hay por indicador 
  )

# Ejericicio 12 -----------------------------------------------------------

municipios_mty <- c("Apodaca","Cadereyta Jiménez","El Carmen",
                    "García","San Pedro Garza García",
                    "General Escobedo","Guadalupe","Juárez",
                    "Monterrey","Salinas Victoria",
                    "San Nicolás de los Garza",
                    "Santa Catarina","Santiago") #filtra los municipios de nuevo leon 

fecundidad_mty <- indicadores_municipales %>%
  filter(`Clave de indicador` == 138) %>%
  left_join(cat_mun, by = c("Municipio" = "nom_mun")) %>%
  filter(Municipio %in% municipios_mty) #filtra la fecundidad por municipio selecionado


anio_reciente <- max(fecundidad_mty$Año, na.rm = TRUE)

fecundidad_mty_reciente <- fecundidad_mty %>%
  filter(Año == anio_reciente)


grafica_fecundidad_mty <- ggplot(fecundidad_mty_reciente,
                                 aes(x = reorder(Municipio, Valor),
                                     y = Valor)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Fecundidad adolescente en la Zona Metropolitana de Monterrey",
    subtitle = paste("Indicador 138 | Año:", anio_reciente),
    x = "Municipio",
    y = "Valor"
  ) +
  theme_update()

grafica_fecundidad_mty

ggsave("output/grafica_fecundidad_mty.png", grafica_fecundidad_mty, width = 8, height = 6)
# Ejericicio 13 -----------------------------------------------------------

celulares_ancho <- indicadores_estatales %>%
  filter(no == 98,
         year %in% c(2000,2005,2010,2015,2020),
         !cve_ent %in% c("00","33","34","99")) %>%
  left_join(cat_edos, by="cve_ent") %>%
  pivot_wider(names_from=year,
              values_from=valor)

celulares_ancho #convierte datos a formato ancho 


# Ejericicio 14 -----------------------------------------------------------

celulares_largo <- celulares_ancho %>%
  pivot_longer(
    cols=c(`2000`,`2005`,`2010`,`2015`,`2020`),
    names_to="year",
    values_to="valor"
  ) %>%
  mutate(year=as.numeric(year))

celulares_largo # convierte datos a formato largo


# Ejericicio 15 -----------------------------------------------------------

estado_sel <- "Puebla"

ambiental <- indicadores_estatales %>%
  filter(no %in% c(564, 950, 628)) %>%
  left_join(cat_edos, by = "cve_ent") %>%
  filter(entidad == estado_sel) %>%
  left_join(metadatos_estatales, by = "no") %>% #filtra indicadors ambientales por estado 

  mutate(indicador_limpio = str_wrap(indicador, width = 30))


grafica_ambiental <- ggplot(ambiental, aes(x = year, y = valor)) + #grafica su elvolucion en multiples paneles
  geom_line(color = "steelblue", size = 0.8) + 
  geom_point(color = "darkblue", size = 1) +   
  facet_wrap(~indicador_limpio, 
             scales = "free_y", 
             ncol = 3) + 
  labs(
    title = paste("Evolución de Indicadores Ambientales:", estado_sel),
    subtitle = "Periodo disponible por indicador",
    x = "Año",
    y = "Valor de la unidad correspondiente",
    caption = "Fuente: Elaboración propia con datos del repositorio estatal"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(face = "bold", size = 9), 
    panel.spacing = unit(1.5, "lines"),               
    axis.text.x = element_text(angle = 45, hjust = 1)  
  )

grafica_ambiental

ggsave("output/grafica_ambiental.png", grafica_ambiental, width = 10, height = 8)

# Ejericicio 16 -----------------------------------------------------------

datos <- read.csv("datos_problemario/1-19.csv", stringsAsFactors = FALSE)


datos$Member <- ifelse(datos$Member == ".", NA, datos$Member)
datos$Member <- gsub(",", "", datos$Member)
datos$Member <- as.numeric(datos$Member) #limpia datos 


datos$Year <- as.numeric(datos$Year)


datos <- datos %>%
  filter(Chamber == "House")


datos_resumen <- datos %>%
  group_by(Year, Party) %>%
  summarise(Member = sum(Member, na.rm = TRUE), .groups = "drop") #agrupa año y partido


datos_resumen <- datos_resumen %>%
  arrange(Year)


grafica_house <- ggplot(datos_resumen, aes(x = Year, y = Member, color = Party, group = Party)) +
  geom_line(size = 1.2) +
  geom_point() +
  scale_color_manual(
    values = c("D" = "#2E86C1", "R" = "#E74C3C"))+
  
  labs(
    title = "Número de mujeres electas a la Cámara de Representantes de EE.UU. por partido",
    subtitle = "El partido Democrata a postulado a más mujeres a la cámara que el partido Republicano",
    x = "Año",
    y = "Número de mujeres electas",
    color = "Partido",
    caption ="Fuente: Congressional Quarterly's Guide to U.S. Elections")+
  theme_economist_white()+
  theme(plot.title = element_text(color = "black",
                                  hjust = 0,
                                  family = "Arial",
                                  face = "bold",
                                  size = 20,
  ),
  plot.subtitle = element_text(color = "gray30",
                               hjust = 0.5,
                               family = "Arial",
                               face = "bold",
                               size = 15,
  ),
  plot.caption = element_text(color = "gray30",
                              hjust = 1,
                              family = "Arial",
                              face = "bold",
                              size = 10
  ),
  axis.text = element_text(size = 10),
  )

grafica_house #grafica la evolucion de mujeres en el congreso 

ggsave("output/grafica_house.png", width = 10, height = 6)
