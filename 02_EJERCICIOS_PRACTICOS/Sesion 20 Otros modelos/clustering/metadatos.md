# Metadatos — Perfiles socioeconómicos de municipios (clustering)

> **Dataset REUTILIZADO de la Sesión 18 (clustering / aprendizaje no
> supervisado).** Es el mismo conjunto de municipios con indicadores
> socioeconómicos que usamos para introducir agrupamiento; aquí lo
> reaprovechamos para comparar **k-means, agrupamiento jerárquico (hclust)
> y DBSCAN**.

## Nombre

`datos.csv` — Indicadores socioeconómicos municipales (México).

## Contexto / problema

Una oficina de política pública quiere **agrupar municipios** con perfiles
socioeconómicos parecidos (pobreza, carencias, ruralidad, acceso a internet,
marginación) para diseñar intervenciones diferenciadas. No hay una etiqueta
"correcta" de grupo: se trata de **descubrir estructura** en los datos
(aprendizaje no supervisado). Comparamos tres familias de algoritmos para ver
qué tan estables y plausibles son los grupos que cada uno encuentra.

## Tipo de problema

Clustering (aprendizaje **no supervisado**).

## Variable objetivo

**Ninguna.** No hay variable a predecir; el objetivo es agrupar
observaciones similares.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango (aprox.) | Descripción |
|---|---|---|---|---|
| clave_municipio | character | — | MUN001–MUN500 | Identificador del municipio. **No es predictor; se remueve.** |
| pct_pobreza | numérica | % | 8.6 – 99.0 | Porcentaje de población en pobreza. |
| pct_carencia_educativa | numérica | % | 1.0 – 77.0 | Porcentaje con carencia por rezago educativo. |
| pct_carencia_salud | numérica | % | 1.0 – 80.8 | Porcentaje con carencia por acceso a salud. |
| ingreso_promedio_mxn | numérica | MXN/mes | 1,500 – 19,280 | Ingreso mensual promedio. **~4% NAs (20).** |
| pct_poblacion_rural | numérica | % | 0 – 100 | Porcentaje de población rural. |
| pct_acceso_internet | numérica | % | 1.0 – 99.0 | Porcentaje de hogares con internet. |
| densidad_pob_km2 | numérica | hab/km² | 1.0 – 2,504 | Densidad poblacional. |
| tasa_alfabetizacion | numérica | % | 61.1 – 100 | Tasa de alfabetización. |
| grado_marginacion_idx | numérica | índice | 0.14 – 1.75 | Índice de grado de marginación. **Colineal con pct_pobreza.** |

## Número de observaciones

500 filas × 10 columnas (9 indicadores numéricos tras remover el
identificador). Se espera del orden de **~4 perfiles latentes** de municipios.

## Notas

- **Valores faltantes (NAs):** `ingreso_promedio_mxn` ~4% (20 NAs). Se imputa
  con la mediana antes de normalizar (en clustering no podemos dejar NAs:
  todas las distancias se romperían).
- **Colinealidad:** `grado_marginacion_idx` está muy correlacionado con
  `pct_pobreza` (la marginación se construye en parte a partir de la pobreza).
  Se comenta en el ejercicio; en clustering la colinealidad sobre-pondera esa
  dimensión, por lo que conviene tenerla presente al interpretar.
- **Normalización OBLIGATORIA:** las variables están en escalas muy distintas
  (porcentajes 0–100, ingreso en miles de pesos, densidad hasta 2,500). Sin
  normalizar (`step_normalize` / `scale`), la densidad y el ingreso dominarían
  por completo las distancias euclidianas. Por eso **siempre** estandarizamos
  (z-score) antes de k-means, jerárquico y DBSCAN.
- **Sin variable objetivo:** no hay accuracy ni AUC; la calidad de los grupos
  se juzga con criterios como la silueta, la interpretabilidad de los perfiles
  y la estabilidad entre métodos.
- **Origen:** dataset **reutilizado de la Sesión 18**; idéntico en estructura
  al usado allí para clustering.
