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

# _pane_term_strand <pane_id> — what strand is ACTUALLY running in this term?
# Reads the term's tty and finds the `aicli <strand>` in its process group. This
# is GROUND TRUTH: argv cannot be clobbered by the app the way a title can, and
# unlike the registry it is re-read live rather than written once at spawn.
# Echoes the strand name, or nothing if no aicli is running there (bare shell).
_pane_term_strand() {
  local pid="$1" tty
  tty="$(tmux display-message -pt "$pid" '#{pane_tty}' 2>/dev/null)" || return 1
  [[ -n "$tty" ]] || return 1
  # last aicli wins: if someone ran `aicli hardware` over an old session, the
  # newest is what's in front of you. Skip flags (--new etc) to find the strand.
  ps -t "$tty" -o args= 2>/dev/null | awk '
    /\/aicli( |$)/ {
      for (i = 1; i <= NF; i++)
        if ($i ~ /aicli$/) {
          for (j = i + 1; j <= NF; j++)
            if ($j !~ /^-/) { found = $j; break }
          break
        }
    }
    END { if (found != "") print found }'
}

# _pane_verify <strand> <pane_id> — does the term actually run this strand?
# Returns 0 if it matches (or if we cannot tell — a bare shell is not proof of
# drift, e.g. the keeper is still booting). Returns 1 ONLY on a real mismatch,
# with the truth on stdout, so callers can refuse rather than act on the wrong term.
_pane_verify() {
  local strand="$1" pid="$2" actual
  actual="$(_pane_term_strand "$pid")"
  [[ -n "$actual" ]] || return 0            # nothing running: unproven, not wrong
  [[ "$actual" == "$strand" ]] && return 0
  echo "$actual"; return 1
}

# _pane_keeper_pane <strand> — resolve a keeper's live pane id from the registry,
# validating it still exists (the human may have killed the pane by hand, leaving
# a stale entry). Echoes the pane id, or nothing if not up. Prunes stale entries.
#
# IDENTITY DIVERGENCE GUARD (added 2026-08-10, second occurrence of the bug).
# The registry says WHERE a term is; it is written once at spawn and says nothing
# about what runs there NOW. Type `aicli hardware` into a live term's shell and
# the tag still reads the strand it was spawned with — silently, for a whole
# session (2026-08-09: we believed astro-storage was backfilling; it was
# home-automation. 2026-08-10: %5 tagged home-automation was running hardware and
# a resize nearly hit the wrong strand). So: VERIFY AGAINST THE PROCESS, REFUSE ON
# MISMATCH. Never act on a term whose identity we know to be wrong.
_pane_keeper_pane() {
  local strand="$1" var pid actual
  var="$(_pane_keeper_var "$strand")"
  pid="$(_pane_env "$var")"
  [[ -n "$pid" ]] || return 1
  if tmux list-panes -t "$_pane_session" -F '#{pane_id}' | grep -qxF "$pid"; then
    if actual="$(_pane_verify "$strand" "$pid")"; then
      echo "$pid"; return 0
    fi
    echo "pane: IDENTITY DIVERGENCE — registry says '$strand' is $pid, but $pid is running '$actual'." >&2
    echo "pane: refusing to act on the wrong term. Fix with: pane reconcile" >&2
    return 3
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

# The overview terminal is curses and can't resize its own pane, so it PUBLISHES
# the row count it needs to <strand>/.overview-rows on each redraw. These sync the
# pane height to that number, so the overview is always "just tall enough".
_pane_overview_rows_file="${STRANDS_DIR:-$HOME/strands}/aifabric-pane/.overview-rows"

# pane_fit_overview — one-shot: resize the overview pane to its published height.
pane_fit_overview() {
  local ov want cur
  ov="$(_pane_env PANE_OVERVIEW)"; [[ -n "$ov" ]] || return 1
  [[ -r "$_pane_overview_rows_file" ]] || return 0
  want="$(<"$_pane_overview_rows_file")"; [[ "$want" =~ ^[0-9]+$ ]] || return 0
  cur="$(tmux display-message -t "$ov" -p '#{pane_height}' 2>/dev/null)"
  [[ "$want" != "$cur" ]] && tmux resize-pane -t "$ov" -y "$want" 2>/dev/null
}

# pane_fit_overview_watch — background loop keeping the overview fitted. Cheap:
# only resizes when the published number changes. Start once from the bootstrap.
pane_fit_overview_watch() {
  while tmux has-session -t "$_pane_session" 2>/dev/null; do
    pane_fit_overview
    sleep 2
  done
}
