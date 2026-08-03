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

## Pending / loose ends

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
