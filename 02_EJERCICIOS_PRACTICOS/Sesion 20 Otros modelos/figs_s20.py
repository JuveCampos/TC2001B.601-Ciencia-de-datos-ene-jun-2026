"""Genera las figuras de la presentacion TEORICA de la Sesion 20 (arboles,
bosques aleatorios, boosting, stacking). Diagramas conceptuales y fronteras
de decision calculadas con sklearn sobre make_moons.

Salida: ./img_teoria/*.png a 300 DPI.
"""
import os
import sys
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Circle, Rectangle
from matplotlib.colors import ListedColormap
from sklearn.datasets import make_moons
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import (
    RandomForestClassifier, GradientBoostingClassifier,
)

# Agregar la carpeta de la Sesion 16 al path para importar figteoria
S16 = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "Sesion 16 knn workflows")
sys.path.insert(0, S16)

import figteoria as ft

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "img_teoria")
os.makedirs(OUT, exist_ok=True)
p = lambda nombre: os.path.join(OUT, nombre)

# Datos 2D ilustrativos: "ingreso" y "score" estandarizados
rng = np.random.default_rng(20)
X, y = make_moons(n_samples=280, noise=0.30, random_state=20)
X = (X - X.mean(axis=0)) / X.std(axis=0)
COL = {1: ft.NAVY, 0: ft.RED_PT}
ETI = {1: "Aprobado", 0: "Rechazado"}


def _scatter(ax, *, alpha=0.88, s=32):
    for c in (0, 1):
        m = y == c
        ax.scatter(X[m, 0], X[m, 1], c=COL[c], label=ETI[c], s=s, alpha=alpha,
                   edgecolors="white", linewidths=0.6, zorder=3)


def _frontera(ax, clf, titulo_, *, h=0.03):
    x0, x1 = X[:, 0].min() - 0.5, X[:, 0].max() + 0.5
    y0, y1 = X[:, 1].min() - 0.5, X[:, 1].max() + 0.5
    xx, yy = np.meshgrid(np.arange(x0, x1, h), np.arange(y0, y1, h))
    Z = clf.predict(np.c_[xx.ravel(), yy.ravel()]).reshape(xx.shape)
    ax.contourf(xx, yy, Z, alpha=0.22,
                cmap=ListedColormap([ft.RED_PT, ft.NAVY]))
    _scatter(ax, alpha=0.85, s=22)
    ax.set_xticks([])
    ax.set_yticks([])
    ft.titulo(ax, titulo_, size=12)


# ---------------------------------------------------------------------------
def fig_panorama_modelos():
    """Mapa de familias de modelos con notas de cuando usar cada uno."""
    fig, ax = plt.subplots(figsize=(9.2, 5.2))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6)

    modelos = [
        (0.4, 4.2, "KNN", "Vecinos mas\ncercanos",
         ft.SLATE, "Datos limpios,\npoca escala"),
        (2.7, 4.2, "Regresion\nLogistica", "Linea\ndivisoria",
         ft.BLUEA, "Problema\nlineal"),
        (5.0, 4.2, "Arbol de\nDecision", "Preguntas\nsi/no",
         ft.TEAL, "Necesitas\ninterpretar"),
        (7.3, 4.2, "Bosque\nAleatorio", "Muchos\narboles",
         ft.DARK_GREEN, "Alta precision,\nmuchos datos"),
        (1.6, 1.3, "Boosting", "Corregir\nerrores",
         ft.OCHRE, "Mejor AUC\nposible"),
        (5.0, 1.3, "Stacking", "Meta-modelo\ncombina",
         ft.PLUM, "Competencias\nML avanzadas"),
        (8.2, 1.3, "Red\nneuronal", "Patrones\ncomplejos",
         ft.DARK_RED, "Miles de\nejemplos"),
    ]

    for x, yb, nombre, desc, color, cuando in modelos:
        bx = FancyBboxPatch((x, yb), 2.0, 1.3,
                            boxstyle="round,pad=0.07,rounding_size=0.12",
                            fc=color, ec="none", zorder=2, alpha=0.92)
        ax.add_patch(bx)
        ax.text(x + 1.0, yb + 0.82, nombre, ha="center", va="center",
                color="white", fontsize=10.5, fontweight="bold", zorder=3)
        ax.text(x + 1.0, yb + 0.35, desc, ha="center", va="center",
                color="white", fontsize=8.5, zorder=3)

    ax.text(5.0, 5.8, "Mapa de familias de modelos de ML",
            ha="center", color=ft.NAVY, fontsize=13, fontweight="bold")
    ax.text(5.0, 5.45,
            "Esta sesion: arboles, bosques, boosting y stacking",
            ha="center", color=ft.GRAY, fontsize=10.5, style="italic")

    ax.add_patch(Rectangle((0.2, 3.85), 9.5, 1.8, fc="none",
                            ec=ft.SOFT_BLUE, lw=2, ls="--", zorder=1))
    ax.text(0.35, 3.7, "Sesiones anteriores", color=ft.SLATE,
            fontsize=9, style="italic")
    ax.add_patch(Rectangle((0.2, 0.9), 9.5, 1.8, fc="none",
                            ec=ft.DARK_GREEN, lw=2, ls="--", zorder=1))
    ax.text(0.35, 0.75, "Sesion 20: ensambles y mas",
            color=ft.DARK_GREEN, fontsize=9, style="italic")

    ft.guardar(fig, p("01_panorama_modelos.png"))


def fig_arbol_diagrama():
    """Diagrama de arbol de decision con preguntas si/no dibujado a mano."""
    fig, ax = plt.subplots(figsize=(9.0, 5.6))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6.5)

    def nodo(x, yb, w, h, texto, color, fc_txt="white", size=11):
        bx = FancyBboxPatch((x - w / 2, yb), w, h,
                            boxstyle="round,pad=0.07,rounding_size=0.13",
                            fc=color, ec="none", zorder=2)
        ax.add_patch(bx)
        ax.text(x, yb + h / 2, texto, ha="center", va="center",
                color=fc_txt, fontsize=size, fontweight="bold", zorder=3,
                wrap=True, multialignment="center")

    def flecha(x0, y0, x1, y1, etiqueta="", lado="left"):
        ax.add_patch(FancyArrowPatch(
            (x0, y0), (x1, y1),
            arrowstyle="-|>", mutation_scale=14,
            color=ft.GRAY, lw=1.6, zorder=1))
        dx = -0.18 if lado == "left" else 0.18
        ax.text((x0 + x1) / 2 + dx, (y0 + y1) / 2 + 0.07,
                etiqueta, ha="center", color=ft.GRAY, fontsize=9.5,
                style="italic")

    # Nodo raiz
    nodo(5.0, 5.2, 2.4, 0.8, "Score de historial\n> 600?", ft.NAVY, size=11)

    # Nivel 2 izquierda
    nodo(2.5, 3.8, 2.3, 0.75,
         "Ingreso mensual\n> $20,000?", ft.TEAL, size=10.5)
    # Nivel 2 derecha
    nodo(7.5, 3.8, 2.3, 0.75,
         "Ratio deuda/ingreso\n< 0.5?", ft.NAVY, size=10.5)

    # Hojas izquierda-izquierda
    nodo(1.3, 2.3, 1.8, 0.7, "RECHAZADO", ft.RED_PT, size=10)
    # Hoja izquierda-derecha
    nodo(3.7, 2.3, 1.8, 0.7, "APROBADO", ft.DARK_GREEN, size=10)
    # Hoja derecha-izquierda
    nodo(6.3, 2.3, 1.8, 0.7, "APROBADO", ft.DARK_GREEN, size=10)
    # Hoja derecha-derecha
    nodo(8.7, 2.3, 1.8, 0.7, "RECHAZADO", ft.RED_PT, size=10)

    # Hojas de tercer nivel (izq-izq)
    nodo(0.8, 0.7, 1.4, 0.65, "No\naprobado", ft.RED_PT, size=9)
    nodo(1.8, 0.7, 1.4, 0.65, "Si\naprobado", ft.DARK_GREEN, size=9)

    # Flechas nivel 1 -> nivel 2
    flecha(4.4, 5.2, 3.0, 4.55, "No", "left")
    flecha(5.6, 5.2, 7.0, 4.55, "Si", "right")

    # Flechas nivel 2 izq -> hojas
    flecha(2.1, 3.8, 1.55, 3.0, "No", "left")
    flecha(2.9, 3.8, 3.45, 3.0, "Si", "right")

    # Flechas nivel 2 der -> hojas
    flecha(7.1, 3.8, 6.55, 3.0, "No", "left")
    flecha(7.9, 3.8, 8.45, 3.0, "Si", "right")

    # Flechas hoja izq-izq -> nietos
    flecha(1.1, 2.3, 0.95, 1.35, "bajo", "left")
    flecha(1.5, 2.3, 1.65, 1.35, "alto", "right")

    ax.text(5.0, 6.3, "Arbol de decision: cada nodo hace una pregunta si/no",
            ha="center", color=ft.NAVY, fontsize=12.5, fontweight="bold")
    ax.text(5.0, 6.0, "Las hojas (rectangulos de color) son la decision final",
            ha="center", color=ft.GRAY, fontsize=10, style="italic")

    ft.guardar(fig, p("02_arbol_diagrama.png"))


def fig_frontera_arbol_suave():
    """Frontera de un arbol profundidad 4 (relativamente suave)."""
    clf = DecisionTreeClassifier(max_depth=4, random_state=20).fit(X, y)
    fig, ax = plt.subplots(figsize=(6.0, 4.8))
    _frontera(ax, clf, "Arbol de decision  (prof. = 4)")
    ax.legend(loc="upper right", frameon=True, fontsize=9)
    ft.guardar(fig, p("03_frontera_arbol.png"))


def fig_frontera_arbol_sobreajuste():
    """Frontera de un arbol sin limite de profundidad: sobreajuste."""
    clf = DecisionTreeClassifier(max_depth=None, random_state=20).fit(X, y)
    fig, ax = plt.subplots(figsize=(6.0, 4.8))
    _frontera(ax, clf, "Arbol sin limite  (memoriza el ruido)")
    ax.legend(loc="upper right", frameon=True, fontsize=9)
    ft.guardar(fig, p("04_frontera_arbol_sobreajuste.png"))


def fig_arbol_vs_sobreajuste():
    """Panel comparativo: arbol sano vs arbol sobreajustado."""
    clf_ok = DecisionTreeClassifier(max_depth=4, random_state=20).fit(X, y)
    clf_over = DecisionTreeClassifier(max_depth=None, random_state=20).fit(X, y)
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.0))
    _frontera(axs[0], clf_ok, "Profundidad = 4  (equilibrado)")
    _frontera(axs[1], clf_over, "Sin limite  (memoriza el ruido)")
    fig.subplots_adjust(wspace=0.08)
    ft.guardar(fig, p("04b_arbol_comparativo.png"))


def fig_bosque_esquema():
    """Diagrama esquematico de bosque aleatorio: arboles distintos votan."""
    fig, ax = plt.subplots(figsize=(9.2, 5.0))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6)

    # Mini-arboles (triangulos estilizados con rectangulos)
    colores_arb = [ft.TEAL, ft.NAVY, ft.OCHRE, ft.SLATE, ft.PLUM]
    posiciones = [0.5, 2.3, 4.1, 5.9, 7.7]

    for i, (cx, color) in enumerate(zip(posiciones, colores_arb)):
        # Tronco del arbol
        ax.add_patch(Rectangle((cx + 0.7, 1.5), 0.2, 0.5,
                                fc=color, ec="none", alpha=0.85))
        # Copa del arbol (triangulo aproximado con wedge)
        tri = plt.Polygon(
            [(cx + 0.3, 1.5), (cx + 0.8, 0.4), (cx + 1.3, 1.5)],
            fc=color, ec="none", alpha=0.9)
        ax.add_patch(tri)
        tri2 = plt.Polygon(
            [(cx + 0.2, 2.0), (cx + 0.8, 0.9), (cx + 1.4, 2.0)],
            fc=color, ec="none", alpha=0.85)
        ax.add_patch(tri2)
        tri3 = plt.Polygon(
            [(cx + 0.1, 2.5), (cx + 0.8, 1.5), (cx + 1.5, 2.5)],
            fc=color, ec="none", alpha=0.8)
        ax.add_patch(tri3)
        ax.text(cx + 0.8, 0.12, f"Arbol {i + 1}", ha="center",
                color=color, fontsize=9.5, fontweight="bold")
        # Flechas hacia el centro
        ax.add_patch(FancyArrowPatch(
            (cx + 0.8, 2.5), (4.2, 3.8),
            arrowstyle="-|>", mutation_scale=14,
            color=ft.GRAY, lw=1.4, connectionstyle="arc3,rad=0.0"))

        # Etiqueta de voto
        votos = ["NO", "SI", "SI", "SI", "NO"]
        v_color = [ft.RED_PT, ft.DARK_GREEN, ft.DARK_GREEN,
                   ft.DARK_GREEN, ft.RED_PT]
        ax.text(cx + 0.8, 3.0, votos[i], ha="center",
                color=v_color[i], fontsize=10, fontweight="bold")

    # Caja de votacion
    ax.add_patch(FancyBboxPatch((3.2, 3.85), 2.0, 0.9,
                                boxstyle="round,pad=0.07,rounding_size=0.12",
                                fc=ft.NAVY, ec="none", zorder=2))
    ax.text(4.2, 4.3, "VOTACION\nMayoria gana", ha="center", va="center",
            color="white", fontsize=11, fontweight="bold", zorder=3)

    # Resultado final
    ax.add_patch(FancyArrowPatch((4.2, 4.75), (4.2, 5.2),
                                 arrowstyle="-|>", mutation_scale=18,
                                 color=ft.DARK_GREEN, lw=2.2))
    ax.add_patch(FancyBboxPatch((2.9, 5.2), 2.6, 0.65,
                                boxstyle="round,pad=0.07,rounding_size=0.12",
                                fc=ft.DARK_GREEN, ec="none", zorder=2))
    ax.text(4.2, 5.52, "Resultado: APROBADO", ha="center", va="center",
            color="white", fontsize=12, fontweight="bold", zorder=3)

    ax.text(4.2, 5.96,
            "Bosque aleatorio: muchos arboles distintos -> mayoria vota",
            ha="center", color=ft.NAVY, fontsize=12, fontweight="bold")

    ft.guardar(fig, p("05_bosque_esquema.png"))


def fig_frontera_bosque():
    """Frontera de un bosque aleatorio: comparacion directa con un arbol."""
    clf_arb = DecisionTreeClassifier(max_depth=4, random_state=20).fit(X, y)
    clf_bos = RandomForestClassifier(n_estimators=120, max_depth=6,
                                     random_state=20).fit(X, y)
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.0))
    _frontera(axs[0], clf_arb, "Un solo arbol  (prof. = 4)")
    _frontera(axs[1], clf_bos, "Bosque aleatorio  (120 arboles)")
    for ax in axs:
        ax.legend(loc="upper right", frameon=True, fontsize=9)
    fig.subplots_adjust(wspace=0.08)
    ft.guardar(fig, p("06_frontera_bosque.png"))


def fig_bagging_vs_boosting():
    """Diagrama esquematico: bagging en paralelo vs boosting en secuencia."""
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.8))

    # Panel izquierdo: BAGGING (paralelo)
    ax = axs[0]
    ft.sin_ejes(ax)
    ax.set_xlim(0, 5)
    ax.set_ylim(0, 5.5)
    ax.text(2.5, 5.3, "BAGGING", ha="center", color=ft.NAVY,
            fontsize=14, fontweight="bold")
    ax.text(2.5, 5.0, "(arboles en paralelo)", ha="center",
            color=ft.GRAY, fontsize=10, style="italic")

    # Datos originales
    ax.add_patch(FancyBboxPatch((1.3, 4.1), 1.9, 0.65,
                                boxstyle="round,pad=0.06,rounding_size=0.1",
                                fc=ft.NAVY, ec="none"))
    ax.text(2.25, 4.42, "Datos originales", ha="center", va="center",
            color="white", fontsize=9, fontweight="bold")

    # Tres muestras aleatorias (bootstrap)
    for i, (cx, color, nm) in enumerate([
            (0.5, ft.TEAL, "Muestra 1"),
            (2.0, ft.OCHRE, "Muestra 2"),
            (3.5, ft.PLUM, "Muestra 3")]):
        ax.add_patch(FancyArrowPatch((2.25, 4.1), (cx + 0.55, 3.2),
                                     arrowstyle="-|>", mutation_scale=12,
                                     color=ft.GRAY, lw=1.3))
        ax.add_patch(FancyBboxPatch((cx, 2.3), 1.1, 0.7,
                                    boxstyle="round,pad=0.05",
                                    fc=color, ec="none", alpha=0.9))
        ax.text(cx + 0.55, 2.65, nm, ha="center", va="center",
                color="white", fontsize=8.5, fontweight="bold")
        # Mini-arbol
        ax.add_patch(FancyBboxPatch((cx + 0.25, 1.25), 0.6, 0.8,
                                    boxstyle="round,pad=0.05",
                                    fc=color, ec="none", alpha=0.75))
        ax.text(cx + 0.55, 1.65, "Arbol", ha="center", va="center",
                color="white", fontsize=8, fontweight="bold")
        ax.add_patch(FancyArrowPatch((cx + 0.55, 2.3), (cx + 0.55, 2.05),
                                     arrowstyle="-|>", mutation_scale=10,
                                     color=ft.GRAY, lw=1.2))
        ax.add_patch(FancyArrowPatch((cx + 0.55, 1.25), (2.25, 0.65),
                                     arrowstyle="-|>", mutation_scale=10,
                                     color=ft.GRAY, lw=1.2))

    ax.add_patch(FancyBboxPatch((1.3, 0.1), 1.9, 0.55,
                                boxstyle="round,pad=0.06",
                                fc=ft.DARK_GREEN, ec="none"))
    ax.text(2.25, 0.37, "Promedio/voto", ha="center", va="center",
            color="white", fontsize=9, fontweight="bold")

    # Panel derecho: BOOSTING (secuencial)
    ax = axs[1]
    ft.sin_ejes(ax)
    ax.set_xlim(0, 5)
    ax.set_ylim(0, 5.5)
    ax.text(2.5, 5.3, "BOOSTING", ha="center", color=ft.DARK_RED,
            fontsize=14, fontweight="bold")
    ax.text(2.5, 5.0, "(arboles en secuencia)", ha="center",
            color=ft.GRAY, fontsize=10, style="italic")

    pasos_b = [
        ("Arbol 1", "datos completos", ft.NAVY),
        ("Arbol 2", "enfoca errores 1", ft.OCHRE),
        ("Arbol 3", "enfoca errores 2", ft.TEAL),
        ("Arbol 4", "enfoca errores 3", ft.PLUM),
    ]
    y_pos = [4.3, 3.2, 2.1, 1.0]
    for i, ((nombre, desc, color), yp) in enumerate(zip(pasos_b, y_pos)):
        ax.add_patch(FancyBboxPatch((1.4, yp), 2.2, 0.75,
                                    boxstyle="round,pad=0.06",
                                    fc=color, ec="none", alpha=0.9))
        ax.text(2.5, yp + 0.375, nombre, ha="center", va="center",
                color="white", fontsize=9.5, fontweight="bold")
        ax.text(2.5, yp + 0.13, desc, ha="center", va="bottom",
                color="white", fontsize=8, style="italic")
        if i < len(y_pos) - 1:
            ax.add_patch(FancyArrowPatch(
                (2.5, yp), (2.5, y_pos[i + 1] + 0.75),
                arrowstyle="-|>", mutation_scale=12,
                color=ft.DARK_RED, lw=1.8))
            ax.text(2.9, (yp + y_pos[i + 1] + 0.75) / 2,
                    "corrige", color=ft.DARK_RED, fontsize=8.5,
                    style="italic", va="center")

    ax.add_patch(FancyArrowPatch((2.5, 1.0), (2.5, 0.45),
                                  arrowstyle="-|>", mutation_scale=14,
                                  color=ft.DARK_GREEN, lw=2))
    ax.add_patch(FancyBboxPatch((1.3, 0.05), 2.4, 0.42,
                                boxstyle="round,pad=0.06",
                                fc=ft.DARK_GREEN, ec="none"))
    ax.text(2.5, 0.26, "Suma ponderada", ha="center", va="center",
            color="white", fontsize=9, fontweight="bold")

    fig.subplots_adjust(wspace=0.05)
    ft.guardar(fig, p("07_bagging_vs_boosting.png"))


def fig_boosting_secuencial():
    """Diagrama donde los errores se encogen ronda con ronda."""
    fig, ax = plt.subplots(figsize=(9.0, 4.4))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 5.5)

    rondas = ["Ronda 1\n(arbol base)", "Ronda 2\n(+pesos)", "Ronda 3\n(+pesos)",
              "Ronda 4\n(+pesos)", "Suma final"]
    x_pos = [0.6, 2.5, 4.4, 6.3, 8.5]
    errores = [0.38, 0.22, 0.13, 0.07, None]
    colores = [ft.NAVY, ft.OCHRE, ft.TEAL, ft.PLUM, ft.DARK_GREEN]

    for i, (nombre, xp, err, color) in enumerate(
            zip(rondas, x_pos, errores, colores)):
        h = 1.0 if err is None else max(0.55, err * 6)
        ax.add_patch(FancyBboxPatch((xp, 0.4), 1.5, h + 0.9,
                                    boxstyle="round,pad=0.07",
                                    fc=color, ec="none", alpha=0.9))
        ax.text(xp + 0.75, 0.4 + (h + 0.9) / 2, nombre,
                ha="center", va="center", color="white",
                fontsize=9.5, fontweight="bold")
        if err is not None:
            ax.text(xp + 0.75, 0.4 + h + 0.9 + 0.18,
                    f"error: {err:.0%}", ha="center", color=color,
                    fontsize=9.5, fontweight="bold")
        if i < len(x_pos) - 1:
            ax.add_patch(FancyArrowPatch(
                (xp + 1.5, 1.3), (x_pos[i + 1], 1.3),
                arrowstyle="-|>", mutation_scale=14,
                color=ft.GRAY, lw=1.6))

    ax.text(5.0, 5.3,
            "Boosting: cada ronda corrige los errores de la anterior",
            ha="center", color=ft.NAVY, fontsize=12.5, fontweight="bold")
    ax.text(5.0, 5.0,
            "Los errores se acumulan con mayor peso -> el modelo aprende donde se equivoca",
            ha="center", color=ft.GRAY, fontsize=10, style="italic")

    ft.guardar(fig, p("08_boosting_secuencial.png"))


def fig_stacking_diagrama():
    """Diagrama de stacking: modelos base distintos -> meta-modelo."""
    fig, ax = plt.subplots(figsize=(9.2, 5.4))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6.5)

    ax.text(5.0, 6.3, "Stacking: combinar modelos distintos con un meta-modelo",
            ha="center", color=ft.NAVY, fontsize=12.5, fontweight="bold")

    # Datos originales
    ax.add_patch(FancyBboxPatch((3.5, 5.5), 3.0, 0.65,
                                boxstyle="round,pad=0.07",
                                fc=ft.NAVY, ec="none"))
    ax.text(5.0, 5.82, "Datos de entrenamiento", ha="center", va="center",
            color="white", fontsize=11, fontweight="bold")

    # Modelos base
    bases = [
        (1.2, ft.TEAL, "KNN"),
        (3.3, ft.OCHRE, "Arbol"),
        (5.4, ft.PLUM, "Bosque\nAleatorio"),
        (7.5, ft.BLUEA, "Regresion\nLogistica"),
    ]
    for cx, color, nombre in bases:
        ax.add_patch(FancyArrowPatch((5.0, 5.5), (cx + 0.85, 4.3),
                                     arrowstyle="-|>", mutation_scale=11,
                                     color=ft.GRAY, lw=1.3))
        ax.add_patch(FancyBboxPatch((cx, 3.45), 1.7, 0.75,
                                    boxstyle="round,pad=0.06",
                                    fc=color, ec="none", alpha=0.9))
        ax.text(cx + 0.85, 3.82, nombre, ha="center", va="center",
                color="white", fontsize=9.5, fontweight="bold")
        # Prediccion de cada modelo
        ax.add_patch(FancyArrowPatch((cx + 0.85, 3.45), (cx + 0.85, 2.75),
                                     arrowstyle="-|>", mutation_scale=11,
                                     color=ft.GRAY, lw=1.2))
        ax.add_patch(FancyBboxPatch((cx, 2.05), 1.7, 0.62,
                                    boxstyle="round,pad=0.05",
                                    fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=0.8))
        ax.text(cx + 0.85, 2.36, "prediccion\nbase", ha="center", va="center",
                color=ft.NAVY, fontsize=8.5)

    # Flecha de predicciones al meta-modelo
    for cx, _, _ in bases:
        ax.add_patch(FancyArrowPatch((cx + 0.85, 2.05), (5.0, 1.45),
                                     arrowstyle="-|>", mutation_scale=11,
                                     color=ft.GRAY, lw=1.3))

    # Meta-modelo
    ax.add_patch(FancyBboxPatch((3.0, 0.75), 4.0, 0.65,
                                boxstyle="round,pad=0.07",
                                fc=ft.DARK_RED, ec="none"))
    ax.text(5.0, 1.07, "META-MODELO (combina las predicciones)",
            ha="center", va="center", color="white",
            fontsize=10.5, fontweight="bold")

    # Resultado final
    ax.add_patch(FancyArrowPatch((5.0, 0.75), (5.0, 0.18),
                                 arrowstyle="-|>", mutation_scale=16,
                                 color=ft.DARK_GREEN, lw=2.2))
    ax.add_patch(FancyBboxPatch((3.3, -0.12), 3.4, 0.45,
                                boxstyle="round,pad=0.06",
                                fc=ft.DARK_GREEN, ec="none"))
    ax.text(5.0, 0.11, "Prediccion final (mas robusta)",
            ha="center", va="center", color="white",
            fontsize=10.5, fontweight="bold")

    ft.guardar(fig, p("09_stacking_diagrama.png"))


def fig_importancia_variables():
    """Importancia de variables de un RandomForest sobre el dataset ilustrativo."""
    # Usamos las dos variables del make_moons como referencia conceptual;
    # para el deck agregamos labels del dominio credito
    rng2 = np.random.default_rng(42)
    nombres = [
        "score_historial", "pct_deuda_ingreso",
        "ingreso_mensual", "monto_solicitado",
        "antiguedad_empleo", "edad",
        "num_creditos", "plazo_meses",
    ]
    # Simular importancias razonables (fumador/score dominan)
    imp = np.array([0.28, 0.22, 0.17, 0.11, 0.09, 0.07, 0.04, 0.02])
    idx = np.argsort(imp)

    fig, ax = plt.subplots(figsize=(8.8, 4.6))
    ft.limpia(ax, grid=True, keep=("bottom",))
    bars = ax.barh(range(len(imp)), imp[idx], color=ft.NAVY,
                   alpha=0.88, edgecolor="white", linewidth=0.8)
    ax.set_yticks(range(len(imp)))
    ax.set_yticklabels([nombres[i] for i in idx], fontsize=12, color=ft.GRAY)
    ax.set_xlabel("Importancia relativa", color=ft.GRAY, fontsize=12)
    ax.tick_params(axis="x", colors=ft.GRAY)
    # Etiquetas de valor
    for i, (bar, v) in enumerate(zip(bars, imp[idx])):
        ax.text(v + 0.004, bar.get_y() + bar.get_height() / 2,
                f"{v:.0%}", va="center", color=ft.NAVY,
                fontsize=10, fontweight="bold")
    ft.titulo(ax, "Importancia de variables (bosque aleatorio, credito)")
    ax.text(0.99, -0.14, "Nota: valores ilustrativos basados en perfil tipico",
            transform=ax.transAxes, ha="right", color=ft.GRAY,
            fontsize=8.5, style="italic")
    ft.guardar(fig, p("10_importancia_variables.png"))


def fig_comparacion_fronteras():
    """Panel 4 modelos: frontera de arbol, bosque, boosting."""
    clf_arb = DecisionTreeClassifier(max_depth=4, random_state=20).fit(X, y)
    clf_bos = RandomForestClassifier(n_estimators=100, max_depth=6,
                                     random_state=20).fit(X, y)
    clf_gb = GradientBoostingClassifier(n_estimators=80, max_depth=2,
                                        random_state=20).fit(X, y)
    fig, axs = plt.subplots(1, 3, figsize=(9.4, 3.5))
    _frontera(axs[0], clf_arb, "Arbol (prof. 4)", h=0.035)
    _frontera(axs[1], clf_bos, "Bosque (100 arb.)", h=0.035)
    _frontera(axs[2], clf_gb, "Boosting (GBM)", h=0.035)
    fig.subplots_adjust(wspace=0.08)
    ft.guardar(fig, p("11_comparacion_fronteras.png"))


def fig_no_free_lunch():
    """Diagrama conceptual del teorema 'no free lunch'."""
    fig, ax = plt.subplots(figsize=(8.6, 4.6))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 5.5)

    escenarios = [
        (0.5, "Datos\nlineales", ft.BLUEA,
         "Reg. Logistica\ngana", ft.DARK_GREEN),
        (3.3, "Pocas\nvariables", ft.TEAL,
         "Arbol\ngana", ft.DARK_GREEN),
        (6.1, "Miles de\nejemplos", ft.NAVY,
         "Bosque o\nBoosting gana", ft.DARK_GREEN),
    ]
    for cx, esc, c_esc, ganador, c_gan in escenarios:
        ax.add_patch(FancyBboxPatch((cx, 3.0), 2.5, 1.3,
                                    boxstyle="round,pad=0.07",
                                    fc=c_esc, ec="none", alpha=0.9))
        ax.text(cx + 1.25, 3.65, esc, ha="center", va="center",
                color="white", fontsize=10.5, fontweight="bold")
        ax.add_patch(FancyArrowPatch((cx + 1.25, 3.0), (cx + 1.25, 2.3),
                                     arrowstyle="-|>", mutation_scale=12,
                                     color=ft.GRAY, lw=1.4))
        ax.add_patch(FancyBboxPatch((cx, 1.3), 2.5, 0.85,
                                    boxstyle="round,pad=0.07",
                                    fc=c_gan, ec="none", alpha=0.9))
        ax.text(cx + 1.25, 1.72, ganador, ha="center", va="center",
                color="white", fontsize=10, fontweight="bold")

    ax.add_patch(FancyBboxPatch((1.5, 0.15), 7.0, 0.88,
                                boxstyle="round,pad=0.07",
                                fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=1.5))
    ax.text(5.0, 0.59,
            "No existe un modelo que siempre gane: depende del problema",
            ha="center", va="center", color=ft.NAVY,
            fontsize=11.5, fontweight="bold")

    ax.text(5.0, 5.3, "Teorema 'No Free Lunch': ningún modelo es el mejor en todo",
            ha="center", color=ft.NAVY, fontsize=12, fontweight="bold")
    ax.text(5.0, 5.0,
            "Por eso comparamos varios modelos con validacion cruzada",
            ha="center", color=ft.GRAY, fontsize=10, style="italic")

    ft.guardar(fig, p("12_no_free_lunch.png"))


if __name__ == "__main__":
    fig_panorama_modelos()
    fig_arbol_diagrama()
    fig_frontera_arbol_suave()
    fig_frontera_arbol_sobreajuste()
    fig_arbol_vs_sobreajuste()
    fig_bosque_esquema()
    fig_frontera_bosque()
    fig_bagging_vs_boosting()
    fig_boosting_secuencial()
    fig_stacking_diagrama()
    fig_importancia_variables()
    fig_comparacion_fronteras()
    fig_no_free_lunch()
    print("Figuras S20 generadas en", OUT)
