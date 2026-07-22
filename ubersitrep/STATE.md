# ubersitrep — state

*The macro picture across all workstreams. Curated prose, not a log. Detail
lives in the sub-strands; this is the shape of the whole. Updated at session
end / on dcp.*

## The thrust (2026-07-22)

Two very large efforts are both **near "done"** — each has been a huge piece of
work — and the question of the moment is what the next phase for each looks like.

### aifabric — almost done
The AI working method extracted into `~/aifabric` as Peter's principal
portfolio (a *fabric*, not a drawer of tools). The core is built: manywrapper
library, the `idea`/`ding`/`spool` tools converging by symlink from super,
strands + forkterms as working exhibits, method docs. Remaining is polish and
the portfolio-bar scrub before flipping the repo public. **Source of truth:**
`super/strands/aifabric/STATE.md` — don't re-record its detail here.

### astro — almost done, entering an instrument-refresh phase
The astronomy fleet + pipeline is mature (capture, storage/squashing,
sub-pixel science, deliverables). The active frontier is the **cameras
themselves**, and the near-term thrust is a three-move instrument refresh
(below). **Source of truth:** the `astro-*` strand family.

## astro next steps (Peter's steer, 2026-07-22)

Recorded here as the macro plan; each becomes real work in the relevant
`astro-*` sub-strand (canon / a new astrocam strand / breathing).

1. **Canon becomes the temporary primary — "canon temp replaces astrocam."**
   The Canon EOS 2000D (see `astro-canon`) steps in as the primary imager
   while astrocam is out. It's the big-sensor instrument and is already
   tethered + tooled; this makes it the stopgap primary rather than a
   complement. (Depends on the astro-canon capture wedge / tether being in a
   working state — see that strand's reset ladder.)

2. **Break / fix / replace the actual astrocam.** astrocam is **currently
   broken** — that's why the Canon is stepping in. The task is to diagnose and
   either fix it or replace the unit. This is the trigger for #3: if it's being
   replaced anyway, replace it with something better.

3. **Should astrocam be rebuilt as a v3 camera?** eclipticam's v3w (IMX708
   Wide) is the sensor behind the focus-**breathing** sub-pixel work
   (`astro-breathing`) — VCM focus control gives commanded sub-pixel dither, a
   capability astrocam's current sensor lacks. Open question: rebuild astrocam
   as a v3-class camera to get the same breathing/dither capability fleet-wide.
   Decide as part of the "replace" branch of #2.

## Pending / loose ends

- Flesh out the sitrep for the *other* workstreams (fleet, mywebsite, splay,
  home-automation) — first pass above covers only the two headline efforts.
- Decide the fix-vs-replace branch for astrocam (#2), which gates the v3
  question (#3).

## Decisions

- **ubersitrep is the macro-sitrep strand** (2026-07-22): top-level situation
  report reading across all workstreams; owns the connecting narrative, not
  code. Sub-strands stay the source of truth for their own detail.
