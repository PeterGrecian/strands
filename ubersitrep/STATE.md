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
   broken** — that's why the Canon is stepping in. Specifically it's the **v2
   astrocam, and its lens is inaccurately fitted.** The branch point: **a fix
   attempt might destroy it** (getting at the lens seating risks wrecking the
   unit). So this is genuinely fix-*or*-replace, not fix-then-maybe-replace —
   and because a fix could kill it anyway, replacement is a live option rather
   than a fallback. That directly feeds #3: if it may not survive the fix, the
   sensible replacement is a better camera, not another v2. ("break" in the
   strand title = this risk is real, not rhetorical.)

3. **Should astrocam be rebuilt as a v3 camera?** eclipticam's v3w (IMX708
   Wide) is the sensor behind the focus-**breathing** sub-pixel work
   (`astro-breathing`) — VCM focus control gives commanded sub-pixel dither, a
   capability astrocam's current sensor lacks. Open question: rebuild astrocam
   as a v3-class camera to get the same breathing/dither capability fleet-wide.
   Decide as part of the "replace" branch of #2.

## Repo re-evaluation sweep (started 2026-07-22)

A deliberate broad pass over *all* the repos, re-evaluating each: alive /
stalled / what's next. **Collating and planning only — not doing the work.**
Order is by lived importance, so we start with what Peter uses daily.

### tersetransporttimes (T3) — daily driver, healthy
Android commute app (K2 bus ↔ Surbiton train ↔ Waterloo), zero-interaction via
GPS. Clean git tree; last commit 2026-06-26 (~4 weeks ago). Two Lambdas (`t3`
buses, `t3-trains`) behind API Gateway. **Used every day** — highest-value
repo to keep working. Open items, in dependency order:

1. **End-of-service 500 bug** — `t3.py` should return 200 `{"seconds":[]}` when
   TfL has no K2 buses (after midnight), not HTTP 500. Commit `c48955a` claims
   the fix, but TODO still says "in place locally, needs deploying" —
   **ambiguity to check: is the fix actually live?** (Check only, later — not
   deploying during the sweep.)
2. **Waterloo→work leg** (unimplemented) — the natural next feature and a good
   GCP entry point: Weather API decides tube-vs-bus (bus when dry, tube when
   raining). *This then that:* the weather-decision logic comes before #3.
3. **Bus-train `/journey` integration** — combined Lambda chaining bus→train→
   Waterloo leg. Depends on #2's GCP groundwork.
4. **Multi-user configurability** — explicitly parked until the app is stable
   and worth sharing.

Related: `busclock` (web prototype of the same K2 data as a clock face) — future
undecided; re-evaluate it in the sweep too.

### Next in the sweep
Continue the broad pass over the remaining repos (order TBD with Peter):
ansible, mywebsite, splay, home-automation, the astro repos, dotfiles, super,
and the rest of the portfolio list in super/GLOBAL.md.

## Pending / loose ends

- Continue the repo sweep (see above) — only T3 evaluated so far.
- Flesh out the sitrep for the *other* workstreams (fleet, mywebsite, splay,
  home-automation) — first pass covers only the two headline efforts + T3.
- Decide the fix-vs-replace branch for astrocam (#2), which gates the v3
  question (#3).
- **Scaffolding + `cld -s` bug** (2026-07-22): `cld -s ubersitrep` created the
  strand as a symlink into `aifabric/method/template` and rooted a live session
  in the template. Fixed the dir by hand; logged to the strands-system inbox.
  This session is still template-rooted — relaunch `cld -s ubersitrep` for a
  clean one.

## Decisions

- **ubersitrep is the macro-sitrep strand** (2026-07-22): top-level situation
  report reading across all workstreams; owns the connecting narrative, not
  code. Sub-strands stay the source of truth for their own detail.
