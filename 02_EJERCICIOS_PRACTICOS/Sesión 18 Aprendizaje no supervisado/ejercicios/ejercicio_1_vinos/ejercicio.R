options(scipen = 999)

# =============================================================================
# SESIÓN 18 — APRENDIZAJE NO SUPERVISADO
# Ejercicio 1: perfil químico de vinos (clustering + PCA)
# =============================================================================
#
# Idea central de esta sesión:
# ----------------------------
# En el aprendizaje NO supervisado NO existe una variable objetivo (una "y"
# que queramos predecir). Por eso aquí NO partimos los datos en
# entrenamiento/prueba: no hay un acierto que medir. El objetivo es
# DESCUBRIR estructura: ¿las muestras de vino se agrupan en perfiles
# químicos naturales? ¿cuántos grupos hay y qué los distingue?
#
# Trabajaremos dos familias de técnicas:
#   * PCA (análisis de componentes principales): reduce las 11 variables a
#     unos pocos ejes que concentran la varianza; sirve para visualizar y
#     entender qué variables "se mueven juntas".
#   * Clustering (k-means y jerárquico): agrupa las observaciones por
#     cercanía. El alumno decide cuántos grupos usar con el codo y la silueta.

# Librerías ----
library(tidyverse)
library(tidymodels)
library(factoextra)
library(cluster)

tidymodels::tidymodels_prefer()

# -----------------------------------------------------------------------------
# 1. CARGA Y PREPARACIÓN DE LOS DATOS
# -----------------------------------------------------------------------------

# Cargamos las 600 muestras. Todas las columnas son atributos
# fisicoquímicos: no hay columna id ni variable objetivo que remover.
vinos <- read_csv("datos.csv")

# Inspección rápida: dimensiones, tipos y faltantes.
glimpse(vinos)
summary(vinos)

# ¿Cuántos NAs hay por columna? En este dataset no hay, pero verificarlo
# siempre es parte del flujo: los algoritmos de distancia no toleran NAs.
colSums(is.na(vinos))

# Antes de normalizar, miremos la colinealidad. dioxido_azufre_total
# contiene al libre (total = libre + combinado), así que esperamos una
# correlación muy alta entre ambos. No la eliminamos: el PCA la absorberá
# proyectando sobre ejes ortogonales, pero conviene tenerla presente al
# interpretar las cargas.
matriz_cor <- vinos %>%
  cor() %>%
  round(2)
matriz_cor[, c("dioxido_azufre_libre", "dioxido_azufre_total")]

# ¿POR QUÉ NORMALIZAR (z-score) ES INDISPENSABLE AQUÍ?
# -----------------------------------------------------
# Las variables están en escalas muy distintas: cloruros y ácido cítrico
# valen menos de 1, mientras que dioxido_azufre_total llega a cientos.
# Tanto el PCA (que maximiza varianza) como el clustering (que mide
# distancias) son SENSIBLES A LA ESCALA. Sin normalizar, el dióxido de
# azufre total dominaría por completo la varianza y las distancias, y los
# grupos reflejarían solo las unidades de medida, no la química real.
# La normalización z-score deja cada variable con media 0 y desviación 1,
# de modo que todas pesan por igual.

# Construimos un recipe SOLO para preprocesar (no hay modelo supervisado).
# step_impute_median: red de seguridad si hubiera NAs (aquí no cambia nada).
# step_normalize: z-score sobre todas las variables numéricas.
receta_vinos <- recipe(~ ., data = vinos) %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors())

# prep() aprende las medianas y los parámetros de escala; bake() devuelve
# la matriz ya normalizada y lista para PCA y clustering.
vinos_norm <- receta_vinos %>%
  prep() %>%
  bake(new_data = NULL)

# Verificación: cada columna debe tener media ~0 y desviación ~1.
vinos_norm %>%
  summarise(across(everything(), list(media = mean, desv = sd))) %>%
  glimpse()

# -----------------------------------------------------------------------------
# 2. PCA — ANÁLISIS DE COMPONENTES PRINCIPALES
# -----------------------------------------------------------------------------
#
# El PCA reexpresa las 11 variables en 11 nuevos ejes (componentes) que son
# combinaciones lineales de las originales, ordenados de mayor a menor
# varianza explicada. Las primeras componentes resumen lo esencial de la
# variabilidad; nos permiten visualizar 600 vinos en un plano (PC1-PC2).
# Como ya normalizamos, NO volvemos a escalar dentro de prcomp().

pca_vinos <- prcomp(vinos_norm, center = FALSE, scale. = FALSE)

# Scree plot: porcentaje de varianza explicada por cada componente.
# Se lee buscando el "codo": el punto a partir del cual añadir componentes
# aporta poco. Ahí decidimos cuántas componentes retener.
fviz_eig(pca_vinos, addlabels = TRUE,
         barfill = "#1e4c7d", barcolor = "#1e4c7d",
         main = "Varianza explicada por componente (scree plot)")

# Varianza explicada en números (acumulada incluida).
varianza_explicada <- summary(pca_vinos)$importance
varianza_explicada[, 1:5]

# Cargas (rotation): cuánto pesa cada variable original en cada componente.
# Aquí interpretamos QUÉ representan PC1 y PC2 según sus cargas.
cargas <- pca_vinos$rotation[, 1:2] %>%
  round(2)
cargas

# INTERPRETACIÓN DE LAS PRIMERAS COMPONENTES (leer las cargas de 'cargas'):
# - PC1 suele capturar el contraste químico dominante del vino: el bloque
#   de azufre (dioxido_azufre_libre y _total, que entran juntos por su
#   colinealidad) frente a variables como alcohol y acidez. Es el eje que
#   más separa las muestras.
# - PC2 recoge un segundo contraste, típicamente ligado a la estructura
#   ácida/densidad (acidez_fija, ph, densidad, azucar_residual): vinos más
#   densos y dulces frente a vinos más alcohólicos y secos.
# La lectura exacta depende de los signos y magnitudes que aparezcan en
# 'cargas'; el alumno debe leer esa tabla y describir el contraste real.

# Proyección de las 600 muestras en el plano PC1-PC2 (biplot):
# los puntos son las muestras; las flechas son las variables. Variables con
# flechas casi paralelas están correlacionadas (esperamos ver juntas a las
# dos de dióxido de azufre).
fviz_pca_biplot(pca_vinos,
                label = "var", col.var = "#d62828",
                col.ind = "#1e4c7d", alpha.ind = 0.4,
                title = "Muestras de vino en el plano PC1-PC2 (biplot)")

# -----------------------------------------------------------------------------
# 3. ELECCIÓN DEL NÚMERO DE GRUPOS (k)
# -----------------------------------------------------------------------------
#
# k-means necesita que fijemos k de antemano. Dos diagnósticos ayudan a
# elegirlo a partir de los datos (no a ojo).

# Método del codo (WSS = suma de cuadrados dentro de los grupos):
# al aumentar k, WSS siempre baja. Buscamos el "codo": el k a partir del
# cual el descenso se vuelve marginal. Ese codo sugiere el número de grupos.
set.seed(123)
fviz_nbclust(vinos_norm, kmeans, method = "wss", nstart = 20) +
  labs(title = "Método del codo (WSS) — vinos")

# Método de la silueta: para cada k mide qué tan bien separados quedan los
# grupos (cada punto cómodo en su grupo vs. cercano a otro). El k con
# silueta promedio MÁS ALTA es el preferido. Suele ser el diagnóstico más
# decisivo cuando el codo es ambiguo.
set.seed(123)
fviz_nbclust(vinos_norm, kmeans, method = "silhouette", nstart = 20) +
  labs(title = "Método de la silueta — vinos")

# Tras leer ambos diagnósticos, elegimos k = 3 para este dataset (el codo
# se aplana y la silueta es alta alrededor de 3 perfiles químicos).
k_elegido <- 3

# -----------------------------------------------------------------------------
# 4. K-MEANS CON EL k ELEGIDO
# -----------------------------------------------------------------------------
#
# nstart = 25: k-means depende de la inicialización aleatoria de centroides;
# probar 25 arranques y quedarse con el mejor evita caer en un óptimo local
# malo. set.seed() garantiza reproducibilidad.
set.seed(123)
km_vinos <- kmeans(vinos_norm, centers = k_elegido, nstart = 25)

# Tamaño de cada grupo.
km_vinos$size

# Visualización de los clusters (factoextra los proyecta sobre PC1-PC2).
fviz_cluster(km_vinos, data = vinos_norm,
             geom = "point", ellipse.type = "convex",
             palette = c("#1e4c7d", "#2d7a7a", "#c97b2a"),
             main = paste0("k-means (k = ", k_elegido, ") — vinos"))

# PERFILADO DE LOS GRUPOS:
# Para interpretar QUÉ tipo de vino es cada grupo, calculamos las medias de
# las variables ORIGINALES (no las normalizadas) por cluster. Así leemos
# las cifras en sus unidades reales (% de alcohol, g/L, etc.).
vinos_perfilados <- vinos %>%
  mutate(cluster = factor(km_vinos$cluster))

perfil_clusters <- vinos_perfilados %>%
  group_by(cluster) %>%
  summarise(across(everything(), mean), n = n()) %>%
  ungroup()
perfil_clusters

# INTERPRETACIÓN (leer 'perfil_clusters'):
# Comparando las medias por grupo se identifica el carácter de cada perfil,
# por ejemplo:
# - un grupo de vinos con alcohol alto y azúcar baja (más secos/potentes),
# - un grupo con azúcar residual y dióxido de azufre altos (más dulces y
#   conservados, típico de blancos),
# - un grupo de acidez elevada y alcohol moderado (más frescos/ácidos).
# El alumno debe nombrar cada grupo según las medias reales observadas.

# -----------------------------------------------------------------------------
# 5. CLUSTERING JERÁRQUICO (comparación)
# -----------------------------------------------------------------------------
#
# El clustering jerárquico no necesita fijar k de antemano: construye un
# árbol (dendrograma) fusionando puntos/grupos por cercanía. Lo "cortamos"
# a la altura que deje el número de grupos deseado.

# Matriz de distancias euclidianas entre las 600 muestras normalizadas.
dist_vinos <- dist(vinos_norm, method = "euclidean")

# hclust con Ward (ward.D2): tiende a formar grupos compactos y de tamaño
# parecido, lo que lo hace comparable con k-means.
hc_vinos <- hclust(dist_vinos, method = "ward.D2")

# Dendrograma coloreado al mismo número de grupos que k-means.
fviz_dend(hc_vinos, k = k_elegido,
          k_colors = c("#1e4c7d", "#2d7a7a", "#c97b2a"),
          show_labels = FALSE, rect = TRUE,
          main = paste0("Dendrograma (Ward) — corte en k = ",
                        k_elegido))

# Cortamos el árbol en k grupos.
grupos_hc <- cutree(hc_vinos, k = k_elegido)

# COMPARACIÓN k-means vs jerárquico:
# La tabla cruzada muestra cuántas muestras coinciden entre ambos métodos.
# Las etiquetas de grupo son arbitrarias (el "1" de un método no tiene por
# qué ser el "1" del otro), así que NO miramos la diagonal sino si cada
# grupo de un método cae mayormente en UN solo grupo del otro: eso indica
# que ambos descubren la misma estructura, lo que da confianza en los
# perfiles encontrados.
table(kmeans = km_vinos$cluster, jerarquico = grupos_hc)

