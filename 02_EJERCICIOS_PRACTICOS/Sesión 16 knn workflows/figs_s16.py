"""Genera las figuras de la presentacion TEORICA de la Sesion 16 (KNN,
workflows, validacion cruzada y tuning). Diagramas conceptuales + fronteras de
decision e indicadores calculados sobre un conjunto 2D ilustrativo (para poder
graficarlos; los datos reales del ejercicio tienen muchas dimensiones).

Salida: ./img_teoria/*.png a 300 DPI."""
import os
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Circle, Rectangle
from sklearn.datasets import make_moons
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import cross_val_score
from sklearn.metrics import roc_curve, auc

import figteoria as ft

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "img_teoria")
os.makedirs(OUT, exist_ok=True)
p = lambda nombre: os.path.join(OUT, nombre)

# Datos 2D ilustrativos: "ingreso" y "score" estandarizados, clase aprobado.
rng = np.random.default_rng(16)
X, y = make_moons(n_samples=260, noise=0.30, random_state=16)
X = (X - X.mean(axis=0)) / X.std(axis=0)
COL = {1: ft.NAVY, 0: ft.RED_PT}      # 1 = aprobado, 0 = rechazado
ETI = {1: "Aprobado", 0: "Rechazado"}


def _scatter(ax, *, alpha=0.9, s=34):
    for c in (0, 1):
        m = y == c
        ax.scatter(X[m, 0], X[m, 1], c=COL[c], label=ETI[c], s=s, alpha=alpha,
                   edgecolors="white", linewidths=0.6, zorder=3)


def _ejes_credito(ax):
    ax.set_xlabel("Ingreso (estandarizado)", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Score de crédito (estandarizado)", color=ft.GRAY,
                  fontsize=12)


# ---------------------------------------------------------------------------
def fig_supervisado():
    fig, ax = plt.subplots(figsize=(9.2, 4.4))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 4)

    def caja(x, y_, w, h, texto, color, fg="white", size=12):
        ax.add_patch(FancyBboxPatch((x, y_), w, h,
                     boxstyle="round,pad=0.08,rounding_size=0.12",
                     fc=color, ec="none", zorder=2))
        ax.text(x + w / 2, y_ + h / 2, texto, ha="center", va="center",
                color=fg, fontsize=size, fontweight="bold", zorder=3)

    caja(0.3, 1.2, 2.7, 1.6,
         "Datos con\nRESPUESTA conocida\n(solicitudes pasadas:\naprobado / rechazado)",
         ft.SOFT_BLUE, fg=ft.NAVY, size=11)
    caja(3.8, 1.4, 2.4, 1.2, "MODELO\nque aprende\nel patrón", ft.NAVY, size=13)
    caja(7.0, 1.2, 2.7, 1.6,
         "Predicción para\nun caso NUEVO\n(¿aprobar esta\nsolicitud?)",
         ft.SOFT_GREEN, fg=ft.DARK_GREEN, size=11)
    for x0, x1 in ((3.05, 3.75), (6.25, 6.95)):
        ax.add_patch(FancyArrowPatch((x0, 2.0), (x1, 2.0),
                     arrowstyle="-|>", mutation_scale=22, color=ft.GRAY, lw=2))
    ax.text(5.0, 0.7, "Aprendizaje supervisado: aprender de ejemplos etiquetados",
            ha="center", color=ft.GRAY, fontsize=11, style="italic")
    ft.guardar(fig, p("01_supervisado.png"))


def fig_clasif_regres():
    fig, axs = plt.subplots(1, 2, figsize=(9.2, 4.0))
    a = axs[0]
    ft.limpia(a, grid=True)
    g1 = rng.normal([-1, 1], 0.5, (40, 2)); g2 = rng.normal([1, -1], 0.5, (40, 2))
    a.scatter(g1[:, 0], g1[:, 1], c=ft.NAVY, s=28, edgecolors="white", lw=0.5)
    a.scatter(g2[:, 0], g2[:, 1], c=ft.RED_PT, s=28, edgecolors="white", lw=0.5)
    a.plot([-2.2, 2.2], [-2.2, 2.2], "--", color=ft.DARK_GREEN, lw=2)
    a.set_xticks([]); a.set_yticks([])
    ft.titulo(a, "Clasificación", size=14)
    a.text(0.5, -0.16, "La respuesta es una CATEGORÍA\n(aprobado / rechazado)",
           transform=a.transAxes, ha="center", va="top", color=ft.GRAY,
           fontsize=10.5)
    b = axs[1]
    ft.limpia(b, grid=True)
    xx = rng.uniform(0, 10, 50); yy = 1.2 * xx + 3 + rng.normal(0, 2.2, 50)
    b.scatter(xx, yy, c=ft.OCHRE, s=28, edgecolors="white", lw=0.5)
    xs = np.array([0, 10]); b.plot(xs, 1.2 * xs + 3, color=ft.NAVY, lw=2.2)
    b.set_xticks([]); b.set_yticks([])
    ft.titulo(b, "Regresión", size=14)
    b.text(0.5, -0.16, "La respuesta es un NÚMERO\n(costo médico en pesos)",
           transform=b.transAxes, ha="center", va="top", color=ft.GRAY,
           fontsize=10.5)
    fig.subplots_adjust(bottom=0.2, wspace=0.15)
    ft.guardar(fig, p("02_clasif_regres.png"))


def fig_espacio():
    fig, ax = plt.subplots(figsize=(8.4, 5.0))
    ft.limpia(ax, grid=True)
    _scatter(ax)
    _ejes_credito(ax)
    ax.legend(loc="upper right", frameon=True, fontsize=11)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, "Cada solicitud es un punto en el espacio de características")
    ft.guardar(fig, p("03_espacio.png"))


def fig_distancia():
    fig, ax = plt.subplots(figsize=(7.6, 5.0))
    ft.limpia(ax, grid=True)
    A = np.array([1.0, 1.2]); B = np.array([3.6, 3.0])
    ax.scatter(*A, c=ft.NAVY, s=130, zorder=4, edgecolors="white", lw=1)
    ax.scatter(*B, c=ft.RED_PT, s=130, zorder=4, edgecolors="white", lw=1)
    ax.annotate("Persona A", A, textcoords="offset points", xytext=(-10, -22),
                color=ft.NAVY, fontsize=12, fontweight="bold", ha="center")
    ax.annotate("Persona B", B, textcoords="offset points", xytext=(10, 12),
                color=ft.RED_PT, fontsize=12, fontweight="bold", ha="center")
    ax.plot([A[0], B[0]], [A[1], B[1]], color=ft.DARK_GREEN, lw=2.5, zorder=3)
    ax.plot([A[0], B[0]], [A[1], A[1]], "--", color=ft.GRAY, lw=1.5)
    ax.plot([B[0], B[0]], [A[1], B[1]], "--", color=ft.GRAY, lw=1.5)
    ax.text((A[0] + B[0]) / 2, A[1] - 0.28, "diferencia en ingreso",
            ha="center", color=ft.GRAY, fontsize=10.5)
    ax.text(B[0] + 0.1, (A[1] + B[1]) / 2, "diferencia\nen score",
            ha="left", va="center", color=ft.GRAY, fontsize=10.5)
    ax.text(2.0, 2.5, "distancia", color=ft.DARK_GREEN, fontsize=13,
            fontweight="bold", rotation=33)
    ax.set_xlim(0, 5); ax.set_ylim(0, 4)
    ax.set_xticks([]); ax.set_yticks([])
    _ejes_credito(ax)
    ft.titulo(ax, "Distancia = qué tan parecidas son dos personas")
    ft.guardar(fig, p("04_distancia.png"))


def fig_knn_vota():
    fig, ax = plt.subplots(figsize=(8.4, 5.2))
    ft.limpia(ax, grid=True)
    _scatter(ax, alpha=0.45, s=30)
    # Buscamos un punto de consulta cuyos 5 vecinos den un voto 3-2 con mayoria
    # "aprobado" (3 azules, 2 rojos): asi la votacion se ve interesante.
    gx = np.linspace(X[:, 0].min() + 0.3, X[:, 0].max() - 0.3, 40)
    gy = np.linspace(X[:, 1].min() + 0.3, X[:, 1].max() - 0.3, 40)
    q = np.array([0.0, 0.0])
    for qx in gx:
        for qy in gy:
            cand = np.array([qx, qy])
            ii = np.argsort(np.sqrt(((X - cand) ** 2).sum(axis=1)))[:5]
            if np.bincount(y[ii], minlength=2).tolist() == [2, 3]:
                q = cand
                break
        else:
            continue
        break
    d = np.sqrt(((X - q) ** 2).sum(axis=1))
    idx = np.argsort(d)[:5]
    r = d[idx].max()
    ax.add_patch(Circle(q, r, fill=False, ec=ft.DARK_GREEN, lw=2,
                        ls="--", zorder=2))
    for i in idx:
        ax.plot([q[0], X[i, 0]], [q[1], X[i, 1]], color=ft.GRAY, lw=1, zorder=2)
        ax.scatter(X[i, 0], X[i, 1], c=COL[y[i]], s=70, edgecolors=ft.DARK_GREEN,
                   linewidths=1.8, zorder=5)
    ax.scatter(*q, marker="*", c=ft.DARK_GREEN, s=420, edgecolors="white",
               linewidths=1.2, zorder=6)
    votos = np.bincount(y[idx], minlength=2)
    ax.annotate("Solicitud nueva", q, textcoords="offset points",
                xytext=(0, 18), ha="center", color=ft.DARK_GREEN, fontsize=12,
                fontweight="bold")
    ax.set_xticks([]); ax.set_yticks([])
    _ejes_credito(ax)
    ft.titulo(ax, f"k = 5 vecinos más cercanos votan: "
                  f"{votos[1]} aprobado vs {votos[0]} rechazado")
    ax.legend(loc="upper right", frameon=True, fontsize=10)
    ft.guardar(fig, p("05_knn_vota.png"))


def _frontera(ax, k, titulo_):
    h = 0.03
    x0, x1 = X[:, 0].min() - 0.5, X[:, 0].max() + 0.5
    y0, y1 = X[:, 1].min() - 0.5, X[:, 1].max() + 0.5
    xx, yy = np.meshgrid(np.arange(x0, x1, h), np.arange(y0, y1, h))
    clf = KNeighborsClassifier(n_neighbors=k).fit(X, y)
    Z = clf.predict(np.c_[xx.ravel(), yy.ravel()]).reshape(xx.shape)
    from matplotlib.colors import ListedColormap
    ax.contourf(xx, yy, Z, alpha=0.25,
                cmap=ListedColormap([ft.RED_PT, ft.NAVY]))
    _scatter(ax, alpha=0.85, s=22)
    ax.set_xticks([]); ax.set_yticks([])
    ft.titulo(ax, titulo_, size=13)


def fig_fronteras_3():
    fig, axs = plt.subplots(1, 3, figsize=(9.4, 3.5))
    _frontera(axs[0], 1, "k = 1  (sobreajuste)")
    _frontera(axs[1], 15, "k = 15  (equilibrado)")
    _frontera(axs[2], 120, "k = 120  (subajuste)")
    fig.subplots_adjust(wspace=0.08)
    ft.guardar(fig, p("06_fronteras_3.png"))


def fig_frontera_k1():
    fig, ax = plt.subplots(figsize=(5.2, 4.6))
    _frontera(ax, 1, "k = 1: frontera ruidosa")
    ft.guardar(fig, p("07_frontera_k1.png"))


def fig_frontera_kgrande():
    fig, ax = plt.subplots(figsize=(5.2, 4.6))
    _frontera(ax, 120, "k = 120: frontera demasiado plana")
    ft.guardar(fig, p("08_frontera_kgrande.png"))


def fig_sesgo_varianza():
    ks = np.array([1, 3, 5, 9, 15, 25, 41, 61, 91, 131, 181])
    test = []
    for k in ks:
        sc = cross_val_score(KNeighborsClassifier(n_neighbors=int(k)), X, y,
                             cv=5, scoring="accuracy")
        test.append(1 - sc.mean())
    train = []
    for k in ks:
        clf = KNeighborsClassifier(n_neighbors=int(k)).fit(X, y)
        train.append(1 - clf.score(X, y))
    fig, ax = plt.subplots(figsize=(8.6, 4.8))
    ft.limpia(ax, grid=True)
    ax.plot(ks, train, "-o", color=ft.OCHRE, lw=2.2, label="Error en entrenamiento")
    ax.plot(ks, test, "-o", color=ft.NAVY, lw=2.4, label="Error en datos nuevos")
    kbest = ks[int(np.argmin(test))]
    ax.axvline(kbest, color=ft.DARK_GREEN, ls="--", lw=1.6)
    ax.annotate("punto dulce", (kbest, min(test)), textcoords="offset points",
                xytext=(28, 24), color=ft.DARK_GREEN, fontsize=12,
                fontweight="bold",
                arrowprops=dict(arrowstyle="-|>", color=ft.DARK_GREEN))
    ax.text(2, max(test) * 0.98, "k chico\nsobreajusta", color=ft.GRAY,
            fontsize=10.5, va="top")
    ax.text(150, max(test) * 0.98, "k grande\nsubajusta", color=ft.GRAY,
            fontsize=10.5, va="top", ha="right")
    ax.set_xlabel("k (número de vecinos)", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Error", color=ft.GRAY, fontsize=12)
    ax.legend(frameon=True, fontsize=11, loc="center right")
    ft.titulo(ax, "El equilibrio sesgo-varianza")
    ft.guardar(fig, p("09_sesgo_varianza.png"))


def fig_escala():
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 4.4))
    rng2 = np.random.default_rng(7)
    ing = rng2.uniform(8000, 250000, 60)
    ncred = rng2.integers(0, 9, 60).astype(float)
    a = axs[0]
    ft.limpia(a, grid=True)
    a.scatter(ing, ncred, c=ft.NAVY, s=30, edgecolors="white", lw=0.5)
    a.set_xlabel("Ingreso (pesos)", color=ft.GRAY, fontsize=11)
    a.set_ylabel("Núm. de créditos", color=ft.GRAY, fontsize=11)
    ft.titulo(a, "SIN normalizar", size=13)
    a.text(0.5, -0.22, "El ingreso (miles) aplasta al\nnúm. de créditos (0-8) en la distancia",
           transform=a.transAxes, ha="center", va="top", color=ft.DARK_RED,
           fontsize=10)
    b = axs[1]
    ft.limpia(b, grid=True)
    z1 = (ing - ing.mean()) / ing.std(); z2 = (ncred - ncred.mean()) / ncred.std()
    b.scatter(z1, z2, c=ft.DARK_GREEN, s=30, edgecolors="white", lw=0.5)
    b.set_xlabel("Ingreso (estandarizado)", color=ft.GRAY, fontsize=11)
    b.set_ylabel("Créditos (estandarizado)", color=ft.GRAY, fontsize=11)
    ft.titulo(b, "Normalizado", size=13)
    b.text(0.5, -0.22, "Ahora las dos variables pesan\nigual: misma escala",
           transform=b.transAxes, ha="center", va="top", color=ft.DARK_GREEN,
           fontsize=10)
    fig.subplots_adjust(bottom=0.26, wspace=0.32)
    ft.guardar(fig, p("10_escala.png"))


def fig_colinealidad():
    fig, ax = plt.subplots(figsize=(7.6, 4.8))
    ft.limpia(ax, grid=True)
    monto = rng.uniform(10, 100, 80)
    pago = monto / 2.0 + rng.normal(0, 2.5, 80)
    ax.scatter(monto, pago, c=ft.NAVY, s=30, edgecolors="white", lw=0.5)
    ax.set_xlabel("Monto solicitado (miles)", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Pago mensual estimado", color=ft.GRAY, fontsize=12)
    r = np.corrcoef(monto, pago)[0, 1]
    ax.text(0.05, 0.92, f"correlación r = {r:.2f}", transform=ax.transAxes,
            color=ft.DARK_RED, fontsize=13, fontweight="bold")
    ft.titulo(ax, "Variables redundantes: dicen casi lo mismo")
    ft.guardar(fig, p("11_colinealidad.png"))


def fig_normalizacion():
    fig, axs = plt.subplots(1, 2, figsize=(9.4, 3.9))
    datos = rng.normal(45000, 15000, 400)
    a = axs[0]; ft.limpia(a, grid=True)
    a.hist(datos, bins=22, color="#9DBBD6", edgecolor=ft.NAVY)
    a.set_xlabel("Ingreso (pesos)", color=ft.GRAY, fontsize=11)
    ft.titulo(a, "Antes", size=13)
    b = axs[1]; ft.limpia(b, grid=True)
    z = (datos - datos.mean()) / datos.std()
    b.hist(z, bins=22, color="#A8D5BA", edgecolor=ft.DARK_GREEN)
    b.axvline(0, color=ft.DARK_RED, lw=1.6)
    b.set_xlabel("Mismo dato estandarizado (media 0, desv. 1)", color=ft.GRAY,
                 fontsize=11)
    ft.titulo(b, "Después", size=13)
    fig.subplots_adjust(wspace=0.2, bottom=0.18)
    ft.guardar(fig, p("12_normalizacion.png"))


def fig_split():
    fig, ax = plt.subplots(figsize=(9.2, 2.8))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 3)
    ax.add_patch(Rectangle((0.3, 1.0), 7.0, 1.2, fc=ft.NAVY, ec="none"))
    ax.text(3.8, 1.6, "ENTRENAMIENTO  (75%)", ha="center", va="center",
            color="white", fontsize=14, fontweight="bold")
    ax.add_patch(Rectangle((7.4, 1.0), 2.3, 1.2, fc=ft.RED_PT, ec="none"))
    ax.text(8.55, 1.6, "PRUEBA\n(25%)", ha="center", va="center", color="white",
            fontsize=12, fontweight="bold")
    # candado dibujado
    ax.add_patch(Rectangle((8.42, 0.42), 0.26, 0.2, fc=ft.GRAY, ec="none"))
    ax.add_patch(FancyArrowPatch((8.48, 0.62), (8.48, 0.74), arrowstyle="-",
                 color=ft.GRAY, lw=2))
    ax.add_patch(FancyArrowPatch((8.62, 0.62), (8.62, 0.74), arrowstyle="-",
                 color=ft.GRAY, lw=2))
    ax.text(8.55, 0.2, "se guarda en\nla caja fuerte", ha="center", va="top",
            color=ft.GRAY, fontsize=9.5)
    ax.text(3.8, 0.5, "para aprender y elegir k", ha="center", color=ft.GRAY,
            fontsize=10)
    ax.text(5.0, 2.55, "Todos los datos disponibles", ha="center",
            color=ft.NAVY, fontsize=12, fontweight="bold")
    ft.guardar(fig, p("13_split.png"))


def fig_cv_folds():
    fig, ax = plt.subplots(figsize=(8.8, 4.6))
    ft.sin_ejes(ax)
    nf = 5
    ax.set_xlim(-0.5, nf + 0.5); ax.set_ylim(-0.5, nf + 0.5)
    for it in range(nf):
        fila = nf - 1 - it
        for j in range(nf):
            val = (j == it)
            color = ft.DARK_GREEN if val else ft.NAVY
            ax.add_patch(Rectangle((j, fila), 0.92, 0.82, fc=color, ec="white",
                         lw=1.5))
        ax.text(-0.15, fila + 0.41, f"Ronda {it + 1}", ha="right", va="center",
                color=ft.GRAY, fontsize=11)
    ax.text(nf / 2, nf + 0.1, "Cada bloque es 1/5 del entrenamiento",
            ha="center", color=ft.NAVY, fontsize=12, fontweight="bold")
    from matplotlib.patches import Patch
    ax.legend(handles=[Patch(fc=ft.NAVY, label="Entrena"),
                       Patch(fc=ft.DARK_GREEN, label="Valida")],
              loc="lower center", ncol=2, frameon=False,
              bbox_to_anchor=(0.5, -0.12), fontsize=12)
    ft.guardar(fig, p("14_cv_folds.png"))


def fig_workflow():
    fig, ax = plt.subplots(figsize=(9.2, 4.4))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 10); ax.set_ylim(0, 5)
    ax.add_patch(FancyBboxPatch((0.4, 0.5), 9.2, 4.0,
                 boxstyle="round,pad=0.1,rounding_size=0.15", fc=ft.LIGHT_BLUE,
                 ec=ft.NAVY, lw=2))
    ax.text(5.0, 4.15, "workflow()  —  todo en un solo paquete", ha="center",
            color=ft.NAVY, fontsize=14, fontweight="bold")
    pasos = ["Imputar\nfaltantes", "Quitar\nredundantes", "Normalizar"]
    for i, t in enumerate(pasos):
        x = 0.9 + i * 2.0
        ax.add_patch(FancyBboxPatch((x, 1.8), 1.7, 1.3,
                     boxstyle="round,pad=0.06,rounding_size=0.1",
                     fc=ft.SOFT_BLUE, ec=ft.NAVY, lw=1.2))
        ax.text(x + 0.85, 2.45, t, ha="center", va="center", color=ft.NAVY,
                fontsize=10.5, fontweight="bold")
        if i < 2:
            ax.add_patch(FancyArrowPatch((x + 1.7, 2.45), (x + 2.0, 2.45),
                         arrowstyle="-|>", mutation_scale=16, color=ft.GRAY,
                         lw=1.6))
    ax.text(2.95, 3.35, "RECETA (preprocesamiento)", ha="center", color=ft.GRAY,
            fontsize=10.5, style="italic")
    ax.add_patch(FancyBboxPatch((7.2, 1.8), 2.0, 1.3,
                 boxstyle="round,pad=0.06,rounding_size=0.1", fc=ft.NAVY,
                 ec="none"))
    ax.text(8.2, 2.45, "MODELO\nKNN", ha="center", va="center", color="white",
            fontsize=12, fontweight="bold")
    ax.add_patch(FancyArrowPatch((6.7, 2.45), (7.2, 2.45), arrowstyle="-|>",
                 mutation_scale=18, color=ft.GRAY, lw=1.8))
    ax.text(5.0, 0.95, "fit() entrena todo junto  ·  predict() aplica todo junto",
            ha="center", color=ft.DARK_GREEN, fontsize=11.5, fontweight="bold")
    ft.guardar(fig, p("15_workflow.png"))


def fig_auc_vs_k():
    ks = np.array([1, 3, 5, 9, 15, 21, 31, 45, 61, 81, 101])
    medias, errs = [], []
    for k in ks:
        sc = cross_val_score(KNeighborsClassifier(n_neighbors=int(k)), X, y,
                             cv=5, scoring="roc_auc")
        medias.append(sc.mean()); errs.append(sc.std())
    medias = np.array(medias)
    fig, ax = plt.subplots(figsize=(8.6, 4.8))
    ft.limpia(ax, grid=True)
    ax.errorbar(ks, medias, yerr=errs, fmt="-o", color=ft.NAVY, lw=2.2,
                ecolor=ft.LGRAY, capsize=3, markersize=6)
    kbest = ks[int(np.argmax(medias))]
    ax.scatter([kbest], [medias.max()], c=ft.DARK_GREEN, s=160, zorder=5,
               edgecolors="white", lw=1.5)
    ax.annotate(f"mejor k = {kbest}", (kbest, medias.max()),
                textcoords="offset points", xytext=(20, -28),
                color=ft.DARK_GREEN, fontsize=12, fontweight="bold",
                arrowprops=dict(arrowstyle="-|>", color=ft.DARK_GREEN))
    ax.set_xlabel("k (número de vecinos)", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("AUC promedio (validación cruzada)", color=ft.GRAY,
                  fontsize=12)
    ft.titulo(ax, "El tuning elige el k con mejor AUC")
    ft.guardar(fig, p("16_auc_vs_k.png"))


def fig_matriz_confusion():
    fig, ax = plt.subplots(figsize=(7.4, 5.2))
    ft.sin_ejes(ax)
    ax.set_xlim(0, 4); ax.set_ylim(0, 4)
    celdas = [((1, 2), ft.DARK_GREEN, "Verdadero\npositivo", "acierto"),
              ((2, 2), ft.DARK_RED, "Falso\npositivo", "falsa alarma"),
              ((1, 1), ft.DARK_RED, "Falso\nnegativo", "se nos pasó"),
              ((2, 1), ft.DARK_GREEN, "Verdadero\nnegativo", "acierto")]
    for (cx, cy), color, t, sub in celdas:
        ax.add_patch(Rectangle((cx, cy), 0.98, 0.98, fc=color, ec="white",
                     lw=2, alpha=0.85))
        ax.text(cx + 0.49, cy + 0.58, t, ha="center", va="center",
                color="white", fontsize=12, fontweight="bold")
        ax.text(cx + 0.49, cy + 0.26, sub, ha="center", va="center",
                color="white", fontsize=9, style="italic")
    ax.text(1.49, 3.15, "Predijo: SÍ", ha="center", color=ft.NAVY, fontsize=11,
            fontweight="bold")
    ax.text(2.49, 3.15, "Predijo: NO", ha="center", color=ft.NAVY, fontsize=11,
            fontweight="bold")
    ax.text(0.85, 2.49, "Real:\nSÍ", ha="center", va="center", color=ft.NAVY,
            fontsize=11, fontweight="bold")
    ax.text(0.85, 1.49, "Real:\nNO", ha="center", va="center", color=ft.NAVY,
            fontsize=11, fontweight="bold")
    ft.titulo(ax, "Matriz de confusión: 4 resultados posibles")
    ft.guardar(fig, p("17_matriz_confusion.png"))


def fig_roc():
    n = len(X) // 2
    clf = KNeighborsClassifier(n_neighbors=15).fit(X[:n], y[:n])
    prob = clf.predict_proba(X[n:])[:, 1]
    fpr, tpr, _ = roc_curve(y[n:], prob)
    a = auc(fpr, tpr)
    fig, ax = plt.subplots(figsize=(6.6, 5.2))
    ft.limpia(ax, grid=True)
    ax.plot([0, 1], [0, 1], "--", color=ft.GRAY, lw=1.5, label="Azar (AUC = 0.5)")
    ax.plot(fpr, tpr, color=ft.NAVY, lw=2.6, label=f"KNN (AUC = {a:.2f})")
    ax.fill_between(fpr, tpr, alpha=0.12, color=ft.NAVY)
    ax.set_xlabel("Falsos positivos", color=ft.GRAY, fontsize=12)
    ax.set_ylabel("Verdaderos positivos", color=ft.GRAY, fontsize=12)
    ax.legend(loc="lower right", frameon=True, fontsize=11)
    ft.titulo(ax, "Curva ROC: entre más arriba-izquierda, mejor")
    ft.guardar(fig, p("18_roc.png"))


if __name__ == "__main__":
    fig_supervisado()
    fig_clasif_regres()
    fig_espacio()
    fig_distancia()
    fig_knn_vota()
    fig_fronteras_3()
    fig_frontera_k1()
    fig_frontera_kgrande()
    fig_sesgo_varianza()
    fig_escala()
    fig_colinealidad()
    fig_normalizacion()
    fig_split()
    fig_cv_folds()
    fig_workflow()
    fig_auc_vs_k()
    fig_matriz_confusion()
    fig_roc()
    print("Figuras S16 generadas en", OUT)
