#!/usr/bin/env bash
# ============================================================================
#  publica.sh — LA PUERTA DEL TALLER, EN DOS TIEMPOS Y CON DOS MIRADAS
# ============================================================================
#  Palabra de Pedro, 19-11-2026, y es la ley de esta pieza:
#    «las publicaciones son producto de la casa común, por eso se deben
#     verificar antes de publicar: nada se publica sin que el otro cuerpo y yo
#     lo veamos antes. ¿Dónde? en tu web y en GitHub, que es mío, ese lo
#     administro yo como Google y cosas de web, HuggingFace, etc.»
#    «toda publicación hay que verificarla en casa antes de publicar»
#
#  ⇒ DE AHÍ SALEN DOS TIEMPOS, y no hay un tercero:
#
#    TIEMPO 1 · PROPONER   (no publica nada: deja el sitio de revisión en pie)
#        bash publica.sh propone "mensaje"
#          ① construye           ② verifica EN CASA (salud.sh)
#          ③ commit en una RAMA  ④ empuja LA RAMA y abre un PR (sin fusionar)
#          ⑤ levanta la VISTA PREVIA en http://127.0.0.1:8097
#
#    TIEMPO 2 · CERRAR     (sólo cuando las dos miradas han dicho que sí)
#        bash publica.sh cierra <PR> --visto "Hefesto (mesa 19:4x) + Pedro (ventana)"
#          ① fusiona a main   ② apaga la vista previa
#          ③ espera a que el DOMINIO sirva exactamente lo de casa
#          ④ (opcional --espejo) sincroniza el espejo noindex
#
#  Y SU LÍMITE, dicho claro porque es el punto débil y no lo escondo:
#    este guion NO puede comprobar que Hefesto y Pedro hayan mirado de verdad.
#    Lo que hace es NO DEJAR PUBLICAR sin que alguien escriba el `--visto`, y
#    dejarlo grabado en el mensaje de la fusión y en el registro. La firma la
#    pone una mano; el guion sólo se niega a saltársela.
# ============================================================================
set -uo pipefail

REPO="${REPO:-$HOME/Imperio_Escritos}"
DOMINIO="https://taller.dantehef.dev"
ESPEJO_DIR="$HOME/.imperio/tmp/espejo_tn"
ESPEJO_URL="https://pedrow012-svg.github.io/taller-nuevo"
LOG="$HOME/.imperio/logs/taller_web.log"
PREV_PUERTO=8097
PREV_LOG="$HOME/.imperio/logs/taller_previa.log"

sella() { mkdir -p "$(dirname "$LOG")"; printf '%s · %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }
muere() { echo "🔴 $*"; sella "PUBLICA · ABORTADO: $*"; exit 1; }
escucha() { ss -tlnH 2>/dev/null | grep -qE "[:.]${1}[[:space:]]"; }

cd "$REPO" || muere "no encuentro $REPO"
ORDEN="${1:-}"; shift || true

# ═══════════════════════════════════════════════════════════════════════════
#  TIEMPO 1 · PROPONER
# ═══════════════════════════════════════════════════════════════════════════
if [ "$ORDEN" = "propone" ]; then
  MENSAJE="${1:-}"; [ -n "$MENSAJE" ] || muere "uso: publica.sh propone \"mensaje del commit\""
  echo "── PROPONER (esto NO publica) · $(date '+%Y-%m-%d %H:%M') ──"

  [ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || muere "no estás en main: estás en $(git rev-parse --abbrev-ref HEAD). Vuelve a main antes de proponer."
  git fetch -q origin || muere "no puedo hablar con GitHub (¿red?)"
  if [ "$(git rev-list --count origin/main..HEAD)" != "0" ]; then
    muere "main local va por delante del remoto: hay algo sin revisión. Resuélvelo antes."
  fi

  echo "① construyendo…"
  python3 construye.py >/dev/null 2>"${TMPDIR:-/tmp}/taller_err.txt" \
    || { cat "${TMPDIR:-/tmp}/taller_err.txt"; muere "construye.py falló"; }
  echo "   ok ($(find sitio -maxdepth 1 -name '*.html' | wc -l) páginas)"

  echo "② verificando en casa…"
  bash salud.sh --solo-local --publicando | sed 's/^/   /' \
    || muere "la verificación en casa NO pasa: no se propone"

  echo "③ preparando la rama…"
  git add -A
  if git diff --cached --quiet; then
    echo "   no hay nada nuevo que proponer: el árbol está como main."
    exit 0
  fi
  RESUMEN=$(git diff --cached --stat | tail -1)
  git diff --cached --stat | sed 's/^/   /'
  RAMA="revision/$(date '+%Y%m%d-%H%M')-$(printf '%s' "$MENSAJE" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | cut -c1-32)"
  git checkout -q -b "$RAMA" || muere "no pude crear la rama $RAMA"
  git commit -q -m "$MENSAJE" || muere "el commit falló"
  SHA=$(git rev-parse --short HEAD)
  echo "   rama $RAMA · commit $SHA"

  echo "④ empujando LA RAMA (main no se toca)…"
  git push -q -u origin "$RAMA" || muere "no pude empujar la rama: nada publicado, la rama queda en local"

  echo "⑤ abriendo el PR para que lo miréis…"
  SALUD=$(bash salud.sh --solo-local 2>&1 | tail -3)
  CUERPO="**Propuesta de publicación de El Taller.** Nada de esto está en \`main\`: está en la rama \`$RAMA\`.

**Cambio:** $RESUMEN

**Verificación en casa (no es la de fuera):**
\`\`\`
$SALUD
\`\`\`

**Dónde se mira:**
- la web, en la vista previa: http://127.0.0.1:$PREV_PUERTO/ (en pie mientras dure la revisión)
- y aquí mismo, en la pestaña Files changed.

**No se fusiona hasta que lo vean las dos miradas:** 🔨 Hefesto y 👑 Pedro. Después:
\`bash publica.sh cierra <este PR> --visto \"Hefesto (...) + Pedro (...)\"\`"
  PR=$(gh pr create --base main --head "$RAMA" --title "$MENSAJE" --body "$CUERPO" 2>&1 | tail -1)
  echo "   PR: $PR"

  if ! escucha "$PREV_PUERTO"; then
    mkdir -p "$(dirname "$PREV_LOG")"
    ( cd sitio && setsid nohup python3 -m http.server "$PREV_PUERTO" --bind 127.0.0.1 \
        >> "$PREV_LOG" 2>&1 < /dev/null & )
    sleep 1.5
  fi
  if escucha "$PREV_PUERTO"; then
    echo "   ✅ vista previa en pie: http://127.0.0.1:$PREV_PUERTO/"
  else
    echo "   ⚠️  la vista previa no abrió el $PREV_PUERTO (mira $PREV_LOG)"
  fi

  echo
  echo "══ 📬 PROPUESTO, NO PUBLICADO: $SHA · rama $RAMA ══"
  echo "   Para que lo veáis:  http://127.0.0.1:$PREV_PUERTO/  y  $PR"
  echo "   Para cerrarlo:      bash publica.sh cierra <PR> --visto \"Hefesto (...) + Pedro (...)\""
  sella "PROPONE · rama $RAMA · $SHA · PR $PR · main intacto"
  exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════
#  TIEMPO 2 · CERRAR
# ═══════════════════════════════════════════════════════════════════════════
if [ "$ORDEN" = "cierra" ]; then
  PR="${1:-}"; [ -n "$PR" ] || muere "uso: publica.sh cierra <PR> --visto \"Hefesto (...) + Pedro (...)\""
  VISTO=""; ESPEJO=0
  shift || true
  while [ $# -gt 0 ]; do
    case "$1" in
      --visto)  VISTO="${2:-}"; shift 2 ;;
      --espejo) ESPEJO=1; shift ;;
      *) shift ;;
    esac
  done
  [ -n "$VISTO" ] || muere "falta --visto \"quién lo ha visto y dónde\": sin las dos miradas no se cierra"

  echo "── CERRAR (publicar) · $(date '+%Y-%m-%d %H:%M') ──"
  RAMA=$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null) || muere "no encuentro el PR $PR"
  echo "   PR $PR · rama $RAMA"
  echo "   visto por: $VISTO"

  git fetch -q origin || muere "no puedo hablar con GitHub"
  git checkout -q main && git pull -q --ff-only origin main || muere "no pude actualizar main"

  echo "① fusionando…"
  gh pr merge "$PR" --merge --delete-branch \
    -m "Publicado con las dos miradas: $VISTO" >/dev/null 2>&1 \
    || muere "la fusión falló (¿conflicto? mira el PR $PR)"
  git pull -q --ff-only origin main || muere "fusión hecha pero no pude traerla a local"
  SHA=$(git rev-parse --short HEAD)
  echo "   main = $SHA"

  echo "② apagando la vista previa…"
  if escucha "$PREV_PUERTO"; then
    pid=$(ss -tlnpH "sport = :$PREV_PUERTO" 2>/dev/null | grep -o 'pid=[0-9]*' | cut -d= -f2 | head -1)
    if [ -n "$pid" ]; then kill "$pid" 2>/dev/null && echo "   vista previa cerrada (pid $pid)"; fi
  else
    echo "   ya estaba cerrada"
  fi

  echo "③ esperando al dominio (Pages reconstruye desde las fuentes)…"
  dentro=0
  for intento in $(seq 1 60); do
    iguales=0; total=0
    for p in sitio/*.html; do
      rel="${p#sitio/}"; [ "$rel" = "index.html" ] && url="$DOMINIO/" || url="$DOMINIO/$rel"
      total=$((total+1))
      curl -sS --max-time 15 "$url" 2>/dev/null | cmp -s - "$p" && iguales=$((iguales+1))
    done
    [ "$iguales" = "$total" ] && [ "$total" -gt 0 ] && { dentro=1; break; }
    printf '   · %ds: %s/%s páginas ya coinciden\n' "$((intento*5))" "$iguales" "$total"
    sleep 5
  done
  if [ "$dentro" != 1 ]; then
    echo "   🔴 el dominio NO coincide tras 300 s. Está fusionado: no finjas que no."
    echo "      gh run list -R pedrow012-svg/el-taller --limit 3  ·  bash salud.sh"
    echo "      volver atrás: git revert $SHA y proponerlo otra vez"
    sella "CIERRA · dominio NO coincide · $SHA"
    exit 1
  fi
  echo "   ✅ el dominio sirve exactamente lo de casa ($total páginas, sha256)"
  sella "CIERRA · PUBLICADO $SHA · visto por: $VISTO"

  if [ "$ESPEJO" = 1 ]; then
    echo "④ sincronizando el espejo (noindex)…"
    if [ -d "$ESPEJO_DIR/.git" ]; then
      git -C "$ESPEJO_DIR" pull -q --rebase 2>/dev/null || true
      cp -r articulos plantilla construye.py "$ESPEJO_DIR/" 2>/dev/null
      if ( cd "$ESPEJO_DIR" && python3 construye.py >/dev/null 2>&1 \
        && git add -A && git commit -q -m "espejo: sincronizado con $SHA" \
        && git push -q origin HEAD ); then
        for _ in $(seq 1 30); do
          curl -sS --max-time 10 "$ESPEJO_URL/" 2>/dev/null | grep -qi noindex \
            && { echo "   ✅ espejo arriba y noindex"; break; }
          sleep 5
        done
      else
        echo "   ⚠️  el espejo no se pudo sincronizar"
      fi
    else
      echo "   ⚠️  no está el clon del espejo en $ESPEJO_DIR"
    fi
  fi

  echo
  echo "══ ✅ PUBLICADO CON LAS DOS MIRADAS: $SHA · $DOMINIO ══"
  exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════
cat <<EOF
uso: publica.sh <orden>

  propone "mensaje"     construye, verifica EN CASA, abre RAMA + PR y levanta la
                        vista previa en http://127.0.0.1:$PREV_PUERTO/   ⟵ NO publica
  cierra <PR> --visto "Hefesto (...) + Pedro (...)" [--espejo]
                        fusiona a main (ya con las dos miradas), apaga la previa y
                        comprueba que el dominio sirve exactamente lo de casa

  Regla de la casa (Pedro, 19-11-2026): nada se publica sin que Hefesto y Pedro
  lo hayan visto antes, en la vista previa y en GitHub.
EOF
exit 2
