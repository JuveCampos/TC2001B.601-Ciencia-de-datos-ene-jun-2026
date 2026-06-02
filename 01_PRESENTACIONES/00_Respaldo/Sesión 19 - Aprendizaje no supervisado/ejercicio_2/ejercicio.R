options(scipen = 999)

# =============================================================================
# SESIÓN 19 — APRENDIZAJE NO SUPERVISADO
# Ejercicio 2: tipologías de municipios (PCA + clustering)
# Enfoque tidymodels nativo: recipes + tidyclust
# =============================================================================
#
# Idea central:
# -------------
# En el aprendizaje NO supervisado NO hay variable objetivo. NO partimos en
# entrenamiento/prueba: no hay acierto que medir. El objetivo es DESCUBRIR
# estructura.
#
# Caso de política pública: una secretaría de desarrollo tiene 400 municipios
# descritos por indicadores de urbanización, economía, educación, servicios y
# rezago. No existe una clasificación oficial previa. ¿Podemos agrupar los
# municipios en TIPOLOGÍAS comparables para diseñar intervenciones
# diferenciadas (no la misma política para un municipio urbano conectado que
# para uno rural marginado)? (Datos ficticios, nombres genéricos.)
#
# Mismas dos familias de técnicas, mismo ecosistema tidymodels:
#   * PCA con recipes::step_pca()
#   * Clustering con tidyclust (k_means y hier_clust) dentro de workflow()

# Librerías ----
library(tidyverse)
library(tidymodels)
library(tidyclust)

tidymodels_prefer()

# -----------------------------------------------------------------------------
# 1. CARGA Y EXPLORACIÓN
# -----------------------------------------------------------------------------

municipios <- read_csv("datos.csv")

glimpse(municipios)
summary(municipios)

# 'municipio' es un IDENTIFICADOR (nombre genérico): no es un indicador, se
# excluye del modelo. Revisamos NAs (PCA y distancias no los toleran).
colSums(is.na(municipios))

# Colinealidad: indice_rezago_social se construyó a partir de escolaridad,
# conectividad y agua, así que está muy correlacionado con ellas. No lo
# eliminamos; el PCA lo absorbe al proyectar sobre ejes ortogonales.
municipios %>%
  select(where(is.numeric)) %>%
  drop_na() %>%
  cor() %>%
  round(2) %>%
  .[c("escolaridad_prom_anios", "pct_viviendas_internet",
      "pct_agua_entubada"), "indice_rezago_social", drop = FALSE]

# ¿POR QUÉ NORMALIZAR (z-score) ES INDISPENSABLE?
# -----------------------------------------------
# Conviven porcentajes (0–100), años de escolaridad (0–15), tasas (por mil) y
# pesos (PIB per cápita de decenas a cientos de miles, densidad en miles).
# PCA y clustering son SENSIBLES A LA ESCALA: sin normalizar, el PIB y la
# densidad dominarían por completo las distancias y las tipologías reflejarían
# las UNIDADES, no el perfil socioeconómico. El z-score iguala el peso.

# -----------------------------------------------------------------------------
# 2. RECETA DE PREPROCESAMIENTO (recipes)
# -----------------------------------------------------------------------------
receta <- recipe(~ ., data = municipios) %>%
  update_role(municipio, new_role = "id") %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors())

# prep() aprende; bake() aplica. Verificamos media ~0 y desviación ~1.
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
receta_pca <- recipe(~ ., data = municipios) %>%
  update_role(municipio, new_role = "id") %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_pca(all_numeric_predictors(), num_comp = 11, id = "pca")

pca_prep <- prep(receta_pca)

# 3a. VARIANZA EXPLICADA (scree plot) -----------------------------------------
varianza <- tidy(pca_prep, id = "pca", type = "variance") %>%
  filter(terms %in% c("percent variance", "cumulative percent variance")) %>%
  mutate(terms = recode(terms,
                        "percent variance" = "individual",
                        "cumulative percent variance" = "acumulada"))
varianza %>% filter(component <= 6)

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
cargas <- tidy(pca_prep, id = "pca", type = "coef") %>%
  filter(component %in% c("PC1", "PC2"))

cargas %>%
  mutate(terms = fct_reorder(terms, value)) %>%
  ggplot(aes(value, terms, fill = value > 0)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ component) +
  scale_fill_manual(values = c(`TRUE` = "#1e4c7d", `FALSE` = "#d62828")) +
  labs(title = "Cargas de las variables en PC1 y PC2",
       x = "Peso (carga)", y = NULL) +
  theme_minimal(base_size = 11)

# INTERPRETACIÓN ESPERADA: los datos tienen DOS ejes casi independientes y eso
# se ve en las cargas. Uno suele ser DESARROLLO (escolaridad, internet, agua,
# PIB y rezago invertido); el otro, ESTRUCTURA económica (servicios/urbano vs.
# sector primario y población indígena). El alumno debe leer 'cargas' y decir
# qué representa cada componente según qué variables pesan en ella.

# 3c. PROYECCIÓN DE LOS MUNICIPIOS EN PC1-PC2 ---------------------------------
scores <- bake(pca_prep, new_data = NULL) %>%
  rename(PC1 = PC01, PC2 = PC02)

scores %>%
  ggplot(aes(PC1, PC2)) +
  geom_point(alpha = 0.5, color = "#1e4c7d") +
  labs(title = "Los 400 municipios proyectados en PC1-PC2",
       subtitle = "Cada punto es un municipio; se intuye un gradiente de desarrollo") +
  theme_minimal(base_size = 12)

# -----------------------------------------------------------------------------
# 4. ¿CUÁNTAS TIPOLOGÍAS? ELECCIÓN DE k CON tune_cluster()
# -----------------------------------------------------------------------------
receta_clust <- recipe(~ ., data = municipios) %>%
  update_role(municipio, new_role = "id") %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors())

# nstart = 25: k-means depende del arranque aleatorio de centroides. Probar 25
# arranques y quedarse con el mejor evita caer en un óptimo local malo. Es
# IMPRESCINDIBLE: con el valor por defecto (1) k-means puede confundir las
# tipologías.
km_spec <- k_means(num_clusters = tune()) %>%
  set_engine("stats", nstart = 25)

wf_km <- workflow() %>%
  add_recipe(receta_clust) %>%
  add_model(km_spec)

metricas_clust <- cluster_metric_set(sse_within_total, silhouette_avg)

rejilla_k <- tibble(num_clusters = 1:8)
set.seed(123)
folds <- vfold_cv(municipios, v = 5)

set.seed(123)
afinado <- tune_cluster(
  wf_km,
  resamples = folds,
  grid = rejilla_k,
  metrics = metricas_clust
)

metricas_k <- collect_metrics(afinado)
metricas_k

# Método del CODO.
metricas_k %>%
  filter(.metric == "sse_within_total") %>%
  ggplot(aes(num_clusters, mean)) +
  geom_line(color = "#1e4c7d") +
  geom_point(size = 2, color = "#1e4c7d") +
  scale_x_continuous(breaks = 1:8) +
  labs(title = "Método del codo (inercia intra-grupo)",
       x = "Número de tipologías (k)", y = "WSS promedio") +
  theme_minimal(base_size = 12)

# Método de la SILUETA.
metricas_k %>%
  filter(.metric == "silhouette_avg", num_clusters >= 2) %>%
  ggplot(aes(num_clusters, mean)) +
  geom_line(color = "#2d7a7a") +
  geom_point(size = 2, color = "#2d7a7a") +
  scale_x_continuous(breaks = 2:8) +
  labs(title = "Método de la silueta (promedio por k)",
       x = "Número de tipologías (k)", y = "Silueta promedio") +
  theme_minimal(base_size = 12)

# A diferencia del ejercicio de apostadores, aquí los diagnósticos COINCIDEN:
# el codo se aplana en k = 4 y la silueta es máxima en k = 4. Cuando ambos
# apuntan al mismo valor, la elección es clara. Elegimos k = 4.
k_elegido <- 4

# -----------------------------------------------------------------------------
# 5. K-MEANS FINAL
# -----------------------------------------------------------------------------
km_final <- k_means(num_clusters = k_elegido) %>%
  set_engine("stats", nstart = 25)

wf_final <- workflow() %>%
  add_recipe(receta_clust) %>%
  add_model(km_final)

set.seed(123)
ajuste_km <- fit(wf_final, data = municipios)

asignacion <- extract_cluster_assignment(ajuste_km)
table(asignacion$.cluster)

# Centroides normalizados: qué eje domina cada tipología.
extract_centroids(ajuste_km)

# 5a. VISUALIZACIÓN sobre PC1-PC2 ---------------------------------------------
scores_grupos <- scores %>%
  bind_cols(cluster = asignacion$.cluster)

scores_grupos %>%
  ggplot(aes(PC1, PC2, color = cluster)) +
  geom_point(alpha = 0.7) +
  scale_color_manual(values = c("#1e4c7d", "#2d7a7a", "#c97b2a", "#7d3c66")) +
  labs(title = paste0("k-means (k = ", k_elegido, ") sobre PC1-PC2"),
       color = "Tipología") +
  theme_minimal(base_size = 12)

# 5b. PERFILADO (unidades ORIGINALES) -----------------------------------------
municipios_grupos <- municipios %>%
  bind_cols(cluster = asignacion$.cluster)

perfil <- municipios_grupos %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    pct_urbano = mean(pct_urbano),
    escolaridad_prom_anios = mean(escolaridad_prom_anios),
    pct_viviendas_internet = mean(pct_viviendas_internet),
    pct_ocupados_primario = mean(pct_ocupados_primario),
    pct_poblacion_indigena = mean(pct_poblacion_indigena),
    tasa_mort_infantil = mean(tasa_mort_infantil),
    pib_per_capita_mxn = mean(pib_per_capita_mxn, na.rm = TRUE),
    indice_rezago_social = mean(indice_rezago_social)
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 1)))
perfil

# INTERPRETACIÓN (leer 'perfil' y los centroides): las tipologías cruzan DOS
# ejes (nivel de desarrollo x estructura económica servicios/primario):
#  - Urbano desarrollado: muy urbano, alta escolaridad e internet, PIB alto,
#    baja mortalidad, rezago negativo (servicios).
#  - Agroindustrial próspero: desarrollo alto PERO con peso del sector primario
#    (escolaridad/PIB altos, primario alto, poca población indígena).
#  - Urbano popular: urbano y de servicios, pero con desarrollo bajo
#    (escolaridad e internet bajos, mortalidad alta).
#  - Rural marginado: sector primario alto, baja escolaridad y conectividad,
#    mortalidad y rezago altos -> prioridad de intervención.
# Cada tipología pide una política distinta (no la misma para un urbano popular
# que para un rural marginado). El alumno la nombra con las cifras reales.

# -----------------------------------------------------------------------------
# 6. CLUSTERING JERÁRQUICO (comparación)
# -----------------------------------------------------------------------------
hc_spec <- hier_clust(num_clusters = k_elegido, linkage_method = "ward.D2") %>%
  set_engine("stats")

wf_hc <- workflow() %>%
  add_recipe(receta_clust) %>%
  add_model(hc_spec)

ajuste_hc <- fit(wf_hc, data = municipios)
asignacion_hc <- extract_cluster_assignment(ajuste_hc)

# Comparación: etiquetas arbitrarias; buscamos que cada grupo de un método
# caiga mayormente en UN solo grupo del otro (misma estructura).
table(kmeans = asignacion$.cluster, jerarquico = asignacion_hc$.cluster)
