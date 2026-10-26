#!/usr/bin/env bash
# claude.ai "Current session" usage bar on the tmux status bar.
#
#   [ 1% 4h56m ]   (gray bar, % and countdown inside, fill shown by background)
#
# Two modes:
#  - Claude Code statusLine command (no args): Claude pipes session JSON on
#    stdin; rate_limits.five_hour holds the 5-hour window's used % and reset
#    time (subscribers only, after the first reply). Stash them in global tmux
#    options and print nothing, so Claude shows no status row of its own.
#  - `claude-statusline.sh tmux`: called from status-right via #(...); renders
#    the stashed values. The countdown is recomputed on every status refresh,
#    and the bar disappears once the window has reset.
#
# Usage (settings.json): "statusLine": {"type": "command", "command": "<this script>"}
#        (tmux.conf):    set -g status-right '#(<this script> tmux) ...'

BAR_WIDTH=10

if [ "$1" != tmux ]; then
  [ -z "$TMUX" ] && exit 0
  read -r pct resets_at < <(jq -r '
    .rate_limits.five_hour // {} |
    "\(.used_percentage // "") \(.resets_at // "")"' 2>/dev/null)
  [ -z "$pct" ] && exit 0
  resets_at=${resets_at%.*}
  [ -n "$resets_at" ] && [ "$resets_at" -gt 1000000000000 ] && resets_at=$(( resets_at / 1000 ))
  tmux set -g @ai_usage_pct "$pct" \; set -g @ai_usage_reset "$resets_at" 2>/dev/null
  exit 0
fi

pct="$(tmux show -gv @ai_usage_pct 2>/dev/null)"
resets_at="$(tmux show -gv @ai_usage_reset 2>/dev/null)"
[ -z "$pct" ] && exit 0

left_txt=""
if [ -n "$resets_at" ]; then
  left=$(( resets_at - $(date +%s) ))
  [ "$left" -le 0 ] && exit 0   # window reset since Claude last reported
  h=$(( left / 3600 )); m=$(( left % 3600 / 60 ))
  if [ "$h" -gt 0 ]; then left_txt="${h}h${m}m"; else left_txt="${m}m"; fi
fi

pct_int=$(printf '%.0f' "$pct")
filled=$(( (pct_int * BAR_WIDTH + 50) / 100 ))
# Any usage at all shows at least one cell, like the web bar's rounded cap.
[ "$pct_int" -gt 0 ] && [ "$filled" -eq 0 ] && filled=1
[ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH

# The % and reset countdown are printed inside the bar: centre them, then split at
# the fill point so each half gets its own background.
text="${pct_int}%${left_txt:+ $left_txt}"
pad=$(( (BAR_WIDTH - ${#text}) / 2 ))
[ "$pad" -lt 0 ] && pad=0
label="$(printf '%*s%s%*s' "$pad" '' "$text" "$BAR_WIDTH" '')"
label="${label:0:BAR_WIDTH}"

printf '#[fg=colour235,bg=colour246]%s#[fg=colour250,bg=colour238]%s#[default] ' \
  "${label:0:filled}" "${label:filled}"
exit 0
