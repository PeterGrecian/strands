#!/usr/bin/env bash
# mondrian — save / load an aifabric-pane page arrangement (a "mondrian").
#
# WHAT A LAYOUT IS (design, 2026-08-03): tmux already emits an exact geometry
# string (`#{window_layout}`, e.g. `da1d,237x57,0,0{...}`) that `select-layout`
# restores precisely — so the SHAPE is a solved problem. What tmux does NOT store
# is WHICH STRAND sits in each slot (its leaves are ephemeral pane-ids). So a
# layout file = tmux's string + our slot→strand map (the @strand of each leaf, in
# tmux's leaf order). On load we spawn the strands, apply the geometry string,
# then walk the panes in order and re-tag/-place each strand.
#
# SCOPE: two levels —
#   named mondrians   $MONDRIAN_DIR/<name>.mondrian   (reusable page arrangements)
#   deck snapshot   $MONDRIAN_DIR/deck.mondrian     (whole current state; `save-deck`)
#
# Usage:
#   mondrian save <name> [page]     save one page as a named mondrian (default page 0)
#   mondrian load <name> [page]     rebuild a page from a named mondrian
#   mondrian save-deck              snapshot every page of the deck
#   mondrian list                   list saved mondrians
#
# A layout file is line-based, easy to read/edit:
#   deck    pane
#   page    0
#   size    237x57
#   layout  da1d,237x57,0,0{...}
#   slots   overview astro-science (empty) ansible ubersitrep astro-storage driver
set -uo pipefail

_deck=pane
MONDRIAN_DIR="${PANE_MONDRIAN_DIR:-$HOME/strands/aifabric-pane/mondrians}"
HELPERS="$(dirname "$(readlink -f "$0")")/pane-conductor-helpers.sh"
[[ -r "$HELPERS" ]] && source "$HELPERS"

mkdir -p "$MONDRIAN_DIR"

die() { echo "mondrian: $*" >&2; exit 1; }

# strand of a pane: prefer @strand (clobber-proof); '-' if unset.
_strand_of() { tmux display-message -pt "$1" '#{@strand}' 2>/dev/null || echo -; }

save() {  # <name> [page]
  local name="$1" page="${2:-0}" file
  [[ -n "$name" ]] || die "usage: save <name> [page]"
  file="$MONDRIAN_DIR/$name.mondrian"
  local layout size slots=()
  layout="$(tmux list-windows -t "$_deck:$page" -F '#{window_layout}' | head -1)"
  size="$(tmux display-message -t "$_deck:$page" -p '#{window_width}x#{window_height}')"
  [[ -n "$layout" ]] || die "no such page: $page"
  # slots: @strand of each pane, IN tmux's pane order (= layout leaf order)
  while IFS= read -r s; do slots+=("${s:--}"); done \
    < <(tmux list-panes -t "$_deck:$page" -F '#{@strand}')
  {
    echo "deck    $_deck"
    echo "page    $page"
    echo "size    $size"
    echo "layout  $layout"
    echo "slots   ${slots[*]}"
  } > "$file"
  echo "saved '$name' ($page: ${#slots[@]} slots) -> $file"
}

load() {  # <name> [page]
  local name="$1" page="${2:-0}" file
  file="$MONDRIAN_DIR/$name.mondrian"
  [[ -r "$file" ]] || die "no such layout: $name"
  page="${2:-$(sed -n 's/^page  *//p' "$file")}"
  local layout slots
  layout="$(sed -n 's/^layout  *//p' "$file")"
  read -r -a slots < <(sed -n 's/^slots  *//p' "$file")
  [[ -n "$layout" ]] || die "layout string missing in $file"

  # 1) ensure the page has exactly ${#slots} panes: spawn keepers for the named
  #    strands (skip overview/driver/(empty)/- which are structural, not keepers).
  #    We (re)build onto page $page; assumes it exists with at least 1 pane.
  local s
  for s in "${slots[@]}"; do
    case "$s" in overview|driver|'(empty)'|-|'') continue;; esac
    _pane_keeper_pane "$s" >/dev/null 2>&1 || pane_spawn_keeper "$s" >/dev/null
  done

  # 2) apply the exact geometry
  tmux select-layout -t "$_deck:$page" "$layout" \
    || die "select-layout failed (terminal size differs from saved?)"

  # 3) walk panes in order, re-tag @strand from the slot list so borders/identity
  #    match the saved arrangement.
  local i=0 pid
  while IFS= read -r pid; do
    [[ $i -lt ${#slots[@]} ]] && tmux set-option -pt "$pid" @strand "${slots[$i]}"
    i=$((i+1))
  done < <(tmux list-panes -t "$_deck:$page" -F '#{pane_id}')
  echo "loaded '$name' onto page $page (${#slots[@]} slots)"
}

save_deck() {
  local pages p
  mapfile -t pages < <(tmux list-windows -t "$_deck" -F '#{window_index}')
  for p in "${pages[@]}"; do save "deck-page$p" "$p"; done
  echo "deck snapshot: ${#pages[@]} page(s)"
}

list_layouts() {
  local f; for f in "$MONDRIAN_DIR"/*.mondrian; do
    [[ -e "$f" ]] || { echo "(no mondrians in $MONDRIAN_DIR)"; return; }
    printf '  %-20s %s\n' "$(basename "$f" .mondrian)" "$(sed -n 's/^slots  *//p' "$f")"
  done
}

cmd="${1:-}"; shift || true
case "$cmd" in
  save)      save "$@" ;;
  load)      load "$@" ;;
  save-deck) save_deck ;;
  list)      list_layouts ;;
  *) die "usage: mondrian {save <name> [page]|load <name> [page]|save-deck|list}" ;;
esac
