# Actividad M1.1: Fundamentos programación----
#Luis Ramón M.T

#Librerias 
library(tidyverse)
library(ggplot2)
library(scales)

#Sección 1: Verbos de tidyverse----
#Ejercicio 1----
#Cargando archivos :) 

indicadores_estatales <- read_csv ("datos_problemario/indicadores_estatales.csv")
cat_edos <- read_csv ("datos_problemario/cat_edos.csv")
cat_mun <- read_csv ("datos_problemario/cat_mun.csv")
indicadores_municipales <- read_csv ("datos_problemario/indicadores_municipales.csv")
metadatos_estatales <- read.csv("datos_problemario/metadatos_estatales.csv")
metadatos_municipales <- read_csv("datos_problemario/metadatos_municipales.csv")

#Filtración de datos 

pobreza_2022 <- indicadores_estatales %>%
  filter(no == 921) %>%
  filter(year == 2022) %>%
  filter(!cve_ent %in% c("00","33", "34", "39", "99")) %>%
  select(cve_ent, valor) %>%
  left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent")

# Estados con mayor pobreza Top 3

top_3_pobreza <- pobreza_2022 %>%
  arrange(desc(valor)) %>% #arrange para ordenar de mayor a menor
  slice(1:3)

top_3_pobreza

#Respuestas: Chiapas, Guerrero, Oaxa 


#Ejercicio 2----

esperanza_vida_2020 <- indicadores_estatales %>%
  filter(no ==54) %>%
  filter(year == 2020) %>%
  filter(!cve_ent %in% c("00","33", "34", "39", "99")) %>%
  select(cve_ent, valor) 

#Estados con mayor Esperanza de vida Top 5

tabla_esperanza <- left_join(esperanza_vida_2020, cat_edos, by = "cve_ent") %>%
  select(!c(entidad_abr_m)) %>%
  select(cve_ent, entidad, valor) %>%
  rename(esperanza_vida = valor) %>%
  rename(clave_entendidad = cve_ent)

top_5_ev <- tabla_esperanza %>%
  arrange(- esperanza_vida) %>%
  head(5)

bottom_5_ev <- tabla_esperanza %>%
  arrange(esperanza_vida) %>%
  head(5)

#Respuesta: 7.3 (calculo de manera manual)


#Ejercicio 3----

#Filtración de los años 2005 y 2020 para las 32 entidades

s_celulares <- indicadores_estatales %>%
  filter(no ==98) %>%
  # filter(year %in% c(2005, 2020)) %>%
  filter(year == 2005 | year == 2020) %>% 
  filter(!cve_ent %in% c("00", "33", "34", "39")) %>%
  select(c(cve_ent, year, valor))

tabla_cambio_celulares <- left_join(s_celulares, cat_edos, by = "cve_ent") %>%
  select(!c(entidad_abr_m)) %>%
  select(cve_ent, entidad, year, valor) %>%
  rename( s_cienhabitantes = valor) %>%
  rename( clave_entidad = cve_ent) %>%
  pivot_wider(id_cols = "entidad", 
              names_from = "year",
              values_from = "s_cienhabitantes") %>%
  mutate(Diferencia = `2020`-`2005`,
         c_porcentual = ((Diferencia/`2005`)*100)) %>%
  arrange(-c_porcentual) %>%
  head(10)

#Respuesta: Durango

#Ejercicio 4----

vehiculos_decada <- indicadores_estatales %>%
  filter(no == 156,
    cve_ent == "00") %>%
  mutate(decada = paste0(floor(year / 10) * 10, "s")) %>%
  group_by(decada) %>%
  summarise(
    promedio = mean(valor, na.rm = TRUE),
    desv_est = sd(valor, na.rm = TRUE),
    .groups = "drop") %>%
  arrange(decada)
  
#Respuesta:La década con el promedio más alto de vehículos por 1000 habitantes es la de los 2020s, con un promedio de 420.11.
  
#Seccion 2: Gráficas ggplot2----
#Ejercicio 5----

#Filtración de datos

diabetes <- indicadores_estatales %>%
  filter( no == 36, 
          year %in% 2002:2024,
    !cve_ent %in% c("00", "33", "34", "99")) %>%
  select(cve_ent, year, valor) %>%
  left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent") %>%
  filter(entidad %in% c("Chiapas", "Tabasco", "Puebla", "Nuevo León", "Sonora"))
  
  #Gráfica :) 

grafica_diabetes <- ggplot(diabetes, aes(x = year, y = valor, color = entidad)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Mortalidad por diabetes por 100 mil habitantes (2000-2023)",
    x = "Año",
    y = "Tasa de mortalidad",
    color = "Estado:") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
    legend.position = "bottom") #modificación propia

grafica_diabetes
 
#Ejercicio 6----
 
satisfaccion <- indicadores_estatales %>%
  filter( no == 569,
    year == 2024,
    !cve_ent %in% c("00", "33", "34", "99")) %>%
  select(cve_ent, valor) %>%
  left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent")
 
 #Gráfica :)
 
grafica_satisfaccion <- ggplot(
  satisfaccion,
  aes(x = reorder(entidad, valor), y = valor, fill = valor)) +
  geom_col() +
  coord_flip() +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(
    title = "Satisfacción con la vida por estado en 2024",
    x = "Estado",
    y = "Satisfacción con la vida",
    fill = "Valor") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"))

grafica_satisfaccion

 #Respuesta: Chihuahua es el estado con la mayor satisfaccion por la vida.
 
#Ejercicio 7----
 
 pib_2020_1 <- indicadores_estatales %>% 
   filter(no == 1266) %>%
   filter(year == 2020) %>%
   filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
   select(cve_ent, valor) %>%
   rename(pib_per_capita = valor)
 
 fecundidad_2020_1 <- indicadores_estatales %>%
   filter(no == 40) %>%
   filter(year == 2020) %>%
   filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
   select(cve_ent, valor) %>%
   rename(fecundidad_adolescente = valor)
 
 #Unimos indicadores
 
 pib_fecundidad <- pib_2020_1 %>%
   inner_join(fecundidad_2020_1, by = "cve_ent") %>%
   left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent")

  
#Gráfica :)
 
 options(scipen = 999) #Quitamos notación cientifica 
 
 grafica_pib_fecundidad <- pib_fecundidad %>%
   ggplot(aes(x = pib_per_capita, y = fecundidad_adolescente)) +
   geom_point(size = 3, alpha = 0.8) +
   labs(title = "PIB per cápita y fecundidad adolescente por estado, 2020",
        x = "PIB per cápita",
        y = "Fecundidad adolescente") +
   theme_minimal() +
   theme(plot.title = element_text(hjust = 0.5, face = "bold"))
 
  grafica_pib_fecundidad 
  
  #Respuesta:La relación que puedo observar se puede decir que es inversa, ya que cuando un estado tiene un PIB per cápita más alto, la fecundidad adolescente tiende a ser más baja. En otras palabras,los estados con mayor desarrollo económico suelen presentar menores niveles de fecundidad adolescente.
  
#Ejercicio 8----
  
  diabetes <- indicadores_estatales %>%
    filter(no == 36,
           year %in% 2000:2023,
      !cve_ent %in% c("00", "33", "34", "99")) %>%
    select(cve_ent, year, valor) %>%
    left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent") %>%
    filter(entidad %in% c("Chiapas", "Tabasco", "Puebla", "Nuevo León", "Sonora"))
  
  #Gráfica :)
  
  grafica_diabetes_final <- ggplot(diabetes, aes(x = year, y = valor, color = entidad)) +
    geom_line(linewidth = 1.1) +
    labs(
      title = "Mortalidad por diabetes por cada 100 mil habitantes",
      subtitle = "Fuente: Consulta metadatos, 2000-2023",
      x = "Años registrados",
      y = "Muertes por cada 100 mil habitantes",
      color = "Estado:",
      caption = "Luis Ramón Mercado Toledo" ) +
    scale_color_manual(values = c(
      "Chiapas" = "yellow",
      "Nuevo León" = "pink",
      "Puebla" = "brown", #color especifico
      "Sonora" = "blue",
      "Tabasco" = "purple"
    )) +
    scale_y_continuous(
      breaks = seq(0, max(diabetes$valor, na.rm = TRUE) + 20, by = 25) ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(size = 11),
      axis.title = element_text(face = "bold"),
      legend.position = "right")
  
  grafica_diabetes_final

#Ejercicio 9---- 

  lluvia_promedio_1 <- indicadores_estatales %>%
    filter(no == 950,
      year >= 2002,
      year <= 2024,
      !cve_ent %in% c("00", "33", "34", "99")) %>%
    select(cve_ent, year, valor) %>%
    left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent") %>%
    filter(entidad %in% c("Tabasco", "Chihuahua", "Jalisco", "Yucatán", "Ciudad de México", "Baja California"))
  
     
 #Gráfica :)
     
  grafica_lluvia <- ggplot(lluvia_promedio_1, aes(x = year, y = valor)) +
    geom_line(color = "blue", linewidth = 1) +
    geom_smooth(method = "lm", se = FALSE, color = "yellow", linewidth = 1) +
    facet_wrap(~entidad, scales = "free_y") +
    labs(
      title = "Lluvia promedio anual en seis estados de México (2002-2024)",
      x = "Año",
      y = "Lluvia promedio anual"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      strip.text = element_text(face = "bold"))
  
  grafica_lluvia
       
#Seccion 3: Unión de tablas – joins----
#Ejercicio 10----
     
     año_en_comun <- indicadores_estatales %>%
       filter(no %in% c(173, 569)) %>%
       filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
       group_by(year) %>%
       summarise(n_indicadores = n_distinct(no)) %>%
       filter(n_indicadores == 2) %>%
       summarise(año = max (year)) %>%
       pull(año)
     
     #Homicidios
     
     homicidios_1 <- indicadores_estatales %>%
       filter( no == 173, year == año_en_comun) %>%
       filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
       select(cve_ent, year, valor) %>%
       rename(valor_homicidios = valor)
     
     #Satisfacción con la vida 
     
     satisfaccion_1 <- indicadores_estatales %>%
       filter( no == 569, year == año_en_comun) %>%
       filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
       select(cve_ent, year, valor) %>%
       rename(valor_satisfaccion = valor)
     
     #Unimos los indicadores 
     
     violencia_satisfaccion <- homicidios_1 %>%
       inner_join(satisfaccion_1, by = c("cve_ent", "year")) %>%
       left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent")
     
     #Gráfica :)
     
     grafica_violencia_satisfaccion <- violencia_satisfaccion %>%
       ggplot(aes(x = valor_homicidios, y = valor_satisfaccion)) +
       geom_point(size = 3, alpha = 0.8) +
       labs(title = paste("Homicidios y satisfacción con la vida por estado,", año_en_comun),
            x= "Homicidios",
            y= "Satisfaccioón con la vida") +
       theme_minimal() +
       theme(plot.title = element_text(hjust = 0.5, face = "bold"))
     
     grafica_violencia_satisfaccion
     
     #Respuesta:En general, podría esperarse que los estados con más homicidios tengan menor satisfacción con la vida, pero la gráfica puede mostrar que esa relación no siempre es tan directa.
     
#Ejercicio 11----
     
     indicadores_salud <- indicadores_estatales %>%
       left_join(metadatos_estatales %>% select(no, indicador, umedida, clasificacion),
       by = "no") %>%
       group_by(indicador, umedida) %>%
       summarise(n_registros = n(), .groups = "drop") %>%
       select(indicador, umedida, n_registros)
     
     indicadores_salud
     
#Ejercicio 12----
     
     #Municipios
     
     municipios_monterrey <- c("Apodaca", "Cadereyta Jiménez","El Carmen", "García","San Pedro Garza García", "General Escobedo", "Guadalupe", "Juárez", "Monterrey", "Salinas Victoria", "San Nicolás de los Garza", "Santa Catarina", "Santiago")
     
     año_reciente_mty <- indicadores_municipales %>%
       filter(`Clave de indicador` == 138, 
              Municipio %in% municipios_monterrey) %>%
       summarise(año = max(Año, na.rm = TRUE)) %>%
       pull(año) #2019
     
     fecundidad_mty <- indicadores_municipales %>%
       filter(`Clave de indicador` == 138,
         Año == año_reciente_mty,
         Municipio %in% municipios_monterrey) %>%
       select(`Clave de municipio`, Municipio, Indicador, Año, Valor) %>%
       left_join(cat_mun, by = c("Clave de municipio" = "cvegeo")) %>%
       arrange(desc(Valor))
     
     #Gráfica :)
     
     grafica_fecundidad_mty <- fecundidad_mty %>%
       ggplot(aes(x = reorder(Municipio, Valor), y = Valor)) +
       geom_col(fill = "blue") +
       coord_flip() + #Se ve mejor
       labs(title = paste(unique(fecundidad_mty$Indicador), "- Zona Metropolitana de Monterrey"),
            subtitle = paste("Año de la gráfica:", año_reciente_mty),
            x = "Municipio",
            y = "Valor")+
       theme_minimal() +
       theme(plot.title = element_text(hjust = 0.5, face = "bold"),
         plot.subtitle = element_text(hjust = 0.5))
     
     grafica_fecundidad_mty
     
#Sección 4: Pivoteo de datos
#Ejercicio 13----
     
     celulares_ancho <- indicadores_estatales %>%
       filter( no == 98) %>%
       filter(year %in% c(2000, 2005, 2010, 2015, 2020)) %>%
       filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
       select(cve_ent, year, valor) %>%
       left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent") %>%
       select(entidad, year, valor) %>%
       pivot_wider(names_from = year,
         values_from = valor) %>%
       arrange(entidad)
     
     celulares_ancho

#Ejercicio 14----
     
     names(celulares_ancho)
     
     celulares_largo <- celulares_ancho %>%
       pivot_longer(cols = -entidad,
         names_to = "year",
         values_to = "valor") %>%
       mutate(year = as.numeric(year)) %>%
       arrange(entidad, year)
     
     celulares_largo
     
#Ejercicio 15----
     
     #Estado: Jalisco 
     estado_elegido <- "Jalisco"
     
     # 3 indicadores
     residuos_solidos <- indicadores_estatales %>%
       filter(no == 564) %>%
       filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
       left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent") %>%
       filter(entidad == estado_elegido)
     
     lluvia_promedio <- indicadores_estatales %>%
       filter(no == 950) %>%
       filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
       left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent") %>%
       filter(entidad == estado_elegido)
     
     incendios_forestales <- indicadores_estatales %>%
       filter(no == 628) %>%
       filter(!cve_ent %in% c("00", "33", "34", "99")) %>%
       left_join(cat_edos %>% select(cve_ent, entidad), by = "cve_ent") %>%
       filter(entidad == estado_elegido)
     
     #Unimos los inicadores
     
     indicadores_ambientales <- bind_rows(residuos_solidos, lluvia_promedio, incendios_forestales) %>%
       left_join(metadatos_estatales %>% select(no, indicador),
         by = "no")
     
     #Gráfica :)
     
     grafica_ambiental <- indicadores_ambientales %>%
       ggplot(aes(x = year, y = valor)) +
       geom_line(color = "purple", linewidth = 1) +
       facet_wrap(~indicador, scales = "free_y") +
       labs(title = paste("Tendencias ambientales en", estado_elegido),
         subtitle = "Residuos sólidos, lluvia promedio e incendios forestales",
         x = "Año",
         y = "Valor") +
       theme_minimal() +
       theme(plot.title = element_text(hjust = 0.5, face = "bold"),
         plot.subtitle = element_text(hjust = 0.5),
         strip.text = element_text(face = "bold"))
     
     grafica_ambiental

#Sección 5: Integración----
#Ejericio 16----
     
     #Cargamos archivo
     población_afiliacion <- read_csv("datos_problemario/Población_afiliacion.csv")
     
     #limpiamos archivo
     afiliacion <- población_afiliacion[5:38, ]
     
     #Asignamos los nonbres de las columnas
     names(afiliacion) <- as.character(unlist(afiliacion[1, ]))
     
     #Elimine el encabezado del archivo
     afiliacion <- afiliacion[-1, ]
     #Renombramos columnas: 
     afiliacion <- afiliacion %>%
       rename(entidad = `Entidad federativa`,
         total = Total,
         imss = IMSS,
         issste = ISSSTE,
         issste_estatal = `ISSSTE estatal`,
         pemex_defensa_marina = `Pemex, Defensa o Marina`,
         insabi = `Instituto de Salud para el Bienestar`,
         imss_bienestar = `IMSS-Bienestar`,
         institucion_privada = `Institución privada`,
         otra_institucion = `Otra institución`) 
     
     #Quitamos las comas comas y convertimos a numerico 
     afiliacion <- afiliacion %>%
       mutate(across(-entidad, ~ as.numeric(gsub(",", "", .))))

       #Elegimos los 10 estados con mayor afilación 
     top_10_estados <- afiliacion_estados %>%
       arrange(desc(total)) %>%
       slice(1:10)
     
     #Pasamos a formato largo
     afiliacion_larga <- top_10_estados %>%
       select(-total) %>%
       pivot_longer(cols = -entidad,
         names_to = "institucion",
         values_to = "poblacion") %>%
       mutate(institucion = recode(
           institucion,
           imss = "IMSS",
           issste = "ISSSTE",
           issste_estatal = "ISSSTE estatal",
           pemex_defensa_marina = "Pemex, Defensa o Marina",
           insabi = "INSABI",
           imss_bienestar = "IMSS-Bienestar",
           institucion_privada = "Institución privada",
           otra_institucion = "Otra institución"),
         entidad = fct_reorder(entidad, poblacion, .fun = sum))
     
     #Gráfica :)
     
     grafica_afiliacion <- afiliacion_larga %>%
       ggplot(aes(x = entidad, y = poblacion, fill = institucion)) +
       geom_col(width = 0.8) +
       coord_flip() +
       scale_y_continuous(labels = label_comma()) +
       labs(title = "Afiliación a servicios de salud por institución",
         subtitle = "Top 10 entidades con mayor población afiliada, México 2020",
         x = "Entidad federativa",
         y = "Población afiliada",
         fill = "Institución:",
         caption = "Fuente: INEGI (2020), Censo de Población y Vivienda") +
       theme_minimal() +
       theme(plot.title = element_text(size = 16, face = "bold"),
         plot.subtitle = element_text(size = 11),
         axis.text.y = element_text(size = 10),
         legend.position = "bottom",
         legend.title = element_text(face = "bold"))
     
     grafica_afiliacion
     
     
     
     
     
    
     
     
     
     

     
     
    
     
     
     
       
       
     
     
       
       
     
     
     
     
     
     
     
     
  
     
       
    
     
     
       
     
     
     
     
     
  
     
     
     
     
       
     
     
    
     
     
     
       
    
     
     
     
              
            
       
       
            
       
     
     
     
     
     
     
     
       
      
      
     
    
       
       
     
     
       
       
     
       
       
       
     
       
       
  
       
     
       
      
       
       
       
       
    
          
     
     
     
     
     
     
       
      
       
       
     
      
          
        
        
    

        
        

        
        

    

    
  
  
  
  
  
  
  
  
  

  
 
 
 
 
   
   
   
   
 
 
 
 
 
 
 
 
 
 
   
 
   
 
   
   
   
   
 
 
 

 
   
 
   
   
 
 
 
 
 
 
 
         
 
   
  





  
  




  


   
          
          
    



  





















  

       
  
  
  


  






