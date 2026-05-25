# Metadatos — Clientes prometedores en un casino en línea

## Nombre
`datos.csv` — Clientes prometedores en una plataforma de casino en línea.

## Contexto / problema
Una plataforma de apuestas y casino en línea que opera en México quiere
identificar, a partir del comportamiento de juego de sus clientes, a quiénes
vale la pena dirigir campañas de retención y atención personalizada (clientes
"prometedores", es decir, de alto valor potencial para el negocio). Solo una
pequeña fracción de la base de clientes resulta prometedora, por lo que el
problema está fuertemente desbalanceado.

El interés del área de negocio está en **detectar a los pocos clientes
prometedores** (la clase rara), no en clasificar bien a la mayoría que ya se
sabe que no lo es. Esto cambia qué métricas importan: nos interesa el *recall*
(¿cuántos prometedores reales detectamos?) y la *precision* (¿de los que
marcamos como prometedores, cuántos lo son de verdad?), no la *accuracy*.

## Tipo de problema
Clasificación binaria **desbalanceada**.

## Variable objetivo
- **Nombre:** `prometedor`
- **Tipo:** categórica binaria (se convierte a `factor`).
- **Niveles:** `"si"` (cliente prometedor, clase rara / evento de interés) y
  `"no"` (cliente no prometedor, clase mayoritaria).
- **Proporción:** `no` = 90.81 % (1907 obs.) | `si` = 9.19 % (193 obs.).
- **Nota sobre el orden de niveles:** en el script fijamos `"si"` como el
  **primer** nivel del factor con `factor(prometedor, levels = c("si","no"))`
  para que `yardstick` lo trate como el "evento" positivo. Así `recall`,
  `precision`, `f_meas` y `pr_auc` se calculan sobre la clase rara, que es la
  que nos interesa.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango | Descripción |
|---|---|---|---|---|
| `id_cliente` | character | — | CL00001–CL02100 | Identificador único del cliente. **No es predictor; se remueve.** |
| `edad` | numeric | años | 18–70 | Edad del cliente. |
| `dias_desde_registro` | numeric | días | 6–1251 | Días transcurridos desde que el cliente se registró. |
| `num_sesiones_mes` | numeric | conteo | 0–17 | Número de sesiones de juego en el último mes. |
| `num_juegos_distintos` | numeric | conteo | 1–11 | Número de juegos distintos en los que ha participado. |
| `monto_apostado_mensual_mxn` | numeric | MXN | 81–44 525 | Monto total apostado en el último mes. |
| `monto_deposito_promedio_mxn` | numeric | MXN | 22–20 499 | Depósito promedio del cliente. **Tiene NAs (~5 %).** |
| `usa_app_movil` | character | — | si / no | Si el cliente usa la app móvil de la plataforma. |
| `bono_reclamado` | character | — | si / no | Si el cliente ha reclamado algún bono promocional. |
| `tasa_retorno_pct` | numeric | % | 76.8–105.8 | Tasa de retorno (payout) histórica del cliente. |
| `prometedor` | factor | — | si / no | **Objetivo.** Cliente prometedor (clase rara "si"). |

## Número de observaciones
2100 filas × 11 columnas (10 predictores tras remover `id_cliente`).

## Notas
- **Valores faltantes (NAs):** `monto_deposito_promedio_mxn` tiene 105 NAs
  (~5 %). Se imputan con la mediana en la receta (`step_impute_median`), antes
  de cualquier otro paso, porque ni el balanceo ni `step_normalize` toleran
  NAs.
- **Desbalance:** ~90 / 10 (90.81 % `no`, 9.19 % `si`). Es el corazón del
  ejercicio. Un clasificador que prediga siempre `no` alcanza ~91 % de
  accuracy pero **recall 0 sobre la clase rara**: es inútil para el negocio.
- **Técnicas de balanceo comparadas** (paquete `themis`, solo se aplican al
  conjunto de entrenamiento):
  - **Sin balanceo** (línea base).
  - **`step_downsample`:** descarta observaciones de la mayoría hasta igualar
    la minoría. Pierde información pero entrena rápido.
  - **`step_upsample`:** replica observaciones de la minoría hasta igualar la
    mayoría. No inventa datos, los repite.
  - **`step_smote`:** crea ejemplos sintéticos de la minoría interpolando
    entre vecinos cercanos. Requiere **todos los predictores numéricos**, por
    lo que `step_dummy` debe ir **antes** de `step_smote`.
- **Métricas:** se usan `precision`, `recall`, `f_meas`, `roc_auc` y `pr_auc`
  (área bajo la curva precision-recall, muy informativa con desbalance fuerte).
  La accuracy solo se reporta para contraste, no como métrica de decisión.
- **Clasificador base:** regresión logística, fijo para todas las técnicas de
  balanceo, de modo que la comparación sea justa (solo cambia el balanceo).
