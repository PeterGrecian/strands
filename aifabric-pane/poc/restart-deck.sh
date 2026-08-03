#!/usr/bin/env bash
# restart-deck.sh — tear down and rebuild the aifabric-pane deck from a mondrian.
#
# Run this from a FRESH terminal (so it inherits the new font / size), NOT from
# inside the old deck. It:
#   1. kills the old `pane` deck (idempotent keepers are safe to restart)
#   2. builds a fresh detached deck, one terminal per mondrian slot
#   3. applies the mondrian's exact geometry
#   4. spawns the real keepers into their slots + tags @strand (clobber-proof)
#   5. sets deck conveniences: status bar off (full-screen), border labels on
#   6. prints the attach command (it does NOT attach — you attach)
#
# Usage:  restart-deck.sh [mondrian-name]     (default: current)
set -uo pipefail

DECK="${DECK:-pane}"   # overridable for testing (e.g. DECK=decktest)
HERE="$(dirname "$(readlink -f "$0")")"
STRANDS="${STRANDS_DIR:-$HOME/strands}"
MON="${1:-current}"
MFILE="$STRANDS/aifabric-pane/mondrians/$MON.mondrian"
[[ -r "$HERE/pane-conductor-helpers.sh" ]] || { echo "restart-deck: helpers not found at $HERE" >&2; exit 1; }
source "$HERE/pane-conductor-helpers.sh"

[[ -r "$MFILE" ]] || { echo "restart-deck: no mondrian '$MON' ($MFILE)" >&2; exit 1; }

# Guard: never run from inside the deck we're about to kill.
if [[ -n "${TMUX:-}" ]]; then
  cur="$(tmux display-message -p '#{session_name}' 2>/dev/null)"
  [[ "$cur" == "$DECK" ]] && { echo "restart-deck: you're INSIDE '$DECK' — run from a plain terminal." >&2; exit 1; }
fi

layout="$(sed -n 's/^layout  *//p' "$MFILE")"
size="$(sed -n 's/^size  *//p' "$MFILE")"
read -r -a slots < <(sed -n 's/^slots  *//p' "$MFILE")
n=${#slots[@]}
echo "restart-deck: mondrian '$MON' — $n slots: ${slots[*]}"

# 1) kill old deck
tmux kill-session -t "$DECK" 2>/dev/null && echo "  killed old '$DECK'" || echo "  ('$DECK' was not running)"

# 2) fresh detached deck sized to the mondrian; make n panes total. Re-even after
#    each split (tiled-layout) so no pane gets too small to split further — that
#    silent-fail is what dropped a slot in testing.
w="${size%x*}"; h="${size#*x}"
tmux new-session -d -s "$DECK" -x "$w" -y "$h"
for ((i=1; i<n; i++)); do
  tmux split-window -t "$DECK:0" 2>/dev/null || tmux split-window -t "$DECK:0" -l 3
  tmux select-layout -t "$DECK:0" tiled >/dev/null 2>&1
done
have=$(tmux list-panes -t "$DECK:0" -F x | wc -l)
[[ "$have" -eq "$n" ]] || echo "restart-deck: WARNING built $have panes, mondrian wants $n" >&2

# 3) exact geometry
tmux select-layout -t "$DECK:0" "$layout" \
  || { echo "restart-deck: select-layout failed (size drift). Deck built flat; re-arrange by hand." >&2; }

# 4) fill slots: walk panes in order; launch keepers, tag @strand. overview/driver
#    /(empty) are structural — the overview runs the curses readout, driver is a
#    shell you type in, (empty) is a spare shell.
# strand -> border colour: read the strand's own `colour` file (hex, no #). The
# driver's strand IS aifabric-pane. overview/(empty) have no strand → no colour.
_slot_colour() {
  case "$1" in
    driver)          cat "$STRANDS/aifabric-pane/colour" 2>/dev/null ;;
    overview|'(empty)'|-|'') : ;;
    *)               cat "$STRANDS/$1/colour" 2>/dev/null ;;
  esac
}

i=0
while IFS= read -r pid; do
  s="${slots[$i]:-}"; i=$((i+1))
  tmux set-option -pt "$pid" @strand "$s"
  # Thin coloured border per strand (bleeds to the pane edges); no text label —
  # each pane's own prompt already says what it's for.
  hex="$(_slot_colour "$s")"
  if [[ -n "$hex" ]]; then
    tmux set-option -pt "$pid" pane-border-style "fg=#$hex"
    tmux set-option -pt "$pid" pane-active-border-style "fg=#$hex,bold"
  fi
  case "$s" in
    overview)
      tmux send-keys -t "$pid" "clear; while true; do python3 $HERE/aifabric-tmux-overview.py; sleep 1; done" C-m
      tmux set-environment -t "$DECK" PANE_OVERVIEW "$pid" ;;
    driver)
      # The driver is where you talk to the conductor — and the conductor of
      # this pane IS the aifabric-pane strand. Launch it here so you drive the
      # deck by talking to aifabric-pane directly.
      tmux send-keys -t "$pid" "aicli --new aifabric-pane" C-m
      tmux set-environment -t "$DECK" PANE_DRIVER "$pid" ;;
    '(empty)'|-|'')
      : ;;  # leave as a spare shell
    *)
      # --new: always launch a fresh keeper into the pane. Without it aicli's
      # de-dupe sees a stale same-title session as "already live", prints
      # "launch another with: aicli --new" and drops us back to a bare shell —
      # leaving the pane empty.
      tmux send-keys -t "$pid" "aicli --new $s" C-m
      tmux set-environment -t "$DECK" "$(_pane_keeper_var "$s")" "$pid" ;;
  esac
done < <(tmux list-panes -t "$DECK:0" -F '#{pane_id}')

# 5) deck conveniences. No border LABELS (pane-border-status off) — the coloured
# border set per-pane above is the strand's identity; the prompt says the rest.
tmux set-option -t "$DECK" status off
tmux set-option -t "$DECK" mouse on
tmux set-option -t "$DECK" pane-border-status off

# F9 minimises the deck's own full-screen terminal-emulator window. Bound in the
# root table (no prefix) so it's a bare keypress. When full-screen the WM never
# sees the key, so tmux shells out to xdotool (matched by the frozen title
# 'pane', robust across rebuilds); wmctrl is the fallback. F11 still toggles
# fullscreen (that one the terminal-emulator handles).
tmux bind-key -T root -N 'minimise the deck window' F9 \
  run-shell "xdotool search --name '^${DECK}\$' windowminimize %@ 2>/dev/null || wmctrl -r ${DECK} -b add,hidden"

# 6) start the overview auto-fit watcher (backgrounded), then tell the human to attach
nohup bash -c "source '$HERE/pane-conductor-helpers.sh'; pane_fit_overview_watch" >/dev/null 2>&1 &

echo "restart-deck: '$DECK' rebuilt from '$MON'. Attach with:"
echo "    tmux attach -t $DECK"
