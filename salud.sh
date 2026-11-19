#!/usr/bin/env bash
# ============================================================================
#  salud.sh — ¿ESTÁ BIEN EL TALLER? COMPROBADO POR OTRO CAMINO
# ============================================================================
#  Producto de 🎭 Orfeo desde el 19-11-2026 (palabra de Pedro en la ventana).
#
#  QUÉ HACE, y por qué así:
#    No se fía de que «parece que está». Comprueba cinco cosas y las cinco con
#    la mano de fuera:
#      ① EL REPO     árbol limpio y todo empujado (nada construido en local y sin publicar)
#      ② LA FUENTE   reconstruye el sitio EN UNA COPIA y compara byte a byte con
#                    el `sitio/` del repo  ⟵ pilla «edité el .md y no reconstruí»
#      ③ EL DOMINIO  cada página, pedida por HTTP, con el mismo sha256 que la local
#      ④ EL MAPA     sitemap.xml con tantas URL como páginas · robots.txt con su Sitemap
#      ⑤ EL ESPEJO   github.io con `noindex` y canonical al dominio, y el TLS del dominio
#
#  Uso:
#     bash salud.sh                 todo (repo + fuente + dominio + mapa + espejo + TLS)
#     bash salud.sh --solo-local    sólo lo que no sale a la red (antes de publicar)
#     bash salud.sh --calla         sólo el veredicto final y los fallos
#
#  Sale 0 si todo pasa, 1 si algo falla. Todo queda en ~/.imperio/logs/taller_web.log
#  No escribe NADA dentro del repo salvo lo que ya escriba `construye.py` en la copia.
# ============================================================================
set -uo pipefail

REPO="${REPO:-$HOME/Imperio_Escritos}"
DOMINIO="https://taller.dantehef.dev"
ESPEJO="https://pedrow012-svg.github.io/taller-nuevo"
LOG="$HOME/.imperio/logs/taller_web.log"
COPIA="$(mktemp -d "${TMPDIR:-/tmp}/taller_salud.XXXXXX")"
trap 'rm -rf "$COPIA"' EXIT

SOLO_LOCAL=0; CALLADO=0; PUBLICANDO=0
for a in "$@"; do
  case "$a" in
    --solo-local) SOLO_LOCAL=1 ;;
    --calla)      CALLADO=1 ;;
    --publicando) PUBLICANDO=1 ;;   # voy a commitear: el árbol sucio es lo normal
    -h|--ayuda)   sed -n '2,30p' "$0"; exit 0 ;;
  esac
done

mkdir -p "$(dirname "$LOG")"
PASS=0; FALLOS=()
di()   { [ "$CALLADO" = 1 ] || printf '%s\n' "$*"; }
bien() { PASS=$((PASS+1)); di "  ✅ $*"; }
mal()  { FALLOS+=("$*");    di "  🔴 $*"; }
nota() { di "  ·  $*"; }

sella() { printf '%s · %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }

echo "── SALUD DEL TALLER · $(date '+%Y-%m-%d %H:%M') ──"
sella "SALUD · empieza (solo_local=$SOLO_LOCAL)"

# ── ⓪ hay repo y hay construye.py ──────────────────────────────────────────
if [ ! -d "$REPO/.git" ] || [ ! -f "$REPO/construye.py" ]; then
  mal "no encuentro el producto en $REPO"
  echo "🔴 NO PUEDO MIRARLO"; exit 1
fi
cd "$REPO" || exit 1

# ── ① EL REPO ──────────────────────────────────────────────────────────────
sucio=$(git status --porcelain | head -5)
if [ -z "$sucio" ]; then bien "árbol limpio (nada a medias en el working tree)"
elif [ "$PUBLICANDO" = 1 ]; then nota "árbol con cambios sin commitear (normal: se van a commitear ahora)"
else mal "hay cambios sin commitear: $(echo "$sucio" | tr '\n' ' ')"; fi

if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  por_delante=$(git rev-list --count '@{u}..HEAD')
  if [ "$por_delante" = "0" ]; then bien "empujado: HEAD $(git rev-parse --short HEAD) está en el remoto"
  else mal "$por_delante commit(s) en local SIN publicar (el dominio no los tiene)"; fi
else
  nota "sin rama remota configurada: no puedo comparar con el remoto"
fi

# ── ② LA FUENTE: reconstruir en copia y comparar byte a byte ───────────────
#    Copiamos sólo lo que hace falta: si el sitio del repo se hizo con otro
#    estado de los .md, los sha256 no van a cuadrar y esto lo dice.
cp construye.py "$COPIA/" 2>/dev/null
cp -r articulos plantilla "$COPIA/" 2>/dev/null
mkdir -p "$COPIA/sitio"
if ( cd "$COPIA" && python3 construye.py >/dev/null 2>&1 ); then
  iguales=0; distintas=()
  while IFS= read -r f; do
    rel="${f#"$COPIA/"}"
    if [ -f "$REPO/$rel" ] && cmp -s "$f" "$REPO/$rel"; then
      iguales=$((iguales+1))
    else
      distintas+=("$rel")
    fi
  done < <(find "$COPIA/sitio" -type f -name '*.html' | sort)
  if [ "${#distintas[@]}" -eq 0 ] && [ "$iguales" -gt 0 ]; then
    bien "el sitio del repo corresponde a los .md ($iguales HTML reconstruidos idénticos)"
  else
    mal "el sitio NO corresponde a los .md: ${#distintas[@]} distinto(s) — el primero: ${distintas[0]:-ninguno}. Hay que reconstruir y publicar."
  fi
else
  mal "construye.py NO construye en copia limpia: el producto no se puede levantar de cero"
fi

# ── ③ LO BÁSICO DE CADA PÁGINA, en local ───────────────────────────────────
paginas=$(find sitio -maxdepth 1 -name '*.html' | sort)
n_pag=$(printf '%s\n' "$paginas" | grep -c . || true)
articulos_md=$(find articulos -maxdepth 1 -name '*.md' | grep -c . || true)
sin_canonical=()
for p in $paginas; do
  grep -q 'rel="canonical"' "$p" || sin_canonical+=("$p")
done
if [ "${#sin_canonical[@]}" -eq 0 ]; then bien "las $n_pag páginas tienen su canonical"
else mal "sin canonical: ${sin_canonical[*]}"; fi
bien "artículos en markdown: $articulos_md · páginas construidas: $n_pag"

# ── ④ EL MAPA: sitemap y robots ────────────────────────────────────────────
if [ -f sitio/sitemap.xml ]; then
  n_url=$(grep -c '<loc>' sitio/sitemap.xml || true)
  na=$(grep -c '<loc>' sitio/sitemap.xml 2>/dev/null || true)
  # páginas de artículo = las que no son index ni temas
  n_art_pag=$(printf '%s\n' "$paginas" | grep -cvE '/(index|temas)\.html$' || true)
  if [ "$n_url" -ge "$n_art_pag" ]; then
    bien "sitemap.xml con $n_url URL (páginas de artículo: $n_art_pag · $articulos_md .md)"
  else
    mal "sitemap.xml con $n_url URL para $n_art_pag páginas de artículo: falta alguna"
  fi
  [ "$n_url" = "$((n_art_pag + 2))" ] || nota "sitemap cuenta $n_url y hay $n_art_pag artículos + index + temas = $((n_art_pag+2)): revisa cuáles entran"
else mal "no hay sitio/sitemap.xml"; fi
grep -q '<loc>' sitio/sitemap.xml 2>/dev/null && grep -q "$DOMINIO" sitio/sitemap.xml \
  && bien "el sitemap apunta al dominio ($DOMINIO)" || mal "el sitemap no apunta a $DOMINIO"
if grep -qi '^Sitemap:.*sitemap\.xml' sitio/robots.txt 2>/dev/null; then bien "robots.txt anuncia el sitemap"
else mal "robots.txt no anuncia el sitemap"; fi

if [ "$SOLO_LOCAL" = 1 ]; then
  echo "  (—solo-local: no he salido a la red)"
else
  # ── ⑤ EL DOMINIO, página por página, byte a byte ────────────────────────
  mal_vivo=()
  for p in $paginas sitio/sitemap.xml sitio/robots.txt; do
    rel="${p#sitio/}"
    [ "$rel" = "index.html" ] && url="$DOMINIO/" || url="$DOMINIO/$rel"
    servido="$COPIA/vivo_$(echo "$rel" | tr '/' '_')"
    cod=$(curl -sS -o "$servido" -w '%{http_code}' --max-time 20 "$url" 2>/dev/null || echo 000)
    if [ "$cod" != "200" ]; then mal_vivo+=("$rel ($cod)"); continue; fi
    if ! cmp -s "$p" "$servido"; then mal_vivo+=("$rel (200 pero DISTINTO: local $(wc -c <"$p") b · servido $(wc -c <"$servido") b)"); fi
  done
  if [ "${#mal_vivo[@]}" -eq 0 ]; then
    bien "el dominio sirve igual que en casa: $n_pag páginas + sitemap + robots, 200 y sha256 idéntico"
  else
    mal "el dominio NO coincide: ${mal_vivo[*]}"
    sella "DOMINIO NO COINCIDE · ${mal_vivo[*]}"
  fi

  # ── ⑥ EL ESPEJO: noindex y canonical al dominio ─────────────────────────
  cabe=$(curl -sS -o "$COPIA/espejo.html" -w '%{http_code}' --max-time 20 "$ESPEJO/" 2>/dev/null || echo 000)
  if [ "$cabe" = "200" ]; then
    if grep -qi 'noindex' "$COPIA/espejo.html" && grep -q 'rel="canonical"' "$COPIA/espejo.html"; then
      bien "el espejo está arriba y marcado noindex + canonical (no compite con el dominio)"
    else
      mal "el espejo está arriba pero SIN noindex/canonical: se come el dominio"
    fi
  else
    nota "el espejo no responde ($cabe): no es crítico, pero decirlo se dice"
  fi

  # ── ⑦ EL CERTIFICADO ────────────────────────────────────────────────────
  if command -v openssl >/dev/null 2>&1; then
    fin=$(echo | timeout 15 openssl s_client -servername taller.dantehef.dev \
            -connect taller.dantehef.dev:443 2>/dev/null \
          | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -n "${fin:-}" ]; then
      dias=$(( ( $(date -d "$fin" +%s) - $(date +%s) ) / 86400 ))
      if [ "$dias" -ge 14 ]; then bien "certificado TLS: quedan $dias días"
      else mal "certificado TLS: sólo $dias días (renovar)"; fi
    else nota "no pude leer la fecha del certificado"; fi
  fi
fi

# ── veredicto ──────────────────────────────────────────────────────────────
echo
if [ "${#FALLOS[@]}" -eq 0 ]; then
  echo "══ ✅ SALUD: BIEN · $PASS comprobaciones · $(date '+%H:%M:%S') ══"
  sella "SALUD · BIEN ($PASS comprobaciones)"
  exit 0
fi
echo "══ 🔴 SALUD: ${#FALLOS[@]} FALLO(S) · $PASS bien ══"
for f in "${FALLOS[@]}"; do echo "   🔴 $f"; done
sella "SALUD · ${#FALLOS[@]} FALLO(S): ${FALLOS[*]}"
exit 1
