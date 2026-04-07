options(scipen = 999)

# Librerías
library(tidyverse)

# Cargue los datos que se encuentran en la carpeta del ejercicio 01 de la sesión 10. 

empleados <- read_csv("datos_empleados.csv")

# 1. Explore los datos. ¿Cuantas filas tienen? ¿Cuantas columnas? ¿Cuales son los nombres de las variables? ¿Cuales son numéricas? ¿Cuales son categóricas o de texto? 

nrow(empleados) # 300 renglones
ncol(empleados) # 12 columnas 
names(empleados) # Nombres de las columnas
empleados

# 2. Aplique a la tabla la función summary(). ¿Qué resultado le arroja? 
  
summary(empleados)

# 3. Obtenga la media sólo del ingreso mensual. 

mean(empleados$ingreso_mensual, na.rm = TRUE)

empleados %>% 
  summarise(media = mean(ingreso_mensual, na.rm = T))

# 4. Detecte las variables numéricas. Genere una tabla nueva con esas variables. Grafique su distribución usando geom_density y un arreglo de facetas. Comente. 

sapply(empleados, class)

datos_numericos <- empleados %>% 
  select(id, edad, años_experiencia, ingreso_mensual, 
         gastos_mensual, score_desempeño, horas_extras_semana,
         num_dependientes)

bd_plot <- datos_numericos %>% 
  pivot_longer(cols = edad:num_dependientes)

# Gráfica: 
bd_plot %>% 
  ggplot(aes(x = value)) + 
  geom_density() + 
  facet_wrap(~name, scale = "free")

# 5. Ahora haga un boxplot con geom_boxplot. ¿Puede visualizar los outliers?

bd_plot %>%
  ggplot(aes(x = value)) +
  geom_boxplot() + 
  facet_wrap(~name, scales = "free_x")

# 6. Obtenga la correlación entre el ingreso mensual y los gastos mensuales. También haga la gráfica correspondiente con geom_point() y verifique gráficamente esta respuesta.

empleados %>% 
  na.omit() %>% 
  summarise(corr = cor(ingreso_mensual, gastos_mensual))


empleados %>% 
  filter(ingreso_mensual <= 60000) %>% 
  ggplot(aes(x = ingreso_mensual, y = gastos_mensual)) + 
  geom_point(color = "red", alpha = 0.3) + 
  geom_smooth(method = "lm") + 
  theme_minimal() +
  labs(title = "Relación entre ingreso mensual y gasto mensual")

# 7. Diagnostique el tipo de NAs que tiene la variable “ingreso_mensual”.

empleados_na <- empleados %>% 
  mutate(tiene_na_ingreso_mensual = 
           ifelse(is.na(ingreso_mensual), 
                  yes = "Tiene NAs", 
                  no = "No tiene NAs"))

empleados_na %>% 
  group_by(tiene_na_ingreso_mensual) %>% 
  summarise(edad = mean(edad, na.rm = T), 
            score_desempeño = mean(score_desempeño, na.rm = T), 
            años_experiencia = mean(años_experiencia)
            )

empleados_ingreso_imputado <- empleados_na %>% 
  mutate(ingreso_mensual_imputado = ifelse(is.na(ingreso_mensual), 
                                           yes = median(ingreso_mensual, na.rm = TRUE), 
                                           no = ingreso_mensual)) %>% 
  select(id, ingreso_mensual, ingreso_mensual_imputado)

