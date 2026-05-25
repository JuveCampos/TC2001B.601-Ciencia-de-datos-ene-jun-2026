"""Sesión 19 - Funciones para clases desbalanceadas (themis + métricas).
Fragmentos del ejercicio 1 (clientes prometedores en un casino en línea)."""
from estilo_tec import (nueva_presentacion, slide_portada, slide_intro,
                        slide_funcion, slide_conclusiones, slide_cierre)

FT = "Sesión 19 - Clases desbalanceadas"
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "sesion_19_funciones_desbalanceadas.pptx")

prs = nueva_presentacion()
n = 1

slide_portada(prs,
    "Sesión 19: clases\ndesbalanceadas",
    "Rebalancear y medir bien cuando la clase positiva es rara",
    "TC2001B.601 - Ciencia de datos para la toma de decisiones I\n"
    "Ejemplos tomados del ejercicio: clientes prometedores en un casino")

slide_intro(prs, "El problema: una clase muy rara (~9 % \"sí\")",
    "Una plataforma de casino en línea quiere detectar a sus clientes "
    "prometedores para campañas de retención, pero solo ~9 % lo son. Con una "
    "clase tan rara, la accuracy engaña y hay que rebalancear el entrenamiento. "
    "Aquí explicamos cada función del flujo con fragmentos reales del ejercicio.",
    "1.  read_csv() + factor(levels=...)  -  fijar la clase rara como evento\n"
    "2.  initial_split() / vfold_cv() (strata)  -  partir conservando ~90/10\n"
    "3.  recipe() + step_dummy() + step_normalize()  -  preparar para SMOTE\n"
    "4.  step_downsample() / step_upsample() / step_smote()  -  rebalancear\n"
    "5.  workflow() + metric_set()  -  una receta por técnica; métricas justas\n"
    "6.  fit_resamples() + collect_metrics()  -  comparar técnicas\n"
    "7.  last_fit() + conf_mat() + pr_curve()  -  evaluar al ganador",
    n, FT); n += 1

slide_funcion(prs, "factor(levels = ...)",
    "Fija \"si\" (la clase rara) como PRIMER nivel: yardstick lo toma como el "
    "evento positivo.",
    ['clientes <- read_csv("datos.csv") %>%',
     '  select(-id_cliente) %>%   # no es predictor',
     '  mutate(prometedor = factor(prometedor,',
     '                             levels = c("si", "no")))',
     '',
     'levels(clientes$prometedor)   # "si" debe ir primero'],
    "- read_csv() (de readr) lee el CSV como tibble; quitamos el id porque no es "
    "predictor.\n"
    "- factor() es obligatorio: conf_mat, roc_curve y metric_set fallan si el "
    "objetivo es texto.\n"
    "- El ORDEN de levels es lo distintivo: yardstick toma el primer nivel como "
    "evento. Por defecto sería alfabético (\"no\" primero) y recall, precision, "
    "f_meas y pr_auc se calcularían sobre la clase mayoritaria, sin valor.\n"
    "- Al poner \"si\" primero, esas métricas miden lo que el negocio busca.",
    n, FT); n += 1

slide_funcion(prs, "Por qué accuracy engaña",
    "Con desbalance, un modelo \"tonto\" que siempre dice \"no\" tiene accuracy "
    "alta y es inútil.",
    ['clientes %>%',
     '  group_by(prometedor) %>%',
     '  count() %>%',
     '  ungroup() %>%',
     '  mutate(porcentaje = 100 * (n / sum(n)))',
     '',
     'prop.table(table(clientes$prometedor))'],
    "- La clase \"no\" es ~91 % de los datos. Un modelo que SIEMPRE prediga "
    "\"no\" acierta ~91 % de las veces: accuracy alta, recall = 0.\n"
    "- Ese modelo no detecta ni un solo cliente prometedor; para el negocio no "
    "sirve, aunque su accuracy parezca buena.\n"
    "- Por eso medimos recall (cobertura de la clase rara), precision (calidad "
    "de las alertas), f_meas (su balance) y, sobre todo, pr_auc.",
    n, FT); n += 1

slide_funcion(prs, "initial_split() (strata)",
    "Parte en entrenamiento y prueba conservando la proporción ~90/10 de "
    "clases.",
    ['set.seed(123)',
     'clientes_split <- initial_split(data = clientes,',
     '                                prop = 0.75,',
     '                                strata = prometedor)',
     '',
     'clientes_entrenamiento <- clientes_split %>% training()',
     'clientes_prueba        <- clientes_split %>% testing()'],
    "- strata = prometedor estratifica: ambas partes conservan la mezcla ~90/10. "
    "Sin estratificar, con una clase tan rara el azar podría dejar muy pocos (o "
    "ningún) caso \"si\" en algún conjunto.\n"
    "- training() y testing() extraen cada parte; la prueba se reserva para el "
    "final.\n"
    "- set.seed() hace reproducible el corte aleatorio.", n, FT); n += 1

slide_funcion(prs, "vfold_cv() (strata)",
    "Crea los 5 pliegues de validación cruzada, también estratificados, solo "
    "sobre el entrenamiento.",
    ['set.seed(123)',
     'folds_cv <- vfold_cv(data = clientes_entrenamiento,',
     '                     v = 5,',
     '                     strata = prometedor)'],
    "- Parte el entrenamiento en v = 5 porciones; en cada ronda entrena con 4 y "
    "valida con 1, hasta que cada fold valida una vez.\n"
    "- strata = prometedor mantiene la proporción ~90/10 dentro de cada fold: "
    "evita que algún fold se quede casi sin casos \"si\".\n"
    "- Sirve para estimar el desempeño SIN tocar la base de prueba.",
    n, FT); n += 1

slide_funcion(prs, "recipe() + step_dummy() + step_normalize()",
    "Receta base: imputa, convierte categóricas a dummies y estandariza. El "
    "orden está pensado para SMOTE.",
    ['receta_base <-',
     '  recipe(prometedor ~ ., data = clientes_entrenamiento) %>%',
     '  step_impute_median(all_numeric_predictors()) %>%',
     '  step_dummy(all_nominal_predictors()) %>%',
     '  step_normalize(all_numeric_predictors())'],
    "- step_impute_median() va PRIMERO: ni el balanceo ni step_normalize toleran "
    "NAs.\n"
    "- step_dummy() convierte las categóricas en columnas 0/1. Es distintivo "
    "ponerlo ANTES de themis: step_smote() solo opera sobre predictores "
    "NUMÉRICOS.\n"
    "- step_normalize() (z-score) deja todo en la misma escala, necesario para "
    "que las distancias entre vecinos de SMOTE sean comparables.\n"
    "- La receta es solo una receta: se aplica dentro del workflow.",
    n, FT, code_size=11); n += 1

slide_funcion(prs, "step_downsample()",
    "Submuestrea la clase mayoritaria \"no\" hasta igualar a la minoría \"si\". "
    "Función del paquete themis.",
    ['library(themis)',
     '',
     'receta_downsample <- receta_base %>%',
     '  step_downsample(prometedor)'],
    "- Descarta observaciones de la mayoría \"no\" al azar hasta que ambas "
    "clases queden equilibradas.\n"
    "- Es la técnica más rápida y simple, pero tira información: pierde casos "
    "reales de la clase mayoritaria.\n"
    "- Solo se aplica al conjunto de entrenamiento de cada fold; nunca a la "
    "evaluación ni a la prueba.", n, FT); n += 1

slide_funcion(prs, "step_upsample()",
    "Replica observaciones de la minoría \"si\" hasta igualar a la mayoría. "
    "Función del paquete themis.",
    ['receta_upsample <- receta_base %>%',
     '  step_upsample(prometedor)'],
    "- Copia (repite tal cual) observaciones de la clase rara \"si\" hasta "
    "equilibrar las clases.\n"
    "- No inventa datos nuevos: son repeticiones exactas, así que no agrega "
    "variedad y puede sobreajustar a esos casos.\n"
    "- Ventaja sobre downsample: no descarta información de la mayoría.\n"
    "- También se aplica solo al entrenamiento de cada fold.", n, FT); n += 1

slide_funcion(prs, "step_smote()",
    "Crea ejemplos SINTÉTICOS de la minoría interpolando entre cada caso raro y "
    "sus vecinos. Paquete themis.",
    ['receta_smote <- receta_base %>%',
     '  step_smote(prometedor)'],
    "- A diferencia de upsample, no copia: genera puntos NUEVOS sobre la línea "
    "que une cada observación \"si\" con sus vecinos más cercanos.\n"
    "- Aporta variedad en lugar de copias exactas, lo que suele ayudar al "
    "modelo a generalizar mejor sobre la clase rara.\n"
    "- Por usar distancias entre vecinos exige predictores numéricos: por eso "
    "step_dummy() y step_normalize() van antes.\n"
    "- Igual que down/up: solo se aplica al entrenamiento, jamás a la "
    "evaluación.", n, FT); n += 1

slide_funcion(prs, "workflow() (uno por técnica)",
    "Empaqueta cada receta con el MISMO modelo, para que la comparación entre "
    "técnicas sea justa.",
    ['modelo_logistico <- logistic_reg() %>%',
     '  set_engine("glm") %>%',
     '  set_mode("classification")',
     '',
     'workflow_smote <- workflow() %>%',
     '  add_recipe(receta_smote) %>%',
     '  add_model(modelo_logistico)'],
    "- Fijamos un único clasificador (regresión logística) para todas las "
    "técnicas: así lo ÚNICO que cambia entre workflows es el balanceo.\n"
    "- Hay un workflow por receta: sin balanceo, downsample, upsample y smote.\n"
    "- add_recipe() pega el preprocesamiento y add_model() el modelo; el "
    "workflow aplica el mismo preprocesamiento al predecir.", n, FT); n += 1

slide_funcion(prs, "metric_set()",
    "Agrupa las métricas adecuadas al desbalance; accuracy entra solo para "
    "contrastar, no para decidir.",
    ['metricas_desbalance <- metric_set(recall, precision,',
     '                                  f_meas, roc_auc,',
     '                                  pr_auc, accuracy)'],
    "- recall: de los clientes prometedores reales, qué fracción detecta el "
    "modelo (cobertura de la clase rara).\n"
    "- precision: de las alertas que da, qué fracción es correcta (calidad).\n"
    "- f_meas: media armónica de precision y recall (su balance).\n"
    "- roc_auc y pr_auc usan la probabilidad predicha, no la clase. pr_auc "
    "(área precision-recall) enfatiza la clase rara y es la métrica que "
    "recomendamos vigilar con desbalance.", n, FT); n += 1

slide_funcion(prs, "fit_resamples()",
    "Entrena y evalúa cada workflow en los 5 folds; el balanceo se aplica solo "
    "dentro de cada fold.",
    ['control_cv <- control_resamples(save_pred = TRUE)',
     '',
     'set.seed(123)',
     'res_smote <- fit_resamples(workflow_smote,',
     '                           resamples = folds_cv,',
     '                           metrics = metricas_desbalance,',
     '                           control = control_cv)'],
    "- fit_resamples() ajusta y valida el workflow en cada uno de los 5 folds y "
    "promedia las métricas; lo corremos para las cuatro técnicas.\n"
    "- El rebalanceo (down/up/smote) ocurre dentro de cada fold, solo sobre su "
    "porción de entrenamiento; la evaluación usa la distribución real.\n"
    "- control_resamples(save_pred = TRUE) guarda las predicciones por si las "
    "necesitamos después.", n, FT); n += 1

slide_funcion(prs, "collect_metrics()",
    "Reúne las métricas promedio de cada técnica en una sola tabla comparable.",
    ['lista_resultados <- list(sin_balanceo = res_sin_balanceo,',
     '                         downsample = res_downsample,',
     '                         upsample = res_upsample,',
     '                         smote = res_smote)',
     '',
     'metricas_por_tecnica <- lapply(names(lista_resultados),',
     '  function(nombre) {',
     '    collect_metrics(lista_resultados[[nombre]]) %>%',
     '      mutate(técnica = nombre)',
     '  })'],
    "- collect_metrics() junta y promedia (sobre los 5 folds) las métricas de un "
    "objeto de resampling.\n"
    "- Usamos lapply para extraer y etiquetar las métricas de las cuatro "
    "técnicas; bind_rows() + pivot_wider() arman la tabla final, ordenada por "
    "pr_auc descendente.", n, FT, code_size=11); n += 1

slide_funcion(prs, "Lectura de la tabla comparativa",
    "Los números muestran por qué accuracy engaña: la línea base la maximiza "
    "pero casi no detecta la clase rara.",
    ['comparacion_tecnicas <- bind_rows(metricas_por_tecnica) %>%',
     '  select(técnica, .metric, mean) %>%',
     '  pivot_wider(names_from = .metric,',
     '              values_from = mean) %>%',
     '  arrange(desc(pr_auc))'],
    "- sin_balanceo: accuracy MÁS alta (~0.91) pero recall MÁS bajo (~0.11): "
    "detecta apenas uno de cada diez prometedores.\n"
    "- down/up/smote suben el recall a ~0.62-0.66 (detectan ~6 de cada 10) a "
    "costa de bajar la precision; su f_meas (~0.30) triplica al de la base.\n"
    "- Los pr_auc quedan casi empatados (~0.30-0.32): elegimos el de mayor "
    "pr_auc de forma programática, sin cablear una técnica a mano.",
    n, FT); n += 1

slide_funcion(prs, "last_fit()",
    "Reentrena el workflow ganador con TODO el entrenamiento y lo evalúa una "
    "sola vez sobre la prueba.",
    ['nombre_ganador <- comparacion_tecnicas %>%',
     '  slice_max(pr_auc, n = 1) %>%',
     '  pull(técnica)',
     '',
     'workflow_ganador <- workflows_disponibles[[nombre_ganador]]',
     '',
     'set.seed(123)',
     'ajuste_final <- last_fit(workflow_ganador,',
     '                         split = clientes_split,',
     '                         metrics = metricas_desbalance)'],
    "- slice_max(pr_auc) + pull() eligen el nombre de la técnica ganadora desde "
    "la tabla, sin fijarla a mano.\n"
    "- last_fit() reentrena con todo el entrenamiento y evalúa una vez en la "
    "prueba reservada, que NUNCA fue rebalanceada: así medimos sobre la "
    "distribución real que veremos en producción.", n, FT, code_size=11); n += 1

slide_funcion(prs, "conf_mat() + pr_curve() + roc_curve()",
    "Sobre las predicciones de la prueba: matriz de confusión y curvas que "
    "miran la clase positiva.",
    ['predicciones_finales <- collect_predictions(ajuste_final)',
     '',
     'conf_mat(predicciones_finales, truth = prometedor,',
     '         estimate = .pred_class)',
     '',
     'predicciones_finales %>%',
     '  pr_curve(truth = prometedor, .pred_si) %>%',
     '  autoplot()'],
    "- collect_predictions() saca las predicciones (clase y probabilidades) "
    "sobre la prueba.\n"
    "- conf_mat() arma la matriz de confusión: aciertos y errores por clase.\n"
    "- pr_curve() y roc_curve() reciben .pred_si (la probabilidad de \"si\", el "
    "primer nivel). La curva PR es más informativa que la ROC cuando la clase "
    "positiva es muy rara, porque se enfoca en esa clase.", n, FT,
    code_size=11); n += 1

slide_conclusiones(prs, "Resumen: rebalancear y medir bien la clase rara",
    "- Fijar \"si\" como PRIMER nivel del factor hace que recall, precision, "
    "f_meas y pr_auc midan la clase que importa.\n"
    "- Con desbalance la accuracy engaña: vigila recall, f_meas y sobre todo "
    "pr_auc.\n"
    "- step_dummy() y step_normalize() van ANTES de themis, porque step_smote() "
    "exige predictores numéricos.\n"
    "- down/up/smote solo se aplican al entrenamiento; se evalúa sobre la "
    "distribución real.\n"
    "- El objetivo no es subir la accuracy (puede bajar), sino DETECTAR a los "
    "clientes prometedores sin disparar demasiadas falsas alarmas.",
    n, FT); n += 1

slide_cierre(prs)

prs.save(OUT)
print("Guardado:", OUT, "| slides:", len(prs.slides._sldIdLst))
