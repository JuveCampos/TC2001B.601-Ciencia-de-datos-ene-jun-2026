library(tidyverse)
library(readr)
library(ggplot2)
library(readxl)

#carga de datos
indicae <- read_csv("datos_problemario/indicadores_estatales.csv")
indicam <- read.csv("datos_problemario/indicadores_municipales.csv")
estados <- read_csv("datos_problemario/cat_edos.csv")
municipios <- read_csv("datos_problemario/cat_mun.csv")
estados_meta <- read_csv("datos_problemario/metadatos_estatales.csv")
municipios_meta <- read_csv("datos_problemario/metadatos_municipales.csv")
municipios <- read_csv("datos_problemario/cat_mun.csv")

indicae_conestados <- left_join(indicae, estados, by = c("cve_ent" = "cve_ent")) %>% 
  select(-c(entidad_abr_m, cve_ent,))

options(scipen = 999)

#EJERCICIO 1 -----------------------------------------------------------------------------------------------------------------------------------------------

indicae_22 <- indicae %>% 
  filter(year == 2022, no == 921) %>%  #Filtra el indicador de pobreza para el año 2022, Indicador: % población en pobreza (no = 921)
  filter(!cve_ent %in% c("00","99","33","34")) %>% #incluyendo solo las 32 entidades federativas (excluye cve_ent “00”, “33”, “34” y “99”). 
  select("cve_ent","valor") #Selecciona las columnas cve_ent y valor. Une con cat_edos para obtener los nombres de los estados.

indicadores_22 <- left_join(indicae_22, estados, by = c("cve_ent" = "cve_ent")) %>% 
  select(-c(entidad_abr_m, cve_ent,))

pobreza_2022 <- indicadores_22 %>% #Variable resultado: pobreza_2022
  rename(pobreza = valor) %>% 
  arrange(-pobreza) %>% 
  head(3) 

#pregunta: ¿Cuáles son los 3 estados con mayor pobreza en 2022?
#RESPUESTA: LOS 3 ESTADOS CON MAYOR NIVEL DE POBREZA EN 2022 SON CHIAPAS, GUERRERO Y OAXACA


#EJERCICIO 2 -----------------------------------------------------------------------------------------------------------------------------------------------

indicae_20 <- indicae %>% 
  filter(year == 2020, no == 54) %>%   #Indicador: Esperanza de vida al nacer (no = 54)
  filter(!cve_ent %in% c("00","99","33","34")) %>% #Excluir cve_ent “00”, “33”, “34” y “99”. Unir con cat_edos para nombres. 
  select("cve_ent","valor") #Selecciona las columnas cve_ent y valor. Une con cat_edos para obtener los nombres de los estados.

indicadores_20 <- left_join(indicae_20, estados, by = c("cve_ent" = "cve_ent")) %>% 
  select(-c(entidad_abr_m, cve_ent,))

top_5_ev <- indicadores_20 %>% 
  rename(esperanza_vida=valor) %>% 
  arrange(-esperanza_vida) %>% #Obtener el top 5 y bottom 5 de estados por esperanza de vida en 2020.
  slice_head(n = 5)


bottom_5_ev <- indicadores_20 %>% 
  rename(esperanza_vida=valor) %>% 
  arrange(-esperanza_vida) %>% #Obtener el top 5 y bottom 5 de estados por esperanza de vida en 2020.
  slice_tail(n = 5)


diferencia_ev <- max(top_5_ev$esperanza_vida) - min(bottom_5_ev$esperanza_vida) 

#¿Cuántos años de diferencia hay entre el estado con mayor y menor esperanza de vida?
#RESPUESTA: HAY 7.33 AÑOS DE DIFERENCIA ENTRE BAJA CALIFORNIA SUR Y TLAXCALA, ESTADOS CON MAYOR Y MENOR ESPERANZA DE VIDA, RESPECTIVAMENTE


#EJERCICIO 3 -----------------------------------------------------------------------------------------------------------------------------------------------


indicae_98 <- indicae %>% 
  filter(year == 2020|year == 2005, no == 98) %>%   #Filtrar los años 2005 y 2020 para las 32 entidades. Indicador: Suscripciones celulares por 100 hab (no = 98)
  filter(!cve_ent %in% c("00","99","33","34")) %>% #Excluir cve_ent “00”, “33”, “34” y “99”. Unir con cat_edos para nombres. 
  select("cve_ent","valor","year") %>% #Selecciona las columnas cve_ent y valor.
  rename(suscripciones=valor) 

cambio_celulares <- left_join(indicae_98, estados, by = c("cve_ent" = "cve_ent")) %>% #Variable resultado: cambio_celulares (columnas: cve_ent, entidad, valor_2005, valor_2020, cambio_abs, cambio_pct)
  select(-c(entidad_abr_m, cve_ent,)) %>% #Une con cat_edos para obtener los nombres de los estados.
  pivot_wider(names_from = "year",
              names_prefix = "valor_",
              values_from = "suscripciones") %>% # Pista: Necesitarás pivot_wider para poner 2005 y 2020 en columnas separadas, 
  mutate(cambio_abs = valor_2020 - valor_2005) %>%  #luego mutate() para calcular cambio_abs y cambio_pct.
  mutate(cambio_pct = ((valor_2020 - valor_2005)/valor_2005) * 100) %>% # Calcular el cambio absoluto y el cambio porcentual por estado entre esos dos años.
  arrange(-cambio_pct)


#Pregunta: ¿Qué estado tuvo el mayor crecimiento porcentual en adopción de celulares?
#RESPUESTA: EL ESTADO DE DURANGO con un cambio de 390.1552%


#EJERCICIO 4 -----------------------------------------------------------------------------------------------------------------------------------------------


indicae_156 <- indicae %>% #Indicador: Vehículos por 1,000 hab (no = 156)
  filter(no == 156) %>%   
  filter(cve_ent %in% c("00")) %>% 
  select("cve_ent","valor","year") %>% 
  rename(vehiculos=valor) #Para el nivel nacional (cve_ent == "00"), crear una columna de década con mutate, luego calcular el promedio y la desviación estándar de vehículos  por década.

vehiculos_decada <- left_join(indicae_156, estados, by = c("cve_ent" = "cve_ent")) %>% #Variable resultado: vehiculos_decada (columnas: decada, promedio, desv_est) 
  select(-c(entidad_abr_m, cve_ent,)) %>% #Une con cat_edos para obtener los nombres de los estados.
  mutate(decada = floor(year / 10) * 10) %>%  # Pista: Usa mutate(decada = floor(year / 10) * 10) para crear la columna de década.
  group_by(decada) %>% 
  summarise(mean(vehiculos), sd(vehiculos)) %>% 
  rename(promedio = "mean(vehiculos)") %>% 
  rename(desv_est = "sd(vehiculos)") %>% 
  arrange(-promedio)

#Pregunta: ¿En qué década se registra el mayor promedio de vehículos por 1000 habitantes?
#RESPUESTA: EN LA DÉCADA DE 2020, registrándose 420.1121 vehículos por cada 1000 habitantes


#EJERCICIO 5 -----------------------------------------------------------------------------------------------------------------------------------------------


indicae_36 <- indicae %>% #Indicador: Mortalidad por diabetes por 100k (no = 36)
  filter(no == 156) %>% 
  filter(cve_ent %in% c("07","19","21","26","27")) %>% #Grafica la mortalidad por diabetes de 2000 a 2023 para cinco estados: Chiapas, Tabasco, Puebla, Nuevo León y Sonora. 
  select("cve_ent","valor","year") %>% 
  rename(mort_diab=valor)

mortalidad_diabetes <- left_join(indicae_36, estados, by = c("cve_ent" = "cve_ent")) %>% 
  select(-c(entidad_abr_m, cve_ent,)) #Pista: Filtra primero, une con cat_edos,

grafica_diabetes <- ggplot(mortalidad_diabetes, #Guardar como: grafica_diabetes
                           aes(x = year, y = mort_diab, color = entidad)) +
  geom_line(linewidth = 1) + #Usa líneas de colores, luego usa ggplot + geom_line con color = entidad.
  labs(                      # agrega labs() con título y etiquetas de ejes,
    title = "Mortalidad por diabetes por cada 100 mil habitantes",
    x = "Año",
    y = "Mortalidad"
  ) +
  theme_update()            #y aplica un tema limpio.


#EJERCICIO 6 -----------------------------------------------------------------------------------------------------------------------------------------------


indicae_569 <- indicae %>%  #Indicador: Satisfacción con la vida (no = 569)
  filter(year == 2024, no == 569) %>% 
  filter(!cve_ent %in% c("00","99","33","34")) %>% #Excluir “00”, “33”, “34”, “99”.
  select("cve_ent","valor","year") %>% 
  rename(satisfaccion=valor)

satisfaccion_vida <- left_join(indicae_569, estados, by = c("cve_ent" = "cve_ent")) %>% 
  select(-c(entidad_abr_m, cve_ent,))

grafica_satisfaccion <- ggplot(satisfaccion_vida, #Guardar como: grafica_satisfaccion
                               aes(x = reorder(entidad, satisfaccion), y = satisfaccion, fill = satisfaccion)) +  #Pista: Usa reorder() dentro de aes() para ordenar las barras,
  geom_col() +   #Barras horizontales de satisfacción con la vida por estado en 2025, ordenadas de mayor a menor.
  coord_flip()+  #y coord_flip() para hacerlas horizontales.
  scale_fill_gradient() #Colorear las barras por valor usando scale_fill_gradient().


#EJERCICIO 7 -----------------------------------------------------------------------------------------------------------------------------------------------

indicae_1266 <- indicae %>%  #Indicador: PIB per cápita (no = 1266)
  filter(year == 2020, no == 1266) %>% 
  filter(!cve_ent %in% c("00","99","33","34")) %>% #Excluir “00”, “33”, “34”, “99”.
  select("cve_ent","valor","year") %>% 
  rename(PIBpercap=valor)
nv_indicae1266 <- left_join(indicae_1266, estados, by = c("cve_ent" = "cve_ent")) %>% 
  select(-c(entidad_abr_m, cve_ent,))
  
  
  
  indicae_40 <- indicae %>%  #Indicador: Fecundidad adolescente (no = 40)
  filter(year == 2020, no == 40) %>% 
  filter(!cve_ent %in% c("00","99","33","34")) %>% #Excluir “00”, “33”, “34”, “99”.
  select("cve_ent","valor","year") %>% 
  rename(Fecun_adol=valor)
nv_indicae40 <- left_join(indicae_40, estados, by = c("cve_ent" = "cve_ent")) %>% 
  select(-c(entidad_abr_m, cve_ent, year))

datos_pibfec <- inner_join(nv_indicae1266, nv_indicae40, by="entidad")

top_3_pib <- nv_indicae1266 %>% 
  arrange(-PIBpercap) %>% #Obtener el top 3 de PIB per cápita.
  filter(!year) %>% 
  slice_head(n = 3)
  
  
top_3_fecad <- nv_indicae40 %>% 
  arrange(-Fecun_adol) %>% #Obtener el top 3 de fecundidad adolescente.
  slice_head(n = 3)
  
  etiquetas <- rbind(top_3_pib, top_3_fecad) #Etiquetar los 3 estados con mayor PIB y los 3 con mayor fecundidad adolescente.

grafica_pib_fecundidad <- ggplot(datos_pibfec, #Guardar como: grafica_satisfaccion
                                 aes(x = PIBpercap, y = Fecun_adol, color = entidad)) +  
  geom_point()+ #Scatter plot por estado en 2020 (o año cercano disponible).
  labs(title = "Fecundidad adolescente y PIB per cápita por Estado", #Eje X = PIB per cápita, eje Y = fecundidad adolescente.
       x = "PIB per cápita",
       y = "Fecundidad adolescente")

#Pregunta: ¿Qué relación observas entre desarrollo económico y fecundidad adolescente?
#RESPUESTA: PODEMOS OBSERVAR QUE ENTRE MENOR PIB PER CÁPITA SE GENERA POR ESTADO, EXISTE UNA MAYOR TASA DE FECUNDIDAD ADOLESCENTE. SIN EMBARGO,
#GRAN PARTE DE LOS ESTADOS DEL PAÍS SE ENCUENTRA EN BAJOS NIVELES DE PIB PER CÁPITA

#EJERCICIO 8 -----------------------------------------------------------------------------------------------------------------------------------------------

#Guardar como: grafica_diabetes_final

grafica_diabetes_final <- ggplot(mortalidad_diabetes)+  #Indicador: Mortalidad por diabetes (no = 36) 
  aes(x = year, y = mort_diab, color = entidad) +
  geom_line(linewidth = 1)+
  scale_color_manual(values = c("violetred", "thistle3", "wheat", "turquoise3","seagreen4"))+
  theme_minimal()+ #Toma la gráfica del ejercicio 5 (grafica_diabetes) y mejórala con: theme_minimal(), 
  labs(title = "Mortalidad por diabetes por cada 100 mil habitantes", #título informativo, subtítulo con la fuente de datos (consulta metadatos),
       subtitle = "FUENTE: SALUD.  Base de datos del Subsistema de Información sobre Nacimientos.\nSALUD. Bases de datos de mortalidad.\nhttp://www.beta.inegi.org.mx/proyectos/registros/vitales/mortalidad/default.html",
       caption = "Garcés Camacho José Francisco", # caption con tu nombre, escala de colores manual con scale_color_manual(),
       x = "Año",
       y = "Índice de mortalidad")+
  scale_y_continuous() #y ajuste de ejes con scale_y_continuous().

#EJERCICIO 9 -----------------------------------------------------------------------------------------------------------------------------------------------

indicae_950 <- indicae %>% #Indicador: Lluvia promedio por entidad (no = 950)
  filter(no == 950, year %in% 2002:2024) %>% 
  filter(cve_ent %in% c("02","08","14","27","31")) %>% #Grafica la lluvia promedio anual de 2002–2024 para 6 estados de diferentes regiones: Tabasco, Chihuahua, Jalisco, Yucatán, Ciudad de México, Baja California. 
  select("cve_ent","valor","year") %>% 
  rename(lluvia_prom=valor)

lluvias_promedio <- left_join(indicae_950, estados, by = c("cve_ent" = "cve_ent")) %>% 
  select(-c(entidad_abr_m, cve_ent,)) #Filtra primero, une con cat_edos,

grafica_lluvia <- ggplot(lluvias_promedio, #Guardar como: grafica_lluvia
                         aes(x = year, y = lluvia_prom, color = entidad)) +
  geom_line(linewidth = 1) +
  scale_color_brewer(palette ="Set2") +
  facet_wrap(~entidad, ncol = 3, scales = "free") + # Un panel por estado con facet_wrap(~entidad). permite que cada panel tenga su propia escala.
  labs(                      # agrega labs() con título y etiquetas de ejes,
    title = "Lluvias promedio anual en seis regiones del país",
    subtitle = "Datos de 2002 a 2024",
    x = "Año",
    y = "Lluvia promedio anual"
  ) +
  geom_smooth(method = "lm") + #Agrega geom_smooth(method = "lm") para ver la tendencia.
  theme_minimal(base_size = 10) +
  theme(
    axis.text.x = element_text(angle = 90) 
  )


#EJERCICIO 10 -----------------------------------------------------------------------------------------------------------------------------------------------



indicae_628 <- indicae %>% #Indicador: Incendios forestales (no = 628)
  filter(no == 628, year == 2020) %>% 
  filter(!cve_ent %in% c("00","33","34","99")) %>% 
  select("cve_ent","valor","year")  #Unir la base estatal filtrada (indicador de incendios forestales, año 2020) con el catálogo de estados.


incendios_2020 <- left_join(indicae_628, estados, by = c("cve_ent" = "cve_ent")) %>% # left_join(datos, catalogo, by = "cve_ent") y luego select() para quitar la columna de clave.
  select(-c(cve_ent,year))  #Presentar tabla con nombre de entidad, abreviatura y valor, sin la clave numérica.
#Variable resultado: incendios_2020 (columnas: entidad, entidad_abr_m, valor)



#EJERCICIO 11 -----------------------------------------------------------------------------------------------------------------------------------------------


indicae_173 <- indicae %>% #Indicador:  Homicidios (no = 173)
  filter(no == 173) %>%
  filter(!cve_ent %in% c("00","33","34","99")) %>%
  select("cve_ent","valor","year") %>%   #Unir la base estatal filtrada (indicador de incendios forestales, año 2020) con el catálogo de estados.
  rename(valor_homicidios=valor)

indicae_569II <- indicae %>%  #Indicador: Satisfacción con la vida (no = 569)
  filter(no == 569) %>%
  filter(!cve_ent %in% c("00","99","33","34")) %>% #Excluir “00”, “33”, “34”, “99”.
  select("cve_ent","valor","year") %>%
  rename(valor_satisfaccion=valor) #Pista: Filtra cada indicador por separado, renombra la columna valor (ej: valor_homicidios, valor_satisfaccion)

viosat_plot <- inner_join(indicae_173, indicae_569II, by = c("cve_ent","year"))  #Combina ambos indicadores por cve_ent y year. Y luego inner_join() por c("cve_ent", "year").

viosat_2020 <- viosat_plot %>% 
  filter(year == 2023)

# Haz un scatter plot para un año en común: eje X = homicidios, eje Y = satisfacción.

grafica_violencia_satisfaccion <- ggplot(viosat_2020, #Guardar como: grafica_violencia_satisfaccion
                                         aes(x = valor_homicidios, y = valor_satisfaccion, color = cve_ent)) +  
  geom_point()+
  labs(title = "Relación entre satisfacción por la vida y la violencia",
       subtitle = "Año 2020",
       x = "Satistacción",
       y = "Homicidios por cada 100 mil habitantes")+
  theme_minimal()

#Pregunta: ¿Los estados más violentos son menos felices? 
#SI BIEN LA RELACIÓN OBSERVADA NO NOS PERMITE ASEGURARLO, SÍ SE APRECIA UNA TENDENCIA DE LOS ESTADOS CON
#MENOR SATISFACCIÓN A PRESENTAR MAYORES HOMICIDIOS POR CADA 100 MIL HABITANTES


#EJERCICIO 12 ---------------------------------------------------------------------------------------


indicadores_salud <- indicae %>% #Indicadores: Todos los estatales + metadatos. Variable resultado: indicadores_salud (columnas: indicador, umedida, n_registros)
  inner_join(estados_meta) %>%  #Unir la base estatal con los metadatos (por columna no) para obtener nombre del indicador, unidad de medida y clasificación. 
  filter(str_starts(clasificacion, "1\\.")) %>% ##Filtrar todos los indicadores cuya clasificación empiece con “1.” (Demográfico y social). Usa str_starts() o grepl() para filtrar por clasificación. 
  group_by(indicador, umedida) %>%
  summarise(n_registros = n(), .groups = "drop")

print(indicadores_salud) #Mostrar tabla resumen con: nombre del indicador, unidad de medida y número de registros.


#EJERCICIO 13 -----------------------------------------------------------------------------------------------------------------------------------------------



#Pista: La clave de municipio en la base municipal es Clave de municipio y en el catálogo es cvegeo. Cuidado con los nombres de columnas con espacios: usa backticks.
#Guardar como: grafica_fecundidad_mty


grafica_fecundidad_mty <- indicam %>% 
  mutate(`Clave.de.municipio` = as.character(`Clave.de.municipio`)) %>% 
  inner_join(municipios, by = c("Clave.de.municipio" = "cvegeo")) %>% #Unir la base municipal de fecundidad adolescente con el catálogo de municipios. Graficar barras por municipio para el año más reciente disponible.
  filter(Clave.de.indicador == 138) %>% #Indicador municipal: Fecundidad adolescente (clave 138)
  filter(Nombre.de.la.metrópoli == "Monterrey" | Municipio %in% c(
    "Monterrey", "Guadalupe", "Apodaca", "San Nicolás de los Garza", 
    "Santa Catarina", "San Pedro Garza García", "General Escobedo", 
    "Juárez", "García", "Cadereyta Jiménez", "Santiago" #Filtrar la Zona Metropolitana de Monterrey. 
  )) %>%
 
  filter(Año == max(Año)) %>%

  ggplot(aes(x = reorder(Municipio, Valor), y = Valor, fill = Valor)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Fecundidad Adolescente en la Zona Metropolitana de Monterrey",
    x = "Municipio",
    y = "Tasa de fecundidad",
    fill = "Tasa"
  ) +
  theme_minimal()

#EJERCICIO 14 -----------------------------------------------------------------------------------------------------------------------------------------------


indicae_98II <- indicae %>%  #Indicador: Suscripciones celulares (no = 98)
  filter(year %in% c(2000, 2005, 2010, 2015, 2020), no == 98) %>%   
  filter(!cve_ent %in% c("00","99","33","34")) %>% #Excluir cve_ent “00”, “33”, “34” y “99”. Unir con cat_edos para nombres. 
  select("cve_ent","valor","year") %>% #Selecciona las columnas cve_ent y valor.
  rename(suscripciones=valor)  

indicadores_cel5 <- left_join(indicae_98II, estados, by = c("cve_ent" = "cve_ent")) %>% 
  select(-c(entidad_abr_m, cve_ent,))

celulares_ancho <- indicadores_cel5 %>% #Variable resultado: celulares_ancho
  pivot_wider(names_from = year, values_from = suscripciones) #Crear tabla ancha donde filas = estados y columnas = años (2000, 2005, 2010, 2015, 2020).

#EJERCICIO 15 -----------------------------------------------------------------------------------------------------------------------------------------------

celulares_largo <- celulares_ancho %>% #Datos: Resultado del ejercicio 14 Variable resultado: celulares_largo

  pivot_longer( #Transforma la tabla ancha del ejercicio anterior de vuelta a formato largo. 
    cols = -c( entidad), 
    names_to = "year", 
    values_to = "suscripciones"
  ) %>%
  mutate(year = as.numeric(year)) # Recuerda convertir year a numérico con mutate().

dim(indicadores_cel5)
dim(celulares_largo) #Verifica que tenga las mismas dimensiones que los datos originales filtrados.

#EJERCICIO 16 -----------------------------------------------------------------------------------------------------------------------------------------------



# Primero filtra cada indicador para tu estado. 
NAYresiduos <- indicae %>% filter(no == 564, cve_ent == "18") #Indicadores: Residuos sólidos (no = 564), 
NAYlluvia   <- indicae %>% filter(no == 950, cve_ent == "18") #Lluvia promedio (no = 950), 
NAYincendios <- indicae %>% filter(no == 628, cve_ent == "18") #Incendios forestales (no = 628)


grafica_ambiental <- bind_rows(NAYresiduos, NAYlluvia, NAYincendios) %>% #Para UN estado a tu elección, combina los 3 indicadores ambientales. Usa bind_rows() para unirlos. #Guardar como: grafica_ambiental
  left_join(estados_meta, by = "no") %>% #Une con metadatos para obtener el nombre del indicador.
  
ggplot(aes(x = year, y = valor, color = indicador)) +
  geom_line(size = 1) +
  geom_point() +
  facet_wrap(~indicador, scales = "free_y", ncol = 1) +  # Grafica con facet_wrap(~indicador, scales = "free_y") las 3 tendencias temporales. "free_y" es clave porque las unidades son diferentes.
  theme_minimal() +
  labs(
    title = "Indicadores Ambientales en Nayarit",
    subtitle = "Tendencias de Residuos, Lluvia e Incendios)",
    x = "Año",
    y = "Valores",
    color = "Indicador"
  ) +
  theme(legend.position = "none") 


#EJERCICIO 17 -----------------------------------------------------------------------------------------------------------------------------------------------

grafica_fecundidad_tipo <- indicam %>% #Indicador municipal: Fecundidad adolescente (clave 138) Guardar como: grafica_fecundidad_tipo
  filter(Clave.de.indicador == 138) %>%
  filter(Año == max(Año)) %>% #	Filtra el indicador de fecundidad adolescente para el año más reciente.
  mutate(`Clave.de.municipio` = as.character(`Clave.de.municipio`)) %>% #Crear columnad con claves de municipio y homologar como character
  inner_join(municipios, by = c("Clave.de.municipio" = "cvegeo")) %>% #Une con catálogo de municipios.
  group_by(`Tipo.de.metrópoli`) %>% #Agrupa por Tipo de metrópoli y calcula media y mediana.
  mutate(
    media_tipo = mean(Valor, na.rm = TRUE),
    mediana_tipo = median(Valor, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  ggplot(aes(x = reorder(`Tipo.de.metrópoli`, Valor, FUN = median), y = Valor, fill = `Tipo.de.metrópoli`)) + #4.	Grafica boxplot por tipo de metrópoli.
  geom_boxplot(outlier.alpha = 0.5) +
  theme_minimal() +
  labs(
    title = "Fecundidad Adolescente por Tipo de Metrópoli",
    subtitle = "Año 2024",
    x = "Tipo de Metrópoli",
    y = "Tasa de Fecundidad"
  ) +
  theme(legend.position = "none")

#Pregunta: ¿Qué tipo de metrópoli tiene mayores tasas de fecundidad adolescente? ¿Por qué crees que es así?
#RESPUESTA: EN LOS RESULTADOS QUE OBTUVE, SE MENCIONAN ZONAS QUE NO SE CONSIDERAN ZONAS METROPOLITANAS Y LAS CONURBADAS 
#COMO PUNTOS DE MAYOR FECUNDIDAD ADOLESCENTE, CREO QUE ESTO PUEDE DEBERSE A LAS LIMITANTES EN EL ACCESO A SALUD Y
#EDUCACIÓN SEXUAL Y REPRODUCTIVA EN ESOS PUNTOS DE LA REPÚBLICA

