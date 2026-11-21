# FICHA · EL TALLER (`taller.dantehef.dev`)

**Producto mantenido desde el `19-11-2026`:**
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

**⇒ LA REGLA DE PEDRO, y es la que manda aquí:** ***«toda publicación hay que verificarla en casa antes de publicar»*** **⇒ no se empuja nada que no haya pasado `salud.sh` en local primero. Y después de publicar, se verifica EN VIVO por otro camino (sha256 del fichero servido contra el fichero local), no por lo que diga GitHub.**

## ③ LAS TRES PIEZAS QUE LO MANTIENEN

| pieza | qué hace | cuándo |
|---|---|---|
| `salud.sh` | 8 comprobaciones: repo limpio y empujado · el `sitio/` corresponde a los `.md` (reconstruye en copia y compara byte a byte) · cada HTML con su `canonical`/`og`/JSON-LD · **cada página EN VIVO byte a byte igual a la local** · `sitemap.xml` con tantas URL como páginas · `robots.txt` · el espejo con `noindex` · días de certificado TLS | a mano, y antes de publicar (`--solo-local`) |
| `publica.sh "mensaje"` | construye · pasa `salud.sh --solo-local` · commit · push · **espera a que el dominio sirva exactamente lo local** · dice qué hacer si no | cada vez que hay algo nuevo |
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
- **El temporizador ya NO está aquí: está hecho** (`19-11-2026`, con su «sí»). Ver ⑨.
- **DECIDIDO el `19-11-2026`, palabra de Pedro: «déjala callada»** ⇒ el espejo se queda `noindex` y no compite con el dominio. No compite porque dos direcciones con el mismo texto hacen que Google elija una y reparta la fuerza entre las dos; su valor es ser **el repuesto** si el dominio fallara. Si algún día quiere que compita, es una línea (`marca_espejo`) y su palabra — pero hoy está decidido, y no se reabre solo.
- **La nota `07`:** hay material (el hilo del foro, el `truncate`, el banco de la ventana). Escribirla es mío; publicarla es suyo.

## ⑧ EL PRIMER FUEGO DE LAS PIEZAS, CON NÚMEROS (`19-11-2026`, 19:2x)

- **`salud.sh`** — primera pasada completa: **3,4 s**, 11 comprobaciones, el dominio sirve las 8 páginas + `sitemap` + `robots` **byte a byte iguales**, el espejo con `noindex`, y el certificado con **88 días**. El único fallo que dio fue el correcto: los ficheros que acababa de escribir estaban sin commitear.
- **`publica.sh`** — dos publicaciones de verdad, no de prueba: `6891be5` (las cuatro piezas) y la de esta corrección. Las dos pasaron la verificación en casa y el dominio coincidió en el primer sondeo. **Ninguna página del sitio cambió** — era el punto: empaquetar no toca el contenido.
- **`respaldo.sh`** — bundle de **1,7 MB** con la historia entera, verificado por `git bundle verify`, conteniendo el `HEAD`, y **restaurado de verdad**: `git clone` del bundle en una copia, `construye.py` y `diff -rq` contra el original **sin una sola diferencia**. La copia de prueba salió por `gio trash`.
- **`producto.sh estado`** — ahora el taller sale en el estado de la casa, y se ve arriba: `taller.dantehef.dev ARRIBA (web, http 200)` junto a `piel`, `path` y `mecatech`. **No se duerme con `congela`**: no ocupa VRAM ni puerto local; vive en Pages.

## ⑨ EL RELOJ DEL TALLER (hecho el `19-11-2026`, con el «sí» de Pedro)

**Un sitio web no se cae con un aviso: se cae en silencio. Por eso ahora tiene reloj propio, y es de usuario (no de la casa, no pide `sudo`):**

```
taller-web.timer    → cada día a las 08:10 (Persistent=true: si el equipo estaba apagado, lo hace al arrancar)
taller-web.service  → corre salud.sh entero y lo deja en el journal
```

- **Probado el `19-11` a las 19:37:** disparado a mano, **código 0 · 11 comprobaciones en verde**, y la última línea del journal dice «Finished taller-web.service».
- **Mirar lo que vio:** `journalctl --user -u taller-web.service -n 30`
- **Quitarlo:** `systemctl --user disable --now taller-web.timer`
- **Y su límite:** el reloj **no arregla nada solo**; avisa en el journal y deja la huella en `~/.imperio/logs/taller_web.log`. **La mano que repara es la mía, cuando abro turno y leo el registro. No se le promete a Pedro un aviso al móvil que este reloj no da.**

## ⑩ EL INCIDENTE DEL `19-11`, ESCRITO PARA QUE NO SE REPITA

**Lo que pasó, sin adorno:** en el mismo turno en que Pedro dictó la ley de las dos miradas, **empujé tres veces a `main` sin ellas** — `6891be5` y `27a5093` (el empaquetado, antes de saber la ley) y `4aa5a79` (una sección de esta ficha, **después** de saberla). La causa de la tercera no fue prisa: fue que **la puerta nueva vivía dentro del repo esperando revisión, y `main` seguía teniendo la puerta vieja** — así que al ir a proponer, la puerta vieja hizo lo suyo y publicó.

**Y el daño, medido y pequeño:** **el sitio no cambió ni un byte.** Las dos primeras fueron herramientas y la ficha; la tercera, un párrafo de la ficha. `sitio/` sigue igual que en `a36f405`, y `salud.sh` lo confirma con el sha256 del dominio. **Lo que se rompió fue el procedimiento, no el producto** — y aun así se apunta, porque un procedimiento que se salta tres veces en una tarde no es un descuido: es que estaba mal puesto.

**⇒ LA LECCIÓN, y es de diseño:** ***una puerta dentro de lo que custodia se puede saltar.*** **La puerta de dos tiempos vive ahora FUERA del repo**, en `~/scripts/taller.sh`, y el repo sólo guarda una copia que señala dónde está. Así no hay estado del repositorio que pueda reabrir la puerta vieja.

```
bash ~/scripts/taller.sh propone "mensaje"     ← rama + PR + vista previa. main no se toca.
bash ~/scripts/taller.sh cierra <PR> --visto "quien construye (...) + quien decide (...)"
```

---

*Ficha escrita el `19-11-2026`, con la decisión que la origina arriba y sin adornar. Se actualiza cuando cambia el producto, no cuando cambia el ánimo.*
