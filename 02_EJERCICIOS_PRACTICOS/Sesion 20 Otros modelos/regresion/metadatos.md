# Metadatos — Costo médico anual (regresión)

> **Dataset REUTILIZADO de la Sesión 17 (regresión).** Es el mismo conjunto de
> pacientes y costos médicos anuales que usamos para practicar regresión;
> aquí lo reaprovechamos para comparar **regresión lineal regularizada
> (lasso/ridge/elasticnet), random forest y XGBoost**, más un **ensamble por
> stacking**.

## Nombre

`datos.csv` — Costo médico anual por paciente (México).

## Contexto / problema

Una aseguradora de gastos médicos quiere estimar el **costo médico anual**
esperado de un paciente a partir de su perfil (edad, índice de masa corporal,
si fuma, número de hijos, región, etc.). Una buena estimación permite fijar
primas más justas y anticipar el gasto agregado. El reto estadístico es que
el costo está **muy sesgado a la derecha** (pocos pacientes muy caros), por
lo que modelamos `log(costo_anual_mxn)`.

## Tipo de problema

Regresión (aprendizaje supervisado), con variable objetivo continua y
sesgada.

## Variable objetivo

`costo_anual_mxn` — costo médico anual en pesos. **Distribución sesgada a la
derecha** (media 50,086 > mediana 37,860; máximo 317,728). Se modela en
escala logarítmica (`log(costo_anual_mxn)`) y las métricas finales se
interpretan en esa escala log.

## Tabla de variables

| Nombre | Tipo | Unidad | Rango (aprox.) | Descripción |
|---|---|---|---|---|
| id_paciente | character | — | PA00001–PA01050 | Identificador único del paciente. **No es predictor; se remueve.** |
| edad | numérica | años | 18 – 70 | Edad del paciente. |
| sexo | character | — | F / M | Sexo del paciente. |
| imc | numérica | kg/m² | 13.2 – 46.4 | Índice de masa corporal. **~4% NAs (42).** |
| hijos | numérica | conteo | 0 – 7 | Número de hijos / dependientes. |
| fumador | character | — | si / no | Si el paciente fuma (≈21% fumadores). |
| region | character | — | norte / centro / sur / bajio | Región de residencia. |
| actividad_fisica_hrs_sem | numérica | horas/semana | 0 – 10 | Horas de actividad física semanal. |
| num_consultas_anio | numérica | conteo | 0 – 9 | Consultas médicas en el año. |
| costo_anual_mxn | numérica | MXN/año | 6,676 – 317,728 | **Variable objetivo:** costo médico anual. Sesgada → se modela en log. |

## Número de observaciones

1,050 filas × 10 columnas (8 candidatas a predictor tras remover el
identificador; `costo_anual_mxn` es la objetivo).

## Notas

- **Valores faltantes (NAs):** `imc` ~4% (42 NAs). Se imputa con la mediana
  dentro de la receta (`step_impute_median`).
- **Transformación de la objetivo:** `costo_anual_mxn` está fuertemente
  sesgada a la derecha. Modelar el costo en su escala original castiga la
  regresión lineal regularizada (residuos no normales, varianza creciente).
  Por eso transformamos la objetivo a `log(costo_anual_mxn)` con
  `step_log(all_outcomes())`. Las métricas **rmse** y **rsq** se calculan en
  escala log; al comparar modelos lo importante es que todos compartan la
  misma escala.
- **Codificación:** las categóricas (`sexo`, `fumador`, `region`) se
  convierten a variables indicadoras con `step_dummy`. Los numéricos se
  normalizan (`step_normalize`), necesario para glmnet (la penalización L1/L2
  depende de la escala de los predictores).
- **Predictor relevante esperado:** `fumador` suele ser el predictor más
  fuerte del costo; útil para sanity-check de la importancia de variables.
- **Origen:** dataset **reutilizado de la Sesión 17**; idéntico en estructura
  al usado allí para regresión.
