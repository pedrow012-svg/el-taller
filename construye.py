#!/usr/bin/env python3
"""Convierte los articulos en markdown a un sitio estatico de HTML.

Sin dependencias salvo `markdown` de Python. Sin JavaScript. Sin fuentes externas.
Uso:  python3 construye.py
"""
import html
import os
import glob
import re
import markdown

AQUI = os.path.dirname(os.path.abspath(__file__))
ARTICULOS = os.path.join(AQUI, "articulos")
SITIO = os.path.join(AQUI, "sitio")
CSS = os.path.join(AQUI, "plantilla", "estilo.css")
ENTRADA = os.path.join(AQUI, "plantilla", "entrada.html")
INDEXNOW_CLAVE = "ef712d55bfa6505f1a85ce7d9ef26244"   # clave de IndexNow (indexnow.org, 20-11-2026)
BASE = "https://taller.dantehef.dev"

# El sello de la pestaña del navegador: el mismo ET del encabezado, en SVG
# (1 KB, sin fuentes, nítido en cualquier pantalla).
FAVICON = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
<rect width="32" height="32" rx="8" fill="#0a0a0a"/>
<rect x="1.5" y="1.5" width="29" height="29" rx="7" fill="none" stroke="#00f2ff" stroke-width="1.2" opacity=".55"/>
<text x="16" y="22" font-family="ui-monospace,Menlo,Consolas,monospace" font-size="14"
 font-weight="700" fill="#00f2ff" text-anchor="middle">ET</text>
</svg>
"""


def cabeza(titulo, descripcion, ruta, imagen=True, tipo="website", fecha="", jsonld=""):
    """Todo lo que le dice a un buscador qué es esta página y dónde está.

    Sin esto Google puede indexar, pero nadie le ha dicho el nombre propio del
    sitio ni cuál es la dirección buena: la canónica evita que el dominio y
    github.io se peleen por la misma página.
    """
    import json
    url = BASE + "/" + ruta
    og_img = BASE + "/img/portada-ia.jpg"
    etiquetas = [
        '<link rel="canonical" href="%s">' % url,
        '<meta name="theme-color" content="#0a0a0a">',
        '<link rel="icon" href="/favicon.svg" type="image/svg+xml">',
        '<meta property="og:site_name" content="El Taller">',
        '<meta property="og:locale" content="es_ES">',
        '<meta property="og:url" content="%s">' % url,
        '<meta name="twitter:card" content="summary_large_image">',
    ]
    if imagen:
        etiquetas += ['<meta property="og:image" content="%s">' % og_img,
                      '<meta name="twitter:image" content="%s">' % og_img]
    if jsonld:
        etiquetas.append('<script type="application/ld+json">%s</script>'
                         % json.dumps(jsonld, ensure_ascii=False))
    return "\n".join(etiquetas)

SELLO = """<svg viewBox="0 0 32 32" width="26" height="26" aria-hidden="true"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#e0a458"/><stop offset="1" stop-color="#b45309"/></linearGradient></defs><rect width="32" height="32" rx="8" fill="url(#g)"/><path d="M8 22V10h3v9h5v3H8zm9 0V10h7v3h-4v9h-3z" fill="#fff"/></svg>"""

CABECERA = """<header class="casa">
<p class="marca">{sello}<a href="temas.html">El Taller</a></p>
<p class="lema"><a href="index.html">Portada</a> · <strong>medido en casa</strong>, cifras con fecha y comando</p>
</header>"""

PIE = """<footer>
<p>Todo lo que hay aquí se ha medido en una máquina concreta y se puede repetir. Cuando no se pudo medir,
se dice. Los números llevan su fecha y su comando.</p>
<p>Texto bajo <a href="https://creativecommons.org/licenses/by/4.0/deed.es">CC BY 4.0</a>.</p>
<p class="sello-pie">El Taller · taller.dantehef.dev</p>
</footer>"""
# ── La ventana de preguntas. Es un chat DE VERDAD a medias: el aspecto es de chat,
# pero detrás no hay servidor; el formulario abre el correo de quien escribe.
# Se dice así en la propia ventana, que es la única forma honesta de hacerlo.
CHAT = """<section class="chat" aria-label="Preguntas y opiniones">
<div class="barra"><span class="luz" aria-hidden="true"></span>Preguntas y opiniones</div>
<div class="cuerpo">
<div class="burbuja ellos">Aquí se puede preguntar lo que quieras de un artículo: por qué un número salió así,
qué máquina era, o qué crees que medimos mal. Si la pregunta tiene respuesta medida, se contesta con la cifra y el comando.</div>
<div class="burbuja yo">¿Y si quiero que se repita una prueba con otro modelo?</div>
<div class="burbuja ellos">Se pide y se prueba, si la máquina está libre. Lo que no se hace es prometer un número antes de medirlo.</div>
</div>
<form action="mailto:pedrow012@gmail.com" method="post" enctype="text/plain">
<input type="text" name="pregunta" placeholder="Escribe tu pregunta…" aria-label="Tu pregunta" required>
<button type="submit">Enviar</button>
</form>
<p class="nota">El botón abre tu programa de correo con la pregunta escrita: aquí no hay servidor ni cuentas,
y por eso no se finge una conversación en vivo. <a href="https://github.com/pedrow012-svg/el-taller/issues">También se puede dejar en el registro público del taller.</a></p>
</section>"""


PLANTILLA = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="google-site-verification" content="STZHGIxNZcrQlTB4OGM90fCpiz5AYfo35sD9MkqIc1Q">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{titulo} · El Taller</title>
<meta name="description" content="{resumen}">
<meta property="og:title" content="{titulo}">
<meta property="og:description" content="{resumen}">
<meta property="og:type" content="article">
{cabeza}
<style>{css}</style>
</head>
<body>
<div class="progreso" aria-hidden="true"></div>
{cabecera}
<main>
<article>
<p class="cejilla"><span class="tema">{tema}</span><span>{fecha}</span><span>{minutos} min de lectura</span></p>
<h1>{titulo}</h1>
<p class="entradilla">{resumen}</p>
{cuerpo}
</article>
{vecinos}
{pie}
</main>
</body>
</html>
"""

PORTADA = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="google-site-verification" content="STZHGIxNZcrQlTB4OGM90fCpiz5AYfo35sD9MkqIc1Q">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Temas · El Taller</title>
<meta name="description" content="Medidas reales de modelos de lenguaje en hardware de casa.">
<meta property="og:title" content="Temas · El Taller">
<meta property="og:description" content="Medidas reales de modelos de lenguaje en hardware de casa.">
{cabeza}
<style>{css}</style>
</head>
<body>
{cabecera}
<main class="ancho">
<section class="portada">
<p class="ojo">Cuaderno de medidas</p>
<h1>Lo que se mide, se puede repetir.</h1>
<p class="entrada">Pruebas de modelos de lenguaje en una máquina de casa: cifras con fecha, el comando que
las sacó, y lo que se rompió por el camino. Cuando algo no se pudo medir, aquí se dice.</p>
<ul class="datos">
<li>{cuantos} artículos</li>
<li>dos tarjetas de 16 GB · 62 GB de RAM</li>
<li>sin patrocinio</li>
</ul>
</section>
<ul class="rejilla">
{lista}
</ul>
{chat}
{pie}
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


def minutos_de(texto):
    """Palabras / 220, redondeado hacia arriba y con un mínimo de 1."""
    palabras = len(re.findall(r"\w+", texto))
    return max(1, round(palabras / 220))


def envuelve_tablas(cuerpo_html):
    """Mete cada <table> en un contenedor que se puede desplazar en el móvil."""
    return (cuerpo_html.replace("<table>", '<div class="tabla"><table>')
            .replace("</table>", "</table></div>"))


def main():
    os.makedirs(SITIO, exist_ok=True)
    css = open(CSS, encoding="utf-8").read()
    entradas = []

    for ruta in sorted(glob.glob(os.path.join(ARTICULOS, "*.md"))):
        crudo = open(ruta, encoding="utf-8").read()
        meta, cuerpo = parte_cabecera(crudo)
        titulo = meta.get("titulo") or os.path.basename(ruta).replace("-", " ").replace(".md", "")
        entradas.append({
            "fecha": meta.get("fecha", ""),
            "titulo": titulo,
            "resumen": meta.get("resumen", ""),
            "tema": meta.get("tema", "medidas"),
            "nombre": os.path.basename(ruta).replace(".md", ".html"),
            "minutos": minutos_de(cuerpo),
            "cuerpo": cuerpo,
        })

    # Fecha descendente; y entre los del mismo día, el número del fichero descendente
    # (el último que se escribió arriba). Sin esto, tres artículos publicados el mismo
    # día se ordenaban alfabéticamente y el «último» salía detrás de los otros dos.
    entradas.sort(key=lambda e: (e["fecha"], e["nombre"]), reverse=True)

    # ── cada artículo, con sus vecinos (el anterior y el siguiente en el tiempo) ──
    for i, e in enumerate(entradas):
        vecinos = ['<nav class="vecinos">']
        if i + 1 < len(entradas):
            v = entradas[i + 1]
            vecinos.append('<a href="%s"><span class="rotulo">Anterior</span>%s</a>'
                           % (v["nombre"], html.escape(limpia_titulo(v["titulo"]))))
        if i > 0:
            v = entradas[i - 1]
            vecinos.append('<a href="%s" style="text-align:right">'
                           '<span class="rotulo">Siguiente</span>%s</a>'
                           % (v["nombre"], html.escape(limpia_titulo(v["titulo"]))))
        vecinos.append("</nav>")

        cuerpo_html = envuelve_tablas(
            markdown.markdown(e["cuerpo"], extensions=["tables", "fenced_code", "smarty"]))

        jsonld = {
            "@context": "https://schema.org",
            "@type": "BlogPosting",
            "headline": limpia_titulo(e["titulo"]),
            "description": e["resumen"],
            "url": "%s/%s" % (BASE, e["nombre"]),
            "mainEntityOfPage": "%s/%s" % (BASE, e["nombre"]),
            "datePublished": e["fecha"],
            "dateModified": e["fecha"],
            "inLanguage": "es",
            "image": "%s/img/portada-ia.jpg" % BASE,
            "author": {"@type": "Person", "name": "Pedro", "url": BASE},
            "publisher": {"@type": "Organization", "name": "El Taller", "url": BASE},
            "keywords": e["tema"],
        }
        pagina = PLANTILLA.format(
            titulo=html.escape(limpia_titulo(e["titulo"])),
            cabeza=cabeza(limpia_titulo(e["titulo"]), e["resumen"], e["nombre"],
                          tipo="article", fecha=e["fecha"], jsonld=jsonld),
            fecha=html.escape(e["fecha"]),
            resumen=html.escape(e["resumen"]),
            tema=html.escape(e["tema"]),
            minutos=e["minutos"],
            cuerpo=cuerpo_html,
            cabecera=CABECERA.format(sello=SELLO),
            vecinos="\n".join(vecinos),
            pie=PIE,
            css=css,
        )
        with open(os.path.join(SITIO, e["nombre"]), "w", encoding="utf-8") as f:
            f.write(pagina)
        print("  ✅ %s" % e["nombre"])

    lista = "\n".join(
        '<li class="tarjeta">'
        '<span class="num">%s</span>'
        '<h2><a href="%s">%s</a></h2>'
        '<p class="resumen">%s</p>'
        '<p class="pie"><span>%s</span><span>%d min</span></p>'
        '</li>' % (e["nombre"][:2], e["nombre"],
                   html.escape(limpia_titulo(e["titulo"])), html.escape(e["resumen"]),
                   html.escape(e["fecha"]), e["minutos"])
        for i, e in enumerate(entradas))

    jsonld_indice = {
        "@context": "https://schema.org",
        "@type": "Blog",
        "name": "El Taller",
        "url": BASE + "/temas.html",
        "inLanguage": "es",
        "description": "Pruebas de modelos de lenguaje sobre máquina casera. Datos públicos y contrastables.",
        "blogPost": [{"@type": "BlogPosting", "headline": limpia_titulo(e["titulo"]),
                      "url": "%s/%s" % (BASE, e["nombre"]), "datePublished": e["fecha"]}
                     for e in entradas],
    }
    with open(os.path.join(SITIO, "temas.html"), "w", encoding="utf-8") as f:
        f.write(PORTADA.format(css=css, lista=lista, cuantos=len(entradas),
                               cabeza=cabeza("Temas", "Medidas reales de modelos de lenguaje "
                                             "en hardware de casa.", "temas.html",
                                             jsonld=jsonld_indice),
                               cabecera=CABECERA.format(sello=SELLO), pie=PIE,
                               chat=CHAT.format(cuantos=len(entradas))))
    print("  ✅ temas.html (%d artículos)" % len(entradas))

    # ── la entrada: una sola pantalla, la que se ve al llegar ──
    with open(ENTRADA, encoding="utf-8") as f:
        entrada = f.read().replace("{cuantos}", str(len(entradas)))
    with open(os.path.join(SITIO, "index.html"), "w", encoding="utf-8") as f:
        f.write(entrada)
    print("  ✅ index.html (la entrada)")

    # 17-11-2026 · El nombre propio del taller. GitHub Pages lee esto para saber
    # qué dominio sirve: si se pierde al reconstruir, el sitio vuelve a la dirección
    # fea de github.io y el certificado deja de aplicar.
    with open(os.path.join(SITIO, "CNAME"), "w", encoding="utf-8") as f:
        f.write("taller.dantehef.dev\n")
    print("  ✅ CNAME (taller.dantehef.dev)")

    # ── lo que un buscador necesita para encontrar y ordenar el sitio ──
    with open(os.path.join(SITIO, "robots.txt"), "w", encoding="utf-8") as f:
        f.write("User-agent: *\nAllow: /\n\nSitemap: %s/sitemap.xml\n" % BASE)
    print("  ✅ robots.txt")

    hoy = max((e["fecha"] for e in entradas if e["fecha"]), default="")
    urls = [("", hoy, "1.0", "weekly"), ("temas.html", hoy, "0.9", "weekly")]
    urls += [(e["nombre"], e["fecha"], "0.8", "monthly") for e in entradas]
    cuerpo_sitemap = "\n".join(
        "  <url><loc>%s/%s</loc><lastmod>%s</lastmod>"
        "<changefreq>%s</changefreq><priority>%s</priority></url>"
        % (BASE, r, f, c, p) for r, f, p, c in urls if f)
    with open(os.path.join(SITIO, "sitemap.xml"), "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n'
                '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n%s\n</urlset>\n'
                % cuerpo_sitemap)
    print("  ✅ sitemap.xml (%d URLs)" % len(urls))

    # 20-11-2026 · LA CLAVE DE INDEXNOW. Un fichero de texto en la raiz con una cadena
    # aleatoria: es la prueba de que el sitio es nuestro cuando avisamos a Bing y Yandex
    # de que hay URLs nuevas. Sin este fichero el aviso se rechaza. No sirve para nada
    # mas, no se lee, no se enlaza: existe solo para que ellos puedan comprobarlo.
    with open(os.path.join(SITIO, INDEXNOW_CLAVE + ".txt"), "w", encoding="utf-8") as f:
        f.write(INDEXNOW_CLAVE + chr(10))
    print("  \u2705 " + INDEXNOW_CLAVE + ".txt (la clave de IndexNow)")

    with open(os.path.join(SITIO, "favicon.svg"), "w", encoding="utf-8") as f:
        f.write(FAVICON)
    print("  ✅ favicon.svg")


if __name__ == "__main__":
    main()
