# Strand: cld-colours

Per-strand terminal colours for `cld`, in the same manner as `ssp`
(OSC 11/10 background/foreground escapes). Where ssp picks from a fixed
14-colour palette keyed per host, cld generates colours on the
golden-angle hue wheel keyed per strand, so the palette is effectively
unlimited and each strand's terminal is instantly recognisable.

Spans: `super` only — deliverable is `super/bin/cld` (colour logic) plus
one `colour` file per strand dir (hex, in git, portable across machines).

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
