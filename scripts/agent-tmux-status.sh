#!/usr/bin/env bash
# Show AI coding-agent state (Claude Code / Cursor) on the tmux status bar.
# Called from agent lifecycle hooks. Sets a per-window tmux variable @ai_status
# rendered by window-status-format next to each window/tab.
#
#   working    -> animated green twinkling star (Claude-style ✳), background loop
#   done       -> green dot + macOS notification (terminal-notifier)
#   permission -> yellow dot + macOS notification
#   waiting    -> gray dot, unless a done/permission alert is still unseen
#   idle       -> gray dot
#   clear      -> nothing
#   seen <win> -> called from tmux hooks when a window is visited: turns an
#                 unseen green/yellow dot gray and removes its banner
#
# Usage: agent-tmux-status.sh <working|waiting|permission|done|idle|clear>
#        agent-tmux-status.sh seen <window-id>
#
# Notes:
#  - Prints nothing to stdout (Claude's UserPromptSubmit injects hook stdout
#    into the prompt); the animator is fully detached to /dev/null.
#  - Always exits 0 (Cursor treats exit 2 as "block the action").

if [ "$1" = seen ]; then
  PANE="$2"
else
  [ -z "$TMUX" ] || [ -z "$TMUX_PANE" ] && exit 0
  PANE="$TMUX_PANE"
fi
[ -z "$PANE" ] && exit 0

get_opt()  { tmux show -wv -t "$PANE" "$1" 2>/dev/null; }
stop_anim() {
  local pid; pid="$(get_opt @ai_anim_pid)"
  [ -n "$pid" ] && kill "$pid" 2>/dev/null
  tmux set -wu -t "$PANE" @ai_anim_pid 2>/dev/null
}
set_dot() {
  tmux set -w -t "$PANE" @ai_status "#[fg=colour$1]●#[default] " \; refresh-client -S 2>/dev/null
}
# @ai_attn holds the banner group of an alert you haven't looked at yet.
# Clearing it also pulls that banner out of Notification Center. Returns 1 if
# there was nothing to clear.
clear_attn() {
  local group; group="$(get_opt @ai_attn)"
  [ -n "$group" ] || return 1
  tmux set -wu -t "$PANE" @ai_attn 2>/dev/null
  command -v terminal-notifier >/dev/null 2>&1 \
    && terminal-notifier -remove "$group" >/dev/null 2>&1 &
  return 0
}
# macOS banner; backgrounded so the hook returns immediately. Grouped per pane
# so a newer banner from the same pane replaces the older one. Clicking it
# raises the terminal app and switches the tmux client to this pane.
notify() {
  tmux set -w -t "$PANE" @ai_attn "ai-$PANE" 2>/dev/null
  command -v terminal-notifier >/dev/null 2>&1 || return
  local where client term app tmux_bin
  where="$(tmux display -p -t "$PANE" '#S:#W' 2>/dev/null)"
  read -r client term < <(tmux list-clients -F '#{client_name} #{client_termname}' 2>/dev/null | head -1)
  case "$term" in
    xterm-kitty)   app=net.kovidgoyal.kitty ;;
    xterm-ghostty) app=com.mitchellh.ghostty ;;
    alacritty)     app=org.alacritty ;;
    *)             app=net.kovidgoyal.kitty ;;
  esac
  tmux_bin="$(command -v tmux)"
  terminal-notifier -title "$1" -message "${where:-tmux}" \
    -sound "$2" -group "ai-$PANE" -activate "$app" \
    -execute "$tmux_bin switch-client -c '$client' -t '$PANE' \\; select-window -t '$PANE' \\; select-pane -t '$PANE'" \
    >/dev/null 2>&1 &
}

case "$1" in
  working)
    # Skip if an animator is already running for this window.
    pid="$(get_opt @ai_anim_pid)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then exit 0; fi
    # Agent resumed (e.g. permission granted): the pending alert is stale.
    clear_attn

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
    set_dot 114
    notify "AI agent done" Glass
    ;;
  permission)
    stop_anim
    set_dot 220
    notify "AI agent needs permission" Ping
    ;;
  seen)
    # Runs on every window/pane switch, so bail after one tmux call if idle.
    clear_attn && set_dot 244
    ;;
  waiting)
    # Claude's idle reminder fires ~60s after "done"; keep an unseen alert lit.
    stop_anim
    [ -n "$(get_opt @ai_attn)" ] || set_dot 244
    ;;
  idle)
    stop_anim
    clear_attn
    set_dot 244
    ;;
  *)  # clear / unknown
    stop_anim
    clear_attn
    tmux set -wu -t "$PANE" @ai_status 2>/dev/null
    tmux refresh-client -S 2>/dev/null
    ;;
esac
exit 0
