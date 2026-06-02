# Metadatos — Tipologías de municipios

## Nombre

Indicadores de desarrollo municipal (`datos.csv`). **Datos ficticios** con
nombres genéricos, generados para fines didácticos (ver `_genera_datos.R`).

## Contexto / problema

Una secretaría de desarrollo cuenta con 400 municipios descritos por
indicadores de urbanización, economía, educación, servicios y rezago. No
existe una clasificación oficial previa que diga "qué tipo" de municipio es
cada uno. La pregunta es de política pública: **¿podemos agrupar los
municipios en tipologías comparables** para diseñar intervenciones
diferenciadas (no la misma política para un municipio urbano desarrollado que
para uno rural marginado)? Queremos que las tipologías emerjan de los datos,
sin imponer categorías de antemano.

## Tipo de problema

Clustering — aprendizaje **no supervisado**. No hay una etiqueta de "tipo de
municipio" que predecir; buscamos segmentar a partir de la estructura de los
indicadores. Por lo tanto **no** hay partición entrenamiento/prueba.

## Variable objetivo

Ninguna — aprendizaje no supervisado. Salvo el identificador, todas las
columnas son indicadores descriptivos; ninguna es una respuesta a predecir.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango aprox. | Descripción |
|---|---|---|---|---|
| municipio | carácter | — (id) | Municipio_001 … _400 | **Identificador** (nombre genérico); rol `id`, no es indicador. |
| pct_urbano | numérica | % | 0 – 100 | Población en localidades urbanas. |
| pct_ocupados_primario | numérica | % | 0 – 100 | Ocupados en sector primario (agro, pesca). |
| pct_ocupados_servicios | numérica | % | 0 – 100 | Ocupados en servicios. |
| densidad_pob_km2 | numérica | hab/km² | baja – muy alta | Densidad poblacional. |
| pct_poblacion_indigena | numérica | % | 0 – 50 | Población que se reconoce indígena (mayor en municipios rurales/primarios). |
| escolaridad_prom_anios | numérica | años | 4 – 14 | Escolaridad promedio. |
| pct_viviendas_internet | numérica | % | 0 – 100 | Viviendas con internet. |
| pct_agua_entubada | numérica | % | 50 – 100 | Viviendas con agua entubada. |
| tasa_mort_infantil | numérica | por mil | 3 – 28 | Mortalidad infantil. |
| pib_per_capita_mxn | numérica | MXN | ~40,000 – 280,000 | PIB per cápita anual. **Tiene NAs (~4%).** |
| gasto_pub_per_capita_mxn | numérica | MXN | ~4,000 – 11,000 | Gasto público per cápita. *Casi independiente de los ejes (ruido informativo).* |
| indice_rezago_social | numérica | índice z | continuo | Índice de rezago social. **Colineal** (recombinación de escolaridad, internet y agua). |

## Número de observaciones

400 municipios (filas) × 13 columnas (12 indicadores numéricos + 1 id).

## Notas

- **Valores faltantes (NAs):** `pib_per_capita_mxn` tiene 16 NAs (≈ 4%),
  municipios sin dato económico reciente. El PCA y los algoritmos de distancia
  **no toleran NAs**, así que se imputan con la **mediana** (robusta a la
  asimetría del PIB) vía `step_impute_median()`.
- **Colinealidad:** `indice_rezago_social` es prácticamente una combinación de
  escolaridad, conectividad y agua, así que está muy correlacionado con ellas.
  Esa redundancia refuerza el "eje de desarrollo"; el PCA la absorbe al
  construir componentes ortogonales. La dejamos y la comentamos.
- **Escalas heterogéneas:** porcentajes (0–100), años (4–14), tasas (por mil)
  y pesos (PIB en cientos de miles, densidad en miles). Por eso es
  **indispensable normalizar (z-score) antes de PCA y clustering**: sin
  normalizar, el PIB y la densidad dominarían las distancias y las tipologías
  reflejarían solo las unidades, no el perfil socioeconómico.
- **Estructura latente — dos ejes:** el dataset se construyó con **dos
  dimensiones casi independientes**: (1) nivel de **desarrollo** y (2)
  **estructura económica** (servicios/urbano vs. primario/rural). Su cruce
  produce **cuatro** tipologías (urbano desarrollado, agroindustrial próspero,
  urbano popular, rural marginado). A diferencia de un simple gradiente, este
  diseño hace que el codo y la silueta coincidan claramente en k = 4 y que
  k-means y el jerárquico recuperen las mismas tipologías.
- **`nstart` importa:** con k-means de un solo arranque (`nstart = 1`, el
  valor por defecto) el algoritmo puede caer en un óptimo local y confundir
  tipologías. Usamos `set_engine("stats", nstart = 25)`.

## Enfoque técnico (tidymodels nativo)

- **Preprocesamiento:** `recipe()` + `update_role()` (id) +
  `step_impute_median()` + `step_normalize()`.
- **PCA:** `step_pca()`; `tidy(type = "variance")` (scree) y
  `tidy(type = "coef")` (cargas).
- **Clustering:** `tidyclust::k_means()` (con `nstart = 25`) y `hier_clust()`
  en un `workflow()`; selección de *k* con `tune_cluster()` +
  `cluster_metric_set(sse_within_total, silhouette_avg)`;
  `extract_cluster_assignment()` y `extract_centroids()`.
