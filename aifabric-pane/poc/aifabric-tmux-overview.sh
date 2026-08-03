#!/usr/bin/env bash
# aifabric-tmux POC — the OVERVIEW readout. A dumb repainting loop that SUMMARISES
# rather than lists: a headline "N live of TOTAL", only the strands that have
# unread mail (actionable, not the whole roster), and a compact cleft usage line.
# Independent of any conductor — pure status. Ctrl-C to stop.
set -uo pipefail

STRANDS_ROOT="${STRANDS_DIR:-/home/peter/strands}"
SM="$(command -v strand-mailbox || echo /home/peter/aifabric/bin/strand-mailbox)"
CLEFT="$(command -v cleft || true)"
STRAND_PS="$(command -v strand-ps || true)"

total_strands() {  # count strand dirs (have a CLAUDE.md), skip archive/.template
  local n=0 d
  for d in "$STRANDS_ROOT"/*/; do
    [[ -f "$d/CLAUDE.md" ]] || continue
    n=$((n+1))
  done
  echo "$n"
}

live_strands() {  # names of currently-running strand sessions, space-separated
  [[ -n "$STRAND_PS" ]] || { echo ""; return; }
  "$STRAND_PS" 2>/dev/null | awk 'NR>1{print $4}' | sort -u | tr '\n' ' '
}

mail_count() {  # strand -> pending count (0 if none)
  local n; n="$("$SM" peek "$1" 2>/dev/null | sed -n 's/.*: \([0-9]\+\) pending.*/\1/p')"
  echo "${n:-0}"
}

# strands to CHECK for mail (POC set; real version would scan all spools)
MAIL_WATCH=(ansible housekeeping astro-storage astro-science aifabric ubersitrep rackinabox)

cleft_line() {  # one compact line from cleft, or a dash if unavailable
  [[ -n "$CLEFT" ]] || { echo "cleft: (not found)"; return; }
  local out used rate warn
  out="$("$CLEFT" 2>/dev/null)" || { echo "cleft: (unavailable)"; return; }
  used="$(printf '%s\n' "$out" | sed -n 's/.*Used:[[:space:]]*\([0-9]\+%\).*/\1/p' | head -1)"
  rate="$(printf '%s\n' "$out" | sed -n 's/.*Current rate:[[:space:]]*\([0-9.]\+ %\/hr\).*/\1/p' | head -1)"
  warn="$(printf '%s\n' "$out" | sed -n 's/.*\(Quota runs out in [^—]*\).*/\1/p' | head -1)"
  printf '5h: %s used, %s' "${used:-?}" "${rate:-?}"
  [[ -n "$warn" ]] && printf '   \033[1;31m⚠ %s\033[0m' "$warn"
  echo
}

while true; do
  clear
  total="$(total_strands)"
  live="$(live_strands)"; live="${live% }"
  nlive=0; [[ -n "$live" ]] && nlive="$(wc -w <<<"$live")"

  printf '\033[1m aifabric plane\033[0m   %s\n' "$(date '+%a %H:%M:%S')"
  printf '\n'
  printf '  \033[1m%d strand%s live\033[0m of %d' "$nlive" "$([[ $nlive == 1 ]] || echo s)" "$total"
  [[ -n "$live" ]] && printf '   \033[36m[%s]\033[0m' "$live"
  printf '\n'

  # only surface strands WITH mail (actionable) — not the whole list
  mailbits=""
  for s in "${MAIL_WATCH[@]}"; do
    m="$(mail_count "$s")"; [[ "$m" -gt 0 ]] && mailbits+="  $s $m"
  done
  if [[ -n "$mailbits" ]]; then
    printf '  \033[1;33munread mail:\033[0m%s\n' "$mailbits"
  else
    printf '  \033[2mno unread mail\033[0m\n'
  fi

  printf '  %s' "$(cleft_line)"
  printf '\n  \033[2msuggestions: (POC — none yet)\033[0m\n'
  sleep 5
done
