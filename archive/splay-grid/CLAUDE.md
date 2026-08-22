# Strand: splay-grid

**Grid (contact-sheet) mode for splay — a full-viewport thumbnail grid and the
browsing/navigation around it.**

## Mission

**Grid (contact-sheet) mode for splay** and the browsing/navigation features
around it. The headline deliverable is a full-viewport thumbnail grid for
finding frames in large sequences: an N×M page of thumbnails over the current
scope, cursor navigation, click/Enter to open a frame, Esc to cancel. It
reuses splay's existing `thumb()` cache and the strip's per-draw budget so the
first draw stays responsive on big sets.

This is a **viewer/navigation** strand, distinct from the two sibling splay
strands:
- **splay-graticule** owns the `.reg` overlay engine (WCS, rotation, scope
  hierarchy). Overlay work goes there, not here.
- **splay-mosaics** owns raw-Bayer / heat-map inspection + general viewer
  features (n-frame summing, white balance, background subtraction).

Grid mode is browsing UI: no overlay, no pixel processing. If a change is
about *finding your way around a sequence*, it's this strand.

**Repos:** `~/splay` (all code lands here). This strand dir holds only
curation files.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to `~/splay` — this strand dir holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's pending,
   decisions made. Keep it curated prose, not a log.

## Key facts (don't relearn)

- **Development happens in a worktree**, not `~/splay` main. The branch is
  `splay-grid-mode` at `~/splay-grid-mode` (git worktree of `~/splay`). It is
  **deliberately not merged to splay main yet** — treat main as off-limits for
  grid code until Peter says it's ready.
- **Grid is a mode, not a VIEW_*.** It replaces the single-image viewport
  while active. `grid_cursor` drives navigation; `self.idx` is only touched on
  commit (Enter/click), so Esc is non-destructive.
- **Budget discipline is non-negotiable.** Cold FITS thumbs are expensive
  (full read+decode); build only a few per draw, placeholder the rest, keep
  `_thumbs_pending` set so the main loop redraws until the page fills. Copied
  from `_draw_strip`. Skipping this stalls the first draw for seconds.
- **Layout single source of truth:** `_grid_geometry()`, mirrored by
  `_grid_index_at()` for click hit-testing (same pattern as `_thumb_index_at`
  for the strip).
- **Testing needs a live X display** (pygame window). splay backgrounds itself
  by default now (splay-mosaics change) and is single-instance via a unix
  socket — a second launch hands off to the first. To test in isolation: kill
  stray instances + `rm /run/user/1000/splay.sock` first, launch from the
  worktree, drive with `xdotool key --clearmodifiers` + screenshot with
  `import -window <wid>`. **Don't kill Peter's own splay to test.**
