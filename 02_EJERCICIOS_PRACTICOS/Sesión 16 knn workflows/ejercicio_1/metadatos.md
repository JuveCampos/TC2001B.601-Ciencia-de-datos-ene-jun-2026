# Metadatos — Aprobación de crédito

## Nombre del dataset
`datos.csv` — Solicitudes de crédito de consumo (simuladas).

## Contexto / problema de negocio
Una institución financiera recibe solicitudes de crédito de consumo y debe
decidir, con base en el perfil financiero y sociodemográfico del solicitante,
si aprueba o rechaza la solicitud. El objetivo es construir un modelo que
prediga la decisión de aprobación a partir de las características de cada
solicitud, de modo que el área de originación pueda priorizar revisiones,
detectar perfiles de riesgo y estandarizar el criterio de decisión.

## Tipo de problema
Clasificación binaria supervisada (aprendizaje supervisado).

## Variable objetivo
- **Nombre:** `aprobado`
- **Tipo:** categórica (en el CSV viene como texto; se convierte a `factor`).
- **Niveles:** `"si"` (solicitud aprobada) y `"no"` (solicitud rechazada).
- **Proporción de clases:** aproximadamente 56% `"si"` y 44% `"no"`
  (problema casi balanceado).

## Tabla de variables

| Nombre | Tipo | Unidad | Rango esperado | Descripción |
|---|---|---|---|---|
| `id_solicitud` | texto | — | CR0001–CR0950 | Identificador único de la solicitud. **NO es predictor**; se remueve antes de modelar. |
| `edad` | numérica | años | 18–75 | Edad del solicitante. |
| `ingreso_mensual_mxn` | numérica | MXN/mes | ~8,000–250,000 | Ingreso mensual declarado. **Contiene NAs (~5%).** |
| `monto_solicitado_mxn` | numérica | MXN | variable | Monto total que se solicita en crédito. |
| `plazo_meses` | numérica | meses | {6, 12, 24, 36, 48, 60} | Plazo del crédito en meses. |
| `pago_mensual_estimado_mxn` | numérica | MXN/mes | variable | Pago mensual estimado. Se deriva de `monto_solicitado_mxn / plazo_meses`; por eso está **colineal** con `monto_solicitado_mxn`. |
| `pct_deuda_ingreso` | numérica | proporción | 0–1.5 | Razón pago mensual / ingreso (carga de deuda). Derivada de pago e ingreso. |
| `score_historial` | numérica | puntos | 300–850 | Score crediticio del solicitante. **Contiene NAs (~4%).** |
| `num_creditos_activos` | numérica | conteo | 0+ | Número de créditos vigentes que ya tiene el solicitante. |
| `antiguedad_empleo_anios` | numérica | años | 0+ | Antigüedad en el empleo actual. |
| `aprobado` | categórica | — | `"si"`, `"no"` | **Variable objetivo.** Decisión de aprobación del crédito. |

Todos los predictores son **numéricos**, lo que hace de este un caso ideal
para KNN (modelo basado en distancias).

## Número de observaciones
950 filas × 11 columnas.

## Notas
- **Valores faltantes (NAs):**
  - `ingreso_mensual_mxn`: 47 NAs (~5%).
  - `score_historial`: 38 NAs (~4%).
  - El resto de las columnas no tiene faltantes. Por eso la receta imputa la
    mediana en los predictores numéricos antes de cualquier otro paso.
- **Colinealidad intencional:** `pago_mensual_estimado_mxn` se deriva de
  `monto_solicitado_mxn / plazo_meses`, por lo que está altamente
  correlacionado con `monto_solicitado_mxn`; además `pct_deuda_ingreso`
  proviene de pago e ingreso. La receta incluye `step_corr()` para filtrar
  predictores numéricos redundantes y evitar que pesen doble en la distancia
  de KNN.
- **Transformaciones requeridas para KNN:** como KNN clasifica por distancia,
  las variables deben normalizarse (`step_normalize`) para que ninguna domine
  por su escala (p. ej. los montos en miles de pesos contra el conteo de
  créditos). Al ser todos los predictores numéricos, no hace falta codificar
  variables categóricas.
- El identificador `id_solicitud` se elimina con `select(-id_solicitud)`; no
  contiene información predictiva y, si se dejara, agregaría ruido a la
  distancia.
