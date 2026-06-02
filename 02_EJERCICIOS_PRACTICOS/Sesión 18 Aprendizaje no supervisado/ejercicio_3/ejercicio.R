options(scipen = 999)

# =============================================================================
# SESIÓN 18 — APRENDIZAJE NO SUPERVISADO
# Ejercicio 3: apostadores en casas de apuestas en línea (PCA + clustering)
# =============================================================================
#
# Contexto del problema:
# ----------------------
# Una casa de apuestas en línea tiene 700 usuarios descritos por su
# comportamiento de juego: cuánto depositan, cuánto apuestan, con qué
# frecuencia y a qué horas juegan, cuánto retiran, cuánto usan bonos, etc.
# NADIE etiquetó a los usuarios: no sabemos de antemano cuántos "tipos" de
# jugador hay ni a cuál pertenece cada uno. La pregunta es exploratoria y de
# negocio (y de juego responsable): **¿existen perfiles de jugador naturales
# que agrupen a los usuarios?** Segmentarlos permite tratar distinto a un
# jugador recreativo, a uno de alto valor y a uno con señales de riesgo.
#
# Esto es aprendizaje NO supervisado: no hay variable objetivo ("y") que
# predecir, así que NO se parten los datos en entrenamiento/prueba (no hay un
# acierto que medir). El objetivo es DESCUBRIR e interpretar estructura.
#
# Seguiremos tres pasos, en este orden:
#   1) PCA: reducir las variables a unos pocos ejes para visualizar y entender
#      qué variables "se mueven juntas".
#   2) Clustering k-means, eligiendo el número de grupos con el MÉTODO DEL CODO
#      (y confirmando con la silueta).
#   3) Graficar los usuarios ya agrupados usando las componentes del paso 1
#      (PC1 vs PC2), coloreados por cluster.
# Al final comparamos con clustering jerárquico para dar robustez.

# Librerías ----
library(tidyverse)
library(tidymodels)
library(factoextra)
library(cluster)
library(corrplot)

tidymodels::tidymodels_prefer()

# -----------------------------------------------------------------------------
# 0. CARGA Y PREPARACIÓN DE LOS DATOS
# -----------------------------------------------------------------------------

# Cargamos los 700 usuarios. id_usuario es solo un identificador
# (US00001, US00002, ...): NO es una variable de comportamiento y debe
# removerse antes de cualquier cálculo de distancia (si no, el "id" entraría
# como si fuera un atributo).
apostadores <- read_csv("datos.csv") %>%
  select(-id_usuario)

# Inspección rápida: dimensiones, tipos y faltantes.
glimpse(apostadores)
summary(apostadores)

# NAs por columna: esperamos faltantes en monto_promedio_apuesta_mxn (~4%).
# Los algoritmos de distancia (k-means, jerárquico) y el PCA NO toleran NAs:
# hay que resolverlos antes de modelar.
colSums(is.na(apostadores))

# Colinealidad: perdida_neta_mxn se construye como
# monto_total_depositado_mxn - monto_total_retirado_mxn, así que está
# fuertemente correlacionada con ambas. No la eliminamos: el PCA la absorbe
# proyectando sobre ejes ortogonales, pero conviene tenerla presente al
# interpretar las cargas.
matriz_cor <- apostadores %>%
  cor(use = "complete.obs") %>%
  round(2)
matriz_cor[, c("monto_total_depositado_mxn", "monto_total_retirado_mxn",
               "perdida_neta_mxn")]
corrplot(matriz_cor)

# IMPUTACIÓN Y NORMALIZACIÓN
# --------------------------
# step_impute_median: rellena los NAs de la apuesta promedio con la MEDIANA.
# Preferimos la mediana sobre la media porque los montos son asimétricos
# (unos pocos jugadores VIP con apuestas enormes inflan la media); la mediana
# es más robusta.
#
# ¿POR QUÉ NORMALIZAR (z-score) ES INDISPENSABLE AQUÍ?
# Las variables están en escalas muy distintas: los porcentajes y conteos
# valen decenas, mientras que los montos en pesos llegan a decenas de miles.
# Tanto el PCA (que maximiza varianza) como el clustering (que mide
# distancias) son SENSIBLES A LA ESCALA. Sin normalizar,
# monto_total_depositado_mxn y perdida_neta_mxn dominarían por completo la
# varianza y las distancias, y los grupos reflejarían solo las unidades de
# medida (pesos), no el comportamiento de juego. El z-score deja cada
# variable con media 0 y desviación 1, de modo que todas pesen por igual.
receta_apostadores <- recipe(~ ., data = apostadores) %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors())

# prep() aprende la mediana de imputación y los parámetros de escala;
# bake() devuelve la matriz lista (imputada y normalizada).
apostadores_norm <- receta_apostadores %>%
  prep() %>%
  bake(new_data = NULL)

# Verificación: cada columna debe tener media ~0, desviación ~1 y sin NAs.
apostadores_norm %>%
  summarise(across(everything(), list(media = mean, desv = sd))) %>%
  glimpse()
colSums(is.na(apostadores_norm))

# -----------------------------------------------------------------------------
# 1. PCA — ANÁLISIS DE COMPONENTES PRINCIPALES
# -----------------------------------------------------------------------------
#
# El PCA reexpresa las 14 variables en 14 nuevos ejes (componentes) que son
# combinaciones lineales de las originales, ordenados de mayor a menor
# varianza explicada. Las primeras componentes resumen lo esencial de la
# variabilidad y nos permiten visualizar a los 700 usuarios en un plano
# (PC1-PC2). Como ya normalizamos, NO volvemos a escalar dentro de prcomp().

pca_apostadores <- prcomp(apostadores_norm, center = FALSE, scale. = FALSE)

# Scree plot: porcentaje de varianza explicada por cada componente. Se lee
# buscando el "codo": el punto a partir del cual añadir componentes aporta
# poco. Ahí decidimos cuántas componentes retener para resumir los datos.
fviz_eig(pca_apostadores, addlabels = TRUE,
         barfill = "#1e4c7d", barcolor = "#1e4c7d",
         main = "Varianza explicada por componente (scree plot)")

# Varianza explicada en números (proporción y acumulada).
varianza_explicada <- summary(pca_apostadores)$importance
varianza_explicada[, 1:5]

# Cargas (rotation): cuánto pesa cada variable original en cada componente.
# Aquí interpretamos QUÉ representan PC1 y PC2 según sus cargas.
cargas <- pca_apostadores$rotation[, 1:2] %>%
  round(2)
cargas

# INTERPRETACIÓN DE LAS PRIMERAS COMPONENTES (leer la tabla 'cargas'):
# - PC1 suele capturar la INTENSIDAD/GASTO global del jugador: el bloque de
#   dinero y actividad (depósitos, montos, número de apuestas y sesiones,
#   pérdida neta) carga junto. Es el eje que más separa a un usuario casual
#   de bajo gasto de un usuario intenso de alto gasto.
# - PC2 recoge un segundo contraste de ESTILO de juego, típicamente el eje
#   riesgo vs. bonos: de un lado apuestas nocturnas, duración de sesión e
#   índice de persecución de pérdidas (señales de juego problemático); del
#   otro, uso de bonos y retiros (perfil cazador de bonos).
# La lectura exacta depende de los signos y magnitudes que aparezcan en
# 'cargas'; el alumno debe leer esa tabla y describir el contraste real.

# Biplot: proyección de los 700 usuarios en PC1-PC2 con las flechas de las
# variables. Variables con flechas casi paralelas están correlacionadas
# (esperamos ver juntas a depositado, retirado y pérdida neta).
fviz_pca_biplot(pca_apostadores,
                label = "var", col.var = "#d62828",
                col.ind = "#1e4c7d", alpha.ind = 0.4,
                title = "Usuarios en el plano PC1-PC2 (biplot)")

# -----------------------------------------------------------------------------
# 2. CLUSTERING — ELECCIÓN DE k CON EL MÉTODO DEL CODO Y k-MEANS
# -----------------------------------------------------------------------------
#
# k-means necesita que fijemos k (número de grupos) de antemano. Lo elegimos
# a partir de los datos, no a ojo.

# MÉTODO DEL CODO (WSS = suma de cuadrados dentro de los grupos):
# al aumentar k, la WSS siempre baja (más grupos => puntos más cerca de su
# centroide). Buscamos el "codo": el k a partir del cual el descenso se
# vuelve marginal (la curva se aplana). Ese codo sugiere el número de grupos:
# añadir más no compra mucha cohesión adicional.
set.seed(2026)
fviz_nbclust(apostadores_norm, kmeans, method = "wss", nstart = 20) +
  labs(title = "Método del codo (WSS) — apostadores")

# Confirmación con la silueta: para cada k mide qué tan bien separados quedan
# los grupos (cada punto cómodo en su grupo vs. cercano a otro). El k con
# silueta promedio MÁS ALTA es el preferido; sirve para desempatar si el codo
# fuera ambiguo.
set.seed(2026)
fviz_nbclust(apostadores_norm, kmeans, method = "silhouette", nstart = 20) +
  labs(title = "Método de la silueta — apostadores")

# Tras leer el codo (se aplana en 4) y la silueta (máxima en 4), elegimos
# k = 4: cuatro perfiles de jugador.
k_elegido <- 4

# K-MEANS CON EL k ELEGIDO
# nstart = 25: k-means depende de la inicialización aleatoria de centroides;
# probar 25 arranques y quedarse con el mejor evita caer en un óptimo local
# malo. set.seed() garantiza reproducibilidad.
set.seed(2026)
km_apostadores <- kmeans(apostadores_norm, centers = k_elegido, nstart = 25)

# Tamaño de cada grupo (número de usuarios).
km_apostadores$size

# PERFILADO DE LOS GRUPOS:
# Para interpretar QUÉ tipo de jugador es cada grupo, calculamos las medias de
# las variables ORIGINALES (no las normalizadas) por cluster. Así leemos las
# cifras en sus unidades reales (pesos, conteos, %, minutos).
apostadores_perfilados <- apostadores %>%
  mutate(cluster = factor(km_apostadores$cluster))

perfil_clusters <- apostadores_perfilados %>%
  group_by(cluster) %>%
  summarise(across(everything(), ~ mean(.x, na.rm = TRUE)), n = n()) %>%
  ungroup()
perfil_clusters

# INTERPRETACIÓN (leer 'perfil_clusters'):
# Comparando las medias por grupo se reconocen perfiles de jugador, por
# ejemplo:
# - recreativo / casual: depósitos y montos bajos, poca frecuencia, sesiones
#   cortas, baja persecución de pérdidas (el grupo más grande);
# - VIP / alto valor: depósitos y apuesta promedio muy altos, pérdida neta
#   alta, frecuencia moderada (pocos usuarios, mucho ingreso para la casa);
# - en riesgo / juego problemático: frecuencia altísima (muchas apuestas y
#   sesiones), sesiones largas, alto % de juego nocturno e índice de
#   persecución de pérdidas elevado, retiros bajos;
# - cazador de bonos: uso de bonos muy alto, muchas apuestas de monto bajo,
#   retiros que igualan o superan los depósitos (pérdida neta cercana a cero
#   o negativa), sesiones cortas.
# El alumno debe etiquetar cada grupo según las cifras reales observadas y
# pensar qué tratamiento correspondería a cada uno (retención, atención de
# juego responsable, control de abuso de bonos, etc.).

# -----------------------------------------------------------------------------
# 3. GRÁFICA DE LOS CLUSTERS SOBRE LAS COMPONENTES DEL PCA (PASO 1)
# -----------------------------------------------------------------------------
#
# Pedimos explícitamente graficar los puntos ya agrupados usando el PCA que
# calculamos en el paso 1. Tomamos las coordenadas de cada usuario en PC1 y
# PC2 (pca_apostadores$x) y las coloreamos por el cluster de k-means. Así
# vemos en 2D cómo se separan los cuatro perfiles sobre los ejes que más
# varianza concentran.

# Porcentaje de varianza de PC1 y PC2 para rotular los ejes.
pct_pc1 <- round(varianza_explicada[2, 1] * 100, 1)
pct_pc2 <- round(varianza_explicada[2, 2] * 100, 1)

# Tabla con las coordenadas PCA + el cluster asignado.
puntos_pca <- as_tibble(pca_apostadores$x[, 1:2]) %>%
  mutate(cluster = factor(km_apostadores$cluster))

ggplot(puntos_pca, aes(x = PC1, y = PC2, color = cluster)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = c("#1e4c7d", "#2d7a7a", "#c97b2a", "#7d3c66")) +
  labs(
    title = "Apostadores agrupados (k-means) sobre las componentes del PCA",
    x = paste0("PC1 (", pct_pc1, "% de varianza)"),
    y = paste0("PC2 (", pct_pc2, "% de varianza)"),
    color = "Cluster"
  ) +
  theme_minimal()

# Alternativa equivalente con factoextra (proyecta sobre PC1-PC2 igual que
# arriba y añade elipses para resaltar cada grupo).
fviz_cluster(km_apostadores, data = apostadores_norm,
             geom = "point", ellipse.type = "convex",
             palette = c("#1e4c7d", "#2d7a7a", "#c97b2a", "#7d3c66"),
             main = paste0("k-means (k = ", k_elegido, ") sobre PC1-PC2"))

# -----------------------------------------------------------------------------
# 4. CLUSTERING JERÁRQUICO (comparación)
# -----------------------------------------------------------------------------
#
# El clustering jerárquico no necesita fijar k de antemano: construye un árbol
# (dendrograma) fusionando usuarios/grupos por cercanía. Lo "cortamos" a la
# altura que deje el número de grupos deseado. Sirve para contrastar con
# k-means: si ambos encuentran la misma estructura, ganamos confianza.

# Distancias euclidianas entre los 700 usuarios normalizados.
dist_apostadores <- dist(apostadores_norm, method = "euclidean")

# Ward (ward.D2): tiende a formar grupos compactos y de tamaño parecido, lo
# que lo hace comparable con k-means.
hc_apostadores <- hclust(dist_apostadores, method = "ward.D2")

# Dendrograma coloreado al mismo número de grupos que k-means.
fviz_dend(hc_apostadores, k = k_elegido,
          k_colors = c("#1e4c7d", "#2d7a7a", "#c97b2a", "#7d3c66"),
          show_labels = FALSE, rect = TRUE,
          main = paste0("Dendrograma (Ward) — corte en k = ", k_elegido))

# Cortamos el árbol en k grupos.
grupos_hc <- cutree(hc_apostadores, k = k_elegido)

# COMPARACIÓN k-means vs jerárquico:
# Las etiquetas de grupo son arbitrarias (el "1" de un método no tiene por qué
# ser el "1" del otro), así que NO miramos la diagonal: revisamos si cada
# grupo de un método cae mayormente en UN solo grupo del otro. Si la
# correspondencia es fuerte, ambos métodos descubren los mismos perfiles de
# jugador y eso da robustez a la segmentación.
table(kmeans = km_apostadores$cluster, jerarquico = grupos_hc)

