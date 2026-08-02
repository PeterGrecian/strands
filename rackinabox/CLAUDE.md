# Strand: rackinabox

**Builds a silent laser-cut home-server enclosure — flat finger-jointed panels,
DXF-generated, headed for SendCutSend fabrication.**

The `~/rackinabox` deliverable: a silent home-server rack, design locked as a
flat laser-cut 6 mm finger-jointed box. `cad/panels.py` generates the DXF
panel set (baseboard, walls with tube pass-throughs, fan panel); `DESIGN.md` is
the spec. The gate to a physical rack is finishing the panel set and nesting,
then a SendCutSend quote.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
