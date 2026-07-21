# splay-grid — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists (as of 2026-07-11)

**Grid mode is built and verified, on a worktree branch, NOT yet merged to
splay main.**

- **Branch/worktree:** `splay-grid-mode` at `~/splay-grid-mode` (git worktree
  of `~/splay`). Committed at `4c9ab6e` ("splay: add grid (contact-sheet) mode
  for browsing large sequences"), +176 lines in the single `splay` script.
  Branched from `main` at `1e366ce`.

- **What works (screenshot-verified against 40 test JPEGs):**
  - `G` (shift-g) toggles a full-viewport contact-sheet grid over the current
    scope (respects list/selection mode + sort, like the strip).
  - Auto-computed columns from window width (9 cols at test window size),
    filenames labelled under each cell, yellow cursor border, green
    selected-tick — all matching strip conventions.
  - Navigation: arrows (±1, ±cols), PgUp/PgDn (±page), Home/End. Cursor math
    verified: Down×2 + Right×2 from index 0 landed exactly on frame-020.
  - Enter/Space or click commits (opens that frame, leaves grid); Esc/G
    cancels with `self.idx` untouched.
  - Playback pauses on entry. Progressive thumb fill via `_thumbs_pending`
    works (reuses the main loop's existing pending-redraw path).

- **New methods** in `splay`: `toggle_grid`, `_grid_geometry`,
  `_grid_ensure_visible`, `grid_move`, `grid_commit`, `_grid_index_at`,
  `_draw_grid`. Plus: 4 state fields in `__init__`, an early grid dispatch in
  `draw()`, a grid nav-intercept block at the top of the KEYDOWN handler, an
  early grid branch in the MOUSEBUTTONDOWN handler, the `G` binding, and a
  help-text line in the header docstring.

## Pending / loose ends

- **Merge decision.** Not ready for splay main per Peter (2026-07-11). Land
  when he says so. Until then main is off-limits for grid code.
- **Real-data test.** Only tested against synthetic 40-JPEG gradient frames.
  Should be run against a real FITS sequence (cold-thumb budget behaviour,
  FITS thumb path, larger N paging) before merge.
- **Interaction review:** confirm grid keys don't collide with app-mode
  bindings when a plugin is loaded (grid intercept is early, but double-check
  `,`/`.`/`[`/`]` etc. while grid is open).

### v2 ideas (deferred, not started)
- Grid-mode multi-select (space to tick without leaving).
- Chapters / time-gap markers over the grid (from capture timestamps).
- Variable cell zoom (`[`/`]` = fewer/bigger vs more/smaller cells).
- Overview scrubber: whole sequence squashed to one screen-width row.

## Decisions

- **2026-07-11:** grid mode gets its **own strand** (not folded into
  splay-mosaics) — Peter expects it to grow legs (multi-select, chapters,
  cell zoom, overview scrubber).
- **2026-07-11:** developed in a **worktree**, kept off splay main until ready.
- Key binding is **`G`** (shift-g); plain `g` stays open-in-gimp. Works in
  both app and non-app mode.
