"""Genera imagenes ilustrativas para la presentacion de K-NN."""
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Circle

mpl.rcParams['font.family'] = 'Ubuntu'
mpl.rcParams['axes.spines.top'] = False
mpl.rcParams['axes.spines.right'] = False
mpl.rcParams['axes.edgecolor'] = '#888888'

NAVY = '#1E4C7D'
DARK_RED = '#C0392B'
DARK_GREEN = '#1A7A3A'
GRAY = '#555555'
OCHRE = '#C97B2A'

# =========================================================
# 1) Idea visual de K-NN: punto nuevo + vecinos circundantes
# =========================================================
np.random.seed(7)
n = 40
clase_a = np.random.normal(loc=(2.5, 3.0), scale=0.9, size=(n // 2, 2))
clase_b = np.random.normal(loc=(5.5, 5.5), scale=0.9, size=(n // 2, 2))
nuevo = np.array([4.0, 4.2])

fig, ax = plt.subplots(figsize=(7, 5.2), dpi=160)
ax.scatter(clase_a[:, 0], clase_a[:, 1], color=NAVY, s=70, alpha=0.85,
           edgecolor='white', label='Clase A', zorder=3)
ax.scatter(clase_b[:, 0], clase_b[:, 1], color=DARK_RED, s=70, alpha=0.85,
           edgecolor='white', label='Clase B', zorder=3)
ax.scatter(*nuevo, color=DARK_GREEN, s=260, marker='*',
           edgecolor='white', linewidth=1.5, label='Punto nuevo', zorder=5)

# circulo k=5
todos = np.vstack([clase_a, clase_b])
dist = np.linalg.norm(todos - nuevo, axis=1)
idx = np.argsort(dist)[:5]
r = dist[idx[-1]] + 0.1
ax.add_patch(Circle(nuevo, r, fill=False, linestyle='--',
                    edgecolor=GRAY, linewidth=1.6))
for i in idx:
    ax.plot([nuevo[0], todos[i, 0]], [nuevo[1], todos[i, 1]],
            color=GRAY, alpha=0.6, linewidth=1.2, zorder=2)

ax.set_xlim(0, 8)
ax.set_ylim(0, 8)
ax.set_xlabel("Variable 1", fontsize=11, fontweight='bold', color=NAVY)
ax.set_ylabel("Variable 2", fontsize=11, fontweight='bold', color=NAVY)
ax.set_title("K-NN con k = 5: 5 vecinos mas cercanos del punto nuevo",
             fontsize=12, fontweight='bold', color=NAVY)
ax.grid(alpha=0.25)
ax.legend(loc='upper left', frameon=True, fontsize=10)
plt.tight_layout()
plt.savefig("img_knn/knn_k5.png", bbox_inches='tight', facecolor='white')
plt.close()

# =========================================================
# 2) Efecto del valor de k: k=1 vs k=15 (fronteras de decision)
# =========================================================
from matplotlib.colors import ListedColormap

np.random.seed(11)
X1 = np.random.normal(loc=(2, 2), scale=1.0, size=(35, 2))
X2 = np.random.normal(loc=(5, 5), scale=1.0, size=(35, 2))
X3 = np.random.normal(loc=(2.5, 5.5), scale=0.6, size=(5, 2))  # ruido
X = np.vstack([X1, X2, X3])
y = np.array([0] * 35 + [1] * 35 + [1] * 5)

xx, yy = np.meshgrid(np.linspace(-1, 8, 220), np.linspace(-1, 8, 220))
grid = np.c_[xx.ravel(), yy.ravel()]

def knn_predict(grid, X, y, k):
    preds = []
    for g in grid:
        d = np.linalg.norm(X - g, axis=1)
        idx = np.argsort(d)[:k]
        preds.append(int(np.round(y[idx].mean())))
    return np.array(preds).reshape(xx.shape)

cmap_bg = ListedColormap(['#DDE5ED', '#FADBD8'])

fig, axes = plt.subplots(1, 2, figsize=(10, 4.4), dpi=160)
for ax, k in zip(axes, [1, 15]):
    Z = knn_predict(grid, X, y, k)
    ax.contourf(xx, yy, Z, cmap=cmap_bg, alpha=0.85)
    ax.scatter(X[y == 0, 0], X[y == 0, 1], color=NAVY, s=55,
               edgecolor='white', zorder=3)
    ax.scatter(X[y == 1, 0], X[y == 1, 1], color=DARK_RED, s=55,
               edgecolor='white', zorder=3)
    ax.set_title(f"k = {k}", fontsize=13, fontweight='bold', color=NAVY)
    ax.set_xlim(-1, 8)
    ax.set_ylim(-1, 8)
    ax.set_xlabel("Variable 1", fontsize=10, fontweight='bold', color=NAVY)
    ax.set_ylabel("Variable 2", fontsize=10, fontweight='bold', color=NAVY)
    ax.grid(alpha=0.2)
axes[0].text(0.02, 0.97, "Fronteras irregulares\n(alta varianza)",
             transform=axes[0].transAxes, va='top', fontsize=9,
             color=DARK_RED, fontweight='bold')
axes[1].text(0.02, 0.97, "Fronteras suaves\n(alto sesgo)",
             transform=axes[1].transAxes, va='top', fontsize=9,
             color=DARK_GREEN, fontweight='bold')
plt.tight_layout()
plt.savefig("img_knn/k_efecto.png", bbox_inches='tight', facecolor='white')
plt.close()

# =========================================================
# 3) Importancia de escalar
# =========================================================
fig, axes = plt.subplots(1, 2, figsize=(10, 4.4), dpi=160)

# Datos: edad (20-70) e ingreso (10000-100000)
np.random.seed(3)
edad_a = np.random.normal(35, 8, 25)
ing_a = np.random.normal(25000, 8000, 25)
edad_b = np.random.normal(55, 8, 25)
ing_b = np.random.normal(70000, 12000, 25)

axes[0].scatter(edad_a, ing_a, color=NAVY, s=60,
                edgecolor='white', label='Grupo A')
axes[0].scatter(edad_b, ing_b, color=DARK_RED, s=60,
                edgecolor='white', label='Grupo B')
axes[0].set_xlabel("Edad (anos)", fontsize=10, fontweight='bold', color=NAVY)
axes[0].set_ylabel("Ingreso (pesos)", fontsize=10, fontweight='bold', color=NAVY)
axes[0].set_title("SIN escalar: el ingreso domina la distancia",
                  fontsize=11, fontweight='bold', color=DARK_RED)
axes[0].grid(alpha=0.25)
axes[0].legend(fontsize=9)

# Escaladas (z-score)
todas_edad = np.concatenate([edad_a, edad_b])
todas_ing = np.concatenate([ing_a, ing_b])
edad_a_z = (edad_a - todas_edad.mean()) / todas_edad.std()
edad_b_z = (edad_b - todas_edad.mean()) / todas_edad.std()
ing_a_z = (ing_a - todas_ing.mean()) / todas_ing.std()
ing_b_z = (ing_b - todas_ing.mean()) / todas_ing.std()

axes[1].scatter(edad_a_z, ing_a_z, color=NAVY, s=60,
                edgecolor='white', label='Grupo A')
axes[1].scatter(edad_b_z, ing_b_z, color=DARK_RED, s=60,
                edgecolor='white', label='Grupo B')
axes[1].set_xlabel("Edad (z-score)", fontsize=10, fontweight='bold', color=NAVY)
axes[1].set_ylabel("Ingreso (z-score)", fontsize=10, fontweight='bold', color=NAVY)
axes[1].set_title("CON estandarizacion: ambas variables pesan igual",
                  fontsize=11, fontweight='bold', color=DARK_GREEN)
axes[1].grid(alpha=0.25)
axes[1].legend(fontsize=9)
plt.tight_layout()
plt.savefig("img_knn/escalado.png", bbox_inches='tight', facecolor='white')
plt.close()

# =========================================================
# 4) Distancia Euclidiana 2D
# =========================================================
fig, ax = plt.subplots(figsize=(6.5, 4.8), dpi=160)
p = np.array([1.5, 1.5])
q = np.array([5.5, 4.5])
ax.scatter(*p, s=180, color=NAVY, edgecolor='white', zorder=3)
ax.scatter(*q, s=180, color=DARK_RED, edgecolor='white', zorder=3)
ax.plot([p[0], q[0]], [p[1], q[1]], color=DARK_GREEN, linewidth=2.5, zorder=2)
ax.plot([p[0], q[0]], [p[1], p[1]], color=GRAY, linewidth=1.5,
        linestyle='--', zorder=1)
ax.plot([q[0], q[0]], [p[1], q[1]], color=GRAY, linewidth=1.5,
        linestyle='--', zorder=1)
ax.text(p[0] - 0.4, p[1] - 0.4, "p = (1.5, 1.5)", fontsize=11,
        color=NAVY, fontweight='bold')
ax.text(q[0] + 0.1, q[1] + 0.1, "q = (5.5, 4.5)", fontsize=11,
        color=DARK_RED, fontweight='bold')
ax.text(3.4, 3.4, "d(p,q) = 5.0", fontsize=12, color=DARK_GREEN,
        fontweight='bold', rotation=37)
ax.text(3.4, 1.2, "|x2 - x1| = 4", fontsize=10, color=GRAY)
ax.text(5.6, 3.0, "|y2 - y1| = 3", fontsize=10, color=GRAY)
ax.set_xlim(0, 8)
ax.set_ylim(0, 6)
ax.set_xlabel("X", fontsize=11, fontweight='bold', color=NAVY)
ax.set_ylabel("Y", fontsize=11, fontweight='bold', color=NAVY)
ax.set_title("Distancia euclidiana en 2D (Pitagoras)",
             fontsize=12, fontweight='bold', color=NAVY)
ax.grid(alpha=0.25)
plt.tight_layout()
plt.savefig("img_knn/euclidiana.png", bbox_inches='tight', facecolor='white')
plt.close()

print("Imagenes generadas en img_knn/")
