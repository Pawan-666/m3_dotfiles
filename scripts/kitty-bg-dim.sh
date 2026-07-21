#!/usr/bin/env bash
# State-aware "dim background" dial for kitty, bound to Ctrl +/- .
#
# kitty draws a background image opaquely, so background_opacity (desktop
# see-through) has no effect while the wallpaper is shown. So:
#   - wallpaper OFF -> adjust background_opacity  (desktop see-through, as before)
#   - wallpaper ON  -> adjust background_tint      (fade the wallpaper; higher = fainter)
#
# Usage: kitty-bg-dim.sh <more|less|reset>
#   more  = more transparent / less intrusive background
#   less  = less transparent / bolder background
#   reset = back to defaults
set -u

CACHE="$HOME/.cache/kitty-wallhaven"
KITTEN="/Applications/kitty.app/Contents/MacOS/kitten"
TINT_CONF="$CACHE/tint.conf"
STATE="$CACHE/bg-state"
DEF_OPACITY="0.1"   # off-mode reset: very see-through when there's no wallpaper
DEF_TINT="0.95"   # wallpaper very faint by default (~5%); Ctrl+= makes it bolder
STEP="0.1"

mkdir -p "$CACHE"
state="$(cat "$STATE" 2>/dev/null || echo on)"
sockets() { for s in /tmp/kitty-*; do [ -S "$s" ] && echo "$s"; done; }

if [ "$state" = "off" ]; then
  # No image: kitty accepts relative opacity deltas.
  case "${1:-}" in
    more)  arg="-$STEP" ;;
    less)  arg="+$STEP" ;;
    reset) arg="$DEF_OPACITY" ;;
    *) exit 0 ;;
  esac
  # `--all` keeps every OS window in sync; `--` so a negative delta like -0.05
  # is treated as a value, not a flag. kitty clamps opacity to [0.0, 1.0].
  for s in $(sockets); do "$KITTEN" @ --to "unix:$s" set-background-opacity --all -- "$arg" 2>/dev/null; done
else
  # Image on: change tint via include + load-config (no runtime tint command exists).
  cur="$(sed -n 's/^background_tint[[:space:]]*//p' "$TINT_CONF" 2>/dev/null | head -1)"
  [ -n "$cur" ] || cur="$DEF_TINT"
  case "${1:-}" in
    more)  new="$(awk -v c="$cur" -v s="$STEP" 'BEGIN{v=c+s; if(v>1)v=1; printf "%.2f", v}')" ;;
    less)  new="$(awk -v c="$cur" -v s="$STEP" 'BEGIN{v=c-s; if(v<0)v=0; printf "%.2f", v}')" ;;
    reset) new="$DEF_TINT" ;;
    *) exit 0 ;;
  esac
  printf 'background_tint %s\n' "$new" >"$TINT_CONF"
  for s in $(sockets); do "$KITTEN" @ --to "unix:$s" load-config 2>/dev/null; done
fi
