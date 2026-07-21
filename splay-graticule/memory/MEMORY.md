# Memory Index — splay-graticule strand

Strand-scoped memory. Cross-repo/general memory stays in `~/super/memory/`.

Foundational facts for this strand currently live in the **astro** project
memory (`~/.claude/projects/-home-peter-astro/memory/`), because the graticule
work was first done from `~/astro`:

- `project-astrocam-graticule-overlay.md` — WCS provenance (hand fit, RMS
  0.29°), epoch fallback location, the CCW/screen_spin rotation convention.
- `reference-splay-state-files.md` — read `~/.splay-{frame,loaded,state}.json`
  to see what the user is viewing / how splay launched; don't kill their
  session to test.
- `reference-splay-probe-log.md` — `~/.splay-probes.log` tail = user's clicked
  (x,y) and which file.

Write new strand-specific memory here; the running mission/state lives in
`STATE.md` (curated), not in memory files.
