
library(tidyverse)

# Ejercicio 1 ----
# Con ventas_tienda.csv: (1) crea la variable ingreso = cantidad * precio_unitario; (2) calcula el ingreso total y el ticket promedio (ingreso/cantidad) por región y por categoría, usando group_by y summarise; (3) identifica la región con mayor ingreso total y la categoría más rentable por ticket promedio; (4) ordena los productos por ingreso total descendente y reporta los cinco principales.

ventas <- read_csv("02_EJERCICIOS_PRACTICOS/Sesion 02/archivos carga/Data/ventas_tienda.csv")

# (1) crea la variable ingreso = cantidad * precio_unitario;

ventas %>% 
  mutate(ingreso = cantidad * precio_unitario)

# (2) calcula el ingreso total y el ticket promedio (ingreso/cantidad) por región y por categoría, usando group_by y summarise;

ventas %>% 
  mutate(ingreso = cantidad * precio_unitario) %>% 
  group_by(region, categoria) %>% 
  summarise(ingreso = sum(ingreso), 
            ticket_promedio = sum(ingreso)/sum(cantidad))

# (3) identifica la región con mayor ingreso total y la categoría más rentable por ticket promedio;

ventas %>% 
  mutate(ingreso = cantidad * precio_unitario) %>% 
  group_by(region) %>% 
  summarise(ingreso = sum(ingreso)) %>% 
  ungroup() %>% 
  filter(ingreso == max(ingreso))
# La región norte, con 5,398

ventas %>% 
  mutate(ingreso = cantidad * precio_unitario) %>% 
  group_by(categoria) %>% 
  summarise(cantidad_total = sum(cantidad), 
            ingreso_total = sum(ingreso)) %>% 
  mutate(ticket_promedio = ingreso_total/cantidad_total) %>% 
  filter(ticket_promedio == max(ticket_promedio))
# La categoria más rentable son las computadoras

# (4) ordena los productos por ingreso total descendente y reporta los cinco principales.

ventas %>% 
  mutate(ingreso = cantidad * precio_unitario) %>% 
  group_by(producto) %>% 
  summarise(ingreso_total_producto = sum(ingreso)) %>% 
  arrange(-ingreso_total_producto) %>% 
  head(5)


# Ejercicio 2 ----
# Usando ventas_tienda.csv: (1) calcula por vendedor tres métricas: número de transacciones, ingreso total e ingreso promedio por transacción; (2) construye un gráfico de barras horizontales ordenado por ingreso total con reorder() dentro de aes(); (3) añade geom_text() con la etiqueta del ingreso total en formato numérico legible (separador de miles); (4) aplica theme_minimal, título y caption con la fuente.

ventas <- read_csv("02_EJERCICIOS_PRACTICOS/Sesion 02/archivos carga/Data/ventas_tienda.csv")

# (1) calcula por vendedor tres métricas: número de transacciones, ingreso total e ingreso promedio por transacción;
ventas %>% 
  group_by(vendedor) %>% 
  summarise(total_transacciones = n(), 
            ingreso_total = sum(precio_unitario*cantidad), 
            ingreso_promedio_por_transaccion = ingreso_total/total_transacciones)

# (2) construye un gráfico de barras horizontales ordenado por ingreso total con reorder() dentro de aes();

bd_grafica <- ventas %>% 
  group_by(vendedor) %>% 
  summarise(total_transacciones = n(), 
            ingreso_total = sum(precio_unitario*cantidad), 
            ingreso_promedio_por_transaccion = ingreso_total/total_transacciones)

bd_grafica %>% 
  ggplot(aes(x = reorder(vendedor, -ingreso_total), y = ingreso_total)) + 
  geom_col()

# (3) añade geom_text() con la etiqueta del ingreso total en formato numérico legible (separador de miles)

bd_grafica %>% 
  ggplot(aes(x = reorder(vendedor, -ingreso_total), y = ingreso_total)) + 
  geom_col() + 
  geom_text(aes(label = prettyNum(ingreso_total, big.mark = ",")), vjust = -0.2)

# (4) aplica theme_minimal, título y caption con la fuente.

bd_grafica %>% 
  ggplot(aes(x = reorder(vendedor, -ingreso_total), y = ingreso_total)) + 
  geom_col() + 
  geom_text(aes(label = prettyNum(ingreso_total, big.mark = ",")), vjust = -0.2) + 
  labs(title = "Ingreso total por vendedor", caption = "Fuente: Registros internos de ventas") + 
  theme_minimal()


# Ejercicio 3 ----
# Con empleados_empresa.xlsx: (1) crea la variable antigüedad_anios como la diferencia entre la fecha actual (Sys.Date()) y fecha_ingreso, convertida a años; (2) calcula salario promedio y mediana por departamento y género; (3) calcula la brecha salarial relativa por departamento como (salario_hombres − salario_mujeres) / salario_hombres; (4) representa el resultado con un gráfico de barras agrupadas (position = 'dodge') por departamento y género; (5) redacta dos oraciones interpretando los hallazgos.

empleados_empresa <- readxl::read_xlsx("02_EJERCICIOS_PRACTICOS/Sesion 02/archivos carga/Data/empleados_empresa.xlsx")

# (1) crea la variable antigüedad_anios como la diferencia entre la fecha actual (Sys.Date()) y fecha_ingreso, convertida a años;

empleados_empresa %>% 
  mutate(antiguedad_anios = Sys.Date() - as.Date(fecha_ingreso)) %>%   # Lo pase a Date para no tomar en cuenta las horas, minutos y segundos. 
  mutate(antiguedad_anios = as.numeric(antiguedad_anios/365))

# (2) calcula salario promedio y mediana por departamento y género;

empleados_empresa %>% 
  group_by(departamento, genero) %>% 
  summarise(salario_promedio = mean(salario))

# (3) calcula la brecha salarial relativa por departamento como (salario_hombres − salario_mujeres) / salario_hombres;

empleados_empresa %>% 
  group_by(departamento, genero) %>% 
  summarise(salario_promedio = mean(salario)) %>% 
  pivot_wider(id_cols = departamento, 
              names_from = genero, 
              values_from = salario_promedio) %>% 
  rename(salario_hombres = "M", salario_mujeres = "F") %>% 
  mutate(brecha = (salario_hombres - salario_mujeres) / salario_hombres)

# (4) representa el resultado con un gráfico de barras agrupadas (position = 'dodge') por departamento y género;

bd_plot <- empleados_empresa %>% 
  group_by(departamento, genero) %>% 
  summarise(salario_promedio = mean(salario)) %>% 
  pivot_wider(id_cols = departamento, 
              names_from = genero, 
              values_from = salario_promedio) %>% 
  rename(salario_hombres = "M", salario_mujeres = "F") %>% 
  mutate(brecha = (salario_hombres - salario_mujeres) / salario_hombres)

bd_plot %>% 
  pivot_longer(cols = c(salario_mujeres, salario_hombres)) %>% 
  ggplot(aes(x = departamento, y = value, fill = name)) + 
  geom_col(position = position_dodge()) + 
  geom_label(aes(y = 0, label = str_c("Brecha relativa:\n", round(brecha, 3))), fill = "white") + 
  scale_fill_manual(values = c(salario_hombres = "blue", salario_mujeres = "pink"))
  
# (5) redacta dos oraciones interpretando los hallazgos.

# 1. En Finanzas y IT, dados los datos, las mujeres ganan más que los hombres. 
# 2. En Ventas, el salario promedio de las mujeres del departamento es el 85% de de los hombres, obtenido por el cálculo de la brecha relativa de ventas. Si bien hay mejores indicadores, el indicador de la Brecha relativa nos indica, en el ingreso promedio de los hombres, la diferencia promedio de ingresos entre hombres y mujeres. 

# Ejercicio 4 ----
# Con datos_climaticos.rds: (1) resumen estadístico con summary() y cálculo de media, mediana, sd e IQR para temperatura, humedad y precipitación; (2) histogramas facetados por estación; (3) boxplot de temperatura por región y por calidad_aire; (4) matriz de correlaciones entre temperatura, humedad y precipitación; (5) interpreta: ¿existe alguna estación con temperatura atípicamente alta? ¿la humedad y la precipitación están correlacionadas?

clima <- readRDS("02_EJERCICIOS_PRACTICOS/Sesion 02/archivos carga/Data/datos_climaticos.rds") %>% 
  as_tibble()

# (1) resumen estadístico con summary() y cálculo de media, mediana, sd e IQR para temperatura, humedad y precipitación;

summary(clima)

variable <- clima$humedad
gen_estadistica <- function(variable, nombre_variable = ""){
  
  media <- mean(variable)
  sd_var <- sd(variable)
  mediana <- median(variable)
  q3 <- quantile(variable, 0.75)
  q1 <- quantile(variable, 0.25)
  iqr <- as.numeric(q3-q1)
  
  return(c("media" = media, "sd" = sd_var, "mediana" = mediana, "IQR" = iqr))
  
}

gen_estadistica(clima$temperatura)
gen_estadistica(clima$humedad)
gen_estadistica(clima$precipitacion)

# (2) histogramas facetados por estación;
clima %>% 
  mutate(estacion = factor(estacion, levels = c("Primavera", "Verano", "Otoño", "Invierno"))) %>% 
  ggplot(aes(x = temperatura, fill = estacion)) + 
  geom_histogram(color = "black") + 
  facet_wrap(~estacion) + 
  labs(title = "Histograma de valores por estación")

clima %>% 
  mutate(estacion = factor(estacion, levels = c("Primavera", "Verano", "Otoño", "Invierno"))) %>% 
  ggplot(aes(x = humedad, fill = estacion)) + 
  geom_histogram(color = "black") + 
  facet_wrap(~estacion) + 
  labs(title = "Histograma de valores por estación")

clima %>% 
  mutate(estacion = factor(estacion, levels = c("Primavera", "Verano", "Otoño", "Invierno"))) %>% 
  ggplot(aes(x = precipitacion, fill = estacion)) + 
  geom_histogram(color = "black") + 
  facet_wrap(~estacion) + 
  labs(title = "Histograma de valores por estación")


# (3) boxplot de temperatura por región y por calidad_aire;

clima %>% 
  ggplot(aes(x = region, y = temperatura)) + 
  geom_boxplot() + 
  labs(title = "Boxplot de temperatura por región")


clima %>% 
  ggplot(aes(x = calidad_aire, y = temperatura)) + 
  geom_boxplot() + 
  labs(title = "Boxplot de temperatura por calidad del aire")


# (4) matriz de correlaciones entre temperatura, humedad y precipitación;
cor(clima %>% select(temperatura, humedad, precipitacion))
  
# (5) interpreta: ¿existe alguna estación con temperatura atípicamente alta? ¿la humedad y la precipitación están correlacionadas?

clima %>% 
  select(id, temperatura) %>% 
  mutate(IQR_Temperatura = quantile(temperatura, 0.75) - quantile(temperatura, 0.25)) %>% 
  mutate(lim_superior_iqr = quantile(temperatura, 0.75) + 1.5*IQR_Temperatura) %>% 
  filter(temperatura >= lim_superior_iqr)

# Respuesta 1: No. 


# Respuesta 2: 
cor(clima$humedad, clima$precipitacion) # Muy poco

# Ejercicio 5: 
# Con datos_climaticos.rds: (1) extrae el mes con lubridate::month() o format(fecha, '%m'); (2) calcula el promedio mensual de temperatura, humedad y precipitación; (3) pivotea a formato largo con pivot_longer para tener una columna variable y otra valor; (4) grafica con geom_line() y facet_wrap(~variable, scales = 'free_y'), asegurando que cada panel tenga su propia escala Y; (5) añade un punto (geom_point) en cada mes.

clima <- readRDS("02_EJERCICIOS_PRACTICOS/Sesion 02/archivos carga/Data/datos_climaticos.rds") %>% 
  as_tibble()

# (1) extrae el mes con lubridate::month() o format(fecha, '%m')

clima <- clima %>% 
  mutate(mes = lubridate::month(fecha))

# (2) calcula el promedio mensual de temperatura, humedad y precipitación; 
clima_mes <- clima %>% 
  group_by(mes) %>% 
  summarise(temperatura = mean(temperatura), 
            humedad = mean(humedad), 
            precipitacion = mean(precipitacion))

min(clima$fecha)
max(clima$fecha)

# (3) pivotea a formato largo con pivot_longer para tener una columna variable y otra valor;
clima_mes %>% 
  pivot_longer(cols = temperatura:precipitacion)

# (4) grafica con geom_line() y facet_wrap(~variable, scales = 'free_y'), asegurando que cada panel tenga su propia escala Y
clima_mes %>% 
  pivot_longer(cols = temperatura:precipitacion, 
               names_to = "variable") %>% 
  ggplot(aes(x = mes, y = value)) + 
  facet_wrap(~variable, scales = "free_y") + 
  geom_line()

# (5) añade un punto (geom_point) en cada mes.
clima_mes %>% 
  pivot_longer(cols = temperatura:precipitacion, 
               names_to = "variable") %>% 
  ggplot(aes(x = mes, y = value)) + 
  facet_wrap(~variable, scales = "free_y") + 
  geom_line() + 
  geom_point()

# Usando df_pob_ent2.csv (CONEVAL, pobreza estatal anual): (1) filtra a los años disponibles y a la variable 'pobreza'; (2) construye un gráfico de líneas con facet_wrap(~entidad, ncol = 8); (3) dentro de cada panel, añade una línea horizontal con el promedio nacional del año más reciente (geom_hline); (4) colorea cada línea según si la entidad terminó el periodo por encima o por debajo de ese promedio nacional, usando una nueva columna y scale_color_manual; (5) escribe un párrafo con los tres estados que mostraron la mayor reducción absoluta de pobreza en el periodo.

pob <- readxl::read_excel("02_EJERCICIOS_PRACTICOS/Sesion 04/df_pob_ent2.csv") # Está mal el formato! 

# (1) filtra a los años disponibles y a la variable 'pobreza'; (2) construye un gráfico de líneas con facet_wrap(~entidad, ncol = 8);

pob %>% 
  filter(!is.na(pobreza)) %>% 
  ggplot(aes(x = anio, y = pobreza)) + 
  geom_line() + 
  facet_wrap(~entidad, ncol = 8)

# (3) dentro de cada panel, añade una línea horizontal con el promedio nacional del año más reciente (geom_hline);

# NO HAY PROMEDIO NACIONAL!
prom_nacional_mas_reciente <- pob %>% 
  filter(anio == max(anio)) %>% 
  pull(pobreza) %>% 
  mean()
  

pob %>% 
  filter(!is.na(pobreza)) %>% 
  ggplot(aes(x = anio, y = pobreza)) + 
  geom_line() + 
  facet_wrap(~entidad, ncol = 8) + 
  geom_hline(yintercept = prom_nacional_mas_reciente, color = "salmon")


# (4) colorea cada línea según si la entidad terminó el periodo por encima o por debajo de ese promedio nacional, usando una nueva columna y scale_color_manual;

catalogo_colores <- pob %>% 
  filter(anio == max(anio)) %>% 
  select(entidad, pobreza) %>% 
  mutate(arriba_nacional = ifelse(pobreza > prom_nacional_mas_reciente, yes = "encima_promedio", no = "abajo_promedio")) %>% 
  select(-pobreza)

c %>% 
  left_join(catalogo_colores) %>% 
  filter(!is.na(pobreza)) %>% 
  ggplot(aes(x = anio, y = pobreza, color = arriba_nacional)) + 
  geom_line() + 
  facet_wrap(~entidad, ncol = 8) + 
  geom_hline(yintercept = prom_nacional_mas_reciente, color = "salmon") + 
  scale_color_manual(values = c("green", "red"))


# (5) escribe un párrafo con los tres estados que mostraron la mayor reducción absoluta de pobreza en el periodo.

pob %>% 
  filter(anio %in% c(min(anio), max(anio))) %>% 
  select(anio, entidad, pobreza) %>% 
  pivot_wider(id_cols = entidad, names_from = anio, values_from = pobreza) %>% 
  mutate(brecha = `2024` - `2016`) %>% 
  arrange(brecha)

# Los estados con la mayor reducción de pobreza en el periodo fueron Hidalgo, Michoacán y Tabasco

# Ejercicio 07: 
# Con df_pob_ent2.csv restringido al año más reciente: (1) selecciona los seis indicadores de carencia: ic_rezedu (rezago educativo), ic_asalud (acceso salud), ic_segsoc (seguridad social), ic_cv (calidad vivienda), ic_sbv (servicios básicos de vivienda) e ic_ali_nc (alimentación); (2) calcula la matriz de correlaciones entre ellos; (3) visualízala con corrplot::corrplot() o un geom_tile() manual; (4) responde: ¿qué par de carencias está más correlacionado? ¿cuál menos? ¿qué implica eso para el diseño de política social?


