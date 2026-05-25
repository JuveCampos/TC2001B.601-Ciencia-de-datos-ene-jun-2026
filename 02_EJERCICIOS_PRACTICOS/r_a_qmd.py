#!/usr/bin/env python3
"""Convierte un ejercicio.R (con banners # ====, prosa en comentarios y codigo)
en un ejercicio.qmd literario: banners -> encabezados, parrafos de comentario
-> prosa markdown, codigo -> chunks ```{r}``` ejecutables.

Uso:
  python3 r_a_qmd.py                 # convierte todos los */ejercicio.R bajo
                                     # la carpeta actual (recursivo)
  python3 r_a_qmd.py ruta/a/ejercicio.R [otra.R ...]   # archivos puntuales

Luego renderizar a HTML con: quarto render ruta/a/ejercicio.qmd

Reglas de segmentacion:
- Linea de regla (banner): solo '#', espacios y una corrida de '=' o '-'.
- Un banner = regla, lineas-titulo (comentarios), regla. El primer banner del
  archivo aporta el titulo/subtitulo del YAML; los demas -> encabezado '##'.
- El contenido entre banners se parte en bloques por lineas en blanco.
  Bloque con algo de codigo -> chunk; bloque solo de comentarios -> prosa.
- En prosa, las lineas envueltas se re-flujan en parrafos (las lineas '#'
  vacias separan parrafos).
"""
import glob
import os
import re
import sys

RULE = re.compile(r"^#\s*[=\-]{3,}\s*$")
AUTHOR = "Jorge Juvenal Campos Ferreira — TC2001B.601"


def is_comment(line):
    return line.lstrip().startswith("#")


def is_blank(line):
    return line.strip() == ""


def strip_comment(line):
    s = line.lstrip()
    s = s[1:]  # quita el '#'
    if s.startswith(" "):
        s = s[1:]
    return s


def tokenize(lines):
    """Devuelve lista de ('header', [titulos]) y ('content', [lineas])."""
    tokens = []
    i, n = 0, len(lines)
    while i < n:
        if RULE.match(lines[i]):
            j = i + 1
            title_lines = []
            while j < n and not RULE.match(lines[j]):
                if is_comment(lines[j]) or is_blank(lines[j]):
                    title_lines.append(lines[j])
                    j += 1
                else:
                    break
            if j < n and RULE.match(lines[j]):
                titles = [strip_comment(t).rstrip() for t in title_lines
                          if is_comment(t)]
                titles = [t for t in titles if t.strip() != ""]
                tokens.append(("header", titles))
                i = j + 1
                continue
            i += 1  # regla suelta sin cierre: se ignora
            continue
        content = []
        while i < n and not RULE.match(lines[i]):
            content.append(lines[i])
            i += 1
        tokens.append(("content", content))
    return tokens


def split_blocks(content):
    blocks, cur = [], []
    for line in content:
        if is_blank(line):
            if cur:
                blocks.append(cur)
                cur = []
        else:
            cur.append(line)
    if cur:
        blocks.append(cur)
    return blocks


def block_is_code(block):
    return any(not is_comment(l) for l in block)


LIST_RE = re.compile(r"^(?:(?P<num>\(\d+\)|\d+\.)|(?P<bul>[-*•]))\s+(?P<txt>.*)$")


def render_prose(block):
    """Re-fluye lineas envueltas en parrafos; convierte enumeraciones
    '(1)...'/'- ...' en items de lista markdown (las lineas de continuacion,
    sin marcador, se unen al item vigente)."""
    items = []           # ('p'|'ol'|'ul', texto)
    cur_text, cur_type = [], "p"

    def flush():
        nonlocal cur_text, cur_type
        if cur_text:
            items.append((cur_type, " ".join(cur_text)))
            cur_text, cur_type = [], "p"

    for l in block:
        s = strip_comment(l).strip()
        if s == "":
            flush()
            items.append(("break", ""))
            continue
        m = LIST_RE.match(s)
        if m:
            flush()
            cur_type = "ol" if m.group("num") else "ul"
            cur_text = [m.group("txt").strip()]
        else:
            cur_text.append(s)
    flush()

    # Agrupa items consecutivos del mismo tipo de lista en un solo bloque.
    out, i = [], 0
    while i < len(items):
        kind, txt = items[i]
        if kind == "break":
            i += 1
            continue
        if kind in ("ol", "ul"):
            j, lis = i, []
            while j < len(items) and items[j][0] == kind:
                lis.append(items[j][1])
                j += 1
            marker = "- " if kind == "ul" else None
            lines = []
            for idx, t in enumerate(lis, start=1):
                pref = marker if marker else f"{idx}. "
                lines.append(pref + t)
            out.append("\n".join(lines))
            i = j
        else:
            out.append(txt)
            i += 1
    return "\n\n".join(out)


def render_code(block):
    return "```{r}\n" + "\n".join(block) + "\n```"


def yaml_header(title, subtitle, html_name):
    t = title.replace('"', "'")
    s = subtitle.replace('"', "'") if subtitle else ""
    lines = [
        "---",
        f'title: "{t}"',
    ]
    if s:
        lines.append(f'subtitle: "{s}"')
    lines += [
        f'author: "{AUTHOR}"',
        "lang: es",
        "date: today",
        "format:",
        "  html:",
        "    toc: true",
        '    toc-title: "Contenido"',
        "    toc-location: left",
        "    toc-depth: 2",
        "    number-sections: false",
        "    code-tools: true",
        "    code-copy: true",
        "    theme: cosmo",
        "    highlight-style: github",
        "    fig-width: 8",
        "    fig-height: 5",
        "    fig-align: center",
        "    embed-resources: true",
        "execute:",
        "  echo: true",
        "  warning: false",
        "  message: false",
        "  cache: false",
        "---",
    ]
    return "\n".join(lines)


def convert(path):
    with open(path, encoding="utf-8") as f:
        lines = [l.rstrip("\n") for l in f]
    tokens = tokenize(lines)

    # Localiza el primer header para el titulo del documento.
    first_header_idx = next((k for k, (kind, _) in enumerate(tokens)
                             if kind == "header"), None)
    titles = tokens[first_header_idx][1] if first_header_idx is not None else []
    subtitle = titles[0] if titles else ""
    title = titles[1] if len(titles) >= 2 else (titles[0] if titles else "Ejercicio")
    lead = " ".join(titles[2:]) if len(titles) > 2 else ""

    out = [yaml_header(title, subtitle, None), ""]
    if lead:
        out.append("*" + lead + "*")
        out.append("")

    header_seen = False
    for kind, payload in tokens:
        if kind == "header":
            if not header_seen:
                header_seen = True
                continue  # el primer header ya esta en el YAML
            out.append("## " + " — ".join(payload))
            out.append("")
        else:
            for block in split_blocks(payload):
                if block_is_code(block):
                    out.append(render_code(block))
                else:
                    out.append(render_prose(block))
                out.append("")
    text = "\n".join(out).rstrip() + "\n"
    qmd = path.rsplit("/", 1)
    qmd_path = (qmd[0] + "/ejercicio.qmd") if len(qmd) == 2 else "ejercicio.qmd"
    with open(qmd_path, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"OK {qmd_path}")


if __name__ == "__main__":
    paths = sys.argv[1:]
    if not paths:
        paths = sorted(glob.glob(os.path.join("**", "ejercicio.R"),
                                 recursive=True))
        if not paths:
            sys.exit("No se encontro ningun ejercicio.R bajo la carpeta actual.")
    for p in paths:
        convert(p)
