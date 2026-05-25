"""Sesión 20 - Otros modelos y ensambles.
Funciones de R del ejercicio de clasificación (aprobación de crédito):
árboles, random forest, XGBoost, regresión regularizada y ENSAMBLE por
stacking. Un par de fragmentos del ejercicio de clustering (DBSCAN)."""
from estilo_tec import (nueva_presentacion, slide_portada, slide_intro,
                        slide_funcion, slide_conclusiones, slide_cierre)

FT = "Sesión 20 - Otros modelos y ensambles"
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "sesion_20_funciones_otros_modelos.pptx")

prs = nueva_presentacion()
n = 1

slide_portada(prs,
    "Sesión 20: otros modelos\ny ensambles",
    "Árboles, random forest, XGBoost, regularización y stacking",
    "TC2001B.601 - Ciencia de datos para la toma de decisiones I\n"
    "Ejemplos tomados del ejercicio: aprobación de crédito")

slide_intro(prs, "Más allá de un solo modelo: comparar y combinar",
    "Ya no usamos un único clasificador. En esta sesión entrenamos cuatro "
    "modelos distintos y, en vez de quedarnos con un ganador, los COMBINAMOS "
    "en un ensamble por stacking. Lo nuevo de la sesión son las funciones del "
    "paquete stacks.",
    "1.  read_csv() + factor()  -  cargar y dejar lista la objetivo\n"
    "2.  initial_split() + vfold_cv()  -  partir y armar los folds\n"
    "3.  recipe() + step_*()  -  una sola receta compartida\n"
    "4.  decision_tree()  -  árbol de decisión (rpart)\n"
    "5.  rand_forest()  -  random forest, bagging (ranger)\n"
    "6.  boost_tree()  -  XGBoost, boosting (xgboost)\n"
    "7.  logistic_reg(penalty, mixture)  -  regularización (glmnet)\n"
    "8.  tune_grid(control = control_stack_grid())  -  guardar predicciones\n"
    "9.  stacks() + add_candidates() + blend_predictions() + fit_members()\n"
    "10. predict() + roc_auc()  -  comparar stack vs individuales",
    n, FT); n += 1

slide_funcion(prs, "read_csv() + factor()",
    "Carga el CSV, quita el identificador y vuelve factor la variable "
    "objetivo.",
    ['credito <- read_csv("datos.csv") %>%',
     '  select(-id_solicitud) %>%',
     '  mutate(aprobado = factor(aprobado))'],
    "- read_csv() (de readr) lee el archivo como tibble e infiere los tipos "
    "de columna.\n"
    "- select(-id_solicitud) descarta el identificador: no es predictor.\n"
    "- factor(aprobado): parsnip y yardstick exigen que la objetivo de "
    "clasificación sea factor. Las clases están casi balanceadas (~52/48).",
    n, FT); n += 1

slide_funcion(prs, "initial_split() + vfold_cv()",
    "Reservamos la prueba y armamos 5 folds de validación cruzada sobre el "
    "entrenamiento (visto en la Sesión 16).",
    ['set.seed(2020)',
     'credito_split <- initial_split(credito, prop = 0.75,',
     '                               strata = aprobado)',
     'credito_entrenamiento <- credito_split %>% training()',
     'credito_prueba        <- credito_split %>% testing()',
     '',
     'folds_cv <- vfold_cv(credito_entrenamiento, v = 5,',
     '                     strata = aprobado)'],
    "- initial_split(prop = 0.75, strata = aprobado) corta 75/25 manteniendo "
    "la mezcla de clases; la prueba queda guardada para el final.\n"
    "- vfold_cv(v = 5) parte el entrenamiento en 5 porciones. Estos MISMOS "
    "folds sirven para tunear y, después, para que el stacking aprenda.\n"
    "- Es el mismo flujo de siempre; aquí lo reusan los cuatro modelos.",
    n, FT, code_size=12); n += 1

slide_funcion(prs, "recipe() + step_*()",
    "Una sola receta de preprocesamiento, compartida por los cuatro modelos.",
    ['receta_credito <-',
     '  recipe(aprobado ~ ., data = credito_entrenamiento) %>%',
     '  step_impute_median(all_numeric_predictors()) %>%',
     '  step_nzv(all_predictors()) %>%',
     '  step_corr(all_numeric_predictors(), threshold = 0.7) %>%',
     '  step_normalize(all_numeric_predictors()) %>%',
     '  step_zv(all_predictors())'],
    "- Imputa NAs con la mediana, quita predictores casi constantes (nzv) y "
    "redundantes (corr), estandariza y limpia varianza cero.\n"
    "- step_normalize() es CRITICO para glmnet (la penalización depende de la "
    "escala) e inocuo para árboles y ensambles.\n"
    "- Una sola receta hace que los cuatro modelos sean comparables y que el "
    "stacking opere sobre la misma representación de los datos.",
    n, FT, code_size=12); n += 1

slide_funcion(prs, "decision_tree()",
    "Árbol de decisión: parte el espacio con reglas tipo 'si ingreso > X y "
    "score > Y, entonces...'.",
    ['modelo_arbol <- decision_tree(',
     '    cost_complexity = tune(),',
     '    tree_depth = tune()',
     '  ) %>%',
     '  set_engine("rpart") %>%',
     '  set_mode("classification")'],
    "- Un solo árbol es MUY interpretable, pero inestable (alta varianza): "
    "cambia mucho con pequeñas variaciones de los datos.\n"
    "- cost_complexity (cp) penaliza árboles grandes (poda) y tree_depth "
    "limita la profundidad; ambos con tune() para buscarlos por CV.\n"
    "- set_engine(\"rpart\") elige el paquete que construye el árbol.",
    n, FT); n += 1

slide_funcion(prs, "rand_forest()",
    "Random forest: un ENSAMBLE por BAGGING. Muchos árboles que votan; el "
    "promedio reduce la varianza.",
    ['modelo_rf <- rand_forest(',
     '    mtry = tune(),',
     '    min_n = tune(),',
     '    trees = 500',
     '  ) %>%',
     '  set_engine("ranger", importance = "impurity") %>%',
     '  set_mode("classification")'],
    "- Bagging = 'bootstrap aggregating': cada árbol se entrena con una "
    "muestra bootstrap y un subconjunto aleatorio de predictores por corte.\n"
    "- Promediar muchos árboles ruidosos pero poco sesgados REDUCE la varianza "
    "sin subir el sesgo. mtry = predictores por corte; min_n = obs. por nodo.\n"
    "- trees = 500 fijo; importance = \"impurity\" guarda la importancia de "
    "variables para inspeccionarla después.",
    n, FT); n += 1

slide_funcion(prs, "boost_tree()",
    "XGBoost: un ENSAMBLE por BOOSTING. Árboles en SECUENCIA, cada uno corrige "
    "los errores del anterior.",
    ['modelo_xgb <- boost_tree(',
     '    trees = 500,',
     '    tree_depth = tune(),',
     '    learn_rate = tune(),',
     '    loss_reduction = tune()',
     '  ) %>%',
     '  set_engine("xgboost") %>%',
     '  set_mode("classification")'],
    "- BAGGING (random forest): árboles en PARALELO; ataca la VARIANZA. "
    "BOOSTING (XGBoost): árboles en SECUENCIA; ataca el SESGO.\n"
    "- Cada árbol nuevo se enfoca en lo que el conjunto anterior falló; suele "
    "dar el mejor desempeño predictivo.\n"
    "- A cambio, más hiperparámetros y más riesgo de sobreajuste si no se "
    "regulariza.",
    n, FT, code_size=12); n += 1

slide_funcion(prs, "logistic_reg(penalty, mixture)",
    "Regresión logística regularizada: la de siempre, pero con una "
    "penalización que encoge los coeficientes.",
    ['modelo_glmnet <- logistic_reg(',
     '    penalty = tune(),',
     '    mixture = tune()',
     '  ) %>%',
     '  set_engine("glmnet") %>%',
     '  set_mode("classification")'],
    "- penalty (lambda) controla CUÁNTA penalización: más lambda, más encoge "
    "los coeficientes hacia cero.\n"
    "- mixture controla la MEZCLA: 1 = lasso (L1, puede llevar coeficientes a "
    "CERO y seleccionar variables); 0 = ridge (L2, encoge sin eliminar); "
    "intermedio = elastic net.\n"
    "- Tunear ambos deja que los datos decidan cuánto regularizar y de que "
    "tipo.",
    n, FT); n += 1

slide_funcion(prs, "tune_grid(control = control_stack_grid())",
    "Tunea cada modelo Y guarda las predicciones que el stacking necesitará "
    "después.",
    ['control_stack <- control_stack_grid()',
     '',
     'set.seed(2020)',
     'tuning_xgb <- workflow_xgb %>%',
     '  tune_grid(resamples = folds_cv,',
     '            grid = 6,',
     '            metrics = metricas_clasificacion,',
     '            control = control_stack)'],
    "- Lo DISTINTIVO de la sesión. tune_grid prueba 6 candidatos por modelo "
    "sobre los 5 folds, igual que siempre.\n"
    "- control = control_stack_grid() le pide que ADEMÁS guarde las "
    "predicciones out-of-fold de cada candidato.\n"
    "- Sin esas predicciones, stacks() no podría entrenar el meta-modelo. Se "
    "corre uno por cada modelo.",
    n, FT, code_size=12); n += 1

slide_funcion(prs, "stacks() + add_candidates()",
    "Crea el ensamble vacío y le agrega como candidatos los modelos ya "
    "tuneados.",
    ['set.seed(2020)',
     'stack_credito <- stacks() %>%',
     '  add_candidates(tuning_arbol) %>%',
     '  add_candidates(tuning_rf) %>%',
     '  add_candidates(tuning_xgb) %>%',
     '  add_candidates(tuning_glmnet)'],
    "- stacks() inicializa un ensamble vacio (un 'data stack').\n"
    "- add_candidates() junta los resultados de tuning de cada familia: cada "
    "candidato es un modelo concreto con sus hiperparámetros y sus "
    "predicciones out-of-fold.\n"
    "- Así reunimos modelos DIVERSOS (árbol, bagging, boosting, lineal); esa "
    "diversidad es justo lo que el ensamble aprovecha.",
    n, FT); n += 1

slide_funcion(prs, "blend_predictions()",
    "El meta-modelo aprende cómo COMBINAR a los candidatos: a quién le da peso "
    "y cuánto.",
    ['set.seed(2020)',
     'stack_credito_blend <- stack_credito %>%',
     '  blend_predictions()'],
    "- En vez de elegir un único ganador, un META-MODELO (un lasso) aprende "
    "que peso darle a la predicción de cada candidato.\n"
    "- Entrena sobre las predicciones out-of-fold que guardamos con "
    "control_stack_grid(); por eso eran necesarias.\n"
    "- El lasso lleva a CERO el peso de los candidatos que no aportan: decide "
    "quien entra al ensamble y quien queda fuera.",
    n, FT); n += 1

slide_funcion(prs, "fit_members()",
    "Reentrena, sobre todo el entrenamiento, solo los miembros que el "
    "meta-modelo decidió conservar.",
    ['stack_credito_fit <- stack_credito_blend %>%',
     '  fit_members()',
     '',
     '# imprime los pesos del ensamble final',
     'stack_credito_fit'],
    "- blend_predictions() decidió QUE candidatos quedan (peso distinto de "
    "cero) y con que peso relativo.\n"
    "- fit_members() reentrena esos miembros con TODO el entrenamiento, para "
    "que estén listos para predecir sobre datos nuevos.\n"
    "- El flujo completo de stacks es: stacks() -> add_candidates() -> "
    "blend_predictions() -> fit_members().",
    n, FT); n += 1

slide_funcion(prs, "predict() + roc_auc()",
    "Compara el AUC de prueba de cada modelo individual contra el del "
    "ensamble.",
    ['prob_stack <- predict(stack_credito_fit,',
     '                      new_data = credito_prueba,',
     '                      type = "prob")',
     '',
     'credito_prueba %>%',
     '  select(aprobado) %>%',
     '  bind_cols(prob_stack) %>%',
     '  roc_auc(truth = aprobado, .pred_no)'],
    "- predict(type = \"prob\") da las probabilidades del stack; el mismo "
    "patrón se aplica a cada modelo individual.\n"
    "- roc_auc resume con un número (0.5 = azar, 1 = perfecto) el poder de "
    "discriminación, sin depender de un umbral.\n"
    "- El STACK suele igualar o superar al mejor individual: ahí se ve el "
    "valor de combinar modelos diversos.",
    n, FT, code_size=12); n += 1

slide_funcion(prs, "dbscan() + kNNdistplot()",
    "Del ejercicio de CLUSTERING: un tercer tipo de modelo, agrupamiento por "
    "densidad (no supervisado).",
    ['# elegir eps: codo de la curva de distancias al k-ésimo vecino',
     'kNNdistplot(matriz_norm, k = min_pts)',
     'abline(h = 1.0, lty = 2, col = "red")',
     '',
     'set.seed(2020)',
     'modelo_dbscan <- dbscan(matriz_norm, eps = 1.0,',
     '                        minPts = 5)'],
    "- DBSCAN agrupa por DENSIDAD: no fija k, descubre tantos grupos como "
    "regiones densas haya y marca como RUIDO (cluster 0) los puntos aislados.\n"
    "- eps = radio de vecindad; minPts = mínimo de puntos en ese radio para "
    "considerar densa una zona.\n"
    "- kNNdistplot() ayuda a elegir eps: el 'codo' de esa curva (cerca de 1.0 "
    "aquí) separa puntos densos de aislados. Es el único que detecta outliers.",
    n, FT, code_size=12); n += 1

slide_conclusiones(prs, "Resumen: comparar modelos y combinarlos",
    "- decision_tree(): un árbol, interpretable pero inestable (alta "
    "varianza).\n"
    "- rand_forest() = BAGGING: muchos árboles en paralelo; reduce la "
    "VARIANZA. boost_tree() = BOOSTING: árboles en secuencia; reduce el SESGO.\n"
    "- logistic_reg(penalty, mixture) regulariza: lasso (L1) selecciona "
    "variables, ridge (L2) encoge, elastic net mezcla.\n"
    "- El STACKING (stacks -> add_candidates -> blend_predictions -> "
    "fit_members) deja que un meta-modelo combine a los demás; guarda las "
    "predicciones con control_stack_grid().\n"
    "- Decide siempre con la métrica adecuada (roc_auc), comparando en la "
    "PRUEBA. Ver prompt_estudiante.md para usar un LLM como copiloto al "
    "comparar modelos y justificar tu elección.", n, FT); n += 1

slide_cierre(prs)

prs.save(OUT)
print("Guardado:", OUT, "| slides:", len(prs.slides._sldIdLst))
