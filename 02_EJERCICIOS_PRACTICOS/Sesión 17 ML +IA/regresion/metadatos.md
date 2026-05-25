# Metadatos — Costo médico anual

## Nombre
`datos.csv` — Costo médico anual por paciente.

## Contexto / problema
Una institución de salud (o una aseguradora médica) quiere anticipar el
**costo médico anual** de cada paciente a partir de características
demográficas, de estilo de vida y de uso de servicios de salud. Estimar ese
costo apoya la planeación presupuestal, el diseño de primas y la
identificación de pacientes de alto costo para programas preventivos.

El objetivo es construir un modelo que prediga el costo anual (en pesos
mexicanos) de un paciente dado su perfil.

## Tipo de problema
Regresión (aprendizaje supervisado, variable objetivo numérica continua).

## Variable objetivo
- **Nombre:** `costo_anual_mxn`
- **Tipo:** numérica continua.
- **Unidad:** pesos mexicanos (MXN).
- **Rango:** aproximadamente $6,000 a $320,000.
- **Distribución:** **sesgada a la derecha** (tipo log-normal). La media
  ($50,086) es bastante mayor que la mediana ($37,860), lo que confirma la
  cola larga hacia valores altos. Por eso se recomienda **modelar
  `log(costo_anual_mxn)`** (ver Notas).

## Tabla de variables

| Nombre | Tipo | Unidad | Rango | Descripción |
|---|---|---|---|---|
| `id_paciente` | character | — | — | Identificador único del paciente. **No es predictor; se remueve.** |
| `edad` | numeric | años | 18 – 70 | Edad del paciente. |
| `sexo` | character | — | "F" / "M" | Sexo del paciente. |
| `imc` | numeric | kg/m² | ~13 – 46 | Índice de masa corporal. **Tiene NAs (~4%).** |
| `hijos` | numeric | conteo | 0 – 7 | Número de hijos / dependientes. |
| `fumador` | character | — | "si" / "no" | Si el paciente es fumador. **Principal driver del costo.** |
| `region` | character | — | "norte" / "centro" / "sur" / "bajio" | Región del país del paciente. |
| `actividad_fisica_hrs_sem` | numeric | horas/semana | 0 – 10 | Horas de actividad física por semana. |
| `num_consultas_anio` | numeric | conteo | 0 – 9 | Número de consultas médicas en el año. |
| `costo_anual_mxn` | numeric | MXN | ~6,000 – 320,000 | **Variable objetivo.** Costo médico anual. Sesgada a la derecha. |

## Número de observaciones
1,050 observaciones (filas) × 10 variables (columnas), incluyendo el
identificador y la variable objetivo.

## Notas
- **Valores faltantes (NAs):** `imc` tiene 42 NAs (~4% de las filas). Es la
  única variable con datos faltantes. Se recomienda imputar (por ejemplo,
  mediana) dentro de la receta.
- **Transformación logarítmica de la objetivo:** `costo_anual_mxn` está
  sesgada a la derecha (cola larga; media > mediana). Modelar directamente el
  costo en pesos suele dar peores resultados porque:
  1. **Estabiliza la varianza** (heterocedasticidad: la dispersión del costo
     crece con su nivel; el log la comprime).
  2. **Linealiza relaciones** entre predictores y objetivo, lo que ayuda a
     modelos lineales y a los basados en distancia.
  3. **Mejora el ajuste** al reducir el peso desproporcionado de los valores
     extremos.
  La transformación se aplica con `step_log(costo_anual_mxn, base = exp(1))`
  en la receta (o transformando antes de modelar). **Importante:** las
  métricas (RMSE, MAE) quedan en escala logarítmica; para reportar errores
  en pesos hay que **exponenciar de vuelta** (`exp()`) las predicciones y la
  variable real antes de calcular el error en MXN.
- **Driver principal:** `fumador` es el predictor más fuerte del costo; se
  espera que separe claramente los costos altos de los bajos.
- **Escala de variables:** las numéricas tienen escalas muy distintas. Si se
  usa KNN (basado en distancias), normalizar (`step_normalize`) es
  indispensable.
- **Identificador:** `id_paciente` no aporta poder predictivo y debe
  removerse para evitar fuga de información (data leakage).
