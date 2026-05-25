# Metadatos — Aprobación de crédito (clasificación)

> **Dataset REUTILIZADO de la Sesión 16 (KNN y workflows).** Es el mismo
> conjunto de solicitudes de crédito que usamos para introducir workflows y
> tuning de KNN; aquí lo reaprovechamos para comparar **árboles, ensambles
> (random forest, XGBoost), regresión logística regularizada** y un
> **ensamble por stacking**.

## Nombre

`datos.csv` — Solicitudes de aprobación de crédito de consumo (México).

## Contexto / problema

Una institución financiera recibe solicitudes de crédito de consumo y debe
decidir, con base en el perfil del solicitante (edad, ingreso, historial
crediticio, monto pedido, etc.), si **aprobar** o **rechazar** la solicitud.
El objetivo es construir un modelo que ayude a anticipar la decisión de
aprobación, priorizando un buen poder discriminante (AUC) sobre el simple
porcentaje de aciertos, porque el negocio quiere ordenar correctamente a los
solicitantes según su probabilidad de aprobación.

## Tipo de problema

Clasificación binaria (aprendizaje supervisado).

## Variable objetivo

`aprobado` — factor con dos niveles: `"si"` (494 casos, 52%) y `"no"`
(456 casos, 48%). Las clases están prácticamente balanceadas.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango (aprox.) | Descripción |
|---|---|---|---|---|
| id_solicitud | character | — | CR0001–CR0950 | Identificador único de la solicitud. **No es predictor; se remueve.** |
| edad | numérica | años | 18 – 75 | Edad del solicitante. |
| ingreso_mensual_mxn | numérica | MXN/mes | 4,178 – 151,415 | Ingreso mensual declarado. **~5% NAs (47).** |
| monto_solicitado_mxn | numérica | MXN | 11,000 – 877,000 | Monto de crédito solicitado. |
| plazo_meses | numérica | meses | 6 – 60 | Plazo del crédito solicitado. |
| pago_mensual_estimado_mxn | numérica | MXN/mes | 217 – 98,333 | Pago mensual estimado. **Colineal con monto_solicitado_mxn.** |
| pct_deuda_ingreso | numérica | proporción | 0.03 – 1.32 | Razón deuda/ingreso del solicitante. |
| score_historial | numérica | puntos | 327 – 850 | Puntaje de historial crediticio. **~4% NAs (38).** |
| num_creditos_activos | numérica | conteo | 0 – 8 | Número de créditos vigentes. |
| antiguedad_empleo_anios | numérica | años | 0.2 – 28 | Antigüedad en el empleo actual. |
| aprobado | character → factor | — | si / no | **Variable objetivo:** decisión de aprobación. |

## Número de observaciones

950 filas × 11 columnas (9 candidatas a predictor, todas numéricas, tras
remover el identificador; `aprobado` es la objetivo).

## Notas

- **Valores faltantes (NAs):** `ingreso_mensual_mxn` ~5% (47 NAs) y
  `score_historial` ~4% (38 NAs). Se imputan con la mediana dentro de la
  receta (`step_impute_median`), antes de cualquier paso que no tolere NAs.
- **Colinealidad:** `pago_mensual_estimado_mxn` está fuertemente correlacionada
  con `monto_solicitado_mxn` (el pago se deriva del monto y el plazo). La
  receta incluye `step_corr()` para filtrar predictores numéricos muy
  correlacionados.
- **Transformaciones:** el identificador `id_solicitud` se remueve; todos los
  predictores son numéricos y se normalizan. Para árboles y ensambles la
  normalización no es estrictamente necesaria, pero se mantiene una receta
  común para que todos los modelos sean comparables y el stacking opere sobre
  la misma base.
- **Balance de clases:** ~56/44; el accuracy es informativo, pero usamos
  **roc_auc** como métrica principal de comparación y selección.
- **Origen:** dataset **reutilizado de la Sesión 16**; idéntico en estructura
  al usado allí para workflows y KNN.
