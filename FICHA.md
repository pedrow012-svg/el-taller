# FICHA · EL TALLER (`taller.dantehef.dev`)

**Producto de 🎭 Orfeo, por palabra de Pedro del `19-11-2026`:**
> ***«Ok, la página web es tuya, como producto tuyo, la empaquetas como hacemos con los productos, la mantienes, actualizas, mejoras y reparas cuando falle, ¿te parece?»***

**⇒ Desde esa fecha, este sitio es un producto de la casa con dueño: lo mantengo, lo actualizo, lo mejoro y lo reparo. Lo que NO cambia: lo que se publica y lo que cuenta se decide con Pedro; el dominio, el dinero y la voz pública siguen siendo suyos.**

---

## ① QUÉ ES

El cuaderno público de la casa: **medidas, pruebas y lo que se rompe**, con el número, la fecha y el comando al lado. **Ningún número sin su fichero de resultados.** Lo que no se ha podido medir, se dice.

- **Vive en:** `~/Imperio_Escritos` (esto es todo el producto; no hay nada fuera salvo el respaldo y los registros).
- **Se ve en:** `https://taller.dantehef.dev` (GitHub Pages, repo `pedrow012-svg/el-taller`).
- **Espejo:** `github.com/pedrow012-svg/taller-nuevo` → `pedrow012-svg.github.io/taller-nuevo/`, **marcado `noindex` + `canonical` al dominio**. Una casa, una puerta: el dominio.
- **Tecnología:** `construye.py` (Python + `markdown`), HTML estático, **cero JavaScript, cero fuentes externas, cero dependencias de red en el navegador**.

## ② CÓMO SE CONSTRUYE Y SE PUBLICA

```
articulos/*.md  ──(construye.py)──▶  sitio/*.html + sitemap.xml + robots.txt + favicon.svg
                                            │
                                     (publica.sh)  ← la ceremonia, y no hay otra puerta
                                            ▼
                              commit → push a main → GitHub Pages → taller.dantehef.dev
```

**⇒ LAS DOS REGLAS DE PEDRO, y mandan las dos:**

1. ***«toda publicación hay que verificarla en casa antes de publicar»*** ⇒ no sale nada que no haya pasado `salud.sh` primero, y después de publicar se verifica **EN VIVO** por otro camino (sha256 de lo servido contra lo local), no por lo que diga GitHub.
2. ***«nada se publica sin que el otro cuerpo y yo lo veamos antes: en tu web y en GitHub»*** *(19-11-2026)* ⇒ **`main` no se toca sin las dos miradas.** La ceremonia tiene **dos tiempos y no hay un tercero:**

```
bash publica.sh propone "mensaje"   ← rama + PR + vista previa en 127.0.0.1:8097. NO publica.
        ↓  (miran 🔨 Hefesto y 👑 Pedro: en la vista previa y en el PR)
bash publica.sh cierra <PR> --visto "Hefesto (...) + Pedro (...)"
                                    ← fusiona, apaga la previa, y exige que el dominio sirva lo local
```

**Y el límite de esa ceremonia, escrito aquí y no escondido:** el guion **no puede comprobar que hayan mirado**; lo que hace es **negarse a publicar sin que alguien escriba el `--visto`**, y dejarlo grabado en el mensaje de la fusión y en el registro. La firma la pone una mano; el guion sólo se niega a saltársela.

## ③ LAS TRES PIEZAS QUE LO MANTIENEN

| pieza | qué hace | cuándo |
|---|---|---|
| `salud.sh` | 8 comprobaciones: repo limpio y empujado · el `sitio/` corresponde a los `.md` (reconstruye en copia y compara byte a byte) · cada HTML con su `canonical`/`og`/JSON-LD · **cada página EN VIVO byte a byte igual a la local** · `sitemap.xml` con tantas URL como páginas · `robots.txt` · el espejo con `noindex` · días de certificado TLS | a mano, y antes de publicar (`--solo-local`) |
| `publica.sh propone` | construye · verifica en casa · **rama + PR (main intacto)** · levanta la vista previa en `127.0.0.1:8097` | cuando hay algo que enseñar |
| `publica.sh cierra` | **fusiona con las dos miradas** (`--visto`) · apaga la previa · **espera a que el dominio sirva exactamente lo local** | cuando Hefesto y Pedro han dicho que sí |
| `respaldo.sh` | `git bundle` verificado (`git bundle verify`) a `~/.imperio/backups/taller_web/`, guarda los 6 últimos, y comprueba que el remoto tiene todo | cada semana y antes de un cambio gordo |

**Registro de todo:** `~/.imperio/logs/taller_web.log`.

## ④ DE QUÉ RESPONDO Y DE QUÉ NO

**Es mío:** que el sitio se construya, se publique, se verifique, no se rompa, cargue rápido, se lea bien, tenga su SEO correcto, su `sitemap` y su `robots`, y que cada pieza tenga su copia y su registro. **Y que cuando falle, lo arreglo yo.**

**NO es mío, y se pregunta:** qué artículo se escribe y qué se cuenta en él · qué se publica y cuándo (contenido y voz pública) · el dominio y el dinero · a quién se le enseña · los tokens y credenciales de GitHub.

## ⑤ ESTADO MEDIDO (19-11-2026, 19:3x)

- **8 páginas** en `sitemap.xml` · **6 artículos** publicados · índice con 6 tarjetas + `temas.html`.
- **El `HEAD` no se apunta aquí a propósito:** cambia con cada publicación y este papel se quedaría mintiendo. **Quien dice la verdad es `bash salud.sh`**, que compara el dominio con lo de casa.
- En vivo: la portada y los 8 HTML **byte a byte iguales** a los locales (`curl` + `sha256`), `200`.
- Google Search Console: propiedad verificada (etiqueta HTML en `dbbc216`), `sitemap.xml` **«CORRECTO · 7 páginas descubiertas»** (el 8º es la nota 06, posterior al envío).
- Espejo: `200`, `noindex, follow` + `canonical` al dominio, Pages rehecho por mí tras el apagón del `19-11`.

## ⑥ SI SE CAE — EL GUION DE REPARACIÓN

1. `bash salud.sh` → dice **qué** falla: repo, construcción, vivo, espejo o TLS.
2. **Si el dominio no responde:** `gh api repos/pedrow012-svg/el-taller/pages` y `gh run list --limit 3` dicen si Pages está encendido y si el último despliegue falló. Para reencender: `gh api -X POST repos/pedrow012-svg/el-taller/pages -f build_type=workflow`.
3. **Si el dominio sirve algo viejo:** es la caché de Pages; se fuerza reconstruyendo y empujando un commit vacío (`git commit --allow-empty`).
4. **Si el `sitio/` no corresponde a los `.md`:** `python3 construye.py` y volver a publicar. `salud.sh` lo detecta antes que nadie porque reconstruye en copia.
5. **Si me he equivocado publicando:** `git revert <commit>` (nunca `reset --hard` sobre algo ya publicado) y se vuelve a publicar; el historial queda, que es lo honesto.
6. **Si el repo desapareciera:** `git clone ~/.imperio/backups/taller_web/taller_<fecha>.bundle taller_restaurado` — el bundle trae la historia entera.

## ⑦ LO QUE ESTÁ ABIERTO, Y ES DE PEDRO

- **`IndexNow`** (Bing/Yandex): avisar a los buscadores de las páginas nuevas. No necesita cuenta ni dinero; sí su «sí» porque manda datos a terceros.
- **El enlace del espejo:** hoy está `noindex`. Si algún día quiere que el espejo también compita, es una línea (`marca_espejo`) y su palabra.
- **La nota `07`:** hay material (el hilo del foro, el `truncate`, el banco de la ventana). Escribirla es mío; publicarla es suyo.

## ⑧ EL PRIMER FUEGO DE LAS PIEZAS, CON NÚMEROS (`19-11-2026`, 19:2x)

- **`salud.sh`** — primera pasada completa: **3,4 s**, 11 comprobaciones, el dominio sirve las 8 páginas + `sitemap` + `robots` **byte a byte iguales**, el espejo con `noindex`, y el certificado con **88 días**. El único fallo que dio fue el correcto: los ficheros que acababa de escribir estaban sin commitear.
- **`publica.sh`** — dos publicaciones de verdad, no de prueba: `6891be5` (las cuatro piezas) y la de esta corrección. Las dos pasaron la verificación en casa y el dominio coincidió en el primer sondeo. **Ninguna página del sitio cambió** — era el punto: empaquetar no toca el contenido.
- **`respaldo.sh`** — bundle de **1,7 MB** con la historia entera, verificado por `git bundle verify`, conteniendo el `HEAD`, y **restaurado de verdad**: `git clone` del bundle en una copia, `construye.py` y `diff -rq` contra el original **sin una sola diferencia**. La copia de prueba salió por `gio trash`.
- **`producto.sh estado`** — ahora el taller sale en el estado de la casa, y se ve arriba: `taller.dantehef.dev ARRIBA (web, http 200)` junto a `piel`, `path` y `mecatech`. **No se duerme con `congela`**: no ocupa VRAM ni puerto local; vive en Pages.

---

*Ficha escrita y firmada por 🎭 Orfeo el `19-11-2026`, con la palabra de Pedro que la origina, arriba y sin adornar. Se actualiza cuando cambia el producto, no cuando cambia el ánimo.*
