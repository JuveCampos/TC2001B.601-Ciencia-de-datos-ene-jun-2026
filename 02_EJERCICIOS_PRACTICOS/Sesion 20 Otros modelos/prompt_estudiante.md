# Prompt para el estudiante — Sesión 20: Comparar modelos y armar un ensamble

En esta sesión vas a usar un modelo de lenguaje (LLM) como copiloto para
**comparar varios modelos de machine learning, seleccionar el mejor y
combinarlos en un ensamble por stacking**. No se trata de que el LLM te dé el
código y ya: tu trabajo es darle un prompt claro, leer críticamente su
respuesta, correr el código y justificar tu elección con métricas.

Abajo tienes una **plantilla de prompt** lista para copiar, pegar y adaptar al
dataset que te toque (clasificación de crédito, regresión de costos médicos o
clustering de municipios). Revisa que TODAS las restricciones técnicas sigan
presentes: están ahí para que el código respete el estilo del curso y corra a
la primera.

---

## Plantilla de prompt (cópiala y rellena lo que está entre [corchetes])

> ### Rol
> Eres un ingeniero senior de machine learning y docente de un curso
> universitario de ciencia de datos en R. Explicas con rigor pero con
> intuición, pensando en estudiantes de políticas públicas con estadística
> básica. Tu código es limpio, reproducible y está comentado en español.
>
> ### Contexto
> Trabajo con el dataset `datos.csv`, ubicado en la misma carpeta que mi
> script. Es el problema de **[describe: aprobación de crédito / costo médico
> anual / perfiles socioeconómicos de municipios]**. Tiene **[n]
> observaciones** y estas variables: **[pega aquí la tabla de variables de
> `metadatos.md`, indicando tipos, la variable objetivo si aplica, los NAs y
> la colinealidad conocida]**. La variable objetivo es **[nombre de la
> objetivo, o "ninguna: es un problema de clustering no supervisado"]**.
> **[Si la objetivo está sesgada, dilo: p. ej. "costo_anual_mxn está sesgada
> a la derecha, así que hay que modelarla en escala log".]**
>
> ### Tarea
> Quiero un script de R, end-to-end, que:
> 1. Cargue y prepare los datos (imputación de NAs, manejo de colinealidad,
>    normalización, codificación de categóricas según el problema).
> 2. **[Supervisado]** Entrene y **compare al menos [3 o 4] modelos**:
>    **[lista los que correspondan: árbol de decisión (rpart), random forest
>    (ranger), XGBoost (xgboost), regresión lineal/logística regularizada
>    (glmnet)]**, tuneando sus hiperparámetros con validación cruzada.
>    **[Clustering]** Compare **k-means, jerárquico (hclust + cutree) y DBSCAN
>    (dbscan)** sobre datos normalizados.
> 3. Evalúe cada modelo con la **métrica adecuada al problema**
>    (**[clasificación: roc_auc; regresión: rmse y rsq; clustering: número de
>    clusters, silueta y ruido de DBSCAN]**) sobre una base de prueba que el
>    modelo no haya visto.
> 4. **[Supervisado]** Construya un **ENSAMBLE POR STACKING con el paquete
>    `stacks`** combinando los modelos tuneados, y compare el desempeño del
>    stack contra los modelos individuales.
> 5. **Recomiende el mejor modelo (o el ensamble)** y **justifique la elección
>    con las métricas**, no por intuición.
>
> ### Restricciones técnicas (OBLIGATORIAS — el código debe cumplirlas todas)
> - **Solo R.** Usa `tidymodels` + `tidyverse`. Para el ensamble usa el
>   paquete `stacks`. Motores: `rpart`, `ranger`, `xgboost`, `glmnet`; para
>   clustering `stats` (kmeans, hclust), `dbscan`, `factoextra` y `cluster`.
> - **Carga todas las librerías con `library()` al inicio del script.** NO
>   uses `pacman` ni `install.packages()`. Incluye
>   `tidymodels::tidymodels_prefer()`.
> - La **primera línea ejecutable** debe ser `options(scipen = 999)` (sin
>   notación científica en ningún output).
> - Usa el **pipe de magrittr `%>%`** en todo. **NUNCA uses el pipe nativo
>   `|>`.**
> - Asignación con **`<-`**, nunca con `=`.
> - Nombres en **snake_case**.
> - **NO definas funciones propias con `function()`.** (Las funciones de
>   librería como `kmeans`, `hclust`, `dbscan` sí se usan, eso está bien.)
> - Si necesitas iterar, **prefiere `lapply()` sobre `purrr::map()`**, salvo
>   que `map_*()` aporte algo concreto (y entonces explica por qué).
> - Pon **`set.seed()` antes de toda operación aleatoria** (splits, validación
>   cruzada, k-means con nstart, tuning, stacking) para que sea reproducible.
> - Lee el archivo con **`read_csv("datos.csv")`** usando **ruta relativa**.
> - Sigue el **flujo canónico de tidymodels**: split → recipe → model spec →
>   workflow → fit/tune → evaluate → finalize → predict. (En clustering:
>   recipe para normalizar → algoritmo → comparación.)
> - Para el stacking usa `control_stack_grid()` en `tune_grid()` (para guardar
>   las predicciones), y luego
>   `stacks() %>% add_candidates(...) %>% blend_predictions() %>% fit_members()`.
> - **Comentarios en español** (español de México con tildes), pedagógicos:
>   explica qué es un árbol, la diferencia entre bagging y boosting, qué hace
>   la regularización L1/L2 y qué es el stacking.
> - Mantén las **grillas de tuning pequeñas** (`grid = 5` a `8`, o
>   `grid_regular` con pocos niveles) y `vfold_cv(v = 5)`, para que corra en
>   pocos minutos.
> - **Indentación de 2 espacios** y líneas de **máximo 80 caracteres**.
>
> ### Formato de salida
> - Un único bloque de código R, comentado, en el orden del flujo canónico.
> - Antes de cada sección, un comentario corto que explique QUÉ se hace y POR
>   QUÉ (concepto), no solo CÓMO.
> - Al final, una **tabla comparativa** (tibble) con la métrica de cada modelo
>   y la del ensamble, ordenada de mejor a peor.
> - Un párrafo de **conclusión** que diga cuál modelo recomiendas y por qué,
>   citando los números.
>
> ### Criterios de éxito
> 1. El script **corre de principio a fin sin errores** (incluido el
>    stacking) con `Rscript`.
> 2. **Respeta TODAS las restricciones técnicas** de arriba (estilo del curso).
> 3. **Justifica la elección del mejor modelo con la métrica adecuada** al
>    problema (no "se ve bien"): roc_auc para clasificación, rmse/rsq para
>    regresión, y para clustering el número de clusters, la silueta y el ruido
>    de DBSCAN, comentando cuándo conviene cada método.
> 4. Los comentarios explican los conceptos (bagging vs boosting,
>    regularización, stacking) de forma que alguien con estadística básica los
>    entienda.

---

## Cómo trabajar con la respuesta del LLM (no la aceptes a ciegas)

1. **Corre el código tú mismo** con `Rscript ejercicio.R` desde la carpeta del
   dataset. Si truena, copia el error de vuelta al LLM y pídele que lo corrija
   respetando las mismas restricciones.
2. **Verifica el estilo**: busca a mano cualquier `|>`, cualquier `=` usado
   como asignación, cualquier `function(` definida por ti, o un `library()`
   en medio del script. Si aparecen, pídele que los elimine.
3. **Cuestiona la métrica**: ¿está usando roc_auc / rmse / silueta según
   corresponde? ¿Compara el stack contra los individuales en la base de
   prueba (no en entrenamiento)?
4. **Pide que justifique**: si solo te da código, pídele el párrafo de
   conclusión con la recomendación y los números que la sustentan.
5. **Sé escéptico con el "ganador"**: a veces el modelo más complejo (XGBoost)
   no gana. Si una regresión regularizada o el árbol simple quedan igual de
   bien, eso ES un hallazgo: la relación quizá era casi lineal. El stack puede
   empatar al mejor individual; eso también es información válida.
