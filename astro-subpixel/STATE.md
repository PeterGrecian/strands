# astro-subpixel — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

**Method foundations (mostly 2026-07-05 session, in astro memory
`project-v3w-star-id-moon-anchor`):**
- v3w PSF genuinely ~1 px = undersampled. Standard representation for
  white point sources: **local white-balanced mosaic** (gains from the
  star's own patch, not the sky — measured Altair WB R×2.19 B×1.65).
  The residual checkerboard after WB *is* sub-pixel aliasing = the
  signal drizzle recovers, not an error to flatten.
- **Streak astrometry**: cross-streak line fit pins a star's path to
  **0.14 px** within one 55 s exposure; adjacent streaks tile end-to-end
  (angles agree to 0.04°); over 2+ streaks the arc curvature is real and
  measures the local drift vector field.
- **Sub-pixel information theory checked (2026-07-09)**: FWHM ≈ 1 px is
  near-*optimal* for position encoding (neighbour flux ratio swings 7:1
  for a 0.25 px shift); the info collapses only for FWHM ≲ 0.5 px.
  CRLB ~0.006 px for a bright star → current 0.14 px is systematics-
  limited (per-pixel gain, intra-pixel response), not photon-limited.
  Recipe = ePSF fitting (Anderson & King); streaks are ideal ePSF input.
  Plot: `~/tmp/subpix_info.png`.

**Dither sources — three mechanisms, three camera modes:**
- **Speaker rig** (`astro/design/speaker-dither-rig.md`, parts ordered):
  PWM-as-DAC (10 kHz carrier) + RC (fc≈10 Hz) + current driver; 3-point
  corner mount, ~1 µm/mA, 0.1 px = 0.77 µm.
  Modes: **astrocam** = 2-axis *between-frame stepping* (frames are
  9.6 s coadds — hold DC during frame, step in the gap; no smear, no
  phase sync); **v3w** = 1-axis continuous S-streak, ≥1 cycle per
  longitudinal pixel (~14 s period), amplitude budget from the
  no-fold-back rule a·2πf < v_drift (→ ~0.15 px at 0.07 Hz); **zenith
  cam** = 1-axis drift-clocked (drift there is uniform E–W, 4.3 s/px on
  a 40″/px Module 3 — mount axis N–S, a ≲ 0.4 px).
- **VCM focus-breathing**: `V3W_FOCUS_DITHER` + LENSPOS logging landed
  on v3w. On a pole-pointing v3s, breathing (radial, ε·R) ⊥ drift
  (tangential, ω·R) *everywhere*, both ∝R → full 2D dither free of
  charge, except a central dead disc — which contains Polaris.
- **What dither buys** (not "lower noise"): breaks position↔gain
  degeneracy, lock-in rejection of non-synchronous drifts, fixed-pattern
  errors average as 1/√N, and it *measures* the gain/intra-pixel maps.
  Polaris (photometric anchor, static on the same pixels forever) is the
  star that needs it most — that's the speakers' real job.

**Quest board** (`astro/design/zenith-quests.md`, Q1–Q5): M51 (wants
narrow Mod 3 at zenith), Algol eclipse (autumn), Polaris A/B (re-scoped
2026-07-09: optics-blocked on Pi lenses, split handed to Q5), Mizar &
Alcor (calibration ruler, nothing blocking), **Q5 Polaris B by binocular**
(added 2026-07-09: 10×50 half → afocal ~4.9″/px then prime ~1.3″/px;
contrast not resolution is the challenge; stretch = Polaris A's Cepheid
pulsation, 0.05 mag / 3.97 d).

**astrocam PSF campaign (2026-07-06..09, astro memory
`project-astrocam`):** glass-on baseline FWHM 6.3/6.8/8.3 px
(07-03/04/05, worsening), glass-off ~9 px and field-nonuniform (one star
3 px, others 8–9) → protector was never the problem; suspect lens
decentre/creep. **Replace-or-repair pending** (v3s ~£20 or refocus).

## Pending / loose ends

- **v3w breathing demonstration** — first clear night. Success = (1) ε
  linear/repeatable ≲0.05 px, (2) FWHM growth ≲10–20% at extremes,
  (3) one reconstruction win. **This is the gate on the £20 v3s
  purchase** (astrocam replacement).
- **Drizzle prototype** — detranslate Altair-region streaks onto a 6×
  supergrid, verify a point reconstruction. First real super-res result.
- **ePSF builder from streaks** + predict-and-find tool (PSF +
  ephemeris-motion), replacing diff-frame argmax.
- **Uranus enters v3w field ~2026-07-23** — deadline that validates the
  whole detect→ID→mover chain before Neptune.
- **Quest 4 (Mizar–Alcor)**: nothing blocking, most immediate.
- **Quest 5 T1**: fixed bracket, Pi camera behind binocular eyepiece,
  afocal; see B at all.
- Speaker rig: bench build when drivers arrive; calibrate µm/mA loaded.
- Shared deps: standing plate solve; per-night sensitivity deliverable.
- v3s purchase overlap: zenith quests want a narrow Mod 3 *and* the pole
  camera wants one — pole and zenith are 39° apart; decide role of the
  first purchase (or buy two).

## Decisions

- Gain-corrected (star-patch WB) mosaic is the standard representation
  for white point sources; interpolation blurs the undersampled signal.
- Dither strategy is per-camera: between-frame stepping for short-frame
  cameras, continuous within-exposure for 55 s exposures.
- Don't design pole-camera work around the IMX219's fat PSF — astrocam
  will probably be replaced (v3s) or repaired.
- Quest 3 (Polaris split on Pi optics) closed as optics-blocked;
  dithering beats aliasing, not diffraction. Aperture (Q5) is the answer.
