# astro-storage-discussion — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **Mission + design written** (CLAUDE.md): shrink starcam data under ~1 GB/night
  serving three products (deep integration / transient / max reduction), plus a
  fourth tightly-coupled goal — *identification* ("identify 10,000").
- **The identification axis is settled** as the conceptual core: storage and
  star-ID are the same problem. The distortion field (spatial) + the time axis
  (frames from different times) turn "see" into "name". See CLAUDE.md and Quest 6.
- **Quest 6 extended** in `~/astro/design/zenith-quests.md` with the time-axis
  subsection (field densifies as bright stars drift; persistence across time =
  identity; storage consequence).
- **Local catalogue decided** as the permanent spine (see Decisions): mint our
  own star numbers as detections persist; cross-walk to Gaia; keep a running
  tally = live completeness curve; classify every detection fixed/moving/false.

## Pending / loose ends

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
