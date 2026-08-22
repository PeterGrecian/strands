# The keeper roster — who the experts are

*ubersitrep's standing duty. This is the gate's input: the set of strands a
query can be routed to, and what each one serves. Maintained here because
ubersitrep is the keeper-keeper — the expert on which experts exist.*

**Whose file this is (Peter, 2026-08-13): it is the gate's own.** Claude records
whatever it judges relevant to do the routing job — this is working memory, not a
negotiated artefact, and it should change the moment something is learned that
would route better. **Peter's rulings live in STATE.md Decisions**, and those are
the stable thing; do not confuse the two. An earlier draft treated this file as
deliberately stable "because it stands in for co-adaptation" — that was wrong,
and conflated the gate's notes with Peter's decisions.

**Prefer deterministic tools over impressions.** Anything derivable — liveness,
STATE size, activity, the archive-derived verdicts — should be produced by a
re-runnable tool that emits a file, not re-formed by reading each session. The
tool observes; the gate judges. (Same grain as [[deck-mechanics-deterministic]].)

**The tool exists: `ubersitrep/to-whom` (built 2026-08-14).** It parses the
tables below, joins them to `strand-ps` liveness and the mailbox spool, and
answers *who owns this* + *is anyone home* as data. Use it instead of re-reading
this file:

    to-whom "<query>"        ranked candidate owners, with the route to each
    to-whom --list|--live    the roster, or just what is running
    to-whom --strand <name>  one row in full
    to-whom --audit          drift: roster vs the strands actually on disk

**Ranking is lexical overlap, deliberately** — a shortlist, not a verdict. The
tool never decides; it hands candidates to the gate, which judges. That split is
the point: derivation observes, the agent rules.

**Status of the verdicts: BLURB-DERIVED, UNCONFIRMED (2026-08-13).** Every row
below was judged from the strand's `blurb` + `CLAUDE.md` mission and its STATE
size/activity — i.e. from what each strand *declares about itself*. The agreed
next move is to derive the same list independently from the OpenSearch session
archive (what was *actually* worked on) and **diff the two**. Expect rows to
move. See STATE.md, "The keeper-keeper" (2026-08-13).

## How to read a verdict

- **keeper** — defends its context and refines its remit. Bounded subject,
  steady state, serves answers. **Routable**: a query landing here gets an
  authoritative answer.
- **builder** — explores new territory. Moving frontier, STATE churns.
  **Not routable for facts**: an answer is true for as long as the frontier
  stands still. Route *work* here, not questions.
- **provisional** — the strand says so itself (scaffolded, never had a real
  session). Not yet either thing.

A strand is not uniformly one phase. A builder with a settled part should
**fork off a keeper** for it — but only if that part will be *asked about*
independently.

## Roster

### Astro — the deepest theme, and the only one with a full keeper/builder split

| Strand | Verdict | Serves | Evidence |
|---|---|---|---|
| `astro-canon` | **keeper** | the EOS 2000D as a remote instrument | declared; 1506-line STATE, the estate's largest — heavy operational detail |
| `astro-polecam` | **keeper** | the pole-pointing v3/imx708 on astrocam | declared; device rename still pending |
| `astro-storage` | **keeper** | full storage lifecycle of every camera stream | declared; owns the bigstore-primary invariant |
| `astro-capture` | **builder** | unified capture pipeline across cameras | **self-declared development** 2026-08-11; adopted `capture-unification.md` as backlog |
| `astro-science` | **builder** | what a year of urban drift-scan reveals | declared development 2026-08-02; open research frontier |

Cross-cutting facts duplicated across these five (frame naming, night
boundaries, storage roots) are the standing argument for a **theme-level note**
they all link to.

### Infrastructure — the largest undeclared cluster

| Strand | Verdict | Serves | Evidence |
|---|---|---|---|
| `ansible` | **keeper** | *changing* hosts; config drift across the fleet | blurb "Keeps…"; explicitly the sibling of pifleet, each mission naming the other |
| `pifleet` | **keeper** | *knowing* the fleet's state — roster + liveness | as above; the knowing/changing split is textbook two-keeper |
| `hardware` | **keeper** | physical infra — disks, CPUs, power, cooling | blurb "Keeps…"; 757-line STATE, conscious-maintenance ethos |
| `muppet-status` | **keeper** | muppet + puppy host health | blurb "Keeps…"; **18-line STATE — thin**, detail lives in memory files |
| `cloud-init-init` | **keeper** | bootable-Pi-image tooling | blurb "Keeps…"; bounded, stable tool |
| `xmatters` | **keeper** | the alerting/paging pipeline, end to end | blurb "Keeps…"; spans 4 surfaces, clearly bounded |
| `housekeeping` | **provisional** | git housekeeping / data-loss avoidance | **CLAUDE.md self-marks provisional**, "derived from the strand name" |

**None of these seven were declared keepers** — they were found by reading
blurbs, not by the `keeper` grep. That gap is the roster's reason to exist.

### aifabric — the method, mixed

| Strand | Verdict | Serves | Evidence |
|---|---|---|---|
| `aifabric-sessions` | **keeper** | the session archive + RAG in OpenSearch | declared; running infra, hourly ingest. **Owns the archive the keeper-keeper needs** |
| `aifabric-pane` | **builder** | the single pane of glass — surface *and* driver | **absorbed `aifabric-pane-driver` 2026-08-22** (3 pane/chat strands → 1); active build, browser-compositor spike pending |
| `aifabric` | **builder** | tools/libraries/templates of stranding | 513-line STATE, practice half, still building |
| `aifabric-essay` | **builder** | the argued case for using AI well | prose deliverable, not yet written |
| `aicli` | **keeper** | the launcher itself | bounded tool, "hardened here" |
| `strands` | **keeper** | the strand *model* — which strand does what | declared; **the theory sibling of this roster** |
| `super` | **builder** | the meta-repo, carved down | 23-line STATE; method migrating out to aifabric |

### splay — one keeper, three builders

| Strand | Verdict | Serves | Evidence |
|---|---|---|---|
| `splay-tweaks` | **keeper** | the viewer's UX sharpness | blurb "Keeps…"; small continuous curation |
| `splay-grid` | **builder** | contact-sheet grid mode | "headline deliverable"; ⚠ unmerged branch since 07-11 |
| `splay-mosaics` | **builder** | raw Bayer mosaic inspection | "headline deliverable is mosaic mode" |
| `splay-graticule` | **builder** | RA/Dec + star-name overlays | deliverable-shaped |
| `splay-ai-discovery` | **builder** | splay as a first-class AI tool | "Making splay…" — in progress |

### Everything else

| Strand | Verdict | Serves | Evidence |
|---|---|---|---|
| `mywebsite-tweaks` | **keeper** | www.petergrecian.co.uk health | declared; explicitly takes work from other forkterms |
| `home-work-comms` | **keeper** | the home↔work air gap | declared; "the owner of one subject" |
| `home-automation` | **keeper** | Matter/Zigbee, headless | blurb "Keeps…" |
| `electronics` | **keeper** | circuits, actuator drive, the bench layer | bounded charter, sits between home-automation and hardware |
| `ubersitrep` | **keeper** | the whole-estate picture **+ the gate** | this strand; both an expert and the keeper-keeper |
| `considered-prose` | **keeper** | how wording gets chosen — the prose-quality loop | **added 2026-08-13**, the first row since the roster was written. Found as a *missing keeper*: export prose was being re-derived independently by aifabric-essay, cv, aifabric, testbook and owned by none of them |
| `spend` | **keeper** | the money: cloud costs + subscriptions + trials and their expiry | **added 2026-08-18**, the second missing keeper found. Keeper from day one (bounded, steady-state, exists to serve "what does X cost and is it worth it") — the usual builder start does not apply. **Found by the gate's own failures, twice**: "how much is R2 costing" returned no candidate (08-14) and "the Chromebook Gemini + storage offer" mis-routed to `astro-storage` on the word *storage* (08-18) |
| `calendaralarm` | **builder** | un-ignorable calendar alarms | ✅ live but still active effort |
| `rackinabox` | **builder** | the laser-cut enclosure | design locked, unfabricated — **one step from done** |
| `testbook` | **builder** | the sleep-listening app | mid-pivot 2026-07-25 |
| `glacier-app` | **builder** | Deep Archive photo archiving | "prototype now, app later" |
| `cleft-plus` | **builder** | usage observability | "Grow cleft from…" |
| `srfc` | **builder** | court-booking automation | "Integrate…" |
| `manim` | **builder** | animations in cairo, occasionally manim | blurb written 2026-08-14 (Peter): cairo is the usual tool, manim only when its scene machinery earns the dependency — **the strand name is the library that got there first, not the tool of choice** |
| `bookmarks` | **builder** | bookmark reorganisation | self-declares short-lived, retires when done |
| `cv` | **provisional** | CV / job-hunt materials | **CLAUDE.md self-marks provisional** |

## Tally

**40 rows: 20 keeper, 18 builder, 2 provisional** — counted by `to-whom --list`,
not by hand. The `keeper` grep over CLAUDE.md finds only **10**, so **the
declared count is half the real one**, which is exactly why the roster is a file
and not a grep.

*(Re-counted 2026-08-22 after the pane/chat consolidation removed the
`aifabric-pane-driver` and `strandchat` rows.)*

**⚠ 18 of these 40 rows name strands that are no longer live** — all sitting in
`archive/` after the 2026-08-22 archiving sweep: `astro-canon`, `astro-polecam`,
`muppet-status`, `xmatters`, `aifabric-essay`, `splay-grid`, `splay-mosaics`,
`splay-graticule`, `splay-ai-discovery`, `spend`, `calendaralarm`, `testbook`,
`glacier-app`, `cleft-plus`, `srfc`, `manim`, `bookmarks`, `cv`. **The router
will happily route to every one of them** — `to-whom` ranks the row, prints
`route: aicli -s <name>`, and nothing checks the strand still exists. Nearly
half the gate's weights are dead. This is exactly the silent mis-route the
roster exists to prevent, so it needs a deliberate pass: decide whether an
archived strand keeps a row marked **retired** (consistent with "record
transitions, don't overwrite them") or loses it, then apply that uniformly —
and ideally teach `to-whom` to flag a row whose strand dir is gone, so the
next sweep cannot reopen the gap.

*(Corrected 2026-08-14. The hand-written tally said "42: 22/18/2" and was wrong
on every figure — the first thing `to-whom` found. Arithmetic over the rows is
the tool's job now; don't hand-count it again.)*

## Routing rules the ranking cannot know

*Lexical overlap ranks by wording; these are rulings. Where a rule contradicts
the ranking, the rule wins — the gate applies them, `to-whom` only shortlists.*

- **Subject-matter routing is never delegated to a surface agent.** The driver
  owns the surface; ubersitrep owns the subject matter (STATE, 2026-08-13).
- **Cost / billing / subscription questions → `spend`, even when they say
  "storage".** Verified 2026-08-18: *"chromebook gemini google one storage
  subscription offer"* ranks `astro-storage` **[13]** over `spend` **[6]** — the
  word *storage* is astro-storage's strongest weight and will beat `spend` on
  almost any money question that happens to mention storing something. The test
  is **what is being asked about the bytes**: what they *cost* is `spend`, where
  they *live* is `astro-storage`. Both at once is a hand-off, not a contest.

## Retired rules — kept as evidence

*Not applied (this heading is outside the block `to-whom` parses). Kept because
a rule that had to be retired says more than one that still holds — see
"Record transitions, don't overwrite them" under Maintenance.*

- **Pane / deck / layout work → `aifabric-pane-driver`, not `aifabric-pane`**
  (2026-08-14 → **retired 2026-08-22**). The two strands merged in the 3→1
  pane/chat consolidation, so the distinction it policed no longer exists: all
  pane / deck / layout / driver work now goes to `aifabric-pane`, design question
  or not. **The rule's own shape was the warning.** Wording ranked
  `aifabric-pane` first on *every* pane utterance ("replace pane 2 with the
  deck" scored pane **[10]** over driver **[9]**) and the ruling had to override
  it each time. A rule that must permanently contradict the ranking is evidence
  the *split* is wrong, not that the ranking is — the ranking was reading the
  blurbs correctly and reporting that the two strands were one subject.
  **Generalise: a standing override with no exceptions is a merge waiting to be
  done.**

## Contested rows — resolve at the archive diff

- **`aifabric-pane`** — declares keeper, behaves builder (600+-line STATE, active
  build). Was listed as the best candidate for **fork-off** (the settled
  vocabulary ladder [[pane-of-glass-vocabulary]] served while deck work
  continues) — **note that the estate just did the opposite here**, merging
  `aifabric-pane-driver` back in on 2026-08-22 because the forked half could not
  move without its host. Fork-off is still the right shape for a settled,
  independently-*asked-about* part; it is the wrong shape for a component that
  only ever answers alongside the thing it belongs to. Re-judge on that test.
- **`astro-capture`** — declared development, but its *conventions* (epoch_ms
  stems, run-tags, one-capture-one-frame) are already durable and asked about.
  Same fork-off shape.
- **`muppet-status`** — keeper with an 18-line STATE and its detail in memory
  files. Either the thinnest legitimate keeper or a keeper in name only; the
  archive will say which.
- **`super`** — was reclassified dev 2026-08-02, but still holds house tools
  everything else calls. Serving surface may outlive the build.

## Maintenance

- **Re-judge on the review-ledger visit.** The rotation already touches every
  subject; that visit is when a row's verdict is re-derived. Cache stops the gate
  re-reading 41 strands per query; the rotation stops the cache rotting.
- **Record transitions, don't overwrite them.** A builder becoming a keeper is a
  project that *landed* — the estate's completion signal, and nothing else
  captures it.
- **A new strand joins as builder or provisional** unless it is scaffolded to
  serve a bounded subject from day one.
- **Watch for the missing keeper**: a subject recurring across sessions that no
  row here owns. Unfindable from blurbs — every blurb says it is someone else's
  job — which is the whole case for the archive diff.
- **A mis-route is evidence, so keep the failures.** Both missing keepers found
  so far (`considered-prose`, `spend`) were found by the gate coming up empty or
  wrong, not by an audit — and `spend` needed **two** sightings before the
  pattern was legible. So a query that returns nothing, or returns something
  obviously wrong, is data worth writing down at the time; it is cheap then and
  unrecoverable later. The archive diff automates this, but it is not the only
  source and never was.
