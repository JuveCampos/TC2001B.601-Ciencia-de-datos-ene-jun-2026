# Base de Conocimientos — Ciencia de Datos TC2001B.601

**Curso:** Ciencia de datos para la toma de decisiones I
**Institución:** Tecnológico de Monterrey — Escuela de Ciencias Sociales y Gobierno
**Profesor:** Jorge Juvenal Campos Ferreira (juvenal.campos@tec.mx)
**Periodo:** Enero–Junio 2026
**Herramientas principales:** R, RStudio, Python

---

## Sesión 1: Presentación del curso

### Temas cubiertos
- Presentación del profesor y del curso
- Objetivos de aprendizaje
- Herramientas a utilizar (R, RStudio, Python)
- Contexto del programa: políticas públicas y tecnologías digitales

### Conceptos clave
- **Ciencia de datos para la toma de decisiones:** disciplina orientada a mejorar decisiones de política pública mediante el análisis cuantitativo
- **Propósito del curso:** impulsar transformaciones públicas de alto impacto con tecnologías digitales
- **Objetivos:** mejorar programación en R, comprender fundamentos de CD/estadística/ML, practicar modelos estadísticos

### Funciones y paquetes de R utilizados
- Introducción general a R y RStudio (sin funciones específicas en esta sesión)

### Ejercicios prácticos
- `codigo_sesion_01.R`: Operaciones aritméticas básicas, asignación de variables con `<-`, funciones matemáticas (`sqrt()`, `abs()`, `round()`), creación de vectores con `c()`, tipos de datos (numeric, character, logical)
- Paquetes introducidos: `plotly`, `tidyverse`

### Preguntas potenciales para examen
1. ¿Cuáles son los tres objetivos principales del curso?
2. ¿Qué herramientas de programación se utilizan en el curso y para qué sirve cada una?
3. ¿Cómo se asigna una variable en R? ¿Cuál es la diferencia entre `<-` y `=`?
4. ¿Qué tipos de datos escalares existen en R?
5. ¿Cómo se crea un vector en R?

---

## Sesión 2: Introducción a la ciencia de datos

### Temas cubiertos
- Definición de dato (perspectiva CD vs. ciencias sociales)
- Datos cuantitativos vs. cualitativos
- Metadatos
- Definición de ciencia de datos
- Objetivo de la ciencia de datos
- Valor de los datos en la política pública (escalera analítica)
- Tipos de análisis de datos
- El proceso de trabajo con datos (ciclo de Hadley Wickham)
- Por qué aprender a programar
- La explosión de los datos (crecimiento 74x entre 2010-2023)
- Tareas que se hacen con datos
- Estructura de un código en R

### Conceptos clave
- **Dato (CD):** colección de hechos, cifras, palabras, observaciones u otra información útil que debe ser procesada para generar insights
- **Dato (ciencias sociales):** representación de la realidad social obtenida a través de un proceso de observación o medición
- **Metadatos:** datos sobre los datos; información estructurada que describe, contextualiza o documenta otros datos
- **Ciencia de datos:** campo interdisciplinario que combina estadística, matemáticas, programación, IA y conocimiento del dominio para extraer información útil
- **Escalera analítica:** Descriptiva (1990) → Diagnóstica (2000-2005) → Predictiva (2005-2010) → Prescriptiva (2010-2020) → Cognitiva (futuro)
- **Tipos de análisis:** descriptivo (¿qué pasó?), de causalidad (¿por qué pasó?), predictivo (¿qué pasará?), prescriptivo (¿qué se debería hacer?)
- **Ciclo de datos (Wickham):** Importar → Limpiar → Transformar ↔ Visualizar ↔ Modelar → Comunicar y difundir

### Funciones y paquetes de R utilizados
- Tareas mencionadas: manejo de datos con `tidyverse`, análisis estadístico con `base` y `MASS`, ML con `e1071`, `tensorflow`, `caret`, `rpart`
- Estructura sugerida de script: 10 secciones (configuración, librerías, parámetros, carga, limpieza, EDA, funciones, modelos, gráficas, guardado)

### Ejercicios prácticos
- `ejercicio_02.R`: Carga de CSV y Excel con `read_csv()` y `read_xlsx()`, acceso a columnas con `$`, cálculo de `mean()`
- `ejercicio_carga_archivos.R`: Carga comprehensiva de múltiples formatos (CSV, Excel, RDS, Parquet, XML, Stata, SPSS, GeoJSON, KML, Shapefile, SQLite)
- Paquetes: `readr`, `readxl`, `haven`, `foreign`, `sf`, `arrow`, `xml2`, `RSQLite`, `DBI`

### Preguntas potenciales para examen
1. ¿Cuál es la diferencia entre un dato desde la perspectiva de ciencia de datos y desde las ciencias sociales?
2. ¿Qué son los metadatos? Da un ejemplo.
3. Describe las 4 etapas de la escalera analítica de datos y qué pregunta responde cada una.
4. ¿Cuáles son los pasos del ciclo de trabajo con datos según Hadley Wickham?
5. Menciona 3 razones por las que es importante aprender a programar para el análisis de datos.
6. ¿Cuáles son las 10 secciones sugeridas para un script de R?

---

## Sesión 3: Importando datos desde archivos

### Temas cubiertos
- Continuación del ejercicio de importación de datos
- Tipos de variables en R
- Funciones para trabajar con valores numéricos (estadísticas)
- Configuración de un proyecto básico de R
- Directorio de trabajo
- Rutas globales vs. rutas relativas
- Ubicaciones de archivos (local vs. internet)
- Librerías para importar datos
- Formas de importar datos (asistente vs. código)
- Tipos de archivos más utilizados

### Conceptos clave
- **Directorio de trabajo:** la carpeta en la computadora donde R busca y guarda archivos
- **Ruta global (absoluta):** ruta única y completa de un archivo en la computadora
- **Ruta relativa:** ruta relativa a otra ubicación; mejora la replicabilidad del código
- **Archivo .Rproj:** archivo de proyecto de RStudio que establece el directorio de trabajo automáticamente (método recomendado)
- **Estructura de proyecto:** carpeta raíz con .Rproj, subcarpetas Data (datos), Script (código), Output (resultados: plots, datos, reportes)
- **Archivos de datos:** información tabular (CSV, Excel, SPSS, JSON), objetos de R (RDS, RData), información geográfica (TIFF, GeoJSON, SHP, KML), otros formatos (MongoDB, SQL)
- **3 formas de crear rutas relativas:** `setwd()`, `here::here()`, archivos de proyecto .Rproj (recomendado)

### Funciones y paquetes de R utilizados
- `library(readr)`: archivos texto plano — `read_csv()`
- `library(readxl)`: archivos Excel — `read_excel()`
- `library(haven)`: archivos Stata/SAS/SPSS — `read_dta()`, `read_sav()`
- `library(foreign)`: archivos Stata/SAS/SPSS (alternativa)
- `library(sf)`: archivos geográficos — `st_read()`
- `getwd()`, `setwd()`: gestión de directorio de trabajo
- `file.path()`: construcción dinámica de rutas
- `here::here()`: rutas relativas al proyecto

### Ejercicios prácticos
- `cargar_todos_los_archivos.R`: Carga robusta multi-formato con manejo dinámico de rutas usando `file.path()` y `getwd()`, parseo de XML con `xml_ns()`, `xml_find_all()`, `xml_attr()`, `xml_text()`, lectura de tablas SQLite con `dbListTables()` y `dbReadTable()`
- Paquetes adicionales: `jsonlite`, `arrow`

### Preguntas potenciales para examen
1. ¿Cuál es la diferencia entre una ruta global y una ruta relativa? ¿Cuál es preferible y por qué?
2. ¿Qué paquete de R se usa para leer archivos Excel? ¿Y para archivos de Stata?
3. ¿Qué es un archivo .Rproj y por qué es la forma recomendada de manejar directorios de trabajo?
4. Describe la estructura recomendada de un proyecto de R.
5. ¿Cuáles son las dos formas de acceder a archivos en internet desde R?
6. Escribe el código para leer un archivo CSV llamado "datos.csv" ubicado en la subcarpeta "Data" de tu proyecto.

---

## Sesión 4: Procesamiento y visualización de datos

### Temas cubiertos
- Repaso de tidyverse y manejo de datos
- Repaso de visualización en ggplot
- Procesamiento de datos: definición y necesidad
- Ejemplos de procesos de datos comunes
- El tidyverse: definición y paquetes miembros
- El operador pipe (`%>%`)
- Verbos del tidyverse (dplyr)
- Visualización básica con ggplot2

### Conceptos clave
- **Procesamiento de datos:** proceso previo a la creación de análisis, modelos y visualizaciones; consiste en tomar una base de datos de una fuente primaria y convertirla en otra que cumpla nuestras necesidades
- **Tidyverse:** colección de paquetes de R diseñados para ciencia de datos que comparten filosofía de diseño, estructura de datos y gramática comunes
- **Operador pipe (`%>%`):** elemento central del tidyverse que concatena funciones; se lee como "y después"; vincula los objetos del lado izquierdo con las funciones del lado derecho
- **Atajo de teclado:** Cmd+Shift+M (Mac), Ctrl+Shift+M (Windows)
- **Tips del pipe:** (1) Si hay error en un pipeline, correr bloque por bloque hasta encontrar el error; (2) Se puede silenciar código comentando líneas dentro del pipeline

### Funciones y paquetes de R utilizados
- **Paquetes del tidyverse:** ggplot2 (visualización), dplyr (wrangling), readr (lectura), tibble (data frames modernos), stringr (strings), forcats (factores), tidyr (tidying), purrr (programación funcional)
- **Verbos dplyr:** `filter()` (filtrar renglones), `select()` (seleccionar columnas), `mutate()` (generar nuevas columnas), `arrange()` (ordenar renglones), `group_by()` (agrupar), `summarise()` (calcular resúmenes)
- **Operadores lógicos:** `==`, `!=`, `>`, `<`, `>=`, `<=`, `&` (AND), `|` (OR), `!` (NOT), `%in%` (pertenencia), `between()`, `is.na()`
- **Visualización:** `ggplot()`, `geom_point()`, `geom_smooth()`
- **I/O:** `read.csv()`, `write.csv()`, `saveRDS()`, `ggsave()`

### Ejercicios prácticos
- Ejercicio de procesamiento con datos de pobreza por entidad (`df_pob_ent2.xlsx`): cargar datos, contar filas y columnas, identificar estado con mayor pobreza en 2024, menor carencia por acceso a salud

### Preguntas potenciales para examen
1. ¿Qué es el tidyverse y cuáles son sus 8 paquetes principales?
2. Explica qué hace el operador pipe (`%>%`) y da un ejemplo.
3. Describe qué hace cada uno de los 6 verbos principales de dplyr.
4. ¿Cuál es la diferencia entre `filter()` y `select()`?
5. Escribe un pipeline que filtre un dataframe por año 2024, agrupe por entidad y calcule el promedio de pobreza.
6. ¿Qué operadores lógicos se usan para combinar condiciones en `filter()`?

---

## Sesión 5: Práctica del tidyverse

### Temas cubiertos
- Estructura de un script y buenas prácticas
- Flujo de procesamiento de datos (Import-Tidy-Transform)
- Ecosistema tidyverse en profundidad
- Práctica intensiva con verbos dplyr
- Análisis exploratorio de datos (EDA)
- Limpieza y validación de datos
- Operaciones de entrada/salida de archivos

### Conceptos clave
- **Flujo de procesamiento (Wrangle):** Importar → Tidy → Transformar; seguido de fase Understand: Visualizar ↔ Modelar → Comunicar
- **Estructura sugerida de script (10 secciones):** Configuración, librerías, parámetros/funciones propias, carga de datos, limpieza, EDA, funciones, modelos, gráficas, guardado de archivos
- **Tareas comunes de procesamiento:** conversión de tipos, manejo de NAs, eliminación de duplicados/outliers, estandarización de categorías, unión de tablas, reestructuración, agregación por grupos, renombrar columnas, reclasificar grupos, deflactar cifras, transformar valores, reconvertir columnas

### Funciones y paquetes de R utilizados
- Todos los verbos dplyr: `filter()`, `select()`, `mutate()`, `arrange()`, `group_by()`, `summarise()`
- `read.csv()`, `write.csv()`, `saveRDS()`, `library()`, `ggplot()`, `geom_point()`, `geom_smooth()`, `ggsave()`

### Ejercicios prácticos
- `ejercicio_01_codigo.R`: Análisis de indicadores de pobreza por estado mexicano con `ncol()`, `nrow()`, `select()`, `filter()`, `arrange()`, `head()`, `%in%`, `group_by()`, `summarise()`, `mean()`, `sd()`, `unique()`
- `ejercicio_02.R`: Fusión de múltiples fuentes (GRAPROES, POBREZA, PROY_POBLACION) con `left_join()`, `rename()`, `select(-c(...))`, carga remota con `read_csv(url)`
- Datos: `df_pob_ent2.xlsx` (pobreza estatal), indicadores municipales

### Preguntas potenciales para examen
1. ¿Cuáles son las 10 secciones recomendadas para un script de R?
2. Describe el flujo Import-Tidy-Transform-Understand-Communicate.
3. Escribe código que use `group_by()` y `summarise()` para calcular media y desviación estándar de pobreza por entidad.
4. ¿Cómo se combinan dos dataframes usando `left_join()`? ¿Qué parámetros necesita?
5. ¿Qué función usas para seleccionar solo ciertas columnas? ¿Y para eliminar columnas específicas?

---

## Sesión 6: Práctica de ggplot

### Temas cubiertos
- Análisis de series de tiempo con reshape de datos
- Crecimiento sectorial del PIB
- Visualización exploratoria avanzada
- Accidentes de tránsito (ATUS 2023)
- Gráficas de barras y series de tiempo multi-categoría

### Conceptos clave
- **Formato wide vs. long:** transformación de datos tabulares para facilitar análisis y visualización
- **Pivot:** operación para reestructurar tablas entre formato ancho (columnas por periodo) y largo (filas por periodo)
- **Series de tiempo multi-categoría:** gráficas con múltiples líneas diferenciadas por color para comparar tendencias entre grupos

### Funciones y paquetes de R utilizados
- `pivot_longer()`: convertir formato wide a long
- `separate()`: dividir una columna en múltiples (ej. "anio-trimestre")
- `first()`: obtener primer valor de un grupo
- `diff()`: calcular diferencias
- `clean_names()` (janitor): estandarización de nombres de columnas
- `case_when()`: mapeo condicional multi-nivel
- `factor()` con `levels`: datos categóricos ordenados
- `str_c()`: concatenación de strings con formato
- `geom_col()`, `geom_text()`, `geom_line()`: geometrías de ggplot
- `scale_color_manual()`: paletas de color personalizadas
- `theme_minimal()`: tema minimalista
- `ggbackground()` (ggimage): imagen de fondo
- `ggsave()`: exportar gráficas con dimensiones
- Paquetes: `tidyverse`, `sf`, `janitor`, `ggimage`, `ggthemes`

### Ejercicios prácticos
- `ejercicio_02.R` (PIB sectorial): Análisis de crecimiento sectorial 2019-Q4 a 2025-Q4 con `pivot_longer()`, `separate()`, cálculo de cambio porcentual
- `codigo_3.R` (ATUS 2023): Accidentes por día de semana (gráfica de barras), heridos por tipo a lo largo del año (series de tiempo), con datos `datos_atus_2023.rds`

### Preguntas potenciales para examen
1. ¿Cuál es la diferencia entre formato wide y long? ¿Qué función convierte de uno al otro?
2. Escribe código con `pivot_longer()` para convertir columnas de trimestres a formato largo.
3. ¿Para qué sirve `case_when()` y cómo se usa?
4. ¿Cómo se crea un factor ordenado en R?
5. ¿Cómo se personaliza la paleta de colores en ggplot2?

---

## Sesión 7: Teoría de ggplot

### Temas cubiertos
- Fundamentos teóricos de ggplot2
- Gramática de gráficas (Grammar of Graphics)
- Capas de ggplot: datos, estéticas, geometrías, facetas, estadísticas, coordenadas, temas
- Replicación del análisis ATUS 2023

### Conceptos clave
- **Grammar of Graphics:** marco teórico donde las visualizaciones se construyen por capas (layers)
- **Componentes de ggplot2:** `data` (datos), `aes()` (mapeo estético), `geom_*()` (geometría), `stat_*()` (transformaciones estadísticas), `facet_*()` (facetas), `coord_*()` (coordenadas), `theme_*()` (tema visual)
- **Mapeo estético (aes):** conexión entre variables de datos y propiedades visuales (posición, color, tamaño, forma)

### Funciones y paquetes de R utilizados
- Mismas que Sesión 6, replicación y profundización del análisis ATUS

### Ejercicios prácticos
- `codigo_sesion_07.R`: Réplica del análisis de accidentes de tránsito de la Sesión 6, demostrando reproducibilidad

### Preguntas potenciales para examen
1. ¿Qué es la "Grammar of Graphics" y cómo se relaciona con ggplot2?
2. Nombra las 7 capas de una gráfica de ggplot2.
3. ¿Qué es el mapeo estético (`aes()`) y cuáles son los principales parámetros que acepta?
4. ¿Cuál es la diferencia entre asignar un color dentro vs. fuera de `aes()`?

---

## Sesión 8: Visualización de datos

### Temas cubiertos
- Fundamentos de visualización de datos
- Teoría de carga cognitiva en diseño visual
- Canales visuales y su efectividad
- Marcas y canales (marks & channels)
- Tipos de datos para visualización: unidades, variables, vínculos
- Productos de visualización
- Visualización de datos con R y ggplot2
- Introducción al concepto de facetas (small multiples)

### Conceptos clave
- **Carga cognitiva:** teoría sobre cómo las representaciones visuales afectan la capacidad de procesamiento humano de información
- **Canales visuales:** formas de codificar datos (posición, color, forma, tamaño, longitud, orientación, textura)
- **Marcas (marks):** bloques visuales básicos para representar datos (puntos, líneas, áreas)
- **Small multiples (pequeños múltiplos):** conjunto de gráficas similares con los mismos ejes y escalas, diferenciándose solo en los datos que representan; facilitan la comparación
- **Datos no estructurados:** desafíos de representar y visualizar formatos no tradicionales

### Funciones y paquetes de R utilizados
- `ggplot2`: paquete principal de visualización
- `geom_line()`, `geom_point()`: geometrías de líneas y puntos
- `aes()`: mapeo estético
- Escalas de color y formateo de ejes

### Preguntas potenciales para examen
1. ¿Qué es la carga cognitiva y cómo se relaciona con el diseño de visualizaciones?
2. Nombra al menos 5 canales visuales para codificar datos.
3. ¿Qué son los "small multiples" y cuándo conviene usarlos?
4. ¿Cuál es la diferencia entre una marca (mark) y un canal visual?

---

## Sesión 9: Facetas y programación

### Temas cubiertos
- Facetas en ggplot2 (`facet_wrap()`)
- Implementación de small multiples
- Enfoques comparativos de visualización
- Introducción a programación en R: condicionales y loops
- El problema del copy-paste y la automatización
- Funciones personalizadas en R
- Generación de datos sintéticos

### Conceptos clave
- **`facet_wrap()`:** función que crea una cuadrícula de gráficas basada en una variable categórica, organizando automáticamente los subplots
- **Problema del copy-paste:** motivación para aprender programación; evitar duplicación manual de código
- **Funciones personalizadas:** bloques de código reutilizable con parámetros; validación con `stopifnot()`
- **`sapply()`:** aplicar una función a cada elemento de un vector
- **Generación de datos sintéticos:** crear datos ficticios con `set.seed()`, `expand.grid()`, `rnorm()` para reproducibilidad

### Funciones y paquetes de R utilizados
- `facet_wrap(~variable, ncol = n, scales = "free_y")`: facetado
- `scale_color_brewer(palette = "Set2")`: paletas predefinidas
- `if/else`, `for` loops: control de flujo
- `function()`: creación de funciones
- `stopifnot()`: validación de parámetros
- `sapply()`: vectorización de funciones
- `tolower()`: conversión a minúsculas
- `str_c()`: concatenación de strings
- `set.seed()`, `expand.grid()`, `rnorm()`: generación de datos
- `write_xlsx()` (writexl): guardar Excel
- Paquetes: `tidyverse`, `gapminder`, `readxl`, `writexl`

### Ejercicios prácticos
- `ejemplo_01.R`: Spaghetti plot y facetado de PIB per cápita de 6 países latinoamericanos con datos Gapminder (1952-2007)
- `ejemplo_clase_09.R`: Análisis integral de ventas trimestrales por ciudad (2018-2025) con filtros, `case_when()`, funciones personalizadas, loops, y generación de gráficas facetadas
- `generar_excel.R`: Generación de datos sintéticos de ventas con `set.seed(42)` y `expand.grid()`
- `clase_09.R`: Visualización facetada de proyecciones de población estatal hasta 2070 con función template para iteración

### Preguntas potenciales para examen
1. ¿Qué hace `facet_wrap()` y cuáles son sus parámetros principales?
2. Escribe una función personalizada en R que reciba un dataframe y un nombre de ciudad, y genere una gráfica.
3. ¿Qué es `set.seed()` y por qué es importante para la reproducibilidad?
4. ¿Cuál es la diferencia entre `facet_wrap()` con `scales = "free_y"` vs. sin él?
5. Escribe un loop `for` que genere y guarde una gráfica para cada estado en un dataframe.

---

## Sesión 10: Estadística descriptiva y análisis exploratorio

### Temas cubiertos
- Motivación para la exploración de datos
- Medidas de centralidad (media, mediana, moda)
- Rango y dispersión
- Varianza y desviación estándar
- Coeficiente de variación
- Distribuciones y formas
- Cuartiles y percentiles
- Tipos de datos faltantes (MCAR, MAR, MNAR)
- Detección y manejo de outliers
- Análisis de correlación
- Imputación múltiple con MICE

### Conceptos clave
- **Media:** promedio aritmético de todos los valores
- **Mediana:** valor central cuando los datos están ordenados; más robusta ante outliers
- **Moda:** valor más frecuente; cálculo manual con `which.max(table(...))`
- **Varianza:** promedio de las desviaciones cuadráticas respecto a la media
- **Desviación estándar:** raíz cuadrada de la varianza; mismas unidades que los datos
- **Coeficiente de variación (CV):** SD/Media; medida estandarizada de dispersión
- **IQR (Rango intercuartílico):** Q3 - Q1; mide la dispersión del 50% central
- **Asimetría (skewness):** medida de la forma de la distribución; positiva = cola derecha, negativa = cola izquierda
- **Datos faltantes MCAR:** Missing Completely At Random; el patrón no tiene relación con ninguna variable
- **Datos faltantes MAR:** Missing At Random; el patrón depende de variables observadas
- **Datos faltantes MNAR:** Missing Not At Random; el patrón depende de variables no observadas
- **Detección de outliers (IQR):** valores fuera de [Q1 - 1.5*IQR, Q3 + 1.5*IQR]
- **Detección de outliers (3-SD):** valores donde |valor - media| > 3 * desviación estándar
- **Correlación de Pearson:** medida de relación lineal entre variables (-1 a 1)
- **MICE (Multiple Imputation by Chained Equations):** método de imputación múltiple que genera varios datasets completos

### Funciones y paquetes de R utilizados
- `mean()`, `median()`, `var()`, `sd()`, `IQR()`, `quantile()`, `cor()`
- `summary()`: estadísticas descriptivas básicas
- `skewness()` (moments): asimetría
- `is.na()`, `colSums(is.na())`, `colMeans(is.na())`: diagnóstico de NAs
- `vis_miss()` (naniar): visualización de patrones de datos faltantes
- `mice()`, `complete()`, `stripplot()`, `densityplot()` (mice): imputación múltiple
- `corrplot()` (corrplot): matriz de correlación visual
- `geom_density()`, `geom_boxplot()`, `geom_histogram()`, `geom_jitter()`
- `stat_qq()`, `stat_qq_line()`: gráficas Q-Q para normalidad
- `pivot_longer()`, `pivot_wider()`: reestructuración de tablas de estadísticas
- `across()` con funciones lambda: cálculos múltiples por columna
- `ggplotly()` (plotly): gráficas interactivas
- `scale_fill_viridis_d()`: paleta de colores accesible
- `scales::label_dollar()`: formateo de ejes monetarios
- Paquetes: `tidyverse`, `moments`, `corrplot`, `naniar`, `mice`, `plotly`

### Ejercicios prácticos
- `acordeon.R`: EDA rápido con `datos_empleados.csv` (300 empleados, 12 variables); exploración inicial, estadísticas descriptivas, distribuciones con density plots y boxplots, correlaciones, diagnóstico de NAs, imputación con MICE (PMM, 20 iteraciones, 5 datasets)
- `analisis_descriptivo.R`: Framework completo de EDA en 11 secciones: centralidad, dispersión, distribuciones (con `skewness()`), cuartiles/percentiles, detección de outliers (IQR y 3-SD), correlaciones (`corrplot()` con clustering jerárquico), datos faltantes (MCAR/MAR/MNAR), estrategias de imputación (completa, media, mediana, mediana agrupada), análisis agrupado, tabla resumen final exportada a CSV

### Preguntas potenciales para examen
1. ¿Cuál es la diferencia entre media y mediana? ¿Cuándo es preferible usar la mediana?
2. Calcula el coeficiente de variación. ¿Para qué sirve?
3. ¿Qué son los cuartiles? ¿Cómo se usa el IQR para detectar outliers?
4. Explica los tres tipos de datos faltantes (MCAR, MAR, MNAR) con un ejemplo de cada uno.
5. ¿Qué es MICE y cómo funciona para imputar datos faltantes?
6. Escribe código que calcule la media, mediana y SD para todas las columnas numéricas de un dataframe usando `across()`.
7. ¿Cómo interpretas un gráfico Q-Q? ¿Qué indica si los puntos se desvían de la línea?
8. ¿Cuáles son las 3 estrategias para manejar outliers y cuándo usar cada una?

---

## Sesión 11: Causalidad en ciencias sociales

### Temas cubiertos
- El problema fundamental de inferencia causal (Modelo Causal de Rubin)
- Correlación no es causación
- Paradoja de Simpson
- Diferencia entre predicción, causalidad y explicación
- Métodos causales clásicos: Variables Instrumentales, Diferencias en Diferencias, Regresión Discontinua
- La paradoja moderna: causalidad vs. predicción
- Introducción a Causal ML (Causal Forests, Double/Debiased ML)

### Conceptos clave
- **Modelo Causal de Rubin:** marco de resultados potenciales Y(1) y Y(0); el efecto causal individual es τᵢ = Y(1)ᵢ - Y(0)ᵢ
- **Contrafáctico:** resultado potencial no observado; "qué habría pasado" sin la intervención
- **Sesgo de selección:** cuando la asignación al tratamiento se correlaciona con variables confusoras
- **Confundidor (confounder):** variable que afecta tanto al tratamiento como al resultado
- **Paradoja de Simpson:** sesgo de agregación donde las correlaciones a nivel agregado se revierten a nivel de subgrupo
- **Variables Instrumentales (IV):** variable que afecta el resultado solo a través del tratamiento
- **Diferencias en Diferencias (DiD):** compara cambios pre/post entre grupo tratado y control; estimador: (Y₁ᵖᵒˢᵗ - Y₁ᵖʳᵉ) - (Y₀ᵖᵒˢᵗ - Y₀ᵖʳᵉ)
- **Regresión Discontinua (RD):** explota un umbral (cutoff) de asignación; estimador: lim(x→c+) E[Y|X=x] - lim(x→c-) E[Y|X=x]
- **ATE (Average Treatment Effect):** E[Y|T=1] - E[Y|T=0]

### Funciones y paquetes de R utilizados
- `tidyverse`: manipulación y visualización
- `estimatr`: herramientas de estimación
- `lm()`: regresión lineal
- `glm()`: modelos lineales generalizados
- `ggplot2()`: visualización de diagramas causales

### Ejercicios prácticos
- Caso práctico: evaluación de programa de becas con datos municipales (ingreso, educación de profesores, localidad urbana, índice de pobreza)
- Cuatro enfoques de análisis con rigor creciente: correlacional, control por regresión, regresión discontinua, efectos heterogéneos
- Aplicaciones: Programa Progresa/Prospera, políticas de salario mínimo, confinamiento por COVID

### Preguntas potenciales para examen
1. ¿Qué es el problema fundamental de la inferencia causal?
2. Explica con un ejemplo por qué correlación no implica causación. Menciona los 3 mecanismos que generan correlación espuria.
3. ¿Qué es la Paradoja de Simpson? Da un ejemplo.
4. Describe el método de Diferencias en Diferencias (DiD) y su supuesto clave.
5. ¿Qué es una Regresión Discontinua y cuándo se puede aplicar?
6. ¿Cuál es la diferencia entre el ATE y el efecto causal individual?
7. Define contrafáctico, sesgo de selección y confundidor.

---

## Sesión 12: Regresión lineal

### Temas cubiertos
- OLS como minimización de pérdida (MSE)
- Funciones de pérdida
- Problema de multicolinealidad
- Métodos de regularización: Ridge (L2), Lasso (L1), Elastic Net
- Selección del parámetro lambda (λ)
- Métricas de evaluación: MSE, RMSE, MAE, R²
- Interpretación causal vs. predictiva de coeficientes
- Validación cruzada (k-fold)
- Diagnóstico de modelos

### Conceptos clave
- **OLS (Ordinary Least Squares):** β = (X'X)⁻¹X'y; minimiza la suma de errores cuadráticos
- **MSE:** (1/n) Σᵢ (yᵢ - ŷᵢ)²
- **RMSE:** raíz de MSE; mismas unidades que la variable dependiente
- **R²:** 1 - (SSres/SStot); proporción de varianza explicada por el modelo
- **R² ajustado:** 1 - (1-R²)(n-1)/(n-p-1); penaliza por número de predictores
- **Overfitting:** el modelo memoriza datos de entrenamiento pero falla en datos nuevos
- **Regularización Ridge (L2):** MSE + λΣⱼβⱼ²; reduce coeficientes hacia cero sin eliminarlos
- **Regularización Lasso (L1):** MSE + λΣⱼ|βⱼ|; fuerza algunos coeficientes exactamente a cero (selección de variables)
- **Elastic Net:** λ(αΣⱼ|βⱼ| + (1-α)Σⱼβⱼ²); combina L1 y L2
- **Validación cruzada k-fold:** dividir datos en k partes, entrenar en k-1, evaluar en 1, repetir k veces
- **Train/Test split:** típicamente 80/20 o 70/30

### Funciones y paquetes de R utilizados
- `lm()`: regresión lineal OLS
- `summary()`: resumen del modelo (coeficientes, R², p-valores)
- `predict()`: predicciones con intervalos de confianza/predicción
- `glmnet()`, `cv.glmnet()` (glmnet): Ridge, Lasso y Elastic Net con validación cruzada
- `createDataPartition()` (caret): partición train/test
- `tidy()`, `glance()` (broom): extracción de resultados del modelo
- `coef()`, `residuals()`, `fitted()`: diagnóstico del modelo
- `set.seed()`: reproducibilidad
- `drop_na()`, `mutate()`: limpieza
- Paquetes: `tidyverse`, `broom`, `glmnet`, `caret`

### Ejercicios prácticos
- `ejercicio_regresion_lineal.R`: Pipeline completo de regresión con datos municipales simulados (n=500):
  - Simulación de datos con efectos conocidos (educación=1.8, ocupación=0.9, urbanización=0.5)
  - EDA: estadísticas por región, matrices de correlación, scatter plots
  - Limpieza: imputación por mediana, conversión de factores con niveles de referencia
  - Modelos: regresión simple, múltiple, Ridge, Lasso
  - Diagnóstico: residuales vs. ajustados (homocedasticidad), Q-Q (normalidad), Scale-Location (heterocedasticidad)
  - Evaluación: RMSE, MAE, R² en test set
  - Comparación: OLS (R²test=0.62), Ridge (R²test=0.76), Lasso (R²test=0.70, selecciona 4 de 6 variables)

### Preguntas potenciales para examen
1. ¿Qué es OLS y qué función de pérdida minimiza?
2. Explica la diferencia entre R² y R² ajustado.
3. ¿Qué es el overfitting? ¿Cómo lo detectas comparando métricas de entrenamiento y prueba?
4. Compara Ridge y Lasso: ¿qué penalizan, cómo afectan los coeficientes, cuándo usar cada uno?
5. ¿Qué es Elastic Net y cuándo es útil?
6. Explica la validación cruzada k-fold y para qué se usa al seleccionar lambda.
7. ¿Cómo interpretas los residuales de un modelo de regresión?
8. ¿Cuál es la diferencia entre un intervalo de confianza y un intervalo de predicción?
9. Escribe código para ajustar un modelo Lasso con `glmnet` y encontrar el lambda óptimo con `cv.glmnet()`.

---

## Sesión 13: Conceptos de Machine Learning

### Temas cubiertos
- Definición de Machine Learning
- Taxonomía de problemas de ML: supervisado, no supervisado, refuerzo
- Ciclo de vida de un proyecto de ML
- Funciones de pérdida: MSE, Cross-Entropy, 0-1 Loss
- Tradeoff sesgo-varianza (Bias-Variance)
- Overfitting vs. underfitting
- Validación cruzada (K-Fold)
- Consideraciones éticas en ML para política pública

### Conceptos clave
- **Machine Learning:** aprender patrones de datos para generalizar a casos nuevos
- **Aprendizaje supervisado:** entrenamiento con targets conocidos y → regresión (continuo), clasificación (categórico)
- **Aprendizaje no supervisado:** encontrar estructura oculta sin targets → clustering, reducción de dimensionalidad
- **Aprendizaje por refuerzo:** aprender por interacción con un entorno mediante recompensas/penalizaciones
- **Ciclo de vida ML:** Definición del problema (10%) → Recolección/limpieza de datos (40%) → Exploración/visualización (15%) → Feature engineering (15%) → Entrenamiento/validación (10%) → Evaluación/ajuste (5%) → Despliegue/monitoreo (5%)
- **Sesgo (bias):** error sistemático por modelos demasiado simples
- **Varianza:** sensibilidad a variaciones en datos de entrenamiento
- **Descomposición del error:** Error Total = Bias² + Varianza + Ruido Irreducible
- **Cross-Entropy Loss:** -(1/n) Σ[yᵢ*log(ŷᵢ) + (1-yᵢ)*log(1-ŷᵢ)]
- **Underfitting:** modelo demasiado simple, no captura patrones (alto sesgo)
- **Overfitting:** modelo demasiado complejo, memoriza ruido (alta varianza)

### Funciones y paquetes de R utilizados
- `tidyverse`: manipulación y ggplot2
- `caret::createDataPartition()`: partición train/test
- `randomForest()` (randomForest): algoritmo Random Forest
- Visualización: scatter plots, matrices de correlación, gráficas de importancia de variables

### Ejercicios prácticos
- Caso: predicción de pobreza municipal (300 municipios) con 3 modelos comparados:
  - Regresión lineal: RMSE_train=8.5%, RMSE_val=9.2% (sin overfitting)
  - Polinomial grado 3: RMSE_train=6.1%, RMSE_val=12.8% (overfitting severo)
  - Random Forest (50 árboles): RMSE_train=5.2%, RMSE_val=8.8% (mejor balance)
- EDA: correlaciones (pobreza vs. educación r=-0.85, vs. acceso agua r=-0.65)

### Aplicaciones en política pública
- Predicción de pobreza para focalización de ayuda
- Predicción de violencia para despliegue policial
- Detección de fraude en programas sociales
- Riesgo de deserción escolar para intervención temprana

### Consideraciones éticas
- Sesgo histórico en datos (contratación Amazon, riesgo criminal, scoring crediticio)
- Interseccionalidad: efectos multiplicativos de desventajas múltiples
- Auditorías de equidad (fairness) por grupos demográficos
- Transparencia y explicabilidad (valores SHAP)
- "Human-in-the-loop" para decisiones críticas

### Preguntas potenciales para examen
1. Define Machine Learning y explica la diferencia entre aprendizaje supervisado y no supervisado.
2. ¿Cuáles son los tipos de problemas de aprendizaje supervisado? Da un ejemplo de cada uno.
3. Explica el tradeoff sesgo-varianza. ¿Qué pasa cuando aumentas la complejidad del modelo?
4. ¿Qué porcentaje del ciclo de vida de ML corresponde a recolección y limpieza de datos? ¿Por qué?
5. Compara MSE y Cross-Entropy como funciones de pérdida. ¿Cuándo se usa cada una?
6. ¿Qué es la validación cruzada K-Fold y por qué es mejor que un solo train/test split?
7. Dados tres modelos con los siguientes RMSE (train/val): (8.5/9.2), (6.1/12.8), (5.2/8.8), ¿cuál elegirías y por qué?
8. Menciona 3 consideraciones éticas al aplicar ML en política pública.
9. ¿Qué son los valores SHAP y para qué sirven?

---

## Resumen de paquetes de R por sesión

| Sesión | Paquetes clave |
|--------|---------------|
| 1 | base R, plotly, tidyverse |
| 2-3 | readr, readxl, haven, foreign, sf, arrow, xml2, RSQLite, DBI, jsonlite |
| 4-5 | tidyverse (dplyr, ggplot2, readr, tidyr, stringr, forcats, purrr, tibble) |
| 6-7 | tidyverse, sf, janitor, ggimage, ggthemes |
| 8-9 | tidyverse, gapminder, writexl |
| 10 | tidyverse, moments, corrplot, naniar, mice, plotly, scales |
| 11 | tidyverse, estimatr |
| 12 | tidyverse, broom, glmnet, caret |
| 13 | tidyverse, caret, randomForest |

---

## Progresión temática del curso

1. **Sesiones 1-3:** Fundamentos de R, tipos de datos, importación de archivos múltiples formatos
2. **Sesiones 4-5:** Procesamiento de datos con tidyverse (verbos dplyr, pipe operator)
3. **Sesiones 6-7:** Visualización con ggplot2 (geometrías, estéticas, temas, Grammar of Graphics)
4. **Sesiones 8-9:** Visualización avanzada (facetas, small multiples) + programación (funciones, loops)
5. **Sesión 10:** Estadística descriptiva y EDA (centralidad, dispersión, outliers, NAs, correlación, imputación)
6. **Sesiones 11-13:** Modelado (causalidad, regresión lineal/regularizada, conceptos de ML, ética)

---

*Base de conocimientos generada el 24 de marzo de 2026.*
*Fuente: materiales del curso TC2001B.601 — Prof. Jorge Juvenal Campos Ferreira, Tec de Monterrey.*
