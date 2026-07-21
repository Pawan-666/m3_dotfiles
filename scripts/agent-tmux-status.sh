#!/usr/bin/env bash
# Show AI coding-agent state (Claude Code / Cursor) on the tmux status bar.
# Called from agent lifecycle hooks. Sets a per-window tmux variable @ai_status
# rendered by window-status-format next to each window/tab.
#
#   working -> animated green mosaic spinner (background loop)
#   other   -> static gray dot
#   clear   -> nothing
#
# Usage: agent-tmux-status.sh <working|waiting|done|idle|clear>
#
# Notes:
#  - Prints nothing to stdout (Claude's UserPromptSubmit injects hook stdout
#    into the prompt); the animator is fully detached to /dev/null.
#  - Always exits 0 (Cursor treats exit 2 as "block the action").

[ -z "$TMUX" ] || [ -z "$TMUX_PANE" ] && exit 0

PANE="$TMUX_PANE"

get_opt()  { tmux show -wv -t "$PANE" "$1" 2>/dev/null; }
stop_anim() {
  local pid; pid="$(get_opt @ai_anim_pid)"
  [ -n "$pid" ] && kill "$pid" 2>/dev/null
  tmux set -wu -t "$PANE" @ai_anim_pid 2>/dev/null
}

case "$1" in
  working)
    # If an animator is already running for this window, leave it be.
    pid="$(get_opt @ai_anim_pid)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then exit 0; fi

    # Detached mosaic animator: cycles a green braille spinner until the state
    # changes (a new pid takes over) or the pane disappears.
    {
      frames=(◐ ◓ ◑ ◒)
      n=${#frames[@]}
      i=0
      while :; do
        tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qx "$PANE" || break
        [ "$(tmux show -wv -t "$PANE" @ai_anim_pid 2>/dev/null)" = "$BASHPID" ] || break
        tmux set -w -t "$PANE" @ai_status "#[fg=colour46]${frames[i % n]}#[default] " 2>/dev/null
        tmux refresh-client -S 2>/dev/null
        i=$((i + 1))
        sleep 0.12
      done
    } >/dev/null 2>&1 &
    tmux set -w -t "$PANE" @ai_anim_pid "$!" 2>/dev/null
    ;;
  waiting|done|idle)
    stop_anim
    tmux set -w -t "$PANE" @ai_status "#[fg=colour244]●#[default] " 2>/dev/null
    tmux refresh-client -S 2>/dev/null
    ;;
  *)  # clear / unknown
    stop_anim
    tmux set -wu -t "$PANE" @ai_status 2>/dev/null
    tmux refresh-client -S 2>/dev/null
    ;;
esac
exit 0
