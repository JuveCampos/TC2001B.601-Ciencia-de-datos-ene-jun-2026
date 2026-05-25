"""Genera las figuras de la presentacion TEORICA de la Sesion 17
(Machine Learning e Inteligencia Artificial). Diagramas conceptuales
+ graficas calculadas sobre los datasets reales de la sesion.

Salida: ./img_teoria/*.png a 300 DPI."""
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import (FancyBboxPatch, FancyArrowPatch,
                                 Circle, Rectangle)
from sklearn.datasets import make_moons, make_blobs
from sklearn.neighbors import KNeighborsClassifier, KNeighborsRegressor
from sklearn.model_selection import cross_val_score
from sklearn.preprocessing import StandardScaler

import figteoria as ft

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "img_teoria")
os.makedirs(OUT, exist_ok=True)
p = lambda nombre: os.path.join(OUT, nombre)

rng = np.random.default_rng(17)


# ---------------------------------------------------------------------------
# Fig 01 — Circulos concentricos IA > ML > Aprendizaje profundo
# ---------------------------------------------------------------------------
def fig_circulos_ia():
    fig, ax = plt.subplots(figsize=(8.8, 5.2))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6)
    ax.set_aspect("equal")
    ax.set_xlim(1, 9)
    ax.set_ylim(0.2, 5.8)

    radios = [2.6, 1.75, 0.95]
    colores = [ft.NAVY, ft.TEAL, ft.OCHRE]
    etiquetas = [
        ("Inteligencia\nArtificial", 5.0, 0.75, ft.NAVY),
        ("Machine\nLearning", 5.0, 1.85, ft.TEAL),
        ("Aprendizaje\nprofundo", 5.0, 3.1, ft.OCHRE),
    ]
    cx, cy = 5.0, 3.0
    for r, color in zip(radios, colores):
        circle = plt.Circle((cx, cy), r, fc=color, ec="white",
                             lw=2.5, alpha=0.22, zorder=2)
        ax.add_patch(circle)
        circle2 = plt.Circle((cx, cy), r, fc="none", ec=color,
                              lw=2.5, zorder=3)
        ax.add_patch(circle2)

    # Etiquetas
    ax.text(5.0, 0.75, "Inteligencia Artificial",
            ha="center", va="center", color=ft.NAVY,
            fontsize=14, fontweight="bold", zorder=4)
    ax.text(5.0, 1.85, "Machine Learning",
            ha="center", va="center", color=ft.TEAL,
            fontsize=13, fontweight="bold", zorder=4)
    ax.text(5.0, 3.0, "Aprendizaje\nprofundo",
            ha="center", va="center", color=ft.OCHRE,
            fontsize=12, fontweight="bold", zorder=4)

    # Ejemplos en las zonas
    ax.text(2.2, 4.8,
            "Reglas escritas a mano\nSistemas expertos\nPlanificacion",
            ha="center", va="center", color=ft.NAVY,
            fontsize=9, style="italic", zorder=4)
    ax.text(7.6, 4.8,
            "KNN, arboles\nRegresion\nRedes simples",
            ha="center", va="center", color=ft.TEAL,
            fontsize=9, style="italic", zorder=4)

    ft.titulo(ax,
              "IA abarca mas que ML; el aprendizaje profundo es un tipo de ML",
              size=13)
    ft.guardar(fig, p("01_circulos_ia.png"))


# ---------------------------------------------------------------------------
# Fig 02 — Tres tipos de aprendizaje (3 paneles)
# ---------------------------------------------------------------------------
def fig_tres_tipos():
    fig, axs = plt.subplots(1, 3, figsize=(9.4, 4.2))

    # Panel A: supervisado
    a = axs[0]
    ft.sin_ejes(a)
    a.set_xlim(0, 4); a.set_ylim(0, 4)
    pts_a = rng.uniform(0.5, 1.8, (8, 2))
    pts_b = rng.uniform(2.2, 3.6, (8, 2))
    a.scatter(pts_a[:, 0], pts_a[:, 1], c=ft.NAVY, s=55,
              edgecolors="white", lw=0.8, zorder=3, label="Clase A")
    a.scatter(pts_b[:, 0], pts_b[:, 1], c=ft.RED_PT, s=55,
              edgecolors="white", lw=0.8, zorder=3, label="Clase B")
    a.legend(fontsize=8, loc="upper right", frameon=False)
    a.text(2.0, 0.2, "Supervisado", ha="center", color=ft.NAVY,
           fontsize=12, fontweight="bold")
    a.text(2.0, -0.15, "(etiquetas conocidas)", ha="center",
           color=ft.GRAY, fontsize=8.5, style="italic")

    # Panel B: no supervisado
    b = axs[1]
    ft.sin_ejes(b)
    b.set_xlim(0, 4); b.set_ylim(0, 4)
    X2, _ = make_blobs(n_samples=40, centers=3, cluster_std=0.45,
                       random_state=17)
    X2 = (X2 - X2.min(axis=0)) / (X2.max(axis=0) - X2.min(axis=0)) * 3 + 0.5
    b.scatter(X2[:, 0], X2[:, 1], c=ft.SOFT_BLUE, s=50,
              edgecolors=ft.SLATE, lw=0.8, zorder=3)
    b.text(2.0, 0.2, "No supervisado", ha="center", color=ft.TEAL,
           fontsize=12, fontweight="bold")
    b.text(2.0, -0.15, "(sin etiquetas, busca grupos)", ha="center",
           color=ft.GRAY, fontsize=8.5, style="italic")

    # Panel C: por refuerzo
    c = axs[2]
    ft.sin_ejes(c)
    c.set_xlim(0, 4); c.set_ylim(0, 4)
    # Agente (circulo) + flechas de accion + cuadro de premio/castigo
    ag = plt.Circle((2.0, 2.0), 0.42, fc=ft.OCHRE, ec="white", lw=2, zorder=3)
    c.add_patch(ag)
    c.text(2.0, 2.0, "Agente", ha="center", va="center",
           color="white", fontsize=9, fontweight="bold", zorder=4)
    # Flecha accion
    c.add_patch(FancyArrowPatch(
        (2.42, 2.0), (3.4, 2.0),
        arrowstyle="-|>", mutation_scale=15, color=ft.DARK_GREEN, lw=1.8))
    c.text(3.45, 2.15, "Entorno", ha="left", color=ft.DARK_GREEN,
           fontsize=9, fontweight="bold")
    # Flecha premio de vuelta
    c.add_patch(FancyArrowPatch(
        (3.4, 1.7), (2.42, 1.7),
        arrowstyle="-|>", mutation_scale=15, color=ft.PLUM, lw=1.8))
    c.text(2.8, 1.35, "+/- premio", ha="center", color=ft.PLUM,
           fontsize=8.5, fontweight="bold")
    c.text(2.0, 0.2, "Por refuerzo", ha="center", color=ft.OCHRE,
           fontsize=12, fontweight="bold")
    c.text(2.0, -0.15, "(aprende de premio/castigo)", ha="center",
           color=ft.GRAY, fontsize=8.5, style="italic")

    fig.subplots_adjust(wspace=0.05, bottom=0.12)
    ft.guardar(fig, p("02_tres_tipos.png"))


# ---------------------------------------------------------------------------
# Fig 03 — Clasificacion vs Regresion (2 paneles)
# ---------------------------------------------------------------------------
def fig_clasif_regresion():
    fig, axs = plt.subplots(1, 2, figsize=(9.2, 4.2))
    # Panel clasificacion: seguro de vida
    a = axs[0]
    ft.limpia(a, grid=True)
    g1 = rng.normal([25, 0.45], [7, 0.1], (50, 2))
    g2 = rng.normal([55, 0.28], [7, 0.1], (50, 2))
    a.scatter(g1[:, 0], g1[:, 1], c=ft.NAVY, s=30,
              edgecolors="white", lw=0.5, label="Aprobada: si", alpha=0.85)
    a.scatter(g2[:, 0], g2[:, 1], c=ft.RED_PT, s=30,
              edgecolors="white", lw=0.5, label="Aprobada: no", alpha=0.85)
    a.plot([38, 38], [0.1, 0.65], "--", color=ft.DARK_GREEN, lw=2)
    a.set_xticks([]); a.set_yticks([])
    a.set_xlabel("Edad", color=ft.GRAY, fontsize=10)
    a.set_ylabel("IMC simplif.", color=ft.GRAY, fontsize=10)
    ft.titulo(a, "Clasificacion (seguro de vida)", size=13)
    a.text(0.5, -0.18, "Respuesta: CATEGORIA (aprobada / no)",
           transform=a.transAxes, ha="center", color=ft.NAVY,
           fontsize=9.5, fontweight="bold")
    a.legend(fontsize=8.5, loc="upper right", frameon=True)
    # Panel regresion: costo medico
    b = axs[1]
    ft.limpia(b, grid=True)
    edad = rng.uniform(20, 70, 80)
    costo = (edad * 600 + rng.normal(0, 6000, 80) +
             rng.uniform(10000, 30000, 80))
    b.scatter(edad, costo / 1000, c=ft.OCHRE, s=30,
              edgecolors="white", lw=0.5, alpha=0.85)
    xs = np.array([20, 70])
    b.plot(xs, (xs * 600 + 20000) / 1000, color=ft.NAVY, lw=2.2)
    b.set_xticks([]); b.set_yticks([])
    b.set_xlabel("Edad", color=ft.GRAY, fontsize=10)
    b.set_ylabel("Costo (miles MXN)", color=ft.GRAY, fontsize=10)
    ft.titulo(b, "Regresion (costo medico)", size=13)
    b.text(0.5, -0.18, "Respuesta: NUMERO ($ costo anual)",
           transform=b.transAxes, ha="center", color=ft.OCHRE,
           fontsize=9.5, fontweight="bold")
    fig.subplots_adjust(bottom=0.22, wspace=0.22)
    ft.guardar(fig, p("03_clasif_regresion.png"))


# ---------------------------------------------------------------------------
# Fig 04 — Flujo de proyecto ML (pipeline lineal de cajas)
# ---------------------------------------------------------------------------
def fig_flujo_ml():
    fig, ax = plt.subplots(figsize=(9.4, 3.8))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 4)

    pasos = [
        ("Datos\nbrutos", ft.SOFT_BLUE, ft.NAVY),
        ("Preparar\n(limpiar)", ft.LIGHT_BLUE, ft.NAVY),
        ("Entrenar\nel modelo", ft.NAVY, "white"),
        ("Evaluar\n(datos nuevos)", ft.SOFT_GREEN, ft.DARK_GREEN),
        ("Usar /\nDecidir", ft.OCHRE, "white"),
    ]
    n = len(pasos)
    w, h = 1.45, 1.1
    gap = (10 - n * w) / (n + 1)
    for i, (txt, fc, tc) in enumerate(pasos):
        x = gap + i * (w + gap)
        y = 1.4
        ax.add_patch(FancyBboxPatch(
            (x, y), w, h,
            boxstyle="round,pad=0.08,rounding_size=0.12",
            fc=fc, ec=ft.NAVY if fc != ft.NAVY else "white",
            lw=1.6, zorder=2))
        ax.text(x + w / 2, y + h / 2, txt, ha="center", va="center",
                color=tc, fontsize=11, fontweight="bold", zorder=3)
        ax.text(x + w / 2, y - 0.32,
                ["880\nobservaciones", "Imputa NA\nnormaliza",
                 "KNN\napprende", "Error honesto\nCV 5-fold",
                 "Pide aprobacion\no revisa costo"][i],
                ha="center", va="top", color=ft.GRAY,
                fontsize=8.2, style="italic")
        if i < n - 1:
            ax.add_patch(FancyArrowPatch(
                (x + w + 0.04, y + h / 2), (x + w + gap - 0.04, y + h / 2),
                arrowstyle="-|>", mutation_scale=17, color=ft.GRAY, lw=1.8))

    ax.text(5.0, 3.65, "Flujo completo de un proyecto de ciencia de datos",
            ha="center", color=ft.NAVY, fontsize=13, fontweight="bold")
    ft.guardar(fig, p("04_flujo_ml.png"))


# ---------------------------------------------------------------------------
# Fig 05 — Histograma real del costo medico (sesgado) + log(costo)
# ---------------------------------------------------------------------------
def fig_histograma_costo():
    csv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "regresion", "datos.csv")
    df = pd.read_csv(csv_path)
    costo = df["costo_anual_mxn"].dropna()

    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.0))
    a = axs[0]
    ft.limpia(a, grid=True)
    a.hist(costo / 1000, bins=40, color=ft.NAVY, edgecolor="white",
           alpha=0.88)
    a.axvline(costo.mean() / 1000, color=ft.DARK_RED, lw=2.2, ls="--",
              label=f"Media: ${costo.mean()/1000:.0f}k")
    a.axvline(costo.median() / 1000, color=ft.DARK_GREEN, lw=2.2, ls="-",
              label=f"Mediana: ${costo.median()/1000:.0f}k")
    a.set_xlabel("Costo anual (miles MXN)", color=ft.GRAY, fontsize=11)
    a.set_ylabel("Frecuencia", color=ft.GRAY, fontsize=11)
    a.legend(fontsize=10, frameon=True)
    ft.titulo(a, "Escala original: sesgada a la derecha", size=13)
    a.text(0.5, -0.2,
           "Cola larga: unos pocos costos altisimos jalan la media",
           transform=a.transAxes, ha="center", color=ft.DARK_RED,
           fontsize=9.5, style="italic")

    b = axs[1]
    ft.limpia(b, grid=True)
    lcosto = np.log(costo)
    b.hist(lcosto, bins=40, color=ft.TEAL, edgecolor="white", alpha=0.88)
    b.axvline(lcosto.mean(), color=ft.DARK_RED, lw=2.2, ls="--",
              label=f"Media: {lcosto.mean():.2f}")
    b.axvline(lcosto.median(), color=ft.DARK_GREEN, lw=2.2, ls="-",
              label=f"Mediana: {lcosto.median():.2f}")
    b.set_xlabel("log(costo anual)", color=ft.GRAY, fontsize=11)
    b.set_ylabel("Frecuencia", color=ft.GRAY, fontsize=11)
    b.legend(fontsize=10, frameon=True)
    ft.titulo(b, "Escala logaritmica: mucho mas simetrica", size=13)
    b.text(0.5, -0.2,
           "Media y mediana casi iguales: mejor para modelar",
           transform=b.transAxes, ha="center", color=ft.DARK_GREEN,
           fontsize=9.5, style="italic")

    fig.subplots_adjust(bottom=0.22, wspace=0.28)
    ft.guardar(fig, p("05_histograma_costo.png"))


# ---------------------------------------------------------------------------
# Fig 06 — Diagrama residuales: real vs predicho con lineas de error
# ---------------------------------------------------------------------------
def fig_residuales():
    csv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "regresion", "datos.csv")
    df = pd.read_csv(csv_path).dropna(subset=["costo_anual_mxn", "edad"])
    X_reg = df[["edad"]].values
    y_reg = np.log(df["costo_anual_mxn"].values)
    scaler = StandardScaler()
    X_s = scaler.fit_transform(X_reg)
    rng2 = np.random.default_rng(42)
    idx = rng2.choice(len(X_s), 300, replace=False)
    X_s, y_reg = X_s[idx], y_reg[idx]
    knn = KNeighborsRegressor(n_neighbors=15).fit(X_s, y_reg)
    y_pred = knn.predict(X_s)

    # Muestra solo 40 puntos para que el grafico sea legible
    sel = rng2.choice(len(X_s), 40, replace=False)
    yr, yp = y_reg[sel], y_pred[sel]

    fig, ax = plt.subplots(figsize=(7.6, 5.0))
    ft.limpia(ax, grid=True)
    ax.scatter(yr, yp, c=ft.NAVY, s=42, edgecolors="white", lw=0.6,
               zorder=4, label="Prediccion")
    ax.plot([yr.min(), yr.max()], [yr.min(), yr.max()],
            color=ft.DARK_GREEN, lw=2.2, ls="--", label="Prediccion perfecta")
    for ri, pi in zip(yr, yp):
        color_err = ft.RED_PT if abs(ri - pi) > 0.3 else ft.LGRAY
        ax.plot([ri, ri], [ri, pi], color=color_err, lw=1.2, zorder=3)
    ax.set_xlabel("log(costo real)", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("log(costo predicho)", color=ft.GRAY, fontsize=12)
    ax.legend(fontsize=11, frameon=True)
    ax.text(0.05, 0.92,
            "Linea vertical = error (residual)",
            transform=ax.transAxes, color=ft.RED_PT,
            fontsize=11, fontweight="bold")
    ft.titulo(ax, "Real vs predicho: las lineas son los errores del modelo")
    ft.guardar(fig, p("06_residuales.png"))


# ---------------------------------------------------------------------------
# Fig 07 — RMSE vs MAE: errores chicos vs grandes
# ---------------------------------------------------------------------------
def fig_rmse_mae():
    fig, ax = plt.subplots(figsize=(8.6, 4.6))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 5)

    errores = [0.5, 1.0, 2.5]
    labels = ["Error chico\n(0.5)", "Error mediano\n(1.0)",
              "Error grande\n(2.5)"]
    x_pos = [1.5, 4.0, 7.0]
    colores_e = [ft.DARK_GREEN, ft.OCHRE, ft.RED_PT]

    for xi, err, lbl, col in zip(x_pos, errores, labels, colores_e):
        # Barra MAE (proporcional)
        mae_h = err * 1.2
        ax.add_patch(Rectangle((xi - 0.45, 0.5), 0.45, mae_h,
                                fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=1.2))
        ax.text(xi - 0.22, 0.5 + mae_h + 0.12, "MAE",
                ha="center", color=ft.NAVY, fontsize=9, fontweight="bold")
        # Barra RMSE (eleva al cuadrado: penaliza mas los grandes)
        rmse_h = (err ** 2) * 0.9
        ax.add_patch(Rectangle((xi, 0.5), 0.45, rmse_h,
                                fc=ft.RED_PT, ec=ft.DARK_RED,
                                lw=1.2, alpha=0.82))
        ax.text(xi + 0.22, 0.5 + rmse_h + 0.12, "RMSE",
                ha="center", color=ft.DARK_RED, fontsize=9,
                fontweight="bold")
        ax.text(xi - 0.1, 0.18, lbl, ha="center", color=col,
                fontsize=9.5, fontweight="bold")

    handles = [
        mpatches.Patch(fc=ft.SOFT_BLUE, ec=ft.NAVY,
                       label="MAE (error directo)"),
        mpatches.Patch(fc=ft.RED_PT, ec=ft.DARK_RED,
                       label="RMSE (penaliza errores grandes)"),
    ]
    ax.legend(handles=handles, loc="upper left", fontsize=10,
              frameon=False, ncol=2)
    ax.text(5.0, 4.65,
            "RMSE castiga mucho mas los errores grandes que el MAE",
            ha="center", color=ft.NAVY, fontsize=12, fontweight="bold")
    ax.text(6.8, 3.8, "Error grande -> RMSE\nse dispara!",
            ha="center", color=ft.DARK_RED, fontsize=10,
            fontweight="bold", style="italic")
    ft.guardar(fig, p("07_rmse_mae.png"))


# ---------------------------------------------------------------------------
# Fig 08 — R2 como proporcion de variacion explicada
# ---------------------------------------------------------------------------
def fig_r2():
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.2))
    rng3 = np.random.default_rng(9)

    a = axs[0]
    ft.limpia(a, grid=True)
    y_sin = rng3.normal(50, 18, 60)
    x_sin = np.zeros(60)
    a.scatter(np.arange(60), y_sin, c=ft.NAVY, s=28, alpha=0.7,
              edgecolors="white", lw=0.5)
    a.axhline(y_sin.mean(), color=ft.DARK_RED, lw=2.2, ls="--",
              label=f"Media = {y_sin.mean():.1f}")
    for i, yi in enumerate(y_sin):
        a.plot([i, i], [y_sin.mean(), yi], color=ft.LGRAY, lw=0.8)
    a.set_xticks([]); a.set_yticks([])
    a.set_xlabel("Observaciones", color=ft.GRAY, fontsize=11)
    a.set_ylabel("Costo (simplificado)", color=ft.GRAY, fontsize=11)
    ft.titulo(a, "Sin modelo: variacion total", size=13)
    a.text(0.5, -0.18, "R2 = 0.0: el modelo no explica nada",
           transform=a.transAxes, ha="center", color=ft.DARK_RED,
           fontsize=9.5, fontweight="bold")

    b = axs[1]
    ft.limpia(b, grid=True)
    x_b = rng3.uniform(20, 70, 60)
    y_b = 0.8 * x_b + 20 + rng3.normal(0, 4, 60)
    b.scatter(x_b, y_b, c=ft.OCHRE, s=28, alpha=0.85,
              edgecolors="white", lw=0.5)
    xs2 = np.array([x_b.min(), x_b.max()])
    slope = np.polyfit(x_b, y_b, 1)
    y_fit = np.polyval(slope, x_b)
    b.plot(xs2, np.polyval(slope, xs2), color=ft.NAVY, lw=2.4)
    for xi2, yi2, yfi in zip(x_b, y_b, y_fit):
        b.plot([xi2, xi2], [yfi, yi2], color=ft.LGRAY, lw=0.8)
    ss_res = np.sum((y_b - y_fit) ** 2)
    ss_tot = np.sum((y_b - y_b.mean()) ** 2)
    r2 = 1 - ss_res / ss_tot
    b.set_xticks([]); b.set_yticks([])
    b.set_xlabel("Edad", color=ft.GRAY, fontsize=11)
    ft.titulo(b, "Con modelo: variacion explicada", size=13)
    b.text(0.5, -0.18, f"R2 = {r2:.2f}: el modelo explica el {r2*100:.0f}%",
           transform=b.transAxes, ha="center", color=ft.DARK_GREEN,
           fontsize=9.5, fontweight="bold")

    fig.subplots_adjust(bottom=0.22, wspace=0.2)
    ft.guardar(fig, p("08_r2.png"))


# ---------------------------------------------------------------------------
# Fig 09 — Sobreajuste: curva error entrenamiento vs datos nuevos
# ---------------------------------------------------------------------------
def fig_sobreajuste():
    X_ov, y_ov = make_moons(n_samples=300, noise=0.30, random_state=17)
    X_ov = (X_ov - X_ov.mean(axis=0)) / X_ov.std(axis=0)
    ks = np.array([1, 3, 5, 9, 15, 25, 41, 61, 91, 131])
    test_err, train_err = [], []
    for k in ks:
        sc = cross_val_score(
            KNeighborsClassifier(n_neighbors=int(k)), X_ov, y_ov,
            cv=5, scoring="accuracy")
        test_err.append(1 - sc.mean())
        clf = KNeighborsClassifier(n_neighbors=int(k)).fit(X_ov, y_ov)
        train_err.append(1 - clf.score(X_ov, y_ov))

    fig, ax = plt.subplots(figsize=(8.6, 4.8))
    ft.limpia(ax, grid=True)
    ax.plot(ks, train_err, "-o", color=ft.OCHRE, lw=2.2,
            label="Error de entrenamiento")
    ax.plot(ks, test_err, "-o", color=ft.NAVY, lw=2.4,
            label="Error en datos nuevos (CV)")
    kbest = ks[int(np.argmin(test_err))]
    ax.axvline(kbest, color=ft.DARK_GREEN, ls="--", lw=1.8)
    ax.annotate("punto optimo", (kbest, min(test_err)),
                textcoords="offset points", xytext=(25, 22),
                color=ft.DARK_GREEN, fontsize=11.5, fontweight="bold",
                arrowprops=dict(arrowstyle="-|>", color=ft.DARK_GREEN))
    ax.text(2, max(test_err) * 0.97, "Sobreajusta\n(memoriza)",
            color=ft.RED_PT, fontsize=10.5, va="top", fontweight="bold")
    ax.text(118, max(test_err) * 0.97, "Subajusta\n(simplifica)",
            color=ft.GRAY, fontsize=10.5, va="top", ha="right")
    ax.set_xlabel("k (numero de vecinos)", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Error", color=ft.GRAY, fontsize=12)
    ax.legend(frameon=True, fontsize=11, loc="center right")
    ft.titulo(ax, "Sobreajuste y subajuste: el equilibrio sesgo-varianza")
    ft.guardar(fig, p("09_sobreajuste.png"))


# ---------------------------------------------------------------------------
# Fig 10 — IA generativa como copiloto (esquema de flujo)
# ---------------------------------------------------------------------------
def fig_copiloto():
    fig, ax = plt.subplots(figsize=(9.4, 4.2))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 4)

    def caja(xc, yc, w, h, texto, fc, tc="white", size=11):
        ax.add_patch(FancyBboxPatch(
            (xc - w / 2, yc - h / 2), w, h,
            boxstyle="round,pad=0.08,rounding_size=0.12",
            fc=fc, ec="none", zorder=2))
        ax.text(xc, yc, texto, ha="center", va="center",
                color=tc, fontsize=size, fontweight="bold", zorder=3)

    # Cajas
    caja(1.4, 2.0, 1.9, 1.0, "Tu\npregunta", ft.NAVY, size=12)
    caja(5.0, 2.0, 2.4, 1.1,
         "Modelo de\nlenguaje (LLM)\nsugiere",
         ft.TEAL, size=11)
    caja(8.6, 3.1, 1.7, 0.85,
         "Verificas\ny aceptas", ft.DARK_GREEN, size=10.5)
    caja(8.6, 0.9, 1.7, 0.85,
         "Corriges\no rechazas", ft.RED_PT, size=10.5)

    # Flechas
    ax.add_patch(FancyArrowPatch(
        (2.35, 2.0), (3.8, 2.0),
        arrowstyle="-|>", mutation_scale=18, color=ft.GRAY, lw=2))
    ax.add_patch(FancyArrowPatch(
        (6.2, 2.4), (7.7, 2.9),
        arrowstyle="-|>", mutation_scale=16, color=ft.DARK_GREEN, lw=1.8))
    ax.add_patch(FancyArrowPatch(
        (6.2, 1.6), (7.7, 1.0),
        arrowstyle="-|>", mutation_scale=16, color=ft.RED_PT, lw=1.8))

    ax.text(2.85, 1.55, "Pregunta o\npide codigo",
            ha="center", color=ft.GRAY, fontsize=8.5, style="italic")
    ax.text(7.0, 2.8, "OK", ha="center", color=ft.DARK_GREEN,
            fontsize=10, fontweight="bold")
    ax.text(7.0, 1.2, "Error / sesgo", ha="center", color=ft.RED_PT,
            fontsize=10, fontweight="bold")
    ax.text(5.0, 0.35,
            "TU eres quien decide — el modelo es un asistente, no la autoridad",
            ha="center", color=ft.NAVY, fontsize=11, fontweight="bold")
    ax.text(5.0, 3.75,
            "La IA generativa como copiloto: siempre verificar antes de usar",
            ha="center", color=ft.NAVY, fontsize=13, fontweight="bold")
    ft.guardar(fig, p("10_copiloto.png"))


# ---------------------------------------------------------------------------
# Fig 11 — Fumador vs no fumador: comparacion de costos reales
# ---------------------------------------------------------------------------
def fig_fumador_costo():
    csv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "regresion", "datos.csv")
    df = pd.read_csv(csv_path).dropna(subset=["costo_anual_mxn", "fumador"])
    fum = df[df["fumador"] == "si"]["costo_anual_mxn"] / 1000
    nofum = df[df["fumador"] == "no"]["costo_anual_mxn"] / 1000

    fig, ax = plt.subplots(figsize=(7.6, 4.6))
    ft.limpia(ax, grid=True)
    ax.hist(nofum, bins=30, color=ft.NAVY, edgecolor="white",
            alpha=0.75, label=f"No fumador (n={len(nofum)})")
    ax.hist(fum, bins=30, color=ft.RED_PT, edgecolor="white",
            alpha=0.75, label=f"Fumador (n={len(fum)})")
    ax.axvline(nofum.median(), color=ft.NAVY, lw=2.4, ls="--")
    ax.axvline(fum.median(), color=ft.RED_PT, lw=2.4, ls="--")
    ax.set_xlabel("Costo anual (miles MXN)", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Frecuencia", color=ft.GRAY, fontsize=12)
    ax.legend(fontsize=11, frameon=True)
    ax.text(0.97, 0.88,
            f"Mediana fumador:\n${fum.median():.0f}k",
            transform=ax.transAxes, ha="right", color=ft.RED_PT,
            fontsize=10.5, fontweight="bold")
    ax.text(0.97, 0.70,
            f"Mediana no fumador:\n${nofum.median():.0f}k",
            transform=ax.transAxes, ha="right", color=ft.NAVY,
            fontsize=10.5, fontweight="bold")
    ft.titulo(ax,
              "Fumar es el mayor predictor del costo medico anual",
              size=13)
    ft.guardar(fig, p("11_fumador_costo.png"))


# ---------------------------------------------------------------------------
if __name__ == "__main__":
    fig_circulos_ia()
    fig_tres_tipos()
    fig_clasif_regresion()
    fig_flujo_ml()
    fig_histograma_costo()
    fig_residuales()
    fig_rmse_mae()
    fig_r2()
    fig_sobreajuste()
    fig_copiloto()
    fig_fumador_costo()
    print("Figuras S17 generadas en", OUT)
