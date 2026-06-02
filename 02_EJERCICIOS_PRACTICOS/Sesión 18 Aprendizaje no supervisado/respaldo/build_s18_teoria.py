"""Construye la presentacion TEORICA de la Sesion 18 (Aprendizaje no
supervisado: clustering y PCA) para audiencia de preparatoria.
Estilo Tec 4:3. Requiere las figuras de img_teoria/ (generar con
figs_s18.py antes de ejecutar este script)."""
import os
from estilo_teoria import (
    nueva_presentacion, slide_portada, slide_agenda, slide_seccion,
    slide_concepto, slide_figura, slide_texto_figura, slide_pasos,
    slide_comparacion, slide_analogia, slide_alerta, slide_conclusiones,
    slide_cierre, TEAL, PLUM, OCHRE, SOFT_TEAL, SOFT_OCHRE,
)
from estilo_teoria import (
    DARK_GREEN, DARK_RED, NAVY, SOFT_GREEN, SOFT_RED, LIGHT_BLUE,
)

BASE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(BASE, "img_teoria")
OUT = os.path.join(BASE, "sesion_18_teoria_no_supervisado.pptx")
FT = "Sesión 18 · Aprendizaje no supervisado"
img = lambda n: os.path.join(IMG, n)

prs = nueva_presentacion()
n = 0


def sig():
    global n
    n += 1
    return n


# ===========================================================================
# 1. Portada
# ===========================================================================
slide_portada(
    prs,
    "Aprendizaje no supervisado:\nclustering y PCA",
    "Sesión 18 · Descubrir patrones ocultos sin respuestas previas",
    "Tecnológico de Monterrey  ·  TC2001B.601 Ciencia de datos\n"
    "Prof. Jorge Juvenal Campos Ferreira")

# ===========================================================================
# 2. Agenda
# ===========================================================================
slide_agenda(prs, "Lo que veremos hoy", [
    "Aprender SIN respuestas: no supervisado",
    "Clustering: agrupar lo parecido",
    "K-means paso a paso",
    "¿Cuántos grupos elegir? (método del codo)",
    "Estandarizar antes de agrupar",
    "El problema de la dimensión",
    "PCA: comprimir información",
    "PCA + clustering sobre datos reales",
], sig(), FT)

# ===========================================================================
# SECCION 1: Aprender sin respuestas
# ===========================================================================
slide_seccion(prs, 1, "Aprender SIN\nrespuestas",
              "¿Qué hacemos cuando no hay etiquetas?")

slide_concepto(
    prs, "Supervisado vs no supervisado",
    "En el aprendizaje SUPERVISADO, cada ejemplo lleva una etiqueta:\n"
    "\"esta solicitud fue aprobada\", \"este correo es spam\".\n\n"
    "En el aprendizaje NO SUPERVISADO no hay etiquetas. El algoritmo\n"
    "recibe los datos y debe DESCUBRIR la estructura por sí solo:\n"
    "grupos, patrones, dimensiones relevantes.",
    sig(), FT,
    en_cristiano="Es como ordenar tu música en playlists sin que nadie\n"
                 "te diga las categorías: la computadora escucha las\n"
                 "canciones y las agrupa por similitud.")

slide_figura(
    prs, "Supervisado vs no supervisado",
    img("01_supervisado_vs_no.png"), sig(), FT,
    caption="Izquierda: etiquetas conocidas. Derecha: el algoritmo las descubre.",
    nota="No supervisado = aprender SIN respuestas correctas. "
         "Solo vemos datos y buscamos estructura.")

slide_analogia(
    prs, "La analogía de la música",
    "Imagina que tienes 1,000 canciones sin género.\n\n"
    "No sabes si son rock, cumbia o jazz. Pero puedes\n"
    "agruparlas por SIMILITUD: las que tienen bajo ritmo\n"
    "y mucha guitarra van juntas, las de percusión rápida\n"
    "en otro grupo.\n\n"
    "Eso es clustering: agrupar SIN saber los nombres\n"
    "de los grupos de antemano.",
    sig(), FT, color=TEAL, fill=SOFT_TEAL,
    etiqueta="Piénsalo así")

slide_concepto(
    prs, "¿Cuándo usar aprendizaje no supervisado?",
    "Usamos no supervisado cuando:\n\n"
    "1. No existen etiquetas en los datos.\n"
    "2. Queremos EXPLORAR la estructura antes de definir categorías.\n"
    "3. La pregunta es '¿existen grupos naturales?' (no '¿cuál es la clase\n"
    "   de este punto?').\n\n"
    "Ejemplos: segmentar clientes, agrupar municipios, descubrir\n"
    "perfiles químicos de vinos.",
    sig(), FT,
    en_cristiano="No hay un examen con respuestas. El objetivo es\n"
                 "descubrir, no predecir.")

# ===========================================================================
# SECCION 2: Clustering
# ===========================================================================
slide_seccion(prs, 2, "Clustering:\nagrupar lo parecido",
              "Encontrar grupos naturales en los datos")

slide_concepto(
    prs, "¿Qué es el clustering?",
    "Clustering es la tarea de dividir un conjunto de datos en GRUPOS\n"
    "(clusters) de manera que los elementos dentro de un grupo sean\n"
    "SIMILARES entre sí, y diferentes de los elementos en otros grupos.\n\n"
    "No definimos los grupos de antemano: emergen de los datos mismos.",
    sig(), FT,
    etiqueta="Definición",
    en_cristiano="Como separar frijoles de lentejas sin saber sus nombres:\n"
                 "los pones juntos porque se parecen, no porque alguien\n"
                 "te dijo que son del mismo tipo.")

slide_figura(
    prs, "Antes y después del clustering",
    img("02_antes_despues.png"), sig(), FT,
    caption="Los mismos puntos: sin etiqueta vs descubriendo 3 grupos.",
    nota="El algoritmo encontró la estructura que estaba 'escondida' en "
         "los datos. Nadie le dijo cuántos grupos había.")

slide_analogia(
    prs, "Ejemplos reales de clustering",
    "VINOS: 600 muestras con mediciones químicas (acidez, alcohol,\n"
    "azúcar...). ¿Existen perfiles químicos naturales?\n\n"
    "MUNICIPIOS: 500 municipios con indicadores sociales (pobreza,\n"
    "internet, ingreso...). ¿Podemos agruparlos para diseñar políticas\n"
    "públicas diferenciadas?\n\n"
    "CLIENTES: un banco quiere segmentar a sus clientes sin imponer\n"
    "categorías previas. El clustering las descubre.",
    sig(), FT, color=OCHRE, fill=SOFT_OCHRE,
    etiqueta="Usos en la vida real")

# ===========================================================================
# SECCION 3: K-means
# ===========================================================================
slide_seccion(prs, 3, "K-means\npaso a paso",
              "El algoritmo más popular de clustering")

slide_concepto(
    prs, "La idea central de k-means",
    "K-means divide los datos en K grupos usando CENTROIDES: puntos\n"
    "imaginarios que representan el 'centro' de cada grupo.\n\n"
    "La idea: cada punto pertenece al grupo cuyo centroide está\n"
    "MÁS CERCA de él. Y cada centroide se mueve al PROMEDIO de sus\n"
    "puntos asignados. Se repite hasta que nada cambia.",
    sig(), FT,
    etiqueta="Idea central",
    en_cristiano="Es como elegir puntos de reunión: cada persona va\n"
                 "al punto más cercano, y el punto se mueve al\n"
                 "centro de quien llegó.")

slide_figura(
    prs, "K-means: los 4 pasos visualizados",
    img("03_kmeans_pasos.png"), sig(), FT,
    caption="De centroides al azar a grupos estables en 4 pasos.",
    nota="El algoritmo CONVERGE: eventualmente los centroides dejan de "
         "moverse y los grupos quedan fijos.")

slide_pasos(
    prs, "K-means: el algoritmo detallado", [
        ("Elegir K", "Nosotros decidimos cuántos grupos queremos "
         "buscar (por ejemplo K = 3)."),
        ("Colocar centroides al azar",
         "Elegimos K puntos al azar como centroides iniciales."),
        ("Asignar cada punto", "Calculamos la distancia de cada punto a "
         "cada centroide; lo asignamos al más cercano."),
        ("Mover los centroides",
         "Calculamos el promedio de los puntos de cada grupo; "
         "ese promedio es el nuevo centroide."),
        ("Repetir hasta converger", "Repetimos asignar y mover hasta "
         "que ningún punto cambia de grupo."),
    ], sig(), FT,
    intro="Simple, rápido y funciona bien. Es el punto de partida del clustering.")

slide_concepto(
    prs, "La distancia en k-means",
    "K-means usa la distancia EUCLIDIANA: la misma del Teorema de\n"
    "Pitágoras. Si cada municipio es un punto con 9 coordenadas\n"
    "(una por indicador), la distancia mide qué tan 'parecidos' son\n"
    "dos municipios en todos los indicadores a la vez.\n\n"
    "Municipios cercanos en ese espacio tienen perfiles similares.",
    sig(), FT,
    en_cristiano="Dos municipios 'cercanos' no son vecinos geográficos:\n"
                 "son municipios con números parecidos en pobreza,\n"
                 "internet, ingreso, etc.")

# ===========================================================================
# SECCION 4: Cuantos grupos?
# ===========================================================================
slide_seccion(prs, 4, "¿Cuántos grupos\nelegir?",
              "El método del codo y sus límites")

slide_concepto(
    prs, "El problema: K es nuestra decisión",
    "K-means necesita que NOSOTROS decidamos cuántos grupos hay.\n"
    "Pero si no conocemos la estructura de los datos de antemano,\n"
    "¿cómo elegimos K?\n\n"
    "No hay una respuesta única 'correcta'. Pero hay herramientas\n"
    "que nos orientan: el método del codo y el índice de silueta.",
    sig(), FT,
    etiqueta="El dilema",
    en_cristiano="Es como decidir en cuántas categorías ordenar tu\n"
                 "cuarto. Hay muchas formas válidas; buscamos la que\n"
                 "tenga sentido con los datos.")

slide_concepto(
    prs, "Inercia: qué tan compactos son los grupos",
    "La INERCIA es la suma de las distancias al cuadrado de cada\n"
    "punto a su centroide. Mide qué tan 'apretados' están los grupos.\n\n"
    "Con K = 1: inercia máxima (un solo grupo muy disperso).\n"
    "Con K = n: inercia = 0 (cada punto es su propio grupo).\n"
    "Buscamos el K donde la inercia 'deja de bajar tanto'.",
    sig(), FT,
    en_cristiano="Si cada persona en la clase es un grupo de uno, la\n"
                 "'distancia al centro' es cero... pero eso no es útil.\n"
                 "Buscamos el número justo de grupos.")

slide_figura(
    prs, "Método del codo: la curva de inercia",
    img("04_codo.png"), sig(), FT,
    caption="La inercia baja rápido al principio, luego se estabiliza.",
    nota="El 'codo' es el K donde agregar más grupos ya no reduce mucho "
         "la inercia. Ahí está el número óptimo aproximado.")

slide_alerta(
    prs, "El codo no siempre es obvio",
    "En datos reales, la curva del codo a veces NO tiene un quiebre\n"
    "claro. En ese caso:\n\n"
    "1. Usar también el índice de silueta (mide separación entre grupos).\n"
    "2. Probar varios K y evaluar si los grupos tienen INTERPRETACIÓN.\n"
    "3. Consultar el contexto: un experto en vinos sabe si 3 o 4\n"
    "   perfiles químicos tiene sentido.\n\n"
    "No existe un K 'correcto' universal; depende del problema.",
    sig(), FT, etiqueta="Cuidado con el codo")

# ===========================================================================
# SECCION 5: Estandarizar
# ===========================================================================
slide_seccion(prs, 5, "Estandarizar\nantes de agrupar",
              "Por qué la escala importa tanto como en KNN")

slide_figura(
    prs, "Sin estandarizar: una variable domina",
    img("05_estandarizar.png"), sig(), FT,
    caption="Izquierda: ingreso (miles) aplasta a % pobreza. "
            "Derecha: escalas iguales.",
    nota="Sin estandarizar, k-means agruparía casi solo por ingreso y "
         "casi ignoraría el porcentaje de pobreza. La escala deforma los grupos.")

slide_pasos(
    prs, "¿Por qué estandarizar (z-score)?", [
        ("Unidades distintas", "Ingreso en MXN vs porcentaje vs densidad: "
         "no tienen unidades comparables."),
        ("Magnitudes distintas", "Ingreso: decenas de miles. "
         "% pobreza: 0 a 100. Densidad: puede ser miles."),
        ("La distancia es sensible a esto",
         "Un punto en ingreso muy alto parece 'lejos' aunque en\n"
         "todos los demás indicadores sea igual."),
        ("Solución: z-score",
         "Restar la media y dividir entre la desviación estándar.\n"
         "Cada variable queda con media 0 y desviación 1."),
    ], sig(), FT,
    intro="El z-score pone a todas las variables en pie de igualdad.")

slide_comparacion(
    prs, "Estandarizar: la misma lógica que KNN",
    {"titulo": "Sin estandarizar", "color": DARK_RED, "fill": SOFT_RED,
     "body": "Una variable con números grandes\n"
             "domina la distancia euclidiana.\n\n"
             "Los grupos reflejan las UNIDADES\n"
             "de medida, no la realidad.\n\n"
             "Resultado: grupos sin sentido."},
    {"titulo": "Con estandarizar (z-score)", "color": DARK_GREEN,
     "fill": SOFT_GREEN,
     "body": "Todas las variables contribuyen\n"
             "por igual a la distancia.\n\n"
             "Los grupos reflejan la ESTRUCTURA\n"
             "real de los datos.\n\n"
             "Resultado: grupos interpretables."},
    sig(), FT,
    intro="Lo vimos antes con KNN: la escala siempre importa cuando "
          "se miden distancias.")

# ===========================================================================
# SECCION 6: El problema de la dimension
# ===========================================================================
slide_seccion(prs, 6, "El problema\nde la dimensión",
              "Por qué cuesta ver y agrupar con muchas variables")

slide_concepto(
    prs, "La maldición de la dimensionalidad",
    "Cuando tenemos muchas variables, los puntos se vuelven MÁS\n"
    "DISPERSOS. Las distancias tienden a parecerse y es difícil\n"
    "distinguir quién es realmente 'cercano'.\n\n"
    "Con 11 variables químicas ya no podemos visualizar los datos:\n"
    "necesitamos REDUCIR las dimensiones. Ahí entra PCA.",
    sig(), FT,
    etiqueta="El problema",
    en_cristiano="En 2D ves si dos puntos están cerca. En 100 dimensiones\n"
                 "'cerca' pierde significado. Hay que comprimir.")

slide_figura(
    prs, "Muchas variables -> 2 componentes con PCA",
    img("06_dimension.png"), sig(), FT,
    caption="PCA convierte 8 variables en 2 componentes que resumen "
            "la mayoría de la información.",
    nota="Perdemos algo de detalle, pero ganamos capacidad de visualizar "
         "y entender la estructura de los datos.")

# ===========================================================================
# SECCION 7: PCA
# ===========================================================================
slide_seccion(prs, 7, "PCA:\ncomprimir información",
              "Análisis de Componentes Principales en palabras simples")

slide_analogia(
    prs, "La analogía del promedio de materias",
    "Si tienes notas en 10 materias, puedes resumirlas en dos\n"
    "promedios: 'ciencias' y 'humanidades'. Pierdes algo de detalle,\n"
    "pero capturas lo esencial.\n\n"
    "PCA hace lo mismo con datos: busca los 'resúmenes' que\n"
    "conservan MÁXIMA información (varianza). Esos resúmenes son\n"
    "los COMPONENTES PRINCIPALES.",
    sig(), FT, color=TEAL, fill=SOFT_TEAL,
    img=img("10_analogia_pca.png"),
    etiqueta="Piénsalo así")

slide_concepto(
    prs, "¿Qué es un componente principal?",
    "Un componente principal (CP) es una COMBINACIÓN LINEAL de las\n"
    "variables originales, elegida para capturar la máxima varianza.\n\n"
    "CP1 capta la mayor cantidad posible de variación en los datos.\n"
    "CP2 capta la segunda mayor variación, PERPENDICULAR a CP1.\n"
    "...y así sucesivamente.\n\n"
    "Los CP son NUEVAS variables; no son las originales.",
    sig(), FT,
    en_cristiano="CP1 es la dirección en la que los datos 'se esparcen\n"
                 "más'. CP2 es la segunda dirección más importante,\n"
                 "sin repetir lo que ya capturó CP1.")

slide_figura(
    prs, "PCA: proyectar una nube de puntos a 2D",
    img("07_pca_idea.png"), sig(), FT,
    caption="Izquierda: espacio original. Derecha: mismos datos en 2 CP.",
    nota="Los puntos mantienen su estructura relativa (quién está cerca "
         "sigue cerca), pero ahora los vemos en 2 dimensiones.")

slide_figura(
    prs, "Scree plot: cuánta información captura cada CP",
    img("08_scree.png"), sig(), FT,
    caption="Las barras muestran la varianza de cada componente; "
            "la línea roja es la varianza acumulada.",
    nota="El 'codo' del scree plot indica cuántos componentes conservar. "
         "Si los primeros 2-3 suman más del 80%, podemos comprimir bien.")

slide_pasos(
    prs, "PCA paso a paso (sin fórmulas)", [
        ("Estandarizar", "Z-score de todas las variables. "
         "Indispensable: PCA es sensible a la escala."),
        ("Calcular componentes", "El algoritmo encuentra las "
         "direcciones de máxima varianza en los datos."),
        ("Elegir cuántos CP conservar", "Revisar el scree plot: "
         "tomar los CP que sumen el 80-90% de varianza."),
        ("Proyectar los datos", "Transformar cada observación a las "
         "nuevas coordenadas (CP1, CP2, ...)."),
        ("Visualizar e interpretar", "Graficar en 2D y colorear por\n"
         "grupos; analizar qué representa cada CP."),
    ], sig(), FT,
    intro="PCA es una receta matemática, pero su lógica es intuitiva.")

slide_concepto(
    prs, "¿Qué significan los componentes principales?",
    "Los CP combinan las variables originales con 'pesos' (cargas).\n"
    "Leer las cargas dice qué variables contribuyen más a cada CP.\n\n"
    "Ejemplo: si CP1 tiene cargas altas en '% pobreza', '% carencia\n"
    "educativa' y 'grado de marginación', ese componente representa\n"
    "el 'eje de marginación'.\n\n"
    "Interpretar los CP requiere conocer el contexto.",
    sig(), FT,
    en_cristiano="Los CP son combinaciones de tus variables originales.\n"
                 "Leer cuáles variables pesan más en cada CP te dice\n"
                 "qué 'concepto' representa ese componente.")

# ===========================================================================
# SECCION 8: PCA + clustering sobre datos reales
# ===========================================================================
slide_seccion(prs, 8, "Juntando todo:\nPCA + clustering",
              "Aplicación sobre municipios y vinos")

slide_figura(
    prs, "El flujo completo: de datos a perfiles",
    img("13_flujo_completo.png"), sig(), FT,
    caption="Estandarizar -> PCA -> k-means -> interpretar.",
    nota="PCA facilita la visualización; k-means descubre los grupos. "
         "Juntos son una combinación muy poderosa.")

slide_figura(
    prs, "Municipios: 3 perfiles socioeconómicos descubiertos",
    img("09_biplot_municipios.png"), sig(), FT,
    caption="500 municipios proyectados a 2 componentes, coloreados "
            "por k-means.",
    fuente="Fuente: datos.csv ejercicio_2, datos simulados con "
           "estructura latente. Cálculos propios.",
    nota="Los grupos no los definimos nosotros: emergieron de los datos. "
         "Ahora podemos interpretar qué tiene en común cada grupo.")

slide_figura(
    prs, "¿Qué caracteriza a cada grupo de municipios?",
    img("12_perfiles_municipios.png"), sig(), FT,
    caption="Promedio de 4 indicadores clave por grupo.",
    fuente="Fuente: datos.csv ejercicio_2. Cálculos propios.",
    nota="Comparar los promedios ayuda a ponerle nombre a los grupos: "
         "'municipios marginados rurales', 'urbanos conectados', etc.")

slide_figura(
    prs, "Vinos: 3 perfiles químicos descubiertos",
    img("11_biplot_vinos.png"), sig(), FT,
    caption="600 muestras de vino en el espacio PCA, coloreadas "
            "por k-means.",
    fuente="Fuente: datos.csv ejercicio_1, perfil fisicoquímico. "
           "Cálculos propios.",
    nota="Sin que nadie etiquetara las muestras, PCA + k-means "
         "reveló 3 perfiles químicos distintos.")

slide_texto_figura(
    prs,
    "Pasos para aplicar PCA + clustering en R",
    "Con el paquete tidymodels y factoextra:",
    "1. Cargar datos y quitar columna id.\n"
    "2. step_impute_median() para NAs.\n"
    "3. step_normalize() para z-score.\n"
    "4. prcomp() o step_pca() para PCA.\n"
    "5. kmeans() con el K elegido por el codo.\n"
    "6. fviz_cluster() para visualizar.",
    img("13_flujo_completo.png"), sig(), FT,
    img_side="right",
    puntos_size=13)

# ===========================================================================
# Slide de alerta: errores comunes
# ===========================================================================
slide_alerta(
    prs, "Errores comunes en clustering y PCA",
    "1. No estandarizar: una variable domina la distancia.\n\n"
    "2. Elegir K mal: usar el codo sin validar interpretación.\n\n"
    "3. Interpretar de más: los grupos son exploratorios,\n"
    "   no verdad absoluta. Necesitan validación experta.\n\n"
    "4. No hay 'accuracy': sin etiquetas no se mide acierto.\n"
    "   Evalúa con coherencia e interpretación del dominio.",
    sig(), FT, etiqueta="Lista de verificación")

# ===========================================================================
# Conclusiones
# ===========================================================================
slide_conclusiones(prs, "Conclusiones",
                   "\n".join("•  " + t for t in [
    "No supervisado = aprender SIN etiquetas; "
    "el algoritmo descubre la estructura.",
    "Clustering agrupa puntos similares; k-means "
    "usa centroides y converge iterativamente.",
    "K es nuestra decisión: el método del codo ayuda, "
    "pero requiere interpretación.",
    "SIEMPRE estandarizar (z-score) antes de clustering o PCA: "
    "la escala deforma las distancias.",
    "PCA comprime muchas variables en componentes que capturan "
    "la máxima varianza.",
    "PCA + k-means: visualizar y agrupar datos de alta dimensión "
    "para descubrir perfiles reales.",
]), sig(), FT)

# ===========================================================================
# Cierre
# ===========================================================================
slide_cierre(prs)

prs.save(OUT)
print(f"Guardado: {OUT} | slides: {len(prs.slides._sldIdLst)}")
