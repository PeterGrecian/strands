#!/usr/bin/env bash
# aifabric-tmux POC — build the three-zone plane from OUTSIDE tmux (conductor
# model: we drive via the CLI, we never `attach`). Run this, then open a
# full-screen terminal and: tmux attach -t plane
#
# Zones (top to bottom):
#   OVERVIEW  — live-refreshed readout (strands + unread-mail flags)
#   STRANDS   — panes side by side (POC: labelled dummy shells, coloured borders;
#               no real aicli sessions burned — proves layout + identity only)
#   DRIVER    — full-width shell you type conductor/tmux commands into
#
# Robust against tmux's index renumbering: we capture each pane's unique ID
# (%N) as we create it and target those, never positional indices.
#
# Throwaway: `tmux kill-session -t plane` to remove it.
set -euo pipefail

SESSION=plane
HERE="$(cd "$(dirname "$0")" && pwd)"
OVERVIEW="$HERE/aifabric-tmux-overview.sh"
# Panes host KEEPER strands: keepers are idempotent (steady-state maintain+answer,
# no fragile in-progress trajectory), so they're safe to spin up / tear down /
# restart on the plane. Builders have a trajectory you'd disrupt — keep those in
# their own window. (Keeper = blurb starts with "Keeps"; same signal aicli uses.)
PANE_STRANDS=(ansible pifleet)        # two keepers, side by side

tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION"

# Start detached with a generous virtual size; the real size follows your
# terminal when you attach.
tmux new-session -d -s "$SESSION" -x 220 -y 55 -n plane

# The initial single pane becomes the OVERVIEW (top).
overview_p="$(tmux display-message -p -t "$SESSION" '#{pane_id}')"

# Split a big WORK area below the overview (-l sizes the NEW/lower pane).
work_p="$(tmux split-window -v -t "$overview_p" -l 45 -P -F '#{pane_id}')"

# From the work area, peel a full-width DRIVER off the bottom.
driver_p="$(tmux split-window -v -t "$work_p" -l 7 -P -F '#{pane_id}')"

# The work area (work_p) is now the STRANDS row; split it horizontally in two.
left_p="$work_p"
right_p="$(tmux split-window -h -t "$left_p" -P -F '#{pane_id}')"

# --- content ----------------------------------------------------------------
tmux send-keys -t "$overview_p" "exec bash '$OVERVIEW'" C-m

tmux send-keys -t "$driver_p" \
  "clear; echo '=== DRIVER — type to the conductor (POC: raw tmux/shell) ==='; exec bash" C-m

label_strand() {  # pane_id strand_name
  tmux select-pane -t "$1" -T "$2"
  tmux send-keys -t "$1" \
    "clear; printf '  \\033[1mstrand: %s\\033[0m\\n  (dummy shell — real POC would be: aicli %s)\\n' '$2' '$2'; exec bash" C-m
}
label_strand "$left_p"  "${PANE_STRANDS[0]}"
label_strand "$right_p" "${PANE_STRANDS[1]}"

# --- identity: per-pane border titles + colours (transparency can't tint
# per-pane; borders carry identity — see idea note snag 2) --------------------
tmux set -t "$SESSION" pane-border-status top
tmux set -t "$SESSION" pane-border-format ' #{pane_title} '
tmux select-pane -t "$overview_p" -T 'OVERVIEW'
tmux select-pane -t "$driver_p"   -T 'DRIVER'
tmux set -t "$SESSION" pane-active-border-style 'fg=colour39,bold'
tmux set -t "$SESSION" pane-border-style 'fg=colour240'
tmux set -t "$SESSION" status off      # hide default tmux clutter for the POC

# focus the driver — that's where you live
tmux select-pane -t "$driver_p"

# report the pane map so we can verify the layout from outside
echo "plane built:"
tmux list-panes -t "$SESSION" -F '  #{pane_title}: #{pane_width}x#{pane_height} at (#{pane_left},#{pane_top})'
echo
echo "Open a FULL-SCREEN terminal and run:   tmux attach -t $SESSION"
echo "Remove it later with:                  tmux kill-session -t $SESSION"
