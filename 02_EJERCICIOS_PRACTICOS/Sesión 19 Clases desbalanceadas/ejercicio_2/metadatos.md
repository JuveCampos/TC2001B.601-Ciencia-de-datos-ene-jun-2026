# Metadatos — Detección de fraude en transacciones con tarjeta

## Nombre
`datos.csv` — Transacciones con tarjeta etiquetadas como fraude / no fraude.

## Contexto / problema
Un banco mexicano necesita un sistema que, al momento de autorizar una compra
con tarjeta, estime si la transacción es fraudulenta. El fraude es, por
fortuna, raro: solo ~4 % de las transacciones lo son. Esto convierte el
problema en un caso **extremo** de clases desbalanceadas (mucho más severo que
el ejercicio 1, que era ~90/10).

El costo de los errores es asimétrico: dejar pasar un fraude (falso negativo)
suele ser mucho más caro que revisar de más una transacción legítima (falso
positivo). Por eso el objetivo operativo es **maximizar la detección de fraude
(recall)** manteniendo la precision en un nivel que no sature al equipo
antifraude con falsas alarmas.

## Tipo de problema
Clasificación binaria **fuertemente desbalanceada**.

## Variable objetivo
- **Nombre:** `fraude`
- **Tipo:** categórica binaria (se convierte a `factor`).
- **Niveles:** `"si"` (transacción fraudulenta, clase rara / evento de interés)
  y `"no"` (transacción legítima, clase mayoritaria).
- **Proporción:** `no` = 96.08 % (2498 obs.) | `si` = 3.92 % (102 obs.).
- **Nota sobre el orden de niveles:** se fija `"si"` como **primer** nivel con
  `factor(fraude, levels = c("si","no"))`. yardstick toma el primer nivel como
  evento positivo, de modo que `recall`, `precision`, `f_meas` y `pr_auc` miden
  el desempeño sobre el fraude (la clase rara). Con solo 102 casos positivos,
  equivocar este orden haría que las métricas reportaran la clase legítima y se
  vería un desempeño "excelente" que en realidad ignora todo el fraude.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango | Descripción |
|---|---|---|---|---|
| `id_transaccion` | character | — | TX000001–TX002600 | Identificador único de la transacción. **No es predictor; se remueve.** |
| `monto_transaccion_mxn` | numeric | MXN | 34–13 571 | Monto de la transacción actual. |
| `monto_promedio_historico_mxn` | numeric | MXN | 49–5 752 | Monto promedio histórico de las compras del titular. |
| `hora_del_dia` | numeric | hora (0–23) | 0–23 | Hora del día en que ocurrió la transacción. |
| `dias_desde_ultima_compra` | numeric | días | 0–55 | Días transcurridos desde la compra anterior del titular. |
| `num_transacciones_24h` | numeric | conteo | 0–10 | Número de transacciones del titular en las últimas 24 horas. |
| `distancia_km_domicilio` | numeric | km | 0.1–272.9 | Distancia del comercio al domicilio registrado. **Tiene NAs (~4 %).** |
| `es_compra_internacional` | character | — | si / no | Si la compra se realizó en el extranjero. |
| `categoria_comercio` | character | — | 6 niveles | Categoría del comercio: abarrotes, electronica, viajes, entretenimiento, restaurantes, servicios. |
| `fraude` | factor | — | si / no | **Objetivo.** Transacción fraudulenta (clase rara "si"). |

## Número de observaciones
2600 filas × 10 columnas (8 predictores tras remover `id_transaccion`).

## Notas
- **Valores faltantes (NAs):** `distancia_km_domicilio` tiene 104 NAs (~4 %).
  Se imputan con la mediana en la receta (`step_impute_median`), antes del
  balanceo y la normalización, que no toleran NAs.
- **Colinealidad:** `monto_transaccion_mxn` y `monto_promedio_historico_mxn`
  están relacionadas (correlación ~0.77). Es una colinealidad moderada; no la
  filtramos con `step_corr` porque ambos montos aportan señal antifraude
  (la transacción actual vs. el comportamiento típico del titular), pero se
  documenta como nota para que el alumno la tenga presente.
- **Categórica con varios niveles:** `categoria_comercio` tiene 6 niveles. Al
  aplicar `step_dummy` genera 5 columnas dummy. Como `step_smote` exige todos
  los predictores numéricos, `step_dummy` debe ejecutarse **antes** del SMOTE.
- **Desbalance:** ~96 / 4 (96.08 % `no`, 3.92 % `si`). Es desbalance EXTREMO:
  un modelo que prediga siempre "no" alcanza ~96 % de accuracy y recall 0
  sobre el fraude. Inservible. Por eso la accuracy no se usa para decidir.
- **Técnicas de balanceo comparadas** (paquete `themis`, aplicadas solo al
  conjunto de entrenamiento dentro de cada fold de validación cruzada):
  **sin balanceo** (línea base), **`step_downsample`** (descarta mayoría),
  **`step_upsample`** (replica minoría) y **`step_smote`** (sintetiza minoría
  interpolando vecinos).
- **Métricas:** `recall`, `precision`, `f_meas`, `roc_auc` y `pr_auc`. La
  `pr_auc` es especialmente relevante con 4 % de positivos, porque la curva
  ROC tiende a verse optimista cuando la clase positiva es tan escasa.
- **Clasificador base:** regresión logística, fijo para todas las técnicas,
  para que la comparación aísle el efecto del balanceo.
