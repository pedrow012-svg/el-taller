# El Taller — escritos de la casa

**Medidas, pruebas y lo que se rompe.** Lo que se publica aquí ha pasado por un banco, tiene su fichero de
resultados y se puede repetir. Lo que no se ha podido medir, se dice.

Se lee en **[taller.dantehef.dev](https://taller.dantehef.dev)**.

---

## Las notas, una a una

| nº | nota (fuente) | fecha | publicada |
|---|---|---|---|
| 01 | [Ollama tira media ventana de contexto cuando trunca, y no dice cuánto tiró](articulos/01-ollama-truncado-silencioso.md) | 2026-11-19 | [`01-ollama-truncado-silencioso.html`](https://taller.dantehef.dev/01-ollama-truncado-silencioso.html) |
| 02 | [Apagar el razonamiento cuesta 12 aciertos, no te hace más rápido, y nadie te avisa](articulos/02-razonamiento-apagado.md) | 2026-11-17 | [`02-razonamiento-apagado.html`](https://taller.dantehef.dev/02-razonamiento-apagado.html) |
| 03 | [El modelo que dimos por malo era el mejor. Lo medí con la bandera equivocada](articulos/03-el-mejor-modelo-que-tiramos.md) | 2026-11-17 | [`03-el-mejor-modelo-que-tiramos.html`](https://taller.dantehef.dev/03-el-mejor-modelo-que-tiramos.html) |
| 04 | [El archivo de lo común existe. Y el modelo distingue mucho peor un eccema que un tumor](articulos/04-archivo-de-lo-comun.md) | 2026-11-17 | [`04-archivo-de-lo-comun.html`](https://taller.dantehef.dev/04-archivo-de-lo-comun.html) |
| 05 | [El parche que arregla dos casos y estropea otros dos: leer el razonamiento como si fuera la respuesta](articulos/05-el-parche-que-arregla-dos-y-estropea-dos.md) | 2026-11-19 | [`05-el-parche-que-arregla-dos-y-estropea-dos.html`](https://taller.dantehef.dev/05-el-parche-que-arregla-dos-y-estropea-dos.html) |
| 06 | [Hubo un hilo, y nos corrigieron dos veces](articulos/06-hubo-un-hilo-y-nos-corrigieron.md) | 2026-11-19 | [`06-hubo-un-hilo-y-nos-corrigieron.html`](https://taller.dantehef.dev/06-hubo-un-hilo-y-nos-corrigieron.html) |

**La fuente manda:** el `.md` de `articulos/` es el texto; el `.html` de `sitio/` es lo que se construye de él
y lo que se sirve. Si los dos no coinciden, `salud.sh` lo dice.

---

## Cómo se construye

```sh
python3 construye.py
```

Escribe en `sitio/`: un índice y un HTML por artículo. **Sin dependencias salvo `markdown` de Python**, sin
JavaScript, sin fuentes externas. Si mañana esto se cae, se levanta con un comando.

## Cómo se escribe una nota

Un fichero `.md` en `articulos/`, con una cabecera mínima:

```
titulo: Lo que has medido, en una frase
fecha: 2026-11-19
resumen: Una línea para el índice.
```

Y luego el texto. **Regla de la casa:** ningún número sin su fichero de resultados, su fecha y su comando.

## Cómo se publica — y aquí no hay atajos

**Regla del proyecto (`19-11-2026`):** ***nada se publica sin que lo hayan visto antes dos personas distintas — quien construye no se aprueba a sí mismo. La revisión se hace en la vista previa y en GitHub.***

```sh
bash taller.sh propone "mensaje"      # rama + PR + vista previa. main NO se toca.
bash taller.sh cierra <PR> --visto "quien construye (...) + quien decide (...)"
```

**La puerta vive fuera del repo, a propósito:** una puerta dentro de lo que custodia
se puede saltar. La copia `publica.sh` de este repo sólo dice dónde está la buena.

## Las piezas que lo mantienen

- `salud.sh` — 11 comprobaciones: repo, que el `sitio/` corresponda a los `.md` (reconstruye en copia y compara
  byte a byte), cada página **en vivo** con el mismo sha256 que la local, `sitemap`, `robots`, el `noindex` del
  espejo y los días de TLS.
- `respaldo.sh` — `git bundle` verificado por git y **probado restaurándolo**, a la carpeta de respaldos del taller.
- `taller-web.timer` — cada mañana a las 08:10 corre `salud.sh` y lo deja en el journal.

**La ficha entera, con lo que es mío y lo que no:** [`FICHA.md`](FICHA.md).

---

*Producto mantenido desde el `19-11-2026`. Lo que se cuenta en cada nota y lo que se
publica se decide con él; la máquina que lo sostiene es mía.*
