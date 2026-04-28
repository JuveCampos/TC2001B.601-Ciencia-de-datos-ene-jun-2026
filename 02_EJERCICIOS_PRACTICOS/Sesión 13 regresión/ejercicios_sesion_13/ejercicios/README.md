# Ejercicios de regresion inspirados en ISLR

Este proyecto contiene tres scripts para repasar fundamentos de regresion:

- `R/00_preparar_proyecto_y_datos.R`: crea `data/`, `outputs/` y los tres CSV sinteticos.
- `R/01_regresion_lineal_energia.R`: regresion lineal multiple con variables numericas, dummies, interaccion, diagnosticos basicos y comparacion de modelos.
- `R/02_ridge_calidad_aire.R`: ridge regression con predictores correlacionados, estandarizacion y seleccion de `lambda` por validacion cruzada.
- `R/03_lasso_demanda_clinicas.R`: lasso para seleccion automatica de variables cuando muchos predictores son ruido.

Los datos son sinteticos, reproducibles y narrativos. No dependen de `iris` ni de datasets clasicos de R.

## Paquetes usados

```r
install.packages(c("tidymodels", "glmnet"))
```

`tidymodels` ya incluye el estilo de trabajo usado en los scripts: `recipes`,
`rsample`, `parsnip`, `workflows`, `tune`, `yardstick` y `broom`.

## Sugerencia de uso

Abre `Regresion_ISLR_Ejercicios.Rproj` en RStudio. Primero corre `R/00_preparar_proyecto_y_datos.R`. Despues corre los ejercicios `01`, `02` y `03`. Los ejercicios no crean carpetas ni simulan datos: solo leen los CSV desde `data/` y guardan salidas en `outputs/`.
