# Strand: splay-mosaics

## Mission

Bring raw Bayer-mosaic inspection into splay as a first-class mode, and
round out the viewer features that support it. The headline deliverable is
**mosaic mode**: photosite-level heat-map rendering of a raw crop with
per-cell Bayer colour tagging, using the known Bayer pattern for the camera
type (see `splay/design/bayer-heatmap.md` — parity is per-sensor and must be
verified, e.g. via assume-white balance on a star). A reference
implementation exists at `splay/apps/bayer_heatmap.py`, developed in the
astro project for PSF/undersampling inspection.

Supporting viewer work travels with it: variable n-frame summing in memory,
white balance from a selection, heat map at viewable scale, variable
background subtraction, and background-by-default launch with a
`--foreground` option.

**Repos:** `~/splay` (all code deliverables land here). Astro pipelines are
the main consumer — splay is the visual-techniques lab; apps prototype
interactively, pipelines import them headlessly.

**Task tracking:** splay's old `TODO.md` was absorbed into this strand
(2026-07-11) and deleted. Pending work lives in `STATE.md`; new ideas go in
`IDEAS.md`.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
