"""Construye la presentacion TEORICA de la Sesion 19 (Aprendizaje no
supervisado: PCA y clustering) para audiencia de primeros anios de
licenciatura. PCA primero, luego clustering. Estilo Tec 4:3.
Requiere las figuras de img_teoria/ (generar con figs_s19.py antes)."""
import os
from pptx.util import Inches, Pt
from pptx.enum.text import MSO_ANCHOR

from estilo_teoria import (
    nueva_presentacion, slide_portada, slide_agenda, slide_seccion,
    slide_concepto, slide_figura, slide_texto_figura, slide_pasos,
    slide_comparacion, slide_analogia, slide_alerta, slide_tabla,
    slide_conclusiones, slide_cierre, add_picture_fit, add_fuente,
    TEAL, PLUM, OCHRE, SOFT_TEAL, SOFT_OCHRE,
)
from estilo_tec import (
    _blank, add_bg, add_header, add_card, add_footer, add_text,
    NAVY, LIGHT_BLUE, HIGHLIGHT_GREEN, DARK_GREEN, GRAY, WHITE, UBUNTU,
)

BASE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(BASE, "img_teoria")
OUT = os.path.join(BASE, "sesion_19_teoria_no_supervisado.pptx")
FT = "Sesión 19 · Aprendizaje no supervisado"
img = lambda n: os.path.join(IMG, n)

prs = nueva_presentacion()
n = 0


def sig():
    global n
    n += 1
    return n


def slide_formula(prs, titulo, formula_img, explicacion, footer_num,
                  footer_txt, *, intro=None, etiqueta="Qué significa"):
    """Fórmula como imagen prominente + tarjeta de explicación abajo."""
    s = _blank(prs)
    add_bg(s, prs)
    add_header(s, titulo, width_in=9.4, font=UBUNTU, size=22)
    y0 = 1.3
    if intro:
        add_text(s, intro, Inches(0.4), Inches(1.2), Inches(9.2), Inches(0.6),
                 size=14, color=NAVY, italic=True, line_spacing=1.2)
        y0 = 1.95
    add_picture_fit(s, formula_img, Inches(0.7), Inches(y0), Inches(8.6),
                    Inches(2.2))
    add_card(s, Inches(0.3), Inches(y0 + 2.45), Inches(9.4),
             Inches(6.55 - (y0 + 2.45)), fill=HIGHLIGHT_GREEN,
             title=etiqueta, body=explicacion, title_color=DARK_GREEN,
             title_size=16, body_size=14, line_spacing=1.35)
    add_footer(s, footer_num, footer_txt)
    return s


# ===========================================================================
# 1. Portada
# ===========================================================================
slide_portada(
    prs,
    "Aprendizaje no supervisado:\nPCA y clustering",
    "Sesión 19 · Descubrir estructura en los datos sin respuestas previas",
    "Tecnológico de Monterrey  ·  TC2001B.601 Ciencia de datos\n"
    "Prof. Jorge Juvenal Campos Ferreira")

# ===========================================================================
# 2. Agenda
# ===========================================================================
slide_agenda(prs, "Lo que veremos hoy", [
    "Aprender SIN respuestas: ¿qué es?",
    "PCA: el problema de muchas variables",
    "PCA: la idea y su matemática",
    "Estandarizar y leer la varianza",
    "Clustering: agrupar lo parecido",
    "K-means paso a paso",
    "¿Cuántos grupos? Codo y silueta",
    "Jerárquico, perfiles y aplicaciones",
], sig(), FT)

# ===========================================================================
# SECCIÓN 1 — Aprender sin respuestas
# ===========================================================================
slide_seccion(prs, 1, "Aprender SIN\nrespuestas",
              "¿Qué hacemos cuando no hay etiquetas?")

slide_concepto(
    prs, "Supervisado vs no supervisado",
    "En el aprendizaje SUPERVISADO cada ejemplo trae una etiqueta o respuesta:\n"
    "\"este crédito se pagó\", \"este correo es spam\". El modelo aprende a\n"
    "predecir esa respuesta.\n\n"
    "En el aprendizaje NO SUPERVISADO NO hay respuesta. El algoritmo recibe\n"
    "solo los datos y debe DESCUBRIR su estructura por sí solo: grupos\n"
    "naturales, patrones o las dimensiones que de verdad importan.",
    sig(), FT,
    en_cristiano="Es como llegar a una fiesta sin conocer a nadie y, solo "
                 "observando, darte cuenta de que la gente se junta en grupos: "
                 "no te dieron la lista de grupos, la descubriste tú.")

slide_figura(
    prs, "Supervisado vs no supervisado",
    img("01_supervisado_vs_no.png"), sig(), FT,
    caption="Izquierda: las etiquetas se conocen. Derecha: no hay etiquetas; se descubren.",
    nota="No supervisado = aprender SIN respuestas correctas. Solo hay datos y "
         "buscamos la estructura escondida. No se parte en entrenamiento/prueba: "
         "no hay un acierto que medir.")

slide_texto_figura(
    prs, "¿Para qué sirve descubrir estructura?",
    "Dos grandes familias de técnicas no supervisadas que veremos hoy:",
    "PCA (reducir dimensiones)\n"
    "• Resume muchas variables en pocas.\n"
    "• Sirve para VISUALIZAR y para quitar redundancia.\n\n"
    "Clustering (agrupar)\n"
    "• Encuentra grupos de observaciones parecidas.\n"
    "• Sirve para SEGMENTAR: clientes, municipios, pacientes.\n\n"
    "Ejemplos: segmentar usuarios, detectar fraude o anomalías, "
    "tipologías de municipios, comprimir imágenes.",
    img("15_flujo_completo.png"), sig(), FT, img_side="right",
    caption="A menudo se combinan: primero PCA, luego clustering.",
    puntos_size=13)

# ===========================================================================
# SECCIÓN 2 — PCA
# ===========================================================================
slide_seccion(prs, 2, "PCA", "Componentes principales: resumir sin perder lo esencial")

slide_figura(
    prs, "El problema: demasiadas variables",
    img("08_dimension.png"), sig(), FT,
    caption="Con muchas variables no podemos graficar ni ver patrones a simple vista.",
    nota="Con 12 variables hay 66 posibles pares de ejes para graficar: imposible "
         "de inspeccionar. PCA busca POCOS ejes nuevos que concentren casi toda "
         "la información.")

slide_analogia(
    prs, "La idea de PCA, en una analogía",
    "Imagina las calificaciones de 6 materias de cada alumno. En lugar de "
    "cargar las 6, podrías resumirlas en 2 números: un \"perfil de ciencias\" "
    "y un \"perfil de humanidades\".\n\n"
    "Pierdes algún detalle, pero conservas casi toda la información con muchos "
    "menos números. ESO hace PCA: crea \"resúmenes\" (componentes) que combinan "
    "las variables originales.",
    sig(), FT, img=img("10_analogia_pca.png"),
    etiqueta="Piénsalo así")

slide_figura(
    prs, "¿Qué es una componente principal?",
    img("09_pca_idea.png"), sig(), FT,
    caption="La 1ª componente es la dirección en la que la nube de puntos más se estira.",
    nota="PCA gira los ejes: el nuevo eje 1 (CP1) apunta hacia donde los datos "
         "tienen MÁS variación; el CP2 hacia la segunda dirección con más "
         "variación, perpendicular al primero, y así sucesivamente.")

slide_formula(
    prs, "PCA: el fundamento matemático (1)",
    img("f_pca_var.png"),
    "Cada componente es una combinación lineal de las variables. La PRIMERA "
    "componente busca los pesos (φ) que MAXIMIZAN la varianza de los datos "
    "proyectados, con la restricción de que los pesos al cuadrado sumen 1 "
    "(para que el problema tenga solución única). En palabras: ¿qué mezcla de "
    "variables separa más a las observaciones?",
    sig(), FT,
    intro="Maximizar varianza = capturar la mayor cantidad de información posible.")

slide_formula(
    prs, "PCA: el fundamento matemático (2)",
    img("f_pc1.png"),
    "Así se calcula el VALOR de la 1ª componente para la observación i: se "
    "multiplican sus variables por los pesos φ y se suman. φ_j1 (la 'carga') "
    "dice cuánto pesa la variable j en esta componente. Cargas grandes (en "
    "valor absoluto) = variables que definen el eje. El signo indica la "
    "dirección. Leer las cargas es cómo INTERPRETAMOS qué significa cada "
    "componente.",
    sig(), FT)

slide_formula(
    prs, "Antes de PCA: estandarizar (z-score)",
    img("f_estandarizar.png"),
    "PCA maximiza varianza, y la varianza depende de las UNIDADES. Si una "
    "variable está en pesos (miles) y otra en porcentaje (0–100), la primera "
    "dominaría solo por su escala. El z-score resta la media y divide entre la "
    "desviación: deja cada variable con media 0 y desviación 1. Así todas "
    "compiten en igualdad.",
    sig(), FT,
    intro="Regla de oro: estandariza SIEMPRE antes de PCA (y antes de clustering).")

slide_figura(
    prs, "Estandarizar: por qué importa",
    img("06_estandarizar.png"), sig(), FT,
    caption="Sin estandarizar, la variable de números grandes manda; con z-score, todas pesan igual.",
    nota="La misma nube se ve distinta según la escala. Estandarizar evita que "
         "la elección de unidades (pesos, miles, %) decida el resultado.")

slide_formula(
    prs, "¿Cuántas componentes conservar?",
    img("f_pve.png"),
    "Cada componente explica una fracción de la varianza total (PVE = "
    "Proportion of Variance Explained). Las primeras componentes explican "
    "mucho; las últimas, casi nada. Conservamos las primeras hasta acumular "
    "un buen porcentaje (p. ej. 70–80%). El 'scree plot' grafica esto y "
    "buscamos el 'codo'.",
    sig(), FT, etiqueta="Qué significa")

slide_figura(
    prs, "Scree plot: la varianza explicada",
    img("11_scree.png"), sig(), FT,
    caption="Datos reales de apostadores: las barras son el % por componente; la línea, el acumulado.",
    nota="Aquí las primeras 2–3 componentes ya acumulan gran parte de la "
         "información: podemos graficar las cuentas en 2D casi sin perder nada.")

slide_figura(
    prs, "PCA en acción: visualizar en 2D",
    img("12_biplot_apostadores.png"), sig(), FT,
    caption="Las 500 cuentas, originalmente con 12 variables, proyectadas en 2 componentes.",
    nota="Reducir a 2 componentes nos deja VER la estructura: ya se distinguen "
         "agrupamientos de cuentas. PCA + color por grupo = mapa interpretable.")

slide_comparacion(
    prs, "¿Para qué sirve PCA en la práctica?",
    {"titulo": "Usos típicos", "fill": LIGHT_BLUE, "color": NAVY,
     "body": "• Visualizar datos de muchas variables en 2D.\n\n"
             "• Quitar redundancia (variables muy correlacionadas).\n\n"
             "• Comprimir información (imágenes, señales).\n\n"
             "• Preprocesar antes de otro modelo."},
    {"titulo": "Cosas a recordar", "fill": SOFT_OCHRE, "color": OCHRE,
     "body": "• Las componentes son COMBINACIONES, no variables originales.\n\n"
             "• Hay que interpretarlas leyendo las cargas.\n\n"
             "• Estandarizar primero es obligatorio.\n\n"
             "• PCA no agrupa: solo reordena los ejes."},
    sig(), FT)

# ===========================================================================
# SECCIÓN 3 — Clustering
# ===========================================================================
slide_seccion(prs, 3, "Clustering",
              "Agrupar observaciones parecidas sin etiquetas")

slide_concepto(
    prs, "¿Qué es agrupar (clustering)?",
    "Clustering busca partir las observaciones en GRUPOS (clusters) tales que:\n"
    "• los miembros de un mismo grupo se parezcan mucho entre sí, y\n"
    "• grupos distintos sean lo más diferentes posible.\n\n"
    "Nadie nos dice cuántos grupos hay ni quién pertenece a cuál: el algoritmo "
    "lo propone a partir de las distancias entre observaciones.",
    sig(), FT,
    en_cristiano="Como ordenar tu música en playlists sin que nadie te diga las "
                 "categorías: juntas las canciones que 'suenan parecido'.")

slide_figura(
    prs, "Antes y después de agrupar",
    img("02_antes_despues.png"), sig(), FT,
    caption="Mismos puntos: a la izquierda sin grupos; a la derecha, agrupados por similitud.",
    nota="El algoritmo no inventa la estructura: la encuentra si existe. Si los "
         "datos no tienen grupos naturales, igual los partirá (hay que tener cuidado).")

slide_formula(
    prs, "¿Qué tan 'parecidos'? La distancia",
    img("f_distancia.png"),
    "Para agrupar necesitamos medir parecido. La medida más común es la "
    "distancia euclidiana: la distancia 'en línea recta' entre dos "
    "observaciones, sumando las diferencias al cuadrado de cada variable. "
    "Cerca = parecidos; lejos = distintos. Como suma todas las variables, "
    "¡otra vez hay que estandarizar primero!",
    sig(), FT)

slide_figura(
    prs, "K-means paso a paso",
    img("03_kmeans_pasos.png"), sig(), FT,
    caption="Elegimos K, colocamos centroides, asignamos, movemos, repetimos.",
    nota="K-means alterna dos pasos —asignar cada punto a su centroide más "
         "cercano y mover cada centroide al promedio de su grupo— hasta que "
         "ya no cambian. Hay que decidir K de antemano.")

slide_formula(
    prs, "K-means: qué optimiza",
    img("f_kmeans.png"),
    "K-means busca la partición en K grupos que MINIMIZA la suma de distancias "
    "al cuadrado de cada punto a su centroide (la 'inercia' o WSS). Es decir: "
    "grupos lo más compactos posible. El algoritmo no garantiza la solución "
    "perfecta (puede caer en un óptimo local), por eso se prueba con varios "
    "arranques aleatorios (nstart) y se queda con el mejor.",
    sig(), FT, etiqueta="Qué significa")

slide_pasos(
    prs, "Elegir K: dos diagnósticos",
    [("Método del codo", "Grafica la inercia (WSS) contra K. Siempre baja al "
      "subir K; buscamos el 'codo': el K donde deja de bajar rápido."),
     ("Método de la silueta", "Mide qué tan cómodo está cada punto en su grupo "
      "vs. el grupo vecino. Va de -1 a 1; elegimos el K con silueta promedio "
      "MÁS ALTA."),
     ("Y el sentido común", "Los diagnósticos son guías, no veredictos. El K "
      "elegido debe dar grupos INTERPRETABLES y útiles para la decisión.")],
    sig(), FT,
    intro="K-means necesita que fijemos K. No lo elegimos 'a ojo': usamos datos.")

slide_comparacion(
    prs, "Codo y silueta",
    {"titulo": "Método del codo", "img": img("04_codo.png"),
     "fill": LIGHT_BLUE, "color": NAVY,
     "body": "Busca dónde la curva 'se dobla'. A partir de ahí, más grupos "
             "casi no reducen la inercia."},
    {"titulo": "Método de la silueta", "img": img("05_silueta.png"),
     "fill": SOFT_TEAL, "color": TEAL,
     "body": "Elige la K con el valor más alto. Mide separación entre grupos, "
             "no solo compacidad."},
    sig(), FT)

slide_formula(
    prs, "La silueta, con más detalle",
    img("f_silueta.png"),
    "Para cada punto: a(i) = distancia promedio a los de SU grupo; b(i) = "
    "distancia promedio al grupo vecino más cercano. Si b >> a, el punto está "
    "bien clasificado y s(i) se acerca a 1. Si s(i) es negativo, el punto "
    "estaría mejor en otro grupo. Promediamos s(i) sobre todos los puntos.",
    sig(), FT, etiqueta="Qué significa")

slide_texto_figura(
    prs, "Clustering jerárquico",
    "Una alternativa que NO exige fijar K de antemano.",
    "Cómo funciona\n"
    "• Empieza con cada punto solo.\n"
    "• Fusiona los dos más cercanos.\n"
    "• Repite hasta tener un solo grupo.\n\n"
    "El resultado es un ÁRBOL (dendrograma). Lo 'cortamos' a cierta altura "
    "para obtener el número de grupos que queramos.\n\n"
    "El método de enlace 'Ward' tiende a formar grupos compactos y de tamaño "
    "parecido, comparable con k-means.",
    img("07_dendrograma.png"), sig(), FT, img_side="right",
    caption="Cada fusión es una rama; la altura es la distancia a la que se unieron.",
    puntos_size=13)

slide_figura(
    prs, "Perfilar: dar significado a los grupos",
    img("14_perfiles_apostadores.png"), sig(), FT,
    caption="Promedio de variables clave por grupo de apostadores (datos del ejercicio 1).",
    nota="El algoritmo da grupos SIN nombre. Los nombramos comparando sus "
         "promedios: 'recreativo', 'en riesgo', 'gran apostador'… El perfilado "
         "es el paso que convierte números en decisiones.")

slide_figura(
    prs, "Ejemplo completo: tipologías de municipios",
    img("13_biplot_municipios.png"), sig(), FT,
    caption="400 municipios resumidos con PCA y agrupados en 4 tipologías con k-means.",
    nota="Aquí PCA + clustering revelan 4 tipologías claras (desarrollo × "
         "estructura económica). Cada una pide una política distinta: la "
         "segmentación guía la intervención.")

# ===========================================================================
# SECCIÓN 4 — Juntar todo y advertencias
# ===========================================================================
slide_seccion(prs, 4, "En conjunto",
              "El flujo completo y los errores que evitar")

slide_figura(
    prs, "El flujo de trabajo, de principio a fin",
    img("15_flujo_completo.png"), sig(), FT,
    caption="Estandarizar → (PCA para ver) → clustering → perfilar y nombrar.",
    nota="PCA y clustering se complementan: PCA nos deja VER y quitar "
         "redundancia; el clustering AGRUPA. Juntos producen perfiles con "
         "significado.")

slide_alerta(
    prs, "Errores comunes (¡cuidado!)",
    "• NO estandarizar: la variable de números grandes domina y los grupos "
    "reflejan solo las unidades.\n\n"
    "• Creer que hay UNA respuesta correcta: sin etiquetas, no hay 'acierto'. "
    "Distintos métodos o K dan distintos grupos.\n\n"
    "• Forzar grupos donde no los hay: el algoritmo SIEMPRE devuelve grupos, "
    "aunque los datos no tengan estructura real.\n\n"
    "• No interpretar: un cluster sin nombre ni perfil no sirve para decidir.",
    sig(), FT, etiqueta="Errores comunes")

slide_tabla(
    prs, "PCA vs Clustering: en resumen",
    ["", "PCA", "Clustering"],
    [["¿Qué hace?", "Resume variables en componentes", "Agrupa observaciones"],
     ["¿Sobre qué actúa?", "Las columnas (variables)", "Las filas (observaciones)"],
     ["Resultado", "Nuevos ejes (componentes)", "Etiqueta de grupo por fila"],
     ["¿Hay que estandarizar?", "Sí", "Sí"],
     ["Uso típico", "Visualizar, comprimir", "Segmentar, perfilar"]],
    sig(), FT,
    intro="Son técnicas distintas y complementarias, no rivales.",
    col_widths=[2.3, 3.55, 3.55])

# ===========================================================================
# Conclusiones y cierre
# ===========================================================================
slide_conclusiones(prs, "Conclusiones",
    "• No supervisado = descubrir estructura SIN etiquetas; no hay acierto que "
    "medir.\n\n"
    "• PCA resume muchas variables en pocas componentes que concentran la "
    "varianza; sirve para visualizar e interpretar (leyendo las cargas).\n\n"
    "• Clustering agrupa observaciones parecidas: k-means minimiza la inercia y "
    "el jerárquico construye un árbol (dendrograma).\n\n"
    "• Estandarizar SIEMPRE antes de PCA y clustering: las distancias y la "
    "varianza dependen de la escala.\n\n"
    "• Elegir K con codo y silueta, pero validar que los grupos sean "
    "interpretables y útiles para la decisión.",
    sig(), FT)

slide_cierre(prs)

prs.save(OUT)
print("Presentacion teorica S19 guardada:", OUT, "·", n, "slides de contenido")
