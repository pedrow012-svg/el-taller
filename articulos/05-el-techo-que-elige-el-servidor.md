titulo: Ollama no te trunca al límite que crees: te trunca al que él elige, y no te avisa
fecha: 2026-11-19
resumen: El modelo declara 262.144 tokens de contexto. El servidor le dio 16.386 y no lo dijo. Y el techo no es una constante: cambia con el num_ctx que tenga configurado. Medido y reproducido, con la corrección de un error mío incluida.

Un modelo declara **262.144** tokens de contexto. Le mandas un documento largo y contesta con seguridad, como si lo hubiera leído entero.

**No lo ha leído.** Y nadie en la cadena te lo dice.

## La medición, que cabe en una tabla

Same machine, same model (`qwen3.8:27b`, Ollama `0.34.1`), same prompt. Sólo cambia el tamaño del documento que se envía. Lo que se mira es `prompt_eval_count`: **los tokens que el servidor dice haber procesado. Ese número no puede mentir, porque lo cuenta él.**

| documento enviado | tokens que dice haber leído |
|---|---|
| 300.034 caracteres | **16.386** |
| 600.034 caracteres | **16.386** |

**Doblé el documento y el número no se movió.** Ni un token.

Eso no es un modelo que se queda corto: **es un servidor que recorta.**

## Y el techo no es un número: es una configuración

Aquí está la parte que te puede pasar a ti esta tarde. **Si el corte fuera una constante de Ollama, bastaría con sabérsela.** No lo es.

| contexto pedido | documento | leyó |
|---|---|---|
| `num_ctx = 4096` | 200.000 caracteres | **2.050 tokens** |
| `num_ctx = 32768` | 200.000 caracteres | **25.017 tokens** |
| por defecto | 300.000 caracteres | **16.386 tokens** |
| por defecto | 600.000 caracteres | **16.386 tokens** |

**El mismo documento, la misma máquina, el mismo modelo.** Pedir `4096` da `2.050`; pedir `32768` da `25.017`. **Cambia el contexto configurado y cambia lo que lee.**

**⇒ el número que te toca no lo eliges tú, y no te lo dicen.**

## Y una cosa que NO sé, y la digo antes de que la preguntes

**La relación no es proporcional y no sé por qué.** Pedir `4096` da `2.050` (la mitad); pedir `32768` da `25.017` (tres cuartos). **Tampoco sé de dónde sale el `16.386` por defecto.** No lo elige el modelo — el modelo declara `262.144`. Lo elige el servidor, con algún criterio que no he aislado.

**Lo que sí está medido, y es lo que importa:** con entradas de tamaño muy distinto, el servidor devolvió **el mismo número de tokens**. Y cambiando el `num_ctx`, cambia.

## Por qué esto es peor que un truncado normal

Un truncado honesto te devuelve un error, o te avisa, o te dice «no me cabe». Eso lo puedes manejar.

**Esto no.** La petición termina con `200 OK` y `done_reason: stop` — **el mismo final que una respuesta completa y feliz.** El modelo contesta con seguridad. Si le preguntas por lo que se perdió, **te lo inventará con la misma cara que si lo hubiera leído**, porque para él no existe.

No es que el modelo aluciente. **Es que le han mentido primero a él.**

## La corrección que este artículo debe, y por qué va aquí

**El 17 de noviembre publiqué una versión anterior de este texto con la cifra `65.538`, atribuida a Ollama. Era falso.** Un mantenedor de Ollama lo desmontó en horas: la versión que yo usaba ni siquiera admite ese modelo. Fui a mis registros y estaba escrito allí — el archivo de resultados de aquella corrida se llama `qwen27_llamacpp_8099.jsonl`. **Era `llama.cpp` en el puerto 8099, no Ollama.**

**El error de método fue de los que se repiten, así que lo dejo escrito:** el título del registro lo puse yo al empezar el experimento, y cuando cambié de motor no lo corregí. **Después leí mi propio título y me lo creí.**

**⇒ lo que sobrevive es lo que está medido hoy y reproducido:** el truncado es real, es silencioso, y el techo depende del servidor.

**Y un segundo fallo propio, del mismo tipo, que también dejo apuntado:** la primera versión del script de prueba ponía la palabra secreta **al final** del documento. Si el servidor recorta por el principio —que es lo habitual—, encontrarla **no prueba nada**. El número de tokens sí valía; el «acertó la palabra» no. **Un instrumento que no entiendes no mide: condena.**

## Qué hago mientras tanto

1. **Mide antes de creerte.** El campo `prompt_eval_count` de la respuesta es lo único que no puede mentir. Si no lo miras, estás leyendo una frase, no un dato.
2. **Pon el contexto explícito, y vuelve a medirlo.** Pedirlo no garantiza obtenerlo.
3. **Desconfía del `done_reason: stop`.** Un `stop` no significa que se leyera todo: significa que el servidor terminó contento.
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

**Si los dos números son el mismo, ese servidor te está recortando.** Y ahora ya sabes por qué el modelo te contestaba tan seguro.

---

**Nota de método.** Estas cifras salen de un banco de pruebas propio, con las peticiones guardadas y la fecha (`18-11` y `19-11-2026`). La máquina: dos tarjetas de 16 GB, 62 GB de RAM, Linux, Ollama `0.34.1`. **Y una advertencia que me costó un error público:** antes de acusar a un servidor, **mira qué proceso está sirviendo el modelo de verdad** — `ss -tlnp` sobre el puerto, y el nombre del fichero donde guardas los resultados. Yo tenía la prueba en mis propios registros y no la miré. Si repites esto y te sale otra cosa, quiero saberlo: el número manda, y el mío no es sagrado.
