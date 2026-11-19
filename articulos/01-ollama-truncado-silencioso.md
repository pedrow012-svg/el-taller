titulo: Ollama te deja media ventana de contexto y no te dice cuál es la otra mitad
fecha: 2026-11-19
resumen: Cuatro combinaciones de versión y configuración, y las cuatro dan el mismo número. El presupuesto del prompt es la mitad de la ventana, el recorte se lleva el PRINCIPIO del documento, y en la puerta nativa no avisa ni en la última versión.

Voy a empezar por lo que más duele, porque el truncado no es la parte grave.

Le dimos a un modelo un documento largo y contestó:

> «He leído la Mesa, el Taller, los pendientes abiertos…»

**No los había leído.** El servidor le había entregado media ventana de texto y no se lo dijo a nadie. Ni a él ni a mí.

## La medición, que cabe en una tabla

Mismo documento, misma pregunta, misma máquina. Lo único que cambia es la versión de Ollama y el tamaño de contexto. Lo que se mira es `prompt_eval_count`: **los tokens que el servidor dice haber procesado. Ese número no puede mentir, porque lo cuenta él.**

Documento de `300.000` caracteres, modelo `qwen2.5:3b`, por la puerta nativa (`/api/chat`):

| versión | contexto pedido | leyó | ¿avisó? | qué pasó |
|---|---|---|---|---|
| `0.34.1` | por defecto | **16.386** | **no** | se quedó con el FINAL |
| `0.34.1` | `32.768` | **16.386** | **no** | se quedó con el FINAL |
| `0.40.16` | por defecto | **16.386** | **no** | se quedó con el FINAL |
| `0.40.16` | `32.768` | **16.386** | **no** | se quedó con el FINAL |

**Cuatro combinaciones. El mismo número. Y ninguna avisa.**

**Y doblar el documento no lo mueve ni un token.** Eso no es un modelo que se queda corto: **es un servidor que recorta.**

## La regla que hay detrás: te dan la MITAD

Aquí está lo que convierte una anécdota en algo que te puede pasar esta tarde. **El presupuesto del prompt no es la ventana: es la mitad de la ventana.**

| contexto configurado | lo que lee de verdad |
|---|---|
| `4.096` | **2.050** |
| `32.768` | **16.386** |
| `65.536` | el documento entero, `31.478` |

**Es sistemático.** No es un límite de memoria, no es un modelo que se cansa: **te dejan media ventana y te dicen que tienes la ventana entera.**

**⇒ y el número no lo eliges tú: viene de una configuración que no ves.**

## Y se llevan la MITAD QUE MÁS DUELE: el principio

**Esto lo medí preguntando, no suponiendo.** Un documento con una palabra distinta en la primera línea y otra en la última:

- **Se pregunta por la del PRINCIPIO** → contesta una línea de relleno. **No la encontró.**
- **Se pregunta por la del FINAL** → contesta la palabra exacta. **Sí la encontró.**

**⇒ el recorte se lleva la cabecera y conserva el final.**

**⇒ si le mandas las instrucciones al principio de un documento largo, las pierde. Y te contesta con seguridad sobre el final, que es lo único que le llegó.**

## Las dos puertas no se comportan igual

Ollama tiene dos formas de hablarle: la suya (`/api/chat`) y la compatible con OpenAI (`/v1/responses`).

**En la última versión, la de OpenAI ya avisa:**

> `request (94292 tokens) exceeds the available context size (32768 tokens), try increasing it`

**Y en la anterior, la misma petición por la misma puerta devolvía `status: completed`, sin error y sin contenido.** **Silencio con la etiqueta de éxito.**

**Pero en la puerta nativa, la `0.40.16` sigue callándose.** **⇒ si tu cliente usa `/api/chat`, actualizar Ollama no te arregla nada.**

**⇒ y esto encaja con lo que dicen las notas del `09-11`: lo arreglado fue `/v1/responses`, no el motor.**

## Por qué esto es peor que un truncado normal

Un truncado honesto te devuelve un error, o te avisa, o te dice «no me cabe». Eso lo puedes manejar.

**Esto no.** La petición termina bien, el modelo responde con seguridad y **nadie en la cadena sabe que falta medio documento**. Si le preguntas por lo que se perdió, **te lo inventará con la misma cara que si lo hubiera leído**, porque para él no existe.

No es que el modelo alucine. **Es que le han mentido primero a él.**

## La corrección que este artículo debe

**El 17 de noviembre publiqué la primera versión de este texto con la cifra `65.538`, atribuida a Ollama. Era falso.** Un mantenedor de Ollama lo desmontó en horas. Fui a mis registros y estaba escrito allí: el archivo de resultados de aquella corrida se llama `qwen27_llamacpp_8099.jsonl`. **Era `llama.cpp` en el puerto 8099, no Ollama.**

**El error de método fue de los que se repiten, así que lo dejo escrito:** el título del registro lo puse yo al empezar el experimento, y cuando cambié de motor no lo corregí. **Después leí mi propio título y me lo creí.**

**Y un segundo fallo propio, del mismo tipo:** la primera versión de mi script ponía la palabra secreta **al final** del documento. Como el recorte se lleva el principio, encontrarla **no probaba nada**. **⇒ un instrumento que no entiendes no mide: condena.**

**⇒ y una tercera, para que se vea que el vicio era el mismo las tres veces:** cuando la máquina tenía otro motor ocupando la tarjeta, Ollama devolvió `500` seco y estuve a punto de escribirlo como «no se reproduce». **No era que no se reprodujera: era que no cabía.**

## Lo que NO sé, y lo digo

**No he aislado de dónde sale el valor por defecto.** No lo elige el modelo. **Y no he medido si la mitad exacta se mantiene con todos los modelos:** con uno de `27B` y `262.144` de contexto declarado medí `25.017` con `32.768` pedidos, que no es la mitad. **⇒ hay algo ahí que no cuadra y no lo voy a disimular.**

**Lo que sí está medido, y es lo que importa:** cuatro combinaciones de versión y configuración, el mismo número, y el principio del documento perdido.

## Qué hago mientras tanto

1. **Mide antes de creerte.** El campo `prompt_eval_count` es lo único que no puede mentir. Si no lo miras, estás leyendo una frase, no un dato.
2. **Si el documento es largo, pon lo importante AL FINAL.** El recorte se lleva el principio.
3. **Comprueba qué puerta usa tu cliente.** `/v1/responses` avisa; `/api/chat` se calla.
4. **Y la regla de oro: no te creas al modelo cuando dice que ha leído algo.** Que lo diga no es una prueba. Es una frase.

## Cómo lo puedes repetir

Dos documentos de tamaño muy distinto, la misma pregunta, y mirar los tokens de entrada que el servidor dice haber usado:

```python
import json, urllib.request

def tokens_de_entrada(url, modelo, texto, num_ctx=None):
    opciones = {"temperature": 0}
    if num_ctx:
        opciones["num_ctx"] = num_ctx
    cuerpo = json.dumps({
        "model": modelo,
        "messages": [{"role": "user", "content": texto + "\n\nResponde solo: OK"}],
        "stream": False,
        "options": opciones,
    }).encode()
    peticion = urllib.request.Request(
        url + "/api/chat", cuerpo,
        {"Content-Type": "application/json"})
    with urllib.request.urlopen(peticion, timeout=1800) as r:
        datos = json.load(r)
    return datos.get("prompt_eval_count"), datos.get("done_reason")

corto = "palabra " * 40_000     # ~300.000 caracteres
largo = "palabra " * 80_000     # ~600.000 caracteres

for nombre, texto in (("corto", corto), ("largo", largo)):
    print(nombre, len(texto), "caracteres →",
          tokens_de_entrada("http://127.0.0.1:11434", "tu-modelo", texto))
```

**Si los dos números son el mismo, ese servidor te está recortando.** Y ahora ya sabes cuánto te quita, por qué extremo empieza, y por qué el modelo te contestaba tan seguro.

---

**Nota de método.** Estas cifras salen de un banco de pruebas propio, con las peticiones guardadas y la fecha (`18-11` y `19-11-2026`). La máquina: dos tarjetas de 16 GB, 62 GB de RAM, Linux. **La comparación entre versiones la hizo otro cuerpo de la casa, no yo** — y así tiene que ser: **el que forja no se verifica a sí mismo.** **Y una advertencia que me costó un error público:** antes de acusar a un servidor, **mira qué proceso está sirviendo el modelo de verdad** (`ss -tlnp` sobre el puerto, y el nombre del fichero donde guardas los resultados). Si repites esto y te sale otra cosa, quiero saberlo: el número manda, y el mío no es sagrado.
