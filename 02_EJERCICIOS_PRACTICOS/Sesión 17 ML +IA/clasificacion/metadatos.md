# Metadatos — Aprobación de póliza de seguro de vida

## Nombre
`datos.csv` — Solicitudes de póliza de seguro de vida.

## Contexto / problema
Una aseguradora recibe solicitudes de pólizas de seguro de vida. Antes de
emitir la póliza, el área de suscripción (underwriting) evalúa el riesgo del
solicitante a partir de información demográfica, clínica y de su historial
como cliente, y decide si la solicitud se **aprueba** o **no se aprueba**.

El objetivo es construir un modelo que, dada la información de un solicitante,
prediga si su póliza será aprobada. Un modelo así apoya al equipo de
suscripción a priorizar casos, detectar solicitudes de alto riesgo y hacer
el proceso más consistente.

## Tipo de problema
Clasificación binaria (aprendizaje supervisado).

## Variable objetivo
- **Nombre:** `aprobada`
- **Tipo:** categórica → se convierte a `factor`.
- **Niveles:** `"si"` (póliza aprobada) y `"no"` (no aprobada).
- **Balance de clases:** aproximadamente 46% `"si"` y 54% `"no"`. Las clases
  están razonablemente balanceadas, pero conviene estratificar el split y
  vigilar sensibilidad y especificidad, no solo accuracy.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango | Descripción |
|---|---|---|---|---|
| `id_solicitante` | character | — | — | Identificador único del solicitante. **No es predictor; se remueve.** |
| `edad` | numeric | años | 18 – 70 | Edad del solicitante. |
| `sexo` | character | — | "F" / "M" | Sexo del solicitante. |
| `imc` | numeric | kg/m² | ~10 – 42 | Índice de masa corporal. |
| `fumador` | character | — | "si" / "no" | Si el solicitante es fumador. |
| `num_padecimientos_previos` | numeric | conteo | 0 – 5 | Número de padecimientos previos declarados. |
| `presion_sistolica` | numeric | mmHg | ~69 – 164 | Presión arterial sistólica. Correlación moderada con la edad. |
| `colesterol_mg_dl` | numeric | mg/dL | ~90 – 302 | Colesterol total. **Tiene NAs (~5%).** Correlación moderada con edad y con ser fumador. |
| `antecedente_familiar` | character | — | "si" / "no" | Antecedente familiar de enfermedad relevante. |
| `meses_como_cliente` | numeric | meses | 1 – 159 | Antigüedad del solicitante como cliente. |
| `region` | character | — | "norte" / "centro" / "sur" / "bajio" | Región del país del solicitante. |
| `aprobada` | factor | — | "si" / "no" | **Variable objetivo.** Si la póliza fue aprobada. |

## Número de observaciones
880 observaciones (filas) × 12 variables (columnas), incluyendo el
identificador y la variable objetivo.

## Notas
- **Valores faltantes (NAs):** `colesterol_mg_dl` tiene 44 NAs (~5% de las
  filas). Es la única variable con datos faltantes. Se recomienda imputar
  (por ejemplo, mediana) dentro de la receta, antes de los pasos que no
  toleran NAs.
- **Colinealidad:** existe colinealidad moderada entre `presion_sistolica`,
  `colesterol_mg_dl` y `edad` (variables clínicas que tienden a moverse
  juntas con la edad). Conviene revisar la matriz de correlación y considerar
  `step_corr()` para filtrar predictores demasiado correlacionados.
- **Escala de variables:** las variables numéricas tienen escalas muy
  distintas (edad en decenas, colesterol en cientos). Si se usa un modelo
  basado en distancias (KNN), es indispensable normalizar (`step_normalize`)
  antes de ajustar.
- **Identificador:** `id_solicitante` no aporta poder predictivo y debe
  removerse para evitar fuga de información (data leakage).
