# astro-science — state

*Curated summary of where this strand is. Updated at the end of each session.
The science/insight layer of the astro estate. **Consolidated 2026-08-02** from
astro-subpixel + astro-breathing + astro-storage-discussion (theory half) +
astro-v3s (sidereal direction) + astro-deliverables — those strands are archived;
their operational/engineering halves went to the keepers (polecam/eclipticam/
canon/storage).*

## THE MAP — sidereal-space static accumulator
<!-- named "the map" 2026-08-13 (Peter), retiring the placeholder "the thrust".
     Mathematical sense: a mapping from image space to the celestial sphere. -->

**Status 2026-08-14: the map has a name, a design, a subproject, and its first
working measurement.** Read this section first; the older material below is
theory that still stands.

- **`design/accumulation-bucket-refinement.md`** is the master doc — extent,
  projections, buffers, dtype, bootstrap, statistical star/contaminant
  separation, and astro-storage's binding constraints.
- **`polefit/`** is the working subproject (README + fitter + CLI + regression
  test + sample max stacks).
- **`design/refraction-quest.md`** is the long-horizon prize: measure the
  atmosphere as a second static vector field, and invert it to a barometer.

### What was measured on 2026-08-14 (astrocam 2026-08-12)

**De-rotation works** — the first positive result. Matched-moving-star sharpness
on 20 frames of hour 01 (single frame = 4.452 is the ceiling):

| stack | sharpness |
|---|---|
| plain sum | 1.358 |
| whole-image gradient-fit pole | 1.884 |
| **Polaris-arc pole (1392, 978)** | **2.549** |

**The pole comes from Polaris's own arc.** Trails are concentric circles about
the pole; Polaris draws the innermost (radius 17.5 px measured vs 18.1 predicted,
sweeping 138°). Short radius + large sweep is the well-conditioned case for a
circle fit; the long outer arcs have huge radius and small sweep so their
curvature barely constrains a centre. **This beat both existing tools** —
`bin/arc-walk` (moves ~90 px with threshold) and `bin/fit-pole` (wrong for this
night). `_epoch.wcs.json` does NOT rescale cleanly from epoch 1.

**Polaris also gives the plate scale for free**: 0.7525° / 18.1 px = **0.02079
°/px full-res**, against `_epoch.wcs.json`'s 0.02081 — **0.1% agreement from an
independent measurement**.

**The coarse stage is distortion-immune** (Peter's method, `polefit/
radial_normal.py`): points where the arc normal is radial from the image centre
are unaffected by radial distortion, because the displacement is parallel to the
normal. Circular mean of their azimuths → **0.33° = 2.8 px**, versus 85 px for a
whole-image gradient fit. The estimator MUST be circular; the arithmetic mean
errs by 11.58° from mod-180 wrap alone.

### Hour stacks and the arc-completeness filter

Per-hour stacks **do not exist** (only per-night, whose ~7 h arcs are near-
complete circles and hard to separate). Building one takes 7.7 s and gives short
separated ~14.8° arcs — far better suited.

**Peter's completeness insight, made operational:** for a complete arc the
MIDPOINT is half past the hour and the ENDS are the hour's start and end, so a
max stack is a *time-parameterised curve*, not time-blind. Requiring
|sweep − expected| < 0.8° cut **70 candidate arcs to 6 complete ones**;
everything rejected was frame-clipped or occluded. **Sweep-vs-duration is also a
free capture-continuity check** — the same signal proposed for `summary.json`,
straight from geometry.

**Dtype:** a MAX stack is capped at the SENSOR ceiling (1023) whatever the
container; a 60-frame SUM reaches 26,459 (fits uint16, overflows int16 1.9×,
use int32) and has **26× the dynamic range** with zero saturation. For midpoints
the sum is strictly better — a max stack of a saturated star is a flat plateau
with no centroid.

### The hierarchy (Peter): 1 → 6 → 20 → 100

Each stage improves the mapping, which makes the next stage's identifications
trustworthy. 1 star (Polaris) → pole + scale. 6 → roll (one parameter from six
constraints, overdetermined). Then **interpolation between known stars beats
extrapolation**: a tight error box lets you go fainter, because false-alarm rate
scales with search area. So expand *inward between anchors* first, where the
field is best constrained — which makes our clustered arcs a strength, not the
weakness I first called them.

**Accumulation happens in MAP SPACE, not by de-rotating images.** Project each
frame through the field at its own timestamp and sum there; a star is stationary
by construction. De-rotation was only ever an approximation valid when
distortion is ignorable.

**The rigidity constraint is the deepest lever:** the sky is rigid and only its
phase changes, so the same star at two times must map to ONE point. A field
error is fixed in *image* space; a timing/pole error is fixed in *sky* phase.
Opposite signatures, so they separate — and one star sweeping its arc samples
the field at hundreds of positions.

## The thrust — sidereal-space static accumulator

The framing that ties all the sub-pixel work together, and the strand's next
phase (from astro-v3s, 2026-08-01).

**Goal:** a **year-round static accumulator** — integrate every frame into a
fixed sky frame so stars stop being streaks and become *points that accumulate*
night after night, pulling faint stars out from between the bright ones (a deep
stack far below the single-frame limit). Fixed mount + Earth rotation means
every star sweeps a circle about the pole; de-rotate each frame and co-add.

**Coordinate space = a PROJECTION from camera coords onto the SPHERE** (Peter's
framing) — NOT a flat (r,θ) or flat RA/Dec grid. The accumulator lives on the
sphere, so sampling density follows the real geometry (lens projection, pole
compression, plate-scale variation) and uses parameter space efficiently. The
camera→sphere projection *is* the model; de-rotation is a rotation on the sphere.

**Why the sub-pixel work is load-bearing:** camera→sphere is a *resampling*. Feed
it undersampled/aliased data and the aliasing bakes into the accumulator
permanently. So plate-solve (pole + plate scale + distortion) and the sampling
must be right, sub-pixel — hence the care about PSF, undersampling, exact focus,
and cadence.

**Anisotropic sampling → shorter exposures (the key rationale):** a star is a
STREAK per exposure (11px/60s on astrocam). Along the streak the integration
smears position/time → **along-track resolution is compromised**; cross-track
keeps full PSF resolution. The fix is a **higher sampling rate** — shorter
exposures shrink the streak toward a point, recovering along-track resolution,
so de-rotation places near-points (not smears) and the sphere is sampled finely
+ isotropically. The concrete argument for shorter-exposure / more-frequent /
smaller-dither. (Dither + breathing + beading all characterise the PSF being
resampled.)

**Status:** DIRECTION only — nothing built. Prereq: find the pole + plate scale
(STALE from imx219 era). Trail-arc fit on a clear night gives the pole and
doubles as the resampling geometry; then RA/Dec naming + the accumulator become
possible.

**The camera→sphere map = the hierarchical vector field** (design written
2026-08-03, `astro/design/hierarchical-vector-field.md`). The resampling map the
accumulator co-adds through is *the same object* as the bright-anchored
identification field: one static per-camera `pixel → true sky direction` map,
built **brightest-first / hierarchical** (pole star + bright anchors pin the SIP
field → fainter stars read off it by relative position → local Gaia cross-match),
in **three layers by timescale** (per-frame detections / per-night params /
per-epoch residual maps — "lens interpolates, sensor accumulates"), densified as
sidereal drift sweeps bright anchors across every pixel over weeks. The **new
aspect**: this field is not just for naming faint stars — evaluated at *every*
pixel it *is* the camera→sidereal-space accumulation map, so building it
brightest-first solves the accumulator's geometry prerequisite, the static field
makes per-night resampling cheap, and drizzle rains each pixel onto the sphere
through it. Consolidates framing that was split across `zenith-quests.md` +
`worklog/2026-07-05.md`. Valid over one move epoch (`camera-moved-signal.md`).
Proven in pieces; not assembled end-to-end; blocked on the same imx708 clear-night
solve.

**Atmospheric term — the static field breathes with weather** (Peter, 2026-08-03;
`astro/design/atmospheric-model-residuals.md`). The field's refraction component:
for a fixed camera each pixel sees the same altitude, so the *pattern* `shape(x,y)`
(vertical, altitude-dependent) is genuinely static — but its *amplitude* `k` is
**time-varying with air pressure + temperature** (colder/higher-P → more bending),
so `R(x,y)=k(weather)·shape(x,y)`. The static-field model bakes in one average `k`;
a colder/higher-P night is off by `Δk·shape` at low altitude. Fix: fit `shape` once,
make `k` a **per-frame logged covariate** `k(P,T)` from the known refraction physics
(Bennett/Sæmundsson) — turns weather from unmodelled error into a known covariate
(same move as breathing→LENSPREP). Chromatic (blue refracts more) → per-CFA-plane
`k_colour`, natural since the accumulator keeps planes separate. Consequences: it's
a real astrometric error floor, worst for v3w-low-alt / ~zero for astrocam-near-pole
/ maybe below precision at zenith (estimate first); an unmodelled pressure swing can
**fake a wobble** → threatens the companion science (`what-accumulation-buys.md`),
must model not average; a better atmo model is a **prime reprocessing driver**
(logged weather → always re-correctable, `retrospective-reprocessing.md`); per-night
atmospheric residual + seeing/scintillation feed **confidence** + best-seeing
weighting. Design/refinement only; open: weather sensor vs API, magnitude at zenith,
seeing floor vs the 0.14 px systematic.

## Accumulation theory — the capacity law + TDI (from storage-discussion)

- **Whole-night unshifted sums are information-bounded — the capacity law.**
  For a rigid camera trails never cross, they *merge*: a star owns a ~3 px
  cross-drift band, and two same-band stars confuse when separated by less than
  trail length L = min(W, T/t_pix). Stored-sum capacity C(T) = (H/3)·(W/L),
  giving the conservation law **C × T = (H/3)·W·t_pix ≈ 25M star·seconds** for
  v3-wide portrait (was ~8M for OV5647). The 100k-star target needs ~500k cells
  → T ≤ ~50 s. No unshifted window is both deep and high-capacity: sums are
  eliminated *in principle*.
- **TDI / shifted accumulation is the unique escape.** Shifting the accumulator
  at the drift rate pins L at the PSF (~3–5 px): C ≈ 0.5–1.3M elements at
  unlimited T. Chosen shape: **remap-then-shift** — one *static* distortion-field
  mapping (camera fixed → measured once) into a regular (drift, dec) grid, then
  integer shifts. Polar coords about the pole for astrocam/polecam; curved bands
  for eclipticam's 102° field. Pure sidereal binning (same pixel, same sidereal
  phase across nights — zero resampling, CFA-safe) kept only as a validation
  patch (~170 GB). Full swept-sky accumulators: ~400–700 MB **total forever**
  per instrument; per-night marginal cost ≈ 0.
- **Resampling: drizzle, not interpolation.** Naive interpolation on undersampled
  data aliases — use **drizzle-style** accumulation (variable-pixel linear
  reconstruction) onto a finer-than-sensor sky grid, per CFA plane; the drift is
  a continuous dither, drizzle's ideal input. Resampling undoes motion *between*
  frames, never *within* an exposure — hence exposure ≲ t_pix; the within-exposure
  trail kernel is exactly known (drift rate per pixel), so 1–2 px trailing is a
  modellable field-varying PSF, not lost signal.
- **Raw mosaics + drift: the Earth demosaics.** Accumulate CFA planes, never
  demosaic first; drift sweeps each sky point across R/G/B pixels, building full
  colour without interpolating. Shift by the 2×2 CFA period (or keep four
  half-res planes).
- **Sub-pixel makes the /3 pessimistic, direction-dependently.** Along-drift
  super-res is free (continuous pixel-phase sweep, centroids ~0.1 px);
  cross-drift is deblend-limited (~FWHM/√SNR) → ~**1000 effective vertical
  channels at the faint limit** for v3w portrait.
- **Saturation is not a constraint.** The archive owns the regime between the
  catalogue floor and our noise floor; bright stars are only astrometric anchors
  (sub-pixel centroids survive saturation via unsaturated PSF wings). Compression
  corollary: **bits go to the darkest pixels**; bright static regions ≈ free.
- **Outlier rejection — clouds/planes must not co-add** (design 2026-08-03,
  `astro/design/accumulator-outlier-rejection.md`). The naive sum is fragile; a
  plane/meteor/cosmic-ray is a positive per-cell spike, cloud is a correlated
  region-wide lift (or dimming). Two rejection layers, both *non-sidereal ⇒
  reject*: **RANSAC** (Fischler & Bolles — the two-inventor technique, already
  proven here at TOL 0.10 px/s: "stars obey the rotation, everything else
  doesn't") rejects bad tracks/anchors from the FIELD fit; **per-cell temporal
  clipping** (sigma-clip / windowed median against the accumulator's own
  reference) rejects bad samples from the SUM. Coarse frame/region brightness
  gating + streak pre-detection (off-angle vs the analytic sidereal direction)
  throw out the obvious cheaply first; cloud's correlated/dimming signature is
  handled by frame gating + a bright-anchor transparency normalisation, not
  per-cell clipping. Effective-N tracked per cell → honest depth. This is the
  co-add twin of "persistence = identity". Design only; prototype = clipped vs
  straight stack on a night with a known plane pass.
- **What accumulation buys — position saturates, structure doesn't** (Peter's
  question 2026-08-03; `astro/design/what-accumulation-buys.md`). Once a star is
  pinned sub-pixel you do NOT need to accumulate it *for its position* —
  astrometry is systematics-limited early (0.14 px in one frame), so bright
  anchors resolve fast and become **fixed scaffolding** (field anchors, photometric
  + clip references), not integration targets. Depth keeps paying off for three
  OTHER things: (1) **detection** of faint sources below the single-frame floor
  (the "see" number — sources the sum *creates*); (2) **photometric depth**
  (flux/variability/colour keep improving √N); (3) — Peter's target — **sub-PSF
  STRUCTURE on resolved stars: the bumps** = unresolved binaries/companions,
  astrometric wobble (planets/dark companions, integrated over the season), and
  PSF-residual photometry (subtract an ePSF built from confirmed-single anchors →
  the residual IS the companion). Reframing: accumulation is coarse-to-fine in
  *what question* (locate → detect → photometer → resolve-structure); only
  resolve-structure wants unbounded depth. Practical: skip deep integration of
  anchor centroids, but KEEP their ePSF residuals over time (the wobble signal
  lives in the high-SNR bright stars). New stated goal — residual/wobble pipeline
  not yet designed; feasibility of dynamical wobble (sub-mas, likely below floor)
  TBD; static in-PSF companion (Polaris-B/Titan generalised) is the reachable
  first target.
- **Retrospective reprocessing — the archive appreciates** (Peter's question
  2026-08-03; `astro/design/retrospective-reprocessing.md`). YES — when the models
  improve we revisit old data, and it's the *defining* property, not an extra.
  Already stated for the distortion model (`drift-scan-cadences.md`: re-warp old
  frames with a better field → strictly better stacks, "archive more valuable over
  time"); generalised here to EVERY model: the vector field (denser anchors), the
  **catalogue** (old blobs now named), field anchor density, the ePSF, the sensor
  gain map ("sensor map accumulates"), and **confidence** (old candidates re-scored
  to confirmed by intervening nights). Uniform pattern: models are functions of
  the whole archive → growing it improves them → better models reprocess it — a
  **convergent** loop (gains front-loaded, taper as models mature; the frontier is
  the faint tail — bright stars saturate and stop benefiting). **Raw retention IS
  the reprocessing policy**: keep raws a rolling window (~3mo) so any improvement
  reaches the pixels; past the window the per-frame source tables (kept forever)
  carry identity/photometry reprocessing but not pixel re-warp — so schedule big
  field/ePSF jumps to sweep the held raws *before* they age out (the load-bearing
  tension). Runs as a puppy/NFS batch, triggered on material model improvement not
  every night. Deliverable consequence: **catalogue is versioned, old nights
  update** — "3 new stars in last month's data" is retrospective discovery;
  entries carry first_seen + last_reprocessed + model-version. Design/principle
  only.

## Sub-pixel foundations (from astro-subpixel)

- **v3w PSF genuinely ~1 px = undersampled.** Standard representation for white
  point sources: **local white-balanced mosaic** (gains from the star's own
  patch — Altair WB R×2.19 B×1.65). The residual checkerboard after WB *is*
  sub-pixel aliasing = signal drizzle recovers, not an error to flatten.
- **Streak astrometry:** cross-streak line fit pins a star's path to **0.14 px**
  within one 55 s exposure; adjacent streaks tile end-to-end (angles agree to
  0.04°); arc curvature over 2+ streaks measures the local drift vector field.
- **Sub-pixel information theory (2026-07-09):** FWHM ≈ 1 px is near-*optimal*
  for position encoding (neighbour flux ratio swings 7:1 for a 0.25 px shift);
  info collapses only for FWHM ≲ 0.5 px. CRLB ~0.006 px for a bright star →
  current 0.14 px is systematics-limited (per-pixel gain, intra-pixel response),
  not photon-limited. Recipe = ePSF fitting (Anderson & King); streaks are ideal
  ePSF input. Plot: `~/tmp/subpix_info.png`.
- **What dither buys** (not "lower noise"): breaks position↔gain degeneracy,
  lock-in rejects non-synchronous drifts, fixed-pattern errors average as 1/√N,
  and it *measures* the gain/intra-pixel maps. Polaris (photometric anchor,
  static on the same pixels forever) needs it most.

## Dither mechanisms — three, mapped to camera modes

- **Speaker rig** (build is `electronics`; see `astro/design/speaker-dither-rig.md`):
  PWM-as-DAC + RC + current driver, ~1 µm/mA, 0.1 px = 0.77 µm. Modes: polecam
  (astrocam) = 2-axis between-frame stepping; v3w = 1-axis continuous S-streak
  (no-fold-back rule a·2πf < v_drift → ~0.15 px at 0.07 Hz); zenith = 1-axis
  drift-clocked.
- **VCM focus-breathing (from astro-breathing):** `V3W_FOCUS_DITHER` + LENSPOS
  logging live on eclipticam. On a pole-pointing camera, breathing (radial, ε·R)
  ⊥ drift (tangential, ω·R) *everywhere*, both ∝R → full 2D dither free, except a
  central dead disc (which contains Polaris).
  - **Measured 2026-07-13:** VCM genuinely steps (8 distinct 0.125-dpt
    positions); **LENSPREP lags LENSPOS by exactly 4 frames** (libcamera control
    queue + 60 s exposures) — use LENSPREP as the per-frame label. Peak-to-peak
    scale change **0.27 % measured vs 0.245 % predicted** (right magnitude), but
    per-position scatter ±0.30 % swamps it in a free per-frame fit → **must
    register by the breathing model itself**, then drizzle MANY stars' cross-
    sections, to beat matching noise. 6 breathing + 6 fixed nights captured
    (07-01…07-12); don't mix the 07-07 wide ladder (0.1-dpt/20-step) with
    07-08+ (0.125-dpt/8-step).
  - **Numbers:** ≈0.28 %/dpt plate-scale change ⇒ ~0.35 px radial shift per
    0.125-dpt step at r=1000 px; defocus blur ≈0.25 px/0.1 dpt (model per-frame
    PSF width across the ladder).
- **Drift itself** — the always-on dither the accumulator theory rests on.

## Deliverables — the public face (from astro-deliverables)

The output end of the science: where results become visible.
- **Night pages + calendar** at www.petergrecian.co.uk/astro (calendar from
  precomputed `<camera>/index.json`, built nightly by `build-calendar-index`).
- **EOS 2000D (canon) is now a first-class deliverables camera** (BUILT
  2026-08-09). The Canon DSLR — long the astro-canon focus/wedge/plug saga —
  landed its **focus** and got wired into the nights pipeline. *(Focus was
  originally recorded here as "pinned d7"; that regime was RETIRED 2026-08-10 —
  see "Focus regime changed" below. Focus is now by-eye MF at "marker 0".)* **Approach: a CR2→FITS adapter**, not a bespoke
  builder, so canon flows through the *existing* `nightly-cam` /
  `publish-night-cam` / `build-calendar-index` unchanged — every downstream gain
  (derot, drizzle, accumulator, catalogue) applies to it for free. Pieces (astro
  `2130b14`, mywebsite `6eb8ca1`):
  - `canon/camera.json`: `flat` night layout, **GBRG** bayer (decoded from a real
    CR2 — *not* RGGB, don't assume), 6020×4015. plate_scale/pole
    **UNSOLVED** → derot disabled; nightly-cam degrades gracefully (prints "no
    pole prior; skipping derot", still writes max.jpg + brightness + summary).
    pedestal (2048) + sky_clear_max_stops (null) are **PROVISIONAL** — the canon
    black level is ~2048 (14-bit) vs imx708's ~62, so nothing could be copied
    from astrocam; **re-derive both from the first real dense night** (the
    pedestal double-duty trap: this axis anchors the cloud verdict too).
  - `bin/eos-cr2-to-fits` (**muppet**, needs rawpy): CR2 → one `.fits.fz`
    (undemosaiced Bayer in HDU 1, DATE-OBS/EXPTIME/GAIN=**ISO/100**/BAYERPAT/
    POSINDEX). Time/exposure/ISO from the night's `manifest.csv` (authoritative,
    no exiftool). Idempotent. `--only-d` filtered the old sweep nights —
    **never pass it now**: epoch-2 frames are all `_d00`, so `--only-d 7` would
    filter out every frame. Its `--src` default (`~/tmp/canon-focus-nightly/`)
    is **stale** — capture now writes to muppet's
    `/mnt/bigstore/astro-data/eos-frames/<night>/` (pip:
    `/mnt/muppet/bigstore/eos-frames/`), so pass `--src` explicitly until the
    default is fixed.
  - `bin/canon-nightly` (**pip**): the DELIVERY chain (adapt on muppet → stack+
    publish on pip → refresh index). **Host split is load-bearing**: muppet has
    rawpy not matplotlib, pip has matplotlib not rawpy — neither does both halves.
  - Website: 4th `/astro` hub card ("EOS Camera") + canon in the camera-page &
    player route regexes. Reads `astro-berrylands/canon/` + `canon/index.json`
    like the others.
  - **Verified end-to-end on 2026-08-08** (8-frame d7 subset): adapter →
    nightly-cam → **real sharp star-field max.jpg** (d7 focus visually confirmed:
    compact points, not the sweep's defocus blobs), published to S3, calendar
    index built (verdict=clear, 4/8 stacked).
  - **The capture/delivery boundary** (Peter, 2026-08-09): astro-capture (CR2s
    on disk) "should just work"; astro-canon = the keeper; **astro-science = this
    delivery layer**. The adapter is the *seam* — consumes capture's output, never
    reaches into it. Untouched capture files (`eos-focus-cycle`, `eos-power`) were
    left staged-but-uncommitted by their own strand.
  - **Focus regime changed — POSINDEX incremented to epoch 2** (2026-08-11, via
    a GREENLIGHT from [[ubersitrep]]). astro-canon **retired the whole `d`
    apparatus** on 2026-08-10: focus is now set **by eye through the optical
    viewfinder, lens on MF, datum "marker 0"**, and nights run `--no-focus` so
    the ring is never driven (a rail drop cannot move a mechanical ring). By-eye
    beat every driven method outright (edge/std 0.151 vs 0.055 best metric-guided
    bracket vs 0.035 all-day d-schedule), and — the load-bearing part — **`d` was
    tracking NOTHING all along**: 08-08 sharpness split by capture PASS, not by
    d, so the old V-curve/peak/"focus is d7" conclusions are **WITHDRAWN**.
    Decision (Peter): this is a genuine calibration boundary, so
    `position_index` **1 → 2** deliberately under the "increment whenever the
    camera, lens or mounting changes" rule — the mechanism by which focus is set
    changed, so epoch-1 d7 frames and epoch-2 marker-0 frames are never
    co-solved. Epoch 1 is retired in the registry (its only real data = the thin
    8-frame 08-08 bring-up subset). `focus_dial_d` → null; `_d00` in frame stems
    is a **null placeholder, not a dial position**.
    - **Gotcha found while doing it:** muppet's `~/astro` checkout is behind
      (`ab6619f`) and its `canon/camera.json` was **untracked** — a stale
      epoch-1 copy. Since the adapter runs *there* and stamps POSINDEX from the
      local config, running before syncing would have stamped all 460 frames
      epoch 1. Config copied to muppet (old one kept as
      `camera.json.pre-epoch2.bak`); verified POSINDEX=2 on a real frame before
      the bulk run. **The host split means camera.json must be synced to muppet,
      not just committed on pip.**
  - **Night dirs split at UTC midnight — by design, not a bug** (verified
    2026-08-11). The adapter files each frame under its DATE-OBS *calendar
    date*, so the 08-10 night landed as **207 frames in `2026-08-10/` (hours
    21-23) + 253 in `2026-08-11/` (hours 00-03)**. Alarming at first glance
    (the adapter reported "459 written" while the 08-10 dir held 207), but
    correct: `astro/frames.py` `list_night_frames` in the **`flat`** branch
    globs *both* the window's start and end day dirs and filters by
    `night_window` (noon→noon). Confirmed on real data: `list_night_frames(cfg,
    '2026-08-10')` returns **460 frames, 21:03:59→03:37:20 UTC, 6.56 h span,
    70.2/h** — matching capture's report exactly (their times were BST).
    So never judge a canon night's completeness by `ls` on one day dir.
  - **Pedestal + scs MEASURED off 2026-08-10** (77-frame sample across the
    night; same statistic nightly-cam uses — `per_s = mean/(EXPTIME*GAIN)`,
    anchor = median per_s over the darkest 10-min window):
    - frame mean **min 2706.5 / median 2806.8 / max 5918.7 ADU**; darkest at
      23:16 UTC, brightest 03:35 (dawn twilight). per_s 5.639…12.331.
    - **anchor: per_s 5.641, mean 2707.5 ADU, window 23:12–23:21 UTC.**
    - **pedestal 2048 CONFIRMED, not merely provisional**: the darkest frame
      mean (2706.5) sits comfortably above the ~2048 black level, so the
      log2 axis never floors. No change needed.
    - On that axis the **anchor is 9.37 stops** and the brightest frame 11.92 —
      only a **2.5-stop whole-night spread**, and both far above astrocam's
      numbers (pedestal 50 / scs 8), confirming nothing could have been copied.
      Canon sits in the *high-pedestal* family with eclipticam-v3w (4380 / 10.0).
    - **scs has an unforeseen SECOND duty — it also caps the stack band.**
      Beyond gating the verdict (`anchor_stops > scs ⇒ cloudy`), nightly-cam
      derives `sky_clear_hi = (pedestal + 2**scs)/(EXPTIME*GAIN)` and **clamps
      the ±30% acceptance band with it**. So scs must clear *two* thresholds:
      **>9.37** or this clear night reads cloudy, and **≥~11.0** or the cap cuts
      into the band and silently drops good frames from the stack. Measured on
      this night: **scs 9.5 stacks only 36 % of frames, 10.0 stacks 77 %,
      ≥11.0 stacks the full uncapped 92.3 %** (the 3 rejected are dawn frames,
      correctly excluded by the band itself, not the ceiling). **Set to 11.5**
      (Peter, 2026-08-11): ≈2.1 stops of verdict margin, band fully uncapped.
      A sharper form of the pedestal double-duty trap — same lesson one level
      in: a *ceiling* that also silently gates the *stack*.
    - Written back in `astro 1432642`; `reference_nights` now names 2026-08-10
      as the canonical dark/clear marker-0 baseline.
### FIXED 2026-08-11: canon processing moved to muppet — compute follows the data

**The host split was a false constraint, and it cost real time.** `camera.json`
asserted "muppet has rawpy but not matplotlib; pip has matplotlib but not rawpy
— neither host can do both halves, so the split is load-bearing, not
incidental." That was **wrong**. The entire matplotlib dependency is **one
module** — `astro/process/brightness.py`, which draws the brightness *chart* —
and muppet was one `apt install python3-matplotlib` away from doing the whole
job locally. (`darkest_anchor`, which the stack genuinely needs, happens to live
in that same module.)

Believing the constraint put the heavy pass on the wrong side of the wire:
nightly-cam ran on **pip**, dragging all 460 frames (~15 GB) over NFS — **twice**,
since `stack_and_measure` measures then accumulates.

- **Measured penalty:** pip read at **4.9 MB/s**, I/O-starved in `D` state at
  40–50 % CPU, **ETA ~100 minutes**. The same job on muppet reads local NVMe at
  **~34 MB/s at 90 % CPU** — 7× the throughput, and actually computing.
- **Peter's correction (the rule that already existed):** *"pip on wifi is not a
  compute node. it's my interface to all this. **compute follows the data** is a
  rule set months ago."* This was a rule to apply, not a finding to rediscover —
  the session burned ~100 min of wifi grind re-deriving it.
- **Fix:** `apt install python3-matplotlib` on muppet (3.6.3). muppet now has
  rawpy + numpy 1.26.4 + astropy 6.0.0 + matplotlib — **the whole toolchain, no
  split at all**. `processing.host` → `muppet`; `frames_root` already resolves
  per-host to muppet's local `~/canon-frames`, so nothing else changed.
- **Generalisable:** if a future host ever lacks matplotlib, make the
  brightness-chart import **lazy** — never move the heavy pass across a network
  to reach a plotting library. And check whether a claimed host constraint is
  one package deep before designing around it.
  - **DELIVERY IS NOW AUTOMATED (2026-08-12, `astro 0c015e5`)** — the last
    pending piece. **Prompted by a real miss:** 2026-08-11 captured **477
    frames** and produced *nothing* on the website, because delivery had only
    ever been run **by hand** (Peter: *"the delivery should be automated"*).
    Capture was fine; there was simply no timer.
    - `canon-nightly.timer` on **muppet**: `OnCalendar=06:00 Europe/London`,
      **`Persistent=true`** (catches up if muppet was asleep — exactly the
      failure that lost 08-11), `RandomizedDelaySec=600`. Units live in
      `astro/services/canon-nightly.{service,timer}` + `-run.sh`, following the
      house `combined-brightness` pattern.
    - **`canon-nightly` rewritten to run ENTIRELY on muppet.** It was still
      written for the retired split — ssh to muppet to adapt, then stack on pip
      pulling ~15 GB back over wifi. All four stages now run where the frames
      are. Also **drops `--only-d`** (with `d` retired every frame is `_d00`, so
      `--only-d 7` would filter out a whole night) and passes `--src` explicitly
      because the adapter's built-in default still points at the old capture
      path.
    - Designed so an unattended failure can't hide: **exits 0 when a night has
      no capture** (cloudy nights are normal, the unit must not go red and train
      you to ignore it), and every stage is idempotent so a re-run or catch-up
      is safe.
  - **PENDING**: **`sky_clear_max_stops` (11.5) stays
    provisional until a genuinely CLOUDY canon night is logged** — 08-10 gives
    only the clear side of the population, so the ceiling is bounded from below
    but not calibrated from above (astrocam's ceiling was set from both).
    Later refinements: occlusion mask (foreground foliage in frame), pole solve →
    enable derot.
  - **STACKED + DEPLOYED 2026-08-11.** `nightly-cam` on **muppet** (local disk):
    **432/460 frames stacked in 488 s** (~8 min; the same job on pip over wifi
    was ETA ~100 min). `verdict=clear`, anchor `per_s=5.640` — matching the
    77-frame sample's 5.641 to four significant figures, and band [3.948,
    7.332] exactly as predicted, confirming **scs 11.5 leaves the band
    uncapped**. 28 frames out of band (dawn), 0 saturated. badpix hot=1928.
    `no pole prior; skipping derot` — the designed graceful degradation.
    **The `max.jpg` is a real result**: hundreds of thin, crisp concentric
    star-trail arcs about the pole (off frame, upper left) from 6.6 h of a
    fixed urban camera — the by-eye marker-0 focus is **visually vindicated**,
    no fat blurred bands. Trails are *dashed* (30 s subs, ~51 s cadence ⇒ ~21 s
    dead time per cycle) — expected for this mode, and now the public look.
    Aircraft trails cross the lower right (the outlier-rejection design exists
    but is not built).
  - **`verdict` is a trough-finder, not a night-quality metric** (found on this
    night). `max.jpg` shows real cloud billows lit by skyglow, and the hourly
    mean_brightness **bounces** rather than falling smoothly to a trough:
    2908 → 2774 → **2724 (trough, 23h — where the anchor sat)** → **3086** →
    2810 → **3131** → 3487 (dawn). The 00h and 02h spikes are cloud drifting
    through. So `verdict=clear` is defensible *per frame* — the ±30 % band did
    its job — but it only ever proved **the darkest 10 minutes were clear**,
    and it flatters the night as a whole. This is the concrete case behind the
    "scs bounds the ceiling from below only" caveat. A whole-night quality
    measure (fraction-of-frames-in-band, or hourly variance) would make "clear"
    mean what a reader assumes. **Not built** — noted, not fixed.
  - **DEPLOYED 2026-08-11 — `/astro/canon` is LIVE.** The hold that stood since
    08-09 is discharged. `publish-night-cam` on muppet → S3
    (`canon/nights/2026-08-10/`: max.jpg, brightness.png, summary.json) →
    `canon/index.json` rebuilt (2 nights, both with thumbnails) → `./deploy`
    (Lambda CodeSize 200621, Cloudflare cache purged). Verified live: `/astro`
    hub shows the "EOS Camera" card; `/astro/canon` renders **2026-08-10, 460
    frames, 432 stacked, clear**; the night page returns 200 and the thumbnail
    serves 1,690,998 bytes of image/jpeg — byte-identical to muppet's max.jpg.
    NB the raw S3 URL 403s by design (bucket is private; the site serves images
    via **presigned URLs**) — don't mistake that for a broken upload.
    The in-progress `lambda/cv.html` rewrite shipped with it, at Peter's call.
  - **The timelapses were silently MISSING from the first deploy — two ffmpeg
    bugs** (Peter asked "I was hoping for timelapse videos like the other
    cameras"; fixed `astro 23c16fd`). The first publish wrote a **0-byte
    `sweep.mp4`**, logged `FAILED; continuing without it` for *both* sweeps, and
    still printed `=== done ===` — so only max.jpg/brightness.png/summary.json
    reached S3 and the deploy was reported complete on a partial artefact set.
    1. **Odd sensor height.** libx264 requires EVEN dimensions. Every Pi sensor
       is even, but the **EOS 2000D is 6020×4015** — odd rows — so its half-size
       web render is 3010×**2007** and the encoder refuses outright (`height not
       divisible by 2`). Fix: `-vf scale=trunc(iw/2)*2:trunc(ih/2)*2` (no-op
       when already even). Applied to `window-stack-sweep`, `diff-sweep` **and**
       `sum-sweep` — all three build their own ffmpeg call, so all three had it
       latent. `detrans-sweep` already crops odd rows in numpy: the constraint
       was *known*, just not applied consistently.
    2. **Numbering gaps.** `window-stack-sweep` fed `frame_%05d.jpg`, which
       stops dead at the first gap — and gaps are NORMAL (a window with no
       frames is skipped). This night has a **real capture gap at 01:27–01:37
       UTC** (frames 207–215; why 01h holds 56 frames vs 79–80 elsewhere),
       which truncated the encode to 207 of 329 frames. Fix: `pattern_type
       glob`, as `diff-sweep` already did.
    - Re-published clean (**zero** FAILED lines): `sweep-colour.mp4` 181.6 MB,
      `sweep-diff.mp4` 132.1 MB, both `-web` variants, both posters, thumb.jpg.
    - **Lesson: a publish that loses its main video must not report success.**
      Verify the artefact set matches what the other cameras produce, rather
      than checking only the files that did upload.
  - **FIXED 2026-08-11: the site now serves the `-web.mp4` variants**
    (`mywebsite 13bc058`; Peter: *"the website should use the -web videos. I
    don't know why we generate 4k ones"*). `publish-night-cam` has **always**
    built them and states the intent outright — *"the website serves
    `sweep-<name>-web.mp4`; the full-res mp4 stays as the high-quality/download
    copy"* (1280-wide, denoised, **`+movflags faststart`**). The Lambda simply
    never implemented its half, so the `-web` files were encoded and uploaded
    every night and **never used**: visitors got the masters (**181.6 MB** for a
    5.5 s canon colour sweep, 132.1 MB for the diff) and, with the `moov` atom
    at the END, playback couldn't start until the whole file downloaded.
    - **Two changes were needed, not one** — the trap worth remembering: the
      route fix alone would have silently done nothing, because
      `lambda/mywebsite.py:~4059` presigns from an **allowlist of basenames**
      that contained no `-web.mp4`, so `urls.get(web_key)` would miss and fall
      through to full-res every time. Fixed in both places.
    - Route prefers `-web`, **falls back to full-res** for older nights that
      predate the web encode, and offers the master as a "full-res" caption
      link (`.dl` style added) so the archive copy stays reachable.
    - Canon night page: **~314 MB → ~11 MB** of video, and it starts instantly.
      Verified live: ffprobe reads 1280×854 / 5.48 s from the **first 256 KB**
      of the served file. Applies to all four cameras.
    - So the answer to "why do we generate 4k ones": deliberately, as the
      high-quality master/download copy. Keep building them — just don't serve
      them.
  - **The hold is RELEASED — a real working night landed 2026-08-10.** The hold
    condition ("don't deploy `/astro/canon` on the thin 8-frame 08-08 subset;
    wait for a real working night") is met: **460 frames, 22:03→04:37 (6.6 h),
    70/h, ZERO wedges, ZERO restarts, one run tag, focus stable end-to-end**
    (median star FWHM 2.25–2.63 px, first frame to last), 15 GB. The earlier
    08-09 failure was capture-side (astro-canon wedge/plug saga), never a
    delivery fault — the pipeline was proven and idle, exactly as recorded.
    Remaining outward step: `cd ~/mywebsite && ./deploy` (code already committed
    `6eb8ca1`).
- **The catalogue AS the headline deliverable** (Peter, 2026-08-03; design
  `astro/design/catalogue-deliverable.md`). The local star catalogue isn't just
  an internal table — it's the public face of the science, a **forever-growing
  numbered spine with star #0 = Polaris** (the field origin / brightest anchor
  doubles as the catalogue origin). ID number ≈ discovery order = a timeline
  working down the magnitude ladder. Fed by **cadence-tiered accumulators**
  (nightly / weekly / monthly / all-time — the *same* accumulator read at
  increasing depth, each tier lowering the floor + promoting sources), sitting
  above the internal three cadences (`drift-scan-cadences.md`). Every entry AND
  nightly detection carries a **confidence value** that grows with evidence
  (persistence, field-agreement across configs, detection depth/SNR, Gaia
  cross-match as a *boost not a gate*, brightness-ceiling consistency) →
  candidate→probable→confirmed→catalogued tiers, time-stamped so sources are seen
  *earning* their place. **Nightly new-star count is the scoreboard** ("47 new,
  3 promoted, catalogue now 12,431"). Emits `catalogue.json` (spine) +
  `discoveries.json` (per-night) + a new `/astro` catalogue page. Design only;
  builds on the `zenith-quests.md` local-catalogue spec (mint-on-persistence,
  class-from-behaviour). Confidence-as-graded-field, cadence-tier deliverables,
  and the page are all new — not built. Open: hard persistence gate vs
  enter-at-conf-0; confidence calibration against Gaia.
- **moon-net**: `moon-extract`/`moon-overlay`/`moon-deliver` + `moon-drift.mp4`;
  **solver + star-ID still to build**.
- **FIXED 2026-08-12: the advanced player 404'd for eclipticam** (`mywebsite
  3913f7d`; was a spooled bug idea). *"no mp4s for this night yet"* on nights
  that had **eight**. A **URL-namespace mismatch left by the camera split**: the
  night page is addressed by the **logical** camera (`eclipticam`) and links to
  `/astro/eclipticam/night/<n>/player`, but unify-cameras moved the data into
  **physical** prefixes (`eclipticam-v3w` / `-v1`). The player listed
  `eclipticam/nights/<n>/` — the **dead pre-split prefix**, last written
  2026-06-16 with `v3w_`-prefixed filenames — and correctly found nothing. Fix:
  resolve logical→physical with the same mapping the camera page uses, searching
  every section so a night published by only one sub-camera still plays.
  - **Second bug found while fixing it:** the player listed **both** the
    full-res and `-web` copy of each sweep, so every clip appeared **twice** in
    the ↑/↓ cycle, full-res first (162 MB, `moov` at the end ⇒ can't start until
    fully downloaded). The night pages were fixed for this earlier; **the player
    route has its own listing code and was missed** — the general lesson is that
    `/astro` has more than one place that enumerates a night's mp4s.
  - Not bugs, but noted: **`eclipticam-v1` stopped publishing nights
    2026-06-24** (dormant, so its 404 is honest), and the bare `eclipticam/` S3
    prefix is now **unread legacy** — a candidate for tidying.
- **"Open in Splay"** flow (night player → `splay-launcher` daemon, port 8765).
- **/astro/storage** page watches skycam raw growth (an astro-storage concern).
- **Peter has a deliverables adjustment in mind spanning astro + mywebsite** —
  to be described (noted 2026-07-10, still pending).
- **Possible split back out as a keeper** (idea, 2026-08-03): deliverables was
  consolidated INTO astro-science yesterday (2026-08-02); the thought is it may
  eventually earn its own keeper strand (like polecam/eclipticam/canon/storage),
  since it's an *operational* output surface, not open research. Not now — too
  soon after consolidation; revisit once the science layer above it stabilises
  and the deliverables set stops churning.

### Fixed 2026-08-03: astrocam star-trails deliverable missing since Aug 1

The pole cam (astrocam) stopped producing its max-stack star-trail image
(`max.jpg`/`max.fits.fz`) + derot from 2026-08-01. **Not** the bigstore
migration — a **cloud-verdict miscalibration**:
- astrocam's imx708 pedestal was deliberately lowered 105→99→50 (Pi commits
  `6c2f2bb`, `e854c54`, on origin/main) **to keep the brightness chart usable**
  (dark nights get ≥1 stop of footroom instead of flooring at 0). Correct for
  the chart — but `pedestal` is shared with the cloud ceiling `sky_clear_max_stops`.
- On the pedestal-50 axis a *clear* dark trough anchor reads **5.5–5.8 stops**
  (measured across the 5 imx708 nights 07-29..08-02), so the interim ceiling of
  **5.0 cut straight through the clear-night population**. Genuinely-clear dark
  nights 08-01/08-02 → anchor above ceiling → every frame out of band →
  `n_stacked=0` → verdict cloudy → `nightly-cam` deletes the stale stacks and
  writes brightness+summary only. 07-31 escaped only because a twilight/moon
  peak pulled its anchor into a stackable band — the *brighter* night stacked,
  the truly-dark one didn't.
- **Fix (`ab6619f`, pushed to origin/main): `sky_clear_max_stops` 5→8**, keeping
  pedestal=50. Worst clear night (5.81) now gets a ~2.2-stop cloudy margin,
  matching the imx219-era clear/cloudy gap. Pedestal unchanged so the chart
  stays usable; the ceiling is decoupled by living on the same shifted axis.
- **Lesson:** `pedestal` does double duty (chart y-axis AND cloud ceiling);
  moving it for the chart silently shifts the cloud gate. Re-derive the ceiling
  whenever the pedestal moves. Re-check scs=8 if a fully-cloudy imx708 night
  ever shows it's too high (no fully-cloudy imx708 night logged yet).
- **Reprocessed + republished 08-01 + 08-02** with the corrected config: both
  now verdict=clear (357 / 143 frames stacked), full `max.jpg` star-trail +
  `derot.jpg` + thumbs live on S3, calendar index rebuilt (49/49 nights with
  thumbnails). Ran on the astrocam Pi (`nightly-cam` then `publish-night-cam
  --web-only`); slow because the Pi reads frames over NFS from muppet's bigstore
  (~13 min/night stacking), so future backfills are better run on pip.
- **Follow-on: reconciled the git + frames_root divergence** (2026-08-03). The
  astrocam config lived on origin/main (the Pi's pedestal-50 chart-fix commits);
  pip's `main` was behind and the frames_root=bigstore fix sat on an unmerged
  feature branch. Fast-forwarded pip's `main` to origin (picking up the scs fix)
  — which reverted frames_root to the Pi's `~/astrocam-frames`, breaking pip
  (symlink gone → 0 frames). Root design flaw: **one `frames_root` string can't
  serve both hosts** (Pi automounts bigstore at `~/…`; pip sees it at
  `/mnt/muppet/bigstore/…`). Fix (`dc36e38`, on origin/main): `frames_root`
  resolves **per short-hostname** via an optional `frames_root_by_host` map
  (else the host-agnostic default = the Pi's view). One property, every caller
  inherits it. pip now finds 385 frames for 08-01; non-pip hosts unchanged.
  Resolves the per-host divergence astro-storage flagged. (Optional follow-up
  not taken: the abandoned branch also converted the two uploaders to read
  `CameraConfig.frames_root` — safe now that it's host-relative, completes the
  "config is the only seam" goal, but the Pi's hardcoded `~/…` already works.)

### A standard "the camera has moved today" signal (DESIGNED 2026-08-03)

Real gap, promoted because a re-aim invalidates the pole + plate scale the
accumulator/plate-solve rest on. `position_index` (`POSINDEX` per FITS) records
**generation epochs** (sensor/lens/mount swaps — astrocam is index 2 = imx708
v3s). The **sub-epoch** signal — a nudge/re-aim, same hardware, that shifts the
pole but doesn't warrant a generation bump — was missing. **Now designed:**
`astro/design/camera-moved-signal.md`. Shape (mirrors `position_index` one level
down): a `move_index` / `MOVEID` per-FITS header + a `move_registry` in
`camera.json` scoped within a generation (key `"<pos>.<move>"`, each entry the
pole+occlusion that changed); the event logged in astro-storage's inventory; a
one-liner `astro-moved <cam> [night]` to raise it (increment + stub registry +
re-solve reminder); nightly pole-jump detection *prompts* but never
auto-increments. The accumulator's outer loop = **per move epoch**: one (pole,
plate-scale, distortion) solution per `(POSINDEX, MOVEID)`, all landing on the
*same* sphere so a re-aim doesn't fork the science product. Precedent it
formalises: `astrocam/occlusion.json` already notes a by-hand "camera moved
~2026-06-09" tile re-mark. **Not built** — design only; `astro-moved` +
`StreamingConfig.move_index` + registry plumbing still to write.

## Quest board (from astro-subpixel; `astro/design/zenith-quests.md`)

M51 (narrow Mod 3 at zenith), Algol eclipse (autumn), Mizar & Alcor (calibration
ruler, nothing blocking — most immediate), Polaris B by binocular (afocal ~4.9″/px
→ prime ~1.3″/px; contrast not resolution; stretch = Polaris A's Cepheid pulsation
0.05 mag / 3.97 d). Q3 (Polaris split on Pi optics) closed as optics-blocked —
dithering beats aliasing, not diffraction; aperture is the answer.

**Quest 6 dual — the catalogue is a free brightness CEILING** (Peter,
2026-08-03; `zenith-quests.md` §"catalogue is a free brightness ceiling"). The
inverse of the completeness curve: if we hold every catalogued star to mag M over
a region, any detection there that ISN'T catalogued is **provably fainter than M**
(else it'd be catalogued) — "collect all the mag-0 stars and anything in between
is darker." So every unmatched detection arrives free-bracketed: **fainter than
local M** (catalogue ceiling) *and* **brighter than the noise floor** (it was
detected), both bounds for free, no photometry. M(region) is a spatially-varying
field (evaluated through the same bright-anchored vector field); it sanity-checks
measured fluxes (a flux above M ⇒ suspect the match / it's a transient) and turns
the see-vs-identify gap into hard *fainter-than-M-here* labels from detection.
Holds only where the catalogue is genuinely complete to M (uncrowded/bright
regime); the ceiling lifting where the catalogue thins is itself information.

## Transients — meteors as a deliverable (NEW 2026-08-11/12)

**Design: `astro/design/transients.md`. Tool: `bin/find-transients`
(`astro 6b168db`). Peter spotted meteors by eye in the 08-10 sweeps —
*"lets start some science about it."***

- **The gap:** the archive **throws every meteor away**. `accumulator-outlier-
  rejection.md` rejects them as "non-sidereal ⇒ reject" (right for the stack),
  and `catalogue-deliverable.md` mints entries on **persistence** — which a
  sub-second one-off can never have. They fall through every crack. Fix: the
  same rejection pass **emits to a transients table** instead of only deleting.
- **THE RULE — sweep frames cannot classify; work on SUBS.** A sweep frame is a
  10-min stack: it smears the ablation profile flat (a meteor reads as a flat
  satellite trail — this caused a **wrong call** on the 00:05:14 event) and
  merges 10 minutes into one image, so an eyeballed "pair" carries **no timing
  information** — which is the whole question when asking about clustering.
- **Peter's discriminators, both of which overturned my wrong calls:**
  (1) *geometric* — a satellite **crosses** the field so ≥1 end touches the
  border; a meteor **ignites and burns out inside**, both ends interior. Robust
  because it survives the saturated cores (JPEG clips at 255 along the whole
  streak) that defeat profile analysis. (2) *illumination* — at solar altitude
  **−23.2°** Earth's shadow reaches **~560 km**, above Starlink (~550) and the
  ISS (~420), so a bright midnight streak is not a sunlit satellite.
- **Confirmed:** canon **2026-08-11 00:05:14** — 237 px, elong 138, ang 85.8°,
  both ends interior, single sub, symmetric taper (flux ~350 → ~740 → ~350 by
  wing integration). A genuine meteor, two nights before Perseid max.
- **Do they bunch?** Yes across a **season** (that's what a shower is) and
  across a **night** (rates climb toward dawn); **no within minutes** — Poisson,
  independent. Testable: a pair in the same **sub** is notable (P≈0.02); in the
  same 10-min **window** it's ordinary (P≈0.2). Doc carries the arithmetic.
- **STATUS — passes on one event, NOT usable on a night.** A full-night run gave
  10 "meteors" from **8 subs**; the cutouts showed **foliage** — leaf edges trip
  the threshold, stems pass the elongation test. Every *number* looked right
  (conf 1.00, ends=0, single sub); only the picture was wrong. `--save-cutouts`
  earned its place on first use. Root cause: the 40 px floor was **overfitted to
  the one meteor then known** (real 237 px, false positives 48–74 px).
  **Fixes in order:** (1) **median-subtract across the night** before detecting
  — kills static foliage *and* near-static star trails at once, the real fix;
  (2) length floor ~150 px (stopgap; loses the unrecovered 23:51:42 candidate);
  (3) occlusion mask — already a pending canon refinement, now **blocking**;
  (4) tune confidence thresholds against eyeballed cutouts.
- **Next run is astrocam, not canon:** canon has frames on only **08-08 and
  08-10**, so it cannot answer "meteors all week"; astrocam has run continuously
  all month and is the right instrument for a **rate-vs-night curve** across the
  Perseid build-up. **Multi-camera is the prize** — all three cameras recorded
  meteors on 08-10, and two cameras on one event gives **altitude + speed by
  triangulation** (waits on canon's pole solve).
- **CONTRAIL is a third class** (Peter, 2026-08-12: *"the meteor looks like a
  contrail"* — right again). EOS 08-11 sweep frame 312/339: **absent** at 305/311,
  **present** at 312/320, present but visibly **broadened** by 330. Crosses the
  whole frame, diffuse soft edges, lit from below by dawn twilight. A meteor
  lasts <1 s and is in ONE sub; this persists over minutes **and spreads**.
  Currently scores `ends_touching=2` + `persists≫1` ⇒ lands as "satellite" —
  correctly rejected as non-meteor but **wrongly labelled**. Proposed
  discriminator: **width growth over time** (satellite = thin constant line;
  contrail = broadens and softens). Also a **cloud-verdict** concern — a lit
  linear cloud lifts the frame mean. Written up in `design/transients.md`
  (`astro ba4c96a`).
  - **Method refinement:** this was disproved by the **neighbouring sweep
    frames**, no subs needed. Sharpens the earlier rule — "sweep frames cannot
    classify" is about *sub-second* structure (ablation profile, exact timing);
    a stack is the **right** tool for *"is it still there ten minutes later?"*
- **2026-08-11: NO METEORS DETECTED** (Peter's call, checked and it holds).
  A scan of all 339 sweep-diff frames for long thin streaks found **414
  detections in 52 distinct features**, every one explained:
  - frames 312–313 (len 311, ang 17.8°) — **the contrail**;
  - frames 61–70 (len 2005 = full height, ang 56.9°, static) — persistent
    linear feature, contrail or structure;
  - frames 182–186 at y≈726 drifting x 234→275, constant length —
    **satellite/aircraft** (NB my clustering faked a "90°" feature here: 0.4°
    and 179.7° are the *same* horizontal direction, split by angle wraparound.
    Watch for that in any future angle clustering);
  - ~40 others at **154–179°, 140–177 px** — **star trails**, the field's own
    direction, sitting just above the 140 px floor. Same overfitting trap as the
    canon foliage run.
  - Conditions do **not** explain the null: 08-11 was a *better* night than
    08-10 — smooth fall to a flat dark trough (2619–2687 through 00–02h), no
    cloud spikes, 461/477 stacked, verdict clear.
  - **Honest form of the result: "no *detectable* meteors", not "no meteors".**
    The confirmed 08-10 event was bright (237 px, saturated core); the floor is
    140 px and the star-trail population reaches 177 px, so anything fainter or
    shorter than the trails is invisible to the current scan. Exactly what
    **median-subtraction** fixes — remove the static trail field and the floor
    drops a long way. A zero-count night one day before Perseid maximum is
    itself interesting, so this is a real data point with a known and
    improvable sensitivity limit.
- **Unresolved:** the 23:51:42 canon candidate (~54 px by hand) isn't recovered;
  the eclipticam pair Peter screengrabbed isn't yet located in the subs.

## Quality pass — brightness over the ASTROCAM archive (2026-08-19)

Peter's ask: *"sort by brightness, find useless images, maybe delete, and
practice all-project image handling."* The measurement half is done for
**astrocam**: 87,615 frames over 65 nights, ranked. The delete half is
astro-storage's and **nothing was deleted**.

**Scope correction (Peter, same session: "are we processing where the data
is? muppet?").** This covered astrocam only — ~37 % of the archive. The
archive host is **muppet**, `/mnt/bigstore/astro-data` = **1.7 TB** in five
trees. puppy's astrocam copy is an *exact* mirror (68 night dirs, zero diff
either way), so reading from puppy did read all of astrocam, and the heavy
decompression correctly ran there with only 12 MB of CSV shipped to zog. But
three trees were never touched:

| tree | nights | size | brightness.csv |
|---|---|---|---|
| astrocam-frames | 68 | 639 G | 65 — **done** |
| eclipticam-frames (`night/` layout) | 71 | 390 G | 71 = 24,662 rows, ready |
| canon-frames | 10 | 139 G | 8 = 3,745 rows, ready |
| eos-frames | 22 | 170 G | 0 — unmeasured |
| eos-frames-live | 8 | 7.9 G | 0 — unmeasured |

**eclipticam and canon are the same near-free pass** — identical CSV schema,
28,407 rows already measured, no frame re-read. Only the eos trees need real
compute (CR2-derived, large). Doing those two is exactly IDEAS entry *"the 3
live cameras are difficult to compare currently"*, and the machinery here is
what makes it well-posed: per-camera anchors + matched instantaneous solar
altitude. That control matters MORE across cameras than across epochs —
eclipticam-v3w is the wide lens (`lens_position` 3.15 vs astrocam 1.0) and
canon is a different system, so raw means are meaningless between them.

**It cost almost no compute.** Every night already carries a
`brightness.csv` at its root (65 of 68 nights; 2026-06-08 is empty, 06-11 and
06-12 were unmeasured and are being filled with the house `scan-brightness`).
And `EXPTIME`/`GAIN` are **constant within each capture mode** — probed over
10-frame samples of all 68 nights — so normalisation needs two constants per
mode, not a header read per frame. The whole pass is CSV arithmetic.

### Three wrong turns, each caught by looking at the picture

The strand's "grade FIRST, tune second" lesson held for a fourth time.

1. **Raw brightness ranks TWILIGHT, not cloud.** The 500 brightest frames in
   the archive are *all* `sun_alt > -12`. Quality is only meaningful below a
   dark gate; this pass scores at `sun_alt < -15`.
2. **"Flat at the pedestal" is not a dead frame.** ~900 frames over three
   nights sit dead-flat at the electronic floor in long contiguous mid-night
   runs — which reads exactly like a closed cover. Rendered on a fixed
   absolute stretch they are **superb clear star fields**. Those three nights
   (**2026-06-17, 06-19, 08-07**) are the *clearest in the archive*. Culling
   the "zero-signal" end would have destroyed the best data we have.
3. **A whiteout frame is not necessarily cloud.** The first two whiteouts
   picked as "cloudy" were at `sun_alt` −5.7 and −8.1: **dawn**. The cloud
   test only means something at matched solar altitude.

### The metric

Within a mode `EXPTIME`/`GAIN` are constant, so raw mean already ranks
correctly; normalisation is needed *only* to put modes on one axis. Two
anchors that are the same physical thing in both:

    cloud_index = (mean - floor) / (median_dark - floor)

0 = clearest sky that mode ever saw, 1 = typical dark frame, >1 = cloud.
Dimensionless, so it sidesteps the étendue problem that makes raw ADU/s
incomparable. Anchors measured, not taken from config: floor/median_dark =
**512.98 / 518.62** (imx219 co-add) and **86.88 / 98.58** (imx708).

Validated by eye on a contact sheet spanning ci 0→20 in both modes: stars
survive to ci≈1–2, cloud dominates by ci≈3, whiteout by ci≈10 — **and the two
modes look alike at the same index**, which is the cross-epoch normalisation
confirmed visually rather than only arithmetically. Independent check: the
config's own note names **2026-06-15** as the known fully-cloudy night; the
ranking puts it 4th cloudiest of 65 without being told.

### THREE capture modes, not two

The 2026-07-29 imx219→imx708 swap is the known boundary, but **2026-06-09
carries 560 frames of a third mode** — single 1.2 s subs (`max` 1023,
pedestal ~64) mixed into that night's 8× co-adds (`max` 8184, pedestal ~512).
Mode is identifiable from the frame's own **saturation ceiling**, which also
gives the epoch-assignment fallback the archive needs: `POSINDEX` is absent
from 76 % of it.

### The confound — and the fix

**Per-night minimum solar altitude runs monotonically −15.17° (solstice) to
−25.77° (18 Aug), and the sensor swap sits exactly on that ramp.** Epoch 1
spans −15.2…−19.8, epoch 2 spans −20.1…−25.8: **zero overlap**. A raw
epoch-vs-epoch brightness comparison therefore measures *season*, not camera.
(Also: at 51.4°N the sun only reaches −15.2° at midsummer, so the June nights
contain **no astronomical darkness at all** — 61 % of all archived frames are
above the −15° gate. The darkness budget per night is itself a year-scale
result this strand should publish.)

**Fix: compare at matched *instantaneous* solar altitude**, where the epochs
do overlap. Median sky rate ratio imx708 : imx219 over five 1° bands from
−15 to −20 is **1.44, 1.51, 1.54, 1.65, 1.92 — median 1.54**. Its stability
across bands says this is an instrumental scalar, not weather; and
**(1.4 µm / 1.12 µm)² = 1.562**, the pixel-area ratio. So the two sensors
agree photometrically once étendue is accounted for, and **a single scalar
puts both epochs on one photometric scale** — which is what makes the
all-time sweep well-posed.

### Cull candidates — measured, NOT actioned

Deep-dark frames only (33,824 of 87,055). At ci>10: **2,644 frames (7.8 %)
over 19 nights**; at ci>3: 6,297 (18.6 %). Six nights are essentially
all-cloud: **2026-08-18 (100 %), 06-22 (100 %), 06-15 (95 %), 06-29 (88 %),
08-16 (86 %), 07-06 (69 %)**. Frames are 3.8 MB (e1) / 13.9 MB (e2).

**Threshold not set, nothing deleted.** Setting it from plausibility is the
exact mistake the inverted detector calibration documented; it wants Peter's
eye on the contact sheet first. And an overcast night is still a weather
record — "useless for stacking" is not "useless".

### Working files

`~/tmp/qualpass/` on **zog** (`quality.py`, `skyrate.py`, the ranked
`quality-frames.csv`) and on **puppy** (`probe_headers.py`, `contact.py`,
`render_pair.py`, `look/contact-sheet.png`). `quality.py` wants promoting into
`~/astro/bin` — but see the puppy drift below first.

### Found in passing: puppy's astro checkout is 86 commits behind origin/main

The **processing** host is running pre-map code, and its `astrocam/camera.json`
still has `pedestal 105` / `sky_clear_max_stops 4.0` where origin/main has
50 / 8. Measured floor over 21 imx708 nights is **86.7**, so puppy's 105 is
*above* the real floor — it would clip genuine dark sky to zero. Not touched:
pulling 86 commits onto the processing host changes processing behaviour and
is Peter's call.

## Three cameras on one axis, and astrocam's camera/placing history (2026-08-19)

Extended the quality pass to **eclipticam + canon** (their `brightness.csv`
were already there, 28,407 rows, so it was the same near-free arithmetic):
**116,022 frames, three cameras, one axis.**

`cloud_index` is **dimensionless and self-normalising**, which is what makes
this tractable — as long as EXPTIME/GAIN/resolution are constant within a
group it needs no photometric model, so the messy mode history is handled by
GROUPING rather than by modelling each sensor. eclipticam alone has four
modes (59.9 s full-res ×57 nights, 59.9 s **binned 2304×1296** ×7, 55 s ×2,
and a 30 s **v1/v3w coexistence** era in early June where ov5647 and imx708
frames share a night). canon is clean: 30 s, gain 16, 6020×4015, two POSINDEX
epochs. Groups with too few dark frames are excluded, not forced.

**The three cameras independently agree**, which is the real validation —
on the 8 nights all three were running, median dark `ci`:

| night | astrocam | eclipticam | canon |
|---|---|---|---|
| 2026-08-12 | 0.15 | 0.15 | 0.11 |
| 2026-08-13 | 0.29 | 0.21 | 0.36 |
| 2026-08-14 | 5.17 | 2.69 | 6.97 |
| 2026-08-16 | **14.38** | **7.09** | **14.19** |

Three separate optical systems calling the same nights good and bad. Note
eclipticam reads systematically **lower on cloudy nights** (7.09 vs ~14.2) —
consistent with it being the WIDE lens, averaging in more clear sky.

### Astrocam's camera identity — measured, not asked (Peter, this session)

*"astrocam is one host but 3 different cameras and possibly more camera
placings … important for brightness scaling."* Both are testable from data.

**Sensor fingerprint (hot-pixel mask = a serial number).** 63 per-night
`badpixel.fits` exist. Epoch 1 is provably **ONE physical imx219**: after the
mask converges the Jaccard overlap holds **0.84–0.98 from 2026-06-17 to
07-28**, six unbroken weeks. Epoch 2 cannot be tested this way — **its masks
are empty, `n_hot = 1` every night**. That is a live bug, not a null result:
`hot-master.json` was built at imx219 resolution (1232×1640, 2,879 px,
20 nights to 2026-07-05), so it **cannot apply to the imx708 at all** and
epoch 2 is running with **no bad-pixel masking**.

**Scene fingerprint (foliage + vignetting + skyglow gradient = where it
points).** Correlate one clear dark frame per night, coarse-gridded and
brightness-normalised. Cloud washes out scene structure, so this must compare
**clear night to previous CLEAR night** or weather masquerades as motion.
Done that way the imx708 era is stable at 0.94–0.999 — with one exception:

> **A RE-PLACING ON 2026-08-08.** corr 0.379 vs 08-07, and it *persists*
> (0.803, then 0.99+ in the new configuration). Flagged independently by the
> hot-pixel mask the same night (11,922 vs 1). Confirmed visually: from 08-08
> on, a bright diagonal enters the **top-right corner** (lit roofline or
> mount edge) plus new blobs along the bottom edge, and the left foliage
> changes. So epoch 2 contains **two placings**, not one.

**Consequence, and it is material.** My e2 anchors pooled both placings.
Split at 08-08: floor 86.76→87.61, median_dark 100.65→96.91, so the **span —
the unit of `ci` — changes by 33 %**. A frame at mean 200 scores **ci 8.16**
on placing-A anchors, **12.09** on placing-B, 9.67 pooled: wrong for both.
*Caveat:* span is `median − floor` and median_dark is weather-sensitive, so
part of that 33 % may be placing-B simply having clearer nights. Either way
**pooling across a placing boundary is unsafe** — anchors belong per
(mode × placing) segment, and segment boundaries should be *detected* by the
scene fingerprint rather than trusted from config.

Epoch 1 has candidate placing changes too (clear-to-clear dips at 07-13/07-14
and 07-27, corr 0.82–0.90) — weaker, unresolved, worth a pass at finer grid.

**Still open:** the third *physical* camera. Epoch 1 is one sensor; epoch 2's
silicon is unverifiable until bad-pixel detection is fixed for the imx708. If
the third camera was a v3→v3 swap it is invisible in headers AND currently
invisible in fingerprints — fixing the hot-pixel pipeline is what would
settle it.

## `scan-brightness` is silently broken for the whole imx219 era (2026-08-19)

Found while filling the two unmeasured astrocam nights (2026-06-11, 06-12).
The scan ran for ~190 s per hour-dir, reported `wrote … brightness.csv`, and
produced **header-only files — 0 rows, 13 hour-dirs in a row.** Success
message, no data: worse than an error.

**Cause.** `epoch_ms_from_name()` rejects short integer filenames as
non-timestamps (guard `64c5d5e`) and falls back to `epoch_ms_from_header()`,
which only reads `EPOCH_MS`. But **`EPOCH_MS` is absent from every imx219-era
frame**, and those frames are exactly the renumbered ones (`0009.fits.fz`).
Both paths return None, and the caller `continue`s past the frame silently.
So the tool cannot measure any e1-era night — the existing e1 CSVs were
written by an older version, before the guard landed. **origin/main has the
same bug**; it is live, not a local-checkout artefact.

**Fix (written and TESTED, not committed):** fall back to `DATE-OBS`, which
is present on all of them. Validated on 2026-06-11 in a scratch dir with the
originals untouched — rows now emitted with correct timestamps
(`1781222401501 / 2026-06-12T00:00:01.501`). Patch at
`~/tmp/sbfix/scan-brightness-patched` **on muppet**. Purely additive: it only
runs where the current code returns None and skips, so it cannot change the
working path. Needs Peter's go-ahead to land, being shared pipeline tooling.

### Which host should process? muppet, on both counts.

Answering Peter's *"are we processing where the data is? muppet?"*:

- **muppet holds everything** — `/mnt/bigstore/astro-data` 1.7 TB, all five
  trees. puppy holds astrocam only.
- **muppet runs current code** — `~/astro` on main, **0 behind origin/main,
  clean**. puppy is **86 behind**, with a stale `pedestal 105` where the
  measured floor is 86.7.

puppy's astrocam copy is an exact mirror, so this pass's astrocam numbers are
unaffected — but muppet is the right processing host going forward, and the
one place a tooling fix can actually be committed.

## Pending / loose ends

### THE MAP — next steps, in order (2026-08-14)

1. **Solve roll from the six complete arcs.** Feed their midpoints to
   `bin/solve-detections` → `solve-field`, scale bracketed around the measured
   **74.8 arcsec/px**. Pole and scale are known, so only roll is unknown — one
   parameter from six constraints. *Do not* hand-roll a roll scan: mine failed
   because I used catalogue RA from memory. Tycho-2 index files ARE on puppy
   (`/usr/share/astrometry/index-tycho2-*`) but are kd-tree packed and NOT
   directly readable; Vizier is unreachable from pip (connect timeout — and
   astroquery will silently serve a CACHED result, so check for ConnectTimeout
   before trusting one). `solve-field` sidesteps both by quad-matching.
2. **Then the residuals ARE the vector field** — not error to minimise away.
   `per-tile-effective-pole.md` already frames tiles as samples of it; Peter's
   refinement is to **interpolate a continuous field** rather than treat tiles as
   the resolution limit (tiles impose a false discontinuity and force a bad
   resolution-vs-noise trade).
3. **Arc curvature is a second, independent field probe.** In a perfect field an
   arc's curvature is exactly 1/r from the pole; departures measure the field
   locally — and it needs NO identification, so all ~70 arcs contribute, not just
   the 6 identified. Untested. Caveat: circle fits on short sweeps are
   ill-conditioned (a 20 px Polaris fragment gave r=10.9 vs 18.1 expected).
4. **Bound focus breathing BEFORE claiming anything atmospheric.** `LENSPOS` is
   in every frame header, so it is a measurable covariate, not a nuisance.
5. **Then `design/refraction-quest.md`** stages 1–4.

*(Geometry layer settled 2026-08-16 — see below. Step 1 is unchanged and still
the next thing to do; nothing in the quaternion/projection work blocks it, and
the roll solve's output feeds the same sphere either way.)*

### THE MAP — geometry layer settled 2026-08-16

**Three layers, each with the right tool: quaternion for the rotation,
equal-area rings for the projection, drizzle for the fractional placement.**
No code yet — this session was corrections and orientation.

**The integer shift is WITHDRAWN** (`astro 394e9da`). The 24 × 2ⁿ ring
quantisation paid +4% memory to keep a sidereal rotation an exact integer index
shift. Two independent reasons it does not survive:

1. **24 divides 360 for the SOLAR day.** The sky turns at the **sidereal** rate,
   **15.041069°/h** (360/86164.0905 s), which lands on no nice fraction of a
   24-divisible grid — so the exactness claim was never true of the real sky.
   Implementing the literal "15°/h" would have been a live bug worth **+1.55
   px/hour at astrocam's rim, +10.85 px over a 7 h night**.
2. **Sub-pixel is the point** (Peter: *"we are aiming for subpixel resolution so
   this is not important"*). Even correct-rate rounding leaves ~0.24 px at the
   rim — larger than the measured **0.14 px** single-frame astrometric
   precision, and position-dependent. It would quantise away the project's best
   measurement, permanently (resampling error bakes in).

Drizzle is already the stated resampling strategy and handles fractional offsets
natively, so the integer shift bought cheapness for something that is not the
bottleneck. **Consequence: prefer pure equal-area rings at the 1.81e7 floor** —
take the 4% back.

- **The design had already reached this on 2026-08-13** by a different route
  (*"Neither gets a free shift"*, from the measured 11.28 cells per 59.9 s
  exposure); the fallback section still advertised exactness, which is what was
  withdrawn. The rate error is the genuinely new finding.
- **The CODE was already clean** — every tool derives the rate
  (`7.2921e-5 rad/s`, `2π/86164.0905`, `360.0/86164.0905`). The error was
  confined to design prose, so no reprocessing is implied. A doc bug, not a
  data bug.

**Quaternions belong to the ROTATION layer only** (Peter raised them
2026-08-16). They solve: no gimbal-lock singularity at the pole (which is where
this camera points, with Polaris in the dead disc); correct composition and
averaging of rotations — **two logged bugs share the root cause that angles are
not a vector space** (the 11.58° circular-mean error, and the transients
"0.4° vs 179.7° are the same direction" clustering bug); **epoch composition**,
since `camera-moved-signal.md` needs every `(POSINDEX, MOVEID)` to land on ONE
sphere, which is what makes an all-time sweep across the imx219→imx708 boundary
well-posed; and the sidereal rotation as a one-parameter family
`q(t)=[cos(ωt/2), sin(ωt/2)·n̂]` with `n̂` a unit 3-vector shared across cameras.
**They do NOT help with unequal cell areas** (Peter's question) — a quaternion is
an isometry, so it preserves area distortion rather than correcting it; composing
one with an orthographic projection gives a rotated orthographic projection.
`scipy.spatial.transform.Rotation` covers all of it — no new dependency.

**`design/whole-sky-context.md` written** (`astro d9bc9e5`) — the field map, from
Peter: *"I should know more about the whole-sky astronomy world."* Pixelisation
(HEALPix + cousins), drift-scan/transit astronomy (**SDSS ran its whole imaging
survey in TDI drift-scan** — remap-then-shift in silicon; **Evryscope** is the
closest analogue; **GMN** publishes the meteor triangulation methodology
`transients.md` wants), resampling (drizzle/ePSF already adopted by name;
**IMCOM / optimal coaddition is the relevant unread work**, bearing on the open
band-limiting question), and the standards.
- **FITS WCS projection codes are declarable standards, not custom schemes**:
  `SIN` = the orthographic-with-unequal-areas Peter asked about, **`ZEA` =
  zenithal equal-area, the named fix**. (`TAN`'s divergence is also the standard
  reason the design rejects a tangent plane for eclipticam's 102° field.)
- **The HEALPix divergence has CLOSED.** We diverged only to buy the integer
  shift; with that withdrawn, the reason not to use HEALPix proper has gone.
  **Open question, worth revisiting.**
- **Recommendations, in priority order:** (1) **BJD_TDB in frame headers now** —
  light travel time across Earth's orbit is **±8 min** and Polaris's 3.97 d
  Cepheid pulsation is exactly the target it corrupts; cheap now, painful to
  retrofit across a year-scale archive. (2) Emit standard-WCS products so the
  output is readable by every tool in the field. (3) Add `drizzle` (use) +
  `astropy_healpix` (cross-check our ring areas against a reference impl) —
  both **missing** on pip; astropy/numpy/scipy are present.
  (4) **AAVSO** is the natural outside audience for the `zenith-quests.md`
  variable-star targets, and an outside audience forces calibration rigour.

**The all-time-sweep idea is LOST.** IDEAS.md carries Peter's *"I want to do all
time sweeps of the data. I've got an idea..."* — the elaboration was never
spooled and is in no session transcript (searched). Only Peter has it. NB the
quaternion epoch-composition point above may be the same thought arriving by
another road, but that is a guess, not a recovery.

### From 2026-08-13, still pending (details in `ideas/`)

- **EOS capture is being interrupted — confirmed, and the sweep video shows it.**
  Peter: *"the videos look like inch worms as the stacks collapse and build up"*.
  2026-08-12 had 6 gaps >90 s (121–646 s) against a 45 s median cadence; a 10-min
  hole empties a whole sweep window. TWO causes: `eos-focus-cycle` pass turnaround
  (~19.5 min apart, systematic) and a genuine Class-B wedge at 00:05 that
  self-recovered via the 12 V pull. **The unit is `eos-focus`, NOT
  `eos-focus-cycle`** — querying the latter returns "No entries" and looks like a
  quiet night. Proposed: a capture-continuity line in `summary.json`.
- **Multi-camera meteor coincidence is CHEAP — exposures are long.** astrocam
  59.9 s and canon 30 s against a <1 s meteor means both cameras are effectively
  always open, so no trigger or sync work is needed; matching is "same ~60 s
  window by timestamp". **26 of 31 probed astrocam meteors had a simultaneous
  canon exposure.** Blocked for *triangulation* only by canon's null
  `pole_prior_xy`/`plate_scale`. NB the 5 misses are the capture gaps above —
  interruptions directly cost coincidences.
- **`/astro/transients` and `/astro/epochs`** — two cross-camera deliverable
  pages designed but not built (crop-led transient gallery; epoch registry
  renderer). Gated on detector trustworthiness.

### Blocked / known-broken

- **`astro/map/accumulate.py` metric is wrong.** Whole-frame percentile and
  source-count metrics are dominated by FIXED contaminants (one "star" moved
  0.0 px in 59 min), so a CORRECT de-rotation scores worse. Score on **matched
  moving stars only**. The transform itself is unit-tested correct.
- **Detection on the sum stack finds only Polaris.** Robust sigma comes out 716
  ADU because the summed sky background is bright and structured. This is a
  **background-model** problem — do not tune thresholds. Median filter size 25
  also eats the arcs.
- **Strategy (Peter): bright stars only for now.** Light pollution means dim
  stars come later, so SNR is not the constraint and the max stack is adequate.

- **Transients: median-subtract fix → re-run on astrocam** (see above;
  `design/transients.md`). Then the rate-vs-night curve across the Perseids.
  **Detector recall is 1/38** against Peter's probes — see Decisions; the size
  model was inverted, real meteors are small (5–12 px).
- **Prereq for everything: pole + plate scale from real imx708 sky** (STALE from
  imx219 era). Trail-arc fit on a clear night → pole + resampling geometry, then
  RA/Dec naming + the accumulator.
- **Drizzle prototype** — detranslate Altair-region streaks onto a 6× supergrid,
  verify a point reconstruction (first super-res result).
- **ePSF builder from streaks** + predict-and-find tool (PSF + ephemeris motion).
- **Breathing: register-by-model + multi-star drizzle** (the SNR crux above).
- **moon-net solver + star-ID.**
- **The deliverables adjustment** (astro + mywebsite) Peter has in mind.
- Verify the accumulator on an archived night: stacked-PSF width vs single frame
  + anchor astrometric residuals.
- **Speaker-dither µm/mA calibration + camera-mode choice** (the astro *why* of
  the rig, whose electrical/mechanical build lives in [[electronics]]): calibrate
  loaded (mount stiffness changes response); first target is likely polecam
  between-frame stepping (no smear), the prize is Polaris photometry (never
  drifts off its pixels → needs the dither most). PoC proven; the blocker is the
  mechanical flexure stage (electronics).

## Decisions

- **canon-nightly delivered the night BEFORE last, on every run — FIXED
  2026-08-13** (astro `876a45c`). Peter noticed 2026-08-12 had no deliverables.
  Capture was fine (548 CR2s on disk, a *bigger* night than 08-11); the delivery
  chain simply targeted the wrong date. Cause: `canon-nightly` defaulted to
  `last_completed_night()`, but nights run **noon..noon UTC**, so at the timer's
  06:00 local (05:00 UTC) the session that just finished observing has not
  formally *ended* — that helper only advances at noon, seven hours later.
  **The failure mode is the lesson: totally silent.** The 06:05 run exited 0,
  published a complete artefact set and refreshed `index.json` — all for
  2026-08-11, idempotently redoing finished work. No unit went red. Never read
  "exit 0 + uploads happened" as proof the right night shipped; check the date in
  the log line. Fix: default to `night_of()`, falling back to
  `last_completed_night()` when that night has no source dir yet (the timer is
  `Persistent=true`, so a catch-up run after an outage can fire *after* noon,
  where `night_of()` would name a night still in progress). Both sides of the
  boundary verified. Note `bin/nightly-cam:277` still defaults via
  `last_completed_night()` — harmless today because canon-nightly always passes
  an explicit `--night`, but the same trap if it is ever scheduled directly
  (spooled to `ideas/`).
  (2026-08-09's absence from S3 is unrelated and genuine — no capture that night.)

  **Follow-on: the fallback now announces itself** (astro `d393603`). The
  source-dir fallback above quietly reintroduced the same bug by another route —
  if capture ever fails to create tonight's dir, delivery reaches back and
  redelivers the previous night, looking identical to a healthy run. It now logs
  the night it declined and says plainly that a missing dir is a *capture*
  failure surfacing at the delivery seam. Both branches exercised against
  fixtures. The general rule worth keeping: **when a guard's recovery path lands
  in the same state as the bug it guards against, the recovery must be loud.**
  Live on muppet (`d393603`) for tonight's timer.

  2026-08-12 backfilled by hand the same morning. A good night: 548 frames,
  20:57–03:40 UTC, verdict **clear**, **527/548 stacked** (21 out of band, 0
  saturated).
- **astro-science created 2026-08-02** as the consolidated science/theory strand
  (a **development** strand). Absorbs subpixel + breathing-theory + storage-
  discussion-theory + the sidereal direction + deliverables; those strands
  archived. Storage *engineering* stayed in astro-storage; per-camera operations
  stayed in the camera keepers.
- Gain-corrected (star-patch WB) mosaic is the standard representation for white
  point sources; interpolation blurs the undersampled signal.
- Dither strategy is per-camera; drift is the always-on dither.
- Accumulator lives on the **sphere** (projection from camera coords), not a flat
  grid; de-rotation is a rotation on the sphere.
- **The map's geometry is three layers, not one** (2026-08-16): **quaternion**
  for the rigid rotation, **equal-area projection** for the sphere→grid map,
  **drizzle** for sub-cell placement. Each is the wrong tool for the others' job.
- **No integer-shift optimisation.** Sub-pixel accuracy outranks shift
  cheapness; equal-area rings sit at the theoretical floor and drizzle absorbs
  the fraction.
- **The sidereal rate is 15.041069°/h.** Never 15.000° — that is the solar rate
  and it costs 1.55 px/hour at astrocam's rim.
- Use LENSPREP (not LENSPOS) as the per-frame focus label (4-frame lag).
