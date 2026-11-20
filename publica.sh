#!/usr/bin/env bash
# ============================================================================
#  publica.sh — ESTO NO ES LA PUERTA: ES EL SEÑALADOR QUE APUNTA A ELLA
# ============================================================================
#  La puerta de verdad vive FUERA del repo y es una sola:
#
#      ~/scripts/taller.sh
#
#  ⇒ Y aquí no hay copia, a propósito. Una puerta dentro de lo que custodia
#    se puede saltar, y una copia se separa de la original sin avisar.
#
#  LO QUE PASÓ, con fechas, para que nadie vuelva a meter la puerta aquí:
#
#   · Hasta el `20-11-2026` este fichero era una puerta COMPLETA (137 líneas)
#     que empujaba DIRECTO a `main`: construía, verificaba en casa y publicaba
#     sin que nadie más lo hubiera visto. Con la ley del `19-11-2026` —«nada se
#     publica sin las dos miradas»— eso ya no es una puerta: es un atajo.
#
#   · El PR #1 quiso traer al repo la puerta buena, copiada (232 líneas).
#     🔨 Hefesto lo paró el `20-11` a las `09:5x` y tenía razón: además de
#     duplicarla, la copia servía la vista previa DESDE EL ÁRBOL DE TRABAJO en
#     vez de desde la copia congelada, que es justo el defecto medido el `19-11`
#     (al volver a `main`, la previa enseñaba lo viejo). Dos puertas que se
#     comportan distinto en el paso donde se mira: eso no se aprueba.
#
#   · ⇒ Se cerró el PR #1 y se dejó esto: un señalador de cuatro líneas.
#
#  CÓMO SE USA (lo mismo que la puerta de verdad):
#
#      ./publica.sh propone "mensaje del commit"
#          construye, verifica en casa, abre RAMA + PR y deja una vista previa
#          congelada en http://127.0.0.1:8097   ← `main` no se toca
#
#      ./publica.sh cierra <PR> --visto "Hefesto (...) + Pedro (...)"
#          fusiona sólo con las DOS MIRADAS escritas, apaga la previa y espera
#          a que el dominio sirva exactamente lo de casa (sha256)
#
#  Si la puerta no está, esto lo dice y no hace nada: no hay plan B, porque un
#  plan B de la puerta es exactamente el problema que este fichero resuelve.
# ============================================================================
set -uo pipefail

PUERTA="${TALLER_PUERTA:-$HOME/scripts/taller.sh}"

if [ ! -x "$PUERTA" ]; then
  echo "🔴 no encuentro la puerta: $PUERTA"
  echo "   La puerta vive fuera del repo y no se copia aquí. Sin ella NO se publica."
  exit 1
fi

echo "→ puerta: $PUERTA   (esto es un señalador, no la puerta)"
exec bash "$PUERTA" "$@"
