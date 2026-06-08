# Ejercicios de regresión y clasificación (banco de estudio)

Colección de ejercicios resueltos de aprendizaje supervisado para el curso
**TC2001B.601 — Ciencia de datos para la toma de decisiones I**. Cada ejercicio
es un Quarto (`ejercicio.qmd`) autocontenido que reescribe un caso visto en
clase siguiendo el **flujo canónico de `tidymodels`** y comparando **dos
modelos** sobre un mismo dataset.

## Esquema común (los 10 pasos)

Todos los ejercicios siguen la misma estructura:

1. Cargar librerías
2. Cargar los datos
3. Explorar los datos (distribución de la objetivo, NAs, colinealidad)
4. Partición entrenamiento / prueba (`initial_split`, estratificada)
5. Receta de preprocesamiento (`recipe` + `step_*`), compartida por ambos modelos
6. Especificación de los modelos (`parsnip`) + `workflow()`
7. Validación cruzada (`vfold_cv`) y tuning de hiperparámetros (`tune_grid`;
   `fit_resamples` para el modelo base sin hiperparámetros)
8. Implementar el workflow final (`finalize_workflow`)
9. Entrenar y evaluar con `last_fit()` sobre la prueba
10. Pruebas del modelo: métricas, **tabla comparativa** y **visualizaciones**

Cada ejercicio incluye el flujo completo con `workflow()`, validación cruzada y
`last_fit()`, además de gráficas (corrplot, curva de tuning, ROC/PR,
matrices de confusión, real vs. predicho, importancia de variables) y una
sección de interpretación.

## Regresión

| # | Carpeta | Caso | Variable objetivo | Modelos |
|---|---------|------|-------------------|---------|
| 1 | `regresion/01_energia_hogares` | Consumo eléctrico residencial | `consumo_kwh` | Regresión lineal vs. árbol de regresión |
| 2 | `regresion/02_calidad_aire` | Contaminación por PM2.5 | `pm25_ug_m3` | Regresión lineal vs. random forest |
| 3 | `regresion/03_clinicas_respiratorias` | Demanda de consultas respiratorias | `consultas_respiratorias` | Regresión lineal vs. XGBoost |
| 4 | `regresion/04_precio_viviendas` | Precio de viviendas | `precio` | Regresión lineal vs. random forest |
| 5 | `regresion/05_costo_medico` | Costo médico anual (objetivo sesgada, log) | `costo_anual_mxn` | Regresión lineal vs. XGBoost |

## Clasificación

| # | Carpeta | Caso | Variable objetivo | Modelos |
|---|---------|------|-------------------|---------|
| 1 | `clasificacion/01_desercion_estudiantil` | Deserción estudiantil | `deserto` | Regresión logística vs. KNN |
| 2 | `clasificacion/02_cancelacion_hoteles` | Cancelación de reservas | `cancelo` | Regresión logística vs. árbol de decisión |
| 3 | `clasificacion/03_aprobacion_credito` | Aprobación de crédito | `aprobado` | Regresión logística vs. KNN |
| 4 | `clasificacion/04_potabilidad_agua` | Potabilidad del agua | `potable` | Regresión logística vs. KNN |
| 5 | `clasificacion/05_aprobacion_seguro` | Aprobación de seguro de vida | `aprobada` | Regresión logística vs. XGBoost |
| 6 | `clasificacion/06_clientes_casino` | Clientes prometedores (desbalanceado ~90/10) | `prometedor` | Regresión logística vs. random forest (SMOTE) |
| 7 | `clasificacion/07_fraude_tarjetas` | Fraude con tarjeta (desbalanceado ~96/4) | `fraude` | Regresión logística vs. XGBoost (SMOTE) |

## Cómo renderizar

Desde dentro de la carpeta de cada ejercicio:

```bash
quarto render ejercicio.qmd
```

El HTML resultante es autocontenido (`embed-resources: true`): el código se
ejecuta de verdad, así que las figuras y tablas son salidas vivas.

## Notas de diseño

- **Datasets**: todos sintéticos, recopilados de las Sesiones 13–19 del curso y
  reescritos como ejercicios de uno/dos modelos.
- **Métricas**: regresión usa RMSE, R² y MAE; clasificación balanceada usa
  roc_auc, accuracy, sensibilidad y especificidad; clasificación desbalanceada
  (casino, fraude) usa pr_auc, recall, precision, F1 y roc_auc.
- **Convención de niveles**: en clasificación se fija el nivel de interés
  (`"si"`) como primer nivel del factor, para que `yardstick` lo trate como el
  evento positivo.
