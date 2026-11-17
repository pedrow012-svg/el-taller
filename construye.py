#!/usr/bin/env python3
"""Convierte los articulos en markdown a un sitio estatico de HTML.

Sin dependencias salvo `markdown` de Python. Sin JavaScript. Sin fuentes externas.
Uso:  python3 construye.py
"""
import os
import re
import glob
import html
import markdown

AQUI = os.path.dirname(os.path.abspath(__file__))
ARTICULOS = os.path.join(AQUI, "articulos")
SITIO = os.path.join(AQUI, "sitio")
CSS = os.path.join(AQUI, "plantilla", "estilo.css")

PLANTILLA = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{titulo} · El Taller</title>
<meta name="description" content="{resumen}">
<style>{css}</style>
</head>
<body>
<main>
<header class="casa">
<p class="marca"><a href="index.html">El Taller</a></p>
<p class="lema">Medidas, pruebas y lo que se rompe.</p>
</header>
<article>
<h1>{titulo}</h1>
<p class="meta">{fecha}</p>
{cuerpo}
</article>
<footer>
<p>Todo lo que hay aquí se ha medido en una máquina concreta y se puede repetir. Cuando no se pudo medir,
se dice. Los números llevan su fecha y su comando.</p>
<p>Texto bajo <a href="https://creativecommons.org/licenses/by/4.0/deed.es">CC BY 4.0</a>.</p>
</footer>
</main>
</body>
</html>
"""

INDICE = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>El Taller · medidas, pruebas y lo que se rompe</title>
<meta name="description" content="Medidas reales de modelos de lenguaje en hardware de casa.">
<style>{css}</style>
</head>
<body>
<main>
<header class="casa">
<p class="marca">El Taller</p>
<p class="lema">Medidas, pruebas y lo que se rompe.</p>
</header>
<p>Todas las cifras de aquí salen de un banco de pruebas que se puede repetir. Si algo no se pudo medir, se dice.
Si un número salió mal, se corrige y se explica.</p>
<ul class="lista">
{lista}
</ul>
<footer>
<p>Texto bajo <a href="https://creativecommons.org/licenses/by/4.0/deed.es">CC BY 4.0</a>.</p>
</footer>
</main>
</body>
</html>
"""


def parte_cabecera(texto):
    """Separa `clave: valor` del principio del fichero. Devuelve (meta, cuerpo)."""
    meta, lineas = {}, texto.split("\n")
    i = 0
    for i, linea in enumerate(lineas):
        if not linea.strip():
            i += 1
            break
        if ":" in linea:
            clave, valor = linea.split(":", 1)
            meta[clave.strip().lower()] = valor.strip()
    return meta, "\n".join(lineas[i:]).strip()


def limpia_titulo(t):
    """El titulo lo escribo con *cursivas* para enfasis: en el HTML sobran."""
    return re.sub(r"[*_`]", "", t)


def main():
    os.makedirs(SITIO, exist_ok=True)
    css = open(CSS, encoding="utf-8").read()
    entradas = []

    for ruta in sorted(glob.glob(os.path.join(ARTICULOS, "*.md"))):
        crudo = open(ruta, encoding="utf-8").read()
        meta, cuerpo = parte_cabecera(crudo)
        titulo = meta.get("titulo") or os.path.basename(ruta).replace("-", " ").replace(".md", "")
        fecha = meta.get("fecha", "")
        resumen = meta.get("resumen", "")
        cuerpo_html = markdown.markdown(cuerpo, extensions=["tables", "fenced_code", "smarty"])

        nombre = os.path.basename(ruta).replace(".md", ".html")
        pagina = PLANTILLA.format(
            titulo=html.escape(limpia_titulo(titulo)),
            fecha=html.escape(fecha),
            resumen=html.escape(resumen),
            cuerpo=cuerpo_html,
            css=css,
        )
        with open(os.path.join(SITIO, nombre), "w", encoding="utf-8") as f:
            f.write(pagina)
        entradas.append((fecha, titulo, resumen, nombre))
        print(f"  ✅ {nombre}")

    entradas.sort(reverse=True)
    lista = "\n".join(
        f'<li><span class="fecha">{html.escape(f)}</span><br>'
        f'<a href="{n}">{html.escape(limpia_titulo(t))}</a>'
        f'<p class="resumen">{html.escape(r)}</p></li>'
        for f, t, r, n in entradas
    )
    with open(os.path.join(SITIO, "index.html"), "w", encoding="utf-8") as f:
        f.write(INDICE.format(css=css, lista=lista))
    print(f"  ✅ index.html ({len(entradas)} artículos)")

    # 17-11-2026 · El nombre propio del taller. GitHub Pages lee esto para saber
    # qué dominio sirve: si se pierde al reconstruir, el sitio vuelve a la dirección
    # fea de github.io y el certificado deja de aplicar.
    with open(os.path.join(SITIO, "CNAME"), "w", encoding="utf-8") as f:
        f.write("taller.dantehef.dev\n")
    print("  ✅ CNAME (taller.dantehef.dev)")


if __name__ == "__main__":
    main()
