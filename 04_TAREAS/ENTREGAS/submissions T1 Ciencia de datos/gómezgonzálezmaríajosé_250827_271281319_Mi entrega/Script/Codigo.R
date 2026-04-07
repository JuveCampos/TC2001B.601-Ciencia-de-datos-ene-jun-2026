
# Titulo  -----------------------------------------------------------------
#Nombre: María José Gómez González
#Id-A01661632
#Fundamentos de la programación

# Librerias  --------------------------------------------------------------
#carga de libreroas.
library(tidyverse)
library(readxl)
library(ggplot2)
library(dplyr)
library(janitor)
#library(ggplot)

# carga de datos ----------------------------------------------------------
indicadores_estatales<- read_csv("datos_problemario/indicadores_estatales.csv")
indicadores_municipales<-read_csv("datos_problemario/indicadores_municipales.csv")
metadatos_estatales<-read_csv("datos_problemario/metadatos_estatales.csv")
metadatos_municipales<-read_csv("datos_problemario/metadatos_municipales.csv")
cat_edos<-read_csv("datos_problemario/cat_edos.csv")
cat_mun<-read_csv("datos_problemario/cat_mun.csv")
world_athletics<-read_delim("datos_problemario/data.csv", delim=";") #se tuvo que delimitar las clumnas ya que salian como solo un encabezado en lugar de varios, esto por que estaba en ; en lugar de , 
#primero se cargan los catalogos y los datos en el environment en r
# Ejercicio 1: filter + select --------------------------------------------
#Filtra el indicador de pobreza para el año 2022, incluyendo solo las 32 entidades federativas (excluye cve_ent“00”, “33”, “34” y “99”, si llegasen a estar).
  #filtro de datos 
pobreza_2022<-indicadores_estatales %>% 
  filter(no==921, year==2022)
pobreza_2022
#Se fitlraron los datos de pobreza (921) en el año 2022

#eliminación de datos
pobreza_2022<-pobreza_2022 %>% 
  filter(!cve_ent %in% c("00","33","34","99"))
pobreza_2022
#se elimino una fila que tenía el 00, sin emabrgo no se encontraron datos con 33,34 o 99

#unir nombres de estados con la lista princiapal 
pobreza_2022<-pobreza_2022 %>% 
  left_join(cat_edos, by="cve_ent")
pobreza_2022
#se unieron los nombres y ahora en lugar de salir 01 sale "aguascalientes" y asi sucesivamente 

#ordenar de mayor a menor
pobreza_2022 %>% 
  arrange((desc(valor)))
#se ordeno de mayor a menor con el top 1 siendo chiapas
#Top 3
pobreza_2022 %>% 
  arrange(desc(valor)) %>% 
  slice(1:3)
pobreza_2022
#Se obtuvo el top 3
#Respuesta ejerciico 1: El top 3 es Chiapas, Guerrero, Oaxaca. 

# Ejercicio 2 -------------------------------------------------------------
#Obtener el top 5 y bottom 5 de estados por esperanza de vida en 2020
#filtrar el indicador 54 en el año 2024
ev_2020<- indicadores_estatales %>% 
  filter(no==54, year==2020)
ev_2022

#filtrar y excluir entidades 00,33,34,99
ev_2020<-ev_2020 %>% 
  filter(!cve_ent %in% c("00","33","34","99"))
ev_2020
#unir con el catalgo
ev_2020<-ev_2020 %>% 
  left_join(cat_edos, by="cve_ent")
ev_2020

#filtrar el top y 5 y top 5
top_5_ev<-ev_2020 %>% 
  arrange(desc(valor)) %>% 
  slice(1:5)
top_5_ev

bottom_5_ev<-ev_2020 %>% 
  arrange(valor) %>% 
  slice(5:1)
bottom_5_ev
#diferencia entre top 5 y bottom 5
max(top_5_ev$valor)-min(bottom_5_ev$valor)

#Resultado 
#la diferencia de edad entre el más viejo y el más joven es de 7.33 años o 7.34


# Ejercicio 3 -------------------------------------------------------------
#Filtrar los años 2005 y 2020 para las 32 entidades. Calcular el cambio absoluto y el cambio porcentual por estado entre esos dos años.

#filtrar datos 
celulares<-indicadores_estatales %>% 
  filter(no== 98, year %in%c(2005,2020))
celulares

#elimianr datos 
celulares %>% 
  filter(!cve_ent%in%c("00","33","34","99"))

#convertir a fomrato ancho la tabla 
celulares_ancho<-celulares %>% 
  pivot_wider(names_from = year, values_from = valor) %>% 
  filter(!cve_ent%in%c("00","33","34","99"))
celulares_ancho
#esto nos da la tabla de 2005 y 2020 juntas 

#juntar los datos con el catalgo

celulares_ancho<-celulares_ancho %>% 
  left_join(cat_edos, by="cve_ent")
celulares_ancho
#calcular los cambios
cambio_celulares<-celulares_ancho %>% 
  mutate(
    cambio_abs=`2020` - `2005`,
    cambio_pct=(`2020` - `2005`) / `2005` *100
  )

cambio_celulares %>% 
  arrange(desc(cambio_pct)) %>% 
  slice(1)
#DURANGO ES EL ESTADO CON MÁS ADQUISICIÓN DE CELULARES 
#

# Ejercico 4 --------------------------------------------------------------
#¿En qué década se registra el mayor promedio de vehículos por 1000 habitantes? ¿De cuanto es este promedio para la década con el valor más alto?
#filtrar y limpiar los datos 
vehiculos<-indicadores_estatales %>% 
  filter(no==156,cve_ent=="00")

#Creación de decada
vehiculos<-vehiculos %>% 
  mutate(
    decada=floor(year/10)*10
  )
#floor redonde los decimales hacia abako en lugar de hacia arriba
#promedio y desviación estandar 
vehiculos_decada<-vehiculos %>% 
  group_by(decada) %>% 
  summarise(
    promedio=mean(valor,na.rm=TRUE),
    desv_est=sd(valor,na.rm = TRUE)
  )
vehiculos_decada

#ordenar de mayor a menor
vehiculos_decada %>% 
  arrange(desc(promedio)) %>% 
  slice(1)
#¿En qué década se registra el mayor promedio de vehículos por 1000 habitantes? ¿De cuanto es este promedio para la década con el valor más alto?
#en la decada de 2020 es la que registro un amyor promedio con un promedio de 420



# Ejercicio5 --------------------------------------------------------------
#filtrado de datos 

diabetes<-indicadores_estatales %>% 
  filter(no==36, cve_ent%in%c("07","21","27","19","26"))
#left join con todo 
diabetes<-diabetes %>% 
  left_join(cat_edos, by="cve_ent")
#creación de grafica

grafica_diabetes<-diabetes %>% 
  ggplot(aes(x=year, y=valor, color=entidad))+
  geom_line()+
  labs(
    title = "Mortalidad por diabetes en México",
    x="Año",
    y="Tasa por 100,000 habitantes"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size=13, face = "bold")
  )
grafica_diabetes

# Ejercicio 6 -------------------------------------------------------------

#Cuál fue el estado con la mayor satisfacción por la vida?

#filtración de datos 
satisfaccion<-indicadores_estatales %>% 
  filter(no==569) 
#exclusion de entidades 
satisfaccion<-satisfaccion %>% 
  filter(!cve_ent %in% c("00","33","34","99"))
satisfaccion
#juntar catalogos y juntar datos y filtrar de mayor a menor

satisfaccion<-satisfaccion %>% 
  group_by(cve_ent) %>% 
  filter(year==max(year)) %>% 
  ungroup() %>%
  arrange(desc(valor)) %>% #junta todo 
  left_join(cat_edos, by="cve_ent")
satisfaccion
#creacion de la grafica 
grafica_satisfaccion<-satisfaccion %>% 
  ggplot(aes(x=entidad, y=valor, fill=valor))+
  geom_col()+
  coord_flip()+ #cambia de vertical a horizontal la grafico
  scale_fill_gradient(low = "lightblue", high = "navy")+
  labs(
    title = "Satisfacción con la vida por estado en México",
    x="Estado",
    y="Nivel de Satisfacción"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size = 13, face="bold")
  )
grafica_satisfaccion

#Saber cual es el estado con mayor satisfacción en la vida
satisfaccion %>% 
  group_by(cve_ent) %>% 
  filter(year==max(year)) %>% 
  ungroup() %>% 
  arrange(desc(valor)) %>% 
  slice(1)
#El estado con mayor satisfacción con la vida es Chihuahua. 
#
#

# Ejercicio 7 -------------------------------------------------------------
#¿Qué relación observas entre desarrollo económico y fecundidad adolescente?

pib_fecundidad<- indicadores_estatales %>% 
  filter(no %in%c(1266,40), year==2020)
#exclusion de entidades 
pib_fecundidad<-pib_fecundidad %>% 
  filter(!cve_ent%in%c("00","33","34","99"))
pib_fecundidad
#juntar con catalogo 
pib_fecundidad<-pib_fecundidad %>% 
  left_join(cat_edos, by="cve_ent")
#juntar datos sin hacer otra tabla
pib_fecundidad<-pib_fecundidad %>%
  pivot_wider(names_from = no, values_from = valor)
pib_fecundidad

#creacion de la grafica
grafica_pib_fecundidad<-pib_fecundidad %>% 
  ggplot(aes(x=`1266`, y = `40`))+
  geom_point()+
  scale_x_continuous(labels = scales::comma)+ #cambia las labels de notacion cientifica ha numero entero
  labs(
    title = "PIB per capita vs Fecundiad en adolescentes en el año 2002",
    x="PIB per capita",
    y="Fecundiad adolescente"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size = 13, face = "bold")
  )
grafica_pib_fecundidad
#¿Qué relación observas entre desarrollo económico y fecundidad adolescente?
#Minetras menos Pib per capita hay mayor cantidad de fecundidad en adolescentes, de igual forma los estados con menor igreso muestran niveles más altos de feucndidad. 

# Ejercicio 8 -------------------------------------------------------------
#creación de grafica diabetes final con los datos de diabetes anteriores
grafica_diabetes_final<-diabetes %>% 
  ggplot(aes(x=year, y=valor, color=entidad))+
  geom_line(linewidth =1.5)+ #mi versión de r ya no acepta size en ggplot2 ahora es linewidth
  scale_color_manual(values = c(
    "Chiapas"="blue",
    "Tabasco"="green",
    "Puebla"="brown",
    "Nuevo León"="red",
    "Sonora"="purple"
  ))+
  scale_y_continuous(labels = scales::comma)+
  labs(
    title = "Evolución de la mortalidad por diabetes en México",
    subtitle = "Fuente: Indicadores socioeconómicos (INEGI/CONEVAL)",
    x="Año",
    y="Tasa por 100,000 habitantes",
    caption = "Elaborado por: María José Gómez Glz"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size = 13, face="bold"),
    plot.subtitle = element_text(size=10)
  )
grafica_diabetes_final


# Ejercicio 9 -------------------------------------------------------------
#filración de datos y asi #ya me canse #sos

lluvia<-indicadores_estatales %>% 
  filter(no==950, cve_ent%in%c("27","08","14","31","09","02"))
#juntar con catalogo de entidades
lluvia<-lluvia %>% 
  left_join(cat_edos, by="cve_ent")
lluvia

#Creacion de grafica

grafica_lluvia<-lluvia %>% 
  ggplot(aes(x=year, y=valor))+
  geom_line(color="darkblue")+
  geom_smooth(method = "lm", se=FALSE, color="red")+
  facet_wrap(~entidad, scales = "free_y")+
  labs(
    title = "Lluvia promedio anual por Estado",
    x="Año",
    y="Lluvia promedio"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size = 13, face="bold")
  )
grafica_lluvia


# Ejercicio 10 ------------------------------------------------------------

#¿Los estados más violentos son menos felices?

#filtrar y creacion de cada valor por separado
#homicidios

homicidios<-indicadores_estatales %>% 
  filter(no==173) %>% 
  rename(valor_homicidios=valor)
#satisfaccion con la vida

satisfaccionvi<-indicadores_estatales %>% 
  filter(no==569) %>% 
  rename(valor_satisfaccion=valor)

#unir las dos tablas 

violencia<-homicidios %>% 
  inner_join(satisfaccionvi,  by="cve_ent","year")
#filtrar el año en comun
violencia_2016<-violencia %>% 
  filter(year.x == 2016, year.y==2016, !cve_ent %in% c("00","33","34","99"))
violencia_2016
#aqui filtre el año de x y el año de y para q hagan match y lso dos sean 2016, originalemtne lo intentne con 2016, pero no habia datos en la aprte de satisfaccion del año 2006 solo aparecian a partir de 2010
#Creacion de grafica

grafica_violencia_satisfaccion<-violencia_2016 %>% 
  ggplot(aes(x=valor_homicidios, y=valor_satisfaccion))+
  geom_point()+
  labs(
    title = "Homicidios vs Satisfacción con la vida",
    x="Homicidios",
    y="Satisfacción con la vida"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size=13, face="bold")
  )
grafica_violencia_satisfaccion

#¿Los estados más violentos son menos felices? Describe en un comentario la relación que observas.
#En si, no se puede interpretar algo conciso, ya que hay estados con niveles altos de homicidio que muerstran niveles relativamene altos de satisfacción y lugares con una tasa baja pero con niveles variados de satsifacción




# Ejercicio 11 ------------------------------------------------------------

#saber los nombres de cada columna 
names(metadatos_estatales)

indicadores_salud<-indicadores_estatales %>% 
  left_join(metadatos_estatales, by="no")
#une los metadatos por el no o nombre de indicador
indicadores_salud<-indicadores_salud %>% 
  group_by(indicador,umedida) %>% #los agrupa por indicador
  summarise(n_registros =n()) #nos da la cantidad de registros 
indicadores_salud

# Ejercicio 12 -----------------------------------------------------------


#filtro de datos, aqui ya se hace por municipio y no por estado
names(indicadores_municipales)

fecundidad<-indicadores_municipales %>% 
  filter(`Clave de indicador`==138)
#filtrar monterrey
fecundidad_mty<-fecundidad %>% 
  filter(`Nombre de la metrópoli` %in% c("Monterrey"))
fecundidad_mty

#filtrar los municipios cada uno
fecundidad_mty<-fecundidad_mty %>% 
  filter(`Municipio` %in% c("Apodaca", "Cadereyta Jiménez", "El Carmen", "García",
                            "San Pedro Garza García", "General Escobedo", "Guadalupe",
                            "Juárez", "Monterrey", "Salinas Victoria",
                            "San Nicolás de los Garza", "Santa Catarina", "Santiago"))
fecundidad_mty

#generacióm del año más reciente

fecundidad_mty<-fecundidad_mty %>% 
  group_by(`Clave de municipio`) %>% 
  filter(Año==max(Año)) %>% 
  ungroup
fecundidad_mty

#generación de la gráfica

grafica_fecundidad_mty<-fecundidad_mty %>% 
  ggplot(aes(x=reorder(`Municipio`, Valor), y=Valor))+
  geom_col(fill="pink")+
  coord_flip()+
  labs(
    title = "Fecundidad adolescente en la zona metropolitatna de Monterrey",
    subtitle = "Año más reciente disponible --2019--.",
    x="Municipio",
    y="Fecundidad adolescente"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size =13, face="bold")
  )
grafica_fecundidad_mty


# Ejercicio 13 ------------------------------------------------------------
#filtración de datos
celulares_2<-indicadores_estatales %>% 
  filter(no==98, year%in%c(2000,2005,2010,2015,2020))
#eliminación de columnas

celulares_2<-celulares_2 %>% 
  filter(!cve_ent %in%c("00","33","34","99"))
celulares_2
#juntar con el catalgo de estados 

celulares_2<-celulares_2 %>% 
  left_join(cat_edos, by="cve_ent")
celulares
#se hizo lo mismo-o casi- que en un ejercicio anterior solo que esta vez se filtraron años en especifico
celulares_ancho_2<-celulares_2 %>% 
  select(cve_ent, entidad, year,valor) %>% 
  pivot_wider(names_from = year, values_from = valor)
celulares_ancho_2

# Ejercicio 14 ------------------------------------------------------------

#devolver de formato ancho a fomrato largo 

celulares_largo<-celulares_ancho_2 %>% 
  pivot_longer(cols=-c(cve_ent, entidad), names_to = "year", values_to = "valor")
celulares_largo

#convertir la columna de year a numerico 
celulares_largo<-celulares_largo %>% 
  mutate(year=as.numeric(year))
celulares_largo

# Ejercicio 15 ------------------------------------------------------------

#filtrar los indicadores y el estado escogido 

ags_ambiental<-indicadores_estatales %>% 
  filter(no %in% c(564,950,628), cve_ent=="01")
ags_ambiental

#unir con metadoatos para obtener el nombre del indicador 
ags_ambiental<-ags_ambiental %>% 
  left_join(metadatos_estatales, by="no")
ags_ambiental

#creación de la gráfica

grafica_ambiental<-ags_ambiental %>% 
  ggplot(aes(x=year, y=valor))+
  geom_line(color="#8B3A62")+
  facet_wrap(~indicador, scales = "free_y")+
  labs(
    title = "Indicadores ambientales en Aguascalientes",
    subtitle = "Resuidos sólidos, lluvia promedio e incendios forestales",
    x="Año",
    y="Valor"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size=13, face="bold"),
    plot.subtitle = element_text(size = 11)
  )
grafica_ambiental  
  
  
  
  
  
  

# Ejercicio 16 ------------------------------------------------------------

#mis datos
#Base de datos obtenida de Kaggle, los datos son de World Athletics
track<-world_athletics %>% 
  clean_names()
#transformación de datos
track<-track %>% 
  mutate(date=parse_date_time(date, orders = c("ymd", "dmy", "mdy", "b,d,Y")),
         mark_seg=as.numeric(mark_meters_or_seconds))
#obtener nombre exacto de los eventos a comprar
unique(track$event)

eventos<-track %>% 
  filter(sex=="female", event%in%c("400 Metres", "400 Metres Hurdles"))
eventos

grafica_eventos<-eventos %>% 
  ggplot(aes(x=date, y=mark_seg, color=event))+
  geom_line(linewidth = 1.5)+
  geom_point(alpha=0.6)+
  labs(
    title = "Evolución de marcas en 400m y 400m con vallas rama femenil",
    subtitle = "Comparacion del rendimiento en pruebas de velocidad",
    x="Año",
    y="Tiempo (segundos)",
    color="Prueba",
    caption = "Fuente: Base de datos obtenidad de World Athletics en Kaggle "
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size=13, face="bold"),
    plot.subtitle = element_text(size = 11),
    plot.tag.position = "right"
  )
grafica_eventos

#ahora quiero ver el top 5 de atletas en ambas pruebas en los ultimos 20 años 
top_5_atle<-track %>% 
  filter(sex=="female", event%in%c("400 Metres", "400 Metres Hurdles"),
         date >= today()-years(10))
#ordenar del menor 
top_5_atle<-top_5_atle %>% 
  arrange(mark_seg)
#obtener el top 5
top_5_atle<-top_5_atle %>% 
  select(competitor, event, nat, date, mark_seg) %>% 
  slice(1:5)
top_5_atle

grafica_top_5<-top_5_atle %>% 
  ggplot(aes(x=reorder(competitor,mark_seg), y=mark_seg))+
  geom_col()+
  coord_flip()+
  labs(
    title = "Top 3 atletas femeniles en 400m planos",
    x="Atleta",
    y="Mejor tiempo(Segundos)"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size = 13, face="bold")
  )
grafica_top_5

#mejores tiempos de 400 metros con vallas

vallas<-track %>% 
  filter(sex=="female", event=="400 Metres Hurdles")
vallas<-vallas %>% 
  arrange(mark_seg)

top_5_vallas<-vallas %>% 
  group_by(competitor) %>% 
  summarise(mejor_tiempo =min(mark_seg, na.rm = TRUE), .groups = "drop") %>% #evita que se junten los tiempos de una misma atleta como lo sería sydney
  arrange(mejor_tiempo) %>% 
  slice(1:5)
top_5_vallas

top_5_vallas_grafica<-top_5_vallas %>% 
  ggplot(aes(x=reorder(competitor, mejor_tiempo), y=mejor_tiempo))+
  geom_col(fill="#943922")+
  coord_flip()+
  labs(
    title = "Top 5 mejores tiempos en 400m con vallas femenil",
    x="Atleta",
    y="Tiempo en segundos"
  )+
  theme_minimal()+
  theme(
    plot.title = element_text(size=13, face="bold")
  )
top_5_vallas_grafica

