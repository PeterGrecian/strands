# ubersitrep — state

*The macro picture across all workstreams. Curated prose, not a log. Detail
lives in the sub-strands; this is the shape of the whole. Updated at session
end / on dcp.*

## Strand blurb format — new convention, applied to 3 (2026-08-02)

New CLAUDE.md opener shape: a **verb-first 1-liner** (state the *content/TWIMC*,
not the category — no "Recurring workstream:"/"Strand theory:" label prefix; in
a 1-liner every character is precious) **followed by a paragraph**. The 1-liner
must earn its place: say the non-obvious thing the *name* doesn't (ubersitrep's
old "the top-level situation report" merely restated "über-sitrep"). Applied to
**ubersitrep, aifabric, strands** this session. The verb also carries the
theory/practice split: aifabric *"Builds…"*, strands *"Works out…"*. Convention
itself is strand *theory* → belongs in the `strands` strand (spool pending).
Rest of each CLAUDE.md body not yet swept for stale framing below the opener.

## Astro strand consolidation — PLANNED, not yet executed (2026-08-02)

The astro cluster has sprawled to **nine strands** whose real split isn't
per-camera-project but a **two-layer axis** Peter named this session:

- **Operations / maintenance** — keep the machine running: per-camera setup,
  focus/calibration, "did it capture last night", storage pressure, pipeline
  health. Fast loop, measured in nights.
- **Science / insight** — the *point*: year-scale, long-baseline **urban
  astronomy**. What the accumulated data *yields* — the last step of the
  pipeline everything else scaffolds. Slow loop, measured in months/years.

Most current astro strands are one layer wearing a project-phase label. The
tell: the **sidereal-mapped-sampling** discussion (theory: connects drift,
dither, PSF undersampling, accumulation) had no home, so it landed in
**astro-v3s** — an *operations* strand — by default. That misplacement is the
symptom driving this re-org.

### Keeper vs development — the strand-KIND behind this split (2026-08-02)

The astro split isn't just topical; it lands on a **strand-kind** distinction.
Homed by the theory/practice boundary (Peter 2026-08-02: *"aifabric is practical
stranding, strands is strand theory"*):
- **Theory → `strands` strand** (spooled `strands/ideas/…-vMnTSM`): keeper =
  steady-state custodian, cadence visits, sparse STATE (stable spec not
  worklog), **defines metrics**; development = task-to-done, moving-frontier
  STATE every session, measured by progress.
- **Practical build → `aifabric`** (spooled `aifabric/ideas/…-W3LFoR`): the
  `.template` keeper/dev variants, a declared-kind field, the metrics-reading
  sitrep agent.

**The astro _application_ (what stays here):**
- **polecam / eclipticam / canon / storage = keepers.** Each keeper's STATE
  needs a **metrics block** (captured last night? frame count, focus quality,
  GB/night, disk headroom) — the execution session adds one per keeper, and the
  daily sitrep agent reads those *metrics, not prose*.
- **astro-science (+ the subpixel/breathing/storage theory feeding it) =
  development** — an open research frontier, STATE updated every session.
- Scheduling follows the kind: **keepers → cadence** (the sitrep agent);
  **astro-science → the least-recently-reviewed backlog rotation**.

### Target shape (agreed 2026-08-02; execute in a dedicated session)

**Keepers (operational / maintenance layer)** — keep the system running. Three
camera keepers (`astro-<camera>`: setup, calibration state, last-night viewing
reports) + one data keeper (`astro-storage`). Four in total:

| Target strand | Camera | Absorbs |
|---|---|---|
| `astro-polecam` | v3 standard, **pole-pointing** (imx708) | **astro-v3s** (it *is* this camera's setup, mislabelled by phase) |
| `astro-eclipticam` | v3w wide | astro-breathing's *capture experiment* (operational half) |
| `astro-canon` | EOS 2000D | — (canon-power → electronics, not here) |

**Rename: astrocam → polecam** (2026-08-02). "astrocam" is generic — they're
*all* astro cameras — when this one is specifically the **pole-pointing**
instrument (Polaris dead-centre; the radial-breathing ⊥ tangential-drift
geometry the subpixel/science work relies on *is* its identity). "polecam"
beats zenith/north-cam: it points at the celestial **pole**, not the zenith
(that was starcam) nor a ground compass direction. **This is a real device
rename**, not just a strand label — it ripples into CLAUDE.md, `cdf`/
`resolve-host`/ssp aliases, camera.json, S3 keys, host/daemon names. Do the
rename deliberately in the execution session; the strand is the easy part.

**starcam (zenith) — RETIRED** (2026-08-02): camera decommissioned. No
`astro-starcam` keeper. astro-storage only **winds down its historical data**
(the `starcam-berrylands-eu-west-1` bucket, 1.34 GB, already stalled since
2026-06-04 — that stall now reads as the decommission, not a break) — there's no
live starcam stream to ship. Note this closes one of storage-discussion's
original subjects.

**skycam is deliberately NOT here.** It's the all-sky/cloud/weather camera —
*adjacent* to astro but not a drift-scan science instrument feeding the
long-baseline pipeline. No `astro-skycam` keeper; skycam stays its own thing.
(Its storage/ship-and-free is still an astro-storage concern — the unbounded-raw
row — but the camera itself isn't an astro-science instrument.)

**`astro-storage` is the fourth keeper** — not a separate tier. Keeping the
system running *includes* the data plumbing, so storage sits alongside the
camera keepers as day-to-day maintenance (not a sub-topic of science). It's a
**major data-juggling workstream** (bigstore-primary invariant, per-stream
ship-and-free, S3 cold-bucket t² control, skycam's unbounded raw, winding down
retired starcam). astro-storage-discussion's *engineering* half consolidates
here; its *theory* half goes to astro-science.

**So the four keepers = polecam, eclipticam, canon, storage** (3 cameras + the
data plumbing that serves them). The daily astro sitrep reads all four.

**Out to `electronics`** (not astro at all — actuator drive / DC power, which is
that strand's existing charter, cf. the EOS DC-switch design note already there):
- **astro-speaker-dither** → electronics (GPIO→speaker PWM-DAC drive; remaining
  questions are darlington/mechanical, i.e. electronics). Its *dither-as-sampling*
  rationale is theory → referenced from `astro-science`, but the rig build is
  electronics.
- **astro-canon-power** → electronics (EOS high-side P-MOSFET DC switch — already
  half-there: `~/electronics/designs/eos-dc-switch.md`).

**Science — one strand, `astro-science`** (name chosen for the *destination*, not
the pipeline machinery — keeps gravity on "what does a year of urban drift-scan
reveal", not "make tonight's stack run"). Absorbs the **theory halves** of
astro-subpixel, astro-breathing, astro-storage-discussion, and the sidereal
discussion currently stuck in astro-v3s: undersampling/PSF, sub-pixel info
theory, the three dither mechanisms, sidereal-mapped sampling, the accumulation
**capacity law** + TDI, and the local-catalogue / star-ID quest.

**astro-deliverables (the website/publish glue) folds into astro-science** as
its **output/shopfront end** — not a keeper. Minor-but-load-bearing glue
(Lambda site, galleries, moon daily delivery, YouTube builds), but it's *where
the long-baseline insight becomes visible*, so it belongs to the science
strand's output rather than the maintenance layer. Keeps the keeper tier purely
about keeping **capture + data** flowing; the *publish* end is science's, since
publishing IS the last step of the science pipeline. (Publish mechanics that are
pure plumbing can still be maintained; but the strand home is astro-science.)

**Why a strand, not a `~/astro/design/*.md` doc:** design docs are a
write-mostly graveyard — nothing *lists* them, they're not launchable, not
auto-loaded at session start, and invisible to the review-ledger rotation.
`zenith-quests.md` is read *only because* storage-discussion actively points at
it. A strand gets a LIVE mark, `aicli -s`, auto-loaded STATE, and a ledger row.

**Net:** the astro cluster shrinks hard into a clean two-layer shape, from **9
current** astro strands (breathing, canon, canon-power, deliverables,
speaker-dither, storage, storage-discussion, subpixel, v3s) to **5**:
- **4 keepers** (maintenance): astro-polecam (← v3s), astro-eclipticam,
  astro-canon, astro-storage (← storage-discussion's *engineering* half).
- **1 science** strand: astro-science (← subpixel + breathing-theory +
  storage-discussion-theory + sidereal + **deliverables** as its publish end).

Retired/out: starcam retired, skycam out, speaker-dither + canon-power →
`electronics`. Each answers a clear question, and theory-scatter across three
strands collapses into one visible home.

### Daily astro sitrep — scheduled agent, NOT an uber-strand (2026-08-02)

Considered an `astro-keepers` uber-strand to aggregate the four keepers
(polecam/eclipticam/canon/storage) for daily sitreps. **Rejected** — it'd be a
mini-ubersitrep scoped to astro (a second narration layer over this strand,
which already reads *across* the others), and it'd be inert until launched. A
daily sitrep is a **cadence** problem, not a strand: a **scheduled agent**
(`/schedule` cloud routine, or `/loop`) runs each morning, reads the four
keeper STATEs + last-night capture status, posts a short "astro overnight"
report — and *fires itself*, which a strand never does. The cross-camera
narrative stays **here** in ubersitrep at the astro-cluster grain. Prove the
rhythm before building more (same discipline as the manual review ledger). To
build: after the keepers exist, scaffold the scheduled agent reading the four
keeper STATEs (the 3 camera keepers + astro-storage).

### Not done yet — scope for the execution session
- **Plan only this session.** Nothing moved. The sidereal-sampling compaction
  (below/via the astro-v3s session) writes to a **temp target**, since
  `astro-science` doesn't exist yet — or the execution session creates
  `astro-science` first and compaction targets it directly.
- Folding subpixel/breathing/storage-discussion theory → astro-science, and
  renaming astro-v3s → astro-astrocam, are the moving parts. Do them
  deliberately (git mv, STATE surgery), not piecemeal.
- Update this ledger + the astro rows when executed.

## `dispatch` tool spec'd — cut the delegation coordination tax (2026-07-31)

Peter: *"I ask a strand to start a terminal with a strand to do a task; it does
a lot of coordinating and it all costs irrelevant context to the original
strand."* The insight: the expensive part of `forkterm into X "Y"` isn't the
launch, it's the **choreography after** (briefing, arm/drain/re-arm, message
shuttle) — all in the *parent's* context. Refines the **backlog ritual** below
(the conductor→fork pattern): make the conductor pay for *decisions and results
only*, not plumbing.

Three lanes (2026-07-31, extended), split by task shape:
- **scalar query** ("temp of astropi → value|NaN") → headless background
  subagent, no window;
- **correspondent task** (fix/investigate Y) → forkterm into an *existing*
  strand + decision-relay protocol (`DECISION:`/`DONE:`/`BLOCKED:` mailbox
  tags), wait run as a *parent-side background task* so it's out-of-turn;
- **scratch poke** (explore topic T, no home strand) → *cold* forkterm into a
  **throwaway dir** (not in `~/strands`, not in the ledger); the **fork runs
  its own `sessions search`** to self-seed. Default death = discard; rare
  `--graduate` lifts it into a real strand (scratch notes *become* the seed
  STATE). **The ledger only ever sees graduated strands** — protects the
  least-recently-reviewed rotation from poked-once-dead pollution.

The scratch lane came from Peter's usage-reduction discussion: *don't grow the
strand list; seed a temp strand from a sessions search.* It hits all four
reduction levers at once — keep main session lean, reuse prior work
(`sessions`-seeded), cheaper launch (cold, not warm-fork), and is the
deliberate middle rung between a cold subagent and a permanent strand.

Spec written: `aifabric/docs/decisions/dispatch.md` (all three lanes + design
seams). **Not built** — graduates to an aifabric build session (`dispatch` in
`aifabric/bin` beside `forkterm`; orchestration over existing mailbox/`ding`/
`forkterm`/`sessions`/`strands new`, no new primitive). See
[[forkterm-coordination-tax]].

## Ownership call — skycam auto-cleanup → astro-storage (2026-07-31)

astro-storage mailboxed for a ruling: skycam raw on puppy is **unbounded** (the
pressure-GC was retired 2026-07-01 and skycam never got a ship-and-free
replacement — it's the one astro stream that can't meet the new *bigstore holds
every stream in full* invariant). 53G already on bs. **Decision: astro-storage
owns building it. No new strand.** The this-then-that: per-stream ship-and-free
*is* that strand's charter; skycam is the **last un-built stream** and the last
open row of the bigstore-primary reconciliation it closed astrocam/eclipticam/
starcam on *this same session* — so this finishes that table rather than opening
a new theme. Suggested shape (steer, not mandate): reuse the **eclipticam
STAGE-then-COPY** pattern, since puppy is a remote origin like eclipticam, not a
direct-NFS writer like astrocam — a variation on code astro-storage already
owns, not greenfield. Replied via mailbox; astro-storage proceeds.

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

## Session 2026-07-27 — broad sweep across all strands + archive

A **broad sweep** (the second ubersitrep job): a deliberate pass over the whole
estate to re-date the ledger and re-map the shape. 39 active strands + 5
archived. Key findings:

- **The astro cluster has grown into a family** since the 07-22-dated blocks
  below were written. New strands not in the old ledger: **`astro-v3s`**
  (replace astrocam's v2 imx219 with a bought **Pi Camera v3 standard / imx708**
  — this *is* the "rebuild as v3" branch of macro-plan #3, now a live strand, not
  an open question) and **`astro-storage-discussion`** (the conceptual core:
  *storage and star-ID are the same problem* — shrink starcam <1 GB/night while
  serving deep-integration / transient / max-reduction + identification). Both
  touched today. **`astro-canon` capture path is FIXED** (2026-07-24: the
  `eosremoterelease=Immediate`→AF-wedge bug + two others — see its STATE and the
  [[eos-capture-press-full-not-immediate]] memory); canon-as-temp-primary is now
  unblocked. **`astro-speaker-dither` driver works** (2026-07-25 darlington fix
  cleared the last electrical blocker; remaining questions are mechanical).
- **`splay-grid` has unmerged work** — grid mode built + committed on the
  `splay-grid-mode` worktree branch since 07-11, **NOT merged to splay main**.
  A genuine loose end, flagged for a backlog visit.
- **`aifabric-bin-migration` archived** — the two divergent tools (`cld`,
  `sessions`) reconciled; `cld`→`aicli` is now canonical (cf.
  [[aicli-supersedes-cld]]). Archive now holds 5: bin-migration, spool,
  strand-ps, victim, xfer-audio-to-phone — all correctly retired.
- **New idea inboxes** appeared (glacier-app/ideas, xmatters/ideas, home-work-comms,
  home-automation) from recent forkterm work — not yet triaged into their STATEs.
- Ledger below re-dated from STATE mtimes; astro rows folded to reflect the family.

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
| astro-canon | **2026-07-26** | high | ✅ capture path FIXED (Press Full, not Immediate — no more AF-wedge); canon-as-temp-primary unblocked |
| astro-v3s | **2026-07-27** | high | live — the "rebuild astrocam as v3" branch of macro #3, now its own strand (bought imx708 v3-standard, focusing for sky) |
| astro-storage-discussion | **2026-07-27** | high | live — storage+star-ID as one problem; shrink starcam <1 GB/night; Quest 6 time-axis |
| astro-speaker-dither | **2026-07-26** | med | driver works (darlington fix); remaining questions mechanical (deflection/image-shift) |
| astro-storage | **2026-07-22** | **URGENT** | S3 growing, finalize starcam ≈1 GB/day — see "URGENT NOW" above; STATE mtime 07-20 but discussion-strand carrying the live work |
| calendaralarm | **2026-07-22** | high | ✅ LIVE — bridge built, systemd timer armed, real xMatters page fired; see `calendaralarm` STATE |
| splay-grid | 2026-07-11* | med | ⚠️ grid mode built + committed on `splay-grid-mode` worktree branch, **NOT merged to splay main** — unmerged loose end |
| testbook | **2026-07-25** | **MEDIUM** | ✅ reviewed — content drafted, md→PDF pipeline provably WORKS (the "LaTeX blocker" was a myth — one nav-glyph filter). **PIVOTED** from print guide → an assisted sleep-listening app (the real forward direction). Print book = LOW "finish someday" side output; strand rated MEDIUM on the app ambition. See testbook STATE |
| nightsound | 2026-03-19* | — | Android snoring capture; unvisited |
| busclock | 2026-04-01* | — | K2 web clock-face prototype; future undecided (see T3) |
| us-vs-the-machines | 2026-04-01* | — | Human-vs-AI predictions web; unvisited |
| blescape | 2026-04-18* | — | Android stereo BLE scans; unvisited |
| cosmic-cycling | 2026-04-28* | — | Music composition tool; unvisited |
| tersetransporttimes | **2026-07-22** | — | ✅ reviewed — daily driver, healthy (see above) |
| — others — | | | gardencam, pi-fleet, cloud-init-init, pwmaudio, home-automation, dotfiles, mywebsite, splay, osd, astro, ansible, super, strands, aifabric, rackinabox + the ~35 existing strands — slot in by staleness as backlog proceeds |

**Archived 2026-07-25** (retired from the active list; recoverable under
`strands/archive/`, shown by `strands -a`):
- `aifabric-spool` — empty strand; its job (the ideas-spool) shipped as the
  `idea` tool and was folded into the aifabric strand. Nothing to lose.
- `aifabric-strand-ps` — the `strand-ps` tool is built + on PATH; its two
  unbuilt forkterm follow-ups (dup-guard, window-raise) live on in the
  aifabric STATE. Superseded.
- **Kept live** (NOT archiveable): `aifabric-sessions` — running infrastructure
  (hourly ingest timer active + enabled, OSD cluster green) with open work
  (semantic search, OSD-endpoints→config). Dormant ≠ archiveable.
- **Archive mechanism** (Peter's steer): `git mv` to `strands/archive/`; the
  `strands` tool hides `archive/` by default, `-a`/`--and-archived` includes it.

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
  rackinabox, **calendaralarm (first live ritual run, revived → xMatters)**, and
  **testbook (backlog visit LIVE 2026-07-25 — awaiting the fork's report + Pri)**
  so far. **Next stalest after testbook = nightsound** (last touched Mar).
- **Universal coverage is a scaffold backlog in itself:** several repos still
  lack a strand (nightsound, busclock, us-vs-the-machines, blescape,
  cosmic-cycling, and the Berrylands/* set — calendaralarm + testbook now have
  one), and a
  few existing strands look like review subjects / cleanup (`victim`, the
  typo'd `aifrbric-strandchat`, leftover convergence-test naming). Scaffold
  lazily — at each subject's first backlog visit — not in a big bang.
- **rackinabox gate = the panel set**, not the fabricator (SendCutSend is
  committed): PSU baffle/divider, leg sockets, rear cable panel, and sheet
  nesting must land in the DXF before a quote.
- Flesh out the sitrep for the *other* workstreams (fleet, mywebsite, splay,
  home-automation) — first pass covers only the two headline efforts + T3.
- **astrocam fix-vs-replace (#2) → resolved toward replace:** `astro-v3s` is a
  live strand buying a v3-standard (imx708) to replace the v2 — so #3 ("rebuild
  as v3") is effectively the chosen path, no longer an open question. The macro
  #1–#3 block below is now partly historical; astro-v3s owns the detail.
- **Untriaged idea inboxes** from recent forkterm work: `glacier-app/ideas`,
  `xmatters/ideas`, `home-work-comms/ideas`, `home-automation/ideas` — each
  strand should triage its own at next visit (not ubersitrep's job to drain).
- **`splay-grid` unmerged branch** (`splay-grid-mode` worktree, since 07-11) —
  decide merge-or-drop at its backlog visit.
- **bigstore "bs" → astro end-of-night, this-then-that** (2026-07-29): ansible
  NFS-**exports+mounts** `bs` (static transport) → *then* astro-storage's
  end-of-night **sync** writes onto that mount (dynamic). Ansible half first —
  the sync depends on the mount existing. Ideas parked in both owning inboxes;
  ubersitrep just holds the order.

## Decisions

- **Strands come in two kinds — keeper vs development** (2026-08-02, Peter):
  estate-wide taxonomy. **Keeper** = steady-state custodian of a running thing:
  cadence visits, specialized, **modifies STATE sparingly** (STATE = stable
  spec, not worklog), **defines metrics**. **Development** = progresses a task
  toward done: moving-frontier STATE every session, measured by progress,
  reviewed by the backlog rotation. **Homed by the theory/practice boundary**
  (*"aifabric is practical stranding, strands is strand theory"*): the *concept*
  is owned by the **`strands` strand**; the *build* (template variants,
  declared-kind field, sitrep agent) is **`aifabric`**. Both spooled 2026-08-02.
  Astro is the first live instance (keepers = polecam/eclipticam/canon/storage;
  dev = astro-science). See the planning block up top.
- **Astro strands re-org onto a two-layer axis** (2026-08-02, planned): ops
  keepers `astro-<camera>` (**astro-polecam** ← v3s, eclipticam, canon) +
  standalone **astro-storage** (major data-juggling, its own strand) + one
  science strand **`astro-science`** (year-scale long-baseline urban-astronomy
  insight; absorbs the theory halves of subpixel/breathing/storage-discussion +
  the sidereal-sampling discussion). **astrocam → polecam** (real device rename,
  it's the pole-pointing camera). **starcam retired**, skycam stays out,
  speaker-dither + canon-power → `electronics`. **Plan only — execute in a
  dedicated session.** Theory lives in a *strand* not a `~/astro/design` doc
  because design docs are invisible to the ledger and never auto-loaded. See the
  planning block up top.
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
