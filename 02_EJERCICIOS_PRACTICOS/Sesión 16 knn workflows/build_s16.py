"""Sesión 16 - Funciones de KNN, workflows, validación cruzada y tuning.
Fragmentos del ejercicio 1 (aprobación de crédito)."""
from estilo_tec import (nueva_presentacion, slide_portada, slide_intro,
                        slide_funcion, slide_conclusiones, slide_cierre)

FT = "Sesión 16 - KNN y workflows"
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "sesion_16_funciones_knn_workflows.pptx")

prs = nueva_presentacion()
n = 1

slide_portada(prs,
    "Sesión 16: KNN, workflows,\nvalidación cruzada y tuning",
    "Las funciones de tidymodels que usamos, una por una",
    "TC2001B.601 - Ciencia de datos para la toma de decisiones I\n"
    "Ejemplos tomados del ejercicio: aprobación de crédito")

slide_intro(prs, "El flujo de tidymodels, función por función",
    "Cada modelo de este curso sigue el mismo recorrido. En esta sesión "
    "explicamos qué hace cada función del flujo, con fragmentos reales del "
    "ejercicio de aprobación de crédito.",
    "1.  read_csv()  -  cargar los datos\n"
    "2.  initial_split() / training() / testing()  -  partir los datos\n"
    "3.  recipe() + step_*()  -  preprocesamiento (feature engineering)\n"
    "4.  nearest_neighbor() + set_engine() + set_mode()  -  el modelo KNN\n"
    "5.  workflow() + add_recipe() + add_model()  -  empaquetar todo\n"
    "6.  vfold_cv() + grid_regular() + tune_grid()  -  validación y tuning\n"
    "7.  select_best() + finalize_workflow() + last_fit()  -  elegir y evaluar",
    n, FT); n += 1

slide_funcion(prs, "read_csv()",
    "Carga el CSV como tibble; después quitamos el id y volvemos factor el "
    "objetivo.",
    ['creditos <- read_csv("datos.csv") %>%',
     '  select(-id_solicitud) %>%',
     '  mutate(aprobado = factor(aprobado))'],
    "- read_csv() (de readr) lee el archivo y lo deja como tibble, con tipos "
    "de columna inferidos.\n"
    "- select(-id_solicitud) descarta el identificador: no es predictor, solo "
    "añadiría ruido a la distancia de KNN.\n"
    "- factor(aprobado): yardstick y parsnip exigen que el objetivo de "
    "clasificación sea factor, no texto.", n, FT); n += 1

slide_funcion(prs, "initial_split()",
    "Separa los datos en entrenamiento y prueba, conservando la proporción "
    "de clases.",
    ['set.seed(2026)',
     'creditos_split <- initial_split(data = creditos,',
     '                                prop = 0.75,',
     '                                strata = aprobado)',
     'creditos_entrenamiento <- creditos_split %>% training()',
     'creditos_prueba        <- creditos_split %>% testing()'],
    "- initial_split() define el corte (aquí 75% / 25%). strata = aprobado "
    "estratifica: ambas partes mantienen la misma mezcla de sí/no.\n"
    "- training() y testing() extraen cada parte. La prueba se 'guarda en una "
    "caja fuerte': solo se usa al final.\n"
    "- set.seed() hace reproducible el corte aleatorio.", n, FT); n += 1

slide_funcion(prs, "recipe()",
    "Declara la receta de preprocesamiento: la fórmula y la secuencia de "
    "pasos.",
    ['receta_creditos <-',
     '  recipe(aprobado ~ ., data = creditos_entrenamiento) %>%',
     '  step_impute_median(all_numeric_predictors()) %>%',
     '  step_nzv(all_predictors()) %>%',
     '  step_corr(all_numeric_predictors(), threshold = 0.7) %>%',
     '  step_normalize(all_numeric_predictors()) %>%',
     '  step_zv(all_predictors())'],
    "- recipe(aprobado ~ .) dice 'predice aprobado usando todas las demás "
    "variables'.\n"
    "- Encadenamos pasos step_*() con %>%. El ORDEN importa: imputar primero, "
    "porque los pasos siguientes no toleran NAs.\n"
    "- La receta es solo una RECETA: aún no toca los datos; se aplica dentro "
    "del workflow.", n, FT, code_size=12); n += 1

slide_funcion(prs, "step_impute_median()",
    "Rellena los valores faltantes (NAs) de las variables numéricas con su "
    "mediana.",
    ['step_impute_median(all_numeric_predictors())'],
    "- Sustituye cada NA por la mediana de esa columna, calculada SOLO con el "
    "entrenamiento (evita filtrar información de la prueba).\n"
    "- La mediana es robusta a valores extremos (p. ej. ingresos muy altos).\n"
    "- all_numeric_predictors() es un selector: aplica el paso a todas las "
    "columnas numéricas que sean predictores.", n, FT); n += 1

slide_funcion(prs, "step_corr()",
    "Elimina predictores numéricos redundantes por estar muy correlacionados "
    "entre sí.",
    ['step_corr(all_numeric_predictors(), threshold = 0.7)'],
    "- Si dos variables miden casi lo mismo (p. ej. monto y pago mensual), en "
    "KNN esa información pesaría DOBLE en la distancia.\n"
    "- threshold = 0.7: descarta variables cuya correlación supere 0.7, "
    "dejando una representante del grupo.\n"
    "- Reduce colinealidad y dimensiones sin perder señal.", n, FT); n += 1

slide_funcion(prs, "step_normalize()",
    "Estandariza cada predictor a media 0 y desviación 1. Es el paso CRÍTICO "
    "para KNN.",
    ['step_normalize(all_numeric_predictors())'],
    "- KNN mide distancias. Sin normalizar, una variable en miles de pesos "
    "(monto) aplastaría a otra de conteo pequeño (núm. de créditos).\n"
    "- Tras normalizar, todas las variables contribuyen en la misma escala a "
    "la distancia.\n"
    "- Igual que la imputación, los parámetros (media y sd) se estiman con el "
    "entrenamiento.", n, FT); n += 1

slide_funcion(prs, "step_nzv()  /  step_zv()",
    "Quitan predictores sin información: varianza casi nula (nzv) o "
    "exactamente cero (zv).",
    ['step_nzv(all_predictors()) %>%',
     '# ... otros pasos ...',
     'step_zv(all_predictors())'],
    "- step_nzv() elimina variables casi constantes (near-zero variance): "
    "casi no varían, así que no ayudan a discriminar.\n"
    "- step_zv() elimina las que quedaron con varianza CERO tras los pasos "
    "anteriores (una limpieza de seguridad al final).\n"
    "- Menos columnas inútiles = distancias más limpias y modelo más estable.",
    n, FT); n += 1

slide_funcion(prs, "nearest_neighbor()",
    "Especifica el modelo KNN: cuántos vecinos, con qué motor y en qué modo.",
    ['modelo_knn_tune <-',
     '  nearest_neighbor(neighbors = tune(),',
     '                   weight_func = "rectangular") %>%',
     '  set_engine("kknn") %>%',
     '  set_mode("classification")'],
    "- nearest_neighbor() declara el modelo. neighbors = el número de vecinos "
    "k; tune() significa 'a determinar por validación cruzada'.\n"
    "- weight_func = \"rectangular\": voto mayoritario no ponderado (KNN "
    "clásico), para ver el equilibrio sesgo-varianza.\n"
    "- set_engine(\"kknn\") elige el paquete que ejecuta el modelo; "
    "set_mode(\"classification\") fija que es clasificación.", n, FT); n += 1

slide_funcion(prs, "workflow()",
    "Empaqueta la receta y el modelo en un solo objeto, robusto y "
    "reutilizable.",
    ['workflow_knn_tune <- workflow() %>%',
     '  add_recipe(receta_creditos) %>%',
     '  add_model(modelo_knn_tune)'],
    "- workflow() crea el contenedor. add_recipe() le pega el "
    "preprocesamiento y add_model() el modelo.\n"
    "- Ventaja clave: al ajustar, hace internamente prep + bake + fit; al "
    "predecir, aplica el MISMO preprocesamiento a los datos nuevos.\n"
    "- Evita el error común de olvidar transformar la base de prueba.",
    n, FT); n += 1

slide_funcion(prs, "fit()  /  predict()",
    "Entrena el workflow sobre el entrenamiento y predice sobre datos nuevos.",
    ['workflow_knn_fijo_fit <- workflow_knn_fijo %>%',
     '  fit(data = creditos_entrenamiento)',
     '',
     'predict(workflow_knn_fijo_fit, creditos_prueba,',
     '        type = "class")   # clase predicha',
     'predict(workflow_knn_fijo_fit, creditos_prueba,',
     '        type = "prob")    # probabilidades'],
    "- fit() ajusta todo el workflow (receta + modelo) con los datos de "
    "entrenamiento.\n"
    "- predict(type = \"class\") devuelve la clase; type = \"prob\" devuelve "
    "las probabilidades de cada clase (útiles para ROC/AUC).\n"
    "- No hace falta 'hornear' la prueba a mano: el workflow lo hace.",
    n, FT); n += 1

slide_funcion(prs, "vfold_cv()",
    "Crea los pliegues (folds) de validación cruzada sobre el entrenamiento.",
    ['set.seed(2026)',
     'folds_cv <- vfold_cv(data = creditos_entrenamiento,',
     '                     v = 5,',
     '                     strata = aprobado)'],
    "- Parte el entrenamiento en v = 5 porciones. En cada ronda usa 4 para "
    "entrenar y 1 para validar; rota hasta que cada fold valida una vez.\n"
    "- Sirve para estimar el desempeño SIN tocar la prueba.\n"
    "- strata = aprobado mantiene la proporción de clases en cada fold.",
    n, FT); n += 1

slide_funcion(prs, "grid_regular() + tune()",
    "Define la lista de valores candidatos del hiperparámetro a probar.",
    ['# en el modelo: neighbors = tune() marca el parámetro a buscar',
     'grilla_k <- grid_regular(neighbors(range = c(1, 101)),',
     '                         levels = 12)'],
    "- tune() (en el modelo) es un marcador: 'este valor no lo fijo yo, se "
    "elige con datos'.\n"
    "- neighbors(range = c(1, 101)) describe el rango razonable de k.\n"
    "- grid_regular(..., levels = 12) genera 12 valores uniformes dentro de "
    "ese rango: la grilla que el tuning recorrerá.", n, FT); n += 1

slide_funcion(prs, "tune_grid()",
    "Corre la validación cruzada para cada valor de k y guarda sus métricas.",
    ['resultados_tuning <- workflow_knn_tune %>%',
     '  tune_grid(resamples = folds_cv,',
     '            grid = grilla_k,',
     '            metrics = metricas_tuning)'],
    "- Para CADA k de la grilla, ajusta el workflow en los 5 folds y promedia "
    "las métricas. Es el corazón del tuning.\n"
    "- resamples = los folds; grid = los k a probar; metrics = qué medir "
    "(definido con metric_set).\n"
    "- Devuelve una tabla de resultados por k, lista para comparar.",
    n, FT); n += 1

slide_funcion(prs, "collect_metrics() + select_best()",
    "Resume las métricas por k y elige el mejor según el criterio que pidamos.",
    ['collect_metrics(resultados_tuning)',
     '',
     'mejor_k <- resultados_tuning %>%',
     '  select_best(metric = "roc_auc")'],
    "- collect_metrics() junta y promedia las métricas de todos los folds, "
    "una fila por k: útil para graficar la curva AUC vs k.\n"
    "- select_best(metric = \"roc_auc\") devuelve el k con mejor AUC "
    "promedio.\n"
    "- Aquí el mejor k cae DENTRO de la grilla (equilibrio sesgo-varianza), "
    "no en sus extremos.", n, FT); n += 1

slide_funcion(prs, "finalize_workflow() + last_fit()",
    "Inyecta el k ganador, reentrena con todo el entrenamiento y evalúa en la "
    "prueba.",
    ['workflow_knn_final <- workflow_knn_tune %>%',
     '  finalize_workflow(mejor_k)',
     '',
     'ajuste_final <- workflow_knn_final %>%',
     '  last_fit(split = creditos_split,',
     '           metrics = metricas_tuning)'],
    "- finalize_workflow(mejor_k) fija el hiperparámetro tune() con el valor "
    "elegido.\n"
    "- last_fit() hace, en un solo paso: reentrena con TODO el entrenamiento y "
    "evalúa en la prueba reservada.\n"
    "- Es la estimación honesta del desempeño en datos nunca vistos.",
    n, FT); n += 1

slide_funcion(prs, "metric_set() + roc_auc() + conf_mat()",
    "Definen y calculan las métricas de evaluación de la clasificación.",
    ['metricas_tuning <- metric_set(roc_auc, accuracy,',
     '                              sensitivity, yardstick::spec)',
     '',
     'roc_auc(predicciones_finales, truth = aprobado, .pred_no)',
     'conf_mat(predicciones_finales, truth = aprobado,',
     '         estimate = .pred_class)'],
    "- metric_set() agrupa varias métricas en un solo evaluador reutilizable.\n"
    "- roc_auc() resume, con un número (0.5 = azar, 1 = perfecto), qué tan "
    "bien el modelo ordena los casos por probabilidad.\n"
    "- conf_mat() arma la matriz de confusión: aciertos y errores por clase.",
    n, FT); n += 1

slide_conclusiones(prs, "Resumen: el mismo flujo para cualquier modelo",
    "- recipe() + step_*() preparan los datos; el orden de los pasos importa.\n"
    "- workflow() une receta y modelo, y evita errores al predecir.\n"
    "- vfold_cv() + tune_grid() eligen hiperparámetros SIN tocar la prueba.\n"
    "- select_best() + finalize_workflow() + last_fit() cierran el ciclo con "
    "una evaluación honesta.\n"
    "- Cambiar de modelo (de KNN a otro) solo cambia nearest_neighbor() por "
    "otra especificación: el resto del flujo es idéntico.", n, FT); n += 1

slide_cierre(prs)

prs.save(OUT)
print("Guardado:", OUT, "| slides:", len(prs.slides._sldIdLst))
