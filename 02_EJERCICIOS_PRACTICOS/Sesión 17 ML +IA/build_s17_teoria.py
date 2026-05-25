"""Construye la presentacion TEORICA de la Sesion 17 (Machine Learning
e Inteligencia Artificial) para audiencia de preparatoria. Estilo Tec 4:3.
Requiere las figuras de img_teoria/ (generar antes con figs_s17.py).

Estructura: 7 secciones, ~40 slides."""
import os
from estilo_teoria import (
    nueva_presentacion, slide_portada, slide_agenda, slide_seccion,
    slide_concepto, slide_figura, slide_texto_figura, slide_pasos,
    slide_comparacion, slide_analogia, slide_alerta, slide_tabla,
    slide_conclusiones, slide_cierre, TEAL, PLUM, OCHRE, SOFT_TEAL, SOFT_OCHRE,
)
from estilo_teoria import DARK_GREEN, DARK_RED, NAVY, SOFT_GREEN, SOFT_RED

BASE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(BASE, "img_teoria")
OUT = os.path.join(BASE, "sesion_17_teoria_ml_ia.pptx")
FT = "Sesión 17 · Machine Learning e IA"
img = lambda n: os.path.join(IMG, n)

prs = nueva_presentacion()
n = 0


def sig():
    global n
    n += 1
    return n


# ===========================================================================
# 1. PORTADA
# ===========================================================================
slide_portada(
    prs,
    "Machine Learning\ne Inteligencia Artificial",
    "Sesión 17 · Cómo las computadoras aprenden de datos para tomar decisiones",
    "Tecnológico de Monterrey  ·  TC2001B.601 Ciencia de datos\n"
    "Prof. Jorge Juvenal Campos Ferreira")

# ===========================================================================
# 2. AGENDA
# ===========================================================================
slide_agenda(prs, "Lo que veremos hoy", [
    "¿Qué es la Inteligencia Artificial?",
    "¿Cómo aprende una máquina?",
    "Clasificación vs regresión a fondo",
    "El flujo de un proyecto de ciencia de datos",
    "¿Cómo se mide un modelo de regresión?",
    "Sobreajuste y honestidad",
    "La IA generativa como copiloto",
], sig(), FT)

# ===========================================================================
# SECCIÓN 1 — ¿Qué es la Inteligencia Artificial?
# ===========================================================================
slide_seccion(prs, 1,
              "¿Qué es la\nInteligencia Artificial?",
              "IA, Machine Learning y aprendizaje profundo")

slide_figura(
    prs,
    "IA, Machine Learning y aprendizaje profundo",
    img("01_circulos_ia.png"), sig(), FT,
    caption="El ML es un subconjunto de la IA; el aprendizaje profundo es "
            "un subconjunto del ML.",
    nota="Cuando escuchas 'IA', casi siempre se habla de Machine Learning. "
         "Cuando escuchas 'redes neuronales', es aprendizaje profundo.")

slide_concepto(
    prs,
    "¿Qué es la Inteligencia Artificial?",
    "La IA es el campo de la computación que busca crear sistemas capaces de "
    "realizar tareas que normalmente requieren inteligencia humana: entender "
    "texto, reconocer imágenes, traducir idiomas, recomendar películas o "
    "detectar fraudes.",
    sig(), FT,
    en_cristiano="La IA es enseñarle a una computadora a hacer cosas que "
                 "antes solo podía hacer un humano.")

slide_analogia(
    prs,
    "Ejemplos de IA en tu vida cotidiana",
    "Filtro de spam: tu correo aprende cuáles mensajes son basura.\n\n"
    "Recomendaciones: Netflix sugiere series según lo que ya viste.\n\n"
    "Asistentes de voz: Siri o Google entienden tu pregunta hablada.\n\n"
    "Autocompletado: el teclado adivina la siguiente palabra.\n\n"
    "Reconocimiento de cara: tu teléfono sabe que eres tú.",
    sig(), FT,
    color=TEAL, fill=SOFT_TEAL,
    etiqueta="IA que ya usas todos los días")

slide_concepto(
    prs,
    "¿Qué es el Machine Learning?",
    "El Machine Learning (aprendizaje automático) es una rama de la IA donde "
    "los sistemas APRENDEN de datos, sin que el programador escriba reglas "
    "explícitas. En vez de programar 'si tiene fiebre y tos, es gripe', el "
    "modelo extrae ese patrón solo a partir de miles de casos.",
    sig(), FT,
    en_cristiano="En lugar de darle reglas a la computadora, le damos "
                 "muchos ejemplos y ella descubre las reglas sola.")

slide_tabla(
    prs,
    "IA tradicional vs Machine Learning",
    ["", "IA tradicional (reglas)", "Machine Learning"],
    [
        ["¿Quién escribe las reglas?",
         "El programador, a mano",
         "El modelo las aprende de los datos"],
        ["¿Qué pasa con casos nuevos?",
         "Si no está en las reglas, falla",
         "Generaliza si aprendió bien"],
        ["¿Qué necesita?",
         "Expertos que conozcan el dominio",
         "Muchos datos etiquetados"],
        ["Ejemplo",
         "Árbol de decisión de crédito\nhecho por analistas",
         "KNN que aprende de solicitudes\npasadas"],
    ],
    sig(), FT,
    intro="La diferencia clave: reglas escritas a mano vs patrones "
          "aprendidos de datos.")

# ===========================================================================
# SECCIÓN 2 — ¿Cómo aprende una máquina?
# ===========================================================================
slide_seccion(prs, 2,
              "¿Cómo aprende\nuna máquina?",
              "De datos a patrones: los tres tipos de aprendizaje")

slide_figura(
    prs,
    "Tres tipos de aprendizaje automático",
    img("02_tres_tipos.png"), sig(), FT,
    caption="Supervisado, no supervisado y por refuerzo: tres formas de "
            "aprender.",
    nota="En este curso usamos aprendizaje SUPERVISADO: tenemos datos con "
         "la respuesta ya conocida y entrenamos el modelo con ellos.")

slide_concepto(
    prs,
    "Aprendizaje supervisado",
    "El modelo aprende de ejemplos donde YA conocemos la respuesta. Cada "
    "dato de entrenamiento tiene una 'etiqueta': la respuesta correcta. "
    "El modelo ajusta sus parámetros para predecir bien esas etiquetas y "
    "luego generaliza a casos nuevos.",
    sig(), FT,
    en_cristiano="Es como estudiar con un solucionario: ves el problema "
                 "Y la respuesta. Después resuelves problemas nuevos solito.")

slide_comparacion(
    prs,
    "Aprendizaje no supervisado y por refuerzo",
    {
        "titulo": "No supervisado",
        "color": TEAL,
        "fill": SOFT_TEAL,
        "body": "Los datos NO traen etiqueta.\n\n"
                "El modelo busca estructura: "
                "grupos naturales (clustering), "
                "patrones ocultos, "
                "reducción de dimensiones.\n\n"
                "Ejemplo: agrupar clientes "
                "sin saber de antemano sus categorías."
    },
    {
        "titulo": "Por refuerzo",
        "color": OCHRE,
        "fill": SOFT_OCHRE,
        "body": "Un agente aprende por prueba y "
                "error: recibe premios cuando "
                "acierta y castigos cuando falla.\n\n"
                "Ejemplo: el modelo de ajedrez "
                "AlphaGo aprendió solo jugando "
                "millones de partidas contra sí mismo."
    },
    sig(), FT,
    intro="Ambos tipos existen, pero en este curso nos centramos en "
          "el aprendizaje supervisado.")

slide_analogia(
    prs,
    "Analogía: aprender a cocinar",
    "Supervisado: cocinas siguiendo una receta con foto del resultado "
    "esperado. Después de muchas recetas, ya sabes improvisar.\n\n"
    "No supervisado: entras a una cocina llena de ingredientes sin receta "
    "y los agrupas por tipo (frutas, verduras, carnes).\n\n"
    "Por refuerzo: cocinas, pruebas, ajustas. Si sabe rico, repites; "
    "si sabe mal, cambias.",
    sig(), FT,
    color=PLUM, fill=SOFT_OCHRE,
    etiqueta="Piénsalo así")

# ===========================================================================
# SECCIÓN 3 — Clasificación vs regresión
# ===========================================================================
slide_seccion(prs, 3,
              "Clasificación vs\nregresión a fondo",
              "Los dos problemas del día: seguro de vida y costo médico")

slide_figura(
    prs,
    "Clasificación vs regresión: la diferencia central",
    img("03_clasif_regresion.png"), sig(), FT,
    caption="La respuesta que buscamos cambia el tipo de problema y el "
            "modelo que usamos.",
    nota="Clasificación: predecir una CATEGORÍA (aprobada / no aprobada). "
         "Regresión: predecir un NÚMERO (costo médico en pesos).")

slide_concepto(
    prs,
    "Problema 1: seguro de vida (clasificación)",
    "Una aseguradora recibe 880 solicitudes de póliza de seguro de vida. "
    "Para cada solicitante conocemos: edad, sexo, IMC, si fuma, padecimientos "
    "previos, presión, colesterol, antecedentes familiares y región.\n\n"
    "Queremos predecir: ¿se aprobará esta póliza? (sí / no)",
    sig(), FT,
    en_cristiano="Tenemos el expediente médico de 880 personas y sabemos "
                 "cuáles ya fueron aprobadas. Queremos aprender ese patrón "
                 "para clasificar casos nuevos.")

slide_concepto(
    prs,
    "Problema 2: costo médico anual (regresión)",
    "Una aseguradora médica tiene datos de 1,050 pacientes: edad, sexo, IMC, "
    "hijos, si fuma, región, actividad física y número de consultas.\n\n"
    "Queremos predecir: ¿cuánto costará médicamente este paciente al año? "
    "(entre $6,000 y $320,000 MXN)",
    sig(), FT,
    en_cristiano="Ya sabemos el costo de 1,050 pacientes del año pasado. "
                 "Queremos predecir el costo de pacientes nuevos para "
                 "planear el presupuesto de la aseguradora.")

slide_figura(
    prs,
    "El principal predictor: ¿fumas?",
    img("11_fumador_costo.png"), sig(), FT,
    caption="Los fumadores generan costos médicos mucho más altos que "
            "los no fumadores.",
    nota="Esta variable sola separa claramente los costos. Un buen modelo "
         "debe capturar este patrón.",
    fuente="Dataset regresion/datos.csv — 1,050 pacientes simulados.")

# ===========================================================================
# SECCIÓN 4 — El flujo de un proyecto de ciencia de datos
# ===========================================================================
slide_seccion(prs, 4,
              "El flujo de un\nproyecto de ML",
              "Datos -> Preparar -> Entrenar -> Evaluar -> Usar")

slide_figura(
    prs,
    "De los datos a la decisión: el flujo completo",
    img("04_flujo_ml.png"), sig(), FT,
    caption="Cada paso depende del anterior; saltarse uno arruina el "
            "resultado.",
    nota="El paso más importante NO es el modelo: es preparar bien los "
         "datos. 'Basura entra, basura sale'.")

slide_pasos(
    prs,
    "Paso 1: explorar y limpiar los datos",
    [
        ("Entender la variable objetivo",
         "¿Es categórica (clasificación) o numérica (regresión)? "
         "¿Está balanceada? ¿Tiene sesgo?"),
        ("Detectar valores faltantes (NAs)",
         "colesterol tiene ~5% de NAs; IMC tiene ~4%. "
         "Hay que imputarlos antes de modelar."),
        ("Revisar colinealidad",
         "Presión y colesterol están correlacionados con la edad. "
         "Variables redundantes pueden dañar el modelo."),
        ("Escala de las variables",
         "Edad en decenas, colesterol en cientos. Para KNN es crítico "
         "normalizar; sin eso la distancia es falsa."),
    ],
    sig(), FT,
    intro="Antes de entrenar cualquier modelo, hay que conocer los datos.")

slide_pasos(
    prs,
    "Paso 2: preparar (receta de preprocesamiento)",
    [
        ("Imputar NAs",
         "Rellenar valores faltantes con la mediana. Va primero "
         "porque los pasos siguientes no toleran huecos."),
        ("Quitar varianza casi nula",
         "Predictores que casi no cambian no ayudan a distinguir casos."),
        ("Filtrar redundantes",
         "Quitar variables con correlación > 0.7 para no contar lo "
         "mismo dos veces."),
        ("Normalizar",
         "Poner todas las variables en la misma escala (media 0, "
         "desv. 1). INDISPENSABLE para KNN."),
        ("Codificar categóricas",
         "Convertir texto (fumador: si/no) a números (0/1) para "
         "que el modelo los pueda usar."),
    ],
    sig(), FT,
    intro="El orden de los pasos importa: cada uno prepara el terreno "
          "para el siguiente.")

slide_pasos(
    prs,
    "Pasos 3 y 4: entrenar y evaluar",
    [
        ("Separar entrenamiento / prueba",
         "75% para que el modelo aprenda; 25% reservado como 'examen "
         "final' que el modelo NUNCA ve durante el entrenamiento."),
        ("Entrenar con validación cruzada",
         "Usar los datos de entrenamiento en 5 rondas para elegir el "
         "mejor hiperparámetro (k) con honestidad."),
        ("Elegir el mejor modelo",
         "El k con mejor desempeño en las 5 rondas de validación "
         "cruzada es el ganador."),
        ("Evaluación final honesta",
         "Abrir la 'caja fuerte' (base de prueba) una sola vez y "
         "medir el desempeño real del modelo."),
    ],
    sig(), FT,
    intro="Nunca se evalúa un modelo con los mismos datos con que aprendió.")

# ===========================================================================
# SECCIÓN 5 — ¿Cómo se mide un modelo de regresión?
# ===========================================================================
slide_seccion(prs, 5,
              "¿Cómo se mide un\nmodelo de regresión?",
              "Error, RMSE, MAE, R² y el problema del sesgo")

slide_figura(
    prs,
    "El error (residual): la distancia entre real y predicho",
    img("06_residuales.png"), sig(), FT,
    caption="Cada línea vertical es el error del modelo para un paciente.",
    nota="El objetivo del modelo es minimizar esos errores. Un error = 0 "
         "significa predicción perfecta (poco probable en la práctica).")

slide_figura(
    prs,
    "RMSE y MAE: dos formas de resumir el error",
    img("07_rmse_mae.png"), sig(), FT,
    caption="RMSE castiga más los errores grandes; MAE los trata "
            "por igual.",
    nota="Para el costo médico, el RMSE es más sensible a los pacientes "
         "muy caros (los outliers de la cola larga).")

slide_concepto(
    prs,
    "¿Qué es el RMSE?",
    "RMSE = Raíz del Error Cuadrático Medio.\n\n"
    "Se calcula elevando cada error al cuadrado, promediándolos y "
    "sacando la raíz. Por elevar al cuadrado, los errores grandes "
    "pesan MUCHO más que los chicos.\n\n"
    "Se mide en las mismas unidades que la variable objetivo "
    "(pesos, kilos, años...).",
    sig(), FT,
    en_cristiano="RMSE es como un promedio del error, pero los errores "
                 "grandes se castigan el doble. Un RMSE de $15,000 MXN "
                 "significa que en promedio te equivocas en 15 mil pesos.")

slide_figura(
    prs,
    "R²: ¿cuánta variación explica el modelo?",
    img("08_r2.png"), sig(), FT,
    caption="R² compara la variación sin modelo vs la variación que "
            "queda después del modelo.",
    nota="R² = 1.0 es predicción perfecta. R² = 0.0 significa que "
         "el modelo no ayuda nada. R² puede ser negativo si el modelo "
         "es peor que predecir siempre la media.")

slide_figura(
    prs,
    "El problema del sesgo: por qué transformamos el costo",
    img("05_histograma_costo.png"), sig(), FT,
    caption="A la derecha, unos pocos pacientes con costos altísimos "
            "distorsionan el modelo.",
    nota="Solución: modelar log(costo). En escala logarítmica la "
         "distribución es más simétrica y el modelo ajusta mejor.",
    fuente="Dataset regresion/datos.csv — 1,050 pacientes.")

slide_analogia(
    prs,
    "¿Por qué molesta el sesgo al modelo?",
    "Imagina que calculas el sueldo 'promedio' de tu salón: 29 alumnos "
    "ganan $5,000 y uno tiene un negocio y gana $500,000. "
    "El promedio da $21,700, que no representa a nadie.\n\n"
    "Con el costo médico pasa lo mismo: unos pocos pacientes muy caros "
    "jalan el promedio hacia arriba y confunden al modelo.\n\n"
    "Aplicar logaritmo 'aplana' la cola y le permite al modelo "
    "aprender el patrón real.",
    sig(), FT,
    color=TEAL, fill=SOFT_TEAL,
    etiqueta="Piénsalo así")

# ===========================================================================
# SECCIÓN 6 — Sobreajuste y honestidad
# ===========================================================================
slide_seccion(prs, 6,
              "Sobreajuste\ny honestidad",
              "Entrenar vs evaluar: la diferencia crucial")

slide_figura(
    prs,
    "El sobreajuste: memorizar en vez de aprender",
    img("09_sobreajuste.png"), sig(), FT,
    caption="Con k muy pequeño el modelo memoriza; con k muy grande "
            "simplifica demasiado.",
    nota="El error en datos NUEVOS es el que importa. El punto óptimo "
         "de k minimiza ese error, no el de entrenamiento.")

slide_concepto(
    prs,
    "Sobreajuste vs subajuste",
    "Sobreajuste (overfitting): el modelo aprende los datos de "
    "entrenamiento tan bien que hasta aprende el ruido aleatorio. "
    "Funciona perfecto en lo que ya vio, pero falla con datos nuevos.\n\n"
    "Subajuste (underfitting): el modelo es tan simple que no captura "
    "los patrones reales, ni en entrenamiento ni en datos nuevos.",
    sig(), FT,
    en_cristiano="Sobreajustar = aprenderte las preguntas del examen de "
                 "práctica al pie de la letra. Si el examen real cambia "
                 "una coma, repruebas. Subajustar = no estudiar nada.")

slide_pasos(
    prs,
    "Validación cruzada: elegir con honestidad",
    [
        ("Partir el entrenamiento en 5 bloques",
         "Nunca tocamos la base de prueba para elegir el mejor k."),
        ("Entrenar con 4 bloques, validar con 1",
         "El bloque de validación actúa como 'mini-examen'."),
        ("Rotar 5 veces",
         "Cada bloque es el de validación exactamente una vez."),
        ("Promediar las 5 puntuaciones",
         "El promedio da una estimación estable y honesta."),
        ("Elegir el k con mejor promedio",
         "Ese es el k ganador. Solo entonces abrimos la caja fuerte "
         "y evaluamos sobre la prueba."),
    ],
    sig(), FT,
    intro="La validación cruzada nos permite explorar muchos k sin "
          "contaminar la evaluación final.")

slide_alerta(
    prs,
    "La gran trampa: evaluar con los datos de entrenamiento",
    "Si calificamos el modelo con los mismos datos con que aprendió, "
    "siempre obtendrá una calificación perfecta o casi perfecta. "
    "¡Ya vio las respuestas!\n\n"
    "Es como darle al alumno el examen con las respuestas y luego "
    "decir que sacó 10. No prueba nada.\n\n"
    "La regla de oro: el conjunto de prueba se abre UNA SOLA VEZ, "
    "al final, para la evaluación definitiva.",
    sig(), FT,
    etiqueta="Error que NUNCA hay que cometer")

# ===========================================================================
# SECCIÓN 7 — La IA generativa como copiloto
# ===========================================================================
slide_seccion(prs, 7,
              "La IA generativa\ncomo copiloto",
              "Modelos de lenguaje, usos y límites")

slide_concepto(
    prs,
    "¿Qué es un modelo de lenguaje grande (LLM)?",
    "Un LLM (Large Language Model) es un modelo de ML entrenado con "
    "enormes volúmenes de texto para predecir la siguiente palabra. "
    "ChatGPT, Gemini y Claude son ejemplos. Generan texto convincente "
    "porque aprendieron patrones del lenguaje humano, no porque "
    "'entiendan' ni 'piensen'.",
    sig(), FT,
    en_cristiano="Un LLM es como un estudiante que leyó toda internet y "
                 "aprendió a continuar cualquier frase de manera coherente. "
                 "Es muy bueno para redactar, pero puede inventar datos.")

slide_figura(
    prs,
    "La IA generativa como copiloto: el flujo correcto",
    img("10_copiloto.png"), sig(), FT,
    caption="Tú preguntas, el modelo sugiere, TÚ verificas y decides.",
    nota="El modelo puede estar equivocado o desactualizado. Quien "
         "toma la decisión final SIEMPRE eres tú.")

slide_comparacion(
    prs,
    "¿Para qué SÍ y para qué NO usar un LLM en ciencia de datos?",
    {
        "titulo": "Sí ayuda",
        "color": DARK_GREEN,
        "fill": SOFT_GREEN,
        "body": "Explicar un concepto con\n"
                "otras palabras.\n\n"
                "Sugerir código en R o Python\n"
                "que luego debes verificar.\n\n"
                "Revisar ortografía y redacción\n"
                "de reportes.\n\n"
                "Generar ideas de visualizaciones\n"
                "o estructura de análisis."
    },
    {
        "titulo": "No reemplaza",
        "color": DARK_RED,
        "fill": SOFT_RED,
        "body": "Inventar datos que no tienes.\n\n"
                "Verificar si un resultado\n"
                "estadístico es correcto.\n\n"
                "Decidir en lugar de ti.\n\n"
                "Garantizar que el código\n"
                "funcione (puede haber errores\n"
                "sutiles que hay que revisar)."
    },
    sig(), FT,
    intro="Un LLM es un asistente poderoso, no un oráculo infalible.")

slide_alerta(
    prs,
    "Ética y buenas prácticas al usar IA generativa",
    "No inventes datos: si no tienes el dato, escribe "
    "'dato no disponible'. Inventar datos es fraude.\n\n"
    "No copies código sin entenderlo: si no sabes qué hace, "
    "no lo uses. Puede tener errores ocultos.\n\n"
    "Cita si usaste IA: en trabajos académicos menciona "
    "qué usaste y qué verificaste.\n\n"
    "Los sesgos se heredan: si los datos del LLM tienen "
    "sesgos, sus respuestas también.",
    sig(), FT,
    etiqueta="Buenas prácticas")

slide_tabla(
    prs,
    "Resumen: conceptos clave de la sesión",
    ["Concepto", "¿Qué es?", "Ejemplo en la sesión"],
    [
        ["Machine Learning",
         "Aprender patrones de datos sin\nprogramar reglas explícitas",
         "KNN que aprende de 880\nsolicitudes de seguro"],
        ["Clasificación",
         "Predecir una categoría",
         "Aprobada: sí / no"],
        ["Regresión",
         "Predecir un número continuo",
         "Costo médico anual (MXN)"],
        ["RMSE / MAE",
         "Métricas de error en regresión",
         "Error en pesos del costo predicho"],
        ["R²",
         "Proporción de variación explicada",
         "¿Qué tanto explica el modelo?"],
        ["Sobreajuste",
         "Memorizar en vez de generalizar",
         "k=1 en KNN"],
        ["LLM",
         "Modelo de lenguaje grande (IA generativa)",
         "ChatGPT, Claude, Gemini"],
    ],
    sig(), FT)

# ===========================================================================
# CONCLUSIONES
# ===========================================================================
slide_conclusiones(prs, "Conclusiones", "\n".join("•  " + t for t in [
    "La IA incluye al Machine Learning; el ML aprende de datos sin "
    "reglas escritas a mano.",
    "Clasificación predice categorías; regresión predice números: "
    "son los dos problemas del día.",
    "El flujo completo es: datos -> preparar -> entrenar -> evaluar "
    "-> usar. El orden importa.",
    "RMSE castiga errores grandes; MAE los trata igual. R² mide la "
    "proporción de variación explicada.",
    "La variable objetivo sesgada se transforma con logaritmo para "
    "mejorar el ajuste del modelo.",
    "Sobreajustar es memorizar; la validación cruzada permite elegir "
    "el modelo con honestidad.",
    "Los LLM son copilotos poderosos: siempre verifica antes de "
    "aceptar su respuesta.",
]), sig(), FT)

# ===========================================================================
# CIERRE
# ===========================================================================
slide_cierre(prs)

prs.save(OUT)
print(f"Guardado: {OUT} | slides: {len(prs.slides._sldIdLst)}")
