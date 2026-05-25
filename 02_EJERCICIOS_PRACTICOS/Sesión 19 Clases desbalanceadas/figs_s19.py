"""Genera las figuras de la presentacion TEORICA de la Sesion 19 (Clases
desbalanceadas). Diagramas conceptuales + ilustraciones calculadas con
sklearn/numpy para fraude (96/4) y casino (90/10).

Salida: ./img_teoria/*.png a 300 DPI."""
import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import (FancyBboxPatch, FancyArrowPatch,
                                Circle, Rectangle)
from sklearn.datasets import make_classification
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (confusion_matrix, roc_curve, auc,
                             precision_recall_curve,
                             average_precision_score)
from sklearn.model_selection import train_test_split

import figteoria as ft

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "img_teoria")
os.makedirs(OUT, exist_ok=True)
p = lambda nombre: os.path.join(OUT, nombre)

rng = np.random.default_rng(19)


# ===========================================================================
# FIG 1: Barras del desbalance — 96% normal vs 4% fraude
# ===========================================================================
def fig_barras_desbalance():
    """Barras HORIZONTALES para que la enorme (normal) se vea claramente
    a la izquierda y la diminuta (fraude) a la derecha."""
    fig, ax = plt.subplots(figsize=(8.6, 3.8))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 108)
    ax.set_ylim(-0.8, 1.8)

    # Barra normal (izquierda, larga)
    ax.add_patch(Rectangle((0, 0.85), 96, 0.7, fc=ft.NAVY, ec="none", zorder=2))
    ax.text(48, 1.2, "96 %  —  Transaccion normal  (2,498 casos)",
            ha="center", va="center", color="white", fontsize=13,
            fontweight="bold")

    # Barra fraude (izquierda, muy corta)
    ax.add_patch(Rectangle((0, 0.05), 4, 0.7, fc=ft.DARK_RED, ec="none", zorder=2))
    ax.text(4.3, 0.4, "4 %  —  Fraude  (102 casos)",
            ha="left", va="center", color=ft.DARK_RED, fontsize=12,
            fontweight="bold")

    # Flecha de escala
    ax.annotate("", xy=(96, -0.05), xytext=(0, -0.05),
                arrowprops=dict(arrowstyle="<->", color=ft.GRAY, lw=1.4))
    ax.text(48, -0.18, "96 unidades", ha="center", va="top",
            color=ft.GRAY, fontsize=10)
    ax.annotate("", xy=(4, -0.05), xytext=(0, -0.05),
                arrowprops=dict(arrowstyle="<->", color=ft.DARK_RED, lw=1.4))
    ax.text(2, -0.32, "4", ha="center", va="top",
            color=ft.DARK_RED, fontsize=10, fontweight="bold")

    # Texto inferior
    ax.text(54, -0.62,
            "Por cada 100 transacciones, solo 4 son fraude.  "
            "El modelo perezoso acierta el 96 % —  pero detecta 0 fraudes.",
            ha="center", va="top", color=ft.GRAY, fontsize=10.5,
            style="italic")
    ax.set_ylim(-0.85, 1.85)
    ft.titulo(ax, "El desbalance: 96 % normal vs 4 % fraude", size=15)
    ft.guardar(fig, p("01_barras_desbalance.png"))


# ===========================================================================
# FIG 2: La trampa del accuracy — "todo normal" => 96 % acierto, 0 fraude
# ===========================================================================
def fig_trampa_accuracy():
    fig, ax = plt.subplots(figsize=(8.6, 5.2))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 6)

    # ----- Cuadro del modelo perezoso -----
    ax.add_patch(FancyBboxPatch((0.3, 3.5), 3.8, 2.0,
                 boxstyle="round,pad=0.1,rounding_size=0.15",
                 fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=2))
    ax.text(2.2, 4.7, "Modelo 'perezoso'",
            ha="center", va="center", color=ft.NAVY,
            fontsize=13, fontweight="bold")
    ax.text(2.2, 4.15, "Siempre predice:\n\"NO es fraude\"",
            ha="center", va="center", color=ft.GRAY, fontsize=11)

    # ----- Flecha -----
    ax.add_patch(FancyArrowPatch((4.15, 4.5), (4.65, 4.5),
                 arrowstyle="-|>", mutation_scale=22,
                 color=ft.GRAY, lw=2.2))

    # ----- Resultados -----
    ax.add_patch(FancyBboxPatch((4.7, 3.5), 4.8, 2.0,
                 boxstyle="round,pad=0.1,rounding_size=0.15",
                 fc=ft.SOFT_GREEN, ec=ft.DARK_GREEN, lw=2))
    ax.text(7.1, 5.1, "Accuracy = 96 %  [OK]",
            ha="center", va="center", color=ft.DARK_GREEN,
            fontsize=13, fontweight="bold")
    ax.text(7.1, 4.6, "(parece excelente)",
            ha="center", va="center", color=ft.DARK_GREEN,
            fontsize=11, style="italic")

    # Pero en rojo: fraudes detectados = 0
    ax.add_patch(FancyBboxPatch((4.7, 1.0), 4.8, 2.1,
                 boxstyle="round,pad=0.1,rounding_size=0.15",
                 fc="#FADBD8", ec=ft.DARK_RED, lw=2))
    ax.text(7.1, 2.3, "Fraudes detectados = 0",
            ha="center", va="center", color=ft.DARK_RED,
            fontsize=14, fontweight="bold")
    ax.text(7.1, 1.72,
            "Recall = 0 %   Precision = 0 %",
            ha="center", va="center", color=ft.DARK_RED,
            fontsize=11)
    ax.text(7.1, 1.22, "(inservible para el banco)",
            ha="center", va="center", color=ft.DARK_RED,
            fontsize=10.5, style="italic")

    # Flecha diagonal al cuadro rojo
    ax.add_patch(FancyArrowPatch((4.15, 4.1), (4.65, 2.0),
                 arrowstyle="-|>", mutation_scale=18,
                 color=ft.DARK_RED, lw=1.8,
                 connectionstyle="arc3,rad=-0.25"))

    ft.titulo(ax,
              "La paradoja del accuracy: 96 % de aciertos, 0 fraudes atrapados",
              size=13)
    ft.guardar(fig, p("02_trampa_accuracy.png"))


# ===========================================================================
# FIG 3: Matriz de confusión resaltando el error costoso (FN)
# ===========================================================================
def fig_matriz_confusion():
    """Matriz de 2x2 grande y legible con celdas amplias."""
    fig, ax = plt.subplots(figsize=(8.6, 5.8))
    ft.sin_ejes(ax)
    # Coordenadas: x en [0,10], y en [0,7]
    ax.set_xlim(0, 10); ax.set_ylim(0, 7)

    # Celdas: (x_inicio, y_inicio, ancho, alto)
    celdas = [
        # Predicho FRAUDE  | Real FRAUDE   -> VP
        (2.2, 3.0, 3.5, 2.6, ft.DARK_GREEN, "VP",
         "Fraude detectado", "(acierto)", ""),
        # Predicho NO FRAUDE | Real FRAUDE -> FP
        (5.9, 3.0, 3.5, 2.6, "#E88080", "FP",
         "Alarma falsa", "(error leve)", "costo bajo"),
        # Predicho FRAUDE | Real NO FRAUDE -> FN
        (2.2, 0.2, 3.5, 2.6, ft.DARK_RED, "FN",
         "Fraude NO detectado", "(error grave)", "costo ALTO"),
        # Predicho NO FRAUDE | Real NO FRAUDE -> VN
        (5.9, 0.2, 3.5, 2.6, ft.SOFT_BLUE, "VN",
         "Transaccion OK", "(acierto)", ""),
    ]
    for (cx, cy, w, h, color, abrev, t1, t2, costo) in celdas:
        ax.add_patch(Rectangle((cx, cy), w, h, fc=color, ec="white",
                               lw=3, zorder=2))
        # Abreviatura grande
        ax.text(cx + w/2, cy + h*0.70, abrev,
                ha="center", va="center", color="white",
                fontsize=22, fontweight="bold", zorder=3)
        ax.text(cx + w/2, cy + h*0.42, t1,
                ha="center", va="center", color="white",
                fontsize=11, zorder=3)
        ax.text(cx + w/2, cy + h*0.24, t2,
                ha="center", va="center", color="white",
                fontsize=10, style="italic", zorder=3)
        if costo:
            ax.text(cx + w/2, cy + h*0.08, costo,
                    ha="center", va="center", color="white",
                    fontsize=9.5, fontweight="bold", zorder=3)

    # Etiquetas de ejes
    ax.text(3.95, 6.25, "Predicho: FRAUDE",
            ha="center", color=ft.NAVY, fontsize=12, fontweight="bold")
    ax.text(7.65, 6.25, "Predicho: NO FRAUDE",
            ha="center", color=ft.NAVY, fontsize=12, fontweight="bold")
    ax.text(1.5, 4.30, "Real:\nFRAUDE",
            ha="center", va="center", color=ft.NAVY,
            fontsize=12, fontweight="bold")
    ax.text(1.5, 1.50, "Real:\nNO FRAUDE",
            ha="center", va="center", color=ft.NAVY,
            fontsize=12, fontweight="bold")

    # Recuadro de atencion en FN
    ax.add_patch(Rectangle((2.2, 0.2), 3.5, 2.6, fc="none",
                            ec="#FFD700", lw=4, zorder=4))
    ax.text(3.95, -0.1, "<<< Este error es el mas costoso",
            ha="center", va="top", color=ft.DARK_RED,
            fontsize=10.5, fontweight="bold")

    ft.titulo(ax, "Matriz de confusion: el error costoso esta en la esquina FN",
              size=13)
    ft.guardar(fig, p("03_matriz_confusion.png"))


# ===========================================================================
# FIG 4: Precision y Recall ilustrados con la matriz de confusion
# ===========================================================================
def fig_precision_recall():
    """Dos paneles: Precision (columna resaltada) y Recall (fila resaltada).
    Las formulas van dentro de la figura, bien separadas de la matriz."""
    fig, axes = plt.subplots(1, 2, figsize=(9.4, 5.0))

    # ylim extendido hacia abajo para dar espacio a la formula
    YLIM_BOT = -1.1

    def _base_matriz(ax):
        ft.sin_ejes(ax)
        ax.set_xlim(0, 3.4)
        ax.set_ylim(YLIM_BOT, 3.6)
        celdas = [
            ((0.5, 1.7), ft.DARK_GREEN, "VP"),
            ((1.9, 1.7), "#E88080", "FP"),
            ((0.5, 0.2), ft.DARK_RED, "FN"),
            ((1.9, 0.2), ft.SOFT_BLUE, "VN"),
        ]
        for (cx, cy), color, abrev in celdas:
            ax.add_patch(Rectangle((cx, cy), 1.3, 1.3, fc=color, ec="white",
                                   lw=2.5, zorder=2))
            ax.text(cx + 0.65, cy + 0.65, abrev, ha="center", va="center",
                    color="white", fontsize=17, fontweight="bold", zorder=3)
        ax.text(1.15, 3.3, "Pred: FRAUDE", ha="center", color=ft.NAVY,
                fontsize=9.5, fontweight="bold")
        ax.text(2.55, 3.3, "Pred: NO FRAUDE", ha="center", color=ft.NAVY,
                fontsize=9.5, fontweight="bold")
        ax.text(0.22, 2.35, "Real:\nFRAUDE", ha="center", va="center",
                color=ft.NAVY, fontsize=9.5, fontweight="bold")
        ax.text(0.22, 0.85, "Real:\nNO", ha="center", va="center",
                color=ft.NAVY, fontsize=9.5, fontweight="bold")

    # ----- Panel izquierdo: Precision -----
    ax = axes[0]
    _base_matriz(ax)
    # Resaltar COLUMNA "Pred FRAUDE"
    ax.add_patch(Rectangle((0.5, 0.2), 1.3, 2.8, fc="none",
                            ec=ft.OCHRE, lw=3.5, zorder=4))
    # Formula en zona inferior (y negativo)
    ax.text(1.7, -0.1,
            "Precision = VP / (VP + FP)",
            ha="center", va="top", color=ft.OCHRE,
            fontsize=10.5, fontweight="bold")
    ax.text(1.7, -0.55,
            "De los marcados como fraude,\ncuantos eran fraude de verdad?",
            ha="center", va="top", color=ft.GRAY,
            fontsize=8.5, style="italic")
    ft.titulo(ax, "Precision", size=13)

    # ----- Panel derecho: Recall -----
    ax = axes[1]
    _base_matriz(ax)
    # Resaltar FILA "Real FRAUDE"
    ax.add_patch(Rectangle((0.5, 1.7), 2.7, 1.3, fc="none",
                            ec=ft.TEAL, lw=3.5, zorder=4))
    ax.text(1.7, -0.1,
            "Recall = VP / (VP + FN)",
            ha="center", va="top", color=ft.TEAL,
            fontsize=10.5, fontweight="bold")
    ax.text(1.7, -0.55,
            "De todos los fraudes reales,\na cuantos detecte?",
            ha="center", va="top", color=ft.GRAY,
            fontsize=8.5, style="italic")
    ft.titulo(ax, "Recall (sensibilidad)", size=13)

    fig.subplots_adjust(wspace=0.18, bottom=0.04, top=0.9)
    ft.guardar(fig, p("04_precision_recall.png"))


# ===========================================================================
# FIG 5: F1 como balance entre precision y recall
# ===========================================================================
def fig_f1():
    fig, ax = plt.subplots(figsize=(8.8, 4.8))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 5.5)

    # Circulo Precision
    cp = Circle((2.5, 2.8), 1.7, fc=ft.OCHRE, alpha=0.35, ec=ft.OCHRE, lw=2)
    ax.add_patch(cp)
    ax.text(1.3, 2.8, "Precision\n(de los marcados,\ncuantos son\nreales)",
            ha="center", va="center", color=ft.OCHRE, fontsize=10,
            fontweight="bold")

    # Circulo Recall
    cr = Circle((7.5, 2.8), 1.7, fc=ft.TEAL, alpha=0.35, ec=ft.TEAL, lw=2)
    ax.add_patch(cr)
    ax.text(8.7, 2.8, "Recall\n(de los reales,\ncuantos\natrapamos)",
            ha="center", va="center", color=ft.TEAL, fontsize=10,
            fontweight="bold")

    # Interseccion = F1
    ax.text(5.0, 2.8, "F1", ha="center", va="center", color=ft.NAVY,
            fontsize=22, fontweight="bold")
    ax.text(5.0, 2.15, "media armonica\nentre ambas",
            ha="center", va="center", color=ft.NAVY, fontsize=9.5,
            style="italic")

    # Formula
    ax.add_patch(FancyBboxPatch((2.8, 0.2), 4.4, 1.0,
                 boxstyle="round,pad=0.08,rounding_size=0.12",
                 fc=ft.LIGHT_BLUE, ec=ft.NAVY, lw=1.5))
    ax.text(5.0, 0.7,
            "F1 = 2 * (Precision * Recall) / (Precision + Recall)",
            ha="center", va="center", color=ft.NAVY,
            fontsize=11, fontweight="bold")

    ax.text(5.0, 4.9,
            "F1 = 0 si cualquiera de las dos es 0; F1 = 1 solo si ambas son 1",
            ha="center", va="top", color=ft.GRAY, fontsize=10.5,
            style="italic")

    ft.titulo(ax, "F1: el balance entre precision y recall", size=15)
    ft.guardar(fig, p("05_f1.png"))


# ===========================================================================
# FIG 6: ROC vs Precision-Recall (2 paneles con datos simulados desbalanceados)
# ===========================================================================
def fig_roc_vs_pr():
    # Datos desbalanceados: ~4% positivos
    X_sim, y_sim = make_classification(
        n_samples=2600, n_features=8, n_informative=5,
        weights=[0.96, 0.04], flip_y=0.02, random_state=19)
    X_tr, X_te, y_tr, y_te = train_test_split(
        X_sim, y_sim, test_size=0.3, stratify=y_sim, random_state=19)
    clf = LogisticRegression(max_iter=500, class_weight="balanced",
                              random_state=19)
    clf.fit(X_tr, y_tr)
    proba = clf.predict_proba(X_te)[:, 1]

    fpr, tpr, _ = roc_curve(y_te, proba)
    roc_auc = auc(fpr, tpr)
    prec, rec, _ = precision_recall_curve(y_te, proba)
    pr_auc = average_precision_score(y_te, proba)

    fig, axes = plt.subplots(1, 2, figsize=(9.4, 4.8))

    # ----- ROC -----
    ax = axes[0]
    ft.limpia(ax, grid=True)
    ax.plot([0, 1], [0, 1], "--", color=ft.LGRAY, lw=1.5, label="Azar")
    ax.plot(fpr, tpr, color=ft.NAVY, lw=2.4,
            label=f"AUC = {roc_auc:.2f}")
    ax.fill_between(fpr, tpr, alpha=0.12, color=ft.NAVY)
    ax.set_xlabel("Tasa de falsos positivos", color=ft.GRAY, fontsize=11)
    ax.set_ylabel("Tasa de verdaderos positivos", color=ft.GRAY, fontsize=11)
    ax.legend(loc="lower right", fontsize=10, frameon=True)
    # Anotar que ROC se ve "optimista"
    ax.text(0.5, 0.18, "Parece buena,\npero hay solo 4% fraudes",
            ha="center", color=ft.DARK_RED, fontsize=9.5, style="italic")
    ft.titulo(ax, "Curva ROC", size=13)

    # ----- Precision-Recall -----
    ax = axes[1]
    ft.limpia(ax, grid=True)
    baseline = y_te.mean()
    ax.axhline(baseline, ls="--", color=ft.LGRAY, lw=1.5,
               label=f"Azar (baseline = {baseline:.2f})")
    ax.plot(rec, prec, color=ft.TEAL, lw=2.4,
            label=f"AP = {pr_auc:.2f}")
    ax.fill_between(rec, prec, alpha=0.12, color=ft.TEAL)
    ax.set_xlabel("Recall (sensibilidad)", color=ft.GRAY, fontsize=11)
    ax.set_ylabel("Precision", color=ft.GRAY, fontsize=11)
    ax.set_ylim(-0.05, 1.05)
    ax.legend(loc="upper right", fontsize=10, frameon=True)
    ax.text(0.5, 0.5, "Mas informativa\ncon desbalance",
            ha="center", color=ft.DARK_GREEN, fontsize=9.5, style="italic",
            fontweight="bold")
    ft.titulo(ax, "Curva Precision-Recall", size=13)

    fig.subplots_adjust(wspace=0.32, bottom=0.18)
    ft.guardar(fig, p("06_roc_vs_pr.png"))


# ===========================================================================
# FIG 7: Remuestreo — oversampling vs undersampling (barras antes/despues)
# ===========================================================================
def fig_remuestreo():
    fig, axes = plt.subplots(1, 3, figsize=(9.4, 4.6))
    grupos = ["Normal", "Fraude"]
    orig = [2498, 102]  # ~96/4
    over = [2498, 2498]
    under = [102, 102]
    colores = [ft.NAVY, ft.DARK_RED]

    datos = [orig, over, under]
    titulos = ["Original", "Oversampling\n(se duplican minoria)",
               "Undersampling\n(se recorta mayoria)"]
    notas = ["90.8 % vs 9.2 %\nDesbalanceado",
             "50 % vs 50 %\nBalanceado",
             "50 % vs 50 %\nBalanceado"]

    for i, (ax, datos_, tit, nota) in enumerate(
            zip(axes, datos, titulos, notas)):
        ft.limpia(ax, grid=True)
        ax.bar(grupos, datos_, color=colores, width=0.55, edgecolor="white",
               linewidth=1.0)
        ax.set_yticks([])
        for j, v in enumerate(datos_):
            ax.text(j, v + max(datos_) * 0.02, str(v), ha="center",
                    color=colores[j], fontsize=10, fontweight="bold")
        ax.text(0.5, -0.22, nota, transform=ax.transAxes, ha="center",
                color=ft.GRAY, fontsize=9.5, style="italic")
        ft.titulo(ax, tit, size=12)

    fig.subplots_adjust(bottom=0.26, wspace=0.2)
    ft.guardar(fig, p("07_remuestreo.png"))


# ===========================================================================
# FIG 8: SMOTE — puntos originales + sinteticos en dispersion
# ===========================================================================
def fig_smote():
    # Generar clase minoritaria (fraudes) como 2D ilustrativo
    np.random.seed(19)
    n_min = 18
    X_min = np.column_stack([
        rng.normal(2.0, 0.5, n_min),
        rng.normal(2.0, 0.5, n_min),
    ])
    # Mayoritaria
    n_may = 200
    X_may = np.column_stack([
        rng.normal(0.0, 1.4, n_may),
        rng.normal(0.0, 1.4, n_may),
    ])

    # SMOTE manual: para cada punto minoritario, crea 2 sinteticos
    # interpolando con sus k=3 vecinos
    sinteticos = []
    for i in range(n_min):
        dists = np.sqrt(((X_min - X_min[i]) ** 2).sum(axis=1))
        dists[i] = np.inf
        vecinos_idx = np.argsort(dists)[:3]
        for vj in vecinos_idx[:2]:
            alpha = rng.uniform(0.1, 0.9)
            sinteticos.append(X_min[i] + alpha * (X_min[vj] - X_min[i]))
    sinteticos = np.array(sinteticos)

    fig, ax = plt.subplots(figsize=(8.6, 5.2))
    ft.limpia(ax, grid=True)

    ax.scatter(X_may[:, 0], X_may[:, 1], c=ft.NAVY, s=22, alpha=0.5,
               edgecolors="white", lw=0.4, label="Clase mayoritaria (normal)")
    ax.scatter(X_min[:, 0], X_min[:, 1], c=ft.DARK_RED, s=80, alpha=0.9,
               edgecolors="white", lw=1, zorder=4,
               label="Clase minoritaria (fraude)")
    ax.scatter(sinteticos[:, 0], sinteticos[:, 1],
               c=ft.OCHRE, s=60, alpha=0.85,
               edgecolors="white", marker="D", lw=0.8, zorder=5,
               label="Sinteticos SMOTE")

    # Dibujar unas lineas de interpolacion para ilustrar el mecanismo
    idx_ej = [0, 4, 9]
    for i in idx_ej:
        dists = np.sqrt(((X_min - X_min[i]) ** 2).sum(axis=1))
        dists[i] = np.inf
        vj = np.argmin(dists)
        ax.plot([X_min[i, 0], X_min[vj, 0]],
                [X_min[i, 1], X_min[vj, 1]],
                "--", color=ft.OCHRE, lw=1.4, alpha=0.7, zorder=3)

    ax.legend(loc="upper left", fontsize=10, frameon=True)
    ax.set_xlabel("Variable 1 (estandarizada)", color=ft.GRAY, fontsize=11)
    ax.set_ylabel("Variable 2 (estandarizada)", color=ft.GRAY, fontsize=11)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, "SMOTE: puntos sinteticos creados entre vecinos de la minoria",
              size=13)
    ft.guardar(fig, p("08_smote.png"))


# ===========================================================================
# FIG 9: Ajuste de umbral — curva precision/recall vs threshold
# ===========================================================================
def fig_umbral():
    X_sim, y_sim = make_classification(
        n_samples=2600, n_features=8, n_informative=5,
        weights=[0.96, 0.04], flip_y=0.02, random_state=19)
    X_tr, X_te, y_tr, y_te = train_test_split(
        X_sim, y_sim, test_size=0.3, stratify=y_sim, random_state=19)
    clf = LogisticRegression(max_iter=500, class_weight="balanced",
                              random_state=19)
    clf.fit(X_tr, y_tr)
    proba = clf.predict_proba(X_te)[:, 1]
    prec, rec, thresholds = precision_recall_curve(y_te, proba)

    # Agregar threshold = 0 al final para alinear
    # precision_recall_curve devuelve len(thresholds) = len(prec)-1
    thresholds_ext = np.append(thresholds, 1.0)

    fig, ax = plt.subplots(figsize=(8.8, 4.8))
    ft.limpia(ax, grid=True)
    ax.plot(thresholds_ext, prec, color=ft.OCHRE, lw=2.2, label="Precision")
    ax.plot(thresholds_ext, rec, color=ft.TEAL, lw=2.2, label="Recall")

    # Umbral default 0.5
    ax.axvline(0.5, color=ft.GRAY, ls="--", lw=1.8, label="Umbral default 0.5")
    ax.text(0.52, 0.92, "0.5\n(default)", color=ft.GRAY, fontsize=9.5)

    # Umbral bajo ejemplo (mas recall)
    um_bajo = 0.15
    ax.axvline(um_bajo, color=ft.TEAL, ls=":", lw=1.8,
               label=f"Umbral bajo ({um_bajo})")
    ax.text(um_bajo + 0.01, 0.55, f"{um_bajo}\n(mas recall)", color=ft.TEAL,
            fontsize=9.5)

    # Umbral alto ejemplo (mas precision)
    um_alto = 0.75
    ax.axvline(um_alto, color=ft.OCHRE, ls=":", lw=1.8,
               label=f"Umbral alto ({um_alto})")
    ax.text(um_alto + 0.01, 0.55, f"{um_alto}\n(mas precision)",
            color=ft.OCHRE, fontsize=9.5)

    ax.set_xlabel("Umbral de decision (threshold)", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Valor de la metrica", color=ft.GRAY, fontsize=12)
    ax.set_xlim(-0.02, 1.02); ax.set_ylim(-0.04, 1.08)
    ax.legend(loc="center left", fontsize=9.5, frameon=True)
    ft.titulo(ax,
              "Mover el umbral cambia precision y recall: tu decides el equilibrio",
              size=12)
    ft.guardar(fig, p("09_umbral.png"))


# ===========================================================================
# FIG 10: Esquema de contaminacion (data leakage por remuestrear antes del split)
# ===========================================================================
def fig_leakage():
    fig, axes = plt.subplots(1, 2, figsize=(9.4, 4.8))

    for ax, correcto, tit in zip(
            axes,
            [False, True],
            ["INCORRECTO (data leakage)", "CORRECTO"]):
        ft.sin_ejes(ax)
        ax.set_xlim(0, 6); ax.set_ylim(0, 5.5)

        if not correcto:
            # Oversampling ANTES del split — contaminacion
            ax.add_patch(FancyBboxPatch(
                (0.3, 3.8), 5.4, 1.3,
                boxstyle="round,pad=0.08,rounding_size=0.12",
                fc="#FADBD8", ec=ft.DARK_RED, lw=2))
            ax.text(3.0, 4.55, "TODOS los datos (con SMOTE ya aplicado)",
                    ha="center", va="center", color=ft.DARK_RED,
                    fontsize=10, fontweight="bold")
            ax.text(3.0, 4.05,
                    "Los sinteticos del SMOTE 'filtran' info del test al train",
                    ha="center", va="center", color=ft.DARK_RED,
                    fontsize=8.5, style="italic")
            # split
            ax.add_patch(FancyArrowPatch((2.0, 3.78), (1.5, 3.0),
                         arrowstyle="-|>", mutation_scale=14,
                         color=ft.GRAY, lw=1.6))
            ax.add_patch(FancyArrowPatch((4.0, 3.78), (4.5, 3.0),
                         arrowstyle="-|>", mutation_scale=14,
                         color=ft.GRAY, lw=1.6))
            ax.add_patch(FancyBboxPatch(
                (0.3, 1.6), 2.4, 1.2,
                boxstyle="round,pad=0.06,rounding_size=0.1",
                fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=1.5))
            ax.text(1.5, 2.2, "Entrenamiento\n(contaminado)", ha="center",
                    va="center", color=ft.NAVY, fontsize=9.5, fontweight="bold")
            ax.add_patch(FancyBboxPatch(
                (3.3, 1.6), 2.4, 1.2,
                boxstyle="round,pad=0.06,rounding_size=0.1",
                fc="#FADBD8", ec=ft.DARK_RED, lw=1.5))
            ax.text(4.5, 2.2, "Prueba\n(contaminada)", ha="center",
                    va="center", color=ft.DARK_RED, fontsize=9.5,
                    fontweight="bold")
            ax.text(3.0, 0.9, "ERROR: la evaluacion no es honesta",
                    ha="center", color=ft.DARK_RED, fontsize=9.5,
                    fontweight="bold")
        else:
            # Flujo correcto
            ax.add_patch(FancyBboxPatch(
                (0.3, 3.8), 5.4, 1.3,
                boxstyle="round,pad=0.08,rounding_size=0.12",
                fc=ft.LIGHT_BLUE, ec=ft.NAVY, lw=2))
            ax.text(3.0, 4.55, "TODOS los datos (originales, sin balanceo)",
                    ha="center", va="center", color=ft.NAVY,
                    fontsize=10, fontweight="bold")
            ax.text(3.0, 4.05, "Primero se separa; luego se balancea SOLO el train",
                    ha="center", va="center", color=ft.GRAY,
                    fontsize=8.5, style="italic")
            ax.add_patch(FancyArrowPatch((2.0, 3.78), (1.5, 3.0),
                         arrowstyle="-|>", mutation_scale=14,
                         color=ft.GRAY, lw=1.6))
            ax.add_patch(FancyArrowPatch((4.0, 3.78), (4.5, 3.0),
                         arrowstyle="-|>", mutation_scale=14,
                         color=ft.GRAY, lw=1.6))
            ax.add_patch(FancyBboxPatch(
                (0.3, 1.6), 2.4, 1.2,
                boxstyle="round,pad=0.06,rounding_size=0.1",
                fc=ft.SOFT_GREEN, ec=ft.DARK_GREEN, lw=1.5))
            ax.text(1.5, 2.2, "Entrenamiento\n+ SMOTE aqui",
                    ha="center", va="center", color=ft.DARK_GREEN,
                    fontsize=9.5, fontweight="bold")
            ax.add_patch(FancyBboxPatch(
                (3.3, 1.6), 2.4, 1.2,
                boxstyle="round,pad=0.06,rounding_size=0.1",
                fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=1.5))
            ax.text(4.5, 2.2, "Prueba\n(intacta)", ha="center",
                    va="center", color=ft.NAVY, fontsize=9.5,
                    fontweight="bold")
            ax.text(3.0, 0.9, "CORRECTO: evaluacion honesta",
                    ha="center", color=ft.DARK_GREEN, fontsize=9.5,
                    fontweight="bold")
        col_tit = ft.DARK_RED if not correcto else ft.DARK_GREEN
        ax.set_title(tit, color=col_tit, fontsize=12, fontweight="bold",
                     pad=6)

    fig.subplots_adjust(wspace=0.15, bottom=0.06)
    ft.guardar(fig, p("10_leakage.png"))


# ===========================================================================
# FIG 11: Tabla comparativa de metricas (barras horizontales estilizadas)
# ===========================================================================
def fig_comparacion_metricas():
    """Barras horizontales comparando accuracy vs recall/precision/F1
    para un modelo que predice siempre 'no fraude'."""
    metricas = ["Accuracy", "Precision\n(fraude)", "Recall\n(fraude)", "F1\n(fraude)"]
    vals = [0.96, 0.0, 0.0, 0.0]
    colores = [ft.GRAY, ft.DARK_RED, ft.DARK_RED, ft.DARK_RED]

    fig, ax = plt.subplots(figsize=(8.2, 4.0))
    ft.limpia(ax, keep=("bottom",), grid=False)
    ax.set_xlim(0, 1.15)
    ys = range(len(metricas) - 1, -1, -1)
    for y_, val, met, col in zip(ys, vals, metricas, colores):
        ax.barh(y_, val, color=col, height=0.55, edgecolor="white", lw=0)
        ax.text(val + 0.02, y_, f"{val:.0%}", va="center", color=col,
                fontsize=12, fontweight="bold")
    ax.set_yticks(list(ys))
    ax.set_yticklabels(metricas, fontsize=11, color=ft.GRAY)
    ax.set_xlabel("Valor de la metrica (0 a 1)", color=ft.GRAY, fontsize=11)
    ax.set_xticks([0, 0.25, 0.5, 0.75, 1.0])
    ax.xaxis.set_tick_params(labelcolor=ft.GRAY)
    ax.axvline(0.96, color=ft.GRAY, ls="--", lw=1.2)
    ax.text(0.96, len(metricas) - 0.4, "96 % accuracy\n(parece bien)",
            color=ft.GRAY, fontsize=8.5, ha="center", style="italic")
    ax.text(0.5, -0.9,
            "Recall = 0 y F1 = 0: el modelo no sirve para detectar fraude",
            ha="center", va="top", color=ft.DARK_RED, fontsize=10.5,
            fontweight="bold")
    ax.set_ylim(-1.5, len(metricas))
    ft.titulo(ax, "Modelo que siempre dice 'no fraude': metricas reales",
              size=12)
    ft.guardar(fig, p("11_comparacion_metricas.png"))


# ===========================================================================
# FIG 12: Pesos de clase — diagrama conceptual
# ===========================================================================
def fig_pesos_clase():
    fig, ax = plt.subplots(figsize=(8.6, 4.6))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 5)

    # Izquierda: sin pesos
    ax.add_patch(FancyBboxPatch(
        (0.3, 1.5), 3.8, 2.5,
        boxstyle="round,pad=0.1,rounding_size=0.15",
        fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=2))
    ax.text(2.2, 3.6, "Sin pesos", ha="center", color=ft.NAVY,
            fontsize=12, fontweight="bold")
    ax.text(2.2, 2.8, "Normal: peso = 1", ha="center", color=ft.NAVY,
            fontsize=11)
    ax.text(2.2, 2.2, "Fraude: peso = 1", ha="center", color=ft.GRAY,
            fontsize=11)
    ax.text(2.2, 1.65,
            "El modelo ignora que fraude es raro\ny lo aprende mal",
            ha="center", va="bottom", color=ft.GRAY,
            fontsize=9, style="italic")

    # Flecha
    ax.add_patch(FancyArrowPatch((4.2, 2.75), (5.8, 2.75),
                 arrowstyle="-|>", mutation_scale=22,
                 color=ft.DARK_GREEN, lw=2.5))
    ax.text(5.0, 3.1, "class_weight\n='balanced'",
            ha="center", color=ft.DARK_GREEN, fontsize=10,
            fontweight="bold")

    # Derecha: con pesos
    ax.add_patch(FancyBboxPatch(
        (5.9, 1.5), 3.8, 2.5,
        boxstyle="round,pad=0.1,rounding_size=0.15",
        fc=ft.SOFT_GREEN, ec=ft.DARK_GREEN, lw=2))
    ax.text(7.8, 3.6, "Con pesos", ha="center", color=ft.DARK_GREEN,
            fontsize=12, fontweight="bold")
    ax.text(7.8, 2.8, "Normal: peso = 1", ha="center", color=ft.NAVY,
            fontsize=11)
    ax.text(7.8, 2.2, "Fraude: peso = 24", ha="center", color=ft.DARK_RED,
            fontsize=11, fontweight="bold")
    ax.text(7.8, 1.65,
            "Equivocar un fraude 'duele' 24 veces mas:\nmodel aprende a detectarlo",
            ha="center", va="bottom", color=ft.DARK_GREEN,
            fontsize=9, style="italic")

    ft.titulo(ax,
              "Pesos de clase: cada error de fraude vale mas para el modelo",
              size=13)
    ft.guardar(fig, p("12_pesos_clase.png"))


# ===========================================================================
# Punto de entrada
# ===========================================================================
if __name__ == "__main__":
    fig_barras_desbalance()
    fig_trampa_accuracy()
    fig_matriz_confusion()
    fig_precision_recall()
    fig_f1()
    fig_roc_vs_pr()
    fig_remuestreo()
    fig_smote()
    fig_umbral()
    fig_leakage()
    fig_comparacion_metricas()
    fig_pesos_clase()
    print("Figuras S19 generadas en", OUT)
