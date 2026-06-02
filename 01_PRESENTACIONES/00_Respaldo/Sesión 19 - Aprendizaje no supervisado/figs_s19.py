"""Genera las figuras de la presentacion TEORICA de la Sesion 19 (Aprendizaje
no supervisado: PCA y clustering). Diagramas conceptuales + graficas reales
sobre los datos de los ejercicios (apostadores y municipios) + formulas
matematicas renderizadas como PNG.

Salida: ./img_teoria/*.png a 300 DPI."""
import os
import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from scipy.cluster.hierarchy import linkage, dendrogram
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

import figteoria as ft

BASE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(BASE, "img_teoria")
os.makedirs(OUT, exist_ok=True)
p = lambda nombre: os.path.join(OUT, nombre)


def _carga(ejercicio, id_col):
    """Lee datos.csv de un ejercicio, quita el id e imputa NAs con la mediana."""
    df = pd.read_csv(os.path.join(BASE, ejercicio, "datos.csv"))
    df = df.drop(columns=[id_col], errors="ignore")
    for col in df.columns:
        if df[col].isna().any():
            df[col] = df[col].fillna(df[col].median())
    return df


# ===========================================================================
# FORMULAS (PNG con mathtext, fondo blanco para mezclar con el slide)
# ===========================================================================
def fig_formula(nombre, latex, *, fs=30, w=9.0, h=2.3):
    fig, ax = plt.subplots(figsize=(w, h))
    ax.axis("off")
    ax.text(0.5, 0.5, latex, ha="center", va="center", fontsize=fs,
            color=ft.NAVY)
    ft.guardar(fig, p(nombre), pad=0.18)


def formulas():
    fig_formula("f_estandarizar",
                r"$z_{ij} = \dfrac{x_{ij} - \mu_j}{\sigma_j}$")
    fig_formula("f_distancia",
                r"$d(\mathbf{x}_i,\mathbf{x}_{i'}) = "
                r"\sqrt{\sum_{j=1}^{p}\,(x_{ij}-x_{i'j})^2}$")
    fig_formula("f_kmeans",
                r"$\min_{C_1,\dots,C_K}\ \sum_{k=1}^{K}\ "
                r"\sum_{i \in C_k}\ \| \mathbf{x}_i - "
                r"\mu_k \|^{2}$", fs=28)
    fig_formula("f_pc1",
                r"$z_{i1} = \phi_{11}x_{i1} + \phi_{21}x_{i2} + \cdots + "
                r"\phi_{p1}x_{ip}\qquad \sum_{j=1}^{p}\phi_{j1}^{2}=1$",
                fs=24, w=9.6)
    fig_formula("f_pca_var",
                r"$\max_{\phi_1}\ "
                r"\mathrm{Var}(\mathbf{X}\,\phi_1)"
                r"\quad \mathrm{sujeto\ a}\quad \|\phi_1\|=1$",
                fs=26, w=9.0)
    fig_formula("f_pve",
                r"$\text{PVE}_m = \dfrac{\lambda_m}"
                r"{\lambda_1+\lambda_2+\cdots+\lambda_p}$")
    fig_formula("f_silueta",
                r"$s(i) = \dfrac{b(i) - a(i)}{\max\{\,a(i),\,b(i)\,\}}"
                r"\in[-1,\,1]$", fs=27)


# ===========================================================================
# CLUSTERING — figuras conceptuales
# ===========================================================================
def fig_supervisado_vs_no():
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.2))
    a = axs[0]
    ft.sin_ejes(a)
    a.set_xlim(0, 10); a.set_ylim(0, 4.5)
    a.add_patch(FancyBboxPatch((0.2, 3.5), 9.6, 0.75,
                boxstyle="round,pad=0.05,rounding_size=0.1",
                fc=ft.NAVY, ec="none"))
    a.text(5.0, 3.87, "SUPERVISADO", ha="center", va="center",
           color="white", fontsize=13, fontweight="bold")
    np.random.seed(1)
    pts_a = np.random.uniform(0.5, 4.5, (18, 2))
    pts_b = np.random.uniform(5.5, 9.5, (18, 2))
    pts_a[:, 1] = 0.8 + pts_a[:, 1] * 0.55
    pts_b[:, 1] = 0.8 + pts_b[:, 1] * 0.35
    a.scatter(pts_a[:, 0], pts_a[:, 1], c=ft.NAVY, s=55,
              edgecolors="white", lw=0.8, zorder=3, label="Etiqueta A")
    a.scatter(pts_b[:, 0], pts_b[:, 1], c=ft.RED_PT, s=55, marker="^",
              edgecolors="white", lw=0.8, zorder=3, label="Etiqueta B")
    a.legend(loc="lower center", ncol=2, fontsize=9.5, frameon=False,
             bbox_to_anchor=(0.5, -0.02))
    a.text(5.0, 0.22, "Etiquetas CONOCIDAS de antemano", ha="center",
           color=ft.GRAY, fontsize=10, style="italic")
    b = axs[1]
    ft.sin_ejes(b)
    b.set_xlim(0, 10); b.set_ylim(0, 4.5)
    b.add_patch(FancyBboxPatch((0.2, 3.5), 9.6, 0.75,
                boxstyle="round,pad=0.05,rounding_size=0.1",
                fc=ft.TEAL, ec="none"))
    b.text(5.0, 3.87, "NO SUPERVISADO", ha="center", va="center",
           color="white", fontsize=13, fontweight="bold")
    all_pts = np.vstack([pts_a, pts_b])
    b.scatter(all_pts[:, 0], all_pts[:, 1], c=ft.SOFT_BLUE,
              edgecolors=ft.GRAY, lw=0.8, s=55, zorder=3)
    b.text(5.0, 0.22, "NO hay etiquetas: el algoritmo DESCUBRE la estructura",
           ha="center", color=ft.GRAY, fontsize=10, style="italic")
    fig.subplots_adjust(wspace=0.06, bottom=0.12)
    ft.guardar(fig, p("01_supervisado_vs_no.png"))


def fig_antes_despues():
    X, y = make_blobs(n_samples=180, centers=3, cluster_std=0.85,
                      random_state=19)
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.4))
    colores = [ft.NAVY, ft.RED_PT, ft.DARK_GREEN]
    a = axs[0]
    ft.limpia(a, grid=True)
    a.scatter(X[:, 0], X[:, 1], c=ft.SOFT_BLUE, edgecolors=ft.GRAY, lw=0.6,
              s=40, zorder=3)
    a.set_xticks([]); a.set_yticks([])
    ft.titulo(a, "Antes: puntos sin etiqueta", size=13)
    a.text(0.5, -0.1, "Solo vemos datos... sin grupos definidos",
           transform=a.transAxes, ha="center", color=ft.GRAY, fontsize=10,
           style="italic")
    b = axs[1]
    ft.limpia(b, grid=True)
    for c in range(3):
        m = y == c
        b.scatter(X[m, 0], X[m, 1], c=colores[c], edgecolors="white", lw=0.7,
                  s=40, zorder=3, label=f"Grupo {c + 1}")
    b.set_xticks([]); b.set_yticks([])
    b.legend(loc="upper right", fontsize=10, frameon=True)
    ft.titulo(b, "Despues: el clustering descubrio 3 grupos", size=13)
    b.text(0.5, -0.1, "El algoritmo agrupo los puntos por similitud",
           transform=b.transAxes, ha="center", color=ft.GRAY, fontsize=10,
           style="italic")
    fig.subplots_adjust(wspace=0.12, bottom=0.16)
    ft.guardar(fig, p("02_antes_despues.png"))


def fig_kmeans_pasos():
    X_k, _ = make_blobs(n_samples=90, centers=3, cluster_std=0.9,
                        random_state=7)
    colores = [ft.NAVY, ft.RED_PT, ft.DARK_GREEN]
    fig, axs = plt.subplots(2, 2, figsize=(9.4, 7.2))
    axs = axs.ravel()
    np.random.seed(42)
    centroides = X_k[np.random.choice(len(X_k), 3, replace=False)]
    ax = axs[0]
    ft.limpia(ax, grid=True)
    ax.scatter(X_k[:, 0], X_k[:, 1], c=ft.SOFT_BLUE, edgecolors=ft.GRAY,
               lw=0.5, s=35, zorder=2)
    for i, c in enumerate(centroides):
        ax.scatter(*c, marker="X", c=colores[i], s=220, edgecolors="white",
                   lw=1.4, zorder=5)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, "Paso 1: K centroides al azar", size=12)

    def asignar(X_, C_):
        d = np.array([[np.linalg.norm(x - c) for c in C_] for x in X_])
        return np.argmin(d, axis=1)

    labels = asignar(X_k, centroides)
    ax = axs[1]
    ft.limpia(ax, grid=True)
    for c in range(3):
        m = labels == c
        ax.scatter(X_k[m, 0], X_k[m, 1], c=colores[c], edgecolors="white",
                   lw=0.6, s=35, zorder=3)
    for i, c in enumerate(centroides):
        ax.scatter(*c, marker="X", c=colores[i], s=220, edgecolors="black",
                   lw=1.4, zorder=5)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, "Paso 2: asignar al centroide mas cercano", size=12)

    nuevos = np.array([X_k[labels == c].mean(axis=0) for c in range(3)])
    ax = axs[2]
    ft.limpia(ax, grid=True)
    for c in range(3):
        m = labels == c
        ax.scatter(X_k[m, 0], X_k[m, 1], c=colores[c], edgecolors="white",
                   lw=0.6, s=35, alpha=0.55, zorder=2)
    for i in range(3):
        ax.add_patch(FancyArrowPatch(centroides[i], nuevos[i],
                     arrowstyle="-|>", mutation_scale=16, color=colores[i],
                     lw=2.0))
        ax.scatter(*nuevos[i], marker="X", c=colores[i], s=220,
                   edgecolors="black", lw=1.4, zorder=5)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, "Paso 3: mover al promedio del grupo", size=12)

    km = KMeans(n_clusters=3, n_init=10, random_state=19)
    labels_f = km.fit_predict(X_k)
    ax = axs[3]
    ft.limpia(ax, grid=True)
    for c in range(3):
        m = labels_f == c
        ax.scatter(X_k[m, 0], X_k[m, 1], c=colores[c], edgecolors="white",
                   lw=0.6, s=35, zorder=3)
    for i, c in enumerate(km.cluster_centers_):
        ax.scatter(*c, marker="X", c=colores[i], s=220, edgecolors="black",
                   lw=1.4, zorder=5)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, "Paso 4: repetir hasta converger", size=12)
    fig.subplots_adjust(hspace=0.28, wspace=0.1, bottom=0.04)
    ft.guardar(fig, p("03_kmeans_pasos.png"))


def fig_codo():
    X_c, _ = make_blobs(n_samples=200, centers=4, cluster_std=0.8,
                        random_state=19)
    ks = range(1, 11)
    inercias = [KMeans(n_clusters=k, n_init=10, random_state=19)
                .fit(X_c).inertia_ for k in ks]
    fig, ax = plt.subplots(figsize=(8.4, 4.8))
    ft.limpia(ax, grid=True)
    ax.plot(list(ks), inercias, "-o", color=ft.NAVY, lw=2.4, markersize=7,
            markeredgecolor="white", markeredgewidth=0.8)
    ax.scatter([4], [inercias[3]], c=ft.DARK_RED, s=180, zorder=5,
               edgecolors="white", lw=1.5)
    ax.annotate("codo aqui\nk = 4", (4, inercias[3]),
                textcoords="offset points", xytext=(28, 18),
                color=ft.DARK_RED, fontsize=12, fontweight="bold",
                arrowprops=dict(arrowstyle="-|>", color=ft.DARK_RED, lw=1.4))
    ax.set_xlabel("Numero de grupos k", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Inercia (WSS: suma de distancias al centroide)",
                  color=ft.GRAY, fontsize=12)
    ft.titulo(ax, "Metodo del codo: donde la curva deja de caer rapido")
    ft.guardar(fig, p("04_codo.png"))


def fig_silueta_concepto():
    """Silueta vs k (datos sinteticos con 4 grupos claros)."""
    X_c, _ = make_blobs(n_samples=240, centers=4, cluster_std=0.8,
                        random_state=19)
    ks = range(2, 9)
    sils = [silhouette_score(X_c, KMeans(n_clusters=k, n_init=10,
            random_state=19).fit_predict(X_c)) for k in ks]
    fig, ax = plt.subplots(figsize=(8.4, 4.8))
    ft.limpia(ax, grid=True)
    ax.plot(list(ks), sils, "-o", color=ft.TEAL, lw=2.4, markersize=7,
            markeredgecolor="white", markeredgewidth=0.8)
    kbest = list(ks)[int(np.argmax(sils))]
    ax.scatter([kbest], [max(sils)], c=ft.DARK_RED, s=180, zorder=5,
               edgecolors="white", lw=1.5)
    ax.annotate(f"mas alta\nk = {kbest}", (kbest, max(sils)),
                textcoords="offset points", xytext=(24, -8),
                color=ft.DARK_RED, fontsize=12, fontweight="bold",
                arrowprops=dict(arrowstyle="-|>", color=ft.DARK_RED, lw=1.4))
    ax.set_xlabel("Numero de grupos k", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Silueta promedio", color=ft.GRAY, fontsize=12)
    ft.titulo(ax, "Metodo de la silueta: elige la k con valor MAS ALTO")
    ft.guardar(fig, p("05_silueta.png"))


def fig_estandarizar():
    np.random.seed(19)
    n = 80
    ingreso = np.random.normal(120000, 40000, n)
    pct = np.random.uniform(10, 90, n)
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.4))
    a = axs[0]
    ft.limpia(a, grid=True)
    a.scatter(ingreso, pct, c=ft.NAVY, s=35, edgecolors="white", lw=0.5)
    a.set_xlabel("PIB per capita (pesos)", color=ft.GRAY, fontsize=11)
    a.set_ylabel("% poblacion rural", color=ft.GRAY, fontsize=11)
    ft.titulo(a, "SIN estandarizar", size=13)
    a.text(0.5, -0.24,
           "El PIB (miles) domina la distancia;\nel % casi no cuenta",
           transform=a.transAxes, ha="center", color=ft.DARK_RED, fontsize=10)
    b = axs[1]
    ft.limpia(b, grid=True)
    z1 = (ingreso - ingreso.mean()) / ingreso.std()
    z2 = (pct - pct.mean()) / pct.std()
    b.scatter(z1, z2, c=ft.DARK_GREEN, s=35, edgecolors="white", lw=0.5)
    b.set_xlabel("PIB per capita (z-score)", color=ft.GRAY, fontsize=11)
    b.set_ylabel("% rural (z-score)", color=ft.GRAY, fontsize=11)
    ft.titulo(b, "CON estandarizar", size=13)
    b.text(0.5, -0.24, "Ambas variables pesan igual;\nla distancia es justa",
           transform=b.transAxes, ha="center", color=ft.DARK_GREEN,
           fontsize=10)
    fig.subplots_adjust(bottom=0.3, wspace=0.32)
    ft.guardar(fig, p("06_estandarizar.png"))


def fig_dendrograma():
    """Dendrograma jerarquico (Ward) sobre una muestra de municipios."""
    df = _carga("ejercicio_2", "municipio")
    Xs = StandardScaler().fit_transform(df)
    rng = np.random.default_rng(19)
    idx = rng.choice(len(Xs), 40, replace=False)
    Z = linkage(Xs[idx], method="ward")
    fig, ax = plt.subplots(figsize=(9.0, 4.6))
    dendrogram(Z, ax=ax, color_threshold=0.6 * Z[:, 2].max(),
               above_threshold_color=ft.GRAY, no_labels=True)
    ft.limpia(ax, keep=("left",), grid=False)
    ax.set_ylabel("Distancia de fusion", color=ft.GRAY, fontsize=12)
    ax.axhline(0.6 * Z[:, 2].max(), color=ft.DARK_RED, ls="--", lw=1.6)
    ax.text(0.99, 0.6 * Z[:, 2].max(), " corte = 4 grupos", color=ft.DARK_RED,
            fontsize=11, fontweight="bold", va="bottom", ha="right",
            transform=ax.get_yaxis_transform())
    ft.titulo(ax, "Dendrograma (Ward): el arbol se 'corta' para fijar k")
    ft.guardar(fig, p("07_dendrograma.png"))


# ===========================================================================
# PCA — figuras conceptuales
# ===========================================================================
def fig_dimension():
    fig, ax = plt.subplots(figsize=(9.4, 4.2))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 4)
    vars_ = ["sesiones", "duracion", "apuesta", "depositos", "madrugada",
             "chasing", "retiros", "perdida"]
    for i, v in enumerate(vars_):
        col = i % 4
        row = i // 4
        x_ = 0.2 + col * 1.35
        y_ = 0.5 + row * 1.6
        ax.add_patch(FancyBboxPatch((x_, y_), 1.2, 0.8,
                     boxstyle="round,pad=0.05,rounding_size=0.08",
                     fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=1.0))
        ax.text(x_ + 0.6, y_ + 0.4, v, ha="center", va="center",
                color=ft.NAVY, fontsize=9.0, fontweight="bold")
    ax.add_patch(FancyArrowPatch((5.9, 2.0), (6.6, 2.0), arrowstyle="-|>",
                 mutation_scale=24, color=ft.GRAY, lw=2.5))
    ax.text(6.25, 2.3, "PCA", ha="center", color=ft.NAVY, fontsize=13,
            fontweight="bold")
    for i, label in enumerate(["Componente 1\n(50% varianza)",
                                "Componente 2\n(20% varianza)"]):
        y_ = 0.8 + i * 1.7
        ax.add_patch(FancyBboxPatch((7.0, y_), 2.7, 1.1,
                     boxstyle="round,pad=0.06,rounding_size=0.1",
                     fc=ft.SOFT_GREEN, ec=ft.DARK_GREEN, lw=1.4))
        ax.text(8.35, y_ + 0.55, label, ha="center", va="center",
                color=ft.DARK_GREEN, fontsize=10.5, fontweight="bold")
    ax.text(2.75, 3.75, "12 variables originales", ha="center", color=ft.NAVY,
            fontsize=11, fontweight="bold")
    ax.text(8.35, 3.75, "2 componentes", ha="center", color=ft.DARK_GREEN,
            fontsize=11, fontweight="bold")
    ft.guardar(fig, p("08_dimension.png"))


def fig_pca_idea():
    np.random.seed(19)
    n = 120
    t = np.random.uniform(0, 6, n)
    x1 = 2 * t + np.random.normal(0, 0.8, n)
    x2 = t + np.random.normal(0, 0.5, n)
    X_p = np.column_stack([x1, x2])
    X_p = (X_p - X_p.mean(axis=0)) / X_p.std(axis=0)
    pca = PCA(n_components=2)
    coords = pca.fit_transform(X_p)
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.4))
    a = axs[0]
    ft.limpia(a, grid=True)
    a.scatter(X_p[:, 0], X_p[:, 1], c=ft.NAVY, s=30, edgecolors="white",
              lw=0.5, alpha=0.8)
    v = pca.components_[0] * 2.0
    a.annotate("", xy=(v[0], v[1]), xytext=(-v[0], -v[1]),
               arrowprops=dict(arrowstyle="-|>", color=ft.RED_PT, lw=2.4,
                               mutation_scale=18))
    a.text(v[0] + 0.1, v[1] + 0.15, "CP1\n(maxima varianza)", color=ft.RED_PT,
           fontsize=11, fontweight="bold")
    a.set_xlabel("Variable 1", color=ft.GRAY, fontsize=11)
    a.set_ylabel("Variable 2", color=ft.GRAY, fontsize=11)
    a.set_xticks([]); a.set_yticks([])
    ft.titulo(a, "El CP1 es la direccion que mas estira la nube", size=12)
    b = axs[1]
    ft.limpia(b, grid=True)
    b.scatter(coords[:, 0], coords[:, 1], c=ft.DARK_GREEN, s=30,
              edgecolors="white", lw=0.5, alpha=0.8)
    b.set_xlabel("Componente principal 1", color=ft.GRAY, fontsize=11)
    b.set_ylabel("Componente principal 2", color=ft.GRAY, fontsize=11)
    b.set_xticks([]); b.set_yticks([])
    ft.titulo(b, "Mismos puntos, nuevos ejes (CP1, CP2)", size=12)
    fig.subplots_adjust(wspace=0.25, bottom=0.15)
    ft.guardar(fig, p("09_pca_idea.png"))


def fig_analogia_pca():
    fig, ax = plt.subplots(figsize=(9.4, 4.0))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 4)
    materias = ["Matematicas", "Fisica", "Quimica", "Biologia", "Historia",
                "Literatura"]
    ys = np.linspace(0.4, 3.4, len(materias))
    for y_, m in zip(ys, materias):
        ax.add_patch(FancyBboxPatch((0.2, y_), 2.4, 0.55,
                     boxstyle="round,pad=0.05,rounding_size=0.08",
                     fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=0.9))
        ax.text(1.4, y_ + 0.275, m, ha="center", va="center", color=ft.NAVY,
                fontsize=9.5, fontweight="bold")
    ax.add_patch(FancyArrowPatch((2.7, 2.0), (4.0, 2.0), arrowstyle="-|>",
                 mutation_scale=22, color=ft.GRAY, lw=2.5))
    ax.text(3.35, 2.35, "resumir", ha="center", color=ft.NAVY, fontsize=11,
            fontweight="bold")
    for i, (label, fc_, ec_c) in enumerate([
            ("Perfil de ciencias", ft.SOFT_GREEN, ft.DARK_GREEN),
            ("Perfil de humanidades", "#ECDDEC", ft.PLUM)]):
        y_ = 1.0 + i * 1.6
        ax.add_patch(FancyBboxPatch((4.3, y_), 3.2, 1.1,
                     boxstyle="round,pad=0.06,rounding_size=0.1",
                     fc=fc_, ec=ec_c, lw=1.5))
        ax.text(5.9, y_ + 0.55, label, ha="center", va="center", color=ec_c,
                fontsize=11, fontweight="bold")
    ax.text(1.4, 3.82, "6 notas\nindividuales", ha="center", color=ft.NAVY,
            fontsize=10, fontweight="bold")
    ax.text(5.9, 3.82, "2 resumenes\nde informacion", ha="center",
            color=ft.DARK_GREEN, fontsize=10, fontweight="bold")
    ft.guardar(fig, p("10_analogia_pca.png"))


# ===========================================================================
# Figuras con DATOS REALES de los ejercicios
# ===========================================================================
def fig_scree():
    df = _carga("ejercicio_1", "jugador_id")
    X_s = StandardScaler().fit_transform(df)
    pca = PCA(n_components=X_s.shape[1])
    pca.fit(X_s)
    var_exp = pca.explained_variance_ratio_ * 100
    cumvar = np.cumsum(var_exp)
    fig, ax = plt.subplots(figsize=(8.6, 4.8))
    ft.limpia(ax, grid=True)
    nc = len(var_exp)
    xpos = np.arange(1, nc + 1)
    ax.bar(xpos, var_exp, color=ft.NAVY, edgecolor="white", linewidth=0.6,
           zorder=3, width=0.7)
    ax2 = ax.twinx()
    ax2.plot(xpos, cumvar, "-o", color=ft.DARK_RED, lw=2.2, markersize=6,
             markeredgecolor="white", markeredgewidth=0.8)
    ax2.axhline(80, color=ft.DARK_GREEN, ls="--", lw=1.5)
    ax2.text(nc - 0.3, 82, "80%", color=ft.DARK_GREEN, fontsize=10,
             fontweight="bold", ha="right")
    ax2.set_ylabel("Varianza acumulada (%)", color=ft.DARK_RED, fontsize=11)
    ax2.tick_params(colors=ft.DARK_RED, labelsize=10)
    ax2.set_ylim(0, 105)
    ax.set_xlabel("Numero de componente", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("% varianza explicada", color=ft.GRAY, fontsize=12)
    ax.set_xticks(xpos)
    ft.titulo(ax, "Scree plot (apostadores): cuanto resume cada componente")
    ft.guardar(fig, p("11_scree.png"))


def _biplot(ejercicio, id_col, k, nombres, titulo, fname):
    df = _carga(ejercicio, id_col)
    X_s = StandardScaler().fit_transform(df)
    pca = PCA(n_components=2).fit(X_s)
    coords = pca.transform(X_s)
    labels = KMeans(n_clusters=k, n_init=25, random_state=19).fit_predict(X_s)
    paleta = [ft.NAVY, ft.TEAL, ft.OCHRE, ft.PLUM, ft.DARK_GREEN]
    fig, ax = plt.subplots(figsize=(8.6, 5.2))
    ft.limpia(ax, grid=True)
    for c in range(k):
        m = labels == c
        ax.scatter(coords[m, 0], coords[m, 1], c=paleta[c], edgecolors="white",
                   lw=0.6, s=42, alpha=0.85, label=nombres[c], zorder=3)
    var_ = pca.explained_variance_ratio_ * 100
    ax.set_xlabel(f"Componente 1 ({var_[0]:.0f}% varianza)", color=ft.GRAY,
                  fontsize=12)
    ax.set_ylabel(f"Componente 2 ({var_[1]:.0f}% varianza)", color=ft.GRAY,
                  fontsize=12)
    ax.legend(loc="best", fontsize=10, frameon=True)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, titulo, size=13)
    ft.guardar(fig, p(fname))


def fig_biplot_apostadores():
    _biplot("ejercicio_1", "jugador_id", 4,
            ["Grupo 1", "Grupo 2", "Grupo 3", "Grupo 4"],
            "Apostadores: 4 perfiles descubiertos (PCA + k-means)",
            "12_biplot_apostadores.png")


def fig_biplot_municipios():
    _biplot("ejercicio_2", "municipio", 4,
            ["Grupo 1", "Grupo 2", "Grupo 3", "Grupo 4"],
            "Municipios: 4 tipologias descubiertas (PCA + k-means)",
            "13_biplot_municipios.png")


def fig_perfiles_apostadores():
    df = _carga("ejercicio_1", "jugador_id")
    X_s = StandardScaler().fit_transform(df)
    df["grupo"] = KMeans(n_clusters=4, n_init=25, random_state=19).fit_predict(X_s)
    vars_plot = ["sesiones_semana", "apuesta_promedio_mxn",
                 "pct_juego_madrugada", "pct_incremento_tras_perdida"]
    etiquetas = ["Sesiones/sem", "Apuesta media\n(MXN)", "% madrugada",
                 "% chasing"]
    medias = df.groupby("grupo")[vars_plot].mean()
    paleta = [ft.NAVY, ft.TEAL, ft.OCHRE, ft.PLUM]
    fig, axs = plt.subplots(1, len(vars_plot), figsize=(9.4, 4.4))
    for ax, var, lab in zip(axs, vars_plot, etiquetas):
        ax.bar(range(4), [medias.loc[g, var] for g in range(4)], color=paleta,
               edgecolor="white", linewidth=0.8)
        ax.set_xticks(range(4))
        ax.set_xticklabels(["G1", "G2", "G3", "G4"], fontsize=9)
        ft.limpia(ax, grid=True)
        ax.set_title(lab, fontsize=10, color=ft.NAVY, fontweight="bold", pad=6)
    fig.suptitle("Perfil promedio de cada grupo de apostadores", color=ft.NAVY,
                 fontsize=12, fontweight="bold", y=1.02)
    fig.subplots_adjust(wspace=0.4, bottom=0.1)
    ft.guardar(fig, p("14_perfiles_apostadores.png"))


def fig_flujo_completo():
    fig, ax = plt.subplots(figsize=(9.4, 3.4))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 3.5)
    pasos = [
        ("Datos\noriginales", ft.SOFT_BLUE, ft.NAVY),
        ("Estandarizar\n(z-score)", ft.SOFT_BLUE, ft.NAVY),
        ("PCA\n(visualizar)", ft.SOFT_GREEN, ft.DARK_GREEN),
        ("Clustering\n(k grupos)", ft.SOFT_GREEN, ft.DARK_GREEN),
        ("Perfilar y\nnombrar", "#FFF3CD", ft.OCHRE),
    ]
    xpos = [0.4, 2.4, 4.4, 6.4, 8.4]
    for i, ((txt, fc, ec), x) in enumerate(zip(pasos, xpos)):
        ax.add_patch(FancyBboxPatch((x, 1.0), 1.7, 1.5,
                     boxstyle="round,pad=0.07,rounding_size=0.12",
                     fc=fc, ec=ec, lw=1.5, zorder=2))
        ax.text(x + 0.85, 1.75, txt, ha="center", va="center", color=ec,
                fontsize=9.5, fontweight="bold", zorder=3)
        if i < len(pasos) - 1:
            ax.add_patch(FancyArrowPatch((x + 1.74, 1.75),
                         (xpos[i + 1] - 0.04, 1.75), arrowstyle="-|>",
                         mutation_scale=16, color=ft.GRAY, lw=1.8, zorder=3))
    ax.text(5.0, 0.4,
            "El resultado: grupos con significado, no etiquetas artificiales",
            ha="center", color=ft.GRAY, fontsize=10, style="italic")
    ft.guardar(fig, p("15_flujo_completo.png"))


if __name__ == "__main__":
    formulas()
    fig_supervisado_vs_no()
    fig_antes_despues()
    fig_kmeans_pasos()
    fig_codo()
    fig_silueta_concepto()
    fig_estandarizar()
    fig_dendrograma()
    fig_dimension()
    fig_pca_idea()
    fig_analogia_pca()
    fig_scree()
    fig_biplot_apostadores()
    fig_biplot_municipios()
    fig_perfiles_apostadores()
    fig_flujo_completo()
    print("Figuras S19 generadas en", OUT)
