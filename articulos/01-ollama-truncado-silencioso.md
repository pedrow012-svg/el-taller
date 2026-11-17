titulo: Ollama trunca tu documento en silencio, y el modelo te dice que lo ha leído entero
fecha: 2026-11-17
resumen: Le pasamos 300.000 y 600.000 caracteres. En los dos casos leyó 65.538 tokens. Y contestó como si hubiera leído todo.

Voy a empezar por lo que más duele, porque el truncado no es la parte grave.

Le dimos a un modelo un documento largo y contestó:

> «He leído la Mesa, el Taller, los pendientes abiertos…»

**No los había leído.** El servidor le había entregado menos de la mitad del texto y no se lo dijo a nadie. Ni a él ni a mí.

## Qué medí

La misma petición, el mismo prompt, dos servidores distintos. Cada vez cambiaba solo el tamaño del documento:

| lo que envié | Ollama leyó | llama.cpp leyó |
|---|---|---|
| 300.000 caracteres | **65.538 tokens** | 112.627 tokens |
| 600.000 caracteres | **65.538 tokens** | 129.375 tokens |

**Mira la primera columna otra vez.** Doblé el documento y el número no se movió: **65.538**. No es que leyera menos de lo que le di; es que **lee siempre lo mismo, y el resto lo tira**.

En la segunda columna el número sí crece con el documento. Es la misma máquina, las dos tarjetas, el mismo modelo. La diferencia es el servidor.

## Por qué esto es peor que un truncado normal

Un truncado honesto te devuelve un error, o te avisa, o te dice "no me cabe". Eso lo puedes manejar.

**Esto no.** La petición termina con `200 OK`, el modelo responde con seguridad y **nadie en la cadena sabe que falta la mitad del texto**. Si le preguntas por el final del documento, **te lo va a inventar con la misma cara que si lo hubiera leído**, porque para él no existe la parte que no le llegó.

No es que el modelo alucine. **Es que le han mentido primero a él.**

## Lo que NO sé, y lo digo

**No he determinado la causa.** El tope era exactamente 65.536 tokens (64 × 1024), y el servidor entregaba 65.538 entre cabeceras y plantilla. Eso apunta a un límite de contexto del servidor — pero **no he aislado si viene del valor por defecto de `num_ctx`, de una variable de entorno, o de un tope duro del propio servidor**.

**Lo que sí está medido, y es lo que importa:** con dos tamaños de entrada muy distintos, la salida del servidor fue **el mismo número de tokens**. Eso no es un modelo que se queda corto; es un servidor que recorta.

## Qué hago mientras tanto

1. **Si el documento es largo, no uses el atajo.** Comprueba el número de tokens que llegan de verdad antes de creerte una respuesta.
2. **Pídelo explícito.** Si el servidor acepta un tamaño de contexto, ponlo tú, y aun así **mídelo**: pedirlo no garantiza obtenerlo.
3. **Para documentos de verdad largos, un servidor que no recorte.** En mi caso, el mismo modelo por `llama.cpp` leyó 112.627 y 129.375 tokens de los mismos textos.
4. **Y la regla de oro: no te creas al modelo cuando dice que ha leído algo.** Que lo diga no es una prueba. Es una frase.

## Cómo lo puedes repetir

Es un experimento de dos minutos. Genera dos documentos de tamaño muy distinto, mándalos con la misma pregunta, y **mira los tokens de entrada que el servidor dice haber usado** (no los que crees haber enviado):

```python
import json, urllib.request

def tokens_de_entrada(url, modelo, texto):
    cuerpo = json.dumps({
        "model": modelo,
        "messages": [{"role": "user", "content": texto + "\n\nResponde solo: OK"}],
        "stream": False,
    }).encode()
    peticion = urllib.request.Request(
        url + "/v1/chat/completions", cuerpo,
        {"Content-Type": "application/json"})
    with urllib.request.urlopen(peticion, timeout=300) as r:
        datos = json.load(r)
    return datos["usage"]["prompt_tokens"]

corto  = "palabra " * 40_000     # ~300.000 caracteres
largo  = "palabra " * 80_000     # ~600.000 caracteres

for nombre, texto, base in (("ollama", corto, "http://127.0.0.1:11434"),
                            ("ollama", largo, "http://127.0.0.1:11434"),
                            ("llama.cpp", corto, "http://127.0.0.1:8099"),
                            ("llama.cpp", largo, "http://127.0.0.1:8099")):
    print(nombre, len(texto), "caracteres →",
          tokens_de_entrada(base, "tu-modelo", texto), "tokens")
```

Si los dos números de un servidor son **el mismo**, ese servidor te está recortando. Y ahora ya sabes por qué el modelo te contestaba tan seguro.

---

**Nota de método.** Estas cifras salen de un banco de pruebas propio, con las peticiones guardadas y la fecha. La máquina: dos tarjetas de 16 GB, 62 GB de RAM, Linux. El mismo modelo en los dos servidores. Si repites esto y te sale otra cosa, quiero saberlo: el número manda, y el mío no es sagrado.
