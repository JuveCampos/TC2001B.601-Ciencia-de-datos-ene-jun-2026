
# Librerias ----
library(tidyverse)
library(sf)
library(janitor)
library(ggimage)

# Cargamos los datos ----
datos <- readRDS("01_datos/datos_atus_2023.rds") %>% 
  as_tibble() %>% 
  select(-geometry)

datos_grafica_1 <- datos %>% 
  clean_names() %>%  # Cambia los nombres de las columnas 
  group_by(diasemana) %>% 
  summarise(total_accidentes = n()) %>% 
  mutate(dias_semana_texto = case_when(diasemana == 1 ~ "Lunes", 
                                       diasemana == 2 ~ "Martes",
                                       diasemana == 3 ~ "Miércoles",
                                       diasemana == 4 ~ "Jueves",
                                       diasemana == 5 ~ "Viernes",
                                       diasemana == 6 ~ "Sábado",
                                       diasemana == 7 ~ "Domingo",
                                       TRUE ~ "Día no registrado"
                                       )) %>% 
  # Ordenamos los días de la semana como categoría ordenada: 
  mutate(dias_semana_texto = factor(dias_semana_texto, levels = c("Lunes", "Martes", "Miércoles", 
                                                                  "Jueves", "Viernes", "Sábado",
                                                                  "Domingo", "Día no registrado"
                                                                  ))) %>% 
  filter(dias_semana_texto != "Día no registrado") %>% 
  mutate(porcentaje = 100*(total_accidentes/sum(total_accidentes))) %>% 
  mutate(textos_columnas = 
           str_c(prettyNum(total_accidentes, big.mark = ","),
                 "\n", "[",  round(porcentaje, 2), "%]"))



datos_grafica_1

grafica <- datos_grafica_1 %>% 
  ggplot(aes(x = dias_semana_texto, y = total_accidentes)) + 
  geom_col(fill = "#1b3188") + 
  geom_text(aes(label = textos_columnas), 
            color = "black",
            hjust = 0.5, 
            vjust = -0.15,
            fontface = "bold") + 
  labs(title = "Total de accidentes por día de la semana", 
       subtitle = "Accidentes correspondientes al año 2023", 
       caption = "Elaboración propia con datos del ATUS (Accidentes de Trásito Terrestre en Zonas Urbanas y Suburbanas) de INEGI, 2023", 
       y = "Total de accidentes", 
       x = NULL) + 
  scale_y_continuous(expand = expansion(c(0, 0.15)))

grafica


grafica <- ggbackground(gg = grafica, 
             background = "03_visualizaciones/plantilla.png")

ggsave(filename = "03_visualizaciones/grafica_01.jpeg",
       plot = grafica,
       width = 10,
       height = 9)

