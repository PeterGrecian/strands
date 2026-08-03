#!/usr/bin/env bash
# pane-conductor-helpers.sh — the conductor's hands.
#
# Sourced into the DRIVER pane by the bootstrap. These wrap the plain tmux CLI
# calls the conductor uses to arrange the STRANDS row. Nothing here is magic —
# it's exactly what a human would type. The conductor (Claude in the driver
# pane) can call these OR emit the underlying tmux commands directly; they exist
# so the "spawn a keeper" gesture is one line, not four.
#
# The bootstrap records pane ids in the tmux session environment:
#   PANE_STRANDS_ROW — the middle strands row (split horizontally per keeper)
#   PANE_OVERVIEW    — the top summary pane
# and each spawned keeper adds:
#   PANE_KEEPER_<strand> = %<pane_id>
#
# IDENTITY IS BY REGISTRY, NOT BY PANE TITLE. Claude Code rewrites the pane
# title to "✳ Claude Code" every turn (the tmux twin of the X11 _NET_WM_NAME
# clobber — see memory pane-title-clobbered-by-claude), so a keeper's pane no
# longer carries its strand name once it's running. We track keeper→pane_id in
# the session environment, which the keeper's process cannot touch, and resolve
# from there. Border titles are decoration for your eye only.

_pane_session=pane

_pane_env() {  # var -> value from the session environment
  tmux show-environment -t "$_pane_session" "$1" 2>/dev/null | cut -d= -f2-
}

# _pane_keeper_var <strand> — the env var name for a keeper's pane id. Strand
# names can contain '-' which is illegal in a shell/tmux env var name, so map
# '-' to '_' (astro-canon -> PANE_KEEPER_astro_canon).
_pane_keeper_var() { printf 'PANE_KEEPER_%s' "${1//-/_}"; }

# _pane_keeper_pane <strand> — resolve a keeper's live pane id from the registry,
# validating it still exists (the human may have killed the pane by hand, leaving
# a stale entry). Echoes the pane id, or nothing if not up. Prunes stale entries.
_pane_keeper_pane() {
  local strand="$1" var pid
  var="$(_pane_keeper_var "$strand")"
  pid="$(_pane_env "$var")"
  [[ -n "$pid" ]] || return 1
  if tmux list-panes -t "$_pane_session" -F '#{pane_id}' | grep -qxF "$pid"; then
    echo "$pid"; return 0
  fi
  tmux set-environment -u -t "$_pane_session" "$var"   # prune stale registry entry
  return 1
}

# pane_spawn_keeper <strand> — put a keeper on the strands row. If it's already
# up, focus it (one keeper, one pane). Otherwise: reuse the empty placeholder if
# the row is still empty, else split the row; then `aicli <strand>` into the
# pane and register it. Echoes the pane id.
pane_spawn_keeper() {
  local strand="$1"
  [[ -n "$strand" ]] || { echo "usage: pane_spawn_keeper <strand>" >&2; return 2; }

  local existing
  if existing="$(_pane_keeper_pane "$strand")"; then
    tmux select-pane -t "$existing"; echo "$existing"; return 0
  fi

  local row placeholder new
  row="$(_pane_env PANE_STRANDS_ROW)"
  [[ -n "$row" ]] || { echo "PANE_STRANDS_ROW not set — is this the pane session?" >&2; return 1; }

  # If no keepers are registered yet, the row is still the single placeholder
  # pane — take it over rather than splitting (avoids a leftover blank pane).
  placeholder="$(_pane_env PANE_ROW_PLACEHOLDER)"
  if [[ -n "$placeholder" ]] && tmux list-panes -t "$_pane_session" -F '#{pane_id}' | grep -qxF "$placeholder"; then
    new="$placeholder"
    tmux set-environment -u -t "$_pane_session" PANE_ROW_PLACEHOLDER  # consumed
    tmux send-keys -t "$new" C-c                    # drop the placeholder shell prompt
    tmux send-keys -t "$new" "clear; exec aicli $strand" C-m
  else
    new="$(tmux split-window -h -t "$row" -P -F '#{pane_id}')"
    tmux send-keys -t "$new" "aicli $strand" C-m
  fi

  tmux select-pane -t "$new" -T "$strand"           # decoration (will be clobbered)
  tmux set-environment -t "$_pane_session" "$(_pane_keeper_var "$strand")" "$new"
  _pane_even_strands_row
  echo "$new"
}

# _pane_even_strands_row — give every keeper pane on the strands row equal width.
# We must NOT use `select-layout even-horizontal`: that re-layouts the WHOLE
# window and flattens the 3-zone frame (verified 2026-08-03). Instead resize each
# strands-row pane to full_width/N by hand, which leaves overview/driver alone.
# The row is identified by shared #{pane_top}, so title-clobber can't confuse it.
_pane_even_strands_row() {
  local row row_top full ids n each
  row="$(_pane_env PANE_STRANDS_ROW)"
  row_top="$(tmux display-message -p -t "$row" '#{pane_top}')"
  full="$(tmux display-message -p -t "$_pane_session" '#{window_width}')"
  mapfile -t ids < <(tmux list-panes -t "$_pane_session" \
      -F '#{pane_id} #{pane_top}' | awk -v t="$row_top" '$2==t {print $1}')
  n=${#ids[@]}; (( n > 0 )) || return 0
  each=$(( full / n ))
  local p; for p in "${ids[@]}"; do tmux resize-pane -t "$p" -x "$each" 2>/dev/null || true; done
}

# pane_drop_keeper <strand> — kill the keeper's pane (tear-down). Keepers are
# idempotent so this is safe; you lose nothing but the live session.
pane_drop_keeper() {
  local strand="$1" p
  if ! p="$(_pane_keeper_pane "$strand")"; then
    echo "no keeper '$strand' up" >&2; return 1
  fi
  tmux kill-pane -t "$p"
  tmux set-environment -u -t "$_pane_session" "$(_pane_keeper_var "$strand")"
  _pane_even_strands_row   # re-even whatever remains (row-only, frame-safe)
}

# pane_list_keepers — which keepers are up, from the registry (title-proof).
pane_list_keepers() {
  local any=0 line var strand pid
  while IFS= read -r line; do
    case "$line" in
      PANE_KEEPER_*=*)
        var="${line%%=*}"; pid="${line#*=}"
        strand="${var#PANE_KEEPER_}"; strand="${strand//_/-}"
        # only report if the pane is still live
        if tmux list-panes -t "$_pane_session" -F '#{pane_id}' | grep -qxF "$pid"; then
          printf '  %-16s %s\n' "$strand" "$pid"; any=1
        fi
        ;;
    esac
  done < <(tmux show-environment -t "$_pane_session" 2>/dev/null | grep '^PANE_KEEPER_')
  (( any )) || echo '  (no keepers up)'
}
