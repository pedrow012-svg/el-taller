#!/usr/bin/env bash
# ============================================================================
#  publica.sh — LA ÚNICA PUERTA PARA PUBLICAR EL TALLER
# ============================================================================
#  Palabra de Pedro, y es la ley de esta pieza:
#    «toda publicación hay que verificarla en casa antes de publicar»
#    «la página web es tuya […] la mantienes, actualizas, mejoras y reparas»
#
#  ⇒ Aquí no se empuja a ciegas. El orden es siempre el mismo:
#     ① construir          ② verificar EN CASA (salud.sh --solo-local)
#     ③ commit             ④ push            ⑤ esperar a que el DOMINIO sirva
#                                              exactamente lo que hay en casa
#     ⑥ (opcional) sincronizar el espejo, que va marcado noindex
#
#  Uso:  bash publica.sh "mensaje del commit" [--espejo] [--seco]
#        --seco     hace todo menos el push (enseña qué haría)
#        --espejo   además sincroniza github.io/taller-nuevo
#
#  Si el dominio no llega a coincidir, NO lo deja así y sin decirlo: dice qué
#  mirar y cómo volver atrás. Sale 0 sólo si el dominio sirve lo local.
# ============================================================================
set -uo pipefail

REPO="${REPO:-$HOME/Imperio_Escritos}"
DOMINIO="https://taller.dantehef.dev"
ESPEJO_DIR="$HOME/.imperio/tmp/espejo_tn"
ESPEJO_URL="https://pedrow012-svg.github.io/taller-nuevo"
LOG="$HOME/.imperio/logs/taller_web.log"

MENSAJE="${1:-}"; ESPEJO=0; SECO=0
shift || true
for a in "$@"; do
  case "$a" in
    --espejo) ESPEJO=1 ;;
    --seco)   SECO=1 ;;
  esac
done
if [ -z "$MENSAJE" ]; then
  echo "uso: bash publica.sh \"mensaje del commit\" [--espejo] [--seco]"
  exit 2
fi

sella() { mkdir -p "$(dirname "$LOG")"; printf '%s · %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }
muere() { echo "🔴 $*"; sella "PUBLICA · ABORTADO: $*"; exit 1; }

cd "$REPO" || muere "no encuentro $REPO"
echo "── PUBLICAR EL TALLER · $(date '+%Y-%m-%d %H:%M') ──"

# ── ① construir ────────────────────────────────────────────────────────────
echo "① construyendo…"
if ! python3 construye.py >/dev/null 2>"${TMPDIR:-/tmp}/taller_err.txt"; then
  cat "${TMPDIR:-/tmp}/taller_err.txt"; muere "construye.py falló: no se publica nada"
fi
echo "   ok ($(find sitio -maxdepth 1 -name '*.html' | wc -l) páginas)"

# ── ② verificar EN CASA ────────────────────────────────────────────────────
echo "② verificando en casa (sin salir a la red)…"
if ! bash salud.sh --solo-local --publicando | sed 's/^/   /'; then
  muere "la verificación en casa NO pasa: no se publica"
fi

# ── ③ commit ───────────────────────────────────────────────────────────────
echo "③ preparando el commit…"
git add -A
if git diff --cached --quiet; then
  echo "   no hay nada nuevo que publicar (el árbol está como el último commit)."
  echo "   Si querías forzar el redespliegue: git commit --allow-empty -m 'redespliegue'"
  sella "PUBLICA · nada que publicar"
  exit 0
fi
git diff --cached --stat | sed 's/^/   /'
git commit -q -m "$MENSAJE" || muere "el commit falló"
NUEVO=$(git rev-parse --short HEAD)
echo "   commit $NUEVO"

if [ "$SECO" = 1 ]; then
  echo "   (--seco: no empujo. El commit queda hecho en local y se puede deshacer con git reset --soft HEAD~1)"
  sella "PUBLICA · seco · commit $NUEVO NO empujado"
  exit 0
fi

# ── ④ push ─────────────────────────────────────────────────────────────────
echo "④ empujando a main…"
git push -q origin HEAD:main || muere "el push falló: el commit $NUEVO está en local y NO publicado"
sella "PUBLICA · push $NUEVO · $MENSAJE"

# ── ⑤ esperar a que el dominio sirva LO LOCAL ──────────────────────────────
echo "⑤ esperando al dominio (Pages reconstruye desde las fuentes)…"
dentro=0
for intento in $(seq 1 60); do
  iguales=0; total=0
  for p in sitio/*.html; do
    rel="${p#sitio/}"; [ "$rel" = "index.html" ] && url="$DOMINIO/" || url="$DOMINIO/$rel"
    total=$((total+1))
    if curl -sS --max-time 15 "$url" 2>/dev/null | cmp -s - "$p"; then iguales=$((iguales+1)); fi
  done
  if [ "$iguales" = "$total" ] && [ "$total" -gt 0 ]; then dentro=1; break; fi
  printf '   · %ds: %s/%s páginas ya coinciden\n' "$((intento*5))" "$iguales" "$total"
  sleep 5
done
if [ "$dentro" = 1 ]; then
  echo "   ✅ el dominio sirve exactamente lo de casa ($total páginas, sha256)"
  sella "PUBLICA · dominio OK en $((intento*5))s"
else
  echo "   🔴 el dominio NO coincide tras 300 s. El commit SÍ está empujado: no finjas que no."
  echo "      mira:      gh run list -R pedrow012-svg/el-taller --limit 3"
  echo "      y luego:   bash salud.sh"
  echo "      volver atrás: git revert $NUEVO && bash publica.sh 'revertir $NUEVO'"
  sella "PUBLICA · dominio NO coincide tras 300s (commit $NUEVO empujado)"
  exit 1
fi

# ── ⑥ el espejo, si se pide ────────────────────────────────────────────────
if [ "$ESPEJO" = 1 ]; then
  echo "⑥ sincronizando el espejo (noindex)…"
  if [ ! -d "$ESPEJO_DIR/.git" ]; then
    echo "   🔴 no está el clon del espejo en $ESPEJO_DIR: no lo toco"
    sella "PUBLICA · espejo no sincronizado (sin clon)"
    exit 0
  fi
  git -C "$ESPEJO_DIR" pull -q --rebase 2>/dev/null || true
  cp -r articulos plantilla construye.py "$ESPEJO_DIR/" 2>/dev/null
  ( cd "$ESPEJO_DIR" && python3 construye.py >/dev/null 2>&1 ) \
    || { echo "   🔴 el espejo no construye"; sella "PUBLICA · espejo no construye"; exit 0; }
  ( cd "$ESPEJO_DIR" && git add -A && git commit -q -m "espejo: sincronizado con $NUEVO" \
    && git push -q origin HEAD ) || { echo "   🔴 el espejo no se pudo empujar"; exit 0; }
  for intento in $(seq 1 30); do
    if curl -sS --max-time 10 "$ESPEJO_URL/" 2>/dev/null | grep -qi noindex; then
      echo "   ✅ espejo arriba y marcado noindex"; break
    fi
    sleep 5
  done
  sella "PUBLICA · espejo sincronizado"
fi

echo
echo "══ ✅ PUBLICADO: $NUEVO · $DOMINIO ══"
