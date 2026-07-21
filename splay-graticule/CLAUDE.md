# Strand: splay-graticule

Recurring workstream: RA/Dec **graticule and star-name overlays** on astro
camera frames, viewed in splay. The overlay is a DS9 `.reg` file that splay
rotates about the celestial pole per frame time, so one fit serves a whole
camera epoch. Spans **`~/splay`** (the viewer + `.reg` rendering, scope
hierarchy, rotation) and **`~/astro`** (`bin/make-epoch-graticule`, the WCS
fit + overlay generator). Overlay data lives at each camera's frames_root on
the muppet NFS (`/mnt/muppet/<camera>-frames/_epoch.{reg,wcs.json}`).

Purpose: let Peter navigate a frame by RA/Dec and identify stars, without a
full plate solve (`solve-field` won't bite on the binned Bayer stacks — flat
extraction). The WCS is a fixed-scale gnomonic hand fit from probed stars —
good to navigate by (~0.3°), not science-grade.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to (splay, astro) — this
   strand dir holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's pending,
   decisions made. Keep it curated prose, not a log.

## Key facts (don't relearn)

- **Probes:** read `~/.splay-probes.log` (tail) for Peter's clicked (x,y) +
  which file; `~/.splay-{frame,loaded,state}.json` for what's loaded / how
  splay was launched (has `cwd`). Don't kill Peter's splay to test.
- **Rotation sign:** shapes are sky-fixed; splay rotates by
  `(frame_utc − ref_utc) × 15.041 × screen_spin` about the pole.
  `screen_spin = -1` (default) = CCW as time advances (y-down image).
- **Bayer:** OV5647 = SGBRG10, IMX708 = SRGGB10 (recurring mistake).
