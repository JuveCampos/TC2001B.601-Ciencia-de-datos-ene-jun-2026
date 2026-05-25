# Metadatos — Potabilidad del agua

## Nombre del dataset
`datos.csv` — Análisis fisicoquímicos de muestras de agua (simuladas).

## Contexto / problema de negocio
Un organismo operador de agua toma muestras en distintos puntos de la red de
distribución y les realiza un análisis fisicoquímico en laboratorio. Con esos
parámetros (pH, dureza, sólidos disueltos, cloraminas, sulfatos, etc.) se
quiere predecir si una muestra cumple con las condiciones para ser apta para
consumo humano. Un modelo confiable ayudaría a priorizar qué muestras enviar a
verificación adicional y a vigilar la calidad del agua de manera más oportuna.

## Tipo de problema
Clasificación binaria supervisada (aprendizaje supervisado).

## Variable objetivo
- **Nombre:** `potable`
- **Tipo:** categórica (en el CSV viene como texto; se convierte a `factor`).
- **Niveles:** `"si"` (agua apta para consumo) y `"no"` (no apta).
- **Proporción de clases:** aproximadamente 42% `"si"` y 58% `"no"`
  (problema casi balanceado, con ligera mayoría de muestras no potables).

## Tabla de variables

| Nombre | Tipo | Unidad | Rango esperado | Descripción |
|---|---|---|---|---|
| `ph` | numérica | escala pH | 0–14 | Acidez/alcalinidad de la muestra. **Contiene NAs (~3%).** |
| `dureza_mg_l` | numérica | mg/L | >0 | Dureza del agua (concentración de calcio y magnesio). |
| `solidos_disueltos_ppm` | numérica | ppm | >0 | Total de sólidos disueltos. **Colineal** con `conductividad_us_cm`. |
| `cloraminas_ppm` | numérica | ppm | >0 | Concentración de cloraminas (desinfectante). |
| `sulfatos_mg_l` | numérica | mg/L | >0 | Concentración de sulfatos. **Contiene NAs (~6%).** |
| `conductividad_us_cm` | numérica | µS/cm | >0 | Conductividad eléctrica del agua. Altamente **colineal** con `solidos_disueltos_ppm` (ambas miden carga iónica disuelta). |
| `carbono_organico_ppm` | numérica | ppm | >0 | Carbono orgánico total. |
| `trihalometanos_ug_l` | numérica | µg/L | >0 | Concentración de trihalometanos (subproductos de la desinfección). |
| `turbidez_ntu` | numérica | NTU | >0 | Turbidez (claridad del agua). |
| `potable` | categórica | — | `"si"`, `"no"` | **Variable objetivo.** Aptitud para consumo humano. |

## Número de observaciones
820 filas × 10 columnas.

## Notas
- **Sin columna identificadora:** todas las columnas excepto `potable` son
  predictores numéricos; no hay un `id` que remover.
- **Valores faltantes (NAs):**
  - `ph`: 24 NAs (~3%).
  - `sulfatos_mg_l`: 49 NAs (~6%).
  - El resto de las columnas no tiene faltantes. La receta imputa la mediana
    en los predictores numéricos antes de cualquier otro paso.
- **Colinealidad intencional:** `conductividad_us_cm` y
  `solidos_disueltos_ppm` están altamente correlacionadas, porque ambas
  reflejan la cantidad de material iónico disuelto en el agua. La receta
  incluye `step_corr()` para descartar una de las dos y evitar que esa
  información pese doble en la distancia de KNN.
- **Por qué este dataset es ideal para normalizar:** todas las variables son
  numéricas pero en escalas muy distintas (pH va de 0 a 14, mientras que los
  sólidos disueltos llegan a decenas de miles de ppm). Sin
  `step_normalize()`, las variables de mayor magnitud dominarían por completo
  el cálculo de distancias y KNN ignoraría de hecho al pH y a la turbidez.
