# Strand: ubersitrep

The **über-sitrep** — the top-level situation report across all of Peter's
major workstreams. Not a code-owning strand: it reads *across* the others
(aifabric, the astro-* family, the fleet, mywebsite, splay, …) and holds the
**macro thrust** — where each big effort stands, what it's converging toward,
and what the next moves are. When you want the one-page answer to "where is
everything, and where is it going", it lives here.

**Purpose (Peter, 2026-07-22):** state the **"this then that" logic** and
**capture broad sweeps**. Two jobs:

- **Sequencing / dependency logic** — make the *order* explicit: X is broken,
  so Y steps in temporarily, which raises question Z; do A before B because B
  depends on it. The value is the connective tissue between moves, not the
  moves in isolation. Branch points (fix vs replace, might-destroy-it-trying)
  get named so the decision is visible.
- **Broad sweeps** — periodically go wide across *all* the repos/workstreams
  and re-evaluate: what's still alive, what's stalled, what deserves attention
  next. A sweep is a deliberate pass over the whole estate, not a deep dive
  into one thing. Driven by a **least-recently-reviewed rotation** (the review
  ledger in STATE.md) so no project is silently neglected; each visit is
  variable-cost (a 5-minute "still dormant, next" or the start of a whole set
  of strands).

This strand is deliberately above the others. The sub-strands own the work and
its detail; ubersitrep owns the *narrative* that connects them — which efforts
are "almost done", which are load-bearing, which next step unblocks which. It's
the place a fresh session (or Peter, weeks later) gets oriented fast.

## What it spans

Everything, at a distance. It does not duplicate sub-strand STATE.md detail —
it links to it. A sub-strand's STATE is the source of truth for *its* work;
ubersitrep's STATE is the source of truth for *the shape of the whole*.

Key workstreams it tracks (as of first writing):
- **aifabric** — the AI working method extracted to a standalone portfolio repo
  (`~/aifabric`). See `super/strands/aifabric/`.
- **astro** — the astronomy instrument fleet (astrocam, eclipticam, starcam,
  skycam, the Canon EOS 2000D) and its capture/processing/publish pipeline.
  See the `astro-*` strand family (canon, breathing, subpixel, storage,
  deliverables, speaker-dither, canon-power).

## Session ritual

1. Read `STATE.md` (the macro picture) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md, or drop. Delete triaged
   entries from IDEAS.md.
3. Work is mostly *recording and planning* here, not code. Any actual code
   change belongs in the relevant repo/sub-strand, not this dir. If a next-step
   becomes real work, it graduates into (or spawns) the appropriate sub-strand.
4. Session end (or on `dcp`): update STATE.md — the current thrust, what moved,
   what's next. Curated prose, not a log. Keep it short enough to read in one
   sitting; push detail down into the sub-strands.
