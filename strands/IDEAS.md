# strands — ideas inbox

Append ideas about the strand system / session workflow here any time, from
any machine (it's in git). They get triaged at the start of the next strand
session — promoted into STATE.md or dropped — then deleted from this file.

<!-- new ideas below this line -->

## Keeper-per-repo as the organising principle (2026-07-17, Peter)

The shape several threads have been circling: **a keeper per repo, and keepers
are how you don't have to remember conventions.**

- **Each repo has a keeper** that owns *that repo's* patterns, structure,
  conventions. `splay-keeper` knows splay; `super-keeper` knows `super/bin`
  conventions; etc. The keeper is the living embodiment of "the right way to do
  things *here*."
- **You don't re-derive conventions — you hand off to the keeper who is that
  knowledge.** Same principle as `--hints`/self-describing tools, but the
  knowledge lives in an agent that can *act*, not just describe. Direct
  application of Peter's `user_approach` ("one right way, shared everywhere") to
  knowledge of the conventions themselves.
- **Keepers collaborate across repo boundaries.** Concrete example: build the
  `ideas` tool by asking **super-keeper** to write it *to the super/bin
  manywrapper standard*, delivered into **`aifabric/bin/`**. super-keeper carries
  the convention across the boundary; aifabric is the home. Same cross-boundary
  handoff as the air-gap "work pulls aifabric as a collaborator" idea — keepers
  are the agents that do the pulling.
- **REALITY CHECK (found 2026-07-17): keepers don't systematically exist yet.**
  - No `super-keeper` strand. The `super/` strand exists but is **unwritten**
    (mission not filled in) — it is NOT super-keeper.
  - `mywebsite-keeper` is a *role* played by the `mywebsite-tweaks` strand, not a
    strand named `-keeper`.
  - So "keeper per repo" is currently **aspiration, not infrastructure**, and the
    naming is inconsistent (`<repo>-keeper` strand? a keeper role? a bare
    repo-named strand?).
  - **Prerequisite work**: define the keeper *system* first — naming convention,
    what a keeper IS (a strand? a role a strand plays? a keeper always exists per
    repo?), how you summon/hand-off to one. THEN the `ideas` handoff to
    super-keeper becomes real. Until then, cross-keeper handoffs write into an
    inbox for a keeper that may not be live (async spool handoff — fine, but the
    recipient must eventually exist).
  - **Keeper/portfolio boundary**: keepers are *your-setup glue* (know your repos,
    your fleet) → they STAY in their repos/super, NOT in aifabric. The *pattern of
    having keepers*, and the portable *tools keepers build* (like `ideas`), can be
    aifabric portfolio. Don't let "every repo has a keeper" pull repo-specific
    keeper code into the portfolio.

## Ideas can live in REPOS as well as strands (2026-07-17, Peter)

- A *strand* `ideas/` spool is about the workstream; a *repo* `ideas/` spool is
  about the codebase (splay-keeper's ideas about splay-the-repo). Not the same
  spool.
- The `ideas` tool must know which it targets — same pwd/context inference
  problem `strand_idea` already has. One tool, two kinds of spool (strand vs
  repo). Reconcile with the `idea`/`ideas` + `strand_idea` unification above.
- Naming: **`ideas`** (plural, the tool) manages the **`ideas/`** spool — like
  `secrets`→SSM, `resolve-host`→hosts. (Supersedes the earlier `idea` singular.)

## `idea` tool + per-strand `ideas/` spool + `ideas-keeper` (2026-07-17, Peter)

The powerful realisation: capture ideas with a **tool** that makes clashes
*structurally impossible*, not an append-only convention people/AIs must
remember. Same move as `datedir`/trashcan — concurrency-safety by construction.

- **`idea` tool** — writes **one file per idea** into a **per-strand `ideas/`
  dir** (`super/strands/<strand>/ideas/*.md`). Filename = timestamp + strand +
  pid (e.g. `20260717T0912-astro-canon-4412.md`) → two writers, even same strand
  same second, get different files. No shared file, no lock, no append-race.
  - `idea "<text>"` → writes a stamped file (provenance filled by the *tool*, not
    the writer — no more hand-typed `— <strand>, <date>` tags).
  - `idea` (no text) → `$EDITOR` on a stubbed file, provenance pre-filled.
  - `idea --hints` → self-describing, like a manywrapper.
  - Target strand inferred from pwd (like `strand_idea` already does) or a
    strand arg.
  - Sibling to / possibly *supersedes* `strand_idea` (the meta-strand's existing
    idea-capture sketch) — reconcile the two when building. `idea` is the
    per-file-spool evolution of that append-to-IDEAS.md design.

- **`ideas/` = a spool** — same one-file-per-item pattern as the mailbox
  (`MAILBOX-naming.md`) and the strand-idea spool. This recurrence across
  mailbox / ideas / trash-by-date *is* the fabric being woven; worth naming as a
  first-class pattern (a "spool" helper?).

- **`ideas-keeper`** — a keeper that watches the `ideas/` spool: collates,
  dedupes, clusters, promotes-by-default into STATE pending, sweeps triaged files
  to `~/.trash` (never `rm` — the data rule). Active strands **hand off** ideas
  to it instead of triaging inline. First concrete *keeper*; self-describing the
  same way manywrappers are — connects the earlier inbox entries "overlap between
  self-describing tooling and self-describing keepers" and "secret-keeper /
  secrets hints".

- **Air-gap caveat**: `idea` writes to `super/strands/.../ideas/`, so it's a
  *terminal* tool needing the repo present (like `strand_idea`). Browser/remote
  active strands can't write there directly — that's the separate
  air-gap-consumption problem (PR-to-write), not `idea`'s job.

- **Obsoletes** the append-only convention just written into
  `super/strands/aifabric/IDEAS.md` (append below the line, hand-typed provenance
  tags). Once `idea` + per-strand `ideas/` exists, IDEAS.md is either generated
  by `ideas-keeper` from the spool, or retired in favour of the spool dir. Clean
  that up when building.

## Vocabulary: "active strand" — substrate-agnostic (2026-07-17, Peter)

- **Active strand** = a strand with a *live AI attached*, regardless of
  substrate. A *strand* is the durable workstream (its files); *active* is a
  runtime property. The AI can be attached via a **terminal** session
  (`cld`/forkterm) OR a **browser chat** (claude.ai) OR an IDE — activeness is
  about liveness, not location.
- **forkterm is a mechanism, not the definition.** forkterm is a (huge)
  *convenience* for ONE way of creating a new active strand: **seamlessly, in a
  terminal, warm from an existing one.** It is not what an active strand *is* — it
  is one cell of a grid:

  ```
  active strand         = strand + live AI (substrate-agnostic)
   ├─ terminal active strand   ← forkterm (seamless warm create), cld -s, cld
   └─ browser active strand    ← "strandchat"/"forkchat" (analogue; may not exist)
  ```

- **Consequences that reshape earlier ideas:**
  - *"browser strandchats/forkchats"* (earlier inbox entry) = **the browser-side
    analogue of forkterm** — a seamless way to spawn a browser active strand.
    Now it has a place in the model, not a loose idea.
  - **Activeness detection can't be /proc-only.** `/proc` cwd-matching only sees
    *terminal* active strands; browser chats aren't processes on this host. So the
    dup-guard and any "list active strands" / "follow the strandterms" feature
    needs a **second channel** for browser sessions (some registry/heartbeat), or
    must be explicit that it only covers terminal activeness.
  - **forkterm scope** (defer to in/into rename, finding #1): does bare
    same-strand forkterm create a *new* active strand or add a peer to the *same*
    one? Resolve alongside in/into — but note it's now clearly a *terminal*-cell
    question, not a definition of "active strand."

## Relocated from aifabric IDEAS (2026-07-17) — these are strand-system, not portfolio

Raw ideas dropped into the aifabric inbox that actually belong here:

- **`cld -s` should list keepers separately from other strands.** Keepers might
  run unattached to a terminal, and be attached only when required.
- **`cld -s` should asterisk strands active in terminals.**
- **Overlap between self-describing tooling and self-describing keepers** —
  `secret-keeper`, `secrets hints`. Keepers describe themselves the way
  manywrappers do via `--hints`.
- **Undesirable to have 2 terms/forkterms working the same strand** (dup guard —
  see the detailed /proc-based design below).
- **Use `/proc` to follow all forkterms/strandterms.**
- **Browser strandchats / forkchats** — a browser view of live sessions.
- **Master repo relationship**: the master (personal) repo lives on the personal
  side; work *pulls it as a collaborator*. It might need to PR to write back
  across the air gap. (Air-gap consumption model for the fabric.)

### forkterm tool findings (surfaced by using it, 2026-07-16)

Captured from actually running `super/bin/forkterm`:

1. **Rename `in`/`into`.** Names describe *destination* not *mechanism*, and the
   mechanism is what differs (caused a real bug). Preferred: **bare `forkterm`**
   = fork *this* strand (true warm fork, default); **`forkterm new <strand>`** =
   spin up a *new*-strand session ("new" honestly signals fresh/briefed, not
   forked). Don't bake "child" into the name: a forkterm is a **peer by fork;
   child is a role its briefing confers and can revoke**.

2. **Doc fix: "into"/new-strand is NOT a warm launch.** `forkterms.md` and the
   strands meta-strand STATE call it "warm" — wrong. Cross-scope warm-forking is
   *impossible*: `claude --resume <id>` only finds the session from its own
   project dir, so `cd`-ing into another strand loses it (the bug that killed the
   window instantly). A new-strand launch is inherently a **cold session +
   briefing-file handoff** — the briefing, not `--fork-session`, carries context
   across the boundary. Only same-strand forkterm is truly warm. Fix the docs.

3. **Mailbox gap — the tool is half-built.** `forkterm` *spawns* peers (fork +
   window + briefing) but implements no *coordination* channel. The forkterms
   method treats the async **mailbox** (`MAILBOX-naming.md` /
   `MAILBOX-worktransfer.md`) as the co-equal other half. Peter hit this live —
   nearly had a child relay a message to the parent by hand. Implement the
   mailbox half so peers coordinate without a human relay.

### forkterm/cld: guard against duplicate session in the same strand (2026-07-16)

Reading `/proc` revealed 9 live Claudes in 9 distinct strands — but nothing
enforces the distinctness. `forkterm new <strand>` or `cld -s <strand>` into an
already-occupied strand silently gives TWO Claudes editing the same working tree
= self-inflicted collision. Add a launch-path guard.

- **Detect by /proc, NOT a lockfile.** `pgrep -x claude` + compare each
  `/proc/<pid>/cwd` to the target strand dir. Ground truth: process gone → /proc
  entry gone, can't go stale. A lockfile is the WRONG design — a crashed session
  leaves a stale lock (killed a 2-day zombie today that would've held one).
- **Warn on *accidental* dup, allow *coordinated* dup.** Not flat one-per-strand:
  - `cld -s X` into occupied → **refuse with a clear msg naming the culprit**:
    "astro-canon already live (pid NNNN, pts/8, up 3d) — attach to that window, or
    `--force` to open a second."
  - `forkterm new X` into occupied → same warning.
  - **`forkterm` (peer, SAME strand) → ALLOWED** — that's what a peer IS; the
    mailbox/lane mechanism makes it safe. Ideally the peer *announces* into the
    existing session's mailbox.
- **`--force` escape hatch** (warn, don't forbid). Shared helper
  `strand_is_open <strand>` used by BOTH `cld` and `forkterm` (don't duplicate).
  Touches `cld` (load-bearing) — do it deliberately, not mid-swarm.

- Sessions → OpenSearch Dashboards (osd repo): index session JSONL transcripts
  into OSD, then let the 30-day cleanup dispose of the files — ship-and-free for
  conversations. Makes mining a query instead of archaeology; complements (not
  replaces) curated STATE.md. Caveat: transcripts can embed sensitive tool
  output — keep the index local-only. Prompted by session-mining pass that found
  themes recur in HOME/repo-dir launches. — aifabric session, 2026-07-18
  *(ACTIONED 2026-07-18: new strand `aifabric-sessions` scaffolded + launched to
  build exactly this; triage = just delete this entry.)*

- **`--hints` on every key tool** (Peter, 2026-07-18): the important `super/bin`
  tools should each expose `--hints` (or a `hints` subcommand) — the AI-facing
  description, so agents pull it on demand instead of re-reading source every
  session (lazy-context applied to the tools themselves; also each keeper's
  cheap altitude). Audit 2026-07-18 — HAVE hints: secrets, resolve-host, trash,
  datedir, night-dir, cpuworker; **cld + forkterm added 2026-07-18** (aifabric
  session, straight after the gasp). STILL MISSING, by priority:
  **strand-mailbox, ding, splay** (rest of the session/comms family), then
  alert, vm, cleft, dcp, ai-gists, jlog, plm, daytmp, sample-frames. GLOBAL.md's new tool table is the interim substitute; hints
  supersede table entries as they land. — aifabric session, 2026-07-18

- **Look-around ritual: strands should survey other strands periodically**
  (Peter, 2026-07-18) — especially their *parents* (a child strand glancing at
  the strand that birthed it; kinship already exists via forkterm/colour, make
  the awareness reciprocal). Cheap form: skim recently-modified STATE.md
  headlines at session start ("the desk view"). Connects three existing inbox
  threads: active-strand detection (/proc), `cld -s` listing keepers/active
  marks, and live-strand discovery (the remaining gap from comms verification).
  Tooling candidates: `strands --status` (mtime + first heading + live?) or —
  pleasingly — query the sessions index itself (recent sessions per strand =
  the desk's pulse, once the `sessions` CLI lands). Could also make parenthood
  explicit: a `parent` line in the strand scaffold. — aifabric session, 2026-07-18

- **Altitude hierarchy in the strand tree: ancestors broad, keeper-leaves
  narrow** (Peter, 2026-07-18). Depth in the family tree = narrowness of
  concern: grandparent/trunk strands own the broad thrust (direction,
  coherence across children); leaves are keepers, narrow and service-shaped.
  Corollaries worth designing in: (a) the look-around ritual becomes
  *directional* — leaves look UP for alignment, parents look DOWN for drift/
  health, grandparents skim the whole desk at headline altitude; (b) STATE.md
  granularity should differ by depth (empirically already true: aifabric's
  STATE is thesis-heavy, aifabric-sessions' is config-heavy — bless that,
  don't fight it); (c) routing rule: narrow facts flow UP as digests,
  broad decisions flow DOWN as briefings/ratifications — a leaf with a
  cross-cutting question escalates to its parent, not sideways (this is
  exactly today's aifabric ↔ aifabric-sessions flow, formalised); (d) session
  cadence differs by altitude — trunks convene less often, mostly look-around
  + triage + direction. It's the keeper three-altitude model (tool < hints <
  digest) made fractal at the strand level. Needs the explicit `parent` file
  (see look-around entry) to give the tree traversable structure. Feeds the
  keeper-system doc (aifabric STATE #10). — aifabric session, 2026-07-18

- **Coda to the altitude entry: trunks are "strands which specialize in being
  general"** (Peter's phrase, 2026-07-18 — keep it; portfolio-quality). A trunk
  IS a keeper whose narrow subject is breadth: coherence, relations between
  children, triage, ratification. Its cheap surface = the desk view +
  GLOBAL.md conventions; its "database" = the children's STATEs; its digest
  duty = what a parent session does all day. super-keeper is the limit case:
  keeper of generality itself. Corollary that bit today: generality is a
  property of JUDGMENT, not of databases — the trunk stays general but its
  tools stay narrow (cf. aifabric-sessions decision: index transcripts only;
  curated files stay curated; code stays grep). — aifabric session, 2026-07-18

- **`strands` tool built** (2026-07-19, aifabric session — Peter: "a strand
  --new script would make the concept more understood"): `super/bin/strands` =
  list (w/ /proc LIVE marks), `new <name>` (non-interactive scaffold — fixes
  the cld y/N-hangs-automation footgun), `desk` (the look-around view),
  `--hints`. Plural name per house convention (secrets/sessions/ideas).
  Follow-up for a deliberate cld change: `cld -s <unknown>` should delegate
  scaffolding to `strands new` (single implementation; cld is load-bearing so
  not done mid-session). The /proc LIVE detection is the cheap half of the
  dup-guard idea above — reuse it there. — aifabric session, 2026-07-19

- **Vocabulary: "tepid" completes the temperature axis** (Peter, 2026-07-19).
  Warm/cold was defined as what the fork inherits at birth, but the standard
  cross-strand launch (cold session + briefing) inherits *something*: a
  curated distillate of the parent's live context. Three grades, three kinds
  of inheritance: **warm** = full transcript (uncurated, same-scope only);
  **tepid** = briefing (hand-curated handoff — the `forkterm into` /
  FORKTERM-BRIEFING.md cell; forkterms.md already calls it "warm enough",
  tepid names it properly); **cold** = STATE.md floor or nothing. Key
  insight: temperature measures *uncurated* inheritance, so it isn't a
  linear good — warm for same-thread continuation, tepid for cross-domain
  handoff (warmth would be noise: cf. bookmarks launch 2026-07-19), cold for
  a genuinely fresh visit. Fold into the pending in/into rename + forkterms.md
  doc fix (finding #2), which currently miscalls "into" cold. — aifabric
  session, 2026-07-19
