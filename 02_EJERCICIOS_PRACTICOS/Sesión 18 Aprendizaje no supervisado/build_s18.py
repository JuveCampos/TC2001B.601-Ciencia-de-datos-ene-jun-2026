"""Sesión 18 - Funciones de aprendizaje NO supervisado (clustering + PCA).
Fragmentos del ejercicio 1 (perfil químico de vinos). Cuando una función
clave solo aparece de forma más ilustrativa en el ejercicio 2 (municipios),
se indica en el slide."""
from estilo_tec import (nueva_presentacion, slide_portada, slide_intro,
                        slide_funcion, slide_conclusiones, slide_cierre)

FT = "Sesión 18 - Clustering y PCA"
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "sesion_18_funciones_no_supervisado.pptx")

prs = nueva_presentacion()
n = 1

slide_portada(prs,
    "Sesión 18: Aprendizaje no\nsupervisado (clustering + PCA)",
    "Las funciones de R que usamos, una por una",
    "TC2001B.601 - Ciencia de datos para la toma de decisiones I\n"
    "Ejemplos tomados del ejercicio: perfil químico de vinos")

slide_intro(prs, "Sin variable objetivo: descubrir estructura",
    "En el aprendizaje NO supervisado no hay una 'y' que predecir, así que NO "
    "partimos en entrenamiento/prueba: no existe un acierto que medir. El "
    "objetivo es descubrir grupos y resumir la variabilidad. Estas son las "
    "funciones del ejercicio de vinos, en orden de uso.",
    "1.  read_csv()  -  cargar los datos\n"
    "2.  recipe() + step_impute_median() + step_normalize()  -  preparar\n"
    "3.  prep() + bake()  -  obtener la matriz lista\n"
    "4.  prcomp()  -  PCA (componentes principales)\n"
    "5.  fviz_eig() / fviz_pca_biplot()  -  visualizar el PCA\n"
    "6.  fviz_nbclust()  -  elegir k (codo y silueta)\n"
    "7.  kmeans() + fviz_cluster()  -  agrupar y visualizar\n"
    "8.  group_by() + summarise(across())  -  perfilar los grupos\n"
    "9.  dist() + hclust() + cutree() + fviz_dend()  -  jerárquico",
    n, FT); n += 1

slide_funcion(prs, "read_csv()",
    "Carga el CSV como tibble. En vinos todas las columnas son atributos; no "
    "hay id ni objetivo que remover.",
    ['# Ejercicio de vinos: 600 muestras, sin id ni "y"',
     'vinos <- read_csv("datos.csv")',
     '',
     '# En el ejercicio de municipios SI hay un id que quitar:',
     'municipios <- read_csv("datos.csv") %>%',
     '  select(-clave_municipio)'],
    "- read_csv() (de readr) lee el archivo y lo deja como tibble, con tipos "
    "de columna inferidos.\n"
    "- Un identificador (clave_municipio) NO es un atributo: si se queda, "
    "entraría como variable más en el cálculo de distancias y distorsionaría "
    "los grupos. Por eso se remueve con select(-...).\n"
    "- En no supervisado NO se separa el objetivo: aquí no hay ninguno.",
    n, FT); n += 1

slide_funcion(prs, "recipe()",
    "Declara una receta SOLO de preprocesamiento (no hay modelo): la fórmula y "
    "la secuencia de pasos.",
    ['receta_vinos <- recipe(~ ., data = vinos) %>%',
     '  step_impute_median(all_numeric_predictors()) %>%',
     '  step_normalize(all_numeric_predictors())'],
    "- La fórmula ~ . (sin nada a la izquierda) significa 'no hay variable "
    "objetivo': todas las columnas son predictores. Es la marca del no "
    "supervisado.\n"
    "- Encadenamos pasos step_*() con %>%; el ORDEN importa: primero imputar, "
    "porque los pasos siguientes no toleran NAs.\n"
    "- La receta es solo una RECETA: todavía no toca los datos.",
    n, FT); n += 1

slide_funcion(prs, "step_impute_median()",
    "Rellena los valores faltantes (NAs) de las variables numéricas con su "
    "mediana. Red de seguridad.",
    ['step_impute_median(all_numeric_predictors())'],
    "- Sustituye cada NA por la mediana de esa columna. En vinos no hay NAs, "
    "pero incluirlo es buena práctica del flujo.\n"
    "- La mediana es robusta a valores extremos: en municipios el ingreso es "
    "asimétrico (unos pocos muy ricos inflan la media), así que la mediana "
    "imputa mejor.\n"
    "- Importa porque los algoritmos de distancia y el PCA NO toleran NAs.",
    n, FT); n += 1

slide_funcion(prs, "step_normalize()",
    "Estandariza cada variable a media 0 y desviación 1. Es el paso CRÍTICO "
    "antes de PCA y clustering.",
    ['step_normalize(all_numeric_predictors())'],
    "- El PCA maximiza varianza y el clustering mide distancias: ambos son "
    "SENSIBLES A LA ESCALA.\n"
    "- Sin normalizar, dioxido_azufre_total (cientos) aplastaría a cloruros o "
    "ácido cítrico (menos de 1): los grupos reflejarían las unidades, no la "
    "química real.\n"
    "- El z-score deja a todas las variables pesando por igual. Los parámetros "
    "(media y sd) se estiman al hacer prep().", n, FT); n += 1

slide_funcion(prs, "prep() + bake()",
    "prep() aprende los parámetros del preprocesamiento; bake() devuelve la "
    "matriz ya transformada.",
    ['vinos_norm <- receta_vinos %>%',
     '  prep() %>%',
     '  bake(new_data = NULL)',
     '',
     '# Verificación: cada columna con media ~0 y desv ~1',
     'vinos_norm %>%',
     '  summarise(across(everything(),',
     '                   list(media = mean, desv = sd)))'],
    "- prep() recorre la receta y aprende los valores que necesita: las "
    "medianas de imputación y la media/sd de cada columna.\n"
    "- bake(new_data = NULL) aplica esos pasos a los mismos datos de la receta "
    "y entrega la matriz lista para prcomp() y kmeans().\n"
    "- Verificamos que media ~0 y desviación ~1 confirma que la "
    "normalización quedó bien.", n, FT, code_size=12); n += 1

slide_funcion(prs, "prcomp()",
    "Calcula el PCA: reexpresa las variables en componentes ortogonales, "
    "ordenados de mayor a menor varianza.",
    ['pca_vinos <- prcomp(vinos_norm,',
     '                    center = FALSE, scale. = FALSE)',
     '',
     '# Cargas: peso de cada variable en PC1 y PC2',
     'cargas <- pca_vinos$rotation[, 1:2] %>% round(2)'],
    "- prcomp() crea ejes (componentes) que son combinaciones lineales de las "
    "variables originales; las primeras concentran lo esencial de la "
    "variabilidad.\n"
    "- center y scale. en FALSE porque YA normalizamos con la receta: no hay "
    "que escalar dos veces.\n"
    "- $rotation guarda las cargas: cuánto pesa cada variable en cada "
    "componente, clave para interpretar qué representa PC1 y PC2.",
    n, FT); n += 1

slide_funcion(prs, "fviz_eig()",
    "Dibuja el scree plot: el porcentaje de varianza explicada por cada "
    "componente principal.",
    ['fviz_eig(pca_vinos, addlabels = TRUE,',
     '         barfill = "#1e4c7d",',
     '         barcolor = "#1e4c7d",',
     '         main = "Varianza explicada (scree)")'],
    "- fviz_eig() (del paquete factoextra) grafica la varianza explicada en "
    "orden decreciente.\n"
    "- Se lee buscando el 'codo': el punto a partir del cual añadir más "
    "componentes aporta poco. Ahí decidimos cuántas retener.\n"
    "- addlabels = TRUE escribe el porcentaje sobre cada barra para leerlo "
    "directo.", n, FT); n += 1

slide_funcion(prs, "fviz_pca_biplot()",
    "Proyecta las observaciones en el plano PC1-PC2 y superpone las variables "
    "como flechas.",
    ['fviz_pca_biplot(pca_vinos,',
     '                label = "var", col.var = "#d62828",',
     '                col.ind = "#1e4c7d",',
     '                alpha.ind = 0.4)'],
    "- Los puntos son las 600 muestras de vino; las flechas son las variables "
    "originales.\n"
    "- Variables con flechas casi paralelas están correlacionadas: aquí se ve "
    "juntas a las dos de dióxido de azufre (total contiene al libre).\n"
    "- label = \"var\" etiqueta solo las variables; col.ind / col.var fijan "
    "los colores de puntos y flechas.", n, FT); n += 1

slide_funcion(prs, 'fviz_nbclust(method="wss")',
    "Método del codo: grafica la suma de cuadrados dentro de los grupos (WSS) "
    "para cada k.",
    ['set.seed(123)',
     'fviz_nbclust(vinos_norm, kmeans,',
     '             method = "wss", nstart = 20) +',
     '  labs(title = "Método del codo (WSS)")'],
    "- Al aumentar k, la WSS siempre baja. Buscamos el 'codo': el k a partir "
    "del cual el descenso se vuelve marginal.\n"
    "- Recibe la matriz y la función de clustering (kmeans); nstart = 20 hace "
    "20 arranques por cada k para estabilizar la curva.\n"
    "- set.seed() hace reproducible la aleatoriedad de los arranques.",
    n, FT); n += 1

slide_funcion(prs, 'fviz_nbclust(method="silhouette")',
    "Método de la silueta: mide qué tan bien separados quedan los grupos para "
    "cada k.",
    ['set.seed(123)',
     'fviz_nbclust(vinos_norm, kmeans,',
     '             method = "silhouette", nstart = 20) +',
     '  labs(title = "Método de la silueta")'],
    "- La silueta evalúa, para cada punto, qué tan cómodo está en su grupo vs. "
    "qué tan cerca queda del grupo vecino.\n"
    "- El k con silueta promedio MÁS ALTA es el preferido; suele desempatar "
    "cuando el codo es ambiguo.\n"
    "- Tras leer ambos diagnósticos, en vinos elegimos k = 3.",
    n, FT); n += 1

slide_funcion(prs, "kmeans()",
    "Agrupa las observaciones en k grupos minimizando la distancia de cada "
    "punto al centroide de su grupo.",
    ['set.seed(123)',
     'k_elegido <- 3',
     'km_vinos <- kmeans(vinos_norm,',
     '                   centers = k_elegido,',
     '                   nstart = 25)',
     'km_vinos$size   # tamaño de cada grupo'],
    "- centers = k fija de antemano el número de grupos (decidido con codo y "
    "silueta).\n"
    "- nstart = 25: k-means depende de la inicialización aleatoria de los "
    "centroides; probar 25 arranques y quedarse con el mejor evita caer en un "
    "óptimo local malo.\n"
    "- set.seed() garantiza reproducibilidad. $cluster guarda la etiqueta de "
    "grupo de cada observación.", n, FT, code_size=12); n += 1

slide_funcion(prs, "fviz_cluster()",
    "Visualiza los grupos de k-means proyectándolos sobre el plano PC1-PC2.",
    ['fviz_cluster(km_vinos, data = vinos_norm,',
     '             geom = "point",',
     '             ellipse.type = "convex",',
     '             palette = c("#1e4c7d", "#2d7a7a",',
     '                         "#c97b2a"))'],
    "- factoextra usa internamente el PCA para mostrar grupos de muchas "
    "dimensiones en un plano de 2D.\n"
    "- ellipse.type = \"convex\" dibuja la envolvente de cada grupo, útil para "
    "ver solapamientos.\n"
    "- geom = \"point\" muestra solo los puntos (sin etiquetas), ideal con "
    "cientos de observaciones.", n, FT); n += 1

slide_funcion(prs, "group_by() + summarise(across())",
    "Perfila los grupos: calcula la media de cada variable ORIGINAL por "
    "cluster para interpretarlos.",
    ['vinos_perfilados <- vinos %>%',
     '  mutate(cluster = factor(km_vinos$cluster))',
     '',
     'perfil_clusters <- vinos_perfilados %>%',
     '  group_by(cluster) %>%',
     '  summarise(across(everything(), mean),',
     '            n = n())'],
    "- mutate() pega la etiqueta de grupo a los datos en sus unidades "
    "originales (no las normalizadas), para leer cifras reales.\n"
    "- group_by(cluster) + summarise() resume cada grupo; across(everything(), "
    "mean) aplica la media a TODAS las columnas de una vez.\n"
    "- Comparando las medias se nombra cada grupo: p. ej. 'vinos secos y "
    "alcohólicos' vs. 'dulces con mucho azufre'.", n, FT, code_size=12); n += 1

slide_funcion(prs, "dist() + hclust()",
    "Clustering jerárquico: construye un árbol fusionando observaciones por "
    "cercanía, sin fijar k de antemano.",
    ['dist_vinos <- dist(vinos_norm,',
     '                   method = "euclidean")',
     '',
     'hc_vinos <- hclust(dist_vinos,',
     '                   method = "ward.D2")'],
    "- dist() arma la matriz de distancias euclidianas entre todas las "
    "muestras normalizadas; es el insumo del jerárquico.\n"
    "- hclust() construye el dendrograma fusionando primero lo más cercano.\n"
    "- method = \"ward.D2\" tiende a formar grupos compactos y de tamaño "
    "parecido, lo que lo hace comparable con k-means.", n, FT); n += 1

slide_funcion(prs, "fviz_dend() + cutree()",
    "Dibuja el dendrograma y lo 'corta' a la altura que deja el número de "
    "grupos deseado.",
    ['fviz_dend(hc_vinos, k = k_elegido,',
     '          show_labels = FALSE, rect = TRUE)',
     '',
     'grupos_hc <- cutree(hc_vinos, k = k_elegido)',
     'table(kmeans = km_vinos$cluster,',
     '      jerárquico = grupos_hc)'],
    "- fviz_dend() muestra el árbol; k colorea las ramas según el número de "
    "grupos y rect = TRUE los enmarca.\n"
    "- cutree(hc, k) corta el árbol en k grupos y devuelve la etiqueta de cada "
    "observación.\n"
    "- table() cruza k-means vs. jerárquico: si cada grupo de un método cae en "
    "UNO del otro, ambos descubren la misma estructura.",
    n, FT, code_size=12); n += 1

slide_conclusiones(prs, "Resumen: el flujo del no supervisado",
    "- Sin variable objetivo: NO se parte en entrenamiento/prueba; se busca "
    "estructura, no acierto.\n"
    "- step_normalize() es indispensable: PCA y clustering son sensibles a la "
    "escala; sin z-score mandan las unidades, no la información.\n"
    "- prcomp() resume la variabilidad en pocos ejes y permite visualizar; las "
    "cargas ($rotation) dicen qué significa cada componente.\n"
    "- fviz_nbclust() (codo + silueta) elige k a partir de los datos, no a "
    "ojo; kmeans() agrupa y fviz_cluster() lo muestra.\n"
    "- group_by() + summarise(across()) perfila los grupos; dist() + hclust() "
    "+ cutree() dan un segundo método para confirmarlos.",
    n, FT); n += 1

slide_cierre(prs)

prs.save(OUT)
print("Guardado:", OUT, "| slides:", len(prs.slides._sldIdLst))
