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

### Bootstrapping strategy — earn the right to accumulate (Peter, 2026-08-20)

The hierarchy above is not just an identification ladder, it is the **nightly
operating procedure**. Nothing goes into the precious accumulator until the night
has earned it.

**1. Daily health gate, before anything accumulates.** Has the camera been
nudged? Is there a smear on the window? Is temperature a factor tonight? Only
then start. This is a *gate*, not a weighting — see the noise/bias split below.

**2. Climb the ladder at gain 1, brightest first.** ~10 brightest stars → gather
their PSFs → build a first-level mapping into the accumulator. **Check that for
irregularities.** Then ~100 stars, still gain 1, fitting with respect to the
already-known stars. And so on: each rung's mapping makes the next rung's
identifications trustworthy.

**3. Raise gain only as depth demands it.** Once light pollution dominates, use
the fix already achieved to brighten stars, and increase gain to reach fainter.

**4. Re-accumulate retrospectively.** As the mapping's resolution improves,
redo the accumulation of earlier data at the higher resolution. Then fold in
previous nights, until ultimately all measurements are accumulated.

**5. Ordering and stopping.** Add the **darkest frames first**, and **stop when
the addition makes things worse**.

#### Why the gate and the stop rule must be separate mechanisms

This is the load-bearing part of the design, and it is already right:

- **A known constant offset is NEITHER** — it is CORRECTABLE (astro-polecam,
  2026-08-21). The tempered-glass window fitted to astrocam at epoch 3 costs a
  fixed multiplicative transmission factor. That is not noise (it does not
  average away) and not bias in the gate's sense (it is known and stable), so
  gating on it would throw away good nights forever. Carry it as a per-epoch
  photometric offset instead. **The gate must therefore be epoch-relative**: its
  job is to catch *new* contamination, and it must not flag epoch 3's constant
  offset as a smear.
- **Cloud, moonlight, faintness are NOISE.** Noise is weightable. With proper
  inverse-variance weighting you never strictly need to stop — a poor frame
  simply earns a weight near zero. "Stop when it makes things worse" is the
  unweighted special case of that, and is the robust choice.
- **A nudge, a smear, a thermal shift are BIAS.** No weighting saves you: a
  smeared frame is *systematically* wrong, and adding it with any positive
  weight corrupts the accumulator in a way more data cannot undo.

So the daily gate exists to catch **bias**, and the darkest-first-with-a-stop
rule exists to handle **noise**. Conflating them is how a precious accumulator
gets quietly poisoned.

#### Three consequences worth stating now

**The gain ladder collides with the anchor ladder.** Measured 2026-08-20: Altair
saturates at any gain >= 2, and 40 real sources saturate at gain 4. But the
bright anchors are needed at EVERY rung, not just the first — they are what the
mapping is fitted against. So the ladder cannot simply raise gain as it descends;
it needs unsaturated anchors throughout. This is exactly the asymmetric bracket
arrived at independently from the gain analysis: **~1 frame in 10 at gain 1** for
anchors, the rest deep. Two routes, same answer.

**Retrospective re-accumulation makes the accumulator a CACHE, not the archive.**
If accumulation is redone at higher resolution whenever the mapping improves,
then the raw frames must survive to be re-projected. ⚠️ **This is in direct
tension with the cull** spooled to astro-storage ("sort by brightness and delete
the entirely cloudy ones"). *Stop* is a runtime decision and is reversible;
*delete* is not. A frame excluded tonight may be wanted once the mapping is
better, or once its bias is understood and correctable. Resolve before deleting
anything: the safe form is to keep the frames and record the verdict.

**Temperature: dark current is the WRONG signal, and SENSTEMP is the right one.**
Peter: *"we will not detect dark current in london pointing a camera at the
sky."* Correct, and the mechanism matters more than the conclusion: Sony's
on-chip black-level correction is referenced to **optically-black pixels**, which
are shielded but carry the *same* dark current as the active area. Subtracting
that reference removes dark current before readout — which is exactly why the
pedestal sits at ~64 regardless of temperature. London sky-glow then dominates
whatever remains. Evidence: eclipticam's nightly floor over 2026-08-04..20 is
stable to **sd 0.62 ADU** across a month of varying temperature.

So `black_level` is **not** a thermal proxy (an earlier note here claimed it was
— wrong). picamera2 reports **`SensorTemperature`** directly in frame metadata,
so the gate gets a real reading instead: stamped as **`SENSTEMP`** from
2026-08-20 (verified on eclipticam at 27.0 degC), reusing the metadata fetch the
focus dither already made.

**And the thermal effect that actually matters is focus drift, not dark
current** — VCM/lens thermal expansion, which is the astro-breathing thread
consolidated into this strand. That is why SENSTEMP wants reading alongside
LENSPOS, and why the gate's thermal test should be PSF width, not a black-level
trend.

**The stop metric already exists.** The de-rotation work uses matched-moving-star
sharpness (single frame 4.452 = ceiling; plain sum 1.358; Polaris-arc pole
2.549). Reuse it as the "is this addition making things worse" test rather than
inventing a second metric.

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

## Archive Census and Standardization Complete (2026-08-19, Follow-up)

All open tasks from the initial brightness investigation have been executed and the complete multi-camera archive is now standardized.

**1. `scan-brightness` bug fixed and committed:**
The script was patched to fall back to `DATE-OBS` and convert it to UTC `epoch_ms`. This patch was committed and pushed to `main`, fixing the silent skipping of imx219-era frames.

**2. `puppy` processing host updated:**
Connected to `puppy` and ran `git pull`, bringing it 86 commits forward (syncing it with the new accumulator tools and fixing the stale pedestal configuration). 

**3. `astrocam` IMX708 hot-pixel mask generated:**
The mystery of `n_hot = 1` for the `imx708` was resolved: the sensor is simply incredibly clean. A scan across all August nights confirmed only two stable hot pixels: `(485, 1107)` and `(567, 1604)`. A new `hot-master.json` containing just these two pixels mapped to the `1296x2304` binned resolution was created and committed, fixing the shape-mismatch bug in `badpix.py`.

**4. `starcam` cold archive revived and scanned:**
Found 210 nights of cold storage for the legacy `starcam` (OV5647). Kicked off a background job to scan all remaining 161 unmeasured nights. Initial data reveals two distinct capture phases for starcam: 10-bit single subs (max <= 1023) and 4x co-adds (max <= 4092).

**5. Complete Multi-Camera Epoch Inventory:**
With all cameras scanned, we grouped the 160,000+ frames strictly by hardware/capture boundaries (derived from saturation ceilings and known swap dates):

| Camera | Model / Phase | Frames |
|---|---|---|
| **astrocam** | v2 (IMX219) 1.2s subs | 560 |
| **astrocam** | v2 (IMX219) 8x co-add | 78,362 |
| **astrocam** | v3s (IMX708) streaming | 8,693 |
| **canon** | EOS Canon 30s | 3,745 |
| **eclipticam** | v3w (IMX708) early, 16-bit rescaled ⚠️ MISLABELLED as OV5647 | 3,277 |
| **eclipticam** | v3w (IMX708) binned 55s | 2,995 |
| **eclipticam** | v3w (IMX708) full-res 59.9s | 18,390 |
| **starcam** | v1 (OV5647) 10-bit & 4x co-add | ~44,000+ |

**6. Cloud Index (ci) Thresholds:**
A log-scale histogram and cumulative drop curve of `ci` were generated over 75,000+ frames. 
- **ci < 2**: Drops ~44% of the archive.
- **ci < 5**: Drops ~28% of the archive (recommended loose cutoff).
This normalized metric allows long-baseline multicamera accumulation to systematically filter weather, testing how borderline frames impact the final SNR of registered stacks.

---

## Audit of the 2026-08-19/20 brightness session — and the repack it forced (2026-08-20)

Peter asked for the previous session's conclusions to be double-checked. The
headline hardware finding is real and turned out to be worth ~170 GiB of disk;
three of the conclusions built on it were wrong; and the fix that session
deployed would have killed tonight's capture.

### The nugget is real, and it pays for itself

**The Pi 5 (BCM2712 / PiSP) unpacks 10-bit raw into the TOP 10 bits of the
uint16; the Pi 4 (VC6) into the bottom.** Verified: eclipticam is a *Pi 5 Model
B Rev 1.1*, astrocam a *Pi 4 Model B Rev 1.5*, and both eclipticam IMX708 modes
had `max_adu` exactly 65472 = 1023×64. So the same sensor produced two archives
64× apart.

The six dead low-order bits are also six bits Rice cannot compress. Right-
shifting the archive is therefore **both** the consistency fix and a storage
win: measured **44–51% per frame**, eclipticam **395G → ~225G**.

`bin/repack-msb` does it: strict eligibility (`unsigned` ∧ `max > 1023` ∧
`all(%64 == 0)`), pixel-identical round-trip verified before the original is
replaced, atomic `os.replace`, and a **`RAWSHIFT` header keyword** so alignment
is self-describing and nothing downstream has to infer it from pixel values
again. `bin/repack-msb --csv` reconciles each night's `brightness.csv` *against
its frames' headers*, correcting in either direction.

**Black levels, per sensor** — from coadd arithmetic, which divides out the sky
along with everything else:

| sensor | black level | evidence | confidence |
|---|---|---|---|
| IMX219 | **64.07** | astrocam `imx219_coadd` floor 512.585, `max_adu` 8184 = 8×1023 → /8 | measured |
| OV5647 | **~15.3–15.9** | starcam `ov5647_4x_coadd` 61.184/4 = 15.30; eclipticam-v1 10180/10/64 = 15.9 | measured, two independent |
| IMX708 | **~64** (≤64.8) | earliest v3w floor 64.82, an upper bound (includes sky) | **inferred, not measured** |
| EOS 2000D | **2048** | per-channel 2046–2052 on real sky, 2026-08-11 | measured |

⚠️ **Correction (same day):** an earlier draft of this section cited the 64.07
figure as confirming **IMX708**. It does not — `imx219_coadd` is astrocam's *v2
IMX219* era. IMX708's black level is still only inferred, and the one way to
settle it is a lens-capped master dark. Exactly the class of error this session
was auditing, made while writing the audit.

### What was wrong

**1. "The v1 OV5647's pedestal is exactly 64" — wrong twice.** `build_db.py`
labels eclipticam frames by date alone, so `ov5647_v3w_coexist` is a *date
range*, not a sensor: those filenames are `…/v3w/…` — IMX708 frames. There are
**no eclipticam OV5647 frames in the DB at all**. And the OV5647 black level is
~16, not 64: `eclipticam-v1` frames are uint32 with `max = 654720 = 10×1023×64`,
i.e. 10-frame coadds, so `pedestal 10180` = 10 × 64 (MSB) × **15.9** —
corroborated by starcam's `ov5647_4x_coadd` floor 61.184/4 = **15.3**.

**2. The winter extrapolation has no mechanism and probably the wrong sign.**
The floor is already flat in sun altitude — eclipticam `min(mean_adu)` by 2° bin
(Aug 3+): −12° → 72.13, −16° → 71.85, −20° → 71.5, −24° → 71.29. **0.8 ADU
across twelve further degrees of depression**, and by 2026-08-20 the sun already
reaches −26.1° at midnight. The twilight driver is *exhausted*; there is no
remaining darkening mechanism between now and December. What is left is
aerosol/humidity/lighting seasonality, which at an urban UK site usually runs
*brighter* in winter. The method compounds it: fitting a **cumulative-minimum
envelope**, which is monotone non-increasing by construction, so any fit slopes
down regardless of physics and its slope measures how often you set records, not
sky change. Refitting the same post-Aug-1 records lands on **61.2 ADU — below
the 64 black level**, physically impossible. The reported 68.9 "kissing the
pedestal" was an artefact of one point set.

**3. "Both V3 cameras trace identical physics" is overstated.** Sky signal above
64 differs by 2.7–3.0×; the f/1.8 vs f/2.2 aperture ratio explains only 1.49×.
Nightly-floor correlation over the settled window (Aug 4–20) is **r = 0.67**,
with astrocam's spread (sd 2.06 ADU) 3× eclipticam's (0.62). Astrocam's
Jul 29 → Aug 4 descent (108.6 → 89.0) overlaps its own commissioning, so it is
not clean sky signal. The "seasonal curves lie on top of each other" plot zeroed
each camera to its own minimum, forcing agreement at one end.

Also: the **Gain 4.0** figure was a hallucination, retracted mid-session, but its
consequences were not — the −12.5 ADU overlay offset and the "multiply orange by
4 and it overlays blue" claim were never withdrawn.

### Method notes for anything built on this DB

- **Night bucketing used `date(timestamp)`**, not the house `night_of` /
  `night-dir` noon rollover, while `build_db.py`'s *mode* assignment *does* use
  night dirs — two conventions in one analysis. Since `MIN()` is dominated by
  the post-midnight half, every "night" in those plots is labelled by its **end**
  date, off by one from what we mean.
- **`MIN(mean_adu)` per night is a min-of-N estimator**, biased low with N. The
  −26° bin has 34 frames and a "floor" of 78.9 against 71.3 in the well-sampled
  −24° bin. Eclipticam has 18,834 frames to astrocam's 9,153, so cross-camera
  floor comparison is biased. Use a low percentile over a fixed sun-altitude
  window.
- **`build_db.py` swallows every error** (`except: pass` per row *and* per file,
  no counters), so the frame census is not verifiable from it. `cloud_index` is
  hardcoded per mode and **NULL for every eclipticam row** — so "cloud_index is
  dimensionless, 2.0 means the same on both cameras" is false as implemented.

### A live regression, caught and fixed

The patch that session deployed read `cfg.bayer_format` inside `_capture_thread`
— which is started `args=(cam, q, stop, log, cfg.focus_dither)` and has **no
`cfg` in scope**. `NameError` on the first frame tonight. Worse, `run()` only
did `while not stop.is_set(): time.sleep(1.0)` and never checked whether the
capture thread was alive, so the service would have sat "running" with an empty
queue producing zero frames, and `Restart=on-failure` would never have fired.

Fixed in `astro/capture/streaming.py` and **verified on eclipticam hardware**:
detection latched once per session (`raw alignment: shift=6 bits (max=65472)`),
`RAWSHIFT`/`SAMPBITS` stamped into every frame, `run()` detects a dead capture
thread, and both night daemons now return non-zero so systemd restarts.

**Two absolute-scale thresholds were silently dead** after the ÷64 shift, and are
now rescaled to sample full scale:

| threshold | was | max reachable post-shift |
|---|---|---|
| saturation guard | 0.95 × 65535 = 62258 | mean ≤ 1023 → **never fires** |
| `state.py` brightness tier | day ≥ 10 stops | log2(1023/68) = **3.91** → only ever votes `night` |

The guard now fires — confirmed live in daylight: `frame mean 1023 >= 972 (95% of
10-bit full scale)`. Both were masked by the sun-altitude path, so nothing broke,
but the brightness tier voting `night` through full daylight is the one to watch:
`state.py`'s own comment says the sun-altitude tier exists so "we never point a
sensor at the sun".

## The Bayer/PSF toolchain, rescued from muppet (2026-08-20)

An audit of 39 loose scripts in muppet's home dir found one stratum worth
keeping: ten well-documented **2026-08-01** analysis scripts, in no repo, doing
exactly this strand's core subject — PSF, undersampling, Bayer parity. Folded
into `astro/bayer.py` (library) plus `bin/bayer-heatmap`, `bin/bayer-parity`,
`bin/bayer-channels`, `bin/join-trail`, `bin/rect-heat`, and documented in
**`design/bayer-heatmap.md`** — the doc the 2026-08-01 code cited but which was
never written.

**The port found a real bug in the originals.** They measured "ADU above sky"
against a median taken across all four Bayer phases at once. The phases do not
share a background: on astrocam's IMX708 the red sky median is 85 against
green's 114. Subtract the mixed median and red comes out **negative** on a real
star — precisely the "dead channel" signature those scripts were written to
investigate:

```
star (4343,698):  mixed sky  R  -5   G  35   B  21     <- "red is dead"
                  per-chan   R  +7   G  35   B  28     <- red is alive, just weak
```

The conclusion (undersampling, not a defect) was right; the evidence was mostly
artefact. `local_sky_by_channel()` is now the default everywhere.
`bayer-channels --stats` settles it independently — red's whole-frame std is 7.7
with a tail to 716. Separately real: red **never saturates** anywhere in the
frame while G and B both reach 1023.

Also found in passing: **glacier-app has 17 eclipticam nights (2026-06-25 …
07-11) in S3 Deep Archive** (bucket `glacier-app-archive`, 156 GB total). Those
tars hold MSB-aligned FITS and now diverge from bigstore — benign and
self-identifying (no `RAWSHIFT` = never shifted). Do not re-upload 156 GB.
`splay` never got the Bayer-heatmap feature its reference implementation was
written for; parity is confirmed only for IMX708/RGGB.

## Gain bracketing — 4 bits, and the experiment that decides it

Measured live from picamera2 on eclipticam: **`AnalogueGain: (1.0, 16.0, 1.0)`**
— min 1.0, max 16.0, i.e. **4 bits of analog gain**, currently unused (both V3
cameras run at exactly 1.0, confirmed from the FITS headers).

The motivation is real and does **not** depend on the discredited winter
extrapolation. On today's numbers eclipticam's entire clear-sky signal above
black level is **~7 ADU** (71.29 − 64). Seven integers to describe the sky and
every faint star inside it. Because analog gain is applied **before** the ADC it
stretches that into more codes, so quantization error shrinks relative to signal.

**But gain only helps if quantization noise is actually significant.** If sky
shot noise already exceeds the quantization step (1/√12 ≈ 0.29 ADU), amplifying
buys nothing and costs highlight headroom. That is not yet known — and it is
exactly what a **photon transfer curve** measures. So Peter's PTC idea is not a
nice-to-have proof, it is the **prerequisite** that decides whether bracketing is
worth doing at all.

Pending, in order:

1. **PTC / gain-linearity sweep.** Sweep gain 1 → 16 against a stable source,
   plot mean vs variance. Y-intercept gives read noise in electrons; the slope
   gives conversion gain (e⁻/ADU), which converts the ~7 ADU sky into photons and
   settles whether quantization matters. Also tests the untested claim that the
   black level stays ~64 independent of gain — asserted last session from the
   *retracted* Gain-4.0 reasoning, never measured.
2. **Then, only if warranted, bracket.** Alternate gain per frame (even/odd
   minutes), branching the `mode` string (`imx708_g1` vs `imx708_g16`) so the two
   streams separate trivially in SQL. Cost to weigh: alternating halves the
   frames at each gain, so each stream accumulates half the exposure time — a
   real loss for the map.

## Pending from this session

### RESOLVED 2026-08-20: pedestal split three ways

The whole muddle came from one field carrying three different meanings. Split
in every `camera.json`:

| field | what it is | may be chosen freely? |
|---|---|---|
| `pedestal` | **chart floor** — the `log2(mean/pedestal)` axis reference, set low for footroom | yes, it is arbitrary by design |
| `black_level` | **sensor electronic zero** — what a photosite reads with no photons | no, it is physics |
| `blackest_observed` | **darkest sky ever recorded** = black_level + minimum real sky | no, it is data |

`blackest_observed - black_level` is the **footroom**: eclipticam **7.29 ADU**,
astrocam ~19.8, canon ~542. That number is the whole argument about gain, and
previously it was unstateable because one field was being asked to be all three.

This also settles the 68 → 50 argument: under the split `pedestal` **is** the
chart floor, so 50 is correct and consistent with astrocam, while the measured
value moves to `black_level: 64` where nothing can quietly redefine it. Nothing
was lost, and the stale notes that claimed 4380 was a "BINNED-BASIS 2×2 sum ~4×
too high" are corrected — 4380 was simply 68.4 MSB-aligned, proven by the binned
and full-res floors differing by ~4 ADU rather than 4×.

`black_level` is wired through capture and stamped into every frame as
**`BLACKLVL`** (verified on eclipticam hardware), so downstream arithmetic
subtracts the physical zero and never the chart floor. A split nothing reads
would just be documentation.

`starcam` gained a `black_level` but deliberately **no** `pedestal` — it has no
live chart. Its two modes are also not on a common scale (`ov5647_4x_coadd`
floors at 61.18 on a 4-coadd basis; `ov5647_10bit_subs` floors at 0.001, so its
black level was already subtracted upstream). Resolve before using starcam in
cross-camera accumulation.

### Gain: don't bracket — move it (Peter, 2026-08-20)

Peter: *"the only loss in increasing the gain will be in bright stars which are
not an issue anyway."* Correct, and it collapses the plan. Bright stars already
clip at gain 1.0 (astrocam's G and B top pixels read 1023 today), so raising
gain loses nothing not already lost. **Bracketing exists to preserve both ends
of a dynamic range; if the bright end does not matter there is no second end,
and alternating just halves the frames in each stream for nothing.**

The real ceiling is not stars but **the sky on a bright night** — brightest
eclipticam deep-night frame mean is 166.16 ADU:

| gain | sky mean clips above | vs brightest recorded night |
|---|---|---|
| 4 | 303.8 | fits, 1.8× margin |
| 8 | 183.9 | fits, 11% margin |
| 16 | 123.9 | **clips** |

**Gain 4 is the safe choice; 8 is the aggressive limit; 16 is out.**

⚠️ **Superseded within the hour by the right measurement.** Frame means are the
wrong ceiling — *pixels* clip long before the frame mean does. On a dark clear
frame (2026-08-19, sky 14 ADU above black):

| gain | headroom above sky (gain-1 ADU) | pixels clipped |
|---|---|---|
| 1 | — | 77 (0.0006%) |
| 4 | 225.8 | 3,352 (0.028%) |
| 8 | 105.9 | 7,763 (0.065%) |
| 16 | 45.9 | **523,006 (4.38%)** |

A cliff, not a slope: 16 clips **67× more pixels than 8**. The p99.9 pixel sits
86 ADU above sky while gain 16 leaves only 45.9, so it eats the whole top of the
star field. Winter does not rescue it — the floor has stopped falling (twilight
exhausted below ~−12°), so even the darkest frame only improves the headroom to
~52.6 ADU.

**Peter's cloud argument holds per NIGHT, not per FRAME.** 6.8% of deep-night
frames would clip whole-frame at gain 16, and they are not all cloudy:
2026-08-10 had a near-record floor of 72.1 (clear) yet 23% of its frames would
clip. That is the Moon crossing an otherwise clear night — a separate cull from
cloud.

And one bright star is load-bearing: **polefit takes the pole from Polaris's own
arc**, which beat both existing tools. At 4.4% of pixels saturated, bright-star
centroids stop being trustworthy, so "bright stars don't matter" has an exception
that happens to carry our astrometry.

**Count SOURCES, not pixels.** Pixel counts overstate it — most components above
threshold are hot pixels and cosmic rays. Filtering to components of >=3 px on a
dark clear frame:

| gain | real sources saturated | headroom |
|---|---|---|
| 2 | 11 | 2× |
| 4 | **40** | 4× |
| 8 | 58 | 8× |
| 16 | catastrophic — 4.38% of ALL pixels | 16× |

The cliff is precisely between 8 and 16: gain 8 costs only 18 more saturated
stars than gain 4, while 16 begins clipping the noise floor itself.

### Altair, not Polaris — and the bracket that survives (Peter, 2026-08-20)

**Correction:** an earlier draft said "polefit takes the pole from Polaris's own
arc" as the reason to protect bright stars *on eclipticam*. Wrong camera.
Polaris/polefit is **astrocam**. **eclipticam-v3w has no pole in frame** — which
is exactly why moon/sun-net hand-marking existed as scaffolding, and why it was
retired 2026-07-06 in favour of **Altair star-ID** (`design/
retire-moon-marking-v1.md`, `design/standing-plate-solve.md`).

Altair is magnitude 0.76, so it saturates at **any gain >= 2**. That revives
bracketing — but NOT the version Peter correctly killed. 50/50 HDR bracketing to
protect pretty bright stars stays dead. What survives is that **the plate solve
and the accumulator want opposite gains**: star-ID needs unsaturated anchors, the
deep stack wants low quantization. Since the solve is **per-night, not
per-frame**, the cheap form is asymmetric — **1 frame in 10 at gain 1 for
astrometry, 9 at gain 8** — costing 10% of frames rather than 50%.

**On moonlight:** the 2026-07-06 retirement removed the Moon as an *anchor*, not
as a source of sky-glow. Moonlight raises the background whether or not the Moon
is a target, which is why clear nights still contain bright frames.

**Aside:** the brightest object in a v3w frame sits at y~2176, inside the band
`privacy.json` flags as neighbouring windows (bottom 232 binned rows). The
brightest thing in eclipticam's field is a neighbour's window, not a star —
exclude it from any gain or photometric analysis.

How much it buys is still unmeasured and hinges entirely on conversion gain
`g` (e⁻/ADU). Sky sits 7.29 ADU above black level, quantization noise is
1/√12 = 0.289 ADU, shot noise is √(7.29/g): at g ≈ 6 quantization inflates total
noise ~3%, at g ≈ 20 ~11% — i.e. worth between 7% and 23% more exposure time.
Worth having, not transformative. **The PTC is still step one**, because it
measures `g` and read noise directly and settles which end we are at; it also
tests whether black level moves with gain, which `black_level` now has a home
for. Then set the gain once, rather than bracketing.

### Still open

- **`pedestal` 68 → 50 (commit 1b5a703) — superseded by the split above.** It is convention, not
  data: it touches only `stops_above_pedestal`, a derived column recomputable
  from `mean`, and `state.py` currently decides on `sun_altitude` anyway. But it
  discards the one *measured* value (4380/64 = 68.4, corroborated by 64.07 from
  the imx219 coadd) for a deliberately fictional floor — astrocam's own
  `pedestal_notes` say so explicitly. `pedestal` now means "chart floor" on every
  camera and no field records the measurement. **Decide: revert, or split the
  field into `pedestal` (chart) + `black_level` (measured).**
- ~~Rebuild the quality DB.~~ **DONE 2026-08-20 — `bin/build-quality-db`.** See
  the section below.
- **Per-night derived products** (`max/min/sum.fits.fz`, 198 files) — `sum` is
  float32 on the old scale, needs regenerating post-repack.
- **eclipticam-v1** (2,929 files, 9.3 GiB) deliberately *not* repacked: they are
  uint32 10-frame coadds and shifting changes the pedestal basis 10180 → 159.
  Calibration decision, not mechanical.
- The 39 originals are still in muppet's `~` and copied to `~/tmp/muppet-orphans`
  on pip. Once confirmed, `trash` them — not `rm`.
- **IMX708 black level wants a real measurement.** Cap the lens, take a master
  dark. It is the only sensor of the four still inferred, it is the one carrying
  99% of the data, and the same run settles whether black level moves with gain.

### The 2026-06-22 gap is explained (Peter, 2026-08-20)

`night/2026-06-22` does not exist and `06-23` holds just 2 frames. **Storage
problems that night, and it was cloudy** — so nothing of value was lost, and the
gap needs no investigation. Recorded because it sits right on the binned →
full-res boundary and looks exactly like a capture regression to anyone reading
the archive cold. (Resolution actually went full-res 06-10…06-14, *back* to
binned 06-15…06-21, then full-res from 06-23 — so `build_db.py`'s date-range
mode labels get the resolution boundary wrong too, a third instance of the same
label-by-date flaw.)


---

## The census is trustworthy now — `bin/build-quality-db` (2026-08-20)

`build_db.py` is out of muppet's `~` and into the repo, with all five defects
fixed: sensor and geometry now come from a FITS header rather than a date range,
nights from `night_of`, every skip counted into a `scan_log` table, and the
output written to a temp and swapped atomically with `RAWSHIFT` per frame — so a
rebuild *reproduces* the repack correction instead of reverting it. Rebuilt at
**160,918 rows**, matching the old DB exactly.

**The counters earned themselves immediately.** 8,795 astrocam rows threw
KeyError, and the instinct was to relax the parser and "recover" them. Checking
first: **8,780 of the 8,795 were already in the DB** via the other CSV schema —
`scan-brightness` writes one format into the night tree, the capture daemons
write another into `YYYY/MM/DD/<cam>/`, and they describe the SAME frames.
Ingesting both would have inflated astrocam's census by 10%. Now skipped
deliberately as `skip:capture_schema_dup`, documented so nobody "fixes" it.

### `cohort` — pooling is now structural, not remembered

Peter (2026-08-20): *canon and starcam will be inserted into the series when we
understand them better; they need to be treated separately.* The `cohort` column
makes that a property of the schema. It keys on everything that must MATCH before
frames may be pooled, all measured: sensor, geometry, exposure, gain, raw
alignment, coadd depth.

| cohort | frames |
|---|---|
| `astrocam/-/imx219/3280x2464/9.6s/g4/rs0/x8` | 77,904 |
| `starcam/-/starcam/2592x1944/2.9s/g16/rs0` | 36,863 |
| `eclipticam/v3w/imx708/4608x2592/59.9s/g1/rs6` | 18,653 |
| `astrocam/-/imx708/4608x2592/59.9s/g1/rs0` | 9,153 |
| `starcam/-/starcam/1296x972/2.9s/g16/rs0` | 7,129 |
| `canon/-/canon/6020x4015/30s/g16/rs0` | 3,490 |

17 cohorts in all. `GROUP BY cohort` is now the honest unit for any census,
pixel-second total or accumulation.

### ⚠️ The "Gain 4.0 hallucination" was a MISATTRIBUTION, not an invention

Correcting this morning's account. The 2026-08-19/20 session's Gain 4.0 was read
from a **real** header: astrocam's v2 imx219 era genuinely ran at
`GAIN = 4.0, EXPTIME = 9.6, NCOADD = 8`. The error was attaching it to the
**imx708** v3s that replaced it. The number was true; the sensor was wrong —
which is the same failure mode as the OV5647 and resolution mislabels, and it
argues for reading identity from headers rather than from era assumptions.

### We already own the gain experiment

The gain question does not need a new capture to get started — **the archive
already contains it**:

- **78k frames at gain 4** (astrocam v2, imx219, 8x1.2s coadd)
- **37k frames at gain 16** (starcam, ov5647, 8x2.9s coadd)

Cautionary and confounded, but pointed: of starcam's 36,863 gain-16 frames only
**698 are flag-clean**. The cause is the clipped pedestal rather than the gain
itself, so this is not proof — but "the one camera we ran at gain 16 produced
almost nothing usable" is worth understanding *before* raising eclipticam's gain.
Mine these two cohorts before running a PTC from scratch.

### v2 is next — and it is a familiar problem

Peter: *the v2 frames are probably the next to understand; it took a while to
grip the two v3 cameras because of the Pi 4/5 differences.* The good news is that
the thing that made v3 hard does not apply — astrocam has always been a Pi 4, so
it has been LSB-aligned throughout. What replaces it is exactly analogous:

| | v3 (eclipticam) | v2 (astrocam) |
|---|---|---|
| the multiplier | bit-shift x64 (Pi 5 MSB) | **coadd x8 (`NCOADD`)** |
| ceiling | 65472 = 1023 x 64 | 8184 = 1023 x 8 |
| consistency | was mixed, now uniform | **uniform across all 77,904 frames** |
| recorded? | `RAWSHIFT` header | `NCOADD` header — explicit, now in the cohort |

Both eras are "the numbers are N x what you think", but v2's N never varied,
which is why it yields the **best-measured black level in the estate** (64.07,
the only Pi sensor measured rather than inferred).

**The one real v2 puzzle:** the 666 `1.2s` sub frames floor at **69.888** while
the coadd arithmetic gives **64.07**. Short subs collect *less* sky, so they
should sit closer to the black level, not 5.8 ADU above it. Different gain, a
different capture path, or the subs are not what the label says. Same error class
as the two mislabels found today — start there.

### Known limitation in the new tool

`dir_metadata` reads `ext=-1`, which is not always the image HDU: 326 astrocam
frames from `2026-06-09/00` report a nonsensical 7x30 shape and land in a `?`
cohort. Harmless (they are excluded from pixel-second totals by having no npix)
but it should select the image HDU explicitly.


## Epoch 3 (astrocam tempered glass) — measured, not assumed (astro-polecam, 2026-08-21)

Relayed via strand mail, correcting three things in my epoch-3 note:

**The ~8% transmission loss is a TEXTBOOK ESTIMATE, not a measurement.** Fresnel
at normal incidence, R = ((n1-n2)/(n1+n2))^2 = 0.04 per air-glass surface at
n=1.5, two surfaces → T = 0.9216 = 7.84% = 0.089 mag = 0.118 stops. It assumes
the protector is UNCOATED, and many ship with AR/"HD clear" treatment which would
put the real loss well below 8%. Do not treat 0.12 stops as calibrated.

**Measure it with STARS, not sky.** A fixed star's summed flux drops by exactly
the transmission factor regardless of sky conditions; the sky-mean route is
hopeless because night-to-night scatter swamps 0.12 stops (08-19 per-hour means
ran 96–166, 08-20 ran 132–282). The plate-solve + limiting-mag machinery can do
this across the 08-19/08-20 boundary.

**Epoch 3 is PHOTOMETRIC, not geometric — the mount is clamped.** Phase-
correlating the 08-19 and 08-20 max-stacks gives 2 px at half-res = ~4 px native
= **3.4 arcmin**. So the epoch-2 pole/plate solution remains a good starting
point and the accumulator may be able to **continue across the boundary** with a
per-epoch photometric offset rather than restarting. Off-axis check: R rises to
4.4%/surface at the 37.5° diagonal, so only ~0.9% corner-to-centre — no
meaningful vignetting gradient, which is the part that would have hurt radial
geometry.

**Backfill done, so the boundary is now sharp.** The 2026-08-20 night was
captured under epoch 3 but stamped POSINDEX=2 (config bumped the next morning);
all 465 frames re-stamped 2026-08-21. Verified: 2026-08-20 = {3: 465},
2026-08-19 = {2: 460}. ⚠️ **`max/min/sum.fits.fz` carry NO POSINDEX at all** —
the derived products sit outside the stamping convention entirely, which matters
if anything accumulates from co-adds. Adds to the existing pending item about
those products still being on the pre-repack scale.

## HTM step 1 — and the plate scale that blocks it (2026-08-21)

**Answer to "how low should we go?": HTM level 4.** L4 is the *coarsest* level
that separates the ten brightest anchors — measured, not estimated: L2 puts two
pairs in one trixel, L3 still collides (Schedar `N31131` and Gamma Cas `N31130`,
4.2° apart, share the 13.6° parent `N3113`), L4 separates all ten. L4 is 2048
trixels, 20.1 deg², ~6.8° a side — still ~7× coarser than early pointing error,
so nothing lands in the wrong cell. L3 remains the useful "whole field in ~34
cells" overview.

**HTM is in** (`astro/htm.py`). Verified: prefix nesting exact to level 12 (the
level-(N-1) id *is* the level-N id `>> 2`), all 8 base faces reachable, and the
four children's areas sum to the parent's exactly — the 4:1 property the
accumulator depends on. Within L4 trixel areas vary by 2.10×; that is fine
because it is *deterministic* — `trixel_area` computes it exactly, so a
surface-brightness accumulator divides it out. An equal-area grid buys nothing
we cannot compute, and HTM's prefix code is worth more: the ladder's rungs are
the same integers at different lengths.

### The blocker: astrocam's imx708 plate scale is genuinely unsolved

`camera.json` already says so (`plate_scale 0.0190` marked STALE, "must be
re-solved from imx708 sky frames"), but `_epoch.wcs.json` still serves 0.02081
on imx219 3280×2464 geometry and that is what tools actually consume. This
session tried to close it and **did not succeed**. What is now known:

| method | full-res °/px |
|---|---|
| single night (2026-08-12), Polaris track | 0.0210 |
| four nights separately | 0.0166, 0.0188, 0.0206, 0.0186 |
| joint fit, 14 nights, 111 points | 0.0186 ± 0.0010 (5.6%) |
| estate legacy (`_epoch.wcs.json`) | 0.02081 |
| imx708 spec, f=4.74 mm, 1.4 µm | 0.01690 |

**The honest reading: 0.0186 ± 6%, which is consistent with BOTH candidates.**
Polaris cannot separate them. A single night that appears to agree with one to
1% is over-reading its own noise — 2026-08-12 did exactly that, and an early
claim in this session that the legacy value was "23% too large" was simply
wrong, in the wrong direction.

**Why Polaris fails, and it is geometry not sloppiness.** Peter asked how well
the points actually fit a circle. **Superbly — 0.26 px rms per night** (0.17–0.56
on good nights), so the detections are excellent and an earlier "~1.5 px scatter"
claim in this session was wrong (that was residual about a mis-specified
rate-constrained fit, not about a circle). The precision simply does not buy
radius precision: the arc is ~16 px radius sagging ~6 px over 100°, so centre and
radius slide together along a valley.

The killer is that the model choice moves the answer more than the noise does.
Pure circle gives R = 17.0 px (scale 0.0184); adding the physically-required
drift term gives R = 20.4 px (scale 0.0153) **while fitting better**. A 20% swing
on a modelling decision. Bootstrap σ_R is only 0.55 px, so this is not noise —
drift and radius are near-degenerate over a short arc. **Polaris cannot settle
the plate scale, whatever is done to the fitting.** Peter's instinct that it is
the clean target is right about *distortion* (none worth speaking of over 0.6°)
but proximity to the pole is what destroys the lever arm. Not saturation either:
per-frame peaks run ~440 of 1023 ADU.

**CORRECTED same session.** The first version of this section said the camera
was fixed and therefore nights were combinable. Peter: *"the camera does move
every night — the setup is prone to temperature humidity and wind variance."*
"Unclamped three times" means three HARD epoch breaks, not nightly stability.
So the 14-night joint fit was mis-specified (it shared one pole) and its rms of
5.23 px was the model being wrong, not the data being bad. Do not use it.

**Within-night drift is now MEASURED.** Fitting `p = c + d·t + Rot(ωt)v` — still
linear, because the angles come from the clock — improves the residual on 9 of
10 nights (08-12: 0.89 → 0.36 px) and returns drift rates of **0.3–1.6 px/hour**,
i.e. a few px across a night. That is the thermal/wind variance Peter describes,
and it has a consequence beyond calibration: **the accumulator cannot assume a
fixed pole even within one night.** Frames need registration, not just rotation.

### The fix, not yet built: two stars, each doing what it is good at

Fix the **pole** with a star far out (Kochab, arc radius ~470 px, sagitta
~170 px) — the centre of rotation does not require knowing *which* star it is,
so no identification is needed for this half. Then measure **Polaris's radius**
from that now-solid centre; it stops having to determine the centre and only
supplies a distance. Note `0.14 px` elsewhere in this file is **cross-streak**
line-fit precision, i.e. *perpendicular to a trail* — which is exactly the
radial direction of a pole-centred arc. So once the centre is known
independently, the max-stack ridge should give the radius far better than
per-frame centroids did.

### Tools added this session

- `astro/htm.py` — trixel ids/names/vertices/exact areas; prefix code.
- `astro/skypos.py` — epoch-aware pole distances, 22 bright northern stars.
- `bin/htm-anchors` — the anchor set with L4 ids and predicted ring radii.
- `bin/fit-pole-track` — pole by tracking one star across a night with the
  rotation angles fixed by the clock (`p = c + Rot(ωt)v`, linear in c and v).
  Carries the sweep consistency check: a night of length T subtends exactly
  15.041·T degrees and no more, so an arc that appears to subtend more is a
  wrong centre or a mis-identified star. Doubles as the daily nudge gate.
- **Bug fixed:** `polefit.py` hardcoded `POLARIS_SEP_DEG = 0.7525` commented as
  the 2026 value. It is a mid-1990s value — J2000 is 0.7359°, **2026 is
  0.6262°**. Not cosmetic: `fit_pole` uses that radius as the *selector* among
  candidate arcs, so a 20%-stale value can pick the wrong star. Now computed per
  epoch. (`fit-pole-polaris` returns radius 21.1 px on 2026-08-12 against ~16 px
  from tracking — it is picking up the thick max-stack band, and should be
  regarded as unreliable for this camera until the two-star fit replaces it.)

### Known-bad in what was built

`fit-pole-track`'s "brightest peak in the box" picked the wrong object on 5 of
116 detections (nights 08-10, 08-14, 08-16, 08-18, 08-19 have detections
20–70 px off the arc). It needs a sanity filter against the running arc before
it is trusted unattended as the nudge gate.

### Environment

`~/astro/.venv` did not exist on pip — that is why this work had been
muppet-only. Created 2026-08-21 from `requirements.txt`; it is also what lets
splay open FITS on pip. `~/bigstore-astro` is an SMB share of the data and reads
at **~2 MB/s**, so night products (max/sum, a few MB) are fine on pip but
per-frame passes belong on muppet — 14 nights × 10 frames took 3.5 minutes.

### Prior art I failed to check first (2026-08-21)

`bin/` already had a whole pole family — `fit-pole`, `fit-per-star-poles`,
`fit-tile-poles`, `fit-tile-pole-tangent`, `refine-tile-pole`,
`fit-distortion-from-poles`, `sweep-tile-poles` — plus
`design/per-tile-effective-pole.md`. `fit-pole-track` was written without
looking, which is the house-tool rule broken. They use a better method than
circle fitting: **derotate frames about a trial pole, stack, and maximise
sharpness** — every star, every frame, which is the real operational form of
"rotate the image about the pole". `fit-per-star-poles` already documents the
exact degeneracy rediscovered the hard way here: *"scatter along the
perpendicular bisector of each star's arc — the expected under-determination of
a single-star pole fit (arc length is short → fit is flat along the bisector)."*

**The distortion-free pole method, most likely recovered** (Peter: *"there is a
distortion free way of doing it but I've forgotten, look in sessions"*). His own
words, 2026-07-02: *"the pole from polaris and the pole from edge stars is
different. I'm thinking of looking only in the first 10 degrees from the pole,
that's the area we know most about"*, and *"more stars on the same side of the
pole than opposite within 10 degrees of the pole"*. So: **many stars within ~10°
of the pole** — distortion-free by *restriction* rather than by modelling. It
succeeds where the Polaris fit fails because one short arc is degenerate along
its own perpendicular bisector, but stars at different position angles have
different bisectors and the degeneracies intersect. The starchart remark is the
failure mode: stars all on one side leave the bisectors parallel and the
degeneracy alive. NEEDS PETER'S CONFIRMATION that this is the method he meant.

A second exactly-true property, derivable from `fit-distortion-from-poles`'s own
model `P_eff(p) = p + (1/J_r(p))·(P_true − p)`: at `p = P_true` the effective
pole equals the true pole **for any distortion**. So the true pole is the FIXED
POINT of the effective-pole map, reachable by iterating a tile onto its own
reported pole with no distortion model at all.

## PLATE SCALE SOLVED — 0.0208 deg/px, from Peter's shared-radius constraint (2026-08-21)

**`plate_scale_deg_px = 0.02075 ± 0.00089` full-res (4.3%).** The estate's legacy
0.02081 is confirmed to **0.3%** — right all along, but now for a measured reason
instead of by inheritance from the imx219. The imx708 **spec value 0.01690 is
excluded at 5.5σ**: effective focal length at the pole's field position is ~3.8 mm,
not the catalogue 4.74 mm. `camera.json`'s `plate_scale_notes` ("STALE ... must be
re-solved") can now be closed for epoch 2.

**The constraint that cracked it was Peter's**, in one sentence: *"the cyan circle
should always be the same size."* Polaris's arc radius is pole-distance ÷ plate
scale — neither changes, ever. The camera moving changes only the CENTRE. So fit
all nights at once with ONE shared R and a free centre per night. Each night alone
is degenerate (centre and radius slide together along a ~100° arc of a 15 px
circle); eleven nights sharing R over-determine it.

    R = 15.090 px half-res, 11 nights, overall rms 0.485 px
    per-night rms 0.22-0.88 px vs 0.17-0.56 for FREE radii

Imposing one radius costs almost nothing, which is itself the proof that one
radius really does explain every night. Seed each night's centre from its own
circle fit — seeding from the point-median drops two nights into a local minimum
20 px away and quietly corrupts R.

**Nightly camera motion, now cleanly separated** because the centres are no longer
absorbing radius error: **4.60 px median step between consecutive nights, 17.8 px
spread over three weeks.** Confirms Peter's "temperature humidity and wind".

**What is still unconstrained, and why.** Peter's 18 eyeball pole probes sit
(−2.2, −4.9) px from the fitted centres — a real systematic, unchanged by sharing
R. Its direction is **18.1° from the arc's chord-bisector**, i.e. along the one
axis a short arc cannot constrain at all. Sharing R fixed the circle's SIZE, not
its POSITION along that axis. The cure is arcs at other position angles — which is
exactly the remembered "many stars within 10° of the pole" method. Do that next.

Consequence for the field: with f_eff ~3.8 mm the FOV is ~3700 deg² (not the
~2700 estimated from the spec), so ~184 L4 trixels in frame and ~0.24 expected
colliding pairs for ten anchors. **HTM level 4 stands.**

### The PSF is real — three hypotheses killed

Single-frame FWHM is **3.29 ± 0.19 px** half-res, and the max-stack trail is
~3.3 px. So:

1. **NOT focus dither.** Retracted: this session claimed a max stack takes the
   worst focus of the dither and so inflates the trail, and recommended a
   focus-selected stack. Worth ≤0.5 px across the whole LENSPOS range. Not worth
   building.
2. **NOT chromatic aberration from binning RGGB.** R−B separation is 0.69 full-res
   px = 0.35 half-res. (Per-channel FWHM comparisons are unreliable — second
   moments inflate on the wings at 4× lower SNR.)
3. **NOT a wrong pole** — the sweep-exceeds-the-clock flag raised repeatedly today
   is explained by PSF extension at the trail ends, `2·asin(2/R)` ≈ 16° at R≈14.
   `fit-pole-track`'s check needs that term; as written it cries wolf.

So ~3.3 px half-res (6.6 px full-res, ~9 µm) is genuine optics at 16-20° off axis.
That matters for the sub-pixel programme: it is the real sampling kernel.

**LENSPOS is a slow RAMP, not a 3-value dither** — 1.30 → 1.58 in 0.02 steps over
36 consecutive frames, perfectly correlated with time. So focus breathing and sky
rotation are degenerate in any consecutive block, and the 0.216% magnification
signal measured across the ramp is uninterpretable. Separating breathing needs
INTERLEAVED focus values, not a ramp.

### The trail is a time series — a free nightly quality gate

Azimuth about the pole IS time (Peter). Reading the max-stack trail radially at
each azimuth gives transparency (peak brightness), seeing (FWHM) and pole position
(peak radius) against time, with **no per-frame reads**. On 2026-08-13 at 6.1 h in,
peak brightness collapses 255 → 95 and the width/radius measurements go to noise:
cloud arriving, exactly the "weather front" Peter predicted. 2026-08-12 holds 255
all night and fades only at dawn.

Two consequences: the last hour of 08-13 must be cut from any geometry (it was in
the earlier fits), and this is most of the daily bootstrapping gate for free.
`~/tmp/htm-step1/trail-timeseries.png`.
