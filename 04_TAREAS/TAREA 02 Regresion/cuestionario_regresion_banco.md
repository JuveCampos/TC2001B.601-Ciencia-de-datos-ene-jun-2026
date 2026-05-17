---
title: "Cuestionario — Regresión lineal, regularización y tidymodels"
subtitle: "Banco amplio de preguntas (selección abierta)"
author: "Jorge Juvenal Campos Ferreira"
course: "TC2001B.601 — Ciencia de datos para la toma de decisiones I"
session: "Sesiones 13 y 14"
date: "2026-05-16"
---

# Cuestionario — Regresión lineal, regularización y tidymodels

> **Nota para el profesor.** Banco de preguntas para seleccionar las que se enviarán a los alumnos. Cubre los contenidos de las Sesiones 13 (*Fundamentos de Regresión*) y 14 (*Repaso de regresión + Recetas/tidymodels*). Las preguntas están agrupadas por tema y tipo. Se sugiere seleccionar entre 20 y 30 para una tarea estándar, o entre 40 y 50 para un trabajo extenso.

---

## SECCIÓN A. Conceptos fundamentales de regresión

**A.1.** Defina con sus propias palabras qué es la regresión y precise cuál es su objetivo principal en ciencia de datos.

**A.2.** En la formulación general $Y = f(X) + \varepsilon$, explique qué representan cada uno de los tres componentes ($Y$, $f(X)$ y $\varepsilon$) y dé un ejemplo concreto en el contexto de políticas públicas.

**A.3.** ¿Cuál es la diferencia entre la **variable respuesta** y las **variables predictoras**? Dé tres nombres alternativos para cada una.

**A.4.** Explique por qué decimos que el error $\varepsilon$ "no se puede eliminar, pero sí cuantificar". ¿De dónde proviene ese error en problemas reales?

**A.5.** Mencione cinco aplicaciones distintas de la regresión en problemas reales. Para cada una identifique cuál sería $Y$ y cuáles podrían ser las $X$.

**A.6.** ¿Por qué la regresión lineal sigue siendo una de las herramientas más utilizadas en ciencia de datos a pesar de que existen modelos más sofisticados? Mencione al menos dos ventajas.

**A.7.** ¿Qué diferencia hay entre la frase "la regresión predice" y "la regresión explica"? ¿Puede un modelo cumplir las dos funciones a la vez?

**A.8.** ¿Por qué la regresión lineal es especialmente útil para tomadores de decisiones en gobierno? Argumente con un ejemplo mexicano (CONEVAL, IMSS, INEGI, etc.).

---

## SECCIÓN B. Regresión lineal simple — interpretación, cálculo y fórmula

**B.1.** Escriba la fórmula general de la regresión lineal simple e identifique cada uno de sus parámetros.

**B.2.** Suponga el modelo $\hat{Y} = 2.15 + 1.47 X$, donde $Y$ son calificaciones (0-10) y $X$ son horas de estudio. Interprete económicamente $\beta_0$ y $\beta_1$.

**B.3.** ¿En qué sentido la regresión lineal es "lineal"? ¿Es lineal en $X$, en los parámetros $\beta$, o en ambos? Justifique con un ejemplo (por ejemplo, ¿es lineal $Y = \beta_0 + \beta_1 X^2$?).

**B.4.** Explique en lenguaje no técnico qué significa "el método de mínimos cuadrados ordinarios" (OLS) y por qué se eleva al cuadrado el error en lugar de tomar el valor absoluto.

**B.5.** Escriba la fórmula de la **Suma de Residuos al Cuadrado (RSS)** y explique cada término.

**B.6.** Dadas las fórmulas:
$$\hat{\beta}_1 = \frac{\sum_{i=1}^n (x_i - \bar{x})(y_i - \bar{y})}{\sum_{i=1}^n (x_i - \bar{x})^2} = \frac{\widehat{Cov}(x,y)}{\widehat{Var}(x)} \quad \text{y} \quad \hat{\beta}_0 = \bar{y} - \hat{\beta}_1 \bar{x}$$

   a) Interprete por qué $\hat{\beta}_1$ es esencialmente "una covarianza dividida entre una varianza".
   b) ¿Qué pasaría con $\hat{\beta}_1$ si $X$ tuviera varianza cero? ¿Por qué tiene sentido económicamente?

**B.7.** Para los siguientes datos:

| X | Y |
|---|---|
| 1 | 3 |
| 2 | 5 |
| 3 | 7 |
| 4 | 9 |

   Calcule a mano $\hat{\beta}_0$ y $\hat{\beta}_1$ utilizando las fórmulas anteriores. ¿Qué significa el resultado?

**B.8.** Si la pendiente $\beta_1$ de un modelo es negativa, ¿qué implica sobre la relación entre $X$ y $Y$? Dé un ejemplo donde esto sea esperable.

**B.9.** ¿Por qué la línea de regresión "siempre pasa por el punto $(\bar{x}, \bar{y})$"? Demuéstrelo a partir de la fórmula de $\hat{\beta}_0$.

**B.10.** Suponga que se ajusta $\text{Salario} = 5000 + 2300 \cdot \text{años\_escolaridad}$. ¿Tiene sentido interpretar literalmente que alguien con 0 años de escolaridad ganaría \$5,000? Discuta los riesgos de **extrapolar fuera del rango de los datos**.

---

## SECCIÓN C. Evaluación del modelo — R², RMSE, MAE, RSE

**C.1.** Defina el **coeficiente de determinación $R^2$**. ¿Cuál es su rango? ¿Qué significa un $R^2 = 0.85$?

**C.2.** ¿Por qué $R^2$ por sí solo no garantiza que el modelo sea bueno? Mencione al menos dos limitaciones.

**C.3.** Defina **RSE (error estándar residual)** y **RMSE (raíz del error cuadrático medio)**. ¿Cuál es la principal ventaja de usar RMSE frente a $R^2$ para reportar resultados a un público no técnico?

**C.4.** ¿En qué unidades está expresado el RMSE? ¿Por qué eso lo hace más interpretable que el $R^2$?

**C.5.** Defina **MAE (Mean Absolute Error)** y compare en qué situaciones es preferible frente a RMSE.

**C.6.** Suponga que dos modelos tienen los siguientes resultados sobre el mismo conjunto de prueba:

| Modelo | $R^2$ | RMSE |
|---|---|---|
| Modelo A | 0.85 | \$50,000 |
| Modelo B | 0.78 | \$42,000 |

   ¿Cuál preferiría y por qué? ¿Es posible que estas dos métricas se contradigan?

**C.7.** En el ejercicio de la clase, el primer intento tuvo $R^2 = 0.639$ y RMSE = \$47,777, y el segundo intento $R^2 = 0.722$ y RMSE = \$41,938. Argumente por qué el segundo modelo es mejor y qué cambió entre ambos.

**C.8.** ¿Por qué se evalúa el modelo sobre la **base de prueba** y no sobre la base de entrenamiento? Explique con sus propias palabras qué problema se evita.

**C.9.** Si un modelo tiene $R^2 = 0.99$ en entrenamiento pero $R^2 = 0.40$ en prueba, ¿qué problema está ocurriendo? ¿Qué haría para diagnosticarlo y corregirlo?

**C.10.** Cuando vemos la gráfica de "valores reales vs valores predichos", ¿qué patrón visual indica que el modelo predice bien? ¿Qué patrones indican problemas?

---

## SECCIÓN D. Regresión lineal múltiple y variables categóricas

**D.1.** Escriba la fórmula general de la **regresión lineal múltiple** con $p$ predictores. ¿Cómo se interpreta cada coeficiente $\beta_j$?

**D.2.** ¿Por qué en regresión múltiple decimos que "ya no es una línea, es un plano (o hiperplano)"? ¿En qué dimensión vive el plano si tenemos 5 predictores?

**D.3.** Explique la frase: "cada $\beta_j$ mide el efecto de $X_j$ sobre $Y$, manteniendo el resto de las variables constantes". ¿Qué dificultad práctica supone esto en datos observacionales?

**D.4.** ¿Qué es una **variable dummy** y por qué se necesita para incluir variables categóricas en un modelo de regresión?

**D.5.** Para una variable con $K = 4$ niveles (por ejemplo, región: Norte, Centro, Sur, Sureste), ¿cuántas variables dummy se deben crear? ¿Qué representa el nivel que no recibe dummy?

**D.6.** ¿Cambia el $R^2$ del modelo dependiendo de cuál sea la categoría base elegida? ¿Cambia la interpretación de los coeficientes? Justifique.

**D.7.** Convierta la siguiente tabla a su representación con variables dummy, dejando "Centro" como categoría base:

| ID | Región |
|---|---|
| 1 | Norte |
| 2 | Centro |
| 3 | Sur |
| 4 | Sureste |
| 5 | Norte |

**D.8.** Considere un modelo: $\text{Ingreso} = 8{,}000 + 3{,}200 \cdot \text{escolaridad} + 1{,}500 \cdot \text{dummy\_hombre}$. Interprete el coeficiente de la dummy `dummy_hombre` y discuta si esto necesariamente implica discriminación salarial por género.

**D.9.** ¿En qué momento del flujo de tidymodels se crean las variables dummy? ¿Qué función específica se usa y por qué es importante hacerlo dentro de la receta y no antes?

**D.10.** Si una variable categórica tiene muchos niveles raros (por ejemplo, 32 estados pero solo 3 aparecen mucho), ¿qué problemas puede causar al crear dummies y qué soluciones propondría?

---

## SECCIÓN E. Cuando la relación no es recta y balance sesgo-varianza

**E.1.** Defina **regresión polinómica**. Escriba un ejemplo de un modelo polinómico de grado 3 y explique por qué sigue siendo "lineal en los parámetros".

**E.2.** ¿Cuándo conviene usar una regresión polinómica en lugar de una lineal simple? Dé un ejemplo del mundo real donde la relación entre $X$ y $Y$ no sería razonable suponerla lineal.

**E.3.** ¿Por qué se recomienda no usar grados muy altos (mayores a 3 o 4) en una regresión polinómica? ¿Qué pasa en los extremos del rango de $X$?

**E.4.** Defina los tres conceptos: **subajuste, buen ajuste y sobreajuste**. ¿Qué tipo de sesgo y qué tipo de varianza tiene cada uno?

**E.5.** Si un modelo de regresión tiene **alto sesgo y baja varianza**, ¿qué problema tiene y cómo lo solucionaría?

**E.6.** Si un modelo tiene **bajo sesgo y alta varianza**, ¿qué problema tiene y cómo lo solucionaría?

**E.7.** Explique con sus propias palabras la frase: "el mejor modelo es el que minimiza el error en datos **nuevos**, no en los de entrenamiento".

**E.8.** ¿Por qué un modelo que ajusta perfectamente los datos de entrenamiento ($R^2 = 1$) puede ser peor que uno con $R^2 = 0.85$?

**E.9.** Suponga que está prediciendo el rendimiento académico de estudiantes con un polinomio de grado 9 sobre 50 observaciones. ¿Qué problema podría tener este modelo? ¿Qué métricas le permitirían detectarlo?

---

## SECCIÓN F. Colinealidad y heterocedasticidad

**F.1.** Defina **colinealidad** entre predictores. ¿Por qué es un problema en regresión lineal múltiple?

**F.2.** Mencione dos métodos para **detectar colinealidad** y explique cómo se interpreta cada uno.

**F.3.** ¿Qué es el **VIF (Variance Inflation Factor)**? ¿A partir de qué valor se considera problemático?

**F.4.** Mencione tres estrategias para **resolver la colinealidad** y discuta los pros y contras de cada una.

**F.5.** Si dos variables (por ejemplo `años_escolaridad` y `nivel_educativo`) están altamente correlacionadas, ¿qué problema concreto ocurre con los coeficientes $\hat{\beta}$? ¿Por qué los signos pueden "voltearse"?

**F.6.** Defina **heterocedasticidad**. ¿Cuál es la diferencia visual entre un gráfico con heterocedasticidad y uno con homocedasticidad?

**F.7.** ¿Por qué la heterocedasticidad es un problema? ¿Qué supuesto de la regresión lineal viola?

**F.8.** Explique por qué transformar $Y$ con $\log(Y)$ a veces resuelve la heterocedasticidad. Dé un ejemplo donde sería razonable hacerlo (ingresos, precios, etc.).

**F.9.** Considere la siguiente matriz de correlación de cuatro predictores:

| | $X_1$ | $X_2$ | $X_3$ | $X_4$ |
|---|---|---|---|---|
| $X_1$ | 1.00 | 0.92 | 0.15 | 0.20 |
| $X_2$ | 0.92 | 1.00 | 0.18 | 0.22 |
| $X_3$ | 0.15 | 0.18 | 1.00 | 0.10 |
| $X_4$ | 0.20 | 0.22 | 0.10 | 1.00 |

   ¿Qué problema detectaría y qué decisión tomaría?

---

## SECCIÓN G. Regularización — Ridge, Lasso y Elastic Net

**G.1.** ¿Qué es la **regularización** y por qué se introduce en un modelo de regresión? ¿Qué problema busca resolver?

**G.2.** Escriba la función de pérdida de **Ridge (L2)** y la de **Lasso (L1)**. ¿En qué se diferencian matemáticamente?

**G.3.** ¿Qué hace el hiperparámetro $\lambda$ (penalización)? ¿Qué ocurre con los coeficientes cuando $\lambda \to 0$ y cuando $\lambda \to \infty$?

**G.4.** Una diferencia fundamental entre Ridge y Lasso es que Lasso "hace coeficientes exactamente cero". Explique por qué esto convierte a Lasso en un método de **selección de variables**.

**G.5.** ¿Cuándo conviene usar **Ridge** y cuándo conviene usar **Lasso**? Mencione al menos tres criterios.

**G.6.** ¿Qué es **Elastic Net** y qué valor del parámetro `mixture` lo identifica en tidymodels?

**G.7.** En tidymodels, ¿qué valores debe tomar `mixture` para producir cada uno: regresión lineal clásica, Ridge, Lasso y Elastic Net? ¿Qué motor (engine) se utiliza para Ridge y Lasso?

**G.8.** Complete la tabla:

| Situación | Método recomendado |
|---|---|
| Pocos predictores, relación lineal | ____________________ |
| Muchos predictores, todos aportan algo | ____________________ |
| Muchos predictores, solo unos pocos relevantes | ____________________ |

**G.9.** ¿Por qué es **necesario normalizar (estandarizar)** las variables antes de aplicar Ridge o Lasso? ¿Qué pasaría si no se hiciera?

**G.10.** Cuando se hace tuning de $\lambda$ en Ridge/Lasso con `tune_grid()` y validación cruzada, ¿qué decide la función `select_best()`? ¿Bajo qué métrica recomendaría seleccionar el mejor $\lambda$?

---

## SECCIÓN H. Flujo de trabajo tidymodels

**H.1.** Enumere los **cinco pasos del flujo de trabajo estándar de tidymodels**. ¿Qué paquete corresponde a cada paso?

**H.2.** ¿Para qué sirve `tidymodels_prefer()`? ¿Qué problema resuelve?

**H.3.** Explique la diferencia entre `initial_split()` e `initial_time_split()`. ¿Cuándo es estrictamente necesario usar `initial_time_split()`?

**H.4.** ¿Qué hace el argumento `strata` dentro de `initial_split()`? Dé un ejemplo donde sería importante utilizarlo.

**H.5.** ¿Por qué se separa la base en **entrenamiento** y **prueba**? ¿Qué proporción se usó en el ejercicio de la clase (70/30 o 75/25)?

**H.6.** ¿Por qué en estadística descriptiva sobre la base de entrenamiento y la base de prueba los valores deben verse "parecidos"? Si fueran muy diferentes, ¿qué problema indicaría?

**H.7.** Explique los tres elementos que definen un modelo en parsnip (`linear_reg()`, `set_engine()`, `set_mode()`).

**H.8.** ¿Qué hace `workflow()`? ¿Por qué empacar receta + modelo en un mismo objeto es preferible a aplicar cada paso por separado?

**H.9.** ¿Cuál es la diferencia entre `fit()` y `predict()` en tidymodels? ¿Por qué el flujo termina con esas dos funciones?

**H.10.** ¿Qué información extrae `extract_fit_engine()`? ¿Y la función `tidy()`? ¿Para qué sirve cada una?

**H.11.** Considere el siguiente código incompleto. Complételo:

```r
library(tidyverse)
library(tidymodels)

set.seed(2026)

# 1. Dividir
split <- ______(datos, prop = 0.75, strata = y)
train <- ______(split)
test  <- ______(split)

# 2. Modelo
modelo <- linear_reg() %>%
  ______("lm") %>%
  ______("regression")

# 3. Ajuste
ajuste <- modelo %>%
  ______(formula = y ~ x1 + x2 + x3, data = train)

# 4. Predicción
preds <- ______(ajuste, new_data = test)
```

**H.12.** En tidymodels, ¿qué función permite calcular varias métricas al mismo tiempo (rmse, rsq, mae)? Escriba un ejemplo de su uso.

---

## SECCIÓN I. Recetas y feature engineering

**I.1.** Defina **feature engineering**. ¿Cuáles son las tres acciones principales que abarca?

**I.2.** Mencione cinco problemas típicos en datos crudos que motivan el uso de recetas (por ejemplo, NAs, varianza cero, etc.).

**I.3.** Describa los cuatro pasos del flujo de una receta: `recipe()`, `step_*()`, `prep()`, `bake()`. ¿Qué hace cada uno?

**I.4.** ¿Por qué es importante que la receta se ajuste **solo con datos de entrenamiento** antes de aplicarla a la base de prueba? ¿Qué problema se evita?

**I.5.** Complete la tabla relacionando el problema con la función `step_*()` apropiada:

| Problema | Función `step_*()` |
|---|---|
| Variables categóricas a dummies | ____________________ |
| Variables con escala muy distinta | ____________________ |
| Predictores con varianza casi cero | ____________________ |
| Datos faltantes (numéricos) | ____________________ |
| Predictores altamente correlacionados | ____________________ |
| Variables muy sesgadas (positivas y negativas) | ____________________ |

**I.6.** Explique la diferencia entre `step_zv()` y `step_nzv()`. ¿En qué momento del pipeline conviene aplicarlos?

**I.7.** ¿Por qué es importante el **orden** en el que se concatenan los `step_*()` en una receta? Dé un ejemplo de un orden incorrecto y explique qué saldría mal.

**I.8.** Explique los selectores: `all_predictors()`, `all_numeric_predictors()`, `all_nominal_predictors()`, `all_outcomes()`. Dé un caso de uso para cada uno.

**I.9.** Defina **normalización (z-score)**. ¿En qué tipos de modelos es importante normalizar? ¿En cuáles es irrelevante?

**I.10.** Suponga la siguiente receta:

```r
receta <- recipe(precio ~ ., data = train) %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_impute_mode(all_nominal_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_corr(all_numeric_predictors(), threshold = 0.85) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors())
```

   a) Explique línea por línea qué hace cada paso.
   b) ¿Por qué se aplica `step_dummy()` al final y no al principio?
   c) ¿Por qué se aplica `step_normalize()` antes que `step_dummy()`?

---

## SECCIÓN J. Validación cruzada y tuning de hiperparámetros

**J.1.** ¿Qué es la **validación cruzada (k-fold CV)**? ¿Qué problema resuelve frente a un único split entrenamiento/prueba?

**J.2.** ¿Para qué se usa `vfold_cv()` en tidymodels? ¿Qué representa el argumento `v`?

**J.3.** Explique el flujo completo de tuning de hiperparámetros: `tune()` → `grid_regular()` → `tune_grid()` → `collect_metrics()` → `select_best()` → `finalize_workflow()` → `fit()`. Qué hace cada función.

**J.4.** ¿Por qué se usa una grilla de valores de `penalty` (lambda) en escala logarítmica (por ejemplo, `range = c(-3, 1)`)?

**J.5.** En el ejercicio de calidad del aire (Ridge), se usaron 10 folds y 50 valores de lambda. ¿Cuántos modelos se ajustaron en total? ¿Por qué este enfoque es más confiable que un solo split?

**J.6.** ¿Qué argumento se le pasa a `select_best()` para que escoja el mejor modelo bajo una métrica específica? ¿Qué métrica usaría en un problema de regresión y por qué?

---

## SECCIÓN K. Aplicación e interpretación con contexto mexicano/latinoamericano

**K.1.** **CDMX — Precios de vivienda.** Suponga que quiere predecir el precio de venta de viviendas en la CDMX con variables: $m^2$, alcaldía, antigüedad, número de recámaras y baños. Diseñe el flujo completo (split → receta → modelo → evaluación) e identifique qué pasos de feature engineering aplicaría.

**K.2.** **ENOE — Ingreso laboral.** Con la ENOE del INEGI se quiere modelar el ingreso laboral en función de educación, experiencia, sexo, formalidad y región. ¿Qué tipo de regresión utilizaría? ¿Qué problemas de colinealidad o heterocedasticidad esperaría?

**K.3.** **CONEVAL — Pobreza.** ¿Por qué un modelo de regresión lineal **no** sería apropiado para predecir si un hogar es pobre o no (variable binaria 0/1)? ¿Cómo cambiaría el problema si la variable respuesta fuera el ingreso per cápita continuo?

**K.4.** **PISA — Resultados educativos.** Para un modelo que prediga el puntaje PISA de México con variables del centro educativo (recursos, número de alumnos, perfil docente, NSE), discuta:
- ¿Se justifica usar Lasso o Ridge?
- ¿Qué problemas éticos o de interpretación podrían surgir si los coeficientes se interpretan causalmente?

**K.5.** **IMSS — Salarios formales.** Con datos de salarios del IMSS, suponga que la variable $Y$ es altamente sesgada hacia la derecha (cola larga de altos salarios). ¿Qué transformación recomendaría y por qué?

**K.6.** **Programas sociales.** Un investigador encuentra que en un modelo que estima el efecto de un programa social, el coeficiente de "participación en el programa" cambia bruscamente cuando agrega "nivel educativo" como control. ¿Cómo se llama este fenómeno? ¿Qué precaución debe tomar al interpretarlo?

**K.7.** **ENIGH — Gasto.** El INEGI publica la ENIGH cada dos años. Si quisiera modelar el gasto familiar como función del ingreso y otras variables, ¿usaría todos los años disponibles o solo uno? ¿Qué problemas plantearía mezclar varios años?

**K.8.** **Banxico — Inflación.** Para predecir la inflación mensual con muchas variables macroeconómicas, ¿usaría `initial_split()` o `initial_time_split()`? Justifique a partir de la naturaleza temporal de los datos.

---

## SECCIÓN L. Verdadero / Falso (con justificación)

**Instrucciones**: Responda V o F y justifique brevemente cada respuesta. Una respuesta sin justificación no recibe puntos.

**L.1.** El modelo $Y = \beta_0 + \beta_1 X^2 + \beta_2 X^3$ no es un modelo lineal porque tiene potencias de $X$.

**L.2.** El método de OLS (mínimos cuadrados ordinarios) minimiza la suma de los **valores absolutos** de los errores.

**L.3.** Un $R^2$ alto en datos de entrenamiento garantiza que el modelo predecirá bien en datos nuevos.

**L.4.** El RMSE y el $R^2$ siempre concuerdan: si uno mejora, el otro también.

**L.5.** Para incluir una variable categórica con 5 niveles en una regresión, se deben crear 5 variables dummy.

**L.6.** El $R^2$ de una regresión múltiple depende de cuál nivel se elija como categoría base de las variables dummy.

**L.7.** Ridge (L2) realiza selección automática de variables haciendo coeficientes exactamente cero.

**L.8.** Lasso (L1) es preferible cuando se sospecha que solo unos pocos predictores son verdaderamente relevantes.

**L.9.** La normalización (z-score) es indispensable para regresión lineal clásica (OLS).

**L.10.** En tidymodels, cambiar de un modelo lineal a un random forest requiere reescribir todo el flujo de trabajo.

**L.11.** La función `prep()` aprende los parámetros de la receta usando la base de entrenamiento; `bake()` los aplica.

**L.12.** Si dos predictores tienen correlación de 0.99, conviene incluirlos a ambos en el modelo porque "más información, mejor".

**L.13.** La heterocedasticidad invalida automáticamente los coeficientes estimados de la regresión.

**L.14.** Un modelo sobreajustado tiene **alto sesgo** y **baja varianza**.

**L.15.** Validación cruzada k-fold con $k = 10$ ajusta el modelo 10 veces y promedia las métricas.

---

## SECCIÓN M. Código R — completar, depurar e interpretar

**M.1.** Identifique el error en el siguiente código y corríjalo:

```r
home_split <- initial_split(home_prices, prop = 0.7, strata = selling_price)
home_test  <- home_split %>% training()
home_train <- home_split %>% testing()

modelo <- linear_reg() %>% set_engine("lm")
fit_modelo <- modelo %>% fit(selling_price ~ ., data = home_test)
preds <- predict(fit_modelo, new_data = home_train)
```

**M.2.** Considere el siguiente código. ¿Qué hiperparámetro está dejando como `tune()` y qué tipo de regularización resultará?

```r
modelo <- linear_reg(penalty = tune(), mixture = 0.5) %>%
  set_engine("glmnet")
```

**M.3.** Escriba el código completo de una receta que: imputa NAs numéricos con la mediana, imputa NAs nominales con la moda, elimina predictores con correlación mayor a 0.85, elimina varianza cero, normaliza numéricos y crea dummies. Use la fórmula `y ~ .` y los datos `train`.

**M.4.** El siguiente código produce un error. Explique por qué y corríjalo:

```r
receta <- recipe(precio ~ ., data = train) %>%
  step_dummy(all_nominal_predictors()) %>%
  step_corr(all_numeric_predictors(), threshold = 0.85) %>%
  step_impute_median(all_numeric_predictors())
```

(*Pista*: piense en el orden lógico de las operaciones.)

**M.5.** Considere el siguiente código de evaluación y explique qué calcula cada línea:

```r
resultados <- predict(ajuste, new_data = test) %>%
  bind_cols(test %>% select(precio))

mis_metricas <- metric_set(rmse, rsq, mae)
resultados %>% mis_metricas(truth = precio, estimate = .pred)
```

**M.6.** Escriba el código de tidymodels que:

   1. Carga `precio_viviendas_2.xlsx`.
   2. Divide 75/25 con `set.seed(20260512)`.
   3. Aplica una receta de imputación, normalización y dummies.
   4. Ajusta un modelo Lasso con `penalty = 0.1` y `mixture = 1`.
   5. Evalúa con rmse, rsq y mae en la base de prueba.
   6. Grafica valores reales vs predichos con ggplot2 y `geom_abline()`.

**M.7.** Escriba el código para obtener la **matriz de correlación** de las variables numéricas de un dataframe `datos` y visualizarla con `corrplot::corrplot()`. ¿Qué patrón visual indicaría problemas de colinealidad?

**M.8.** Si tras ajustar un modelo Lasso con tidymodels quiere ver **qué variables fueron seleccionadas** (coeficiente distinto de cero), ¿qué código usaría?

**M.9.** Modifique el siguiente bloque para que use **Ridge** en lugar de regresión lineal clásica:

```r
modelo <- linear_reg() %>%
  set_engine("lm") %>%
  set_mode("regression")
```

**M.10.** Escriba el código completo para correr validación cruzada de 10 folds sobre el dataset `cultivos_training`, ajustar un modelo Ridge tuneando `penalty` sobre 50 valores y seleccionar el mejor por RMSE.

---

## SECCIÓN N. Análisis crítico y casos abiertos (preguntas de discusión)

**N.1.** Un consultor presenta a un funcionario público un modelo de regresión con $R^2 = 0.94$ que predice la deserción escolar en secundarias. El funcionario le pide que **identifique las causas** de la deserción para diseñar política pública. ¿Qué problemas conceptuales debe advertir el consultor? Distinga entre predicción y causalidad.

**N.2.** Suponga un modelo Lasso que predice la incidencia delictiva por colonia. Una variable seleccionada es "porcentaje de hogares jefatura femenina". El alcalde quiere usar esto para focalizar patrullaje. Discuta los riesgos éticos y metodológicos.

**N.3.** ¿Por qué un modelo con muchas variables (alto $R^2$) puede ser **peor** para tomar decisiones de política pública que un modelo con pocas variables (menor $R^2$)? Discuta la tensión entre **predicción** y **explicabilidad**.

**N.4.** Compare las ventajas y desventajas de un modelo de regresión lineal frente a un random forest desde la perspectiva de un **tomador de decisiones públicas**. ¿Cuál preferiría y por qué?

**N.5.** Imagine que está prediciendo el riesgo de no recibir un trasplante con tiempo en el IMSS. Las variables incluyen edad, sexo, comorbilidades y código postal. El modelo resulta con buen RMSE. ¿Qué cuestionamientos éticos plantearía antes de usarlo operativamente? ¿Qué le pediría al equipo de datos?

**N.6.** Un compañero argumenta: "como el $R^2$ del modelo Lasso es 0.05 menor que el de la regresión múltiple, prefiero la regresión múltiple". ¿Es necesariamente correcto? ¿Bajo qué criterio preferiría usted Lasso?

**N.7.** Discuta: **"todos los modelos están equivocados, pero algunos son útiles"** (George Box). ¿Cómo aplica esta frase específicamente a los modelos de regresión que estudiamos en clase?

---

## SECCIÓN O. Cálculos y problemas numéricos

**O.1.** Dada la regresión $\hat{Y} = 100 + 25 X$:

   a) Prediga $Y$ para $X = 8$.
   b) Si el valor real fue $Y = 320$, ¿cuál es el residuo?
   c) Si los datos van de $X = 0$ a $X = 10$, ¿sería razonable predecir $Y$ para $X = 50$? ¿Por qué?

**O.2.** Suponga que en un modelo de salarios:

$$\hat{\text{Salario}} = 6{,}000 + 2{,}500 \cdot \text{escolaridad} + 150 \cdot \text{experiencia} - 1{,}200 \cdot \text{dummy\_mujer}$$

   Calcule el salario predicho para:

   a) Una mujer con 16 años de escolaridad y 5 años de experiencia.
   b) Un hombre con 12 años de escolaridad y 10 años de experiencia.
   c) Interprete la diferencia $-1{,}200 \cdot \text{dummy\_mujer}$.

**O.3.** Dado el modelo y datos:

| $y_i$ | $\hat{y}_i$ |
|---|---|
| 10 | 9 |
| 15 | 14 |
| 20 | 22 |
| 25 | 24 |
| 30 | 31 |

   Calcule:

   a) RSS (suma de residuos al cuadrado).
   b) RMSE.
   c) MAE.

**O.4.** Suponga que la varianza total de $Y$ es $\text{TSS} = 100$ y la suma de residuos al cuadrado del modelo es $\text{RSS} = 25$. Calcule $R^2$ usando la fórmula $R^2 = 1 - \frac{\text{RSS}}{\text{TSS}}$. Interprete el resultado.

**O.5.** Si una variable $X$ tiene media 50 y desviación estándar 10, normalice (z-score) los siguientes valores: 30, 50, 65, 80. ¿Qué interpretación tiene cada $z$?

---

## SECCIÓN P. Síntesis e integración

**P.1.** **Tabla resumen.** Complete la siguiente tabla comparativa:

| Aspecto | Regresión Lineal Múltiple | Ridge | Lasso |
|---|---|---|---|
| Penalización | | | |
| Selección automática de variables | | | |
| ¿Coeficientes pueden ser cero? | | | |
| ¿Requiere normalización? | | | |
| ¿Cuándo usar? | | | |

**P.2.** **Mapa conceptual.** Dibuje (o describa) un mapa conceptual que conecte los siguientes términos: regresión, OLS, RSS, R², overfitting, validación cruzada, regularización, Ridge, Lasso, feature engineering, recetas.

**P.3.** **Pipeline completo.** Para un problema de política pública de su interés (educación, salud, seguridad, vivienda, transporte, etc.):

   1. Defina la pregunta de investigación.
   2. Identifique $Y$ y $X$.
   3. Proponga la fuente de datos (encuesta, registro administrativo, censo).
   4. Diseñe el pipeline completo: split, receta, modelo, evaluación.
   5. Justifique cada decisión.
   6. Discuta limitaciones éticas y metodológicas.

---

## Sugerencias para la selección final

- **Tarea ligera (10-15 preguntas):** Tomar 2-3 de definiciones (Sección A, B), 2-3 de evaluación (C), 2-3 de tidymodels (H, I), 1-2 de V/F (L) y 1 de código (M).
- **Tarea estándar (20-30 preguntas):** Cubrir todas las secciones temáticas con 2-3 preguntas cada una, incluyendo al menos un caso aplicado (K) y un análisis crítico (N).
- **Tarea extensa (40-50 preguntas):** Incluir cálculos numéricos (O), código de tidymodels (M) y un caso de síntesis (P.3) como ejercicio integrador.
- **Para examen parcial:** Combinar V/F con justificación (L) + interpretación (B, D, F) + cálculo numérico (O) + código corto (M).

---

*Fin del banco de preguntas. Total aproximado: 140+ preguntas.*
