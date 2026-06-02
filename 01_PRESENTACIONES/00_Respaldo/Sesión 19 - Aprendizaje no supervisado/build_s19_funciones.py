"""Sesión 19 - Funciones de aprendizaje NO supervisado con tidymodels nativo
(recipes + tidyclust). Fragmentos tomados de los ejercicios de apostadores
(ejercicio_1) y municipios (ejercicio_2). Estilo Tec 4:3."""
import os
from estilo_tec import (nueva_presentacion, slide_portada, slide_intro,
                        slide_funcion, slide_conclusiones, slide_cierre)

FT = "Sesión 19 - PCA y clustering (tidymodels)"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "sesion_19_funciones_no_supervisado.pptx")

prs = nueva_presentacion()
n = 1

slide_portada(prs,
    "Sesión 19: Aprendizaje no\nsupervisado (PCA + clustering)",
    "Las funciones de R que usamos, una por una",
    "TC2001B.601 - Ciencia de datos para la toma de decisiones I\n"
    "Enfoque tidymodels nativo: recipes + tidyclust\n"
    "Ejemplos: apostadores en línea y tipologías de municipios")

slide_intro(prs, "Sin variable objetivo: descubrir estructura",
    "En el aprendizaje NO supervisado no hay una 'y' que predecir, así que NO "
    "partimos en entrenamiento/prueba: no existe un acierto que medir. El "
    "objetivo es resumir variables (PCA) y descubrir grupos (clustering). "
    "Usamos el ecosistema tidymodels: recipes para preparar y para el PCA, y "
    "tidyclust para el clustering. Estas son las funciones, en orden de uso.",
    "1.  library() + tidymodels_prefer()\n"
    "2.  read_csv()  -  cargar los datos\n"
    "3.  recipe() + update_role()  -  declarar roles\n"
    "4.  step_impute_median() + step_normalize()  -  preparar\n"
    "5.  prep() + bake()  -  aplicar la receta\n"
    "6.  step_pca() + tidy()  -  PCA y su lectura\n"
    "7.  k_means() + set_engine() + workflow()  -  modelo\n"
    "8.  vfold_cv() + cluster_metric_set() + tune_cluster()  -  elegir k\n"
    "9.  fit() + extract_cluster_assignment() + extract_centroids()\n"
    "10. hier_clust()  -  jerárquico (comparación)",
    n, FT); n += 1

slide_funcion(prs, "library() + tidymodels_prefer()",
    "Cargamos el universo tidyverse + tidymodels y, con tidyclust, el soporte "
    "de clustering. tidymodels_prefer() evita choques de nombres.",
    ['library(tidyverse)    # dplyr, ggplot2, readr...',
     'library(tidymodels)   # recipes, workflows, tune...',
     'library(tidyclust)    # k_means(), hier_clust()',
     '',
     'tidymodels_prefer()   # resuelve conflictos de nombres'],
    "- tidyclust es la extensión de tidymodels para clustering: trae k_means() "
    "y hier_clust() con la misma gramática de modelos que ya conoces.\n"
    "- tidymodels_prefer() hace que, cuando dos paquetes definen una función "
    "con el mismo nombre, gane la de tidymodels (p. ej. tune()).",
    n, FT); n += 1

slide_funcion(prs, "read_csv()",
    "Carga el CSV como tibble. El identificador (folio, nombre de municipio) "
    "no es un atributo de comportamiento: se tratará aparte.",
    ['# Apostadores: 500 cuentas (jugador_id es el folio)',
     'apostadores <- read_csv("datos.csv")',
     '',
     '# Municipios: el id es el nombre genérico',
     'municipios <- read_csv("datos.csv")'],
    "- read_csv() (de readr) lee el archivo y lo deja como tibble, infiriendo "
    "los tipos de columna.\n"
    "- Un identificador (jugador_id, municipio) NO es un indicador: si entrara "
    "al modelo, se calcularían 'distancias' entre folios, lo que no tiene "
    "sentido. En el siguiente paso le damos un rol especial.",
    n, FT); n += 1

slide_funcion(prs, "recipe() + update_role()",
    "La receta declara la fórmula y los roles de las columnas. Sin 'y' a la "
    "izquierda: es la marca del no supervisado.",
    ['receta <- recipe(~ ., data = apostadores) %>%',
     '  update_role(jugador_id, new_role = "id")',
     '',
     '# En municipios:  update_role(municipio, ...)'],
    "- La fórmula ~ . (nada a la izquierda) significa 'no hay variable "
    "objetivo': todas las columnas son predictores.\n"
    "- update_role() marca el identificador con el rol 'id'. Así NO se usa "
    "como predictor (no entra en el PCA ni en las distancias), pero se "
    "conserva en la tabla por si lo necesitamos.\n"
    "- Alternativa: step_rm() para eliminarlo del todo.",
    n, FT); n += 1

slide_funcion(prs, "step_impute_median()",
    "Rellena los valores faltantes (NAs) de las variables numéricas con su "
    "mediana. Va PRIMERO: los pasos siguientes no toleran NAs.",
    ['receta <- recipe(~ ., data = apostadores) %>%',
     '  update_role(jugador_id, new_role = "id") %>%',
     '  step_impute_median(all_numeric_predictors()) %>%',
     '  step_normalize(all_numeric_predictors())'],
    "- En apostadores, deposito_mensual_mxn tiene ~3% de NAs; en municipios, "
    "pib_per_capita_mxn ~4%. El PCA y las distancias NO admiten NAs.\n"
    "- Se usa la MEDIANA (no la media) porque los montos son asimétricos: "
    "unos pocos valores enormes inflarían la media.\n"
    "- all_numeric_predictors() aplica el paso a todas las numéricas (excluye "
    "el id, que ya no es predictor).",
    n, FT); n += 1

slide_funcion(prs, "step_normalize()",
    "Estandariza (z-score) cada variable: media 0, desviación 1. Es "
    "INDISPENSABLE antes de PCA y clustering.",
    ['  step_normalize(all_numeric_predictors())',
     '',
     '# z = (x - media) / desviación   por cada variable'],
    "- PCA maximiza varianza y el clustering mide distancias: ambos son "
    "sensibles a la ESCALA. Sin normalizar, una variable en pesos (miles) "
    "domina sobre un porcentaje (0-100).\n"
    "- El z-score deja todas las variables comparables, de modo que cada una "
    "pese por igual.\n"
    "- Regla de oro de la sesión: normaliza SIEMPRE.",
    n, FT); n += 1

slide_funcion(prs, "prep() + bake()",
    "prep() APRENDE los parámetros (medianas, medias, desviaciones) con los "
    "datos; bake() los APLICA y devuelve la tabla lista.",
    ['datos_norm <- receta %>%',
     '  prep() %>%',
     '  bake(new_data = NULL)',
     '',
     '# new_data = NULL  ->  usa los mismos datos del prep()'],
    "- prep() recorre la receta y calcula lo que cada paso necesita "
    "(las medianas para imputar, la media y desviación para normalizar).\n"
    "- bake(new_data = NULL) devuelve la tabla ya transformada con los datos "
    "de entrenamiento; con new_data = otros aplicaría lo aprendido a datos "
    "nuevos.\n"
    "- El resultado tiene media ~0 y desviación ~1 en cada columna numérica.",
    n, FT); n += 1

slide_funcion(prs, "step_pca()",
    "Añade el PCA como UN PASO MÁS de la receta. Le ponemos un id para poder "
    "extraer después la varianza y las cargas.",
    ['receta_pca <- receta %>%',
     '  step_pca(all_numeric_predictors(),',
     '           num_comp = 11, id = "pca")',
     '',
     'pca_prep <- prep(receta_pca)'],
    "- En tidymodels el PCA no es una función aparte: es step_pca() dentro de "
    "la receta, después de normalizar.\n"
    "- num_comp fija cuántas componentes calcular; id = 'pca' nos deja "
    "identificar este paso para inspeccionarlo con tidy().\n"
    "- Tras prep(), bake() devolvería las coordenadas (scores) PC01, PC02, ...",
    n, FT); n += 1

slide_funcion(prs, 'tidy(type = "variance")',
    "Extrae la varianza explicada por cada componente: el insumo del scree "
    "plot.",
    ['varianza <- tidy(pca_prep, id = "pca",',
     '                 type = "variance")',
     '',
     '# Filtramos "percent variance" y',
     '# "cumulative percent variance" para graficar'],
    "- tidy() 'ordena' la información interna de un objeto en un tibble.\n"
    "- Con type = 'variance' devuelve, por componente, la varianza, el % y el "
    "% acumulado.\n"
    "- Con eso hacemos el scree plot (barras = % por componente; línea = "
    "acumulado) y decidimos cuántas componentes conservar.",
    n, FT); n += 1

slide_funcion(prs, 'tidy(type = "coef")',
    "Extrae las CARGAS: cuánto pesa cada variable original en cada componente. "
    "Así interpretamos qué significa cada eje.",
    ['cargas <- tidy(pca_prep, id = "pca",',
     '               type = "coef") %>%',
     '  filter(component %in% c("PC1", "PC2"))'],
    "- Las cargas (loadings) son los pesos φ de cada variable en cada "
    "componente.\n"
    "- Variables con carga grande (en valor absoluto) son las que DEFINEN el "
    "eje; el signo indica la dirección.\n"
    "- Leerlas es el paso de INTERPRETACIÓN: p. ej. 'PC1 = eje de desarrollo', "
    "'PC2 = servicios vs. primario'.",
    n, FT); n += 1

slide_funcion(prs, "k_means() + set_engine()",
    "Declara el modelo de k-means. num_clusters = tune() deja k por elegir; "
    "nstart = 25 lo hace robusto.",
    ['km_spec <- k_means(num_clusters = tune()) %>%',
     '  set_engine("stats", nstart = 25)'],
    "- k_means() es de tidyclust: define el modelo igual que linear_reg() o "
    "knn definen los suyos.\n"
    "- num_clusters = tune() es un 'hueco' que llenaremos probando varios k.\n"
    "- nstart = 25 corre k-means con 25 arranques aleatorios y se queda con el "
    "mejor: evita óptimos locales (con el valor por defecto, 1, k-means puede "
    "confundir los grupos).",
    n, FT); n += 1

slide_funcion(prs, "workflow()",
    "Une la receta (preprocesamiento) y el modelo en un solo objeto que se "
    "ajusta de una vez.",
    ['wf_km <- workflow() %>%',
     '  add_recipe(receta_clust) %>%',
     '  add_model(km_spec)'],
    "- El workflow encapsula 'preparar + modelar' como una sola unidad, igual "
    "que en los modelos supervisados que ya vimos.\n"
    "- receta_clust normaliza (sin PCA): agrupamos sobre las variables "
    "estandarizadas.\n"
    "- Ventaja: el mismo preprocesamiento se aplica de forma consistente al "
    "afinar y al ajustar final.",
    n, FT); n += 1

slide_funcion(prs, "vfold_cv() + cluster_metric_set()",
    "Preparamos el remuestreo (validación cruzada) y las métricas con que "
    "evaluaremos cada k.",
    ['set.seed(123)',
     'folds <- vfold_cv(apostadores, v = 5)',
     '',
     'metricas_clust <- cluster_metric_set(',
     '  sse_within_total, silhouette_avg)'],
    "- vfold_cv() parte los datos en 5 'pliegues' para estimar las métricas de "
    "forma estable (no en un solo corte).\n"
    "- cluster_metric_set() agrupa las métricas de clustering: sse_within_total "
    "(inercia, para el CODO) y silhouette_avg (la SILUETA, más alta = mejor).\n"
    "- set.seed() fija la aleatoriedad para reproducibilidad.",
    n, FT); n += 1

slide_funcion(prs, "tune_cluster()",
    "Prueba todos los valores de k de la rejilla y calcula las métricas para "
    "cada uno. Es el equivalente no supervisado de tune_grid().",
    ['rejilla_k <- tibble(num_clusters = 1:8)',
     '',
     'afinado <- tune_cluster(',
     '  wf_km, resamples = folds,',
     '  grid = rejilla_k, metrics = metricas_clust)'],
    "- Recorre k = 1, 2, ..., 8, ajusta k-means en cada pliegue y promedia las "
    "métricas.\n"
    "- grid = rejilla con los k a probar; resamples = los pliegues; metrics = "
    "el conjunto que definimos.\n"
    "- Su salida no son grupos todavía, sino una TABLA de qué tan bien funciona "
    "cada k.",
    n, FT); n += 1

slide_funcion(prs, "collect_metrics()",
    "Recoge las métricas promediadas por k. Con ellas dibujamos el codo y la "
    "silueta y elegimos k.",
    ['metricas_k <- collect_metrics(afinado)',
     '',
     '# graficamos sse_within_total -> codo',
     '# graficamos silhouette_avg   -> silueta',
     'k_elegido <- 4'],
    "- Devuelve un tibble con num_clusters, .metric y mean (promedio entre "
    "pliegues).\n"
    "- Filtrando por .metric hacemos las dos gráficas de diagnóstico.\n"
    "- En apostadores la silueta sugería k = 2 pero el codo y la "
    "interpretación apoyan k = 4: los diagnósticos son guías, decide el "
    "sentido sustantivo.",
    n, FT); n += 1

slide_funcion(prs, "fit() + extract_cluster_assignment()",
    "Ajustamos el k-means final con el k elegido y obtenemos a qué grupo "
    "pertenece cada observación.",
    ['km_final <- k_means(num_clusters = k_elegido) %>%',
     '  set_engine("stats", nstart = 25)',
     'wf_final <- workflow() %>%',
     '  add_recipe(receta_clust) %>% add_model(km_final)',
     '',
     'ajuste_km   <- fit(wf_final, data = apostadores)',
     'asignacion  <- extract_cluster_assignment(ajuste_km)'],
    "- fit() ajusta el workflow sobre TODOS los datos con el k decidido.\n"
    "- extract_cluster_assignment() devuelve una columna .cluster con el grupo "
    "de cada fila, en el mismo orden que los datos.\n"
    "- Con bind_cols() la pegamos a la tabla original para perfilar.",
    n, FT); n += 1

slide_funcion(prs, "extract_centroids()",
    "Devuelve el centroide (promedio) de cada grupo en el espacio "
    "normalizado: dice qué eje domina cada cluster.",
    ['extract_centroids(ajuste_km)',
     '',
     '# Valores positivos  -> por encima del promedio',
     '# Valores negativos  -> por debajo del promedio'],
    "- Como los centroides están en z-score, un valor positivo en una variable "
    "significa 'este grupo está por encima del promedio en esa variable'.\n"
    "- Es una primera lectura rápida del carácter de cada grupo, antes de "
    "perfilar en unidades originales.",
    n, FT); n += 1

slide_funcion(prs, "bind_cols() + group_by() + summarise()",
    "Perfilamos: pegamos la etiqueta de grupo y promediamos las variables "
    "ORIGINALES por cluster para interpretarlas.",
    ['apostadores_grupos <- apostadores %>%',
     '  bind_cols(cluster = asignacion$.cluster)',
     '',
     'perfil <- apostadores_grupos %>%',
     '  group_by(cluster) %>%',
     '  summarise(across(where(is.numeric), mean),',
     '            n = n())'],
    "- Usamos las variables en sus UNIDADES reales (pesos, %, sesiones) para "
    "que el perfil se lea fácil.\n"
    "- group_by() + summarise() calculan el promedio de cada variable por "
    "grupo: la tabla con la que NOMBRAMOS cada cluster.\n"
    "- Este es el paso que convierte 'Cluster_1' en 'apostador en riesgo'.",
    n, FT); n += 1

slide_funcion(prs, "hier_clust()",
    "Clustering jerárquico: NO fija k de antemano; construye un árbol "
    "(dendrograma) que luego se corta. Sirve para comparar.",
    ['hc_spec <- hier_clust(num_clusters = k_elegido,',
     '            linkage_method = "ward.D2") %>%',
     '  set_engine("stats")',
     '',
     'ajuste_hc <- fit(workflow() %>%',
     '  add_recipe(receta_clust) %>%',
     '  add_model(hc_spec), data = apostadores)'],
    "- También de tidyclust, con la misma gramática. linkage_method = 'ward.D2' "
    "forma grupos compactos, comparables con k-means.\n"
    "- Comparamos ambos con table(kmeans, jerarquico): las etiquetas son "
    "arbitrarias, así que buscamos que cada grupo de un método caiga "
    "mayormente en UN solo grupo del otro. Si coinciden, hay confianza.",
    n, FT); n += 1

slide_funcion(prs, "ggplot() para los diagnósticos",
    "Todas las gráficas (scree, cargas, codo, silueta, proyección) se hacen "
    "con ggplot2 a partir de los tibbles que extrajimos.",
    ['metricas_k %>%',
     '  filter(.metric == "silhouette_avg",',
     '         num_clusters >= 2) %>%',
     '  ggplot(aes(num_clusters, mean)) +',
     '  geom_line() + geom_point()'],
    "- Como todo sale en tibbles ordenados (tidy), graficar es directo con "
    "ggplot2.\n"
    "- La silueta no se define para k = 1, por eso filtramos num_clusters >= 2.\n"
    "- Mismo patrón para el codo (sse_within_total), el scree (varianza) y la "
    "proyección PC1-PC2 coloreada por grupo.",
    n, FT); n += 1

slide_conclusiones(prs, "En resumen: el flujo en tidymodels",
    "• recipe() + update_role() + step_impute_median() + step_normalize(): "
    "preparar (¡siempre normalizar!).\n\n"
    "• step_pca() + tidy(): PCA y su lectura (varianza con 'variance', cargas "
    "con 'coef').\n\n"
    "• k_means()/hier_clust() + workflow(): el modelo, con nstart = 25 para "
    "k-means robusto.\n\n"
    "• vfold_cv() + cluster_metric_set() + tune_cluster() + collect_metrics(): "
    "elegir k (codo y silueta).\n\n"
    "• fit() + extract_cluster_assignment() + group_by()/summarise(): asignar "
    "grupos y perfilarlos para decidir.",
    n, FT); n += 1

slide_cierre(prs)

prs.save(OUT)
print("Presentacion de funciones S19 guardada:", OUT, "·", n - 1, "slides")
