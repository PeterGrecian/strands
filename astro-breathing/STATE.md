# astro-breathing — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Nights captured (established 2026-07-13)

Frames live on **muppet:/mnt/bigdisk2/eclipticam-frames** (the staging copy
for the storage ship — pip's NFS mount to eclipticam only holds the current
night; puppy is full). Dither is detected by presence of the LENSPOS FITS
header:

| Nights | Mode | Ladder |
|---|---|---|
| 2026-07-01 … 07-06 | **fixed focus** (no dither) — "before" baseline | — |
| 2026-07-07 | **breathing** — WIDE early ladder | **3.15→5.05, 0.1-dpt, 20 steps** |
| 2026-07-08 … 07-12 | **breathing** — retuned narrow ladder | 3.5→4.375, 0.125-dpt, 8 steps |

So it's **6 breathing nights, 6 fixed nights** — more than the "~2 and ~2"
recalled. Dither turned on 2026-07-07. **Checked 2026-07-13 (Peter asked
whether the 7th's env var was actually set): it WAS.** All 279 frames on
07-07 carry LENSPOS, reported tracks commanded at lag-4 (99% match) across
the full 3.15→5.05 range — the VCM genuinely swept the wide ladder. The
"written/deployed but env var unset" worry did not happen; the only change
on the 8th was retuning the ladder to the narrower 8-step sweep. Do NOT
mix 07-07 (0.1-dpt/20-step) with 07-08+ (0.125-dpt/8-step) in a single
scale-vs-lp fit — different sampling grids.

## What exists

- **Capture is live.** `astro/capture/streaming.py` has an opt-in
  focus-dither mode (`V3W_FOCUS_DITHER=1` + `V3W_FD_BASE/TOP/STEP`),
  wired through `astro/eclipticam/v3w_night_daemon.py`. Running config:
  sawtooth lp **3.5 → 4.375 in 0.125-dpt steps** (8 phases), one 59.9 s
  full-res frame per ~minute, LENSPOS (commanded) + LENSPREP (metadata)
  written to every FITS header. The env toggle is set on-host on
  eclipticam only — not in the ansible role (fine for an experiment,
  don't lose it in a re-deploy).

- **Before/after analysis done 2026-07-13** (00 UT hour, 07-05 vs 07-11,
  60 frames each). Scripts + plots in `results/`:
  - `field_overview.png` — **the field is NOT dark sky.** Bottom ⅔ is
    rooftops + trees + a bright light-polluted horizon glow; only the top
    ~third (rows 0–560 mono) is usable sky. Wind-blown trees on the right
    are the dominant "movers". First "brightest streak" mosaic
    (`before.png`) was almost all window-lattice / reflection / foliage,
    not stars — a caution for any future auto-picker.
  - `sky_band.png` — clean diagonal star trails do exist in the sky band,
    running ~12° from horizontal (consistent with az≈160° pointing).

## Results (honest)

1. **VCM genuinely steps.** LENSPREP cycles through all 8 distinct
   positions 3.5–4.375 in exact 0.125-dpt increments — the actuator does
   move at this granularity, it is not stuck/quantised coarser. **LENSPREP
   lags LENSPOS by exactly 4 frames** (half the 8-cycle); key analysis on
   LENSPREP.
2. **Breathing magnitude confirmed, but SNR-limited** (`breathing_curve.png`).
   Per-frame plate scale fitted from ~140 stars (Umeyama similarity to a
   reference frame) vs LENSPREP: **measured peak-to-peak scale change
   0.27 %**, vs **predicted 0.245 %** (0.28 %/dpt × 0.875 dpt). Right
   magnitude — the breathing effect is real and about the predicted size.
   BUT the per-position scatter is **±0.30 %**, as large as the whole
   signal, and the curve does not cleanly track lens position. Single-frame
   star-matching noise swamps the trend.
3. **Lateral-streak super-resolution — not demonstrated from one streak.**
   At 60 s exposures a given star sits in a fixed crop for only ~5 frames
   before drifting out (`compare.png` waterfalls show the streak bright in
   a handful of frames only). Cross-track centroid "wander" is ~3 px RMS on
   BOTH nights — that's bulk sky drift, not the sub-px breathing dither.
   The single-streak drizzle can't isolate the breathing contribution.
- **Finding: LENSPREP lags LENSPOS by exactly 4 frames** (half the
  8-step cycle) — reported[i] = commanded[i−4]. The libcamera control
  queue + 60 s exposures mean the commanded value doesn't apply to the
  frame captured that iteration. Consequence: **LENSPOS in the header is
  the wrong label for the frame**; use LENSPREP (always on the 0.125
  grid, so positions look stable per-frame), and treat the star-fitted
  per-frame magnification as ground truth.
- **Lateral-streak concept** (this session's framing): with 60 s
  exposures stars are ~11 px·cosδ trails. The trail continuously samples
  along-track; the breathing dither radially shifts frames, and where
  the radial direction is perpendicular to the local drift direction the
  8 phases sample the trail **cross-track** at sub-pixel offsets →
  super-resolved streak cross-sections. Facing az≈160° alt≈55°, streaks
  are roughly horizontal, so the useful zones are the **upper and lower
  bands** of the frame (radial ⊥ streak); left/right edges get
  along-track shift only, and the optical axis gets nothing.
- **Back-of-envelope numbers** (thin-lens, f≈2.75 mm, f/2.2, 1.4 µm px):
  plate-scale change ≈ 0.28 %/dpt ⇒ per 0.125-dpt step ≈ **0.35 px of
  radial shift at r = 1000 px** (~0.46 px at top/bottom mid-line,
  r≈1300), full-ladder span ~3 px there. Defocus blur ≈ 0.25 px per
  0.1 dpt ⇒ the 0.875-dpt ladder spans ~2 px of blur variation
  edge-to-edge — per-frame PSF width varies across the ladder and the
  reconstruction must weight or model that.

## Pending / loose ends

- **The signal-to-noise problem is the crux.** Breathing shift at r=1000
  px is ~0.35 px/step — genuinely sub-pixel, which is the whole point, but
  it means per-frame star-matching noise (~0.3 %) hides it. To *use*
  breathing rather than just detect it, register frames by the breathing
  model itself (fit scale from LENSPREP + measured per-position calibration)
  rather than a free per-frame similarity fit, then drizzle MANY stars'
  cross-sections coadded, not one streak. That averages down the matching
  noise while preserving the deterministic sub-px shift.
- **Better target than long streaks:** the lateral-streak idea needs a
  star that stays in-frame across many focus phases. Either (a) coadd the
  cross-track profiles of ALL sky-band stars per focus phase (they share
  the same radial-shift-per-step at a given radius), or (b) shorten the
  exposure so a star dwells in one crop for a full 8-phase cycle. Decide
  which before more capture.
- Geometry map: cross-track dither amplitude ε(x,y) = Δscale·r·|sin φ|
  over the frame, to mark where lateral streak super-resolution is
  actually available (top/bottom bands; nothing at the optical axis).
- Confound to control: the "after" night had ~12× more bright-streak sky
  pixels than "before" — likely just a clearer night, not the dither.
  Don't attribute sky-quality differences to breathing.
- Known confounds carried over: window reflections (near-field, defocus
  differently across the ladder — may actually help separate them),
  daytime bloom (night-only for now).

## Tools that exist (don't re-write these)

- **Bayer coloured-dot heat-map = `~/splay/apps/bayer_heatmap.py`** (spec:
  `~/splay/design/bayer-heatmap.md`). Renders a raw Bayer crop as an
  intensity heat-map with an R/G/B dot per photosite (the filter colour),
  optional 3D stems, and the **assume-white** balance (scale R,B up to G on
  the star patch → true PSF, not the green checkerboard). Extracted from
  astro scratch into splay 2026-07-08, so it is NO LONGER in the astro
  tree. Standalone CLI: `bayer_heatmap.py FRAME.fits --x --y --size
  [--pattern RGGB] [--no-white] [--no-3d]`. v3w pattern = RGGB.
  - Verified 2026-07-13 on a clear-night (07-10) v3w star at raw
    (2622,1007): `results/star_heatmap.png`. WB came out R×2.51 B×1.85
    (reddish star / uncorrected response). The "star" is a ~10 px
    HORIZONTAL streak — the 60 s trail — so this tool doubles as the
    per-photosite streak inspector for the breathing work.
  - **The "show mosaics as heat map" idea is owned by the `splay-mosaics`
    strand**, not this one. splay's old `TODO.md` was absorbed into
    `super/strands/splay-mosaics/STATE.md` and deleted 2026-07-11 (hence no
    `~/splay/TODO.md`). That strand's headline = mosaic mode: photosite-level
    heat-map with per-cell Bayer colour, using the camera's known pattern.
    astro-breathing is a *consumer* of that tool; keep the viewer work there.

## Data note (2026-07-13)

- **2026-07-10 was VERY CLEAR; 2026-07-12 was CLOUDY.** For any before/after
  or PSF work use **07-10** (clear breathing night) — my earlier 07-11 pick
  was mediocre and 07-12 is unusable. Fixed-focus clear-night baseline:
  pick from 07-01…07-06 by sky quality, not blindly.

## Channel-balance thread (opened 2026-07-13, → extended session next)

Peter suspects the v3w R/G/B are **not balanced properly**. Started with the
Bayer heat-map on a clear-night (07-10) streak at raw (2622,1007).

- **Tool:** `results/heatmap_hist.py` — extends the splay `bayer_heatmap`
  app with a 3rd panel: per-channel R/G/B **histograms over the star patch**
  (>15% peak), plus a bar chart of the **WB factors AND their reciprocals**
  (Peter asked for both). Reuses `bayer_heatmap.bayer_channel`/parity so the
  selection matches the splay tool exactly. Output: `results/star_heatmap_hist.png`.
- **What it showed:** for THIS star, raw channel means R=1536, G=3854,
  B=2080 → WB R×2.51, B×1.85 (reciprocals R=0.40, B=0.54 of G). So R and B
  read low vs G — consistent with the imbalance suspicion.
- **BUT the measurement is not yet trustworthy.** On one thin streak the
  patch has ~14 G photosites but only **2 R and 4 B** (just the RGGB 2:1:1
  ratio on a 2–3px-wide trail). R/B means rest on 2–4 pixels — small-number
  noise. Worse, R/B photosites are never co-located with G, so a channel can
  look dim just because its few pixels landed on the streak's faint flank,
  not from real sensor response. **Single-frame per-star balance is
  sampling-dominated; can't confirm/refute imbalance from it.**

## Next session (Peter's steer: EXTENDED session on channel balance)

- **Aggregate ONE STAR ACROSS THE 8 FOCUS PHASES** (Peter's choice). The
  breathing dither shifts the star sub-pixel between frames, so over the
  phases each channel eventually samples the streak core — pooling R/G/B
  photosites across phases should give statistically meaningful histograms
  where one frame can't. This is the payoff use of the dither for the
  balance question, and dovetails with the super-res thread.
  - Need: track a chosen star through its frames (it drifts ~11px/frame +
    sits in a crop only ~5 frames — pick a star and follow it, or re-centre
    per frame from the residual), register, pool per channel, histogram.
  - Star picking method deferred to that session (Peter will drive: options
    were finder-chart / give-coords / auto-clean).
- Consider promoting the histogram panel into the splay app proper — that
  work belongs to the **`splay-mosaics`** strand (mosaic-mode owner), not
  here. astro-breathing is the consumer / motivating science.

## Decisions

- Channel-balance investigation will aggregate a single star across the 8
  breathing focus phases (not many-stars), to keep per-star colour intact
  while beating down the RGGB small-sample noise. (2026-07-13)

- VCM repeatability is explicitly *not* required — per-frame scale is
  self-calibrated from stars; lp command is a shift generator, not a
  control variable. (2026-07-13)
- Frame focus label = LENSPREP, not LENSPOS (4-frame control-queue lag).
  (2026-07-13)
