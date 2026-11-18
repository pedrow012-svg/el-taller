titulo: Ollama trunca tu documento en silencio, y el modelo te dice que lo ha leído entero
fecha: 2026-11-17
resumen: Doblé el documento de tamaño y los tokens que leyó no se movieron. Ollama recorta al contexto que tenga configurado y no avisa. Y hay una corrección: la primera cifra que publiqué aquí no era de Ollama.

Voy a empezar por lo que más duele, porque el truncado no es la parte grave.

Le dimos a un modelo un documento largo y contestó:

> «He leído la Mesa, el Taller, los pendientes abiertos…»

**No los había leído.** El servidor le había entregado una fracción del texto y no se lo dijo a nadie. Ni a él ni a mí.

## Qué medí

El experimento, en el fondo, es de una simplicidad insultante: **el mismo documento, con el mismo prompt, dos veces, cambiando sólo el tamaño de la entrada.** Y mirar cuántos tokens de entrada dice el servidor que ha usado. Ese número no puede mentir: lo cuenta él.

El 18 de noviembre de 2026, con `qwen3.8:27b`, que declara **262.144** tokens de contexto:

| lo que envié | lo que el servidor dice haber leído |
|---|---|
| 300.000 caracteres | **16.386 tokens** |
| 600.000 caracteres | **16.386 tokens** |

**Mira la columna otra vez.** Doblé el documento y el número no se movió ni un token. No es que leyera menos de lo que le di: **es que lee siempre lo mismo, y el resto lo tira.**

## Y la corrección que debo a este artículo

**La primera versión de este texto decía `65.538`.** Lo publiqué el 17 de noviembre y era falso **en un punto concreto y grave: atribuía ese número a Ollama, y venía de otro servidor.**

Un mantenedor de Ollama lo cazó en horas con una sola línea: la versión que yo usaba ni siquiera admite ese modelo. Fui a mis propios registros y estaba escrito allí: el archivo de resultados de aquella corrida se llama `qwen27_llamacpp_8099.jsonl`. **Era `llama.cpp` en el puerto 8099, no Ollama.**

El error de método fue ridículo y por eso lo dejo escrito: **el título del registro lo puse yo al empezar el experimento, y cuando cambié de motor no lo corregí. Después leí mi propio título y me lo creí.**

**Lo que sí sobrevive, medido hoy y reproducido:** el truncado es real, es silencioso, y la cifra depende del servidor.

## El techo no es un número: es una configuración

Aquí está lo que convierte una anécdota en algo que te puede pasar a ti. **El corte no es una constante de Ollama: sigue al contexto que tenga configurado.**

| contexto pedido | documento | leyó |
|---|---|---|
| `num_ctx = 4096` | 200.000 caracteres | **2.050 tokens** |
| `num_ctx = 32768` | 200.000 caracteres | **25.017 tokens** |
| por defecto | 300.000 caracteres | **16.386 tokens** |
| por defecto | 600.000 caracteres | **16.386 tokens** |

**El mismo modelo, la misma máquina.** Con el mismo documento de 200.000 caracteres, pedir `4096` da `2.050` tokens y pedir `32768` da `25.017`: **cambia el contexto configurado y cambia lo que lee.** Y con el valor por defecto, doblar el documento de 300.000 a 600.000 caracteres no mueve la cifra. Y el modelo declara `262.144`.

**⇒ el número que te toca no lo eliges tú, y no te lo dicen.** Eso es lo que hay que llevarse.

## Por qué esto es peor que un truncado normal

Un truncado honesto te devuelve un error, o te avisa, o te dice «no me cabe». Eso lo puedes manejar.

**Esto no.** La petición termina con `200 OK`, el modelo responde con seguridad y **nadie en la cadena sabe que falta texto**. Si le preguntas por lo que se perdió, **te lo inventará con la misma cara que si lo hubiera leído**, porque para él no existe.

No es que el modelo alucine. **Es que le han mentido primero a él.**

## Lo que NO sé, y lo digo

**No he determinado de dónde sale exactamente el valor por defecto.** No lo elige el modelo, desde luego. **Y hay una asimetría que no he medido: cuál de las dos puntas del documento se tira.** Si recorta el principio y conserva el final, el modelo pierde tus instrucciones y se queda con la conclusión — que es la peor mitad para perder.

**Lo que sí está medido, y es lo que importa:** con entradas de tamaño muy distinto, la salida del servidor fue **el mismo número de tokens**. Eso no es un modelo que se queda corto; es un servidor que recorta.

## Qué hago mientras tanto

1. **Si el documento es largo, no uses el atajo.** Comprueba los tokens que llegan de verdad antes de creerte una respuesta.
2. **Pídelo explícito.** Si el servidor acepta un tamaño de contexto, ponlo tú, y aun así **mídelo**: pedirlo no garantiza obtenerlo.
3. **Y la regla de oro: no te creas al modelo cuando dice que ha leído algo.** Que lo diga no es una prueba. Es una frase.

## Cómo lo puedes repetir

Es un experimento de dos minutos. Genera dos documentos de tamaño muy distinto, mándalos con la misma pregunta, y **mira los tokens de entrada que el servidor dice haber usado** (no los que crees haber enviado):

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

**Nota de método, y esta vez va en serio.** Estas cifras salen de un banco de pruebas propio, con las peticiones guardadas y la fecha. La máquina: dos tarjetas de 16 GB, 62 GB de RAM, Linux. **Y una advertencia que me costó un error público:** antes de acusar a un servidor, **mira qué proceso está sirviendo el modelo de verdad** (`ss -tlnp` sobre el puerto, y el nombre del fichero de resultados). Yo tenía la prueba en mis propios registros y no la miré. Si repites esto y te sale otra cosa, quiero saberlo: el número manda, y el mío no es sagrado.
