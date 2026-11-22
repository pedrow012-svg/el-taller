---
titulo: Nuestro modelo aprendió castellano en 1,09 bits por carácter; la etapa que iba a enseñarle nuestra voz lo dejó en 3,77
fecha: 2026-11-22
resumen: Entrenamos desde cero un modelo de 74,7 millones de parámetros — arquitectura, tokenizador y datos propios —. Aprendió castellano con 1,09 bits por carácter. La etapa final, la que iba a meterle nuestra forma de escribir, multiplicó la perplejidad por 246. Y la cifra que decidía de verdad llevaba semanas delante de nosotros: un examen de 20 preguntas.
tema: entrenamiento
---

Este artículo va de un modelo que construimos entero, de la cifra que nos hizo creer que iba bien, y de la cifra que decía la verdad y que tardamos en mirar.

No hay nada aquí que no esté en un registro de entrenamiento con su fecha. Los números salen de las fichas que escribió cada corrida: cada ficha guarda los pasos, los tokens vistos, la pérdida de validación y los bits por carácter. Nada de esto es una impresión.

## Lo que se construyó

Sin descargar un solo peso. Arquitectura escrita aquí, tokenizador entrenado aquí, y el corpus montado a mano. El bicho, leído del checkpoint y no de la memoria:

```
74.771.200 parámetros · 12 capas · d=640 · 10 cabezas
MLP denso de 2.560 · contexto 512 · vocabulario 24.000
cabeza de salida ATADA a la tabla de palabras
149 tensores · denso, sin expertos ni enrutador
```

Dos detalles que costaron su rato y que conviene contar, porque son los que uno se salta:

**La cabeza atada.** El tensor de entrada y el de salida son el mismo. Cuando alguien suma el `state_dict` a mano le salen **90.131.200** parámetros, y son mentira: los 15.360.000 de la tabla (`24.000 × 640`) están contados dos veces. Los de verdad son **74.771.200**. Cualquiera que copie el número del `state_dict` está publicando un modelo un 20 % más grande del que tiene.

**La unidad de medida.** No usamos perplejidad para comparar entre etapas. La perplejidad no se puede comparar entre tokenizadores distintos, y aquí había dos. La unidad fue **bits por carácter**, que sí se compara. Esa decisión nos salvó de una confusión y nos metió en otra que cuento más abajo.

**Y un tokenizador propio de 24.000 piezas.** Eso significa que las cifras de este artículo no son comparables con las de ningún modelo de fuera: nadie más parte el texto igual.

## Cómo se entrenó: dos etapas y una proporción

- **Etapa 1 — el idioma.** **1.189.642.240 tokens** de castellano público: 1.574.713 documentos, 5,20 GB, licencia abierta, filtrados entre 400 y 120.000 caracteres. 72.610 pasos. Tardó **17.022 segundos** (4 h 44 min).
- **Etapa 2 — nuestra voz.** **4.968.943 tokens** de material propio: conversaciones, actas, notas de trabajo.

La proporción, y este es el dato que hay que mirar dos veces: **la etapa nuestra era el 0,42 % de todo lo que el modelo vio**. Cuatro mil novecientos sesenta y ocho mil tokens frente a mil ciento noventa millones.

Un modelo de 74,7 millones de parámetros pide alrededor de **1.495 millones de tokens** para aprender bien, a razón de unos 20 por parámetro. Teníamos **4.968.943** tokens de material propio. Faltaban **300 veces**.

Ese diagnóstico — faltan datos nuestros, no pericia — lo escribimos y lo sostuvimos. Y era verdad a medias, que es la peor clase de verdad.

## Los tres números

| etapa | pasos | tokens vistos | pérdida val. | bits/carácter |
|---|---|---|---|---|
| castellano público | 72.610 | 1.189.642.240 | 3,3662 | **1,0947** |
| + nuestra etapa | 1.425 | 23.347.200 | 8,8735 | **3,7687** |

**El modelo aprendió castellano.** 1,09 bits por carácter es un texto que se lee: sujeto, verbo, concordancia, párrafos que empiezan y acaban. Para un modelo de 74 millones entrenado cuatro horas en una máquina de casa, eso está bien y no hace falta adornarlo.

**Y la etapa nuestra lo destrozó.** De 1,09 a 3,77 bits por carácter. La perplejidad pasó de **28,97 a 7.140,36**: multiplicada por **246**.

La etapa que existía para enseñarle nuestra forma de escribir fue la que le hizo olvidar cómo se escribe.

## Lo que creímos entonces, y lo que era

La explicación que nos dimos fue la de los datos: faltaban trescientas veces. Y con esa explicación se cerró el capítulo del modelo, con un número delante.

Es una explicación razonable y no la retiro, pero no es la que explica ese salto. Un corpus pequeño y bien elegido **afina** un modelo; no lo convierte en ruido. Lo que hace ruido es repetir ese corpus pequeño muchas veces encima de uno grande: cinco épocas sobre el 0,42 % no enseñan la voz, borran el idioma. Es el viejo olvido catastrófico, y aquí se vio con una claridad que casi da pena.

¿Por qué no lo medimos como tal? Porque para eso estaba el **gemelo**: una copia de los pesos justo antes de la etapa nuestra, el mismo modelo sin haber visto ni una línea de lo propio. La comparación honesta era **A → B**: el gemelo contra el afinado. Y no contra un modelo de fuera cuatrocientas cuarenta y cuatro veces más grande, que es una comparación que no dice nada y queda muy bien en una tabla.

El gemelo se guardó. La comparación, no la hicimos con el rigor que habíamos escrito. Eso también hay que decirlo.

## Una veintena de corridas más, y la trampa otra vez

Después de aquello no nos quedamos quietos. Hay **veinticinco fichas** de entrenamiento guardadas, y casi todas son intentos de arreglar la etapa nuestra: más épocas, menos épocas, otra tasa de aprendizaje, pares de pregunta y respuesta en vez de prosa, la duda sobrepesada para que el modelo aprendiera a decir «no lo sé» en vez de inventar.

Y funcionó, en el sentido de que los números mejoraron:

| corrida | pérdida val. | bits/carácter |
|---|---|---|
| la que se rompió | 8,8735 | 3,7687 |
| la misma etapa con más tokens propios | 4,6730 | 1,98 |
| la mejor corrida afinada | 3,2792 | 1,36 |

De 3,77 a 1,36 bits por carácter. Sobre el papel, la etapa nuestra dejó de romperlo: el modelo volvía a escribir castellano.

**Y no sabía nada.** Llegó el examen, veinte preguntas cuya respuesta no estaba copiada en ningún sitio, y el mejor modelo salió con **3 aciertos de 20**.

## La cifra que decidía estaba delante desde el primer día

El examen no lo inventamos después. Existía desde antes de entrenar: **veinte preguntas con su respuesta esperada y una tercera columna para las invenciones** — porque un modelo que acierta doce veces inventando seis no es mejor que uno que acierta tres y se calla nueve.

La vara estaba puesta en **12 aciertos de 20, 33 puntos de 55 y cero invenciones**.

| | aciertos | puntos | invenciones |
|---|---|---|---|
| la vara | 12/20 | 33/55 | 0 |
| el mejor modelo construido aquí | **3/20** | 9/55 | — |
| el más honesto (no inventa y se calla) | 2/20 | 6/55 | **0**, con 9 «no lo sé» |

Tres de veinte. Y el más honesto, dos, con nueve negativas limpias: un modelo que no inventa porque apenas habla.

Y aquí está lo que de verdad enseñó este experimento, más que cualquier pérdida: **con el mismo corpus escaso, el índice de búsqueda —un buscador, no un modelo— llegaba a 11 aciertos de 20.** El material no daba para un modelo de lenguaje. Daba para un buscador. Elegimos el instrumento equivocado para el material que había, y lo elegimos con los ojos abiertos porque construir un modelo hace más ilusión que montar un índice.

## La moraleja, que es sobre medir y no sobre modelos

La pérdida de validación mide **cuánto se parece el texto que sale al texto que entró**. No mide si el modelo sabe algo. Un modelo puede bajar a 1,09 bits por carácter y no saber dónde está, ni qué es una nómina, ni cuándo tiene que decir «no lo sé».

Nosotros teníamos la cifra buena —el examen— escrita desde el principio, y miramos la otra durante semanas porque la otra mejoraba. Es exactamente el mismo error que ya habíamos cometido antes en este taller con otra bandera: medir con la varita que sube en vez de con la que decide.

Lo que queda de todo aquello no son los pesos. **Los pesos se perdieron**; lo que hay son las fichas: veinticinco ficheros de unos cuatrocientos bytes con los pasos, los tokens, la pérdida y los bits por carácter, y los dos tokenizadores. La ficha sobrevivió al modelo.

Y eso, para un taller que publica lo que mide, es la lección de verdad: **lo que no se escribe, no existe — y una cifra sin su examen es una cifra que miente con la cara seria.**
