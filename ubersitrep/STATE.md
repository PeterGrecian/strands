# ubersitrep — state

*The macro picture across all workstreams. Curated prose, not a log. Detail
lives in the sub-strands; this is the shape of the whole. Updated at session
end / on dcp.*

## Rough schedule (Peter, 2026-07-23 — soft targets, revise freely)

Parallel workstreams, not a queue — separate forkterm tracks progressing at
once. Dates are **rough targets** (momentum + slippage-catching, not
commitments), anchored to today.

| Workstream | Est. | Rough target | |
|---|---|---|---|
| **astro-storage** (finalize starcam ≈1 GB/day) | ~4 days | **~2026-07-27** | urgent; smallest scope |
| **astro-cam** (instrument refresh: canon-primary / fix-or-replace astrocam / v3?) | few days | **~2026-07-26–27** | hardware-gated (weather, parts) |
| **aifabric** (polish + portfolio-bar scrub → public) | ~1 week | **~2026-07-30** | background track |

They overlap by design (all land in the same ~week); running in parallel is the
plan, so a slip in one doesn't push the others. Revisit these dates each session
— rough by intent.

## Session 2026-07-23 — triage + electronics spun out + two forks

A working session, not just narrative:
- **Triaged every strand's ideas inbox** (25 files across 8 strands) — promoted
  the keepers into each STATE, cleared the inboxes.
- **Fixed the scaffolder symlink bug** (both `strands new` and `cld -s`): they
  copied the `.template` *symlink* as a symlink, so new strands became symlinks
  into `aifabric/method/template` and the sed corrupted the shared template.
  Fix = `cp -rT "$(readlink -f …)"`; template restored; validated by
  scaffolding two new strands cleanly. **This item is now closed** (was the
  long-standing pending bug).
- **Spun out `electronics`** (strand + `~/electronics` repo) — the bench/circuit
  layer between home-automation and hardware. A forkterm carried it forward
  (EOS DC-switch design note, rackinabox as the live build). See its STATE.
- **`xfer-audio-to-phone`**: a forkterm flattened the on-phone audio for
  AntennaPod and built `super/bin/adb-wifi` (wireless adb over the tailnet, USB
  wouldn't enumerate on pip). A **subset** (5.3 GB, spoken-word) transferred;
  `composers`/`pop` (23 GB music) never fit the phone's ~16 GB — revisit if
  Peter wants the music too.

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

## URGENT NOW — astro-storage / finalize starcam (Peter, 2026-07-22)

Jumped the queue: **S3 storage is increasing and starcam data needs
finalizing. Target ≈ 1 GB/day.** Owned by the `astro-storage` strand (a mature
strand — squash tooling, cold pipeline, glacier all exist); this is a *finalize
+ decide* task, not new build. Grounded facts pulled this session:

- **What's actually growing = the astro COLD bucket**, not starcam.
  `astro-berrylands-eu-west-1` is **~72.6 GB / 1214 objects and climbing**
  (was 63 GB / 12 objects earlier the same session — the nightly Deep-Archive
  ship via `cold-archive-night`). That's the `glacier-every-day` accrual and
  the **t² cost** the strand already flagged. Cheap now (~pennies/mo) but
  quadratic if unbounded — the lever is squash-first + lifecycle-expire raw.
- **The starcam bucket is small AND stalled.** `starcam-berrylands-eu-west-1`
  = **1.34 GB, STANDARD class, 673 objects**, newest key **2026-06-04** — the
  live starcam→S3 upload appears to have **stopped ~4 June**. 16 nights
  (05-20…06-04) of tiny derived products (~2.7 MB/night: sum/derot jpgs +
  summaries). **`videos/` is 94% of it** (1.28 GB of mp4s). So "finalize
  starcam" ≠ firefighting a runaway bucket — it's **defining the intended
  end-state**: what a *finished* starcam pipeline ships per day (~1 GB target)
  and its retention, because right now it's neither running nor bounded.
- **gardencam is the real S3 giant** (142 GB / 41,881 objects) — different
  stream, but worth naming if "S3 increasing" is a billing worry.

**Decisions to make (this-then-that):**
1. Is the starcam→S3 upload *meant* to be stopped since 4 June, or did it
   break? (Determines fix-vs-finalize.)
2. Define the ~1 GB/day starcam deliverable: which products ship daily (derived
   jpgs/summaries are KB; the GB is video) and what's the retention/lifecycle?
3. Bound the cold-bucket t²: apply the retention schedule (squash-first +
   S3 lifecycle-expire raw after N months) the IDEAS.md design already sketches.

Next action: **`forkterm into astro-storage`** with a finalize-starcam briefing
carrying these numbers. (Not yet done — awaiting Peter's go, since the
calendaralarm fork is still active.)

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

**Rotation model (Peter, 2026-07-22): least-recently-reviewed, so none are
missed.** Some projects have been neglected; a rotation makes neglect
impossible by construction. Each repo carries a *last-reviewed* date; the sweep
always picks up the stalest. A visit is **variable-cost** — it might take 5
minutes ("still fine, still dormant, next") or it might crack open into a whole
set of strands. That's fine: the schedule guarantees *attention*, not uniform
effort. This is the conscious-maintenance ethos (changelog-in-hand, not
nag-popup; cf. the `hardware` strand's firmware flow) applied to projects, and
the RRD-pyramid idea (recent = fine cadence, old = coarse but never zero)
applied to codebases. **Mechanism = a manual ledger here, for now** (no cron/
cloud agent until the rhythm proves itself).

### The "backlog" ritual (Peter, 2026-07-22)
The engine that drives the rotation. Wake this strand and say **"let's
backlog"** (working name); then:

1. **Pick the stalest** subject from the ledger (top unreviewed row) —
   least-recently-reviewed, tie-broken by priority.
2. **Ensure it has a strand.** Every repo / Berrylands project (and, over time,
   every subject) gets its *own* strand. Scaffold with `cld -s <name>` if it
   doesn't exist yet.
3. **`forkterm into <strand>`** with a turn-one briefing ("review this repo:
   where is it, is it alive, what's next") — a cold session in the repo's own
   dir. (`forkterm into` needs the strand to already exist — hence step 2.)
   The fork gives it a go; the parent (this strand) stays the conductor.
4. **Re-queue with a rating.** When the visit ends, the parent records a
   **priority/importance rating** that sets how far back down the queue the
   subject goes. Rating is a *weight on top of staleness*: high-importance
   resurfaces sooner regardless of recency; low-importance sinks. Neglect is
   still impossible (recency always pulls things up), but importance decides
   the depth of the push-back. Stamp the last-reviewed date + the rating in the
   ledger.

A visit is variable-cost: a 5-minute "still dormant, next" *still* goes through
the forkterm+strand path (so every subject accretes its own curation over
time), or it cracks open into a whole set of strands.

### Review ledger
Last-reviewed date per subject (seeded 2026-07-22 from last-commit date as a
proxy where no formal review has happened yet — so the stalest float to the
top). **Coverage principle:** every repo and every Berrylands project gets its
own strand and a review; strands themselves are reviewable subjects too. So
this ledger grows to cover the whole estate, not just today's active repos.
Update the date + rating when a subject gets a real backlog visit.
**Up next = the top unreviewed row** (recency first, priority as tie-break).

`Pri` = priority/importance rating set at the *end* of a visit — weights how far
back down the queue it goes (high resurfaces sooner, low sinks). Blank until
first reviewed.

| Subject | Last-reviewed | Pri | Status / note |
|---|---|---|---|
| astro-storage | **2026-07-22** | **URGENT** | S3 growing, finalize starcam ≈1 GB/day — see "URGENT NOW" above; strand exists, forkterm pending |
| calendaralarm | **2026-07-22** | high | ✅ LIVE — bridge built, systemd timer armed, real xMatters page fired; see `calendaralarm` STATE |
| testbook | 2026-01-30* | — | STALEST — Götterdämmerung LaTeX/online; unvisited |
| nightsound | 2026-03-19* | — | Android snoring capture; unvisited |
| busclock | 2026-04-01* | — | K2 web clock-face prototype; future undecided (see T3) |
| us-vs-the-machines | 2026-04-01* | — | Human-vs-AI predictions web; unvisited |
| blescape | 2026-04-18* | — | Android stereo BLE scans; unvisited |
| cosmic-cycling | 2026-04-28* | — | Music composition tool; unvisited |
| tersetransporttimes | **2026-07-22** | — | ✅ reviewed — daily driver, healthy (see above) |
| — others — | | | gardencam, pi-fleet, cloud-init-init, pwmaudio, home-automation, dotfiles, mywebsite, splay, osd, astro, ansible, super, strands, aifabric, rackinabox + the ~35 existing strands — slot in by staleness as backlog proceeds |

\* = proxy (last-commit), not a real review yet. First real visit replaces it
with the review date and sets a Pri.

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

### Electronics — now has a home (strand + repo created 2026-07-23)
**Note the category:** this is **electronics** — circuits and actuator drive —
*not* the `hardware` strand, which is scoped to "the host as a machine, not the
things a host drives" (actuators explicitly out of scope there). **DONE
2026-07-23:** spun out the `electronics` strand + `~/electronics` repo
(`PeterGrecian/electronics`), sitting between home-automation and hardware. A
forkterm has already landed the first design note (EOS high-side P-MOSFET DC
switch, `~/electronics/designs/eos-dc-switch.md`) and re-prioritised: **rackinabox
is the live bench project**, PWM-for-8R is nearly done, the EOS switch is
deferred (astro-side command rate-limiting is the cheaper first mitigation).
Source of truth is now `super/strands/electronics/STATE.md`. What still needs
catching up (per that strand):

1. **GPIO→speaker drive — bench-test in isolation.** The dither speaker drive
   (`astro-speaker-dither`, still a placeholder — no bench build; PWM-DAC code
   in `~/Berrylands/pwmaudio`) should be **separately bench-tested**, decoupled
   from the astro use, before it's trusted in the rig. Calibrate loaded (mount
   stiffness changes response).
2. **GPIO→DC P-MOSFET switch — a distinct circuit.** GPIO driving a P-MOSFET as
   a DC power switch (high-side switching) — a *different* board from the audio
   drive above. Needs its own bench validation.
3. **Host portability matrix: Pi / Pico / ESP32.** The GPIO drive (both the
   speaker drive and the P-MOSFET switch) should run on **all three host
   types** — a deliberate cross-platform exercise proving the same actuator
   control across Raspberry Pi, Pico, and ESP32. (Intent = portability matrix,
   not host-selection.)

### rackinabox — get it cut
Silent home-server enclosure, design **locked**: flat laser-cut, single 6 mm,
finger-jointed corners, DXF for **SendCutSend** (the committed fab route — spec
in `~/rackinabox/DESIGN.md`, panel generator `cad/panels.py`). Not doing it now,
but the ordered path to a physical rack: finish the panel set (PSU baffle +
dual-chamber divider, leg sockets, dovetail rear cable panel aren't in the DXF
yet), **nest all panels onto a sheet layout**, confirm real ATX PSU dims, then
get the SendCutSend quote and order. The gate is the panel set, not the vendor.

### Next in the sweep
Continue the broad pass over the remaining repos (order TBD with Peter):
ansible, mywebsite, splay, home-automation, the astro repos, dotfiles, super,
and the rest of the portfolio list in super/GLOBAL.md.

## Pending / loose ends

- Continue the sweep via the backlog ritual (see above) — T3, electronics,
  rackinabox, **calendaralarm (first live ritual run, revived → xMatters)** so
  far. **Next stalest = testbook** (untouched since Jan).
- **Universal coverage is a scaffold backlog in itself:** several repos still
  lack a strand (testbook, nightsound, busclock, us-vs-the-machines, blescape,
  cosmic-cycling, and the Berrylands/* set — calendaralarm now has one), and a
  few existing strands look like review subjects / cleanup (`victim`, the
  typo'd `aifrbric-strandchat`, leftover convergence-test naming). Scaffold
  lazily — at each subject's first backlog visit — not in a big bang.
- **rackinabox gate = the panel set**, not the fabricator (SendCutSend is
  committed): PSU baffle/divider, leg sockets, rear cable panel, and sheet
  nesting must land in the DXF before a quote.
- Flesh out the sitrep for the *other* workstreams (fleet, mywebsite, splay,
  home-automation) — first pass covers only the two headline efforts + T3.
- Decide the fix-vs-replace branch for astrocam (#2), which gates the v3
  question (#3).

## Decisions

- **ubersitrep is the macro-sitrep strand** (2026-07-22): top-level situation
  report reading across all workstreams; owns the connecting narrative, not
  code. Sub-strands stay the source of truth for their own detail.
- **Repo review runs on a least-recently-reviewed rotation** (2026-07-22): a
  per-subject last-reviewed ledger (above) always surfaces the stalest, so no
  project is silently neglected. Visits are variable-cost (5 min → a whole set
  of strands). Manual ledger for now; automate only if the rhythm needs it.
- **The "backlog" ritual** (2026-07-22): wake ubersitrep → "let's backlog" →
  pick the stalest → ensure it has a strand → `forkterm into` it with a review
  briefing → give it a go → parent re-queues it with a **priority rating**.
  The parent strand is the conductor; the fork does the per-repo work.
- **Universal strand coverage** (2026-07-22, Peter): *every* repo and every
  Berrylands project gets its own strand and a review; strands themselves are
  reviewable subjects in the rotation too. The estate is fully covered, not
  just the currently-active repos. (Accept the resulting many thin/dormant
  strands — the ledger keeps them from being forgotten; that's the point.)
- **Re-queue rating = priority/importance** (2026-07-22), not a fixed cooldown:
  a weight *on top of* recency. High-importance resurfaces sooner regardless of
  staleness; low-importance sinks. Recency guarantees nothing is skipped;
  priority decides the depth of the push-back.
- **The big efforts carry rough target dates** (2026-07-23): soft finish-line
  estimates (see schedule table up top), parallel not serial, revised each
  session. Aim is momentum + catching slippage, not commitment — so a slipped
  date is information, not a failure.
