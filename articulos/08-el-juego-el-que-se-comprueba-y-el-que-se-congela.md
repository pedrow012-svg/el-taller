titulo: El mismo juego, dos modelos: la diferencia no fue el tamaño, fue que uno se comprueba antes de entregar
fecha: 2026-11-27
resumen: Pedimos a dos modelos locales que escribieran un juego, y el que juzgó si se podía jugar fue una persona con las manos, no un banco. Uno entregó un arcade que funciona; el otro, algo que se congela solo. La causa está en una línea de código, y la misma historia se repitió después con tres tareas medidas dieciocho veces.
tema: medidas

Hay una cosa que ningún banco de pruebas puede juzgar: **si un juego se puede jugar**. Se puede comprobar que el fichero existe, que el JavaScript no tiene errores de sintaxis, que responde. Nada de eso dice si el personaje corre o si la nave se queda clavada en el aire.

Así que la prueba fue esta: **se le pidió a un modelo local que escribiera un juego, y quien decidió si servía fue la persona que lo jugó.** Con las manos y sin mirar el código antes. Ese veredicto es el único de esta historia que no lo firma ninguna herramienta.

Este artículo cuenta qué pasó, qué se midió después para no quedarse en la anécdota, y qué es lo que **no** se puede concluir de aquí.

## Los dos juegos

Mismo encargo, dos motores distintos, la misma máquina:

| | `Qwen3.8-27B QUASAR` (4 bits) | `qwen2.5:14b` |
|---|---|---|
| lo que entregó | `11.101` bytes, `444` líneas | `6.003` bytes, `186` líneas |
| ¿su código compila? | sí (`node --check`) | sí (`node --check`) |
| cómo late el bucle | `requestAnimationFrame` | `setTimeout(gameLoop, 20)` |
| delta de tiempo | `performance.now()`, `dt = t - ultimoTiempo` | **ninguno** |
| y además | `if (dt > 100) dt = 100;` — *«evita saltos grandes al volver a la pestaña»* | nada |

El veredicto, tal como se dictó después de jugar los dos, sin haber leído una línea:

> **«Defensa orbital se juega muy bien, el defensor corre rápido y dispara bien; el otro se pega, es lento y se queda congelado. El juego del `27B` es muy bueno»**

(Dictado en voz alta: el dictado escribió «se paga», y es **«se pega»**. Lo corrigió él al leer este artículo antes de publicarlo, y va la corrección dentro porque el fallo no fue suyo, fue del oído de la máquina que transcribió.)

Y la causa no es una opinión: **está en cómo late el bucle.**

**`setTimeout(gameLoop, 20)` no es un reloj.** Es «avísame dentro de 20 ms», y el navegador puede tardar más. Y como la siguiente vuelta se pide **después** de hacer el trabajo, el retraso **se va sumando**: el juego se va frenando solo. A los pocos segundos, la nave se mueve a tirones y luego se para.

**Y sin delta de tiempo, todo se mueve «por fotograma».** Si el navegador da menos vueltas, el juego va más lento. **La velocidad del juego pasa a depender de la máquina y no del juego.**

`requestAnimationFrame` es lo contrario: el navegador llama **cuando toca pintar** —unas sesenta veces por segundo, más en pantallas rápidas— y con `dt` el movimiento es el mismo en cualquier máquina. El tope de `100` ms es el detalle que remata: si vuelves a la pestaña después de un rato, el personaje no aparece al otro lado de la pantalla.

**Un modelo escribió un juego que aguanta que lo dejes y vuelvas. El otro escribió uno que se congela en la primera partida.** Y a los dos su código les pasa la comprobación de sintaxis: `node --check` da por bueno el del `27B` (`8.821` bytes de JavaScript) y el del `14B` (`5.574`). **La sintaxis no distingue un juego de un cartel.**

## Para no quedarse en la anécdota: el banco 3×3

Una anécdota no vale nada. Esa misma madrugada se montó un banco con **tres tareas, tres pasadas y los dos motores**: dieciocho pasadas, de `00:01:45` a `00:11:40`, **en casa y con cero tokens de nube**.

| Tarea | Criterio de PASS, comprobado por el banco |
|---|---|
| **A · crear un juego** | existe `juego.html` y el JavaScript pasa `node --check` |
| **B · calcular cinco cifras** | las cinco coinciden con las que calcula el banco |
| **C · arreglar un fallo** | `test_suma.py` en verde sin que el modelo lo toque |

Y quién decide PASS o FAIL es **el banco**, no el modelo.

| motor | PASS | FAIL | herramientas mal | se comprobó a sí mismo |
|---|---:|---:|---:|---|
| `Qwen3.8-27B` | **9** | **0** | **0** | **9 de 9** |
| `qwen2.5:14b` | 8 | **1** | 3 | 5 de 9 |

El único FAIL de las dieciocho pasadas fue del `14B`: en la tarea A, pasada 2, **no entregó el fichero**.

| tarea | 27B, segundos p1·p2·p3 · mediana | 14B, segundos p1·p2·p3 · mediana |
|---|---|---|
| A · crear un juego | `55 · 54 · 55` · **`54,6`** | `794 · 34 · 46` · **`45,6`** |
| B · cinco cifras | `6 · 8 · 8` · **`8,0`** | `65 · 44 · 66` · **`65,1`** |
| C · arreglar el fallo | `6 · 5 · 6` · **`5,7`** | `28 · 17 · 28` · **`27,6`** |

Y por qué va la mediana y no la media, que es lo que casi se publica mal: con tres pasadas, la media esconde justo lo que hay que ver. `794 · 34 · 46` da una media de `291` segundos y una mediana de `45,6`. **La media cuenta la irregularidad como lentitud; la mediana la esconde.** Por eso van las tres cifras, una por una, y cada quien saque la suya.

## La forma de lo entregado, que el banco no juzga

Aquí está la parte que la palabra PASS no cuenta. En la tarea larga, lo que entregó cada motor:

| motor | pasada | bytes | líneas | canvas | teclas | bucle | puntos |
|---|---|---:|---:|---:|---:|---:|---:|
| `27B` | 1 | 11.280 | 487 | 1 | 2 | 1 | 20 |
| `27B` | 2 | 11.076 | 445 | 1 | 2 | 2 | 9 |
| `27B` | 3 | 11.739 | 453 | 1 | 2 | 1 | 15 |
| `14B` | 1 | 7.781 | 221 | 1 | 1 | 1 | 8 |
| `14B` | 2 | — | — | — | — | — | — |
| `14B` | 3 | **2.086** | **1** | 1 | 1 | 2 | **4** |

Un fichero de dos kilobytes escrito en **una línea** salió **PASS**: el JavaScript no tenía errores de sintaxis. Por eso la tabla está aquí, al lado. **PASS significa que el fichero existe y compila, no que el juego exista.**

## Lo que este banco **no** puede decir

- **No mide si el juego es bonito ni si se puede jugar.** Eso lo hizo una persona, con las manos, y no se puede repetir con un script.
- **Nueve pasadas se apartaron, no se borraron.** Devolvieron `503` porque el `14B` seguía ocupando `23,4` GiB de tarjeta y el `27B` no tenía sitio para cargarse. **No eran fallos de los modelos: eran fallos del banco.** Están guardadas aparte y se dicen aquí.
- **La tarea A es declaradamente floja.** Comprueba que el fichero existe y que su sintaxis es válida, y nada más. Las tareas B y C son prueba dura: la verdad la calcula el banco y las pruebas las corre el banco.
- **No es un ranking de modelos.** Son dos motores, una máquina y tres pasadas. Con otro `quant`, otra tarjeta o más pasadas, los números se moverían. **Lo que se puede afirmar es lo que se midió, con estas versiones y este día.**

## Y lo que sí se puede decir sin exagerar

**El modelo pequeño no es tonto.** En las tareas cortas acertó las tres: **sabe lo breve**. Donde se hunde es en lo largo: entregó un fichero de una línea, o ninguno, o uno que se congela.

**La diferencia entre estos dos no fue el tamaño: fue que uno se lee antes de firmar.** El `27B` se comprobó las nueve veces, y su tercera comprobación en la tarea del juego no fue de sintaxis sino **de comportamiento**: simuló el vuelo de la bala hasta el impacto. De ahí salió un bucle que aguanta que lo dejes y vuelvas. **Un modelo que se comprueba entrega algo que se puede jugar; uno que no, entrega algo que compila.**

Eso no lo dice ninguna tabla de `PASS`. Lo dijo una persona jugando dos veces.
