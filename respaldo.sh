#!/usr/bin/env bash
# ============================================================================
#  respaldo.sh — LA COPIA DEL TALLER, CON PRUEBA DE QUE SIRVE
# ============================================================================
#  Un respaldo que no se ha probado no es un respaldo: es una carpeta.
#  ⇒ esto hace un `git bundle` (la historia entera en un fichero), lo VERIFICA
#    con `git bundle verify`, y comprueba que el remoto tiene todo.
#
#  Uso:  bash respaldo.sh [--quedan=N]     (por defecto guarda los 6 últimos)
#  Destino: ~/.imperio/backups/taller_web/taller_<fecha>.bundle
#  Registro: ~/.imperio/logs/taller_web.log
# ============================================================================
set -uo pipefail

REPO="${REPO:-$HOME/Imperio_Escritos}"
DESTINO="$HOME/.imperio/backups/taller_web"
LOG="$HOME/.imperio/logs/taller_web.log"
QUEDAN=6
for a in "$@"; do case "$a" in --quedan=*) QUEDAN="${a#*=}" ;; esac; done

sella() { mkdir -p "$(dirname "$LOG")"; printf '%s · %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }
cd "$REPO" || { echo "🔴 no encuentro el producto en $REPO"; exit 1; }
mkdir -p "$DESTINO"

SHA=$(git rev-parse --short HEAD)
FECHA=$(date '+%Y%m%d-%H%M%S')
BUNDLE="$DESTINO/taller_$FECHA.bundle"

echo "── RESPALDO DEL TALLER · HEAD $SHA · $(date '+%Y-%m-%d %H:%M') ──"

# ① el bundle, con toda la historia y todas las ramas
if ! git bundle create "$BUNDLE" --all >/dev/null 2>&1; then
  echo "🔴 git bundle FALLÓ: no hay respaldo nuevo"; sella "RESPALDO · FALLÓ el bundle"; exit 1
fi
echo "  · creado $(basename "$BUNDLE") ($(du -h "$BUNDLE" | cut -f1))"

# ② verificado: que git lo pueda leer y diga qué trae
if git bundle verify "$BUNDLE" >/dev/null 2>&1; then
  echo "  ✅ bundle verificado por git (legible y completo)"
else
  echo "🔴 el bundle NO pasa la verificación: se queda como está y se avisa"; sella "RESPALDO · bundle no verifica"; exit 1
fi

# ③ que la historia del bundle contiene el HEAD de hoy, no una copia vieja
if git bundle list-heads "$BUNDLE" 2>/dev/null | grep -q "$(git rev-parse HEAD)"; then
  echo "  ✅ el bundle contiene el HEAD de hoy ($SHA)"
else
  echo "🔴 el bundle no contiene el commit actual: respaldo INCOMPLETO"; sella "RESPALDO · bundle sin el HEAD"; exit 1
fi

# ④ el remoto tiene todo lo que tenemos (si no, el respaldo es lo único que hay)
if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  pend=$(git rev-list --count '@{u}..HEAD')
  if [ "$pend" = "0" ]; then
    echo "  ✅ el remoto tiene todo (0 commits sin empujar): hay dos copias"
  else
    echo "  ⚠️  $pend commit(s) sólo en este equipo — el bundle los guarda, pero el remoto no los tiene"
  fi
else
  echo "  ⚠️  sin rama remota: el bundle es la única copia"
fi

# ⑤ rotación: se quedan los N últimos (a la papelera, no se borran)
mapfile -t viejos < <(ls -1t "$DESTINO"/taller_*.bundle 2>/dev/null | tail -n +"$((QUEDAN+1))")
if [ "${#viejos[@]}" -gt 0 ]; then
  if command -v gio >/dev/null 2>&1; then
    gio trash "${viejos[@]}" 2>/dev/null && echo "  · ${#viejos[@]} bundle(s) viejos a la papelera (recuperables)"
  else
    echo "  · ${#viejos[@]} bundle(s) viejos sin rotar (no hay gio): se dejan"
  fi
fi

echo "  · hay $(ls -1 "$DESTINO"/taller_*.bundle 2>/dev/null | wc -l) bundle(s) en $DESTINO"
echo
echo "══ ✅ RESPALDO HECHO Y VERIFICADO · $SHA ══"
echo "   restaurar:  git clone $BUNDLE taller_restaurado"
sella "RESPALDO · OK $SHA · $(basename "$BUNDLE")"
