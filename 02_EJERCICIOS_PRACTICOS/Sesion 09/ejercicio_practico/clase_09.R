# Opciones 
options(scipen = 999)

# Gráficas de facetas ----
library(tidyverse)
library(readxl)

# Cargar los datos ----
proyecciones <- read_excel("proyeccion_poblacion_2070.xlsx")

cat_edos <- read_csv("https://raw.githubusercontent.com/JuveCampos/Shapes_Resiliencia_CDMX_CIDE/master/Datos/cat_edos.csv")

bd_grafica <- proyecciones %>% 
  filter(cve_ent != "00") %>% 
  left_join(cat_edos, by = "cve_ent")

bd_grafica %>% 
  ggplot(aes(x = year, y = valor/1e6, 
             group = entidad, color = entidad)) + 
  geom_line() + 
  theme_minimal() + 
  facet_wrap(~entidad, scales = "free_y", ncol = 8) + 
  theme(legend.position = "none") + 
  labs(title = "Proyección de población por entidad")
  
ggsave("grafica_proyecciones_poblacion.jpeg", 
       height = 10, width = 20)


for (i in 1:5) {
  print(i)
}


#Saludo

Saludos <- function(tiempo = "mañana"){
  if(tiempo == "mañana"){
    saludo <- "Buenos días"
  }else if (tiempo == "noche"){
    saludo <- "Buenas noches" 
  }else{
    saludo <- "Hola"
  }
  return(saludo)
}

Saludos()
Saludos(tiempo = "noche")
Saludos(tiempo = "tared")

# Aguascalientes ----

bd_grafica <- proyecciones %>% 
  filter(cve_ent != "00") %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  filter(entidad == "Aguascalientes")

bd_grafica %>% 
  ggplot(aes(x = year, y = valor/1e6, 
             group = entidad, color = entidad)) + 
  geom_line() + 
  theme_minimal() + 
  facet_wrap(~entidad, scales = "free_y", ncol = 8) + 
  theme(legend.position = "none") + 
  labs(title = "Proyección de población por entidad")

# Morelos ----

bd_grafica <- proyecciones %>% 
  filter(cve_ent != "00") %>% 
  left_join(cat_edos, by = "cve_ent") %>% 
  filter(entidad == "Morelos")

bd_grafica %>% 
  ggplot(aes(x = year, y = valor/1e6, 
             group = entidad, color = entidad)) + 
  geom_line() + 
  theme_minimal() + 
  facet_wrap(~entidad, scales = "free_y", ncol = 8) + 
  theme(legend.position = "none") + 
  labs(title = "Proyección de población por entidad")

# Generar funcion para gráfica de cada estado 

generar_grafica_estado <- function(edo_sel = "Morelos"){
  
  bd_grafica <- proyecciones %>% 
    filter(cve_ent != "00") %>% 
    left_join(cat_edos, by = "cve_ent") %>% 
    filter(entidad == edo_sel)
  
  plt <- bd_grafica %>% 
    ggplot(aes(x = year, y = valor/1e6, 
               group = entidad, color = entidad)) + 
    geom_line() + 
    theme_minimal() + 
    facet_wrap(~entidad, scales = "free_y", ncol = 8) + 
    theme(legend.position = "none") + 
    labs(title = "Proyección de población por entidad")
  
  return(plt)
  
}

# Ejecuciones funcion 
generar_grafica_estado()
generar_grafica_estado(edo_sel = "Tabasco")
generar_grafica_estado(edo_sel = "Sinaloa")
generar_grafica_estado(edo_sel = "Puebla")
generar_grafica_estado(edo_sel = "Veracruz")

# Bucle 

nombres_estados <- cat_edos %>% 
  filter(cve_ent != "00") %>% 
  filter(!(cve_ent %in% c("33", "34", "99"))) %>% 
  pull(entidad)

# nombre_estados <- c("Aguascalientes", "Baja California")

for(estado in nombres_estados){
  generar_grafica_estado(edo_sel = estado)
  ggsave(filename = str_c("grafica_", estado, ".jpeg"), 
         height = 8, width = 10)
}



