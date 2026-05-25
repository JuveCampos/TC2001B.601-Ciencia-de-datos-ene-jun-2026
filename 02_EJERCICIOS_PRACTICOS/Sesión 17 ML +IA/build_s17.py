"""Sesión 17 - ML + IA. Funciones de R del ejercicio de REGRESIÓN.
Predecir el costo médico anual (MXN) con KNN de regresión y k tuneado.
Fragmentos reales del ejercicio sesion_17_ml_ia/regresión/ejercicio.R."""
from estilo_tec import (nueva_presentacion, slide_portada, slide_intro,
                        slide_funcion, slide_conclusiones, slide_cierre)

FT = "Sesión 17 - ML + IA (regresión)"
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "sesion_17_funciones_ml_ia.pptx")

prs = nueva_presentacion()
n = 1

slide_portada(prs,
    "Sesión 17: ML + IA\nRegresión con tidymodels",
    "Las funciones de R que usamos, una por una",
    "TC2001B.601 - Ciencia de datos para la toma de decisiones I\n"
    "Ejemplos tomados del ejercicio: costo médico anual (regresión)")

slide_intro(prs, "El flujo de regresión, función por función",
    "El objetivo es predecir el costo médico anual de un paciente, en pesos. "
    "Es un problema de regresión: la variable objetivo es numérica y está "
    "sesgada a la derecha, así que modelamos su logaritmo. Recorremos cada "
    "función con fragmentos reales del ejercicio.",
    "1.  read_csv() + select()  -  cargar y quitar el id\n"
    "2.  initial_split() / training() / testing()  -  partir los datos\n"
    "3.  recipe() + step_log()  -  receta y log de la objetivo\n"
    "4.  step_impute_median() / step_dummy() / step_normalize()  -  preparar\n"
    "5.  nearest_neighbor() + set_mode(\"regression\")  -  el modelo KNN\n"
    "6.  workflow() + vfold_cv() + tune_grid()  -  empaquetar y tunear\n"
    "7.  select_best() + last_fit() + métricas en pesos  -  cerrar el ciclo",
    n, FT); n += 1

slide_funcion(prs, "read_csv() + select()",
    "Carga el CSV como tibble y quita el identificador, que no es un "
    "predictor.",
    ['costos <- read_csv("datos.csv") %>%',
     '  select(-id_paciente)'],
    "- read_csv() (de readr) lee el archivo y lo deja como tibble, con tipos "
    "de columna inferidos.\n"
    "- select(-id_paciente) descarta el identificador: dejarlo no aporta "
    "señal y podría inducir fuga de información (data leakage).\n"
    "- La objetivo costo_anual_mxn se queda numérica: por eso es regresión, "
    "no clasificación.", n, FT); n += 1

slide_funcion(prs, "summarise() + log()",
    "Comparamos media contra mediana para detectar el sesgo a la derecha de "
    "la objetivo.",
    ['costos %>%',
     '  summarise(media = mean(costo_anual_mxn),',
     '            mediana = median(costo_anual_mxn))',
     '',
     '# si media >> mediana hay cola larga a la derecha;',
     '# log() comprime esa cola y simetriza la distribución'],
    "- Si la media es bastante mayor que la mediana, hay sesgo a la derecha: "
    "una cola larga de costos altos, típica de variables monetarias.\n"
    "- log() comprime esa cola y vuelve la distribución más simétrica, lo que "
    "facilita el ajuste del modelo.\n"
    "- Esta exploración motiva la decisión de modelar log(costo) en la receta.",
    n, FT); n += 1

slide_funcion(prs, "initial_split()",
    "Separa los datos en entrenamiento y prueba, conservando la distribución "
    "del costo.",
    ['set.seed(123)',
     'costos_split <- initial_split(data = costos,',
     '                              prop = 0.75,',
     '                              strata = costo_anual_mxn)',
     'costos_entrenamiento <- costos_split %>% training()',
     'costos_prueba        <- costos_split %>% testing()'],
    "- initial_split() define el corte (aquí 75% / 25%). En regresión "
    "estratificamos por la propia objetivo numérica con strata.\n"
    "- Así la distribución del costo queda parecida en ambas particiones.\n"
    "- training() y testing() extraen cada parte; la prueba se reserva para "
    "el final. set.seed() hace reproducible el corte.", n, FT); n += 1

slide_funcion(prs, "recipe()",
    "Declara la receta de preprocesamiento: la fórmula y la secuencia de "
    "pasos.",
    ['receta_costos <-',
     '  recipe(costo_anual_mxn ~ ., data = costos_entrenamiento) %>%',
     '  step_log(costo_anual_mxn, base = exp(1)) %>%',
     '  step_impute_median(all_numeric_predictors()) %>%',
     '  step_unknown(all_nominal_predictors()) %>%',
     '  step_nzv(all_predictors()) %>%',
     '  step_normalize(all_numeric_predictors()) %>%',
     '  step_dummy(all_nominal_predictors()) %>%',
     '  step_zv(all_predictors())'],
    "- recipe(costo_anual_mxn ~ .) dice 'predice el costo usando todas las "
    "demás variables'.\n"
    "- Encadenamos pasos step_*() con %>%. El ORDEN importa: primero el log de "
    "la objetivo y la imputación, antes de los pasos que no toleran NAs.\n"
    "- La receta es solo una RECETA: aún no toca los datos; se aplica dentro "
    "del workflow.", n, FT, code_size=11); n += 1

slide_funcion(prs, "step_log()",
    "Transforma la objetivo a su logaritmo. Es el paso DISTINTIVO de esta "
    "regresión.",
    ['step_log(costo_anual_mxn, base = exp(1))'],
    "- El costo está sesgado a la derecha (tipo log-normal). Modelar log(costo) "
    "ESTABILIZA la varianza y LINEALIZA relaciones multiplicativas.\n"
    "- Reduce el peso de los valores extremos, que de otro modo dominarían el "
    "error cuadrático.\n"
    "- CONSECUENCIA: el modelo predice en escala log. Para reportar en pesos "
    "hay que EXPONENCIAR de vuelta con exp() al final.", n, FT); n += 1

slide_funcion(prs, "step_impute_median()",
    "Rellena los valores faltantes (NAs) de las variables numéricas con su "
    "mediana.",
    ['step_impute_median(all_numeric_predictors())'],
    "- En estos datos imc tiene cerca de 4% de NAs; este paso los sustituye "
    "por la mediana de la columna.\n"
    "- La mediana se calcula SOLO con el entrenamiento (evita filtrar "
    "información de la prueba) y es robusta a valores extremos.\n"
    "- all_numeric_predictors() es un selector: aplica el paso a todas las "
    "columnas numéricas que sean predictores.", n, FT); n += 1

slide_funcion(prs, "step_dummy() + step_unknown()",
    "Codifican las variables categóricas como columnas binarias, tras tratar "
    "sus NAs.",
    ['step_unknown(all_nominal_predictors()) %>%',
     '# ... otros pasos ...',
     'step_dummy(all_nominal_predictors())'],
    "- Hay categóricas: sexo, fumador y region. KNN necesita números, no "
    "texto.\n"
    "- step_unknown() convierte los NAs categóricos en un nivel 'unknown' "
    "ANTES de crear las dummies, para no perder filas.\n"
    "- step_dummy() crea una columna 0/1 por cada nivel (menos uno de "
    "referencia): así las categorías entran en la distancia de KNN.",
    n, FT); n += 1

slide_funcion(prs, "step_normalize()",
    "Estandariza cada predictor numérico a media 0 y desviación 1. Es CRÍTICO "
    "para KNN.",
    ['step_normalize(all_numeric_predictors())'],
    "- KNN mide distancias. Sin normalizar, una variable en miles de pesos "
    "aplastaría a otra de escala pequeña, como las horas de actividad.\n"
    "- Tras normalizar, todas las variables contribuyen en la misma escala a "
    "la distancia.\n"
    "- Igual que la imputación, los parámetros (media y sd) se estiman con el "
    "entrenamiento.", n, FT); n += 1

slide_funcion(prs, "nearest_neighbor() + set_mode()",
    "Especifica el modelo KNN en modo regresión: promedia el valor de los k "
    "vecinos.",
    ['modelo_knn <- nearest_neighbor(neighbors = tune()) %>%',
     '  set_engine("kknn") %>%',
     '  set_mode("regression")'],
    "- nearest_neighbor() declara el modelo. neighbors = el número de vecinos "
    "k; tune() significa 'a determinar por validación cruzada'.\n"
    "- set_mode(\"regression\"): a diferencia de la clasificación, no vota una "
    "clase, sino que PROMEDIA el log del costo de los k vecinos más cercanos.\n"
    "- set_engine(\"kknn\") elige el paquete que ejecuta el modelo.",
    n, FT); n += 1

slide_funcion(prs, "workflow()",
    "Empaqueta la receta y el modelo en un solo objeto, robusto y "
    "reutilizable.",
    ['workflow_knn <- workflow() %>%',
     '  add_recipe(receta_costos) %>%',
     '  add_model(modelo_knn)'],
    "- workflow() crea el contenedor. add_recipe() le pega el preprocesamiento "
    "y add_model() el modelo.\n"
    "- Ventaja clave: al ajustar hace internamente prep + bake + fit; al "
    "predecir aplica el MISMO preprocesamiento a los datos nuevos.\n"
    "- Evita el error común de olvidar transformar la base de prueba.",
    n, FT); n += 1

slide_funcion(prs, "vfold_cv()",
    "Crea los pliegues (folds) de validación cruzada sobre el entrenamiento.",
    ['set.seed(123)',
     'folds_cv <- vfold_cv(data = costos_entrenamiento,',
     '                     v = 5,',
     '                     strata = costo_anual_mxn)'],
    "- Parte el entrenamiento en v = 5 porciones. En cada ronda usa 4 para "
    "entrenar y 1 para validar; rota hasta que cada fold valida una vez.\n"
    "- Sirve para estimar el desempeño SIN tocar la prueba.\n"
    "- strata = costo_anual_mxn mantiene la distribución del costo en cada "
    "fold.", n, FT); n += 1

slide_funcion(prs, "tibble(neighbors=) + tune_grid()",
    "Definen la lista de valores de k y corren la validación cruzada para "
    "cada uno.",
    ['grilla_k <- tibble(',
     '  neighbors = c(3, 5, 7, 11, 15, 21, 31, 51, 75, 101))',
     '',
     'resultados_tuning <- workflow_knn %>%',
     '  tune_grid(resamples = folds_cv,',
     '            grid = grilla_k,',
     '            metrics = metricas_tuning)'],
    "- tune() (en el modelo) marca el parámetro a buscar; la grilla lista los "
    "valores candidatos de k a probar.\n"
    "- tune_grid() ajusta el workflow en los 5 folds para CADA k y promedia "
    "sus métricas. Es el corazón del tuning.\n"
    "- resamples = los folds; grid = los k; metrics = qué medir. Devuelve una "
    "tabla por k lista para comparar.", n, FT, code_size=11); n += 1

slide_funcion(prs, "metric_set() + rmse() + rsq() + mae()",
    "Definen las métricas de regresión con que evaluamos el modelo (no AUC).",
    ['metricas_tuning <- metric_set(rmse, rsq, mae)',
     '',
     'collect_metrics(resultados_tuning)'],
    "- metric_set() agrupa varias métricas de regresión en un evaluador "
    "reutilizable.\n"
    "- rmse: raíz del error cuadrático medio, penaliza fuerte los errores "
    "grandes; es la principal aquí. mae: error absoluto medio, más robusto.\n"
    "- rsq (R cuadrada): proporción de la variación del costo que explica el "
    "modelo; cerca de 1 es mejor.\n"
    "- OJO: en el tuning estas métricas están en escala LOGARÍTMICA.",
    n, FT); n += 1

slide_funcion(prs, "select_best() + finalize_workflow()",
    "Elige el mejor k (menor RMSE) y lo inyecta en el workflow para "
    "finalizarlo.",
    ['mejor_k <- resultados_tuning %>%',
     '  select_best(metric = "rmse")',
     '',
     'workflow_knn_final <- workflow_knn %>%',
     '  finalize_workflow(mejor_k)'],
    "- select_best(metric = \"rmse\") devuelve el k con menor RMSE promedio en "
    "CV. En regresión queremos minimizar el error, no maximizar AUC.\n"
    "- finalize_workflow(mejor_k) fija el hiperparámetro tune() con el valor "
    "elegido.\n"
    "- El k elegido por CV equilibra sesgo y varianza.", n, FT); n += 1

slide_funcion(prs, "last_fit() + métricas en pesos",
    "Reentrena con todo el entrenamiento, evalúa en la prueba y exponencia "
    "para reportar en MXN.",
    ['ajuste_final <- workflow_knn_final %>%',
     '  last_fit(split = costos_split,',
     '           metrics = metric_set(rmse, rsq, mae))',
     '',
     'predicciones_finales <- collect_predictions(ajuste_final) %>%',
     '  mutate(pred_pesos = exp(.pred),',
     '         real_pesos = exp(costo_anual_mxn))',
     'metricas_pesos(predicciones_finales,',
     '               truth = real_pesos, estimate = pred_pesos)'],
    "- last_fit() reentrena con TODO el entrenamiento y evalúa en la prueba "
    "reservada en un solo paso: la estimación honesta del desempeño.\n"
    "- Las predicciones salen en escala log; exp() las regresa a pesos junto "
    "con el valor real.\n"
    "- Recalculamos rmse y mae sobre los pesos: así el error se lee "
    "directamente en MXN, que es lo que entiende el área de negocio.",
    n, FT, code_size=11); n += 1

slide_conclusiones(prs, "Resumen: regresión con el mismo flujo de tidymodels",
    "- En regresión la objetivo es numérica; si está sesgada, step_log() la "
    "simetriza y luego exp() devuelve los resultados a pesos.\n"
    "- recipe() + step_*() preparan los datos; el orden de los pasos importa "
    "(log e imputación primero, dummies y normalización después).\n"
    "- set_mode(\"regression\") es lo único que cambia en el modelo KNN: "
    "promedia en vez de votar.\n"
    "- Las métricas son rmse, rsq y mae (no AUC); elegimos k por el menor RMSE "
    "con vfold_cv() + tune_grid().\n"
    "- Sesión ML + IA: el archivo prompt_estudiante.md trae un prompt para que "
    "un LLM te GUÍE por este flujo respetando el estilo del curso, sin "
    "resolvértelo.", n, FT); n += 1

slide_cierre(prs)

prs.save(OUT)
print("Guardado:", OUT, "| slides:", len(prs.slides._sldIdLst))
