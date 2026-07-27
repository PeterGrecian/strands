# astro-storage-discussion — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **Mission + design written** (CLAUDE.md): shrink starcam data under ~1 GB/night
  serving three products (deep integration / transient / max reduction), plus a
  fourth tightly-coupled goal — *identification* (completeness target under
  review: 10,000 → possibly 100,000, see Pending).
- **The identification axis is settled** as the conceptual core: storage and
  star-ID are the same problem. The distortion field (spatial) + the time axis
  (frames from different times) turn "see" into "name". See CLAUDE.md and Quest 6.
- **Quest 6 extended** in `~/astro/design/zenith-quests.md` with the time-axis
  subsection (field densifies as bright stars drift; persistence across time =
  identity; storage consequence).
- **Local catalogue decided** as the permanent spine (see Decisions): mint our
  own star numbers as detections persist; cross-walk to Gaia; keep a running
  tally = live completeness curve; classify every detection fixed/moving/false.
- **Grounding facts corrected (2026-07-27, verified against
  `starcam_night_daemon.py`):** night capture is **raw Bayer SGBRG10, 10-bit
  linear, 2592×1944, 2.9 s exposure / ~3 s cadence, ~10 MB/frame** — not JPEG.
  The 1280×720 JPEG q85 figure in the old grounding facts was **skycam's video
  path**. Chain is linear photons → accumulator; the JPEG-quantisation concern
  is void. Real budget pressure: ~95 GB potential raw/night → keep ratio ~1%.
- **Accumulation architecture settled in discussion (2026-07-27)** — see next
  section. Planned v3 hardware recorded in CLAUDE.md grounding facts (detail
  belongs to the `astro-v3s` strand once its mission is written).

## Accumulation architecture (discussion outcomes, 2026-07-27)

- **Whole-night unshifted sums are information-bounded — the capacity law.**
  For a rigid camera trails never cross, they *merge*: a star owns a ~3 px
  cross-drift band, and two same-band stars confuse when separated by less than
  the trail length L = min(W, T/t_pix). Stored-sum capacity C(T) = (H/3)·(W/L),
  giving the conservation law **C × T = (H/3)·W·t_pix ≈ 25M star·seconds** for
  v3-wide portrait (was ~8M for OV5647). The 100k-star target needs ~500k cells
  (≈1000 vertical × 500 horizontal at ~20% occupancy) → T ≤ ~50 s. No unshifted
  window is both deep and high-capacity: sums are eliminated *in principle*.
- **TDI / shifted accumulation is the unique escape.** Shifting the accumulator
  at the drift rate pins L at the PSF (~3–5 px): C ≈ 0.5–1.3M elements at
  unlimited T. Chosen shape: **remap-then-shift** — one *static* distortion-field
  mapping (camera fixed → measured once) into a regular (drift, dec) grid, then
  integer shifts. Polar coordinates about the celestial pole for astrocam;
  curved bands (not literal rows) for eclipticam's 102° field, where row-aligned
  trails only hold in the central strip. Pure sidereal binning (same pixel, same
  sidereal phase across nights — zero resampling, automatically CFA-safe) costs
  bins × sensor (~170 GB) and is kept only as a validation patch.
  **Resampling accuracy (idea 2026-07-27):** naive interpolation on undersampled
  data aliases — use **drizzle-style** accumulation (variable-pixel linear
  reconstruction) onto a finer-than-sensor sky grid, per CFA plane; the drift is
  a continuous dither, drizzle's ideal input. Mapping accuracy = the per-hour
  pole/k1/k2 fit quality. Verify on an archived night: stacked-PSF width vs
  single frame + anchor astrometric residuals. Resampling undoes motion
  *between* frames, never *within* an exposure — hence exposure ≲ t_pix; but the
  within-exposure trail kernel is exactly known (drift rate at each pixel), so
  1–2 px trailing is a modellable field-varying PSF, not lost signal. Full swept-sky
  accumulators: ~400–700 MB **total forever** per instrument; per-night marginal
  cost ≈ 0.
- **Raw mosaics + drift: the Earth demosaics.** Accumulate CFA planes, never
  demosaic first (interpolation smears the sub-pixel PSF); drift sweeps each sky
  point across R/G/B pixels, building full colour without interpolating.
  Shift-based accumulation must shift by the 2×2 CFA period (or keep four
  half-res planes). Single-frame colour of a faint star is CFA-phase noise;
  colour comes from accumulation.
- **Sub-pixel makes the /3 pessimistic, direction-dependently.** Along-drift
  super-resolution is free (continuous pixel-phase sweep, centroids ~0.1 px).
  Cross-drift separation is deblending-limited (~FWHM/√SNR), so channel count is
  magnitude-dependent: ~**1000 effective vertical channels at the faint limit**
  for v3w portrait (1536 raw bands).
- **Saturation is not a constraint (reframed).** The archive owns the regime
  between the catalogue floor and our noise floor; brighter stars are needed
  only as **astrometric anchors**, whose sub-pixel centroids survive saturation
  via unsaturated PSF wings (plus occasional short calibration exposures).
  Handling: a few-px exclusion halo around clipped cores (blooming/ghosts),
  absorbed by the count image. Corollary compression law for product #3: **bits
  go to the darkest pixels**; bright static regions encode at near-zero cost.
- **Instrument split under the v3 upgrade** (both → IMX708 4608×2592 10-bit):
  **astrocam → v3 standard = the depth instrument** (f/1.8, 2.6 mm aperture ≈
  4.5× photons ≈ 1.6 mag over OV5647; ~52″/px); **eclipticam → v3 wide,
  mounted portrait = the capacity instrument** (same ~1.25 mm aperture as
  OV5647 — it buys field, not depth; ~93″/px drift axis, t_pix ≈ 6.2 s).
  ~24 MB/frame → capture host must be Pi-4-class. Exposure ceiling becomes the
  sub-pixel condition (~5–6 s), halving shipped volume vs 2.9 s at no cost.
- **Pipeline shape: detect at cadence, archive at the quantum, accumulate
  forever.** Sightings/detection runs at full 3–6 s cadence; the archive bins
  frames to the capacity quantum (~30–50 s ≈ 5 px of trailing — preserves the
  500-horizontal-sample requirement) before computing residuals; accumulators
  integrate without bound.
- **Storage tiers (6 TB-disk-per-year, bought 2026-07-27).** Raw-forever stays
  impossible (14–28 TB/yr); but ~30–50 s binned residuals vs the TDI master run
  ~3–4 GB/night ≈ 0.5 TB/yr — **one disk holds every clear night's residuals
  forever** → whole-history reprocessability replaces the rolling-window-only
  model. Tier by replaceability: catalogue / source tables / accumulators /
  fields = small, replicated (S3/R2); residual bulk = single-copy on the annual
  disk, acceptable-loss (losing it costs the *option* to reprocess, not the
  science). One disk = one year = one self-contained epoch (close each year by
  snapshotting accumulators + catalogue onto it). Pairs with the hardware
  strand's disk power switch: cold archive, spun up to ship. The 1 GB/night
  budget is **rescoped to the cloud/product budget**; the disk sets the local
  bulk ceiling (~15 GB/night), undershot ~4× by the binned-residual design.

## Data reconnaissance (S3 `starcam-berrylands-eu-west-1`, checked 2026-07-25)

Bucket = **673 objects, ~1.3 GB total.** The pipeline is **further along than the
design assumed** — two structured products already exist:

- **`nights/<date>/` — the deep-integration product, already built.** 16 nights,
  2026-05-20 → 06-04. Per night: `all-night-derot.fits.fz` + `.jpg` (de-rotated
  all-night stack — **in FITS, high-bit**, so the uint8-JPEG stacking bug is
  *only* in the live-capture path, NOT here), `sum-of-sums.fits.fz`, per-hour
  `sum_NN.jpg`, `brightness.png` (light curve), `summary.json`. The summary
  carries per-hour **`pole_x/pole_y` (rotation centre) + `k1/k2` (radial
  distortion)** — i.e. **the distortion field is already being fit per hour** —
  plus `nframes_binned`, `mean_brightness`, `verdict` ("rain" etc.).
- **`sightings/<Y>/<M>/<D>/<HH>/` — the detection stream, already built.** Each
  detection = a JSON line `{epoch_ms, cx, cy, bbox, area, dark_delta,
  frame_idx, mp4}` + a tiny crop. **This is already the per-frame source table**
  the retention rule wanted — but anonymous: no persistence linking, no
  catalogue, no classification. That gap is exactly what the local catalogue
  fills → the natural prototype.
- **Coverage caveat (the blocker for prototype scope):** the two products barely
  overlap. **Sightings exist only 2026-05-18 → 05-22.** The rich `nights/`
  deep-stacks+distortion metadata are **2026-05-27 → 06-04** (earlier/other
  nights are 3-file rainouts). No single week is rich in both.

## Pending / loose ends

- **Decide the prototype (open since 2026-07-25).** Open choice, driven by the
  coverage caveat above:
  - **Which week:** sightings week (05-18→22, real detection stream, no matching
    distortion metadata) vs nights week (05-27→06-04, deep stacks + pole/k1/k2
    fits + brightness, but detections must be re-extracted from the stacks).
  - **Which capability first:** (a) persistence → local catalogue + fixed/moving/
    false classifier + tally (the star-ID spine; wants the sightings stream);
    (b) distortion-field ID bridge (anchor bright stars → verify pole+k1+k2 →
    predict faint (x,y) → local Gaia cross-match; wants nights/ metadata + a Gaia
    tier); (c) storage/retention shape (measure real week cost, prove
    accumulator+source-tables+field reconstructs, define rolling-window free).
  - **Leaning:** the persistence→catalogue prototype on the sightings week is the
    lowest-risk end-to-end proof of the conceptual spine — but note option (c)
    now has a concrete design to prove: the **remap-then-shift accumulator**
    (2026-07-27 architecture) could be prototyped on an archived week.
- **Build the sky-budget calculator** (idea 2026-07-27): Gaia-DR3-based
  N_stars(camera, exposure/accumulated depth) for the actual swept bands —
  inputs aperture, pixel scale, sky brightness; outputs limiting magnitude,
  N_stars, and a check against the C·T capacity law. Answers whether 100k is
  reachable at v3w's aperture, the accumulation hours needed, and whether depth
  or capacity binds first. Small, feeds the target confirmation below and the
  Gaia tier the ID bridge needs anyway.
- **Confirm the 100,000-star completeness target** (floated 2026-07-27; the
  capacity design was sized to it — ~500k cells, archive quantum 30–50 s). It
  10×'s the mission's completeness goal, so it wants an explicit yes before the
  mission text changes — best given with the sky-budget calculator's numbers in
  hand.
- **Write the `astro-v3s` strand mission** (strand exists, unscaffolded) — the
  v3 hardware facts (formats, AF pinning, HDR off, SAT_VAL recalibration, host
  upgrade) belong there; this strand only consumes the resulting pixel scales.
- **Eclipticam is now a planned instrument** (v3 wide, portrait) — needs a home:
  capture daemon fork, mount design, pointing choice along the ecliptic.

- **CRUCIAL to the starcam data backfill: the distortion field as an ID bridge**
  (Peter, 2026-07-25). When backfilling/reprocessing starcam data, most stars
  are too faint to plate-solve independently — so identification stalls at the
  plate-solve floor. The bridge: use the **lens-distortion field as a vector
  field** (the SIP-distortion WCS `standing-plate-solve` produces; the camera is
  *fixed*, so the field is static per camera — measured once, refined per night).
  Bright, catalogued stars anchor that field across the whole sensor; then you
  **evaluate the field at any faint detection's (x,y)** to predict its sky
  coordinate from its *relative position to nearby bright stars*, and do a
  **local one-star cross-match** against a deep catalogue (Gaia DR3) at that
  exact spot — never a blind global solve. **The bright stars bridge to the dark
  ones.** For backfill this means each archived starcam frame/stack can be
  identified far deeper than its own solvable-star count would allow, and the
  identification is consistent frame-to-frame because it rides the same static
  distortion field. Full mechanism + graduated wins live in
  `~/astro/design/zenith-quests.md` "Quest 6 → The distortion field as an ID
  bridge" (astro `5e8c3c3`). **Validate the field into the faint regime on
  self-solvable medium stars before trusting it on the backfill.** Deps: the
  standing plate-solve / SIP tools + a Gaia DR3 tier.

  **Time-axis extension (Peter, 2026-07-25):** the point of frames from
  *different times* is identification, not only √N depth. Camera fixed + sky
  rotating → bright anchors drift across the whole sensor over nights, so (a) the
  distortion field **densifies everywhere** (anchored on a grid traced by bright
  stars' tracks, not just tonight's positions), letting faint stars *between* the
  bright ones be identified when a different bright neighbour drifts near them;
  and (b) a real faint star's field-predicted position **persists across many
  frames** under many anchoring configurations while noise/hot-pixels/satellites
  do not — **persistence across time = identity.** Work down mag-1 → deep in time
  as well as space. Full mechanism in Quest 6's "time axis" subsection.

## Decisions

- **2026-07-25 — Budget is the design driver: ~1 GB/night max.** A ceiling, not a
  reversibility preference. Reframes to "best science that fits in 1 GB/night".
  *(Rescoped 2026-07-27: this is the **cloud/product** budget; the annual disk
  sets the local bulk ceiling — see below.)*
- **2026-07-25 — Optimise for all three products** (deep integration, transient,
  max reduction), plus identification. Consequence: no single reduced archive;
  long exposures computed *forward* into O(1) accumulators, not reconstructed.
- **2026-07-25 — No L4 (star-catalogue-only) collapse** — it would make
  week/month integrations impossible.
- **2026-07-25 — Retention rule (LOCKED).** Keep **forever**: the accumulator
  (deep sum + count/variance), the **per-frame detected-source tables**, and the
  **standing distortion field**. **Free after a rolling window:** the raw pixels.
  Rationale: identification comes from cross-time persistence + multi-config field
  agreement, which live in the per-frame source tables (~KB/frame — trivial vs
  the 1 GB budget), not in the time-collapsed deep stack. Pixels are freeable
  once folded into the accumulator AND reduced to a source table; identity and
  the deep image are both reconstructable without them.
  *(Extended 2026-07-27: binned residuals additionally kept forever on the
  annual disk — see storage tiers.)*
- **2026-07-25 — Build our own local catalogue as the permanent spine (LOCKED).**
  When a detection persists across enough frames (persistence = identity), mint
  it a **local ID** (`SC-000001`…) with mean field-predicted position, light
  curve, frame-appearance count, classification, and — as an *attribute, not a
  gate* — a Gaia DR3 cross-match if one exists. Consequences:
  - **Our index is primary, Gaia is a cross-walk.** Persistent detections that
    *don't* match Gaia (below the catalogue/plate-solve floor, or in gaps) stay
    as real named-by-us sources. This unmatched-but-persistent set **is** the
    "see vs identify" gap made into records, not a number — the science of what
    this rig sees that the catalogue doesn't reach.
  - **Keep a running tally** (total minted, fraction Gaia-matched, vs magnitude)
    = the Quest-6 completeness curve accumulating live, cheap aggregates.
  - **Classification falls out of cross-time positional behaviour for free:**
    position fixed (tracks sidereal drift) → **star**; appears once/twice, no
    persistence → **false detection** (cosmic ray / hot pixel / plane / noise),
    reject; persists but moves smoothly → **wanderer** (planet / asteroid /
    satellite), flag into a moving-object table that feeds the transient product.
  - **Retention refinement:** the local catalogue is the object never deleted;
    per-frame source tables may eventually be pruned to detections that
    contributed to (or updated) a catalogue entry.
- **2026-07-27 — Accumulation is shift-based; unshifted sums are dead.** The
  capacity law C·T = (H/3)·W·t_pix proves no whole-night (or any-window) sum
  serves the completeness goal. Architecture: **remap-then-shift** (static
  distortion-field remap into a (drift, dec) grid, integer shifts), CFA planes
  accumulated undemosaicked, per-pixel count image, clip-halo exclusion.
- **2026-07-27 — Eclipticam is mounted portrait** (long axis cross-drift):
  1.33× capacity for a 13% depth cost — capacity is the binding constraint for
  the capacity instrument.
- **2026-07-27 — Saturation is not a design constraint.** Bright stars are
  astrometric anchors only (centroids from unsaturated wings); the archive's
  science lives between the catalogue floor and the noise floor; residual bits
  go to the darkest pixels.
- **2026-07-27 — Storage tiering by replaceability + annual disk epochs.**
  Precious-and-small (catalogue, source tables, accumulators, fields) →
  replicated cloud. Bulk binned residuals (~30–50 s quantum) → one 6 TB disk
  per year, single-copy, self-contained epoch, cold behind the power switch.
  Detect at capture cadence; archive at the capacity quantum; accumulate
  forever.
