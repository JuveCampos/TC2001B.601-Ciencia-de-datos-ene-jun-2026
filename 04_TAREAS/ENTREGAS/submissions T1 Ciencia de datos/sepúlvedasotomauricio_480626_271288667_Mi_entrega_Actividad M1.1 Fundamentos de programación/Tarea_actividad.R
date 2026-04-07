# Cargamos librerías  -----------------------------------------------------

library(tidyverse)
library(ggplot2)
library(readr)
library(readxl)




# Cargamos los datos ------------------------------------------------------

cat_edos <- read_csv("Datos_problemario/cat_edos.csv")
cat_mun <- read_csv("Datos_problemario/cat_mun.csv")
indicadores_estatales <- read_csv("Datos_problemario/indicadores_estatales.csv")
indicadores_municipales <- read_csv("Datos_problemario/indicadores_municipales.csv")
metadatos_estatales <- read_csv("Datos_problemario/metadatos_estatales.csv")
metadatos_municipales <- read_csv("Datos_problemario/metadatos_municipales.csv")




# Sección 1 ---------------------------------------------------------------


# Ejercicio 1: filter + select --------------------------------------------

indicador_pobreza <- indicadores_estatales %>% 
filter(cve_ent != "00") %>% 
filter(cve_ent != "33") %>% 
filter(cve_ent  != "34") %>% 
filter(cve_ent != "99") %>% 
filter(no == "921") %>% 
filter(year == "2022") %>% 
select("cve_ent", "valor")


tabla_pobreza_estados_2022 <- left_join(indicador_pobreza, cat_edos, by = "cve_ent") %>% 
arrange(-valor) %>% 
head(3) #la función head la comprobé con IA, no recuerdo si fue utilizada en clase


# ¿Cuáles son los 3 estados con mayor pobreza en 2022?
#CHIAPAS, GUERRERO, OAXACA





# Ejercicio 2: arrange + slice --------------------------------------------

indicador_esperanza_de_vida <- indicadores_estatales %>% 
  filter(cve_ent != "00") %>% 
  filter(cve_ent != "33") %>% 
  filter(cve_ent  != "34") %>% 
  filter(cve_ent != "99") %>% 
  filter(no == "54") %>% 
  filter(year == "2020") %>% 
  select("cve_ent", "valor")

tabla_esperanza_2020 <- left_join(indicador_esperanza_de_vida, cat_edos, by = "cve_ent")  
  
  
  bottom_5_ev <- arrange(tabla_esperanza_2020, valor) %>% 
  slice(1:5) 
  
  
  top_5_ev <- arrange(tabla_esperanza_2020, desc(valor)) %>%
  slice(1:5)
  
#¿Cuántos años de diferencia hay entre el estado con mayor y menor esperanza de vida?  
# La diferencia entre el estado con mayor esperanza de vida (Baja California Sur) y menor esperanza de vida (Tlaxcala) en 2020 es de 7.3 años 
  


  
  
# Ejercicio 3: mutate -----------------------------------------------------

indicador_suscripciones_celulares <- indicadores_estatales %>% 
  filter(cve_ent != "00") %>% 
  filter(cve_ent != "33") %>%     
  filter(cve_ent  != "34") %>% 
  filter(cve_ent != "99") %>% 
  filter(no == "98") %>% 
  filter(year == "2005" | year == "2020") %>% 
  select("cve_ent", "valor", year)
  
tabla_suscripciones_2005_2020 <- left_join(indicador_suscripciones_celulares, cat_edos, by = "cve_ent") %>% 
  select(-cve_ent) %>% 
  select(-entidad_abr_m) %>% 
  pivot_wider(id_cols = entidad, 
    names_from = year,
              values_from = "valor") %>% 
  mutate(diferencia =  `2020`- `2005`)  
  

# ¿Qué estado tuvo el mayor crecimiento porcentual en adopción de  --------
#Durango, con un crecimiento de 76.41





# Ejercicio 4: group_by + summarise---------------------------------------------
indicador_vehículos <- indicadores_estatales %>% 
  filter(cve_ent == "00") %>% 
  filter(no == "156") %>% 
  select(-cve_ent) %>% 
  select(-no) %>% 
  mutate(decada = floor(year / 10) * 10) %>%  
  group_by(decada) %>% 
  summarise(
    promedio = mean(valor, na.rm = TRUE), 
    desv_est = sd(valor, na.rm = TRUE)
  )

#¿En qué década se registra el mayor promedio de vehículos por 1000 habitantes?
                  # En la década del 2020
#¿De cuanto es este promedio para la década con el valor más alto?
                  # En promedio hay 420 vehículos por cada 1000 habitantes






# Sección 2 ---------------------------------------------------------------


# Ejercicio 5: geom_line --------------------------------------------------


indicador_mort_diabetes <- indicadores_estatales %>% 
filter(cve_ent != "00") %>% 
  filter(cve_ent != "33") %>%     
  filter(cve_ent  != "34") %>% 
  filter(cve_ent != "99") %>% 
  filter(no == "36") %>% 
  filter(year >= 2000 & year <= 2023) %>% 
  select(cve_ent, valor, year)

tabla_diabetes <- indicador_mort_diabetes %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  filter(cve_ent %in% c("07", "27", "21", "19", "26")) %>% 
  select(-cve_ent) %>% 
  select(-entidad_abr_m) 

grafica_diabetes <- ggplot(tabla_diabetes, aes(x = year, y = valor, color = entidad)) +
  geom_line(size = 1) +
  labs(
    title = "Mortalidad por diabetes en México (2000–2023)",
    x = "Año",
    y = "Mortalidad cada 100,000 habitantes",
    color = "Estado"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),      legend.position = "bottom" #Modificación personal 
  )    

ggsave("grafica_diabetes.png", grafica_diabetes, width = 8, height = 6)   




# Ejercicio 6: geom_col ---------------------------------------------------

indicador_satisfaccion <- indicadores_estatales %>% 
  filter(cve_ent != "00") %>% 
  filter(cve_ent != "33") %>%     
  filter(cve_ent  != "34") %>% 
  filter(cve_ent != "99") %>% 
  filter(no == "569") %>% 
  filter(year == 2024) %>% 
  select(cve_ent, valor, year)

tabla_satisfaccion <- indicador_satisfaccion %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  select(-cve_ent) %>% 
  select(-entidad_abr_m) 

grafica_satisfaccion <- ggplot(tabla_satisfaccion, aes(x = reorder(entidad, valor), y = valor, fill = valor)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Satisfacción con la vida por estado en el año 2024",
    x = "Estado",
    y = "Nivel de satisfacción"
  ) +
  scale_fill_gradient(low = "palegreen", high = "black") +
  theme_minimal()+
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),      legend.position = "bottom" #Modificación personal 
  )    

ggsave("grafica_satisfaccion.png", grafica_satisfaccion, width = 8, height = 6)

#¿Cuál fue el estado con la mayor satisfacción por la vida?
#El Estado con la mayor satisfacción fue Chihuahua.





# Ejercicio 7: geom_point (scatter plot) ----------------------------------

indicador_PIB_PC <- indicadores_estatales %>% 
  filter(cve_ent != "00") %>% 
  filter(cve_ent != "33") %>%     
  filter(cve_ent  != "34") %>% 
  filter(cve_ent != "99") %>% 
  filter(no == "1266") %>% 
  filter(year == 2020) %>% 
  select(cve_ent, valor, year)

indicador_fecundidad_adolescente <- indicadores_estatales %>% 
  filter(cve_ent != "00") %>% 
  filter(cve_ent != "33") %>%     
  filter(cve_ent  != "34") %>% 
  filter(cve_ent != "99") %>% 
  filter(no == "40") %>% 
  filter(year == 2020) %>% 
  select(cve_ent, valor, year)

tabla_PIB_PC <- indicador_PIB_PC %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  select(-cve_ent) %>% 
  select(-entidad_abr_m) 

tabla_fecundidad_adolescente <- indicador_fecundidad_adolescente %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  select(-cve_ent) %>% 
  select(-entidad_abr_m) 

tabla_PIB_fecundidad <- tabla_PIB_PC %>% 
  left_join(tabla_fecundidad_adolescente, by = "entidad") %>% 
  select(-year.x) %>% 
  select(-year.y)

grafica_PIB_fecundidad <- ggplot(tabla_PIB_fecundidad, aes(x = valor.x, y = valor.y, color = entidad)) +
  geom_point(size = 4) +
  labs(
    title = "PIB per cápita y fecundidad adolescente en el año 2020",
    x = "PIB per cápita (en miles)",
    y = "Fecundidad adolescente",
    color = "Estado"
  ) +
  scale_x_continuous(labels = function(x) x / 1000) +
  theme_minimal() +
  theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    legend.position = "right")

ggsave("grafica_PIB_fecundidad.png", grafica_PIB_fecundidad, width = 8, height = 6)


# ¿Qué relación observas entre desarrollo económico y fecundidad adolescente?
# Aunque se requiere de un análisis mucho más profundo para determinar la correlación, gráficamente es posible deducir que entre menor pib, mayor fecundidad adolescente hay en el estado y viceversa. El caso de Campeche es sumamente irregular.





# Ejercicio 8: Personalización de gráficas --------------------------------

grafica_diabetes_final <- ggplot(tabla_diabetes, aes(x = year, y = valor, color = entidad)) +
  geom_line(size = 1) +
  labs(
    title = "El problema de la mortalidad por diabetes en México (2000–2023)",
    subtitle = "Fuente: Indicadores estatales (INEGI)",
    x = "Año",
    y = "Defunciones por cada 100,000 habitantes",
    color = "Estado",
    caption = "Autor: Mauricio Sepúlveda Soto"
  ) +
  scale_color_manual(values = c(
    "Chiapas" = "green4",
    "Tabasco" = "red",
    "Puebla" = "brown",       
    "Nuevo León" = "lightskyblue2",
    "Sonora" = "orange"
  )) +
  scale_y_continuous(labels = scales::comma) + 
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 8, hjust = 0.5),
    legend.position = "bottom"
  )

ggsave("grafica_diabetes_final.png", grafica_diabetes_final, width = 8, height = 6)   




# Ejercicio 9: facet_wrap -------------------------------------------------

indicador_lluvia <- indicadores_estatales %>% 
  filter(cve_ent != "00") %>% 
  filter(cve_ent != "33") %>%     
  filter(cve_ent  != "34") %>% 
  filter(cve_ent != "99") %>% 
  filter(no == "950") %>% 
  filter(year >= 2002 & year <= 2024) %>% 
  select(cve_ent, valor, year)

tabla_lluvia <- indicador_lluvia %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  filter(cve_ent %in% c("27", "08", "14", "31", "09", "02")) %>% 
  select(-cve_ent) %>% 
  select(-entidad_abr_m) 

grafica_lluvia <- tabla_lluvia %>% 
  ggplot(aes(x = year, y = valor)) +
  geom_line(color = "lightblue", size = 1) +
  geom_smooth(method = "lm", se = FALSE, color = "darkred") +
  facet_wrap(~entidad, scales = "free_y") +
  labs(
    title = "Lluvia promedio anual por estado (2002–2024)",
    x = "Año",
    y = "Precipitación promedio"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5)
  )

ggsave("grafica_lluvia.png", grafica_lluvia, width = 8, height = 6) 





# Sección 3: Unión de tablas – joins --------------------------------------



# Ejercicio 10: _join de dos indicadores ----------------------------------

indicador_homicidios_2015 <- indicadores_estatales %>% 
  filter(cve_ent != "00") %>% 
  filter(cve_ent != "33") %>%     
  filter(cve_ent  != "34") %>% 
  filter(cve_ent != "99") %>% 
  filter(no == "173") %>% 
  filter(year == 2015) %>%   
  select(cve_ent, valor, year)                                  

indicador_satisfaccion_2015 <- indicadores_estatales %>% 
  filter(cve_ent != "00") %>% 
  filter(cve_ent != "33") %>%     
  filter(cve_ent  != "34") %>% 
  filter(cve_ent != "99") %>% 
  filter(no == "569") %>% 
  filter(year == 2015) %>% 
  select(cve_ent, valor, year)

tabla_violencia <- indicador_homicidios_2015 %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  select(-cve_ent) %>% 
  select(-entidad_abr_m) 

tabla_satisfaccion_2015 <- indicador_satisfaccion_2015 %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  select(-cve_ent) %>% 
  select(-entidad_abr_m) 

tabla_violencia_satisfaccion <- tabla_violencia %>% 
  left_join(tabla_satisfaccion_2015, by = "entidad") %>% 
  select(-year.x) %>% 
  select(-year.y)

grafica_violencia_satisfaccion <- ggplot(tabla_violencia_satisfaccion, aes(x = valor.x, y = valor.y, color = entidad)) +
  geom_point(size = 4) +
  labs(
    title = "Relación entre Homicidios y Satisfacción con la vida en el año 2015",
    x = "Homicidios",
    y = "Satisfacción con la vida",
    color = "Estado"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        legend.position = "right")

ggsave("grafica_violencia_satisfaccion.png", grafica_violencia_satisfaccion, width = 8, height = 6)

#¿Los estados más violentos son menos felices?
#En efecto, la respuesta parece contraintuitiva, ya que en la gráfica se observan estados con muy pocos homicidios pero bajos niveles de satisfacción con la vida. Tampoco se observa una correlación directa clara entre los homicidios y la satisfacción con la vida. 





# Ejercicio 11: left_join con metadatos -----------------------------------

indicadores_estatales_y_metadatos <- indicadores_estatales %>% 
  left_join(metadatos_estatales, by = "no") %>% 
  group_by(indicador, umedida) %>% 
  summarise(
    n_registros = n(),
    .groups = "drop")
#Como se solicita en el ejercicio, Variable resultado: indicadores_salud (columnas: indicador, umedida, n_registros).




#Ejercicio 12: Join con datos municipales

indicador_fecundidad_adolescente_municipal <- indicadores_municipales %>% 
  filter(Año == 2024) %>% 
  filter("Clave de indicador" == "138") %>% 
  filter("Clave de metrópoli" == "19.1.01") %>% 
  select("Año", "Clave de indicador", "Clave de metrópoli")





# Sección 4: Pivoteo de datos ---------------------------------------------



# Ejercicio 13: pivot_wider -----------------------------------------------

celulares_ancho <- indicadores_estatales %>% 
  filter(!cve_ent %in% c("00", "33", "34", "99"),
         no == "98",
         year %in% c(2000, 2005, 2010, 2015, 2020)) %>% 
  select(cve_ent, year, valor) %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  select(entidad, year, valor) %>% 
  pivot_wider(
    names_from = year,
    values_from = valor
  )



# Ejercicio 14: pivot_longer ----------------------------------------------

celulares_largo <- celulares_ancho %>% 
  pivot_longer(
    cols = -entidad,
    names_to = "year",
    values_to = "valor"
  ) %>% 
  mutate(year = as.numeric(year))



# Ejercicio 15: pivot + ggplot – Dashboard ambiental ----------------------

residuos_solidos <- indicadores_estatales %>% 
  filter(cve_ent == "15", no == "564")

lluvia_promedio <- indicadores_estatales %>% 
  filter(cve_ent == "15", no == "950")

incendios_forestales <- indicadores_estatales %>% 
  filter(cve_ent == "15", no == "628")


tabla_ambiental <- bind_rows(residuos_solidos, lluvia_promedio, incendios_forestales)

tabla_ambiental <- tabla_ambiental %>% 
  left_join(metadatos_estatales, by = "no")

grafica_ambiental <- tabla_ambiental %>% 
  ggplot(aes(x = year, y = valor)) +
  geom_line(color = "darkgrey", size = 3) +
  geom_point(size = 4) +
  facet_wrap(~indicador, scales = "free_y") +
  labs(
    title = "Indicadores ambientales en el Estado de México",
    subtitle = "Residuos sólidos, lluvia promedio e incendios forestales",
    x = "Año",
    y = "Valor"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5)
  )

ggsave("grafica_ambiental.png", grafica_ambiental, width = 8, height = 6)





# Sección 5: Integración --------------------------------------------------


# Ejercicio 16: Use sus propios datos. ------------------------------------

#Datos de inflación del Banco Mundial

inflacion <- read_csv("Datos_problemario/API_FP.CPI.TOTL.ZG_DS2_en_csv_v2_84.csv", skip = 4)


inflacion_limpio <- inflacion %>% 
  select(`Country Name`, starts_with("20")) %>% 
  pivot_longer(
    cols = -`Country Name`,
    names_to = "year",
    values_to = "inflacion"
  ) %>% 
  mutate(
    year = as.numeric(year),
    inflacion = as.numeric(inflacion)
  ) %>% 
  filter(!is.na(inflacion))

inflacion_latest <- inflacion_limpio %>% 
  group_by(`Country Name`) %>% 
  filter(!is.na(inflacion)) %>% 
  slice_max(year, n = 1, with_ties = FALSE) %>% 
  ungroup()

grafica_inflacion <- inflacion_latest %>% 
  arrange(desc(inflacion)) %>% 
  slice_head(n = 10) %>% 
  ggplot(aes(x = reorder(`Country Name`, inflacion), y = inflacion)) +
  geom_col(fill = "red") +
  coord_flip() +
  theme_minimal()

ggsave("grafica_inflacion.png", grafica_inflacion, width = 8, height = 6)
