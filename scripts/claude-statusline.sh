#!/usr/bin/env bash
# Claude Code status line: compact claude.ai "Current session" usage bar,
# right-aligned so it sits at the bottom-right of the Claude UI.
# Claude pipes session JSON on stdin; rate_limits.five_hour holds the 5-hour
# window's used % and reset time (subscribers only, after the first reply).
#
#                                                  █░░░░░░░░░ 1% 4h56m
#
# Usage (settings.json): "statusLine": {"type": "command", "command": "<this script>"}

export LC_ALL=en_US.UTF-8   # ${#str} must count the bar glyphs as one column each

BAR_WIDTH=10
BLUE=$'\e[38;5;33m'
TRACK=$'\e[38;5;238m'
DIM=$'\e[38;5;245m'
RESET=$'\e[0m'

read -r pct resets_at < <(jq -r '
  .rate_limits.five_hour // {} |
  "\(.used_percentage // "") \(.resets_at // "")"' 2>/dev/null)

# Prints $1 (colored) right-aligned, using $2 (plain text) for its width.
# Claude doesn't pass the terminal width, so ask tmux; one column of slack
# keeps the line from wrapping.
print_right() {
  local cols
  [ -n "$TMUX_PANE" ] && cols=$(tmux display -p -t "$TMUX_PANE" '#{pane_width}' 2>/dev/null)
  cols=${cols:-$COLUMNS}
  local pad=$(( ${cols:-0} - ${#2} - 1 ))
  [ "$pad" -gt 0 ] && printf '%*s' "$pad" ''
  printf '%s' "$1"
}

if [ -z "$pct" ]; then
  print_right "${DIM}—${RESET}" "—"
  exit 0
fi

pct_int=$(printf '%.0f' "$pct")
filled=$(( (pct_int * BAR_WIDTH + 50) / 100 ))
# Any usage at all shows at least one cell, like the web bar's rounded cap.
[ "$pct_int" -gt 0 ] && [ "$filled" -eq 0 ] && filled=1
[ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH

done_cells=""; todo_cells=""
for ((i = 0; i < BAR_WIDTH; i++)); do
  if [ "$i" -lt "$filled" ]; then done_cells+="█"; else todo_cells+="░"; fi
done

left_txt=""
if [ -n "$resets_at" ]; then
  resets_at=${resets_at%.*}
  [ "$resets_at" -gt 1000000000000 ] && resets_at=$(( resets_at / 1000 ))
  left=$(( resets_at - $(date +%s) ))
  if [ "$left" -gt 0 ]; then
    h=$(( left / 3600 )); m=$(( left % 3600 / 60 ))
    if [ "$h" -gt 0 ]; then left_txt="${h}h${m}m"; else left_txt="${m}m"; fi
  fi
fi

plain="${done_cells}${todo_cells} ${pct_int}%${left_txt:+ $left_txt}"
colored="${BLUE}${done_cells}${TRACK}${todo_cells}${RESET} ${pct_int}%${left_txt:+ ${DIM}${left_txt}${RESET}}"
print_right "$colored" "$plain"
exit 0
