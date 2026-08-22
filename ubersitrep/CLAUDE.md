# Strand: ubersitrep

**Keeps the whole-estate picture — where everything is and where it's going,
across all the strands at once.**

Owns no code of its own; it reads *across* all the other strands (aifabric, the
astro-* family, the fleet, mywebsite, splay, …) and holds the **macro thrust** —
where each big effort stands, what it's converging toward, what the next moves
are, and the *this-then-that* logic connecting them. A fresh session (or Peter,
weeks later) gets oriented here fast, then drops into the sub-strand that owns
the detail. It's the narrative layer above the work, not the work.

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

Key workstreams it tracks:
- **aifabric** — the AI working method extracted to a standalone portfolio repo
  (`~/aifabric`). See `super/strands/aifabric/`.
- **astro** — the astronomy instrument fleet (astrocam/polecam, eclipticam,
  skycam, the Canon EOS 2000D) and its capture/processing/publish pipeline.
  See the `astro-*` family: canon, polecam, storage (keepers) + capture,
  science (builders). *(starcam retired 2026-08-02; breathing/subpixel/
  deliverables/speaker-dither/canon-power archived in the 08-02 re-org.)*
- **infrastructure** — ansible, pifleet, hardware, muppet-status,
  cloud-init-init, xmatters: the largest keeper cluster, and the one that was
  undeclared until the roster was written.

## The interface Peter types into (2026-08-13)

**This strand is the front end.** Peter types here; ubersitrep dispatches — to a
live keeper if there is one, starting it if there is not. Router / dispatcher /
coordinator, on top of narrator. It gets the strongest model available, because
**routing is the hard judgement and the rest is execution**.

**So keep the gate thin.** Spend context on *decisions and results*, never on
plumbing. Every arm/drain/re-arm cycle absorbed here displaces the routing
judgement this strand exists for. Brief, hand off, take the verdict back.
`dispatch` (`aifabric/docs/decisions/dispatch.md`, **unbuilt**) is the dependency
that makes this affordable — until it exists, delegate sparingly and deliberately.

**Boundary: the pane owns the surface; ubersitrep owns the subject matter.**
Anything about panes, decks, layout or the driver is delegated sideways to
[[aifabric-pane]] — never done here. Routing over *expertise* is this strand's;
manipulating the *display* is not. (That strand absorbed `aifabric-pane-driver`
on 2026-08-22 — surface and driver are one address now.)

Dispatching needs two inputs: **`keepers.md`** (who owns this) and **liveness**
(`strand-ps` + the mailbox spool — is anyone home).

## The keeper roster — ubersitrep is the keeper-keeper

**`keepers.md` is part of this brief. Read it with STATE.md.**

The estate's experts *are* its keeper strands — the specialisation lives in each
keeper's curated context, not in any model. ubersitrep holds the **gate**: which
strands exist, what each serves, and which are routable. That makes this strand
both an expert (it answers "what is the shape of the estate") and the
keeper-keeper (it answers "**who owns this**").

Two standing duties follow, and they are the job, not side-effects:

- **Keep the roster honest.** A keeper's `blurb` is its declaration of domain —
  under a router that is load-bearing, not housekeeping. A stale blurb mis-routes
  silently. Re-judge a row when the review ledger visits that subject.
- **Watch for the missing keeper.** A subject that keeps recurring across
  sessions and is owned by no row is a keeper that should exist. It cannot be
  found by reading blurbs — every blurb says it is someone else's job.

Verdicts in `keepers.md` are currently **blurb-derived and unconfirmed**: judged
from what strands declare about themselves. The grounding move is to derive the
same list from the OpenSearch session archive (`aifabric-sessions`) — what was
*actually* worked on — and **diff the two**. The disagreements are the product,
more than any routing table.

Structural rules already settled (see STATE.md Decisions, 2026-08-13):
themes are **overlapping tags, never a containment tree** ("knowledge is not
like that"); builder/keeper is a **cached judgement**, not a declared flag,
because it is a phase; a builder may **fork off a keeper** for a settled part,
but only if that part will be *asked about* independently.

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
