#!/usr/bin/env bash
# Claude Code status line: the claude.ai "Current session" usage bar.
# Claude pipes session JSON on stdin; rate_limits.five_hour holds the 5-hour
# window's used % and reset time (subscribers only, after the first reply).
#
#   Current session  ██░░░░░░░░░░░░░░░░░░  4% used · resets in 4 hr 53 min
#
# Usage (settings.json): "statusLine": {"type": "command", "command": "<this script>"}

BAR_WIDTH=20
BLUE=$'\e[38;5;33m'
TRACK=$'\e[38;5;238m'
DIM=$'\e[38;5;245m'
RESET=$'\e[0m'

read -r pct resets_at < <(jq -r '
  .rate_limits.five_hour // {} |
  "\(.used_percentage // "") \(.resets_at // "")"' 2>/dev/null)

if [ -z "$pct" ]; then
  printf '%sCurrent session  —%s' "$DIM" "$RESET"
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
bar="${BLUE}${done_cells}${TRACK}${todo_cells}${RESET}"

reset_txt=""
if [ -n "$resets_at" ]; then
  resets_at=${resets_at%.*}
  [ "$resets_at" -gt 1000000000000 ] && resets_at=$(( resets_at / 1000 ))
  left=$(( resets_at - $(date +%s) ))
  if [ "$left" -gt 0 ]; then
    h=$(( left / 3600 )); m=$(( left % 3600 / 60 ))
    if [ "$h" -gt 0 ]; then reset_txt="resets in $h hr $m min"; else reset_txt="resets in $m min"; fi
    reset_txt="${DIM} · ${reset_txt}${RESET}"
  fi
fi

printf '%sCurrent session%s  %s  %s%% used%s' "$DIM" "$RESET" "$bar" "$pct_int" "$reset_txt"
exit 0
