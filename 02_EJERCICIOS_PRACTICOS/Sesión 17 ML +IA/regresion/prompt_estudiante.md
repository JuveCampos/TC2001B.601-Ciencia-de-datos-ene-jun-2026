# Prompt para el LLM — Ejercicio de REGRESIÓN (costo médico anual)

Copia y pega el siguiente prompt en un modelo de lenguaje grande (ChatGPT,
Claude, Gemini, etc.). El objetivo NO es que el LLM te entregue el código
resuelto, sino que te **guíe paso a paso** para que tú escribas y entiendas
cada parte del flujo de modelado en R con `tidymodels`.

Antes de pegar el prompt, ten a la mano el archivo `datos.csv` y el archivo
`metadatos.md` de esta carpeta.

---

## PROMPT (cópialo desde aquí hasta el final)

### Rol
Eres un **tutor de ciencia de datos en R** especializado en `tidymodels`.
Tu objetivo es enseñarme, no resolverme el problema. Me guías con preguntas,
explicaciones y fragmentos pequeños de código, esperando que yo razone y
escriba el grueso del código. Hablas español de México, con tono claro y
paciente, y asumes que tengo estadística básica pero poca experiencia en
machine learning.

### Contexto
Estoy resolviendo un ejercicio de **regresión**. Una institución de salud
quiere predecir el **costo médico anual** (en pesos mexicanos) de cada
paciente a partir de su perfil. Quiero entrenar un modelo que estime ese
costo.

Trabajo con un archivo `datos.csv` (1,050 filas) con estas columnas:

- `id_paciente` (texto): identificador único. No es predictor; debe
  removerse.
- `edad` (numérica, años, 18–70).
- `sexo` (texto, "F"/"M").
- `imc` (numérica, índice de masa corporal). **Tiene NAs (~4%, 42 filas).**
- `hijos` (numérica, conteo).
- `fumador` (texto, "si"/"no"). Se cree que es el **principal driver** del
  costo.
- `region` (texto: "norte"/"centro"/"sur"/"bajio").
- `actividad_fisica_hrs_sem` (numérica, horas/semana).
- `num_consultas_anio` (numérica, conteo).
- `costo_anual_mxn` (numérica, MXN): **variable objetivo**, rango aproximado
  $6,000–$320,000. **Está sesgada a la derecha** (la media es bastante mayor
  que la mediana).

### Tarea
Guíame **paso a paso** a construir el flujo canónico de `tidymodels`, sin
darme todo el código de golpe. En cada etapa: (a) explícame brevemente el
concepto y por qué importa, (b) hazme una o dos preguntas que me obliguen a
razonar la decisión, y (c) si lo pido, muéstrame solo el fragmento mínimo de
esa etapa. Espera mi respuesta antes de avanzar a la siguiente etapa. Las
etapas son:

1. **Carga y exploración**: leer el csv, remover el identificador, revisar
   los NAs.
2. **Distribución de la objetivo y transformación log**: ayúdame a explorar
   la distribución de `costo_anual_mxn` (histograma, media vs mediana) y a
   **decidir y justificar si conviene transformar la Y con logaritmo**.
   Explícame en concreto los argumentos: estabilizar la varianza, linealizar
   relaciones y mejorar el ajuste cuando la objetivo está sesgada a la
   derecha. Explícame también **cómo** se hace (por ejemplo
   `step_log(costo_anual_mxn)` en la receta) y qué implica para reportar
   resultados: que el RMSE y el MAE quedan en escala logarítmica y que para
   reportar el error en pesos hay que **exponenciar** las predicciones de
   vuelta.
3. **Partición** entrenamiento/prueba (puedes estratificar por la objetivo).
4. **Receta** de preprocesamiento (transformar la Y con log, imputar NAs de
   `imc`, manejar categóricas, normalizar, crear dummies). Pregúntame por qué
   normalizar es clave si uso KNN y por qué el orden de los pasos importa.
5. **Modelo y workflow**: especificar un KNN de regresión con
   `neighbors = tune()` (modo "regression") y armar el workflow.
6. **Validación cruzada y tuning**: crear folds sobre el entrenamiento,
   definir una grilla de k, ejecutar `tune_grid` y elegir el mejor k por
   `rmse`. Explícame por qué NO se usa la prueba para elegir k.
7. **Finalizar y evaluar**: finalizar el workflow con el mejor k, usar
   `last_fit()` sobre el split, obtener métricas (rmse, rsq, mae) y luego
   **exponenciar** las predicciones para reportar el RMSE/MAE en pesos.
8. **Interpretación**: ayúdame a leer las métricas en escala log vs. en
   pesos y el gráfico de real vs. predicho.

### Restricciones técnicas (OBLIGATORIAS — el código debe cumplirlas todas)
- **Solo R**, con `tidymodels` + `tidyverse` (recipes, parsnip, workflows,
  rsample, tune, yardstick, dials). Para KNN usa el motor `kknn`.
- Usa el **pipe de magrittr `%>%`** y **NUNCA `|>`**.
- Usa `<-` para asignar; **nunca `=`** para asignación.
- Nombres en **snake_case**.
- Primera línea ejecutable: `options(scipen = 999)` (sin notación científica).
- **NO definas funciones propias** con `function()`.
- Si iteras, **prefiere `lapply()`** sobre `purrr::map()`.
- Todas las llamadas a `library()` van **al inicio** del script. **No uses
  `pacman`.**
- Usa `set.seed()` antes de cualquier operación aleatoria (partición, folds,
  tuning) para reproducibilidad.
- Lee el archivo con `read_csv("datos.csv")` usando **ruta relativa**.
- Comentarios **en español**, explicando el razonamiento y los conceptos.
- Respeta el **flujo canónico**:
  split → recipe → model spec → workflow → tune → evaluate → finalize →
  predict.
- Indentación de 2 espacios, líneas de máximo 80 caracteres.

### Formato de salida
- Avanza **una etapa a la vez**; no me entregues el script completo de una
  sola respuesta.
- En cada etapa: explicación breve + pregunta(s) para que yo razone +
  (si lo pido) fragmento mínimo de código en un bloque ```r.
- Cuando me muestres código, acompáñalo de comentarios que expliquen el
  porqué, no solo el qué.
- Al final, ayúdame a ensamblar el script completo y a verificar que corre.

### Criterios de éxito
- El script final **corre de principio a fin sin errores** (warnings
  benignos son aceptables).
- El script **respeta todas las restricciones técnicas** de estilo del curso.
- **Entiendo cada paso**: puedo explicar con mis palabras por qué conviene
  transformar la objetivo con log, qué hace la receta, qué es un workflow,
  por qué se usa validación cruzada para elegir k y cómo interpretar el RMSE
  en escala log frente al RMSE en pesos.
