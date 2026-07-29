# astro-storage — ideas inbox

- **Glacier every day** (Peter, 2026-07-12): nightly ship of astro data to
  Deep Archive **via `cold-archive-night`** (the astro cold tool — NOT
  glacier-app; see STATE.md). ~20G/day is virtually free *per day* (~$0.02/mo)
  but accumulates: ~7.3TB/yr → run-rate ~$7/mo after a year, rising yearly.
  So the real question is retention per data class, not whether to ship.
  Mechanics: 180-day minimum makes "keep ≥6 months" the pricing floor;
  S3 lifecycle rules can auto-expire raw after N months while derived
  products stay forever. Powerline link fine at daily volume (~10 min/night).
  Still to decide: which classes (.fz raw / jpg / mp4 / derived) get which
  retention.

- **The t² argument** (Peter, 2026-07-12): constant capture rate +
  keep-everything ⇒ holdings grow linearly ⇒ **cumulative spend ∝ t²**
  (~$43×t² at 20G/day in Deep Archive). Squashing with a bounded
  full-cadence window makes the full-res term linear (flat run-rate);
  the full resolution pyramid (chunk→daily→monthly→yearly, bounded
  windows per level — the RRD property) makes total storage O(1) and
  kills the quadratic entirely. Retention design = choosing the
  coefficients of that polynomial.

- **Data-reduction day: retention = squashable** (Peter, 2026-07-12).
  "Squashing" = the existing process of reducing *temporal* resolution —
  the same chunk→daily→monthly→yearly shape used elsewhere. Retention policy
  is then not keep-vs-delete but a resolution schedule: recent data at full
  cadence, older data progressively squashed (fewer frames / stacked /
  summarised), squashed form kept ~forever. Peter to spend a day working out
  the schedule and quality trade-offs per data class. Pairs with
  [glacier-every-day]: ship full-cadence raw to Deep Archive nightly (cheap
  insurance, lifecycle-expire after N months), keep the squashed series as
  the permanent local/hot record — squash cadence decides local footprint,
  Deep Archive covers the gap until each night ages past squashing.
  (Secondary, smaller idea from same conversation: fpack lossy quantization
  of .fz could also give ~4–8× spatially — orthogonal to temporal squashing,
  could test the same day using the eclipticam backlog corpus on bigdisk2.)

- **Trace/replace the powerline hop** for eclipticam if bulk transfers ever
  need to be routine — cable or 5GHz wifi; the bridge caps everything at
  ~100Mbit real (see memory `project_lan_gigabit_devices`).

- **Migrate the 17 glacier-app eclipticam nights?** They sit in the wrong
  bucket (reconciled on the page, not moved). Once squashing exists, the
  clean end-state is: squash them, cold-archive-night the keepers to the
  astro bucket, let the glacier-app raw copies lifecycle-expire. Low
  priority — the page is honest and the bytes are safe.

- **Restore drill**: thaw one Deep Archive night and verify it restores +
  un-tars intact — good practice before trusting cold storage as the only
  copy (12h bulk thaw, pennies).

(glacier-app product ideas — thumbnail gaps, restore-as-demo — live in the
~/glacier-app repo, not here.)

End-of-night sync to bigstore 'bs' (Peter, 2026-07-29): write the night's astro images to the bs disk at end of each night — the dynamic sync half of the bs plan. Depends on ansible having NFS-exported bs and mounted it on the writing host first (that half is in the ansible strand's inbox); this sync writes onto that mount. Open: which data classes go to bs (raw .fz / jpg / mp4 / derived); whether bs is the ship-and-free destination or a staging hop before cold-archive; how it relates to the squashing schedule ([[data-reduction-day]] / [[glacier-every-day]]) — permanent local hot record, or a landing zone that then squashes + cold-archives?

