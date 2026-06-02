"""Genera las figuras de la presentacion TEORICA de la Sesion 18 (Aprendizaje
no supervisado: clustering y PCA). Diagramas conceptuales + graficas reales
sobre datos de vinos (ejercicio_1) y municipios (ejercicio_2).

Salida: ./img_teoria/*.png a 300 DPI."""
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.patches import (FancyBboxPatch, FancyArrowPatch, Circle,
                                 Rectangle)
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

import figteoria as ft

BASE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(BASE, "img_teoria")
os.makedirs(OUT, exist_ok=True)
p = lambda nombre: os.path.join(OUT, nombre)

rng = np.random.default_rng(18)


# ---------------------------------------------------------------------------
# Figura 1: Supervisado vs no supervisado (2 paneles)
# ---------------------------------------------------------------------------
def fig_supervisado_vs_no():
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.2))

    # Panel izquierdo: supervisado (puntos con colores/etiquetas conocidos)
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
    pts_b[:, 1] = pts_b[:, 1] * 0.35
    pts_a[:, 1] = 0.8 + pts_a[:, 1] * 0.55
    pts_b[:, 1] = 0.8 + pts_b[:, 1]

    a.scatter(pts_a[:, 0], pts_a[:, 1], c=ft.NAVY, s=55,
              edgecolors="white", lw=0.8, zorder=3, label="Aprobado")
    a.scatter(pts_b[:, 0], pts_b[:, 1], c=ft.RED_PT, s=55,
              marker="^", edgecolors="white", lw=0.8, zorder=3,
              label="Rechazado")
    a.legend(loc="lower center", ncol=2, fontsize=9.5, frameon=False,
             bbox_to_anchor=(0.5, -0.02))
    a.text(5.0, 0.22, "Etiquetas CONOCIDAS de antemano",
           ha="center", color=ft.GRAY, fontsize=10, style="italic")

    # Panel derecho: no supervisado (puntos sin color -> descubrimos grupos)
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
    b.text(5.0, 0.22, "NO hay etiquetas: el algoritmo DESCUBRE grupos",
           ha="center", color=ft.GRAY, fontsize=10, style="italic")

    fig.subplots_adjust(wspace=0.06, bottom=0.12)
    ft.guardar(fig, p("01_supervisado_vs_no.png"))


# ---------------------------------------------------------------------------
# Figura 2: Puntos sin etiqueta -> mismos puntos en 3 grupos (antes/despues)
# ---------------------------------------------------------------------------
def fig_antes_despues():
    X_blobs, y_blobs = make_blobs(n_samples=180, centers=3,
                                   cluster_std=0.85, random_state=18)
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.4))
    colores = [ft.NAVY, ft.RED_PT, ft.DARK_GREEN]

    a = axs[0]
    ft.limpia(a, grid=True)
    a.scatter(X_blobs[:, 0], X_blobs[:, 1], c=ft.SOFT_BLUE,
              edgecolors=ft.GRAY, lw=0.6, s=40, zorder=3)
    a.set_xticks([]); a.set_yticks([])
    ft.titulo(a, "Antes: puntos sin etiqueta", size=13)
    a.text(0.5, -0.1, "Solo vemos datos... sin grupos definidos",
           transform=a.transAxes, ha="center", color=ft.GRAY, fontsize=10,
           style="italic")

    b = axs[1]
    ft.limpia(b, grid=True)
    for c in range(3):
        m = y_blobs == c
        b.scatter(X_blobs[m, 0], X_blobs[m, 1], c=colores[c],
                  edgecolors="white", lw=0.7, s=40, zorder=3,
                  label=f"Grupo {c + 1}")
    b.set_xticks([]); b.set_yticks([])
    b.legend(loc="upper right", fontsize=10, frameon=True)
    ft.titulo(b, "Despues: k-means descubrio 3 grupos", size=13)
    b.text(0.5, -0.1, "El algoritmo colorio los puntos por similaridad",
           transform=b.transAxes, ha="center", color=ft.GRAY, fontsize=10,
           style="italic")

    fig.subplots_adjust(wspace=0.12, bottom=0.16)
    ft.guardar(fig, p("02_antes_despues.png"))


# ---------------------------------------------------------------------------
# Figura 3: k-means paso a paso (4 paneles)
# ---------------------------------------------------------------------------
def fig_kmeans_pasos():
    X_k, _ = make_blobs(n_samples=90, centers=3, cluster_std=0.9,
                         random_state=7)
    colores = [ft.NAVY, ft.RED_PT, ft.DARK_GREEN]

    fig, axs = plt.subplots(2, 2, figsize=(9.4, 7.2))
    axs = axs.ravel()

    np.random.seed(42)
    # Paso 1: centroides iniciales al azar
    centroides = X_k[np.random.choice(len(X_k), 3, replace=False)]
    ax = axs[0]
    ft.limpia(ax, grid=True)
    ax.scatter(X_k[:, 0], X_k[:, 1], c=ft.SOFT_BLUE, edgecolors=ft.GRAY,
               lw=0.5, s=35, zorder=2)
    for i, c in enumerate(centroides):
        ax.scatter(*c, marker="X", c=colores[i], s=220, edgecolors="white",
                   lw=1.4, zorder=5)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, "Paso 1: centroides al azar", size=12)

    # Paso 2: asignar puntos al centroide mas cercano
    def asignar(X_, C_):
        dists = np.array([[np.linalg.norm(x - c) for c in C_] for x in X_])
        return np.argmin(dists, axis=1)

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

    # Paso 3: mover centroides al promedio del grupo
    nuevos = np.array([X_k[labels == c].mean(axis=0) for c in range(3)])
    ax = axs[2]
    ft.limpia(ax, grid=True)
    for c in range(3):
        m = labels == c
        ax.scatter(X_k[m, 0], X_k[m, 1], c=colores[c], edgecolors="white",
                   lw=0.6, s=35, alpha=0.55, zorder=2)
    for i in range(3):
        ax.add_patch(FancyArrowPatch(centroides[i], nuevos[i],
                     arrowstyle="-|>", mutation_scale=16,
                     color=colores[i], lw=2.0))
        ax.scatter(*nuevos[i], marker="X", c=colores[i], s=220,
                   edgecolors="black", lw=1.4, zorder=5)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, "Paso 3: mover al promedio del grupo", size=12)

    # Paso 4: converge (iteracion final con KMeans real)
    km = KMeans(n_clusters=3, n_init=10, random_state=18)
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


# ---------------------------------------------------------------------------
# Figura 4: Metodo del codo (inercia vs k)
# ---------------------------------------------------------------------------
def fig_codo():
    X_c, _ = make_blobs(n_samples=200, centers=4, cluster_std=0.8,
                         random_state=18)
    ks = range(1, 11)
    inercias = [KMeans(n_clusters=k, n_init=10, random_state=18)
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
                arrowprops=dict(arrowstyle="-|>", color=ft.DARK_RED,
                                lw=1.4))
    ax.set_xlabel("Numero de grupos k", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Inercia (suma de distancias al centroide)",
                  color=ft.GRAY, fontsize=12)
    ft.titulo(ax, "Metodo del codo: busca donde la curva deja de caer rapido")
    ft.guardar(fig, p("04_codo.png"))


# ---------------------------------------------------------------------------
# Figura 5: Estandarizar antes de agrupar (2 paneles)
# ---------------------------------------------------------------------------
def fig_estandarizar():
    np.random.seed(18)
    n = 80
    ingreso = np.random.normal(25000, 8000, n)
    pct = np.random.uniform(10, 90, n)

    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.4))

    a = axs[0]
    ft.limpia(a, grid=True)
    a.scatter(ingreso, pct, c=ft.NAVY, s=35, edgecolors="white", lw=0.5)
    a.set_xlabel("Ingreso (pesos)", color=ft.GRAY, fontsize=11)
    a.set_ylabel("% pobreza", color=ft.GRAY, fontsize=11)
    ft.titulo(a, "SIN estandarizar", size=13)
    a.text(0.5, -0.22,
           "Ingreso (miles) domina la distancia;\n% pobreza casi no cuenta",
           transform=a.transAxes, ha="center", color=ft.DARK_RED,
           fontsize=10)

    b = axs[1]
    ft.limpia(b, grid=True)
    z1 = (ingreso - ingreso.mean()) / ingreso.std()
    z2 = (pct - pct.mean()) / pct.std()
    b.scatter(z1, z2, c=ft.DARK_GREEN, s=35, edgecolors="white", lw=0.5)
    b.set_xlabel("Ingreso (estandarizado)", color=ft.GRAY, fontsize=11)
    b.set_ylabel("% pobreza (estandarizado)", color=ft.GRAY, fontsize=11)
    ft.titulo(b, "CON estandarizar", size=13)
    b.text(0.5, -0.22,
           "Ambas variables pesan igual;\nla distancia es justa",
           transform=b.transAxes, ha="center", color=ft.DARK_GREEN,
           fontsize=10)

    fig.subplots_adjust(bottom=0.28, wspace=0.32)
    ft.guardar(fig, p("05_estandarizar.png"))


# ---------------------------------------------------------------------------
# Figura 6: El problema de la dimension (muchas variables -> 2 componentes)
# ---------------------------------------------------------------------------
def fig_dimension():
    fig, ax = plt.subplots(figsize=(9.4, 4.2))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 4)

    # Variables originales (cajas izquierda)
    vars_ = ["alcohol", "acidez", "azucar", "pH", "sulfatos",
             "densidad", "cloruros", "SO2"]
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

    # Flecha grande hacia el centro
    ax.add_patch(FancyArrowPatch((5.9, 2.0), (6.6, 2.0),
                 arrowstyle="-|>", mutation_scale=24, color=ft.GRAY, lw=2.5))
    ax.text(6.25, 2.3, "PCA", ha="center", color=ft.NAVY,
            fontsize=13, fontweight="bold")

    # 2 componentes (cajas derecha)
    for i, label in enumerate(["Componente 1\n(45% varianza)",
                                "Componente 2\n(22% varianza)"]):
        y_ = 0.8 + i * 1.7
        ax.add_patch(FancyBboxPatch((7.0, y_), 2.7, 1.1,
                     boxstyle="round,pad=0.06,rounding_size=0.1",
                     fc=ft.SOFT_GREEN, ec=ft.DARK_GREEN, lw=1.4))
        ax.text(8.35, y_ + 0.55, label, ha="center", va="center",
                color=ft.DARK_GREEN, fontsize=10.5, fontweight="bold")

    ax.text(2.75, 3.75, "8 variables originales", ha="center",
            color=ft.NAVY, fontsize=11, fontweight="bold")
    ax.text(8.35, 3.75, "2 componentes", ha="center",
            color=ft.DARK_GREEN, fontsize=11, fontweight="bold")
    ft.guardar(fig, p("06_dimension.png"))


# ---------------------------------------------------------------------------
# Figura 7: Idea de PCA — nube en alta dimension proyectada a 2D
# ---------------------------------------------------------------------------
def fig_pca_idea():
    np.random.seed(18)
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
    # Primer componente principal
    v = pca.components_[0] * 2.0
    a.annotate("", xy=(v[0], v[1]), xytext=(0, 0),
                arrowprops=dict(arrowstyle="-|>", color=ft.RED_PT,
                                lw=2.2, mutation_scale=18))
    a.text(v[0] + 0.08, v[1] + 0.15, "CP1", color=ft.RED_PT,
           fontsize=12, fontweight="bold")
    a.set_xlabel("Variable 1 (alcohol)", color=ft.GRAY, fontsize=11)
    a.set_ylabel("Variable 2 (acidez)", color=ft.GRAY, fontsize=11)
    a.set_xticks([]); a.set_yticks([])
    ft.titulo(a, "Espacio original (2 vars)", size=13)

    b = axs[1]
    ft.limpia(b, grid=True)
    b.scatter(coords[:, 0], coords[:, 1], c=ft.DARK_GREEN, s=30,
              edgecolors="white", lw=0.5, alpha=0.8)
    b.set_xlabel("Componente principal 1", color=ft.GRAY, fontsize=11)
    b.set_ylabel("Componente principal 2", color=ft.GRAY, fontsize=11)
    b.set_xticks([]); b.set_yticks([])
    ft.titulo(b, "Espacio PCA (2 componentes)", size=13)

    fig.subplots_adjust(wspace=0.25, bottom=0.15)
    ft.guardar(fig, p("07_pca_idea.png"))


# ---------------------------------------------------------------------------
# Figura 8: Scree plot (% varianza explicada por componente)
# ---------------------------------------------------------------------------
def fig_scree():
    df = pd.read_csv(os.path.join(BASE, "ejercicio_1", "datos.csv"))
    scaler = StandardScaler()
    X_s = scaler.fit_transform(df)
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
    ax2.text(nc - 0.3, 81.5, "80%", color=ft.DARK_GREEN, fontsize=10,
             fontweight="bold", ha="right")
    ax2.set_ylabel("Varianza acumulada (%)", color=ft.DARK_RED, fontsize=11)
    ax2.tick_params(colors=ft.DARK_RED, labelsize=10)
    ax2.set_ylim(0, 105)
    ax.set_xlabel("Numero de componente", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("% varianza explicada", color=ft.GRAY, fontsize=12)
    ax.set_xticks(xpos)
    ft.titulo(ax, "Scree plot: cuanta informacion captura cada componente")
    ft.guardar(fig, p("08_scree.png"))


# ---------------------------------------------------------------------------
# Figura 9: Biplot / proyeccion PCA real — municipios coloreados por clusters
# ---------------------------------------------------------------------------
def fig_biplot_municipios():
    df = pd.read_csv(os.path.join(BASE, "ejercicio_2", "datos.csv"))
    df = df.drop(columns=["clave_municipio"], errors="ignore")
    # Imputar NAs con mediana
    for col in df.columns:
        if df[col].isna().any():
            df[col] = df[col].fillna(df[col].median())
    scaler = StandardScaler()
    X_s = scaler.fit_transform(df)
    pca = PCA(n_components=2)
    coords = pca.fit_transform(X_s)
    # Colorear por k-means (k=3)
    km = KMeans(n_clusters=3, n_init=15, random_state=18)
    labels = km.fit_predict(X_s)

    colores = [ft.NAVY, ft.RED_PT, ft.DARK_GREEN]
    nombres = ["Perfil 1", "Perfil 2", "Perfil 3"]

    fig, ax = plt.subplots(figsize=(8.4, 5.4))
    ft.limpia(ax, grid=True)
    for c in range(3):
        m = labels == c
        ax.scatter(coords[m, 0], coords[m, 1], c=colores[c],
                   edgecolors="white", lw=0.6, s=40, alpha=0.85,
                   label=nombres[c], zorder=3)
    var_ = pca.explained_variance_ratio_ * 100
    ax.set_xlabel(f"Componente 1 ({var_[0]:.1f}% varianza)",
                  color=ft.GRAY, fontsize=12)
    ax.set_ylabel(f"Componente 2 ({var_[1]:.1f}% varianza)",
                  color=ft.GRAY, fontsize=12)
    ax.legend(loc="upper right", fontsize=11, frameon=True)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax,
              "Municipios en el espacio PCA coloreados por perfil (k-means)")
    ft.guardar(fig, p("09_biplot_municipios.png"))


# ---------------------------------------------------------------------------
# Figura 10: Analogia "resumir muchas materias en un promedio"
# ---------------------------------------------------------------------------
def fig_analogia_pca():
    fig, ax = plt.subplots(figsize=(9.4, 4.0))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 4)

    # Materias (cajas izquierda)
    materias = ["Matematicas", "Fisica", "Quimica", "Biologia", "Historia",
                "Literatura"]
    ys = np.linspace(0.4, 3.4, len(materias))
    for y_, m in zip(ys, materias):
        ax.add_patch(FancyBboxPatch((0.2, y_), 2.4, 0.55,
                     boxstyle="round,pad=0.05,rounding_size=0.08",
                     fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=0.9))
        ax.text(1.4, y_ + 0.275, m, ha="center", va="center",
                color=ft.NAVY, fontsize=9.5, fontweight="bold")

    # Flecha
    ax.add_patch(FancyArrowPatch((2.7, 2.0), (4.0, 2.0),
                 arrowstyle="-|>", mutation_scale=22, color=ft.GRAY,
                 lw=2.5))
    ax.text(3.35, 2.35, "resumir", ha="center", color=ft.NAVY,
            fontsize=11, fontweight="bold")

    # Resultados resumidos
    resums = [("Promedio ciencias", ft.DARK_GREEN, ft.SOFT_GREEN),
              ("Promedio humanidades", ft.PLUM, RGBColor_to_hex(0xEC, 0xDD, 0xF0))]

    def fill_color(r, g, b):
        return "#{:02X}{:02X}{:02X}".format(r, g, b)

    fills = [ft.SOFT_GREEN, "#ECD DF0"]
    for i, (label, ec_, _) in enumerate(resums):
        y_ = 1.0 + i * 1.6
        fc_ = ft.SOFT_GREEN if i == 0 else "#ECDDEC"
        ec_c = ft.DARK_GREEN if i == 0 else ft.PLUM
        ax.add_patch(FancyBboxPatch((4.3, y_), 3.2, 1.1,
                     boxstyle="round,pad=0.06,rounding_size=0.1",
                     fc=fc_, ec=ec_c, lw=1.5))
        ax.text(5.9, y_ + 0.55, label, ha="center", va="center",
                color=ec_c, fontsize=11, fontweight="bold")

    ax.text(1.4, 3.82, "6 notas\nindividuales", ha="center",
            color=ft.NAVY, fontsize=10, fontweight="bold")
    ax.text(5.9, 3.82, "2 resumenes\nde informacion", ha="center",
            color=ft.DARK_GREEN, fontsize=10, fontweight="bold")
    ft.guardar(fig, p("10_analogia_pca.png"))


def RGBColor_to_hex(r, g, b):
    return "#{:02X}{:02X}{:02X}".format(r, g, b)


# ---------------------------------------------------------------------------
# Figura 11: PCA + clustering sobre vinos (biplot con grupos)
# ---------------------------------------------------------------------------
def fig_biplot_vinos():
    df = pd.read_csv(os.path.join(BASE, "ejercicio_1", "datos.csv"))
    scaler = StandardScaler()
    X_s = scaler.fit_transform(df)
    pca = PCA(n_components=2)
    coords = pca.fit_transform(X_s)
    km = KMeans(n_clusters=3, n_init=15, random_state=18)
    labels = km.fit_predict(X_s)

    colores = [ft.NAVY, ft.RED_PT, ft.DARK_GREEN]
    nombres = ["Perfil quimico A", "Perfil quimico B", "Perfil quimico C"]

    fig, ax = plt.subplots(figsize=(8.4, 5.4))
    ft.limpia(ax, grid=True)
    for c in range(3):
        m = labels == c
        ax.scatter(coords[m, 0], coords[m, 1], c=colores[c],
                   edgecolors="white", lw=0.6, s=40, alpha=0.85,
                   label=nombres[c], zorder=3)
    var_ = pca.explained_variance_ratio_ * 100
    ax.set_xlabel(f"Componente 1 ({var_[0]:.1f}% varianza)",
                  color=ft.GRAY, fontsize=12)
    ax.set_ylabel(f"Componente 2 ({var_[1]:.1f}% varianza)",
                  color=ft.GRAY, fontsize=12)
    ax.legend(loc="upper right", fontsize=11, frameon=True)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, "Vinos: 3 perfiles quimicos descubiertos con PCA + k-means")
    ft.guardar(fig, p("11_biplot_vinos.png"))


# ---------------------------------------------------------------------------
# Figura 12: Tabla de perfiles municipales (barras de atributos por grupo)
# ---------------------------------------------------------------------------
def fig_perfiles_municipios():
    df = pd.read_csv(os.path.join(BASE, "ejercicio_2", "datos.csv"))
    df = df.drop(columns=["clave_municipio"], errors="ignore")
    for col in df.columns:
        if df[col].isna().any():
            df[col] = df[col].fillna(df[col].median())
    scaler = StandardScaler()
    X_s = scaler.fit_transform(df)
    km = KMeans(n_clusters=3, n_init=15, random_state=18)
    labels = km.fit_predict(X_s)
    df["grupo"] = labels

    # Promediar variables clave por grupo
    vars_plot = ["pct_pobreza", "pct_acceso_internet", "ingreso_promedio_mxn",
                 "pct_poblacion_rural"]
    etiquetas = ["% pobreza", "% internet", "Ingreso promedio\n(MXN)",
                 "% rural"]
    medias = df.groupby("grupo")[vars_plot].mean()

    fig, axs = plt.subplots(1, len(vars_plot), figsize=(9.4, 4.6))
    colores_g = [ft.NAVY, ft.RED_PT, ft.DARK_GREEN]
    for j, (ax, var, lab) in enumerate(zip(axs, vars_plot, etiquetas)):
        vals = [medias.loc[g, var] for g in range(3)]
        bars = ax.bar(range(3), vals, color=colores_g, edgecolor="white",
                      linewidth=0.8)
        ax.set_xticks(range(3))
        ax.set_xticklabels(["G1", "G2", "G3"], fontsize=10)
        ft.limpia(ax, grid=True)
        ax.set_title(lab, fontsize=10, color=ft.NAVY, fontweight="bold",
                     pad=6)
    fig.suptitle("Perfil promedio de cada grupo de municipios",
                 color=ft.NAVY, fontsize=12, fontweight="bold", y=1.01)
    fig.subplots_adjust(wspace=0.38, bottom=0.12)
    ft.guardar(fig, p("12_perfiles_municipios.png"))


# ---------------------------------------------------------------------------
# Figura 13: Flujo completo PCA + clustering (diagrama)
# ---------------------------------------------------------------------------
def fig_flujo_completo():
    fig, ax = plt.subplots(figsize=(9.4, 3.4))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 3.5)

    pasos = [
        ("Datos\noriginales\n(11 vars)", ft.SOFT_BLUE, ft.NAVY),
        ("Estandarizar\n(z-score)", ft.SOFT_BLUE, ft.NAVY),
        ("PCA\n(2 CP)", ft.SOFT_GREEN, ft.DARK_GREEN),
        ("k-means\n(k grupos)", ft.SOFT_GREEN, ft.DARK_GREEN),
        ("Perfiles\ndescubiertos", "#FFF3CD", ft.OCHRE),
    ]
    xpos = [0.4, 2.4, 4.4, 6.4, 8.4]
    for i, ((txt, fc, ec), x) in enumerate(zip(pasos, xpos)):
        ax.add_patch(FancyBboxPatch((x, 1.0), 1.7, 1.5,
                     boxstyle="round,pad=0.07,rounding_size=0.12",
                     fc=fc, ec=ec, lw=1.5, zorder=2))
        ax.text(x + 0.85, 1.75, txt, ha="center", va="center",
                color=ec, fontsize=9.5, fontweight="bold", zorder=3)
        if i < len(pasos) - 1:
            ax.add_patch(FancyArrowPatch((x + 1.74, 1.75),
                                          (xpos[i + 1] - 0.04, 1.75),
                         arrowstyle="-|>", mutation_scale=16,
                         color=ft.GRAY, lw=1.8, zorder=3))
    ax.text(5.0, 0.4, "El resultado: grupos con significado, no etiquetas artificiales",
            ha="center", color=ft.GRAY, fontsize=10, style="italic")
    ft.guardar(fig, p("13_flujo_completo.png"))


# ---------------------------------------------------------------------------
# Punto de entrada
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    fig_supervisado_vs_no()
    fig_antes_despues()
    fig_kmeans_pasos()
    fig_codo()
    fig_estandarizar()
    fig_dimension()
    fig_pca_idea()
    fig_scree()
    fig_biplot_municipios()
    fig_analogia_pca()
    fig_biplot_vinos()
    fig_perfiles_municipios()
    fig_flujo_completo()
    print("Figuras S18 generadas en", OUT)
