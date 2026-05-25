"""Construye la presentacion TEORICA de la Sesion 20 (arboles de decision,
bosques aleatorios, boosting y stacking) para audiencia de preparatoria.
Estilo Tec 4:3. Requiere las figuras de img_teoria/ (generar antes con
figs_s20.py).
"""
import os
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
S16 = os.path.join(BASE, "..", "Sesion 16 knn workflows")
sys.path.insert(0, S16)

from estilo_teoria import (
    nueva_presentacion, slide_portada, slide_agenda, slide_seccion,
    slide_concepto, slide_figura, slide_texto_figura, slide_pasos,
    slide_comparacion, slide_analogia, slide_alerta, slide_tabla,
    slide_conclusiones, slide_cierre,
    TEAL, PLUM, OCHRE, SOFT_TEAL, SOFT_OCHRE,
)
from estilo_teoria import DARK_GREEN, DARK_RED, NAVY, SOFT_GREEN, SOFT_RED
from estilo_teoria import LIGHT_BLUE

IMG = os.path.join(BASE, "img_teoria")
OUT = os.path.join(BASE, "sesion_20_teoria_otros_modelos.pptx")
FT = "Sesión 20 · Otros modelos y ensambles"
img = lambda n: os.path.join(IMG, n)

prs = nueva_presentacion()
n = 0


def sig():
    global n
    n += 1
    return n


# =============================================================================
# 1. PORTADA
# =============================================================================
slide_portada(
    prs,
    "Árboles, bosques, boosting\ny ensambles",
    "Sesión 20 · De un solo árbol a un bosque completo",
    "Tecnológico de Monterrey  ·  TC2001B.601 Ciencia de datos\n"
    "Prof. Jorge Juvenal Campos Ferreira",
)

# =============================================================================
# 2. AGENDA
# =============================================================================
slide_agenda(prs, "Lo que veremos hoy", [
    "Más allá de KNN y la regresión logística",
    "Árboles de decisión: preguntas sí/no",
    "Por dentro de un árbol: nodos, ramas y hojas",
    "El problema de un solo árbol",
    "Bosques aleatorios: la sabiduría de la multitud",
    "Bagging vs boosting",
    "Boosting: corregir errores en secuencia",
    "Ensambles y stacking: combinar lo mejor",
    "¿Qué modelo elegir?",
], sig(), FT)

# =============================================================================
# SECCION 1 - Mas alla de KNN y la regresion logistica
# =============================================================================
slide_seccion(
    prs, 1,
    "Más allá de KNN\ny la regresión logística",
    "¿Por qué existen tantos modelos? Ninguno gana siempre.",
)

slide_analogia(
    prs,
    "Muchas herramientas para muchos problemas",
    "Un carpintero tiene martillo, sierra, formones y lija. No usa solo el"
    " martillo para todo.\n\nEn ciencia de datos pasa igual: cada modelo tiene"
    " sus puntos fuertes. No existe un modelo perfecto para todos los problemas."
    " Por eso aprendemos varios y elegimos el que mejor encaja con cada reto.",
    sig(), FT,
    color=TEAL, fill=SOFT_TEAL, etiqueta="Piénsalo así",
)

slide_figura(
    prs,
    "El mapa de modelos de ML",
    img("01_panorama_modelos.png"),
    sig(), FT,
    caption="Cada familia de modelos brilla en distintos escenarios.",
    nota="Hoy nos enfocamos en los árboles y sus 'primos' más poderosos:"
         " bosque aleatorio, boosting y stacking.",
)

slide_concepto(
    prs,
    "El teorema del No Free Lunch",
    "Formalmente: para cualquier algoritmo de aprendizaje, existe un problema"
    " donde ese algoritmo falla. Ningún modelo es el mejor en todo."
    " La solución práctica es comparar varios modelos con validación cruzada"
    " y quedarse con el que dé mejor desempeño en TUS datos.",
    sig(), FT,
    en_cristiano="Ningún modelo gana siempre. La receta es probar varios y"
                 " dejar que los datos decidan.",
)

slide_figura(
    prs,
    "Ningún modelo gana siempre",
    img("12_no_free_lunch.png"),
    sig(), FT,
    caption="El ganador depende del tipo de datos y del problema.",
    nota="Por eso en cada sesión aprendemos un nuevo modelo: cada uno es"
         " el experto en algo.",
)

# =============================================================================
# SECCION 2 - Arboles de decision
# =============================================================================
slide_seccion(
    prs, 2,
    "Árboles de decisión",
    "Cómo partir el espacio con preguntas sí/no",
)

slide_analogia(
    prs,
    "El juego de las 20 preguntas",
    "Piensa en el juego '20 preguntas': intentas adivinar un objeto haciendo"
    " preguntas de sí/no. Cada respuesta te acerca más a la solución.\n\n"
    "Un árbol de decisión hace EXACTAMENTE eso con los datos:"
    " hace preguntas sobre las variables del solicitante y al final llega a una"
    " decisión: APROBADO o RECHAZADO.",
    sig(), FT,
    color=OCHRE, fill=SOFT_OCHRE, etiqueta="Piénsalo así",
)

slide_figura(
    prs,
    "Un árbol de decisión en acción",
    img("02_arbol_diagrama.png"),
    sig(), FT,
    caption="Cada nodo hace una pregunta; cada hoja da la decisión final.",
    nota="Este árbol dice: si el score es alto y la deuda es baja, aprueba."
         " Muy fácil de explicar a cualquier persona.",
)

slide_concepto(
    prs,
    "Los tres componentes de un árbol",
    "NODO RAÍZ: la primera pregunta, la más importante (la que mejor separa"
    " las clases).\n\n"
    "RAMAS: los caminos según la respuesta (sí / no).\n\n"
    "HOJAS: los nodos finales donde ya no hay más preguntas; dan la predicción.",
    sig(), FT,
    en_cristiano="Raíz = primera pregunta, ramas = caminos, hojas = respuesta"
                 " final. Como un diagrama de flujo.",
)

# =============================================================================
# SECCION 3 - Por dentro de un arbol
# =============================================================================
slide_seccion(
    prs, 3,
    "Por dentro de un árbol",
    "Fronteras rectangulares y particiones",
)

slide_figura(
    prs,
    "La frontera de un árbol son rectángulos",
    img("03_frontera_arbol.png"),
    sig(), FT,
    caption="Cada pregunta crea un corte vertical u horizontal en el espacio.",
    nota="El árbol parte el plano en bloques rectangulares. Dentro de cada"
         " bloque, todos los puntos reciben la misma predicción.",
)

slide_pasos(
    prs,
    "¿Cómo elige el árbol qué pregunta hacer primero?",
    [
        ("Prueba todos los cortes posibles",
         "Para cada variable y cada valor de corte, calcula cuánto reduce la"
         " mezcla de clases."),
        ("Elige el mejor corte",
         "El corte que deja los grupos más 'puros' (una clase domina) gana."),
        ("Repite en cada rama",
         "En cada subconjunto resultante, repite el proceso hasta llegar a una"
         " hoja o al límite de profundidad."),
        ("Se para cuando toca",
         "El árbol se detiene cuando ya no puede mejorar o alcanza la"
         " profundidad máxima que le indicamos."),
    ],
    sig(), FT,
    intro="El algoritmo es voraz: elige la mejor división local en cada paso.",
)

slide_concepto(
    prs,
    "Profundidad del árbol",
    "La profundidad es cuántos niveles de preguntas tiene el árbol."
    " Un árbol muy profundo hace muchas preguntas y puede llegar a memorizar"
    " los datos de entrenamiento.\n\n"
    "La profundidad es el hiperparámetro principal que controlamos, igual que"
    " era k en KNN.",
    sig(), FT,
    en_cristiano="Profundidad pequeña = preguntas generales."
                 " Profundidad grande = preguntas muy específicas que"
                 " memorizan hasta el ruido.",
)

# =============================================================================
# SECCION 4 - El problema de un solo arbol
# =============================================================================
slide_seccion(
    prs, 4,
    "El problema\nde un solo árbol",
    "Sobreajuste e inestabilidad",
)

slide_comparacion(
    prs,
    "Árbol sano vs árbol sobreajustado",
    {
        "titulo": "Profundidad = 4 (equilibrado)",
        "img": img("03_frontera_arbol.png"),
        "color": DARK_GREEN,
        "fill": SOFT_GREEN,
        "body": "Fronteras razonables\n\n"
                "-  Generaliza bien a datos nuevos\n"
                "-  Grupos relativamente puros\n"
                "-  Se puede explicar",
    },
    {
        "titulo": "Sin límite (memoriza todo)",
        "img": img("04_frontera_arbol_sobreajuste.png"),
        "color": DARK_RED,
        "fill": SOFT_RED,
        "body": "Fronteras con escalones mínimos\n\n"
                "-  Memoriza hasta el ruido\n"
                "-  Falla con datos nuevos\n"
                "-  'Aprendí de memoria'",
    },
    sig(), FT,
    intro="La profundidad máxima controla el equilibrio sesgo-varianza.",
)

slide_alerta(
    prs,
    "Árbol muy profundo = memorizar, no aprender",
    "Un árbol sin límite de profundidad puede hacer exactamente UNA hoja por"
    " cada punto de entrenamiento: memoriza el 100% de los datos.\n\n"
    "Pero si llega un caso nuevo que nunca vio, no sabe qué hacer."
    " Es como memorizar las respuestas del examen sin entender el tema.\n\n"
    "REGLA: siempre usa validación cruzada para elegir la profundidad máxima.",
    sig(), FT,
    etiqueta="El error clásico",
)

slide_concepto(
    prs,
    "Inestabilidad: una trampa adicional",
    "Si cambias unos pocos datos de entrenamiento, el árbol puede quedar"
    " completamente diferente. Eso se llama ALTA VARIANZA: el modelo es muy"
    " sensible al azar de qué datos entrenaron.\n\n"
    "Esto es un problema cuando necesitas decisiones consistentes y confiables.",
    sig(), FT,
    en_cristiano="Con un pequeño cambio en el examen, el estudiante que"
                 " memorizó todo saca 10; con otro pequeño cambio, saca 4."
                 " El que entendió el tema saca 8 en ambos.",
)

# =============================================================================
# SECCION 5 - Bosques aleatorios
# =============================================================================
slide_seccion(
    prs, 5,
    "Bosques aleatorios",
    "La sabiduría de la multitud",
)

slide_analogia(
    prs,
    "Pedir opinión a un grupo, no a una sola persona",
    "Si quieres decidir a qué restaurante ir, pregúntale a UNA persona y puede"
    " ser muy mala elección si esa persona tiene gustos raros.\n\n"
    "Pero si le preguntas a 100 personas independientes y eliges el restaurante"
    " que más gente recomienda, es mucho más probable que quedes bien.\n\n"
    "El bosque aleatorio hace lo mismo: construye cientos de árboles"
    " DISTINTOS e independientes, y deja que voten.",
    sig(), FT,
    color=TEAL, fill=SOFT_TEAL, etiqueta="Piénsalo así",
)

slide_figura(
    prs,
    "Cómo funciona un bosque aleatorio",
    img("05_bosque_esquema.png"),
    sig(), FT,
    caption="Muchos árboles independientes votan: la mayoría decide.",
    nota="La clave es que los árboles sean DISTINTOS entre sí."
         " Si todos son iguales, votar no ayuda.",
)

slide_pasos(
    prs,
    "Dos ingredientes secretos del bosque",
    [
        ("Bootstrap (muestras distintas)",
         "Cada árbol entrena sobre una muestra aleatoria CON REEMPLAZO de los"
         " datos originales. Así cada árbol ve datos ligeramente distintos."),
        ("Subconjunto aleatorio de variables",
         "En cada nodo, el árbol solo puede escoger entre un subgrupo"
         " aleatorio de variables. Esto fuerza a que los árboles sean"
         " diferentes entre sí."),
        ("Voto de mayoría",
         "Para clasificación: gana la clase que más árboles predicen."
         " Para regresión: se promedia la predicción de todos los árboles."),
        ("Sin tuning de profundidad",
         "Cada árbol crece hasta su máximo (sin límite). El bosque corrige"
         " el sobreajuste de cada árbol individual al promediar."),
    ],
    sig(), FT,
    intro="Bagging + subconjunto de variables = árboles diferentes que"
          " se complementan.",
)

slide_figura(
    prs,
    "Frontera del bosque vs un árbol",
    img("06_frontera_bosque.png"),
    sig(), FT,
    caption="El bosque tiene una frontera más suave y más correcta.",
    nota="El bosque reduce la varianza de cada árbol individual al"
         " promediar cientos de ellos.",
)

# =============================================================================
# SECCION 6 - Bagging vs Boosting
# =============================================================================
slide_seccion(
    prs, 6,
    "Bagging vs Boosting",
    "Paralelo vs secuencial",
)

slide_figura(
    prs,
    "Dos estrategias de ensamble",
    img("07_bagging_vs_boosting.png"),
    sig(), FT,
    caption="Bagging: árboles en paralelo sobre muestras distintas."
            " Boosting: árboles en secuencia que corrigen errores.",
    nota="Bagging reduce la varianza; boosting reduce el sesgo."
         " Ambos mejoran sobre un árbol solo.",
)

slide_comparacion(
    prs,
    "Bagging vs Boosting: diferencias clave",
    {
        "titulo": "Bagging (Random Forest)",
        "color": TEAL,
        "fill": SOFT_TEAL,
        "body": "Los árboles se entrenan EN PARALELO\n\n"
                "-  Cada árbol ve una muestra distinta\n"
                "-  Los árboles son independientes\n"
                "-  El resultado es su promedio/voto\n"
                "-  Reduce varianza (sobreajuste)\n"
                "-  Muy fácil de paralelizar",
    },
    {
        "titulo": "Boosting (GBM, XGBoost)",
        "color": DARK_RED,
        "fill": SOFT_RED,
        "body": "Los árboles se entrenan EN SECUENCIA\n\n"
                "-  Cada árbol aprende del error anterior\n"
                "-  Los árboles dependen entre sí\n"
                "-  El resultado es su suma ponderada\n"
                "-  Reduce sesgo (subajuste)\n"
                "-  Suele ganar competencias de ML",
    },
    sig(), FT,
    intro="Ambos son ensambles de árboles, pero con lógicas muy distintas.",
)

# =============================================================================
# SECCION 7 - Boosting
# =============================================================================
slide_seccion(
    prs, 7,
    "Boosting",
    "Corregir errores en secuencia",
)

slide_analogia(
    prs,
    "El equipo que aprende de sus errores",
    "Imagina un equipo de trabajo donde la primera persona hace su mejor"
    " esfuerzo, pero comete algunos errores.\n\n"
    "La segunda persona solo trabaja en los errores de la primera."
    " La tercera, solo en los errores que quedaron. Y así sucesivamente.\n\n"
    "Al final se suman todas las contribuciones. El equipo completo"
    " es mucho mejor que cualquier miembro solo.",
    sig(), FT,
    color=OCHRE, fill=SOFT_OCHRE, etiqueta="Piénsalo así",
)

slide_figura(
    prs,
    "Boosting: el error se encoge ronda a ronda",
    img("08_boosting_secuencial.png"),
    sig(), FT,
    caption="Cada ronda agrega un árbol que corrige lo que el anterior falló.",
    nota="Los puntos que el modelo anterior falló reciben MÁS PESO en la"
         " siguiente ronda. El modelo 'se enfoca' en lo difícil.",
)

slide_pasos(
    prs,
    "Algoritmo de boosting, paso a paso",
    [
        ("Ronda 1: primer árbol",
         "Entrenamos un árbol pequeño sobre todos los datos. Calculamos los"
         " errores."),
        ("Dar más peso a los errores",
         "Los puntos que el primer árbol falló reciben mayor peso. El segundo"
         " árbol los prioriza."),
        ("Ronda 2, 3, ..., N",
         "Repetimos: cada árbol se enfoca en los errores del anterior."
         " Los árboles son pequeños (profundidad 1-3)."),
        ("Sumar todo con pesos",
         "La predicción final es la suma ponderada de todos los árboles."
         " Las rondas con menor error pesan más."),
        ("Parar a tiempo",
         "Si dejamos que el proceso siga demasiado, puede sobreajustar."
         " Usamos validación cruzada para decidir cuántas rondas hacer."),
    ],
    sig(), FT,
    intro="XGBoost y GBM son las implementaciones más populares.",
)

slide_concepto(
    prs,
    "XGBoost: el campeón de las competencias",
    "XGBoost (eXtreme Gradient Boosting) es una implementación muy"
    " eficiente y optimizada del boosting. Desde 2014, ganó decenas de"
    " competencias internacionales de ML (Kaggle, Netflix Prize, etc.).\n\n"
    "Agrega regularización L1/L2 al boosting clásico, lo que reduce el"
    " sobreajuste y lo hace más robusto.",
    sig(), FT,
    en_cristiano="XGBoost es el boosting con cinturón de seguridad: muy"
                 " poderoso y además resistente al sobreajuste.",
)

# =============================================================================
# SECCION 8 - Ensambles y stacking
# =============================================================================
slide_seccion(
    prs, 8,
    "Ensambles y stacking",
    "Combinar lo mejor de varios modelos",
)

slide_analogia(
    prs,
    "El jurado de expertos",
    "Cuando un tribunal tiene que tomar una decisión difícil, no depende de"
    " un solo juez. Reúne a varios expertos con perspectivas distintas:"
    " médico, economista, abogado...\n\n"
    "El stacking hace lo mismo: corre varios modelos DISTINTOS (un árbol,"
    " un bosque, regresión logística, KNN) y luego un meta-modelo aprende"
    " cuál combinación de sus predicciones es la mejor.",
    sig(), FT,
    color=PLUM, fill=SOFT_OCHRE, etiqueta="Piénsalo así",
)

slide_figura(
    prs,
    "Stacking: cómo funciona",
    img("09_stacking_diagrama.png"),
    sig(), FT,
    caption="Los modelos base predicen; el meta-modelo combina esas predicciones.",
    nota="La clave es que los modelos base sean DISTINTOS: cada uno captura"
         " algo que los otros no ven. El meta-modelo aprende los pesos"
         " óptimos de cada uno.",
)

slide_pasos(
    prs,
    "Cómo construir un ensamble por stacking",
    [
        ("Elegir modelos base distintos",
         "KNN, árbol de decisión, bosque aleatorio y regresión logística."
         " Cuanto más distintos, mejor."),
        ("Entrenar con validación cruzada",
         "Cada modelo base se entrena con CV para evitar data leakage."
         " Las predicciones de CV forman los nuevos datos de entrenamiento."),
        ("Construir la tabla de predicciones",
         "Cada columna es la predicción de un modelo base. Eso es lo que"
         " ve el meta-modelo."),
        ("Entrenar el meta-modelo",
         "Usualmente es un modelo sencillo (regresión logística) que aprende"
         " a combinar las predicciones base."),
        ("Evaluar el conjunto completo",
         "El stack completo se evalúa en la base de prueba, una sola vez."),
    ],
    sig(), FT,
    intro="Data leakage es el riesgo principal: hay que hacerlo con CV.",
)

slide_alerta(
    prs,
    "Data leakage en stacking: el error más costoso",
    "Si usas el mismo conjunto de datos para entrenar los modelos base Y"
    " para generar las predicciones que ve el meta-modelo, el sistema se"
    " engaña a sí mismo.\n\n"
    "Los modelos base ya 'conocen' esos datos, entonces sus predicciones"
    " son artificialmente buenas. El meta-modelo aprende sobre predicciones"
    " demasiado optimistas y falla en datos reales.\n\n"
    "SOLUCIÓN: usar validación cruzada para generar las predicciones base.",
    sig(), FT,
    etiqueta="Data leakage en stacking",
)

# =============================================================================
# SECCION 9 - Que modelo elegir
# =============================================================================
slide_seccion(
    prs, 9,
    "¿Qué modelo elegir?",
    "Tabla comparativa de modelos",
)

slide_figura(
    prs,
    "Comparación de fronteras de decisión",
    img("11_comparacion_fronteras.png"),
    sig(), FT,
    caption="De izquierda a derecha: mayor complejidad y mejor ajuste.",
    nota="El boosting generalmente produce la frontera más precisa, pero"
         " también es el más lento de entrenar y el más difícil de"
         " interpretar.",
)

slide_figura(
    prs,
    "¿Qué variables importan más?",
    img("10_importancia_variables.png"),
    sig(), FT,
    caption="El bosque aleatorio indica qué variables predicen mejor.",
    nota="La importancia de variables es una de las ventajas de los árboles"
         " sobre KNN: puedes explicar POR QUÉ el modelo toma cada decisión.",
)

slide_tabla(
    prs,
    "Comparación de modelos: guía rápida",
    ["Modelo", "Interpretabilidad", "Desempeño", "Velocidad",
     "¿Cuándo conviene?"],
    [
        ["Árbol de decisión", "Muy alta", "Medio", "Muy rápido",
         "Explicar a no-técnicos, primeros pasos"],
        ["Bosque aleatorio", "Media", "Alto", "Rápido",
         "Buen punto de partida, muchos datos"],
        ["Boosting (XGBoost)", "Baja", "Muy alto", "Moderado",
         "Máximo rendimiento, competencias"],
        ["Stacking", "Muy baja", "Muy alto", "Lento",
         "Competencias, cuando el último % importa"],
        ["KNN", "Alta", "Medio", "Lento (predict)",
         "Pocos datos, línea base"],
        ["Reg. logística", "Alta", "Medio-bajo", "Muy rápido",
         "Datos lineales, interpretación crítica"],
    ],
    sig(), FT,
    intro="No hay un ganador universal: elige según las restricciones del"
          " problema.",
)

slide_alerta(
    prs,
    "Errores comunes al usar modelos avanzados",
    "-  Usar boosting sin validar: sobreajusta si no limitas las rondas.\n\n"
    "-  Creer que más complejo = mejor: un árbol simple a veces gana.\n\n"
    "-  No usar validación cruzada antes de reportar resultados.\n\n"
    "-  Comparar modelos en la prueba para elegir: eso es data leakage.\n\n"
    "-  Ignorar interpretabilidad cuando el negocio la necesita.",
    sig(), FT,
    etiqueta="Lista de verificación",
)

# =============================================================================
# CONCLUSIONES Y CIERRE
# =============================================================================
slide_conclusiones(
    prs,
    "Conclusiones",
    "\n".join("-  " + t for t in [
        "Los árboles de decisión clasifican con preguntas sí/no:"
        " muy fáciles de interpretar pero inestables.",
        "Un árbol muy profundo memoriza el ruido: hay que controlar la"
        " profundidad con validación cruzada.",
        "Los bosques aleatorios combinan cientos de árboles distintos:"
        " mucho más estables y precisos.",
        "Bagging entrena árboles en paralelo sobre muestras distintas;"
        " boosting los entrena en secuencia corrigiendo errores.",
        "El stacking combina modelos distintos con un meta-modelo:"
        " maximiza el desempeño a costa de interpretabilidad.",
        "Ningún modelo gana siempre: prueba varios con validación cruzada"
        " y deja que los datos decidan.",
    ]),
    sig(), FT,
)

slide_cierre(prs)

prs.save(OUT)
print(f"Guardado: {OUT}  |  slides: {len(prs.slides._sldIdLst)}")
