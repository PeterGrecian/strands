# astro-science — state

*Curated summary of where this strand is. Updated at the end of each session.
The science/insight layer of the astro estate. **Consolidated 2026-08-02** from
astro-subpixel + astro-breathing + astro-storage-discussion (theory half) +
astro-v3s (sidereal direction) + astro-deliverables — those strands are archived;
their operational/engineering halves went to the keepers (polecam/eclipticam/
canon/storage).*

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
  - **PENDING**: run the stack + review `max.jpg`, then the deploy, then a
    systemd timer (post-dawn) for hands-off nightly delivery. **scs stays
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
- **Unresolved:** the 23:51:42 canon candidate (~54 px by hand) isn't recovered;
  the eclipticam pair Peter screengrabbed isn't yet located in the subs.

## Pending / loose ends

- **Transients: median-subtract fix → re-run on astrocam** (see above;
  `design/transients.md`). Then the rate-vs-night curve across the Perseids.
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
- Use LENSPREP (not LENSPOS) as the per-frame focus label (4-frame lag).
