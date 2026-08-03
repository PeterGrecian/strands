#!/bin/bash
# Find git repos under ~ (depth-limited) and report divergence vs upstream.
set -u
shopt -s nullglob
# Search common locations for repos
roots=("$HOME")
found=$(find "${roots[@]}" -maxdepth 3 -type d -name .git 2>/dev/null | sed 's#/.git$##' | sort -u)
if [ -z "$found" ]; then
  echo "  (no git repos found under ${roots[*]})"
  exit 0
fi
while IFS= read -r repo; do
  [ -z "$repo" ] && continue
  cd "$repo" || continue
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  # upstream tracking
  up=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  if [ -z "$up" ]; then
    printf "  %-40s %-20s NO-UPSTREAM  dirty=%s\n" "${repo#$HOME/}" "$branch" "$dirty"
    continue
  fi
  # fetch quietly (may be slow/offline)
  git fetch --quiet 2>/dev/null
  ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
  behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
  state="OK"
  if [ "${ahead:-0}" != "0" ] && [ "${behind:-0}" != "0" ]; then
    state="DIVERGED"
  elif [ "${ahead:-0}" != "0" ]; then
    state="AHEAD"
  elif [ "${behind:-0}" != "0" ]; then
    state="BEHIND"
  fi
  printf "  %-40s %-20s %-9s ahead=%s behind=%s dirty=%s\n" "${repo#$HOME/}" "$branch" "$state" "${ahead:-?}" "${behind:-?}" "$dirty"
done <<< "$found"
