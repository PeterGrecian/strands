#!/usr/bin/env bash
# aifabric-pane — self-hosting build (2026-08-03 model).
#
# The conductor LIVES IN the driver pane and puppeteers the panes above it with
# the plain tmux CLI. There is no nesting and no re-attach: a process inside a
# pane is not a tmux client, so there's ONE tmux server and ONE prefix (yours).
#
# What this script does (the human bootstrap — run ONCE, from outside):
#   1. Build the empty 3-zone frame:  OVERVIEW (top) / STRANDS row (middle,
#      starts empty) / DRIVER (bottom).
#   2. Launch the CONDUCTOR into the driver pane as a real `aicli aifabric-pane`
#      Claude session (self-hosting: the conductor is now in the pane).
#   3. Print the attach line. You `tmux attach -t pane` in a full-screen
#      terminal; from then on you talk to the conductor in the driver pane and it
#      spawns/arranges keepers itself.
#
# Adding a keeper is NOT special: the conductor just runs, e.g.
#     pane_spawn_keeper ansible          # helper below, sourced into the driver
# which is only:
#     tmux split-window -h -t <strands-row> -P -F '#{pane_id}'   # new pane
#     tmux send-keys   -t <new-pane> 'aicli ansible' C-m         # aicli into it
#
# Throwaway: `tmux kill-session -t pane` to remove it.
set -euo pipefail

SESSION=pane
HERE="$(cd "$(dirname "$0")" && pwd)"
OVERVIEW="$HERE/aifabric-tmux-overview.sh"
STRAND_DIR="/home/peter/strands/aifabric-pane"
HELPERS="$HERE/pane-conductor-helpers.sh"

# --- guard: never run this FROM inside tmux (would nest the bootstrap) --------
if [[ -n "${TMUX:-}" ]]; then
  echo "Refusing to run inside tmux — bootstrap the pane from a plain terminal." >&2
  echo "(The conductor lives in the pane; the bootstrap must not itself be a client.)" >&2
  exit 1
fi

tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION"

# Start detached with a generous virtual size; real size follows your terminal.
tmux new-session -d -s "$SESSION" -x 220 -y 55 -n pane

# The initial single pane becomes the OVERVIEW (top).
overview_p="$(tmux display-message -p -t "$SESSION" '#{pane_id}')"
# A big WORK area below the overview (-l sizes the NEW/lower pane).
work_p="$(tmux split-window -v -t "$overview_p" -l 45 -P -F '#{pane_id}')"
# Peel a full-width DRIVER off the bottom.
driver_p="$(tmux split-window -v -t "$work_p" -l 8 -P -F '#{pane_id}')"

# work_p is now the STRANDS row — it starts EMPTY (one placeholder pane the
# conductor will replace/split as it spawns keepers). Record its id where the
# conductor can read it.
strands_row_p="$work_p"
tmux set-environment -t "$SESSION" PANE_STRANDS_ROW    "$strands_row_p"
tmux set-environment -t "$SESSION" PANE_OVERVIEW       "$overview_p"
# The row starts as ONE placeholder pane; the first pane_spawn_keeper takes it
# over (rather than splitting) so there's no leftover blank pane.
tmux set-environment -t "$SESSION" PANE_ROW_PLACEHOLDER "$strands_row_p"

# --- content ------------------------------------------------------------------
# OVERVIEW: the live summary readout.
tmux send-keys -t "$overview_p" "exec bash '$OVERVIEW'" C-m

# STRANDS row placeholder — a hint that the conductor will fill this.
tmux send-keys -t "$strands_row_p" \
  "clear; printf '  \\033[2m(strands row — the conductor spawns keepers here)\\033[0m\\n'; exec bash" C-m

# DRIVER: launch the CONDUCTOR as a real aicli session (self-hosting). The
# helpers are sourced first so the conductor (and you) have pane_spawn_keeper on
# hand; then aicli takes over the pane.
#
# `-N`: FORCE a new instance. Plain `aicli aifabric-pane` RAISES an already-live
# aifabric-pane window instead of launching (and the raise yanks that other
# window to the foreground, then exits — killing this pane). See STATE.md finding
# 2026-08-03. The conductor in THIS pane is the authoritative one; any other
# aifabric-pane session is just a curation/editing session, they don't conflict.
tmux send-keys -t "$driver_p" \
  "clear; source '$HELPERS'; echo '=== DRIVER — conductor (aicli -N aifabric-pane) ==='; exec aicli -N aifabric-pane" C-m

# --- identity: per-pane border titles + colours -------------------------------
tmux set -t "$SESSION" pane-border-status top
tmux set -t "$SESSION" pane-border-format ' #{pane_title} '
tmux select-pane -t "$overview_p"     -T 'OVERVIEW'
tmux select-pane -t "$strands_row_p"  -T 'strands'
tmux select-pane -t "$driver_p"       -T 'DRIVER — conductor'
tmux set -t "$SESSION" pane-active-border-style 'fg=colour39,bold'
tmux set -t "$SESSION" pane-border-style 'fg=colour240'
tmux set -t "$SESSION" status off

tmux select-pane -t "$driver_p"   # you live in the driver

echo "pane built (self-hosting):"
tmux list-panes -t "$SESSION" -F '  #{pane_title}: #{pane_width}x#{pane_height} at (#{pane_left},#{pane_top})'
echo
echo "Open a FULL-SCREEN terminal and run:   tmux attach -t $SESSION"
echo "Remove it later with:                  tmux kill-session -t $SESSION"
