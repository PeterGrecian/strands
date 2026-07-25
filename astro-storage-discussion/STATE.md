# astro-storage-discussion — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- (new strand — nothing recorded yet)

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

## Decisions
