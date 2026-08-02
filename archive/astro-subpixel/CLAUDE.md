# Strand: astro-subpixel

**Beats the pixel — sub-pixel astrometry, photometry and super-resolution on
undersampled Pi-camera sensors.**

**Beating the pixel** on Pi cameras — sub-pixel
astrometry, photometry, and super-resolution on undersampled sensors
(v3w PSF ≈ 1 px). The threads: streak astrometry (drift as a time axis),
commanded dither (speaker rig, VCM focus-breathing, drift itself),
drizzle / detranslate-onto-supergrid reconstruction, ePSF fitting,
per-pixel gain maps. The quest board (`astro/design/zenith-quests.md`,
Uranus→Neptune→Titan) provides the milestones that prove each piece.

Spans **`~/astro`** (design docs, capture flags, processing); hardware
builds (speaker dither rig — shares PWM electronics with
`~/Berrylands/pwmaudio`); frame data on the muppet/eclipticam NFS mounts.
Related strands: `splay-mosaics` (Bayer heat-map inspection of exactly
this undersampled regime), `splay-graticule` (star ID / navigation).

## Parent of the dither-mechanism strands

This is the **umbrella** strand for beating the pixel: theory (drizzle,
ePSF, gain maps), the quest board, and the cross-camera picture. There are
**three dither mechanisms**, and each spins out into its own strand once it
goes hot (real data / a bench build), keeping its empirical detail there
rather than bloating this STATE.md:

- **VCM focus-breathing → `astro-breathing`** (spun out 2026-07-13, active).
  eclipticam v3w, ~12 nights captured. This strand keeps only a pointer;
  the SNR results and per-night ladder detail live in astro-breathing.
- **Speaker / PWM dither → `astro-speaker-dither`** (placeholder). The Pi-
  specific rig code is `~/Berrylands/pwmaudio`; the strand holds the
  astro-side design and will go active when the rig is on the bench.
- **Drift itself** (streak astrometry) stays here — it's not a commanded
  rig, it's the through-line of the umbrella.

Key design docs: `astro/design/speaker-dither-rig.md`,
`astro/design/zenith-quests.md`, `astro/design/standing-plate-solve.md`.
Deep session history in the astro project memory
(`project-v3w-star-id-moon-anchor`, `project-astrocam`).

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to (usually astro) —
   this strand dir holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
