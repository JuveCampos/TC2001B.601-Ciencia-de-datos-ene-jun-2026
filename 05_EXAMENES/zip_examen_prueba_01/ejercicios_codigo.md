# Ejercicios con Código — Ciencia de Datos TC2001B.601
## Guía de estudio práctica (Ene-Jun 2026)

---

## Sesión 01: Presentación — Verificación de entorno

### Ejercicio 1.1: Verificar instalación
Ejecuta el siguiente código y verifica que no hay errores:

```r
# Verifica que R funciona correctamente
print(R.version.string)
print(Sys.Date())

# Verifica que puedes instalar paquetes
install.packages("tidyverse")
library(tidyverse)

# Verifica que ggplot funciona
ggplot(mtcars, aes(x = mpg, y = hp)) +
  geom_point() +
  labs(title = "Si ves esta gráfica, tu instalación está correcta")
```

**Pregunta:** ¿Qué versión de R tienes instalada? ¿Cuántos paquetes se cargan al hacer `library(tidyverse)`?

---

## Sesión 02: Introducción a la ciencia de datos

### Ejercicio 2.1: Exploración de un proyecto
Crea un proyecto de R con la siguiente estructura y explica para qué sirve cada carpeta:

```r
# Crea las carpetas de un proyecto de ciencia de datos
dir.create("mi_proyecto/datos", recursive = TRUE)
dir.create("mi_proyecto/scripts")
dir.create("mi_proyecto/resultados")

# Pregunta: ¿Por qué es importante usar rutas relativas en vez de absolutas?
# Escribe tu respuesta como comentario aquí:
# R: ___
```

### Ejercicio 2.2: Tipos de datos en R
Completa el código para identificar el tipo de cada variable:

```r
# Datos de ejemplo
nombre <- "Ana García"
edad <- 25
es_estudiante <- TRUE
fecha_nacimiento <- as.Date("1999-05-15")
calificaciones <- c(8.5, 9.0, 7.8, 9.5)

# Usa class() para verificar el tipo de cada variable
class(nombre)       # ¿Qué tipo es?
class(edad)         # ¿Qué tipo es?
class(es_estudiante) # ¿Qué tipo es?
class(fecha_nacimiento) # ¿Qué tipo es?
class(calificaciones)   # ¿Qué tipo es?

# Pregunta: ¿Cuál es la diferencia entre numeric e integer?
# Convierte 'edad' a integer y verifica:
edad_int <- ___
class(edad_int)
```

### Ejercicio 2.3: Vectores y operaciones básicas
```r
# Datos de ventas mensuales (miles de pesos)
ventas <- c(150, 230, 180, 310, 275, 420, 380, 290, 350, 410, 280, 500)
meses <- c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic")

# 1. ¿Cuál fue el mes con mayores ventas?
meses[which.max(___)]

# 2. ¿Cuál es el promedio de ventas?
mean(___)

# 3. ¿Cuántos meses tuvieron ventas mayores a 300?
sum(___ > 300)

# 4. Crea un vector con las ventas del segundo semestre (Jul-Dic)
segundo_semestre <- ventas[___]

# 5. ¿Cuál es la diferencia entre las ventas máximas y mínimas?
max(ventas) - min(ventas)
```

---

## Sesión 03: Importando datos desde archivos

### Ejercicio 3.1: Crear y manipular tibbles
```r
library(tidyverse)

# Crea una tibble con datos de 10 municipios ficticios
municipios <- tibble(
  nombre = c("Saltillo","Monterrey","Guadalajara","Puebla","Mérida",
             "León","Querétaro","Tijuana","Chihuahua","Oaxaca"),
  poblacion = c(925000, 1135000, 1495000, 1692000, 921000,
                1579000, 1050000, 1810000, 925000, 264000),
  pib_pc = c(185000, 245000, 198000, 142000, 175000,
             167000, 230000, 178000, 195000, 98000),
  tasa_desempleo = c(3.2, 4.1, 3.8, 5.2, 2.9, 4.5, 3.1, 2.8, 3.9, 6.1),
  region = c("Norte","Norte","Occidente","Centro","Sureste",
             "Centro","Centro","Norte","Norte","Sur")
)

# 1. Muestra las primeras 5 filas
head(municipios, ___)

# 2. ¿Cuántas filas y columnas tiene?
dim(___)

# 3. Calcula las estadísticas descriptivas del PIB per cápita
summary(municipios$___)

# 4. ¿Cuál es la media y desviación estándar de la tasa de desempleo?
mean(municipios$tasa_desempleo)
sd(municipios$tasa_desempleo)

# 5. ¿Cuál es la mediana de la población?
median(municipios$___)

# 6. ¿Cuál es el municipio con mayor PIB per cápita?
municipios$nombre[which.max(municipios$___)]
```

### Ejercicio 3.2: Importación desde múltiples formatos
```r
library(tidyverse)
library(readxl)

# Importar CSV
# df_csv <- read_csv("ruta/al/archivo.csv")

# Importar Excel
# df_excel <- read_excel("ruta/al/archivo.xlsx", sheet = 1)

# Pregunta: ¿Qué argumento usas para saltar las primeras N filas de un Excel?
# R: skip = ___

# Pregunta: ¿Qué paquete necesitas para leer un archivo .dta (Stata)?
# R: ___

# Pregunta: ¿Qué función de sf usas para leer un archivo .geojson?
# R: ___
```

---

## Sesión 04: Procesamiento y visualización de datos

### Ejercicio 4.1: Verbos de dplyr
```r
library(tidyverse)

# Datos simulados de pobreza estatal
set.seed(42)
estados <- tibble(
  estado = c("Aguascalientes","Baja California","Chiapas","CDMX","Guerrero",
             "Jalisco","Nuevo León","Oaxaca","Puebla","Tabasco",
             "Veracruz","Yucatán","Sonora","Querétaro","Michoacán"),
  pobreza_pct = c(26.2, 23.5, 75.5, 30.8, 66.4,
                  28.3, 19.5, 66.8, 58.9, 50.1,
                  58.6, 40.8, 25.9, 24.7, 46.0),
  pobreza_extrema = c(2.1, 1.8, 29.7, 3.8, 25.1,
                      3.5, 1.2, 27.3, 12.5, 9.8,
                      15.3, 6.2, 2.9, 2.3, 8.5),
  poblacion = c(1425000, 3769000, 5543000, 9210000, 3540000,
                8348000, 5784000, 4132000, 6584000, 2395000,
                8112000, 2320000, 2944000, 2368000, 4748000),
  region = c("Centro","Norte","Sur","Centro","Sur",
             "Occidente","Norte","Sur","Centro","Sur",
             "Sur","Sureste","Norte","Centro","Occidente")
)

# 1. Filtra los estados con pobreza mayor a 50%
estados_pobres <- estados %>%
  filter(___)

# 2. Selecciona solo estado, pobreza_pct y region
estados %>%
  select(___, ___, ___)

# 3. Crea una nueva columna con la población en pobreza (número absoluto)
estados %>%
  mutate(pob_en_pobreza = ___ * ___ / 100)

# 4. Ordena de mayor a menor pobreza extrema
estados %>%
  arrange(desc(___))

# 5. Calcula el promedio de pobreza por región
estados %>%
  group_by(___) %>%
  summarise(
    promedio_pobreza = mean(___),
    n_estados = n()
  )

# 6. DESAFÍO: En un solo pipeline, filtra estados del Sur,
#    calcula pobreza total (pobreza + extrema),
#    y ordena de mayor a menor
estados %>%
  filter(___) %>%
  mutate(___) %>%
  arrange(___)
```

### Ejercicio 4.2: Primera gráfica con ggplot
```r
# Usando los datos del ejercicio anterior, crea una gráfica de barras
# de pobreza por estado, ordenada de mayor a menor

estados %>%
  ggplot(aes(x = reorder(estado, pobreza_pct), y = pobreza_pct)) +
  geom____() +
  coord_flip() +
  labs(
    title = "___",
    x = "___",
    y = "___"
  ) +
  theme_minimal()
```

---

## Sesión 05: Práctica del tidyverse

### Ejercicio 5.1: Joins y pivot
```r
library(tidyverse)

# Tabla 1: Datos de empleo por estado
empleo <- tibble(
  cve_ent = c("01","02","03","04","05","06","07","08"),
  estado = c("Aguascalientes","Baja California","Baja California Sur",
             "Campeche","Coahuila","Colima","Chiapas","Chihuahua"),
  tasa_desempleo = c(3.2, 2.8, 2.1, 4.5, 3.9, 3.0, 2.5, 3.7),
  pea = c(580000, 1750000, 420000, 380000, 1350000, 370000, 1980000, 1650000)
)

# Tabla 2: Datos de educación por estado
educacion <- tibble(
  cve_ent = c("01","02","03","05","06","07","08","09"),
  escolaridad_promedio = c(10.5, 10.2, 10.8, 10.9, 10.1, 7.8, 10.3, 11.5),
  pct_universidad = c(22.1, 19.8, 24.5, 21.3, 18.7, 12.3, 20.9, 32.1)
)

# 1. Haz un left_join. ¿Cuántas filas tiene el resultado? ¿Por qué?
resultado_left <- left_join(empleo, educacion, by = "___")
nrow(resultado_left)

# 2. Haz un inner_join. ¿Cuántas filas tiene? ¿Qué estados se perdieron?
resultado_inner <- inner_join(empleo, educacion, by = "___")
nrow(resultado_inner)

# 3. ¿Qué estado está en educacion pero no en empleo?
# Pista: usa anti_join()
anti_join(educacion, empleo, by = "___")

# 4. Pivot: Transforma los datos de formato ancho a largo
datos_ancho <- tibble(
  estado = c("CDMX", "Jalisco", "NL"),
  pobreza_2020 = c(33.2, 28.9, 20.1),
  pobreza_2022 = c(31.5, 30.1, 19.8),
  pobreza_2024 = c(30.8, 28.3, 19.5)
)

# Convierte a formato largo con pivot_longer
datos_largo <- datos_ancho %>%
  pivot_longer(
    cols = starts_with("___"),
    names_to = "___",
    values_to = "___"
  )

# 5. ¿Para qué tipo de gráfica necesitas formato largo?
# R: ___
```

### Ejercicio 5.2: case_when y agrupaciones
```r
library(tidyverse)

set.seed(123)
alumnos <- tibble(
  id = 1:50,
  nombre = paste("Alumno", 1:50),
  calificacion = round(runif(50, 40, 100), 1),
  asistencia_pct = round(runif(50, 50, 100), 0),
  grupo = sample(c("A","B","C"), 50, replace = TRUE)
)

# 1. Usa case_when para crear una columna de "nivel"
alumnos <- alumnos %>%
  mutate(
    nivel = case_when(
      calificacion >= 90 ~ "___",
      calificacion >= 80 ~ "___",
      calificacion >= 70 ~ "___",
      TRUE ~ "___"
    )
  )

# 2. ¿Cuántos alumnos hay en cada nivel?
alumnos %>%
  group_by(___) %>%
  count()

# 3. Calcula promedio de calificación y asistencia por grupo
alumnos %>%
  group_by(___) %>%
  summarise(
    promedio_cal = ___,
    promedio_asist = ___,
    n_alumnos = ___
  )

# 4. ¿Cuál es el grupo con mejor promedio?
# Escribe el pipeline:
___

# 5. Crea una columna "aprobado" (TRUE si calificación >= 70 Y asistencia >= 80)
alumnos %>%
  mutate(aprobado = ___)
```

---

## Sesión 06: Práctica de ggplot2

### Ejercicio 6.1: Cuarteto de Anscombe
```r
library(tidyverse)

# R tiene el cuarteto de Anscombe integrado
data("anscombe")

# 1. Calcula media, varianza y correlación para cada par (x1,y1), (x2,y2), etc.
# ¿Qué observas?
mean(anscombe$x1)
mean(anscombe$x2)
var(anscombe$y1)
var(anscombe$y2)
cor(anscombe$x1, anscombe$y1)
cor(anscombe$x2, anscombe$y2)

# 2. Ahora grafica cada par. ¿Las gráficas se parecen a las estadísticas?
# Transforma a formato largo para usar facet_wrap
anscombe_largo <- anscombe %>%
  pivot_longer(everything(),
               names_to = c(".value", "set"),
               names_pattern = "(.)(.)")

ggplot(anscombe_largo, aes(x = x, y = y)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~set) +
  labs(title = "Cuarteto de Anscombe",
       subtitle = "Mismas estadísticas, gráficas muy diferentes") +
  theme_minimal()

# 3. ¿Qué lección nos enseña esto sobre el análisis de datos?
# R: ___
```

### Ejercicio 6.2: Construyendo gráficas paso a paso
```r
library(tidyverse)

# Datos de emisiones de CO2 por país (simulados)
emisiones <- tibble(
  pais = rep(c("México","Brasil","Argentina","Colombia","Chile"), each = 5),
  anio = rep(2020:2024, 5),
  co2_millones_ton = c(
    480,475,470,465,460,  # México
    450,440,430,420,410,  # Brasil
    180,178,175,170,168,  # Argentina
    95,93,90,88,85,       # Colombia
    85,83,80,78,75        # Chile
  )
)

# Paso 1: Gráfica básica de líneas
p1 <- ggplot(emisiones, aes(x = anio, y = co2_millones_ton, color = pais)) +
  geom_line()
p1

# Paso 2: Agrega puntos
p2 <- p1 + geom_point(size = ___)
p2

# Paso 3: Mejora etiquetas
p3 <- p2 +
  labs(
    title = "___",
    subtitle = "___",
    x = "___",
    y = "___",
    color = "___",
    caption = "Datos simulados para ejercicio"
  )
p3

# Paso 4: Agrega un tema
p4 <- p3 + theme_minimal()
p4

# Paso 5: Personaliza el tema
p5 <- p4 +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "bottom"
  )
p5

# Paso 6: Guarda la gráfica
ggsave("emisiones_latam.png", p5, width = 10, height = 6, dpi = 200)
```

---

## Sesión 07: Teoría de ggplot2

### Ejercicio 7.1: Tipos de geometrías
```r
library(tidyverse)

# Datos simulados de accidentes de tránsito
set.seed(42)
accidentes <- tibble(
  municipio = rep(c("Monterrey","Guadalajara","CDMX","Puebla","Tijuana"), each = 12),
  mes = rep(1:12, 5),
  total_accidentes = rpois(60, lambda = rep(c(450, 380, 520, 280, 350), each = 12)),
  heridos = rpois(60, lambda = rep(c(120, 95, 180, 70, 90), each = 12)),
  tipo_zona = sample(c("Urbana","Suburbana"), 60, replace = TRUE, prob = c(0.7, 0.3))
)

# 1. Gráfica de barras: total de accidentes por municipio (todo el año)
accidentes %>%
  group_by(municipio) %>%
  summarise(total = sum(total_accidentes)) %>%
  ggplot(aes(x = reorder(municipio, total), y = total)) +
  geom_col(fill = "___") +
  coord_flip() +
  labs(title = "Total de accidentes por municipio") +
  theme_minimal()

# 2. Gráfica de puntos: relación accidentes vs heridos
ggplot(accidentes, aes(x = total_accidentes, y = heridos, color = municipio)) +
  geom_point(alpha = 0.7, size = 3) +
  labs(title = "___") +
  theme_minimal()

# 3. Gráfica de líneas: evolución mensual por municipio
accidentes %>%
  ggplot(aes(x = mes, y = total_accidentes, color = municipio)) +
  geom_line(linewidth = 1) +
  scale_x_continuous(breaks = 1:12) +
  labs(title = "___") +
  theme_minimal()

# 4. Boxplot: distribución de accidentes por tipo de zona
ggplot(accidentes, aes(x = tipo_zona, y = total_accidentes, fill = tipo_zona)) +
  geom_boxplot() +
  labs(title = "___") +
  theme_minimal()
```

### Ejercicio 7.2: janitor y stringr
```r
library(tidyverse)
library(janitor)

# Datos con nombres feos (como llegarían de un Excel real)
datos_sucios <- tibble(
  `Nombre Completo` = c("Ana García", "luis LÓPEZ", "CARLOS Ruiz"),
  `Año de Nacimiento` = c(1995, 1998, 2000),
  `% Asistencia` = c(95.5, 88.2, 92.1),
  `Ingreso Mensual ($MXN)` = c(15000, 22000, 18500)
)

# 1. Limpia los nombres con clean_names()
datos_limpios <- datos_sucios %>% ___

# 2. Verifica los nuevos nombres
names(datos_limpios)

# 3. Usa str_c() para crear un saludo personalizado
datos_limpios %>%
  mutate(saludo = str_c("Hola, ", ___, ". Tu ingreso es $", ___))

# 4. Usa str_to_title() para estandarizar los nombres
datos_limpios %>%
  mutate(nombre_completo = str_to_title(___))

# 5. Usa case_when para clasificar el ingreso
datos_limpios %>%
  mutate(
    nivel_ingreso = case_when(
      ___ > 20000 ~ "Alto",
      ___ > 15000 ~ "Medio",
      TRUE ~ "Bajo"
    )
  )
```

---

## Sesión 08: Visualización de datos

### Ejercicio 8.1: Principios de visualización
```r
library(tidyverse)

# Datos de presupuesto público por sector
presupuesto <- tibble(
  sector = c("Salud","Educación","Seguridad","Infraestructura",
             "Bienestar Social","Ciencia","Cultura","Deporte"),
  monto_mdp = c(180000, 365000, 195000, 142000, 420000, 35000, 18000, 12000),
  cambio_pct = c(5.2, -2.1, 8.5, -5.3, 12.1, -10.5, 1.2, -3.8)
)

# 1. Crea una gráfica de barras horizontales ordenada
#    ¿Por qué las barras horizontales son mejores para categorías con texto largo?
presupuesto %>%
  ggplot(aes(x = reorder(sector, monto_mdp), y = monto_mdp / 1000)) +
  geom_col(fill = "#6950D8") +
  coord_flip() +
  labs(title = "Presupuesto público por sector",
       x = NULL,
       y = "Miles de millones de pesos") +
  theme_minimal()

# 2. Crea una gráfica que muestre el cambio porcentual
#    Usa colores diferentes para positivo (verde) y negativo (rojo)
presupuesto %>%
  mutate(color_cambio = ifelse(cambio_pct > 0, "Aumento", "Reducción")) %>%
  ggplot(aes(x = reorder(sector, cambio_pct), y = cambio_pct, fill = color_cambio)) +
  geom_col() +
  scale_fill_manual(values = c("Aumento" = "___", "Reducción" = "___")) +
  coord_flip() +
  labs(title = "___",
       subtitle = "Variación porcentual respecto al año anterior",
       x = NULL, y = "Cambio (%)", fill = NULL) +
  theme_minimal()

# 3. REFLEXIÓN: ¿Qué tipo de gráfica sería INADECUADA para estos datos y por qué?
#    (Piensa en: pie chart, 3D, etc.)
# R: ___
```

---

## Sesión 09: Facetas y programación

### Ejercicio 9.1: Small multiples
```r
library(tidyverse)

# Datos de PIB trimestral por país (simulados)
set.seed(2026)
pib_latam <- tibble(
  pais = rep(c("México","Brasil","Colombia","Argentina","Chile","Perú"), each = 20),
  trimestre = rep(paste0(rep(2020:2024, each = 4), "-T", 1:4), 6),
  pib_index = c(
    cumsum(c(100, rnorm(19, 0.8, 1.5))),
    cumsum(c(100, rnorm(19, 0.5, 2.0))),
    cumsum(c(100, rnorm(19, 0.7, 1.8))),
    cumsum(c(100, rnorm(19, -0.2, 3.0))),
    cumsum(c(100, rnorm(19, 0.9, 1.2))),
    cumsum(c(100, rnorm(19, 0.6, 1.6)))
  )
)

# 1. Crea un spaghetti plot (todas las líneas juntas)
ggplot(pib_latam, aes(x = trimestre, y = pib_index, color = pais, group = pais)) +
  geom_line() +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, size = 6))

# 2. Ahora separa con facet_wrap
ggplot(pib_latam, aes(x = trimestre, y = pib_index, group = pais)) +
  geom_line(color = "#6950D8") +
  facet_wrap(~___, ncol = 3, scales = "free_y") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, size = 5))

# Pregunta: ¿Qué hace scales = "free_y"? ¿Cuándo conviene usarlo?
# R: ___
```

### Ejercicio 9.2: Funciones y loops
```r
library(tidyverse)

# Datos de ventas por tienda
set.seed(42)
tiendas <- c("CDMX Centro","CDMX Sur","Monterrey","Guadalajara","Puebla","Mérida")
ventas <- tibble(
  tienda = rep(tiendas, each = 12),
  mes = rep(month.abb, 6),
  mes_num = rep(1:12, 6),
  ventas_miles = round(rnorm(72, mean = rep(c(500,380,420,350,280,220), each=12), sd = 50), 0)
)

# 1. Crea una función que genere una gráfica para UNA tienda
grafica_tienda <- function(datos, nombre_tienda) {
  datos %>%
    filter(tienda == ___) %>%
    ggplot(aes(x = mes_num, y = ventas_miles)) +
    geom_line(color = "#6950D8", linewidth = 1.2) +
    geom_point(color = "#6950D8", size = 3) +
    scale_x_continuous(breaks = 1:12, labels = month.abb) +
    labs(
      title = str_c("Ventas mensuales: ", ___),
      x = "Mes",
      y = "Ventas (miles de pesos)"
    ) +
    theme_minimal()
}

# 2. Prueba la función con una tienda
grafica_tienda(ventas, "CDMX Centro")

# 3. Usa un loop para generar gráficas de TODAS las tiendas
for (t in ___) {
  p <- grafica_tienda(ventas, t)
  nombre_archivo <- str_c("grafica_", str_replace_all(t, " ", "_"), ".png")
  ggsave(nombre_archivo, p, width = 10, height = 6, dpi = 200)
  print(str_c("Guardada: ", nombre_archivo))
}

# 4. DESAFÍO: Modifica la función para que el color sea un parámetro
grafica_tienda_v2 <- function(datos, nombre_tienda, color = "#6950D8") {
  # Escribe tu código aquí
  ___
}
```

---

## Sesión 10: Estadística descriptiva y análisis exploratorio

### Ejercicio 10.1: EDA completo
```r
library(tidyverse)

# Datos simulados de empleados
set.seed(2026)
n <- 200
empleados <- tibble(
  id = 1:n,
  edad = round(rnorm(n, 35, 10)),
  ingreso = round(rlnorm(n, log(25000), 0.5)),
  escolaridad = sample(c("Primaria","Secundaria","Preparatoria","Universidad","Posgrado"),
                       n, replace = TRUE, prob = c(0.05, 0.15, 0.25, 0.40, 0.15)),
  genero = sample(c("M","F"), n, replace = TRUE),
  departamento = sample(c("Ventas","TI","RRHH","Finanzas","Operaciones"), n, replace = TRUE),
  antiguedad_anios = round(runif(n, 0.5, 25), 1),
  satisfaccion = sample(1:10, n, replace = TRUE)
)

# Introducir algunos NAs
empleados$ingreso[sample(1:n, 15)] <- NA
empleados$satisfaccion[sample(1:n, 10)] <- NA

# 1. Exploración inicial
str(empleados)
summary(empleados)

# 2. ¿Cuántos NAs hay por columna?
colSums(is.na(___))

# 3. Estadísticas descriptivas del ingreso
mean(empleados$ingreso, na.rm = ___)
median(empleados$ingreso, na.rm = ___)
sd(empleados$ingreso, na.rm = ___)
IQR(empleados$ingreso, na.rm = ___)

# 4. ¿La media es mayor o menor que la mediana? ¿Qué sugiere eso sobre la distribución?
# R: ___

# 5. Visualiza la distribución del ingreso
ggplot(empleados, aes(x = ingreso)) +
  geom_histogram(bins = 30, fill = "#6950D8", color = "white") +
  labs(title = "Distribución del ingreso") +
  theme_minimal()

# 6. Boxplot de ingreso por departamento
ggplot(empleados, aes(x = departamento, y = ingreso, fill = departamento)) +
  geom_boxplot() +
  theme_minimal() +
  theme(legend.position = "none")

# 7. Detección de outliers con regla IQR
Q1 <- quantile(empleados$ingreso, 0.25, na.rm = TRUE)
Q3 <- quantile(empleados$ingreso, 0.75, na.rm = TRUE)
IQR_val <- Q3 - Q1
limite_inferior <- Q1 - 1.5 * ___
limite_superior <- Q3 + 1.5 * ___

outliers <- empleados %>%
  filter(ingreso < limite_inferior | ingreso > limite_superior)
nrow(outliers)  # ¿Cuántos outliers hay?

# 8. Correlación entre edad e ingreso
cor(empleados$edad, empleados$ingreso, use = "complete.obs")
# ¿Es una correlación fuerte o débil? ¿Positiva o negativa?
# R: ___
```

### Ejercicio 10.2: Manejo de datos faltantes
```r
library(tidyverse)

# Usando los datos de empleados del ejercicio anterior

# 1. Estrategia 1: Eliminar filas con NA
empleados_sin_na <- empleados %>% drop_na()
nrow(empleados_sin_na)  # ¿Cuántas filas se perdieron?

# 2. Estrategia 2: Imputar con la mediana
mediana_ingreso <- median(empleados$ingreso, na.rm = TRUE)
empleados_imputados <- empleados %>%
  mutate(ingreso = ifelse(is.na(ingreso), ___, ingreso))

# 3. Compara las estadísticas antes y después de imputar
# Antes:
mean(empleados$ingreso, na.rm = TRUE)
sd(empleados$ingreso, na.rm = TRUE)

# Después:
mean(empleados_imputados$ingreso)
sd(empleados_imputados$ingreso)

# 4. ¿Por qué la mediana es mejor que la media para imputar datos con sesgo?
# R: ___

# 5. DESAFÍO: Imputación por grupo (mediana del departamento)
empleados_imputados_grupo <- empleados %>%
  group_by(___) %>%
  mutate(ingreso = ifelse(is.na(ingreso),
                          median(ingreso, na.rm = TRUE),
                          ingreso)) %>%
  ungroup()
```

---

## Sesión 11: Causalidad en ciencias sociales

### Ejercicio 11.1: Correlación vs. causalidad
```r
library(tidyverse)

# Ejemplo clásico: helados y ahogamientos
set.seed(42)
meses <- tibble(
  mes = 1:12,
  temperatura = c(12, 14, 18, 22, 27, 32, 35, 34, 30, 24, 18, 13),
  ventas_helado = c(200, 250, 400, 600, 900, 1200, 1500, 1400, 1000, 500, 300, 180),
  ahogamientos = c(5, 6, 10, 18, 30, 45, 55, 50, 35, 15, 8, 4)
)

# 1. Calcula la correlación entre ventas de helado y ahogamientos
cor(meses$ventas_helado, meses$ahogamientos)

# 2. Grafica la relación
ggplot(meses, aes(x = ventas_helado, y = ahogamientos)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "¿Los helados causan ahogamientos?",
       x = "Ventas de helado", y = "Ahogamientos") +
  theme_minimal()

# 3. ¿Cuál es la variable confusora (confounding) aquí?
# R: ___

# 4. Si agregas temperatura como control, ¿qué esperas que pase con la correlación?
cor(residuals(lm(ahogamientos ~ temperatura, data = meses)),
    residuals(lm(ventas_helado ~ temperatura, data = meses)))

# 5. ¿Qué pasó con la correlación? ¿Qué concluyes?
# R: ___
```

### Ejercicio 11.2: Diferencias en Diferencias (DiD)
```r
library(tidyverse)

# Simulación: Efecto de un programa de becas en calificaciones
set.seed(2026)
n <- 100
did_data <- tibble(
  id = 1:n,
  tratamiento = rep(c(0, 1), each = n/2),  # 0=control, 1=con beca
  periodo = rep(c(0, 0, 1, 1), n/4),        # 0=antes, 1=después
  calificacion = 70 +
    5 * tratamiento +       # Diferencia inicial entre grupos
    3 * periodo +            # Tendencia temporal
    8 * tratamiento * periodo + # EFECTO DEL TRATAMIENTO (DiD)
    rnorm(n, 0, 5)           # Ruido
)

# 1. Calcula promedios por grupo y periodo
did_data %>%
  group_by(tratamiento, periodo) %>%
  summarise(promedio = mean(calificacion))

# 2. Calcula el estimador DiD manualmente
#    DiD = (Tratamiento_después - Tratamiento_antes) - (Control_después - Control_antes)
promedios <- did_data %>%
  group_by(tratamiento, periodo) %>%
  summarise(promedio = mean(calificacion)) %>%
  pivot_wider(names_from = periodo, values_from = promedio,
              names_prefix = "periodo_")

did_estimador <- (promedios$periodo_1[2] - promedios$periodo_0[2]) -
                 (promedios$periodo_1[1] - promedios$periodo_0[1])
print(str_c("Estimador DiD: ", round(did_estimador, 2)))

# 3. Verifica con regresión
modelo_did <- lm(calificacion ~ tratamiento * periodo, data = did_data)
summary(modelo_did)

# 4. ¿Cuál coeficiente de la regresión corresponde al efecto DiD?
# R: ___

# 5. ¿El programa de becas tuvo un efecto significativo? ¿De cuántos puntos?
# R: ___
```

---

## Sesión 12: Regresión lineal

### Ejercicio 12.1: Regresión simple y múltiple
```r
library(tidyverse)

# Datos simulados de municipios
set.seed(2026)
n <- 300
municipios_reg <- tibble(
  ingreso_pc = rnorm(n, 120000, 40000),
  escolaridad = rnorm(n, 9, 2.5),
  pct_empleo_formal = rnorm(n, 55, 15),
  acceso_salud = rnorm(n, 70, 15),
  pobreza = 80 - 0.0003 * ingreso_pc - 2.5 * escolaridad -
            0.3 * pct_empleo_formal - 0.2 * acceso_salud + rnorm(n, 0, 5)
)
municipios_reg$pobreza <- pmax(0, pmin(100, municipios_reg$pobreza))

# 1. Regresión simple: pobreza ~ escolaridad
modelo_simple <- lm(pobreza ~ ___, data = municipios_reg)
summary(modelo_simple)

# 2. Interpreta el coeficiente de escolaridad
# R: Por cada año adicional de escolaridad, la pobreza ___

# 3. ¿Cuál es el R² del modelo simple?
# R: ___

# 4. Regresión múltiple: pobreza ~ todas las variables
modelo_multiple <- lm(pobreza ~ ___ + ___ + ___ + ___,
                      data = municipios_reg)
summary(modelo_multiple)

# 5. ¿Mejoró el R²? ¿Cuánto?
# R: ___

# 6. ¿Cuál variable tiene el efecto más grande (estandarizado)?
# Pista: compara los valores t
# R: ___

# 7. Gráfica de diagnóstico: residuos vs ajustados
plot(modelo_multiple, which = 1)
# ¿Qué buscas en esta gráfica?
# R: ___

# 8. Haz una predicción para un municipio con:
#    ingreso_pc=150000, escolaridad=11, empleo_formal=65, acceso_salud=80
nuevo_municipio <- tibble(
  ingreso_pc = 150000,
  escolaridad = 11,
  pct_empleo_formal = 65,
  acceso_salud = 80
)
predict(modelo_multiple, newdata = ___)
```

### Ejercicio 12.2: Ridge y Lasso
```r
library(tidyverse)
library(glmnet)

# Usando los datos anteriores
X <- as.matrix(municipios_reg %>% select(-pobreza))
y <- municipios_reg$pobreza

# 1. Divide en entrenamiento (80%) y prueba (20%)
set.seed(42)
indices <- sample(1:nrow(municipios_reg), 0.8 * nrow(municipios_reg))
X_train <- X[indices, ]
X_test <- X[-indices, ]
y_train <- y[indices]
y_test <- y[-indices]

# 2. Modelo Ridge (alpha = 0)
cv_ridge <- cv.glmnet(X_train, y_train, alpha = ___)
plot(cv_ridge)
mejor_lambda_ridge <- cv_ridge$lambda.min
print(str_c("Mejor lambda Ridge: ", round(mejor_lambda_ridge, 4)))

# 3. Modelo Lasso (alpha = 1)
cv_lasso <- cv.glmnet(X_train, y_train, alpha = ___)
mejor_lambda_lasso <- cv_lasso$lambda.min

# 4. Compara coeficientes
coef(cv_ridge, s = "lambda.min")
coef(cv_lasso, s = "lambda.min")
# ¿Algún coeficiente de Lasso es exactamente 0? ¿Cuál?
# R: ___

# 5. Compara predicciones en datos de prueba
pred_ridge <- predict(cv_ridge, X_test, s = "lambda.min")
pred_lasso <- predict(cv_lasso, X_test, s = "lambda.min")

rmse_ridge <- sqrt(mean((y_test - pred_ridge)^2))
rmse_lasso <- sqrt(mean((y_test - pred_lasso)^2))
print(str_c("RMSE Ridge: ", round(rmse_ridge, 2)))
print(str_c("RMSE Lasso: ", round(rmse_lasso, 2)))
# ¿Cuál modelo es mejor según RMSE?
# R: ___
```

---

## Sesión 13: Conceptos de Machine Learning

### Ejercicio 13.1: Train/Test Split y sobreajuste
```r
library(tidyverse)

# Datos simulados: relación no lineal
set.seed(2026)
n <- 100
datos_ml <- tibble(
  x = seq(0, 10, length.out = n),
  y = sin(x) + rnorm(n, 0, 0.3)
)

# 1. Divide en train (80%) y test (20%)
set.seed(42)
idx_train <- sample(1:n, 0.8 * n)
train <- datos_ml[idx_train, ]
test <- datos_ml[-idx_train, ]

# 2. Modelo simple (lineal)
modelo_1 <- lm(y ~ x, data = train)

# 3. Modelo complejo (polinomio grado 15)
modelo_15 <- lm(y ~ poly(x, 15), data = train)

# 4. Calcula RMSE en ENTRENAMIENTO
rmse_train_1 <- sqrt(mean(residuals(modelo_1)^2))
rmse_train_15 <- sqrt(mean(residuals(modelo_15)^2))
print(str_c("RMSE train - Lineal: ", round(rmse_train_1, 4)))
print(str_c("RMSE train - Polinomio 15: ", round(rmse_train_15, 4)))

# 5. Calcula RMSE en PRUEBA
pred_test_1 <- predict(modelo_1, newdata = test)
pred_test_15 <- predict(modelo_15, newdata = test)
rmse_test_1 <- sqrt(mean((test$y - pred_test_1)^2))
rmse_test_15 <- sqrt(mean((test$y - pred_test_15)^2))
print(str_c("RMSE test - Lineal: ", round(rmse_test_1, 4)))
print(str_c("RMSE test - Polinomio 15: ", round(rmse_test_15, 4)))

# 6. ¿Qué modelo tiene mejor desempeño en ENTRENAMIENTO?
# R: ___

# 7. ¿Qué modelo tiene mejor desempeño en PRUEBA?
# R: ___

# 8. ¿Qué fenómeno observas? (pista: empieza con "sobre...")
# R: ___

# 9. Visualiza ambos modelos
ggplot(datos_ml, aes(x, y)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE, color = "blue", aes(linetype = "Lineal")) +
  geom_smooth(method = "lm", formula = y ~ poly(x, 15), se = FALSE, color = "red",
              aes(linetype = "Polinomio 15")) +
  labs(title = "Subajuste vs Sobreajuste",
       subtitle = "Azul = muy simple, Rojo = muy complejo") +
  theme_minimal()
```

### Ejercicio 13.2: Validación cruzada
```r
library(tidyverse)

# Implementación manual de k-fold cross-validation
set.seed(2026)
n <- 200
datos_cv <- tibble(
  x1 = rnorm(n),
  x2 = rnorm(n),
  x3 = rnorm(n),
  y = 3 + 2*x1 - 1.5*x2 + 0.8*x3 + rnorm(n, 0, 1)
)

# K-fold CV con k = 5
k <- 5
folds <- sample(rep(1:k, length.out = n))
rmse_folds <- numeric(k)

for (i in 1:k) {
  # Separar train y validation para este fold
  train_cv <- datos_cv[folds != i, ]
  val_cv <- datos_cv[folds == i, ]

  # Ajustar modelo
  modelo_cv <- lm(y ~ x1 + x2 + x3, data = ___)

  # Predecir en validation
  pred_cv <- predict(modelo_cv, newdata = ___)

  # Calcular RMSE
  rmse_folds[i] <- sqrt(mean((val_cv$y - pred_cv)^2))
  print(str_c("Fold ", i, " RMSE: ", round(rmse_folds[i], 4)))
}

# RMSE promedio de los k folds
mean(rmse_folds)

# Pregunta: ¿Por qué k-fold CV es mejor que un solo train/test split?
# R: ___

# Pregunta: ¿Qué valores de k son más comunes?
# R: ___
```

---

## Respuestas rápidas (referencia)

Las respuestas están en la base de conocimientos (`base_conocimientos.md`). Estas son pistas para los ejercicios más difíciles:

- **Ej. 5.1:** `anti_join()` devuelve filas que NO tienen coincidencia
- **Ej. 11.1:** La variable confusora es la temperatura
- **Ej. 11.2:** El coeficiente de `tratamiento:periodo` es el DiD
- **Ej. 12.2:** `alpha = 0` para Ridge, `alpha = 1` para Lasso
- **Ej. 13.1:** El polinomio 15 sobreajusta: buen RMSE en train, malo en test
- **Ej. 13.2:** k-fold CV da estimación más robusta porque usa todos los datos

---

*Generado como material de estudio para TC2001B.601 — Ciencia de datos para la toma de decisiones I*
