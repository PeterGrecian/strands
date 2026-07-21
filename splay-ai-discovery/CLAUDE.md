# Strand: splay-ai-discovery

Recurring workstream: **making splay a first-class tool for AI-driven
sessions** — the viewer an agent reaches for (and drives) when it needs Peter
to *see* frames, and when it needs to inspect images itself. splay is the
visual-techniques lab's viewer (`~/splay`, on `$PATH` as `super/bin/splay`);
this strand is the feedback loop from *actually using it in anger* during
other strands (astro-canon, astro-subpixel, gardencam…) back into splay's
UX, discoverability, and scripting surface.

Born 2026-07-14 during an astro-canon focus session: Claude kept rendering
images inline and copying JPEGs to `~/tmp/` because it didn't realise
**splay was the viewer** and was already running, pointed at the frames. The
fix — `splay <dir>` hands off to the running instance; auto-reload makes new
captures appear live — is exactly the discovery this strand exists to
capture and generalise.

Spans **`~/splay`** (the viewer itself; changes commit there) and whichever
strand is exercising it. Deliverables: splay doc/UX/scripting improvements,
and a written account of how an agent should use splay.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Code changes commit to `~/splay`; this strand dir holds only
   curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
