# Metadatos — Patrones de apostadores en línea

## Nombre

Comportamiento de apostadores en línea (`datos.csv`). **Datos ficticios**
generados para fines didácticos (ver `_genera_datos.R`).

## Contexto / problema

Una plataforma de apuestas en línea tiene 500 cuentas descritas por su
comportamiento de juego (frecuencia, montos, depósitos, horarios y señales de
riesgo). El área de **juego responsable** quiere diseñar intervenciones
diferenciadas, pero nadie clasificó a los jugadores de antemano. La pregunta
es exploratoria: **¿existen perfiles naturales de apostadores?** ¿cuántos hay
y, sobre todo, cuál concentra las señales de comportamiento problemático para
priorizar las alertas? Queremos que los grupos emerjan de los datos, sin
imponer categorías previas.

## Tipo de problema

Clustering — aprendizaje **no supervisado**. No hay una etiqueta de "tipo de
jugador" que predecir; buscamos estructura (grupos) en los datos. Por eso
**no** se hace partición entrenamiento/prueba: no hay un objetivo contra el
cual medir acierto.

## Variable objetivo

Ninguna — aprendizaje no supervisado. Salvo el identificador, todas las
columnas son atributos de comportamiento; ninguna es una respuesta a predecir.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango aprox. | Descripción |
|---|---|---|---|---|
| jugador_id | carácter | — (id) | JUG0001 … JUG0500 | **Identificador**; se marca con rol `id`, no es indicador. |
| sesiones_semana | numérica | sesiones/sem | 0 – 20 | Número de sesiones de juego por semana. |
| duracion_sesion_min | numérica | minutos | 5 – 160 | Duración promedio de una sesión. |
| velocidad_apuestas_min | numérica | apuestas/min | 1 – 20 | Ritmo de apuestas (impulsividad). |
| num_juegos_distintos | numérica | conteo | 1 – 9 | Variedad de juegos distintos usados. |
| apuesta_promedio_mxn | numérica | MXN | 15 – 2,500 | Monto promedio por apuesta. |
| num_depositos_mes | numérica | conteo | 0 – 15 | Número de depósitos al mes. |
| pct_juego_madrugada | numérica | % | 0 – 80 | % de juego entre 00:00 y 06:00 h. **Señal de riesgo.** |
| pct_incremento_tras_perdida | numérica | % | 0 – 80 | % en que sube la apuesta tras perder (*chasing*). **Señal de riesgo.** |
| retiros_mes | numérica | conteo | 0 – 5 | Retiros de saldo al mes (alto = juego saludable). |
| ratio_perdida_pct | numérica | % | 1 – 98 | % de lo depositado que se pierde. |
| dias_desde_registro | numérica | días | 30 – 1,400 | Antigüedad de la cuenta. *Ruido* poco informativo. |
| deposito_mensual_mxn | numérica | MXN | 0 – 18,000 | Depósito mensual total. **Colineal** (≈ apuesta × nº depósitos). **Tiene NAs (~3%).** |

## Número de observaciones

500 cuentas (filas) × 13 columnas (12 indicadores numéricos + 1 id).

## Notas

- **Valores faltantes (NAs):** `deposito_mensual_mxn` tiene 15 NAs (≈ 3%),
  simulando cuentas con registro incompleto. El PCA y los algoritmos de
  distancia **no toleran NAs**, así que se imputan con la **mediana** vía
  `step_impute_median()` (robusta porque los montos son asimétricos: pocos
  jugadores con depósitos enormes inflan la media).
- **Colinealidad:** `deposito_mensual_mxn` se construye a partir de
  `apuesta_promedio_mxn` y `num_depositos_mes`, así que está muy
  correlacionado con ambas. Esa redundancia refuerza el "eje de volumen
  monetario"; el PCA la absorbe al construir componentes ortogonales. La
  dejamos y la comentamos en el script.
- **Escalas heterogéneas:** hay porcentajes (0–100), conteos pequeños (0–20)
  y montos en pesos (de decenas a miles). Por eso es **indispensable
  normalizar (z-score) antes de PCA y clustering**: sin normalizar, los
  montos dominarían las distancias y los grupos reflejarían solo las unidades.
- **Estructura latente:** el dataset se construyó con **cuatro** perfiles
  subyacentes (recreativo ocasional, entusiasta controlado, en riesgo /
  problemático y gran apostador). El número de grupos y su interpretación los
  debe descubrir el alumno con el codo y la silueta; el caso es interesante
  porque la silueta sugiere k = 2 pero el codo y el sentido sustantivo apoyan
  k = 4.

## Enfoque técnico (tidymodels nativo)

- **Preprocesamiento:** `recipe()` + `update_role()` (id) +
  `step_impute_median()` + `step_normalize()`.
- **PCA:** `step_pca()` dentro de la receta; `tidy(type = "variance")` para
  el scree plot y `tidy(type = "coef")` para las cargas.
- **Clustering:** `tidyclust::k_means()` y `hier_clust()` dentro de un
  `workflow()`; selección de *k* con `tune_cluster()` +
  `cluster_metric_set(sse_within_total, silhouette_avg)`; etiquetas con
  `extract_cluster_assignment()` y centroides con `extract_centroids()`.
