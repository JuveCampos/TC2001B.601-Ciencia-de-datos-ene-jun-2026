"""Ayudantes de matplotlib para las figuras de las presentaciones TEORICAS
(Sesiones 16-20). Paleta Tec, fuente Ubuntu, exportacion a 300 DPI.

Las figuras se dibujan con codigo (nunca se descargan ni se inventan). Cada
build de sesion importa este modulo y define sus figuras especificas con estos
ayudantes."""
import matplotlib as mpl
import matplotlib.pyplot as plt

mpl.rcParams["font.family"] = "Ubuntu"
mpl.rcParams["axes.unicode_minus"] = False
mpl.rcParams["figure.dpi"] = 110

# === Paleta Tec (hex, para matplotlib) ===
NAVY = "#1E4C7D"
DARK_RED = "#C0392B"
DARK_GREEN = "#1A7A3A"
SOFT_GREEN = "#D5F5E3"
LIGHT_BLUE = "#EAF2FA"
SOFT_BLUE = "#DDE5ED"
MID_BLUE = "#6FB3E0"
GRAY = "#555555"
LGRAY = "#AAAAAA"
# Tarjetas planas del curso
TEAL = "#2D7A7A"
OCHRE = "#C97B2A"
PLUM = "#7D3C66"
OLIVE = "#5A7D2A"
SLATE = "#4A5568"
BLUEA = "#4472C4"
RED_PT = "#D62828"
WHITE = "#FFFFFF"


def guardar(fig, path, *, dpi=300, transparent=False, pad=0.12):
    """Exporta a PNG nitido y cierra la figura."""
    fig.savefig(path, dpi=dpi, bbox_inches="tight", pad_inches=pad,
                transparent=transparent, facecolor="white")
    plt.close(fig)


def limpia(ax, *, keep=("left", "bottom"), grid=False):
    """Quita spines superiores/derechos; opcionalmente deja una rejilla suave."""
    for s in ("top", "right", "left", "bottom"):
        ax.spines[s].set_visible(s in keep)
    for s in keep:
        ax.spines[s].set_color(GRAY)
        ax.spines[s].set_linewidth(1.1)
    ax.tick_params(colors=GRAY, labelsize=11)
    if grid:
        ax.grid(True, color="#E3E3E3", linewidth=0.8, zorder=0)
        ax.set_axisbelow(True)


def sin_ejes(ax):
    """Lienzo limpio para diagramas/esquemas (sin ejes ni marcas)."""
    ax.set_xticks([])
    ax.set_yticks([])
    for s in ("top", "right", "left", "bottom"):
        ax.spines[s].set_visible(False)


def titulo(ax, texto, *, size=15):
    ax.set_title(texto, color=NAVY, fontsize=size, fontweight="bold", pad=12)
