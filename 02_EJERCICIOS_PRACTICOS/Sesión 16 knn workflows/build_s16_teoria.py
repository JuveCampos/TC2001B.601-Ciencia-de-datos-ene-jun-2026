"""Construye la presentacion TEORICA de la Sesion 16 (KNN, workflows,
validacion cruzada y tuning) para audiencia de preparatoria. Estilo Tec 4:3.
Requiere las figuras de img_teoria/ (generar antes con figs_s16.py)."""
import os
from estilo_teoria import (
    nueva_presentacion, slide_portada, slide_agenda, slide_seccion,
    slide_concepto, slide_figura, slide_texto_figura, slide_pasos,
    slide_comparacion, slide_analogia, slide_alerta, slide_conclusiones,
    slide_cierre, TEAL, PLUM,
)
from estilo_teoria import DARK_GREEN, DARK_RED, NAVY, SOFT_GREEN, SOFT_RED

BASE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(BASE, "img_teoria")
OUT = os.path.join(BASE, "sesion_16_teoria_knn.pptx")
FT = "Sesión 16 · KNN y validación cruzada"
img = lambda n: os.path.join(IMG, n)

prs = nueva_presentacion()
n = 0


def sig():
    global n
    n += 1
    return n


# 1. Portada
slide_portada(
    prs,
    "KNN, validación cruzada\ny ajuste de modelos",
    "Sesión 16 · Cómo una computadora aprende a decidir mirando a sus vecinos",
    "Tecnológico de Monterrey  ·  TC2001B.601 Ciencia de datos\n"
    "Prof. Jorge Juvenal Campos Ferreira")

# 2. Agenda
slide_agenda(prs, "Lo que veremos hoy", [
    "¿Qué es predecir con datos?",
    "La gran idea de KNN: tus vecinos te describen",
    "El número k lo cambia todo",
    "Preparar los datos para que KNN funcione",
    "¿El modelo de verdad sirve? Entrenar vs evaluar",
    "Validación cruzada: elegir k con honestidad",
    "Juntar todo en un workflow y afinarlo",
    "Medir qué tan bueno es: matriz de confusión y ROC",
], sig(), FT)

# ====================== SECCIÓN 1 ======================
slide_seccion(prs, 1, "¿Qué es predecir\ncon datos?",
              "De ejemplos del pasado a decisiones del futuro")

slide_figura(
    prs, "Aprendizaje supervisado", img("01_supervisado.png"), sig(), FT,
    caption="El modelo ve muchos ejemplos resueltos y aprende el patrón.",
    nota="Supervisado = aprendemos de ejemplos que YA traen la respuesta "
         "correcta (aquí: solicitudes pasadas que sabemos si se aprobaron).")

slide_figura(
    prs, "Dos tipos de predicción", img("02_clasif_regres.png"), sig(), FT,
    caption="Clasificación predice una categoría; regresión predice un número.",
    nota="Hoy haremos CLASIFICACIÓN: la respuesta es 'sí' o 'no' "
         "(¿se aprueba la solicitud de crédito?).")

slide_concepto(
    prs, "Nuestro problema de hoy",
    "Una institución financiera recibe solicitudes de crédito y debe decidir "
    "si las APRUEBA o las RECHAZA. Tenemos 950 solicitudes del pasado, cada "
    "una con datos del solicitante (edad, ingreso, score de crédito, deudas...) "
    "y la decisión que se tomó. Queremos un modelo que prediga la decisión "
    "para solicitudes nuevas.",
    sig(), FT,
    en_cristiano="Es como aprender a calificar solicitudes viendo miles de "
                 "casos ya resueltos, para luego calificar una nueva tú solo.")

# ====================== SECCIÓN 2 ======================
slide_seccion(prs, 2, "La gran idea\nde KNN",
              "k vecinos más cercanos: dime con quién te pareces")

slide_analogia(
    prs, "La intuición detrás de KNN",
    "Si quieres adivinar si a alguien le gustará una película, preguntas a las "
    "personas más PARECIDAS a esa persona (misma edad, mismos gustos) y ves "
    "qué opina la mayoría.\n\nKNN hace exactamente eso: para clasificar un caso "
    "nuevo, busca los casos más parecidos que ya conoce y copia la respuesta "
    "de la mayoría.",
    sig(), FT, color=TEAL,
    fill=__import__("estilo_teoria").SOFT_TEAL, etiqueta="Piénsalo así")

slide_figura(
    prs, "Cada solicitud es un punto", img("03_espacio.png"), sig(), FT,
    caption="Dos solicitudes parecidas quedan cerca; dos muy distintas, lejos.",
    nota="Colocamos cada solicitud en un 'mapa' según sus características. "
         "Aquí lo vemos en 2 ejes; el modelo real usa muchos más.")

slide_figura(
    prs, "¿Qué significa 'cercano'?", img("04_distancia.png"), sig(), FT,
    caption="La distancia mide qué tan diferentes son dos personas.",
    nota="Entre más pequeña la distancia, más se parecen. Es el mismo Teorema "
         "de Pitágoras que viste en prepa, pero con datos.")

slide_pasos(
    prs, "KNN paso a paso", [
        ("Llega un caso nuevo", "Una solicitud sin clasificar todavía."),
        ("Medir distancias", "Calculamos qué tan lejos está de cada caso "
         "conocido."),
        ("Elegir los k más cercanos", "Nos quedamos con los k vecinos más "
         "parecidos (por ejemplo, k = 5)."),
        ("Votar", "La clase que más se repite entre esos k vecinos gana."),
        ("Asignar la clase", "El caso nuevo recibe la clase ganadora."),
    ], sig(), FT,
    intro="No hay fórmulas mágicas: solo medir, ordenar y votar.")

slide_figura(
    prs, "La votación en acción", img("05_knn_vota.png"), sig(), FT,
    caption="Con k = 5, ganan 3 votos de 'aprobado' sobre 2 de 'rechazado'.",
    nota="El caso nuevo (estrella) se clasifica como 'aprobado' porque la "
         "mayoría de sus 5 vecinos más cercanos lo son.")

slide_concepto(
    prs, "KNN es un modelo 'perezoso'",
    "A diferencia de otros modelos, KNN no calcula fórmulas ni 'estudia' por "
    "adelantado: simplemente GUARDA todos los ejemplos. El trabajo lo hace "
    "hasta que llega un caso nuevo y toca medir distancias y votar.",
    sig(), FT,
    en_cristiano="Es como un estudiante que no estudia antes, pero tiene todos "
                 "sus apuntes a la mano y los consulta justo en el examen.")

# ====================== SECCIÓN 3 ======================
slide_seccion(prs, 3, "El número k\nlo cambia todo",
              "Pocos vecinos vs muchos vecinos")

slide_concepto(
    prs, "k es una decisión nuestra",
    "k es cuántos vecinos consultamos para votar. No lo aprenden los datos: "
    "lo elegimos nosotros. Y cambiarlo cambia por completo cómo el modelo "
    "separa una clase de otra (su 'frontera de decisión').",
    sig(), FT,
    en_cristiano="¿Le preguntas solo a 1 amigo o a 100? La respuesta puede "
                 "cambiar muchísimo según a cuántos consultes.")

slide_figura(
    prs, "La frontera según k", img("06_fronteras_3.png"), sig(), FT,
    caption="Misma información, tres valores de k: la frontera cambia mucho.",
    nota="Con k = 1 la frontera es muy retorcida; con k = 120 es casi una "
         "línea recta. En medio está el equilibrio.")

slide_comparacion(
    prs, "k pequeño vs k grande",
    {"titulo": "k = 1: sobreajuste", "img": img("07_frontera_k1.png"),
     "color": DARK_RED, "fill": SOFT_RED,
     "body": "Le hace demasiado caso a CADA punto, hasta al ruido.\n\n"
             "•  Frontera muy retorcida\n"
             "•  Memoriza en vez de generalizar\n"
             "•  Falla con datos nuevos"},
    {"titulo": "k = 120: subajuste", "img": img("08_frontera_kgrande.png"),
     "color": NAVY, "fill": None,
     "body": "Promedia tantos vecinos que borra el detalle real.\n\n"
             "•  Frontera demasiado plana\n"
             "•  Ignora patrones verdaderos\n"
             "•  También falla, por simplón"},
    sig(), FT,
    intro="Los dos extremos son malos, por razones opuestas.")

slide_figura(
    prs, "El equilibrio sesgo-varianza", img("09_sesgo_varianza.png"), sig(),
    FT,
    caption="El error en datos nuevos baja, toca un mínimo y vuelve a subir.",
    nota="El 'punto dulce' es el k que da el menor error con datos NUEVOS: ni "
         "tan chico que memorice, ni tan grande que simplifique de más.")

slide_analogia(
    prs, "Sesgo y varianza, sin tecnicismos",
    "SESGO alto = estudiar de más con reglas demasiado simples ('todo es 2+2') "
    "y equivocarte por simplón.\n\n"
    "VARIANZA alta = memorizar cada ejemplo del libro al pie de la letra y "
    "perderte si el examen cambia una coma.\n\n"
    "El buen modelo, como el buen estudiante, está en el punto medio.",
    sig(), FT, color=PLUM,
    fill=__import__("estilo_teoria").SOFT_OCHRE, etiqueta="Analogía")

# ====================== SECCIÓN 4 ======================
slide_seccion(prs, 4, "Preparar los datos\npara KNN",
              "Porque KNN mide distancias, los detalles importan")

slide_figura(
    prs, "¡Cuidado con las escalas!", img("10_escala.png"), sig(), FT,
    caption="Sin normalizar, la variable de números grandes domina la distancia.",
    nota="El ingreso (en miles) y el número de créditos (0 a 8) viven en "
         "escalas muy distintas. KNN creería que el ingreso es lo único que "
         "importa.")

slide_figura(
    prs, "Normalizar pone todo en la misma escala",
    img("12_normalizacion.png"), sig(), FT,
    caption="Estandarizar: restar la media y dividir entre la desviación.",
    nota="Tras normalizar, toda variable tiene media 0 y desviación 1. Ahora "
         "todas pesan igual al medir distancias. Es el paso CLAVE para KNN.")

slide_figura(
    prs, "Variables que dicen lo mismo", img("11_colinealidad.png"), sig(), FT,
    caption="Monto y pago mensual están casi perfectamente correlacionados.",
    nota="Si dos variables miden casi lo mismo, esa información pesa DOBLE en "
         "la distancia. Quitamos una para no contar lo mismo dos veces.")

slide_concepto(
    prs, "Datos faltantes (NA)",
    "En la vida real, algunas celdas vienen vacías: un solicitante no reportó "
    "su ingreso, otro no tiene score. KNN no puede medir distancias con huecos. "
    "La solución más común es IMPUTAR: rellenar el hueco con un valor "
    "razonable, como la mediana de esa columna.",
    sig(), FT,
    en_cristiano="Si en una lista falta un dato, lo rellenamos con el valor "
                 "'típico' del grupo para no tener que tirar toda la fila.")

slide_pasos(
    prs, "La receta de preparación (en orden)", [
        ("1. Imputar faltantes", "Rellenar los NA con la mediana. Va primero "
         "porque los pasos siguientes no toleran huecos."),
        ("2. Quitar lo casi constante", "Variables que casi no cambian no "
         "ayudan a distinguir; fuera."),
        ("3. Quitar redundantes", "Si dos variables están muy correlacionadas, "
         "conservamos una."),
        ("4. Normalizar", "Poner todas las variables en la misma escala. "
         "El paso decisivo para KNN."),
    ], sig(), FT,
    intro="El ORDEN importa: cada paso prepara el terreno para el siguiente.")

# ====================== SECCIÓN 5 ======================
slide_seccion(prs, 5, "¿El modelo\nde verdad sirve?",
              "Entrenar es fácil; evaluar con honestidad es lo difícil")

slide_alerta(
    prs, "La gran trampa",
    "Si calificamos al modelo con los MISMOS datos con los que aprendió, "
    "siempre saldrá excelente: ¡ya vio las respuestas!\n\n"
    "Es como darle a un estudiante el examen con las respuestas y luego "
    "presumir su 10. No prueba nada sobre casos nuevos.",
    sig(), FT, etiqueta="Error que hay que evitar")

slide_figura(
    prs, "Separar entrenamiento y prueba", img("13_split.png"), sig(), FT,
    caption="Reservamos un 25% que el modelo no verá hasta el final.",
    nota="La base de prueba se 'guarda en la caja fuerte': solo la usamos al "
         "final, para una calificación honesta con datos verdaderamente nuevos.")

slide_concepto(
    prs, "Un nuevo problema: ¿cómo elegimos k?",
    "Necesitamos probar varios valores de k y quedarnos con el mejor. Pero NO "
    "podemos usar la base de prueba para eso: si la usáramos para elegir k, "
    "dejaría de ser 'nueva' y volveríamos a hacer trampa.",
    sig(), FT,
    en_cristiano="Necesitamos un 'examen de práctica' que salga del material "
                 "de estudio, sin tocar el examen final.")

slide_figura(
    prs, "Validación cruzada (k-fold)", img("14_cv_folds.png"), sig(), FT,
    caption="Partimos el entrenamiento en 5 bloques y rotamos cuál se valida.",
    nota="En cada ronda, 4 bloques entrenan y 1 valida. Así cada bloque sirve "
         "de 'examen de práctica' una vez, sin tocar la prueba final.")

slide_pasos(
    prs, "Validación cruzada, paso a paso", [
        ("Partir en 5 bloques", "Dividimos solo el entrenamiento en 5 partes "
         "iguales."),
        ("Entrenar y validar", "Entrenamos con 4 bloques y medimos en el que "
         "quedó fuera."),
        ("Rotar", "Repetimos 5 veces, cambiando cuál bloque se queda fuera."),
        ("Promediar", "Promediamos las 5 mediciones: estimación estable del "
         "desempeño."),
        ("Repetir por cada k", "Hacemos todo esto para cada k candidato y "
         "comparamos."),
    ], sig(), FT)

# ====================== SECCIÓN 6 ======================
slide_seccion(prs, 6, "Juntar todo\ny afinarlo",
              "Workflows y ajuste de hiperparámetros")

slide_figura(
    prs, "¿Qué es un workflow?", img("15_workflow.png"), sig(), FT,
    caption="Empaqueta la receta de preparación y el modelo en un solo objeto.",
    nota="Con un workflow, entrenar y predecir aplican SIEMPRE los mismos "
         "pasos de preparación, sin que se nos olvide ninguno.")

slide_concepto(
    prs, "Afinar k (tuning)",
    "k es un HIPERPARÁMETRO: una perilla que ajustamos ANTES de entrenar. "
    "'Afinar' (tuning) significa probar muchos valores de k con validación "
    "cruzada y quedarnos con el que dé mejor desempeño. La lista de valores a "
    "probar se llama 'grilla'.",
    sig(), FT,
    en_cristiano="Como buscar el volumen perfecto de la música: pruebas varios "
                 "niveles y te quedas con el que mejor se oye.")

slide_figura(
    prs, "La curva que decide", img("16_auc_vs_k.png"), sig(), FT,
    caption="Calculamos el desempeño (AUC) para cada k y elegimos el máximo.",
    nota="El mejor k cae en medio de la grilla, no en los extremos: justo el "
         "equilibrio sesgo-varianza que buscábamos.")

# ====================== SECCIÓN 7 ======================
slide_seccion(prs, 7, "Medir qué tan\nbueno es",
              "Más allá del simple porcentaje de aciertos")

slide_figura(
    prs, "Matriz de confusión", img("17_matriz_confusion.png"), sig(), FT,
    caption="Las cuatro combinaciones de 'lo real' contra 'lo predicho'.",
    nota="La diagonal verde son aciertos. Las casillas rojas son los dos tipos "
         "de error: falsa alarma y caso que se nos pasó.")

slide_comparacion(
    prs, "Dos preguntas distintas",
    {"titulo": "Sensibilidad", "color": NAVY, "fill": None,
     "body": "De todos los que SÍ eran positivos, ¿a cuántos atrapamos?\n\n"
             "Importa cuando dejar pasar un positivo es grave (por ejemplo, no "
             "detectar una enfermedad o un fraude)."},
    {"titulo": "Especificidad", "color": TEAL, "fill":
     __import__("estilo_teoria").SOFT_TEAL,
     "body": "De todos los que NO eran positivos, ¿a cuántos descartamos "
             "bien?\n\nImporta cuando una falsa alarma es costosa (molestar a "
             "un cliente bueno o bloquear una compra legítima)."},
    sig(), FT,
    intro="El porcentaje de aciertos no basta: hay que ver QUÉ tipo de error "
          "comete el modelo.")

slide_figura(
    prs, "La curva ROC y el AUC", img("18_roc.png"), sig(), FT,
    caption="Entre más se acerca la curva a la esquina superior izquierda, mejor.",
    nota="El AUC resume la curva en un número de 0.5 (azar) a 1 (perfecto). "
         "Mide qué tan bien el modelo ORDENA los casos por riesgo.")

slide_concepto(
    prs, "La calificación final honesta",
    "Una vez elegido el mejor k con validación cruzada, reentrenamos el modelo "
    "con TODO el entrenamiento y, recién entonces, abrimos la 'caja fuerte' y "
    "lo evaluamos sobre la base de prueba. Esa cifra final sí refleja cómo se "
    "comportará con casos que nunca vio.",
    sig(), FT,
    en_cristiano="Estudiar con exámenes de práctica (CV), y solo al final "
                 "presentar el examen real (prueba) una sola vez.")

slide_comparacion(
    prs, "KNN: ventajas y desventajas",
    {"titulo": "Ventajas", "color": DARK_GREEN, "fill": SOFT_GREEN,
     "body": "•  Idea muy intuitiva y fácil de explicar\n\n"
             "•  No asume fórmulas ni líneas rectas\n\n"
             "•  Funciona bien con fronteras complicadas\n\n"
             "•  Pocas decisiones que tomar (básicamente k)"},
    {"titulo": "Desventajas", "color": DARK_RED, "fill": SOFT_RED,
     "body": "•  Lento si hay muchísimos datos (mide todo)\n\n"
             "•  Muy sensible a la escala de las variables\n\n"
             "•  Sufre con muchísimas variables a la vez\n\n"
             "•  No da una 'fórmula' interpretable"},
    sig(), FT)

slide_alerta(
    prs, "Errores comunes a evitar",
    "•  Olvidar normalizar: una variable se 'come' a las demás.\n\n"
    "•  Elegir k mirando la base de prueba: es hacer trampa.\n\n"
    "•  Usar accuracy cuando las clases están desbalanceadas.\n\n"
    "•  Dejar el identificador (id) como si fuera un predictor.",
    sig(), FT, etiqueta="Lista de verificación")

# Conclusiones y cierre
slide_conclusiones(prs, "Conclusiones", "\n".join("•  " + t for t in [
    "KNN clasifica un caso nuevo viendo la clase de sus vecinos más cercanos.",
    "k controla el equilibrio: chico sobreajusta, grande subajusta.",
    "Como KNN mide distancias, normalizar las variables es indispensable.",
    "Nunca se elige k ni se evalúa con los mismos datos del entrenamiento.",
    "La validación cruzada permite elegir k con honestidad.",
    "La calificación final se hace una sola vez, sobre la base de prueba.",
]), sig(), FT)

slide_cierre(prs)

prs.save(OUT)
print(f"Guardado: {OUT} | slides: {len(prs.slides._sldIdLst)}")
