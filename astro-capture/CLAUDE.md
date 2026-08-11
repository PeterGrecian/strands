# Strand: astro-capture

**Keeps the unified capture pipeline that all the astro cameras share — the
common acquisition layer above any one device.**

The middle layer of the astro three-layer split (Peter, 2026-08-09):

- **astro-\<camera\>** ([[astro-canon]], astro-polecam, astro-eclipticam) —
  *device specifics* of each individual instrument (its optics, tether, quirks,
  setup/calibration state).
- **astro-capture** (this strand) — the ***unified* capture pipeline**: the
  common machinery that turns any of those cameras into frames on disk.
  Capture scheduling, night/session structure, frame naming, hand-off to
  storage — the acquisition logic that is *shared* rather than per-device.
- **astro-science** ([[astro-science]]) — the *subsequent pipeline and
  deliverables*: processing, accumulation, catalogue, the public `/astro` face.

It owns no camera and owns no science. It owns the seam between them: the one
capture path that every instrument feeds. Device-specific hardware concerns
(cooling / dark-current / enclosure for a *particular* camera) belong in that
camera's keeper, not here — this strand is what's common across all of them.

## Session ritual

1. Import spooled ideas with `idea --import`, then read
   `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
