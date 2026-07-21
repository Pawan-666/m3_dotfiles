#!/usr/bin/env bash
# Fetch a random Wallhaven image and set it as kitty's (subtle) background.
# - Updates running kitty windows live via the remote-control socket(s).
# - Writes an include file so newly-opened kitty windows pick up the same image.
# Designed to be run daily by a launchd agent; safe to run by hand any time.
#
# Usage: kitty-wallhaven.sh [--force]
#   --force   ignore the once-per-day freshness guard and fetch now.
#
# Tunables live in the CONFIG block below.

set -u

# ----------------------------------------------------------------------------- CONFIG
QUERY=""                  # Wallhaven search terms (empty = any; purity/categories still apply)
FALLBACK_QUERY=""         # used if QUERY returns 0 results (so a change never no-ops)
CATEGORIES="100"          # 100=general, 010=anime, 001=people (bit flags)
PURITY="100"              # SFW only (100=sfw 010=sketchy 001=nsfw)
ATLEAST="2560x1440"       # minimum resolution
RATIOS="16x9"             # preferred aspect ratios
LAYOUT="cscaled"          # kitty background_image_layout (cover, keep aspect)
CACHE="$HOME/.cache/kitty-wallhaven"
MAX_AGE=72000 # freshness guard, seconds (~20h)
UA="kitty-wallhaven/1.0"

# Absolute tool paths (launchd runs with a bare environment).
JQ="/opt/homebrew/bin/jq"
CURL="/usr/bin/curl"
KITTEN="/Applications/kitty.app/Contents/MacOS/kitten"

API="https://wallhaven.cc/api/v1/search"
STAMP="$CACHE/stamp"
LOG="$CACHE/wallhaven.log"
CONF="$CACHE/current.conf"

mkdir -p "$CACHE"
log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG"; }

# ----------------------------------------------------------------------------- freshness guard
if [ "${1:-}" != "--force" ] && [ -f "$STAMP" ]; then
  now=$(date +%s)
  last=$(stat -f %m "$STAMP" 2>/dev/null || echo 0)
  if [ $((now - last)) -lt "$MAX_AGE" ]; then
    log "skip: last fetch $((now - last))s ago (< ${MAX_AGE}s)"
    exit 0
  fi
fi

# ----------------------------------------------------------------------------- optional API key (unlocks NSFW)
APIKEY="${WALLHAVEN_APIKEY:-}"
[ -z "$APIKEY" ] && [ -r "$HOME/.config/wallhaven/apikey" ] && APIKEY="$(tr -d ' \t\r\n' <"$HOME/.config/wallhaven/apikey")"
if [ -z "$APIKEY" ] && [ "$PURITY" = "111" ]; then
  log "no API key: downgrading purity 111 -> 110 (NSFW needs a key)"
  PURITY="110"
fi

# ----------------------------------------------------------------------------- query the API
do_search() {  # $1 = query string
  "$CURL" -sS -A "$UA" -G "$API" \
    --data-urlencode "q=$1" \
    --data "categories=$CATEGORIES" \
    --data "purity=$PURITY" \
    --data "atleast=$ATLEAST" \
    --data "ratios=$RATIOS" \
    --data "sorting=random" \
    ${APIKEY:+--data "apikey=$APIKEY"} 2>>"$LOG"
}

resp="$(do_search "$QUERY")" || { log "curl(search) failed; keeping current image"; exit 0; }
count="$(printf '%s' "$resp" | "$JQ" '.data | length' 2>/dev/null || echo 0)"

# Fall back to a broad query if the primary one matches nothing.
if ! [ "$count" -gt 0 ] 2>/dev/null && [ -n "$FALLBACK_QUERY" ] && [ "$QUERY" != "$FALLBACK_QUERY" ]; then
  log "no results for '$QUERY'; falling back to '$FALLBACK_QUERY'"
  resp="$(do_search "$FALLBACK_QUERY")" || true
  count="$(printf '%s' "$resp" | "$JQ" '.data | length' 2>/dev/null || echo 0)"
fi

if ! [ "$count" -gt 0 ] 2>/dev/null; then
  log "no results (count=$count); keeping current image"
  exit 0
fi

idx=$((RANDOM % count))
url="$(printf '%s' "$resp" | "$JQ" -r ".data[$idx].path" 2>/dev/null)"
id="$(printf '%s' "$resp" | "$JQ" -r ".data[$idx].id" 2>/dev/null)"
if [ -z "$url" ] || [ "$url" = "null" ]; then
  log "could not parse image url; keeping current image"
  exit 0
fi

# ----------------------------------------------------------------------------- download
ext="${url##*.}"
[ -n "$ext" ] || ext="jpg"
tmp="$CACHE/.dl.$ext"
img="$CACHE/bg.$ext" # note: 'bg.*' base so it never collides with wallhaven.log
if ! "$CURL" -sS -A "$UA" -o "$tmp" "$url" 2>>"$LOG"; then
  log "curl(download) failed for $url; keeping current image"
  rm -f "$tmp"
  exit 0
fi
# swap in atomically-ish
rm -f "$CACHE"/bg.* 2>/dev/null
mv "$tmp" "$img"

# ----------------------------------------------------------------------------- point kitty at it
# New windows: via kitty.conf `include`.
printf 'background_image %s\n' "$img" >"$CONF"
echo on >"$CACHE/bg-state" # a fresh image means the wallpaper is shown

# Live windows: update every running kitty instance.
shopt -s nullglob
updated=0
for sock in /tmp/kitty-*; do
  [ -S "$sock" ] || continue
  if "$KITTEN" @ --to "unix:$sock" set-background-image --all --configured --layout "$LAYOUT" "$img" 2>>"$LOG"; then
    updated=$((updated + 1))
  fi
done

date >"$STAMP"
log "set background id=$id ($url) -> $img ; live windows updated on $updated socket(s)"
exit 0
