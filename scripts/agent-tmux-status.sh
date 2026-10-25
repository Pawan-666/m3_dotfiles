#!/usr/bin/env bash
# Show AI coding-agent state (Claude Code / Cursor) on the tmux status bar.
# Called from agent lifecycle hooks. Sets a per-window tmux variable @ai_status
# rendered by window-status-format next to each window/tab.
#
#   working -> animated green twinkling star (Claude-style ✳), background loop
#   done    -> static gray dot + macOS notification (terminal-notifier)
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
    # Skip if an animator is already running for this window.
    pid="$(get_opt @ai_anim_pid)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then exit 0; fi

    # Detached animator: twinkling green Claude-style star. It SELF-REGISTERS its
    # own pid first (no parent/child race), then loops while it still owns the
    # window; a newer animator taking over makes this one reap itself.
    {
      tmux set -w -t "$PANE" @ai_anim_pid "$BASHPID" 2>/dev/null
      frames=(✳ ✶ ✻ ✽ ❉ ✽ ✻ ✶)          # larger star glyphs, gentle pulse
      colors=(208 214 216 209 203 209 216 214)   # warm orange→coral shimmer
      n=${#frames[@]}
      m=${#colors[@]}
      i=0
      # Each frame is a single tmux call; the ownership/pane-alive checks cost two
      # more forks, so they run every 4th frame (~2s) rather than every frame.
      while :; do
        if [ $((i % 4)) = 0 ]; then
          [ "$(tmux show -wv -t "$PANE" @ai_anim_pid 2>/dev/null)" = "$BASHPID" ] || break
          tmux display -p -t "$PANE" '' >/dev/null 2>&1 || break
        fi
        tmux set -w -t "$PANE" @ai_status "#[fg=colour${colors[i % m]},bold]${frames[i % n]}#[default] " \; \
          refresh-client -S 2>/dev/null || break
        i=$((i + 1))
        sleep 0.5
      done
      # Clear our registration if we still own it.
      [ "$(tmux show -wv -t "$PANE" @ai_anim_pid 2>/dev/null)" = "$BASHPID" ] \
        && tmux set -wu -t "$PANE" @ai_anim_pid 2>/dev/null
    } >/dev/null 2>&1 &
    ;;
  done)
    stop_anim
    tmux set -w -t "$PANE" @ai_status "#[fg=colour244]●#[default] " 2>/dev/null
    tmux refresh-client -S 2>/dev/null
    # macOS banner; backgrounded so the hook returns immediately.
    if command -v terminal-notifier >/dev/null 2>&1; then
      where="$(tmux display -p -t "$PANE" '#S:#W' 2>/dev/null)"
      terminal-notifier -title "AI agent done" -message "${where:-tmux}" \
        -sound Glass -group "ai-$PANE" >/dev/null 2>&1 &
    fi
    ;;
  waiting|idle)
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
