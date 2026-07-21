#!/usr/bin/env bash
# Toggle the kitty Wallhaven background on/off across all running kitty windows.
# With the wallpaper OFF, background_opacity (Ctrl +/-) shows the desktop through
# again; with it ON you get the subtle daily image back.
#
# Bound to a key in kitty.conf via: launch --type=background <this script>
set -u

CACHE="$HOME/.cache/kitty-wallhaven"
KITTEN="/Applications/kitty.app/Contents/MacOS/kitten"
CONF="$CACHE/current.conf"     # included by kitty.conf → controls new windows
STATE="$CACHE/bg-state"
LAYOUT="cscaled"
OPACITY_ON="0.5"               # opacity while the wallpaper is shown
OPACITY_OFF="0.1"              # very see-through when there's no wallpaper

mkdir -p "$CACHE"
img="$(ls -1 "$CACHE"/bg.* 2>/dev/null | head -1)"
state="$(cat "$STATE" 2>/dev/null || echo on)"

apply() {  # $1 = image path or "none" ; $2 = layout (optional)
  shopt -s nullglob
  for sock in /tmp/kitty-*; do
    [ -S "$sock" ] || continue
    if [ -n "${2:-}" ]; then
      "$KITTEN" @ --to "unix:$sock" set-background-image --all --configured --layout "$2" "$1" 2>/dev/null
    else
      "$KITTEN" @ --to "unix:$sock" set-background-image --all --configured "$1" 2>/dev/null
    fi
  done
}

set_opacity() {  # $1 = opacity value
  shopt -s nullglob
  for sock in /tmp/kitty-*; do
    [ -S "$sock" ] || continue
    "$KITTEN" @ --to "unix:$sock" set-background-opacity --all -- "$1" 2>/dev/null
  done
}

if [ "$state" = "on" ]; then
  apply none                 # hide wallpaper on live windows
  : >"$CONF"                 # and for new windows
  set_opacity "$OPACITY_OFF" # very see-through with no wallpaper
  echo off >"$STATE"
else
  if [ -n "$img" ]; then
    apply "$img" "$LAYOUT"
    printf 'background_image %s\n' "$img" >"$CONF"
  fi
  set_opacity "$OPACITY_ON"  # restore normal opacity behind the wallpaper
  echo on >"$STATE"
fi
