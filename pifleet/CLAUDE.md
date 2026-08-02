# Strand: pifleet

**Keeps the fleet roster and liveness board — who's in the fleet and whether
each always-on host is up (Pi or not).**

Fleet membership + dashboard/liveness for all always-on hosts. The board is
`Berrylands/pi-fleet` (the source-of-truth inventory). This strand owns
*knowing the fleet's state*; *changing* hosts to make the fleet healthy is the
sibling **ansible** strand's job.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
