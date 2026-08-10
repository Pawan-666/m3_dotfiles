#!/usr/bin/env bash
# Compute the tmux status-bar pane map for a window and store it in the window
# option @panemap (status-right shows #{@panemap}).
#
# The map is a 2x2 mini-screen of the window: each region occupied by a pane
# OTHER than the active one is inked dim grey; the region you're actually in is
# left as bare background (invisible). So a lone pane shows nothing, and a split
# lights up only where the other pane(s) live.
#
# Why a script (not pure tmux format): it is driven by the NON-active panes'
# geometry, which — unlike the active pane's #{pane_left}/#{pane_right} — keeps
# its real coordinates when a pane is ZOOMED. That lets the split view stay
# correct under zoom. OR-ing overlap across a variable number of panes also
# isn't expressible in tmux's format mini-language, so we do it here.
#
# Invoked from hooks in ~/.tmux.conf on any layout/pane/zoom/window change,
# always with the target window id, e.g.:  tmux-pane-map.sh #{window_id}
set -euo pipefail

win="${1:-}"
[ -z "$win" ] && exit 0

geom=$(tmux display-message -p -t "$win" '#{window_width} #{window_height}' 2>/dev/null) || exit 0
read -r W H <<<"$geom"
[ -z "${W:-}" ] || [ -z "${H:-}" ] && exit 0
HW=$((W / 2))   # vertical midpoint (x)
HH=$((H / 2))   # horizontal midpoint (y)

TL=0 TR=0 BL=0 BR=0   # a quarter is "grey" if some non-active pane overlaps it
while read -r active L R T B; do
  [ "$active" = "1" ] && continue          # skip active pane (collapses when zoomed)
  left=0 right=0 top=0 bot=0
  [ "$L" -lt "$HW" ] && left=1
  [ "$R" -ge "$HW" ] && right=1
  [ "$T" -lt "$HH" ] && top=1
  [ "$B" -ge "$HH" ] && bot=1
  [ "$left" = 1 ]  && [ "$top" = 1 ] && TL=1
  [ "$right" = 1 ] && [ "$top" = 1 ] && TR=1
  [ "$left" = 1 ]  && [ "$bot" = 1 ] && BL=1
  [ "$right" = 1 ] && [ "$bot" = 1 ] && BR=1
done < <(tmux list-panes -t "$win" -F '#{pane_active} #{pane_left} #{pane_right} #{pane_top} #{pane_bottom}')

# per column: ink the grey (other-pane) halves — both->███ top->▀▀▀ bottom->▄▄▄ none->spaces
col() {
  if   [ "$1" = 1 ] && [ "$2" = 1 ]; then printf '███'
  elif [ "$1" = 1 ];                 then printf '▀▀▀'
  elif [ "$2" = 1 ];                 then printf '▄▄▄'
  else                                    printf '   '
  fi
}
map="#[fg=colour240 bg=default]$(col "$TL" "$BL")$(col "$TR" "$BR")#[default fg=colour244]"

tmux set-option -w -t "$win" @panemap "$map" 2>/dev/null || exit 0
tmux refresh-client -S 2>/dev/null || true
