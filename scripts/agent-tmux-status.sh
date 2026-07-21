#!/usr/bin/env bash
# Show AI coding-agent state (Claude Code / Cursor) on the tmux status bar.
# Called from agent lifecycle hooks. Sets a per-window tmux variable @ai_status
# to a colored dot that window-status-format renders next to each window/tab.
#
# Usage: agent-tmux-status.sh <working|waiting|done|idle|clear>
#
# Notes:
#  - Prints nothing to stdout: Claude's UserPromptSubmit hook injects hook stdout
#    into the prompt, so this must stay silent.
#  - Always exits 0: Cursor treats exit 2 as "block the action"; we never block.

# Only act when running inside a tmux pane.
if [ -z "$TMUX" ] || [ -z "$TMUX_PANE" ]; then
  exit 0
fi

# Blinking green while actively processing, gray for every other state.
# (#[default] restores the window-status style after the dot.)
case "$1" in
  working)            v="#[fg=colour46,blink]●#[default] " ;;   # live green, blinking
  waiting|done|idle)  v="#[fg=colour244]●#[default] " ;;        # gray
  *)                  v="" ;;                                    # clear / unknown
esac

if [ -z "$v" ]; then
  tmux set -wu -t "$TMUX_PANE" @ai_status 2>/dev/null   # unset the window option
else
  tmux set -w  -t "$TMUX_PANE" @ai_status "$v" 2>/dev/null
fi

tmux refresh-client -S 2>/dev/null   # redraw status line immediately
exit 0
