#!/usr/bin/env bash
# Compute the tmux status-bar pane map for a window and store it in the window
# option @panemap (status-right shows #{@panemap}).
#
# The map is a 2x2 mini-screen of the window: each region occupied by a pane
# OTHER than the active one is inked near-background grey, and the region
# you're actually in is filled magenta. A lone pane shows nothing.
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

geom=$(tmux display-message -p -t "$win" '#{window_width} #{window_height} #{window_zoomed_flag}' 2>/dev/null) || exit 0
read -r W H zoomed <<<"$geom"
[ -z "${W:-}" ] || [ -z "${H:-}" ] && exit 0
HW=$((W / 2))   # vertical midpoint (x)
HH=$((H / 2))   # horizontal midpoint (y)

# Each quarter belongs to the pane covering most of its cells, so a short
# active pane still claims its quarter and a short neighbour still shows up.
# A zoomed active pane reports full-window geometry, so it's left out and
# takes whatever quarters no other pane covers.
ov() { local lo=$(( $1 > $3 ? $1 : $3 )) hi=$(( $2 < $4 ? $2 : $4 )); echo $(( hi >= lo ? hi - lo + 1 : 0 )); }
QX=(0 "$HW" 0 "$HW") QXE=($((HW - 1)) $((W - 1)) $((HW - 1)) $((W - 1)))
QY=(0 0 "$HH" "$HH") QYE=($((HH - 1)) $((HH - 1)) $((H - 1)) $((H - 1)))
best=(0 0 0 0) grey=(0 0 0 0) others=0
while read -r active L R T B; do
  [ "$active" = 1 ] && [ "$zoomed" = 1 ] && continue
  [ "$active" = 1 ] || others=1
  for i in 0 1 2 3; do
    area=$(( $(ov "$L" "$R" "${QX[i]}" "${QXE[i]}") * $(ov "$T" "$B" "${QY[i]}" "${QYE[i]}") ))
    if [ "$area" -gt "${best[i]}" ]; then
      best[i]=$area
      grey[i]=$(( active == 1 ? 0 : 1 ))
    fi
  done
done < <(tmux list-panes -t "$win" -F '#{pane_active} #{pane_left} #{pane_right} #{pane_top} #{pane_bottom}')
TL=${grey[0]} TR=${grey[1]} BL=${grey[2]} BR=${grey[3]}

# Quarters no other pane covers are where you are: ink them magenta (matching
# pane-active-border-style) and the rest a near-background grey, so other panes
# read as empty slots. Each column is one '▀' whose fg paints the top quarter
# and bg the bottom; block elements are drawn by the terminal to fill the cell
# exactly, unlike outline glyphs (▯) which render at font size and misalign.
color() { if [ "$1" = 1 ]; then printf 'colour237'; else printf 'magenta'; fi; }
col() { printf '#[fg=%s bg=%s]▀' "$(color "$1")" "$(color "$2")"; }
if [ "$others" = 0 ]; then
  map=""   # lone pane: nothing to locate
else
  map="$(col "$TL" "$BL")$(col "$TR" "$BR")#[default fg=colour244]"
fi

tmux set-option -w -t "$win" @panemap "$map" 2>/dev/null || exit 0
tmux refresh-client -S 2>/dev/null || true
