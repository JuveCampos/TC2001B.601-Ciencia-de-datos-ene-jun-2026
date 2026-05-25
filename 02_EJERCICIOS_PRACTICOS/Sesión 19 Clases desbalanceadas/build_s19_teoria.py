# -*- coding: utf-8 -*-
"""Construye la presentación TEÓRICA de la Sesión 19 (Clases desbalanceadas)
para audiencia de preparatoria. Estilo Tec 4:3.
Requiere las figuras de img_teoria/ (generar antes con figs_s19.py)."""
import os
from estilo_teoria import (
    nueva_presentacion, slide_portada, slide_agenda, slide_seccion,
    slide_concepto, slide_figura, slide_texto_figura, slide_pasos,
    slide_comparacion, slide_analogia, slide_alerta, slide_conclusiones,
    slide_cierre, slide_tabla,
    TEAL, PLUM, OCHRE, SOFT_TEAL, SOFT_OCHRE,
)
from estilo_teoria import (
    DARK_GREEN, DARK_RED, NAVY, SOFT_GREEN, SOFT_RED, LIGHT_BLUE,
)

BASE = os.path.dirname(os.path.abspath(__file__))
IMG  = os.path.join(BASE, "img_teoria")
OUT  = os.path.join(BASE, "sesion_19_teoria_desbalanceadas.pptx")
FT   = "Sesión 19 · Clases desbalanceadas"
img  = lambda n: os.path.join(IMG, n)

prs = nueva_presentacion()
n = 0


def sig():
    global n
    n += 1
    return n


# ============================================================
# 1. PORTADA
# ============================================================
slide_portada(
    prs,
    "Clases desbalanceadas\nCuando lo raro es lo que importa",
    "Sesión 19  ·  Detección de fraude y clientes de alto valor",
    "Tecnológico de Monterrey  ·  TC2001B.601 Ciencia de datos\n"
    "Prof. Jorge Juvenal Campos Ferreira")

# ============================================================
# 2. AGENDA
# ============================================================
slide_agenda(prs, "Lo que veremos hoy", [
    "El problema: cuando una clase es rarísima",
    "La trampa del porcentaje de aciertos",
    "La matriz de confusión revisitada",
    "Métricas correctas: precisión, recall y F1",
    "Curvas ROC y Precisión-Recall",
    "Solución I: remuestreo (over- y undersampling)",
    "Solución II: SMOTE, crear ejemplos sintéticos",
    "Solución III: umbral y pesos de clase",
], sig(), FT)

# ============================================================
# SECCIÓN 1  —  El problema: cuando una clase es rarísima
# ============================================================
slide_seccion(prs, 1,
              "El problema:\ncuando una clase\nes rarísima",
              "Fraude, enfermedades raras, clientes de alto valor")

slide_analogia(
    prs,
    "Una clase rarísima: el detector de metales",
    "Imagina que vas al aeropuerto y pasas por el detector de metales. "
    "La inmensa mayoría de las personas NO trae nada prohibido. "
    "El detector casi nunca suena.\n\n"
    "Si el detector estuviera roto y nunca sonara, 'acertaría' con casi "
    "todos los pasajeros. Pero su utilidad es detectar los pocos casos "
    "peligrosos, no confirmar que los demás son inocentes.",
    sig(), FT,
    color=OCHRE, fill=SOFT_OCHRE,
    etiqueta="Piénsalo así")

slide_concepto(
    prs,
    "¿Qué es el desbalance de clases?",
    "Un problema de clasificación tiene clases desbalanceadas cuando "
    "una de las categorías aparece MUCHO menos que la otra. "
    "Por ejemplo: fraude bancario, diagnóstico de enfermedades raras, "
    "detección de fallas en una fábrica o clientes de alto valor en "
    "una plataforma de casino en línea.",
    sig(), FT,
    en_cristiano="De cada 100 transacciones, solo 4 son fraude. "
                 "De cada 100 clientes del casino, solo 9 son 'prometedores'. "
                 "Lo raro es lo que nos interesa, y hay muy poco.")

slide_figura(
    prs, "El desbalance en números: 96 % normal vs 4 % fraude",
    img("01_barras_desbalance.png"), sig(), FT,
    caption="Dataset de fraude (ejercicio 2): 2,498 transacciones normales "
            "vs 102 fraudulentas.",
    nota="El casino tiene un desbalance parecido: 90 % clientes 'no "
         "prometedores' vs 10 % prometedores. El fraude es aún más extremo.")

slide_pasos(
    prs, "¿Por qué este problema es tan común?", [
        ("El fraude es raro por diseño",
         "Los bancos tienen mecanismos de prevención; solo pasa una fracción."),
        ("Las enfermedades graves son raras",
         "La mayoría de las personas sanas satura la base de datos."),
        ("Los clientes valiosos son escasos",
         "En un casino, el 10 % de clientes genera la mayor parte del ingreso."),
        ("Las fallas de fábrica son excepcionales",
         "Una máquina falla el 1 % del tiempo; el 99 % funciona bien."),
    ], sig(), FT,
    intro="El desbalance no es un accidente; refleja la realidad del problema.")

# ============================================================
# SECCIÓN 2  —  La trampa del accuracy
# ============================================================
slide_seccion(prs, 2,
              "La trampa del\nporcentaje de aciertos",
              "La paradoja del accuracy: un modelo flojo que parece excelente")

slide_analogia(
    prs,
    "La paradoja del examen más fácil del mundo",
    "Imagina un examen donde el 96 % de las preguntas tiene respuesta "
    "'Verdadero' y el resto 'Falso'.\n\n"
    "Si escribes 'Verdadero' en TODAS las respuestas sin leer nada, "
    "sacas 96 de 100. Parece un 10. "
    "Pero en realidad no aprendiste nada: fallaste todas las preguntas "
    "que realmente importaban (las falsas).",
    sig(), FT,
    color=TEAL, fill=SOFT_TEAL,
    etiqueta="La trampa")

slide_figura(
    prs,
    "Un modelo 'perezoso' consigue 96 % de aciertos: la paradoja",
    img("02_trampa_accuracy.png"), sig(), FT,
    caption="Un modelo que siempre dice 'no es fraude' acierta el 96 % "
            "del tiempo... y no detecta ningún fraude.",
    nota="Recall = 0: todos los fraudes pasan sin ser detectados. "
         "Este modelo es perfectamente inútil para el banco.")

slide_figura(
    prs,
    "Las métricas reales del modelo perezoso",
    img("11_comparacion_metricas.png"), sig(), FT,
    caption="Accuracy alta, pero Precisión = 0, Recall = 0, F1 = 0.",
    nota="La accuracy engaña porque la mayoría de los datos son de la clase "
         "dominante. Necesitamos métricas que midan solo la clase rara.")

slide_concepto(
    prs,
    "La enseñanza: accuracy no es suficiente con desbalance",
    "Cuando las clases están muy desbalanceadas, un modelo puede tener "
    "accuracy muy alta simplemente prediciendo SIEMPRE la clase mayoritaria. "
    "Por eso necesitamos otras métricas que midan qué tan bien detectamos "
    "la clase rara, que es la que nos interesa.",
    sig(), FT,
    en_cristiano="Calificar con accuracy en un problema desbalanceado es como "
                 "poner 10 a un alumno que copió solo las respuestas 'Verdadero'. "
                 "El número no dice nada útil.")

# ============================================================
# SECCIÓN 3  —  La matriz de confusión revisitada
# ============================================================
slide_seccion(prs, 3,
              "La matriz\nde confusión\nrevisitada",
              "Los dos tipos de error y cuál duele más aquí")

slide_figura(
    prs, "La matriz de confusión: 4 resultados posibles",
    img("03_matriz_confusion.png"), sig(), FT,
    caption="Las cuatro combinaciones de lo real vs. lo predicho por el modelo.",
    nota="VP = Verdadero Positivo (fraude detectado). "
         "FN = Falso Negativo (fraude que se escapó). "
         "FP = Falso Positivo (alarma falsa). "
         "VN = Verdadero Negativo (transacción legítima identificada como tal).")

slide_comparacion(
    prs, "Dos tipos de error, costos muy distintos",
    {
        "titulo": "Falso Positivo (FP): alarma falsa",
        "color": OCHRE, "fill": SOFT_OCHRE,
        "body": "El modelo dice FRAUDE pero la transacción era legítima.\n\n"
                "- El banco bloquea la tarjeta del cliente\n"
                "- El cliente se molesta, llama al banco\n"
                "- Costo: incomodidad, llamada de soporte\n\n"
                "Costo BAJO: resoluble en minutos.",
    },
    {
        "titulo": "Falso Negativo (FN): fraude que se escapa",
        "color": DARK_RED, "fill": SOFT_RED,
        "body": "El modelo dice LEGÍTIMO pero era un fraude.\n\n"
                "- El banco paga la transacción fraudulenta\n"
                "- El titular pierde su dinero\n"
                "- El banco tiene que reembolsar y absorber la pérdida\n\n"
                "Costo ALTO: pérdida económica real.",
    },
    sig(), FT,
    intro="No todos los errores cuestan igual. En detección de fraude, "
          "el falso negativo es mucho más grave.")

slide_concepto(
    prs,
    "El objetivo del modelo antifraude",
    "En un sistema antifraude, el objetivo NO es minimizar todos los errores "
    "por igual. Es MAXIMIZAR la detección de fraude (capturar la mayoría de "
    "los FN) aunque eso genere algunas alarmas falsas (FP) adicionales.\n\n"
    "Cuanto más desbalanceado el dataset, más crítico es el FN.",
    sig(), FT,
    en_cristiano="Prefiero que el detector de metales suene de más y revisar "
                 "algunas maletas inocentes, a que no suene cuando alguien trae "
                 "algo peligroso.")

# ============================================================
# SECCIÓN 4  —  Métricas correctas: precisión, recall y F1
# ============================================================
slide_seccion(prs, 4,
              "Métricas correctas:\nPrecisión,\nRecall y F1",
              "Qué mide cada una y cuándo importa")

slide_figura(
    prs,
    "Precisión y Recall: dos preguntas distintas sobre la clase rara",
    img("04_precision_recall.png"), sig(), FT,
    caption="Precisión: de los que MARQUÉ como fraude, ¿cuántos eran fraude? "
            "  |  Recall: de todos los fraudes reales, ¿cuántos ATRAPÉ?",
    nota="Las dos preguntas son complementarias y a menudo están en tensión: "
         "mejorar una puede empeorar la otra.")

slide_tabla(
    prs,
    "Resumen: precisión, recall, F1 y accuracy",
    ["Métrica", "Fórmula", "Pregunta que responde", "Cuándo usarla"],
    [
        ["Accuracy",   "( VP + VN ) / Total",
         "De todo, ¿cuántos aciertos hubo?",
         "Solo si las clases están BALANCEADAS"],
        ["Precisión",  "VP / ( VP + FP )",
         "De los que marqué como positivos, ¿cuántos lo eran?",
         "Si las falsas alarmas son costosas"],
        ["Recall",     "VP / ( VP + FN )",
         "De todos los positivos reales, ¿cuántos detecté?",
         "Si dejar pasar un positivo es muy costoso"],
        ["F1",         "2 * P * R / ( P + R )",
         "Equilibrio entre precisión y recall",
         "Con desbalance: combina ambas métricas"],
    ], sig(), FT,
    intro="Cada métrica responde una pregunta diferente. "
          "Con desbalance: priorizar recall, precisión y F1 sobre accuracy.")

slide_figura(
    prs, "F1: el balance entre precisión y recall",
    img("05_f1.png"), sig(), FT,
    caption="F1 es la media armónica: alta solo cuando AMBAS son altas.",
    nota="Si precisión = 1.0 y recall = 0.0, F1 = 0. "
         "No hay trampa: F1 exige un buen desempeño en los dos frentes.")

slide_analogia(
    prs,
    "Precisión y recall con un ejemplo cotidiano",
    "Imagina una red para pescar truchas en un lago con 10 truchas y "
    "100 carpas.\n\n"
    "- PRECISIÓN: de todos los peces que caen en la red, ¿qué fracción "
    "son truchas? (Si capturo 5 truchas y 20 carpas: precisión = 5/25 = 20 %)\n\n"
    "- RECALL: de las 10 truchas del lago, ¿cuántas caigo? "
    "(Si cazo 5 de 10: recall = 50 %)\n\n"
    "Quiero una red que capture MUCHAS truchas (recall alto) y que NO "
    "esté llena de carpas (precisión alta).",
    sig(), FT,
    color=TEAL, fill=SOFT_TEAL,
    etiqueta="Analogía de la red de pesca")

# ============================================================
# SECCIÓN 5  —  Curvas ROC y Precisión-Recall
# ============================================================
slide_seccion(prs, 5,
              "Curvas ROC\ny Precisión-Recall",
              "Por qué con desbalance la curva PR es más informativa")

slide_figura(
    prs,
    "ROC vs Precisión-Recall: dos curvas, dos historias",
    img("06_roc_vs_pr.png"), sig(), FT,
    caption="Con clases desbalanceadas, la curva ROC puede verse optimista; "
            "la curva Precisión-Recall es más honesta.",
    nota="La curva ROC compara tasa de verdaderos positivos vs falsos positivos. "
         "La curva PR compara precisión vs recall directamente sobre la clase rara.")

slide_comparacion(
    prs, "ROC vs Precisión-Recall: diferencias clave",
    {
        "titulo": "Curva ROC + AUC",
        "color": NAVY, "fill": LIGHT_BLUE,
        "body": "- Eje X: tasa de FP (de los no-fraude, ¿cuántos marcamos mal?)\n"
                "- Eje Y: recall (sensibilidad)\n"
                "- AUC entre 0.5 (azar) y 1 (perfecto)\n"
                "- Puede verse optimista cuando hay muy pocos positivos\n\n"
                "Útil para comparar modelos en general.",
    },
    {
        "titulo": "Curva Precisión-Recall + AP",
        "color": TEAL, "fill": SOFT_TEAL,
        "body": "- Eje X: recall\n"
                "- Eje Y: precisión\n"
                "- AP: área promedio bajo la curva PR\n"
                "- Muy sensible al desbalance: baja línea base\n\n"
                "Preferida cuando la clase positiva es muy rara "
                "(fraude, enfermedades, fallas).",
    },
    sig(), FT,
    intro="Con solo 4 % de fraudes, la curva PR revela problemas que "
          "la ROC esconde.")

# ============================================================
# SECCIÓN 6  —  Solución I: remuestreo
# ============================================================
slide_seccion(prs, 6,
              "Solución I:\nRemuestreo",
              "Oversampling y undersampling: rebalancear los datos")

slide_analogia(
    prs,
    "El problema de estudiar con un libro desbalanceado",
    "Imagina que estudias para un examen con un libro donde el 96 % "
    "de los ejercicios son sumas y solo el 4 % son divisiones. "
    "El modelo (tu cerebro) aprenderá a sumar muy bien y casi ignorará "
    "las divisiones.\n\n"
    "Solución: estudiar MÁS divisiones (oversampling) o MÁS POCAS sumas "
    "(undersampling) para que el cerebro les dé igual atención a ambas.",
    sig(), FT,
    color=PLUM, fill=SOFT_OCHRE,
    etiqueta="Analogía del libro de ejercicios")

slide_figura(
    prs, "Oversampling vs undersampling: antes y después",
    img("07_remuestreo.png"), sig(), FT,
    caption="Original: 2,498 normales vs 102 fraudes. "
            "Oversampling: ambas llegan a 2,498. "
            "Undersampling: ambas bajan a 102.",
    nota="El remuestreo SOLO se aplica al conjunto de entrenamiento, "
         "NUNCA a la prueba. La prueba debe reflejar la realidad.")

slide_comparacion(
    prs, "Oversampling vs undersampling: ventajas y costos",
    {
        "titulo": "Oversampling: ampliar la minoría",
        "color": DARK_GREEN, "fill": SOFT_GREEN,
        "body": "Ventajas:\n"
                "- No pierde información de la mayoría\n"
                "- El modelo ve más ejemplos de la clase rara\n\n"
                "Desventajas:\n"
                "- El simple oversampling REPITE exactamente los mismos "
                "ejemplos: el modelo puede memorizar\n"
                "- El conjunto crece; entrena más lento",
    },
    {
        "titulo": "Undersampling: recortar la mayoría",
        "color": OCHRE, "fill": SOFT_OCHRE,
        "body": "Ventajas:\n"
                "- Entrena rápido: conjunto más pequeño\n"
                "- Obliga al modelo a aprender de ambas clases\n\n"
                "Desventajas:\n"
                "- Descarta datos reales de la mayoría: pierde información\n"
                "- Si la mayoría tenía patrones importantes, se pierden",
    },
    sig(), FT,
    intro="Ninguno es perfecto; SMOTE ofrece una alternativa intermedia.")

# ============================================================
# SECCIÓN 7  —  Solución II: SMOTE
# ============================================================
slide_seccion(prs, 7,
              "Solución II:\nSMOTE",
              "Crear ejemplos sintéticos de la clase rara")

slide_concepto(
    prs,
    "SMOTE: Synthetic Minority Over-sampling TEchnique",
    "SMOTE no repite ejemplos existentes: CREA nuevos ejemplos de la clase "
    "minoritaria interpolando entre casos reales. Toma un punto de la clase "
    "rara y uno de sus vecinos más cercanos, y 'dibuja' un punto nuevo en "
    "algún lugar de la línea que los une.",
    sig(), FT,
    en_cristiano="Es como si, en lugar de fotocopiar los 102 casos de fraude "
                 "varias veces, los mezclaras entre sí para generar variantes "
                 "nuevas y plausibles. Más variedad, menos memorización.")

slide_figura(
    prs, "SMOTE: los puntos sintéticos nacen entre vecinos reales",
    img("08_smote.png"), sig(), FT,
    caption="Los puntos naranjas (SMOTE) se crean sobre la línea entre dos "
            "casos reales de la clase minoritaria (roja).",
    nota="Los sintéticos no son iguales a ningún caso real: son interpolaciones "
         "que dan más variedad al modelo para aprender la clase rara.")

slide_pasos(
    prs, "¿Cómo funciona SMOTE, paso a paso?", [
        ("Tomar un caso de la clase rara",
         "Por ejemplo, una transacción fraudulenta."),
        ("Encontrar sus k vecinos más cercanos",
         "Otros casos de fraude que sean parecidos en sus variables."),
        ("Elegir uno de esos vecinos al azar",
         "Seleccionamos un 'compañero' del caso original."),
        ("Interpolar en una proporción aleatoria",
         "Nuevo punto = original + r * (vecino - original), donde r es "
         "un número aleatorio entre 0 y 1."),
        ("Repetir hasta alcanzar el balance deseado",
         "Se crean tantos sintéticos como sean necesarios."),
    ], sig(), FT,
    intro="El resultado: más casos de fraude, pero no repetidos: son variantes "
          "nuevas y plausibles.")

slide_alerta(
    prs, "Cuidado con SMOTE: el orden importa",
    "SMOTE exige que TODOS los predictores sean numéricos. "
    "Por eso step_dummy (convertir categóricas a dummies) debe ejecutarse "
    "ANTES de step_smote en la receta.\n\n"
    "Además, SMOTE tiene un hiperparámetro (número de vecinos, k) que "
    "también se puede afinar.\n\n"
    "Finalmente: como todo remuestreo, SMOTE solo se aplica al "
    "entrenamiento, NUNCA a la prueba.",
    sig(), FT,
    etiqueta="Orden obligatorio en la receta")

# ============================================================
# SECCIÓN 8  —  Solución III: umbral y pesos de clase
# ============================================================
slide_seccion(prs, 8,
              "Solución III:\nUmbral\ny pesos de clase",
              "Ajustar el modelo sin tocar los datos")

slide_concepto(
    prs,
    "El umbral de decisión: no siempre es 0.5",
    "La mayoría de los clasificadores producen una PROBABILIDAD (0 a 1) "
    "antes de decidir la clase. Por default, si la probabilidad > 0.5, "
    "predice POSITIVO. Pero ese umbral lo podemos mover.\n\n"
    "Bajar el umbral (p. ej. a 0.2) hace al modelo más 'alarmanero': "
    "detecta más fraudes, pero también lanza más alarmas falsas.",
    sig(), FT,
    en_cristiano="Como ajustar la sensibilidad del detector de metales: "
                 "si lo ponemos muy sensible, suena con llaves; si muy tolerante, "
                 "deja pasar cosas peligrosas.")

slide_figura(
    prs, "Mover el umbral cambia el equilibrio precisión-recall",
    img("09_umbral.png"), sig(), FT,
    caption="Con umbral bajo: recall alto (detectamos más fraudes), "
            "precisión baja (más falsas alarmas). Con umbral alto: lo opuesto.",
    nota="Elegir el umbral óptimo depende del costo relativo del FP vs el FN "
         "en el negocio específico.")

slide_figura(
    prs, "Pesos de clase: penalizar más el error en la clase rara",
    img("12_pesos_clase.png"), sig(), FT,
    caption="class_weight='balanced' multiplica el costo de cada error "
            "por el inverso de la frecuencia de esa clase.",
    nota="Con 96 % normales y 4 % fraudes, el peso del fraude es "
         "96/4 = 24: equivocarse en un fraude 'duele' 24 veces más en "
         "el entrenamiento. El modelo aprende a evitar ese error.")

slide_comparacion(
    prs, "Las tres soluciones: cuándo usar cada una",
    {
        "titulo": "Remuestreo + SMOTE",
        "color": DARK_GREEN, "fill": SOFT_GREEN,
        "body": "Cuándo usar:\n"
                "- Desbalance severo (> 10:1)\n"
                "- El modelo es sensible a la distribución de clases\n\n"
                "Cuidado:\n"
                "- Solo en entrenamiento, NUNCA en prueba\n"
                "- step_dummy ANTES de step_smote",
    },
    {
        "titulo": "Umbral + Pesos de clase",
        "color": TEAL, "fill": SOFT_TEAL,
        "body": "Cuándo usar:\n"
                "- Queremos incorporar el costo del negocio\n"
                "- No queremos alterar los datos\n\n"
                "Ventajas:\n"
                "- Simple: un parámetro en el modelo\n"
                "- No crea datos artificiales\n"
                "- Rápido de ajustar",
    },
    sig(), FT,
    intro="Las soluciones se pueden combinar: pesos de clase + SMOTE, "
          "o SMOTE + ajuste de umbral.")

# ============================================================
# SLIDE ALERTA: Errores comunes
# ============================================================
slide_alerta(
    prs,
    "Errores comunes al trabajar con clases desbalanceadas",
    "- Confiar en la accuracy: un modelo con 96 % de accuracy puede ser "
    "inservible si la clase rara tiene recall 0.\n\n"
    "- Remuestrear ANTES de partir el dataset: los sintéticos de SMOTE "
    "generados con datos del test 'filtran' información y contaminan la "
    "evaluación (data leakage).\n\n"
    "- Aplicar SMOTE sin step_dummy previo: SMOTE exige predictores "
    "numéricos; las categóricas deben convertirse primero.\n\n"
    "- Olvidar que el umbral 0.5 es solo el default: ajustarlo puede "
    "mejorar mucho el desempeño operativo.",
    sig(), FT,
    etiqueta="Lista de verificación")

slide_figura(
    prs,
    "La contaminación de datos (data leakage): el error más grave",
    img("10_leakage.png"), sig(), FT,
    caption="Incorrecto: remuestrear ANTES del split. "
            "Correcto: separar primero y remuestrear SOLO el entrenamiento.",
    nota="Si los sintéticos del SMOTE se generan con puntos del conjunto "
         "de prueba, la evaluación final ya no es honesta: el modelo ya "
         "'vio' esos datos de alguna forma.")

# ============================================================
# CONCLUSIONES + CIERRE
# ============================================================
slide_conclusiones(
    prs, "Conclusiones",
    "\n".join("- " + t for t in [
        "Las clases desbalanceadas son comunes: fraude, fallas, casos raros.",
        "La accuracy engaña: un modelo perezoso puede tener 96 % y detectar cero fraudes.",
        "Las métricas clave con desbalance son recall, precisión y F1 (no accuracy).",
        "La curva Precisión-Recall es más informativa que la ROC con desbalance extremo.",
        "Remuestreo (over/under) y SMOTE rebalancean los datos de entrenamiento.",
        "Los pesos de clase y el umbral ajustan el modelo sin cambiar los datos.",
        "La regla de oro: remuestrear SOLO el entrenamiento, NUNCA la prueba.",
    ]),
    sig(), FT)

slide_cierre(prs)

prs.save(OUT)
print(f"Guardado: {OUT}  |  slides: {len(prs.slides._sldIdLst)}")
