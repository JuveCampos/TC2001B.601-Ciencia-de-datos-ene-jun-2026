options(scipen = 999)

# =============================================================================
# SESIÓN 19 — APRENDIZAJE NO SUPERVISADO
# Ejercicio 1: patrones de apostadores en línea (PCA + clustering)
# Enfoque tidymodels nativo: recipes + tidyclust
# =============================================================================
#
# Idea central:
# -------------
# En el aprendizaje NO supervisado NO hay variable objetivo (no hay una "y"
# que predecir). Por eso NO partimos los datos en entrenamiento/prueba: no
# existe un acierto que medir. El objetivo es DESCUBRIR estructura.
#
# Caso: una plataforma de apuestas en línea quiere entender el comportamiento
# de sus 500 cuentas para diseñar mensajes de JUEGO RESPONSABLE. Nadie etiquetó
# a los jugadores. ¿Existen perfiles naturales de apostadores? ¿cuántos hay y
# qué los distingue? (Datos ficticios.)
#
# Dos familias de técnicas:
#   * PCA  : reduce las 11 variables a unos pocos ejes que concentran la
#            varianza; sirve para visualizar y ver qué variables "van juntas".
#   * Clustering (k-means y jerárquico): agrupa cuentas por cercanía.
#
# Usamos el ecosistema tidymodels:
#   - recipes  para el preprocesamiento (imputar, normalizar, PCA).
#   - tidyclust para los modelos de clustering dentro de un workflow().

# Librerías ----
library(tidyverse)
library(tidymodels)
library(tidyclust)

tidymodels_prefer()

# -----------------------------------------------------------------------------
# 1. CARGA Y EXPLORACIÓN
# -----------------------------------------------------------------------------

apostadores <- read_csv("datos.csv")

# Dimensiones, tipos y faltantes.
glimpse(apostadores)
summary(apostadores)

# jugador_id es un IDENTIFICADOR, no un indicador de comportamiento: lo
# excluiremos del modelo (no tiene sentido medir "distancias" entre folios).
# ¿Cuántos NAs hay por columna? Los algoritmos de distancia y el PCA NO
# toleran NAs, así que habrá que imputarlos.
colSums(is.na(apostadores))

# Colinealidad: deposito_mensual_mxn se construye a partir de la apuesta
# promedio y del número de depósitos, así que esperamos correlación alta.
# No la eliminamos; el PCA la absorbe al proyectar sobre ejes ortogonales,
# pero conviene tenerla presente al leer las cargas.
apostadores %>%
  select(where(is.numeric)) %>%
  drop_na() %>%
  cor() %>%
  round(2) %>%
  .[, c("apuesta_promedio_mxn", "num_depositos_mes", "deposito_mensual_mxn")]

# ¿POR QUÉ NORMALIZAR (z-score) ES INDISPENSABLE?
# -----------------------------------------------
# Las variables viven en escalas muy distintas: porcentajes (0-100), número
# de sesiones (0-20) y pesos (apuestas y depósitos de cientos a miles). Tanto
# el PCA (maximiza varianza) como el clustering (mide distancias) son
# SENSIBLES A LA ESCALA. Sin normalizar, deposito_mensual_mxn y
# apuesta_promedio_mxn (números grandes) dominarían todo y los grupos
# reflejarían las UNIDADES, no el comportamiento. El z-score deja cada
# variable con media 0 y desviación 1: todas pesan igual.

# -----------------------------------------------------------------------------
# 2. RECETA DE PREPROCESAMIENTO (recipes)
# -----------------------------------------------------------------------------
#
# Una sola receta resume todo el preprocesamiento. La reutilizaremos tanto
# para el PCA como para el clustering.
#   update_role : marca jugador_id como "id" para que NO entre como predictor.
#   step_impute_median : rellena los NAs con la mediana (robusta a asimetría).
#   step_normalize     : z-score sobre todos los indicadores numéricos.
receta <- recipe(~ ., data = apostadores) %>%
  update_role(jugador_id, new_role = "id") %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors())

# prep() APRENDE las medianas y los parámetros de escala a partir de los datos;
# bake() los APLICA y devuelve la tabla ya lista. La inspeccionamos para
# verificar que cada indicador quedó con media ~0 y desviación ~1.
datos_norm <- receta %>%
  prep() %>%
  bake(new_data = NULL)

datos_norm %>%
  select(where(is.numeric)) %>%
  summarise(across(everything(), list(media = mean, desv = sd))) %>%
  glimpse()

# -----------------------------------------------------------------------------
# 3. PCA — ANÁLISIS DE COMPONENTES PRINCIPALES
# -----------------------------------------------------------------------------
#
# En tidymodels el PCA es un PASO MÁS de la receta: step_pca(). Partimos de
# la normalización y añadimos el PCA. Le ponemos un id para poder extraer
# después la varianza y las cargas con tidy().
receta_pca <- recipe(~ ., data = apostadores) %>%
  update_role(jugador_id, new_role = "id") %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_pca(all_numeric_predictors(), num_comp = 11, id = "pca")

pca_prep <- prep(receta_pca)

# 3a. VARIANZA EXPLICADA (scree plot) -----------------------------------------
# tidy(..., type = "variance") devuelve la varianza por componente en varias
# formas; nos quedamos con el porcentaje y el acumulado.
varianza <- tidy(pca_prep, id = "pca", type = "variance") %>%
  filter(terms %in% c("percent variance", "cumulative percent variance")) %>%
  mutate(terms = recode(terms,
                        "percent variance" = "individual",
                        "cumulative percent variance" = "acumulada"))
varianza %>% filter(component <= 6)

# Scree plot: % de varianza por componente. Buscamos el "codo": a partir de
# qué componente añadir más aporta poco.
varianza %>%
  filter(terms == "individual", component <= 11) %>%
  ggplot(aes(component, value)) +
  geom_col(fill = "#1e4c7d") +
  geom_text(aes(label = paste0(round(value), "%")), vjust = -0.4, size = 3) +
  scale_x_continuous(breaks = 1:11) +
  labs(title = "Varianza explicada por componente (scree plot)",
       x = "Componente principal", y = "% de varianza") +
  theme_minimal(base_size = 12)

# 3b. CARGAS / LOADINGS -------------------------------------------------------
# tidy(..., type = "coef") da el peso de cada variable original en cada
# componente. Leerlas nos dice QUÉ significa cada eje.
cargas <- tidy(pca_prep, id = "pca", type = "coef") %>%
  filter(component %in% c("PC1", "PC2"))

# Gráfica de cargas para PC1 y PC2: variables con barras grandes (en valor
# absoluto) son las que definen el eje. El signo indica la dirección.
cargas %>%
  mutate(terms = fct_reorder(terms, value)) %>%
  ggplot(aes(value, terms, fill = value > 0)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ component) +
  scale_fill_manual(values = c(`TRUE` = "#1e4c7d", `FALSE` = "#d62828")) +
  labs(title = "Cargas de las variables en PC1 y PC2",
       x = "Peso (carga)", y = NULL) +
  theme_minimal(base_size = 11)

# 3c. PROYECCIÓN DE LAS CUENTAS EN EL PLANO PC1-PC2 ---------------------------
# bake() sobre la receta con PCA devuelve las coordenadas (scores) de cada
# cuenta en los nuevos ejes. (bake las nombra PC01, PC02, …; renombramos las
# dos primeras a PC1 y PC2 para que coincidan con las cargas.)
scores <- bake(pca_prep, new_data = NULL) %>%
  rename(PC1 = PC01, PC2 = PC02)

scores %>%
  ggplot(aes(PC1, PC2)) +
  geom_point(alpha = 0.5, color = "#1e4c7d") +
  labs(title = "Las 500 cuentas proyectadas en PC1-PC2",
       subtitle = "Cada punto es un jugador; ya se intuyen agrupamientos") +
  theme_minimal(base_size = 12)

# -----------------------------------------------------------------------------
# 4. ¿CUÁNTOS GRUPOS? ELECCIÓN DE k CON tune_cluster()
# -----------------------------------------------------------------------------
#
# k-means necesita que fijemos k de antemano. En tidymodels declaramos el
# modelo con num_clusters = tune() y dejamos que tune_cluster() pruebe varios
# valores de k, midiendo dos diagnósticos:
#   * sse_within_total : inercia intra-grupo (para el método del CODO).
#   * silhouette_avg   : qué tan separados y compactos quedan los grupos
#                        (cuanto MÁS ALTA, mejor).

# Receta para clustering (sin PCA: agrupamos sobre las variables normalizadas).
receta_clust <- recipe(~ ., data = apostadores) %>%
  update_role(jugador_id, new_role = "id") %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors())

# Modelo k-means con k por afinar. nstart = 25: k-means depende del arranque
# aleatorio de los centroides; probar 25 arranques y quedarse con el mejor
# evita caer en un óptimo local malo (el valor por defecto, 1, es frágil).
km_spec <- k_means(num_clusters = tune()) %>%
  set_engine("stats", nstart = 25)

# workflow() une receta + modelo.
wf_km <- workflow() %>%
  add_recipe(receta_clust) %>%
  add_model(km_spec)

# Conjunto de métricas de clustering.
metricas_clust <- cluster_metric_set(sse_within_total, silhouette_avg)

# Rejilla de valores de k a probar y remuestreo (validación cruzada) para
# estimar las métricas de forma estable.
rejilla_k <- tibble(num_clusters = 1:8)
set.seed(123)
folds <- vfold_cv(apostadores, v = 5)

set.seed(123)
afinado <- tune_cluster(
  wf_km,
  resamples = folds,
  grid = rejilla_k,
  metrics = metricas_clust
)

# Recolectamos las métricas promediadas por k.
metricas_k <- collect_metrics(afinado)
metricas_k

# Método del CODO (WSS / inercia intra-grupo).
metricas_k %>%
  filter(.metric == "sse_within_total") %>%
  ggplot(aes(num_clusters, mean)) +
  geom_line(color = "#1e4c7d") +
  geom_point(size = 2, color = "#1e4c7d") +
  scale_x_continuous(breaks = 1:8) +
  labs(title = "Método del codo (inercia intra-grupo)",
       x = "Número de grupos (k)", y = "WSS promedio") +
  theme_minimal(base_size = 12)

# Método de la SILUETA (más alta = mejor; no se define para k = 1).
metricas_k %>%
  filter(.metric == "silhouette_avg", num_clusters >= 2) %>%
  ggplot(aes(num_clusters, mean)) +
  geom_line(color = "#2d7a7a") +
  geom_point(size = 2, color = "#2d7a7a") +
  scale_x_continuous(breaks = 2:8) +
  labs(title = "Método de la silueta (promedio por k)",
       x = "Número de grupos (k)", y = "Silueta promedio") +
  theme_minimal(base_size = 12)

# LECTURA DE LOS DIAGNÓSTICOS (un caso realista donde NO coinciden):
# - La silueta es más alta en k = 2: si solo quisiéramos la división más
#   "limpia", separaríamos jugadores intensos vs. ligeros y ya.
# - Pero el CODO sigue bajando de forma importante hasta k = 4 y luego se
#   aplana: hay estructura más fina que k = 2 esconde.
# Los diagnósticos son GUÍAS, no veredictos. Como el objetivo es accionable
# (diseñar mensajes de juego responsable para perfiles distinguibles),
# elegimos k = 4: da grupos interpretables y separados (recreativo, entusiasta,
# en riesgo y gran apostador). Siempre conviene confirmar que los grupos
# elegidos tengan sentido sustantivo, no solo métrico.
k_elegido <- 4

# -----------------------------------------------------------------------------
# 5. K-MEANS FINAL CON EL k ELEGIDO
# -----------------------------------------------------------------------------
#
# Fijamos num_clusters = k_elegido y ajustamos el workflow sobre TODOS los
# datos. (nstart = 25 de nuevo para un resultado estable; set.seed para
# reproducibilidad.)
km_final <- k_means(num_clusters = k_elegido) %>%
  set_engine("stats", nstart = 25)

wf_final <- workflow() %>%
  add_recipe(receta_clust) %>%
  add_model(km_final)

set.seed(123)
ajuste_km <- fit(wf_final, data = apostadores)

# Asignación de grupo de cada cuenta (alineada con las filas de los datos).
asignacion <- extract_cluster_assignment(ajuste_km)
table(asignacion$.cluster)

# Centroides en el espacio NORMALIZADO (útil para ver qué eje domina cada
# grupo: valores positivos = por encima del promedio, negativos = por debajo).
extract_centroids(ajuste_km)

# 5a. VISUALIZACIÓN DE LOS GRUPOS sobre PC1-PC2 -------------------------------
# Pegamos la etiqueta de grupo a las coordenadas del PCA.
scores_grupos <- scores %>%
  bind_cols(cluster = asignacion$.cluster)

scores_grupos %>%
  ggplot(aes(PC1, PC2, color = cluster)) +
  geom_point(alpha = 0.7) +
  scale_color_manual(values = c("#1e4c7d", "#2d7a7a", "#c97b2a", "#7d3c66")) +
  labs(title = paste0("k-means (k = ", k_elegido, ") sobre el plano PC1-PC2"),
       color = "Grupo") +
  theme_minimal(base_size = 12)

# 5b. PERFILADO DE LOS GRUPOS (en unidades ORIGINALES) ------------------------
# Para interpretar QUÉ tipo de jugador es cada grupo, calculamos las medias de
# las variables originales (no las normalizadas) por cluster.
apostadores_grupos <- apostadores %>%
  bind_cols(cluster = asignacion$.cluster)

perfil <- apostadores_grupos %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    sesiones_semana = mean(sesiones_semana),
    apuesta_promedio_mxn = mean(apuesta_promedio_mxn),
    deposito_mensual_mxn = mean(deposito_mensual_mxn, na.rm = TRUE),
    pct_juego_madrugada = mean(pct_juego_madrugada),
    pct_incremento_tras_perdida = mean(pct_incremento_tras_perdida),
    retiros_mes = mean(retiros_mes),
    ratio_perdida_pct = mean(ratio_perdida_pct)
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 1)))
perfil

# INTERPRETACIÓN (leer 'perfil' y 'extract_centroids'):
# Comparando las medias por grupo se nombra cada perfil; por ejemplo:
#  - Recreativo ocasional: pocas sesiones, apuestas y depósitos bajos, casi
#    nada de madrugada ni de perseguir pérdidas.
#  - Entusiasta controlado: juega seguido y variado, pero RETIRA y no persigue.
#  - En riesgo / problemático: muchas sesiones, alto % de madrugada, persigue
#    pérdidas (incremento alto), casi no retira -> objetivo de juego responsable.
#  - Gran apostador ("ballena"): apuestas y depósitos enormes, pero controlado.
# El alumno debe nombrar cada grupo a partir de las cifras reales observadas.

# -----------------------------------------------------------------------------
# 6. CLUSTERING JERÁRQUICO (comparación)
# -----------------------------------------------------------------------------
#
# El jerárquico no fija k de antemano: fusiona puntos por cercanía formando un
# árbol y luego lo "cortamos". En tidyclust se usa igual, con hier_clust().
hc_spec <- hier_clust(num_clusters = k_elegido, linkage_method = "ward.D2") %>%
  set_engine("stats")

wf_hc <- workflow() %>%
  add_recipe(receta_clust) %>%
  add_model(hc_spec)

ajuste_hc <- fit(wf_hc, data = apostadores)
asignacion_hc <- extract_cluster_assignment(ajuste_hc)

# COMPARACIÓN k-means vs jerárquico. Las etiquetas de grupo son arbitrarias
# (el "Cluster_1" de un método no tiene por qué ser el del otro). NO miramos
# la diagonal, sino si cada grupo de un método cae mayormente en UN solo grupo
# del otro: eso indica que ambos descubren la misma estructura.
table(kmeans = asignacion$.cluster, jerarquico = asignacion_hc$.cluster)
