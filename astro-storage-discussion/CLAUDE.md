# Strand: astro-storage-discussion

## Mission

Design how to shrink historical astro data (starcam first) **without losing the
science**, under a hard budget of **~1 GB/night**. Optimise for three products
at once — the design's job is to show they coexist within budget:

1. **Deep integrations** — week/month-long exposures. Signal accumulation for
   faint sky, below the single-frame noise floor. ("SEE" — raw detections.)
2. **Transient / time-domain** — meteors, satellites, brightness changes; the
   outliers a deep stack throws away.
3. **Max storage reduction** — smallest archive that still serves 1 and 2.

And, tightly coupled to #1 (see "The identification axis" below): turn what we
*see* into what we can *name* — the "identify 10,000" completeness goal.

Deliverables: design notes + a storage/processing plan, then code changes in the
pipeline repo. Discussion lives here; code lands in `Berrylands/gardencam`.

## Repos this strand spans

- **`Berrylands/gardencam`** — the live pipeline; already holds most primitives.
  Code changes land here.
- **`~/astro`** — design docs. `design/zenith-quests.md` **Quest 6** is the
  companion thinking (distortion-field ID bridge, spatial + time axis).
- **`mywebsite`** — `/starcam/*` routes (public since 2026-06-02) surface products.
- Data in S3 (`starcam-berrylands-eu-west-1`, `frames/`); starcam raw currently
  unbounded on puppy — this strand defines the retention that bounds it.

## Grounding facts (verified 2026-07-25)

- **starcam capture:** 1280×720 JPEG (q85), zenith via mirrors. Cadence 1200 s
  (20 min) → ~30 frames/night (~10 MB). At 20-min cadence storage is a
  non-problem; the budget only bites in the **seconds-cadence regime** deep
  stacking needs (~7000 frames/night, ~2 GB → over budget).
- **Primitives already in the pipeline** (revive/fix, don't rebuild):
  - `gardencam.py::capture_stacked_image` — on-Pi stack, but **averages to uint8
    and saves JPEG**, re-quantising per stack → discards the sub-noise signal √N
    stacking exists to recover. **Fix: accumulate ≥float32, keep accumulator
    high-bit/lossless.**
  - `skycam_processor.py` night path — rolling mean of 5 frames + 3px blur =
    noise reduction, already implemented.
  - `HourAccumulator` + stacked still — written for starcam-night then **parked**.
    This is the running accumulator the deep-integration product needs.

## The design — three products, not one archive

No single reduced form serves all goals:

1. **Running accumulators** (nightly→weekly→monthly). Forward-computed, **O(1)
   storage** — a month costs the same disk as one deep frame. Never
   reconstructed. Delivers week/month exposures; independent of the 1 GB budget.
2. **Per-frame sidecar** — quality score (star count, FWHM, sky background,
   registration residual) + WCS/field-fit + **detected-source table**. Tiny,
   permanent. Serves transients, provenance, the signal/noise gate, **and is the
   identification dataset** (see below).
3. **Rolling raw window + compressed diff-residuals** — raw for the last N
   nights; before that, frame−master residuals (low entropy, compressible).
   Flexes to hit 1 GB/night: tighten the quality gate + residual compression
   until the night fits.

Principles: diff against the running master not the previous frame; the budget
is a knob on the quality gate (√N — keep frames that add the most signal); **no
L4 star-catalogue-only collapse** (it makes week/month exposures impossible).

## The identification axis — why storage and star-ID are the same problem

The reason to keep *many frames from different times* isn't only √N depth — it's
identification (Quest 6). Bright, catalogued stars anchor the SIP **distortion
field** (from `standing-plate-solve`); evaluate that field at a faint detection's
(x,y) and do a **local one-star cross-match** against a deep catalogue (Gaia
DR3) — the bright stars bridge to the dark ones, spatially. **The time axis
extends this:** the camera is fixed but the sky rotates, so bright anchors drift
across the whole sensor over nights — **densifying the field everywhere** and
bringing *different* bright neighbours to bear on the same faint gap. And a real
faint star's field-predicted position **persists across many frames** under many
anchoring configurations; noise/hot pixels/satellites do not — so **persistence
across time = identity.** You work down from mag-1 stars step by step to
something deep, in time as well as space.

**This forces the retention rule:** the deep stack collapses time and gives only
the *see* count. The *identify* count lives in the **per-frame source tables +
each frame's field-fit** — so those are kept forever; the raw pixels can be
freed once folded into the accumulator and reduced to a source table. See
STATE.md Decisions.

**Our own catalogue is the permanent spine.** When a detection persists across
enough frames (persistence = identity), mint it a local ID (`SC-000001`…) with
position, light curve, appearance count, classification, and a Gaia cross-match
*if one exists* (attribute, not gate). Unmatched-but-persistent sources stay as
real named-by-us stars — the "see vs identify" gap turned into records. A running
tally is the live completeness curve. Classification is free from cross-time
behaviour: **fixed = star, transient = false detection (reject), moving =
wanderer** (planet/asteroid/satellite → transient product). The catalogue is the
object never deleted; per-frame tables may later be pruned to detections that fed
a catalogue entry. See STATE.md Decisions.

## Session ritual

1. `idea --import`, then read `STATE.md` and `IDEAS.md`.
2. Triage new ideas with Peter: promote to STATE.md pending or drop; delete from
   IDEAS.md.
3. Work. Commits go to the repo the change belongs to (mostly
   `Berrylands/gardencam`; design to `~/astro`) — this dir holds only curation.
4. Session end / `dcp`: update STATE.md — what changed, pending, decisions.
   Curated prose, not a log.
