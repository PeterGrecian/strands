# strands — state

*Curated summary of the strand system itself. Updated at the end of each session.*

## What exists (as of 2026-07-11)

- Pattern built 2026-07-10 (commit 2d0a7cf): `super/strands/<name>/` with
  CLAUDE.md (mission + ritual), STATE.md (curated state), IDEAS.md (inbox),
  `dirs` (--add-dir list), `memory/` (strand-scoped, symlinked from
  `~/.claude/projects/-home-peter-super-strands-<name>/memory`).
- `cld -s <strand>` cds into the strand dir and passes `dirs` entries as
  --add-dir; per-strand session history / resume list / memory follow from
  the launch directory. Unknown strand → "Start new strand? [y/N]" →
  scaffolded from `strands/.template/` incl. memory symlink.
- Documented in `strands/README.md`; referenced from GLOBAL.md and
  super/CLAUDE.md; dcp in a strand session also updates STATE.md.
- Bare `cld -s` lists the strands. (2026-07-11)
- Strands so far: **astro-deliverables** (astro + mywebsite), **strands**
  (this one), **glacier-app** (Deep Archive photo backup — Peter's
  README/DESIGN wrapped in strand files 2026-07-11), plus astro-canon,
  astro-storage, astro-subpixel, astro-breathing, astro-speaker-dither,
  cld-colours, muppet-status, pip-maintenance, splay-{mosaics,graticule,grid}.
  astro-deliverables inbox already in use.

## Strand relationships — parent/child by mechanism (2026-07-13)

Strands can nest by *mechanism* under an umbrella. `astro-subpixel` is the
umbrella ("beat the pixel"); each dither mechanism spins out its own strand
once it goes hot: `astro-breathing` (VCM focus-breathing, active),
`astro-speaker-dither` (PWM speaker rig, **placeholder**). The umbrella keeps
theory + one-line pointers; children own the empirical detail (avoids two
STATE.md files drifting). A **placeholder strand** is legitimate: full anatomy
(CLAUDE.md/STATE.md/IDEAS.md/dirs/memory) but marked pre-work, existing so a
mechanism has a home and can be pointed at. No `colour` file until first
launch (cld auto-assigns). Spin out when a mechanism has real data or a bench
build — not before (deferred astro-speaker-dither's activation to the rig).

## forkterm — orchestrating peer sessions in terminals (2026-07-13/14)

**Name: `forkterm`** (settled). The thing = forking the *current* Claude Code
session into its own persistent terminal window. Named via a dogfooded peer
session (its brainstorm produced `sprig`/`scion`/`sib`, but its own follow-on
reasoning superseded that): the category word should be **silent on both axes
below**, and `sprig` ("a small live shoot") smuggles in child-ish/subordinate
meaning. `forkterm` names only the mechanism — a forked terminal session —
and clips `terminal`→`term` (Unix-abbrev, like `xterm`) to dodge the Germanic
compound. Verb: `cld forkterm <task>` / a flag. Reserve `scion` if the
warm-fork-carries-history nuance ever wants to be the headline.

**Two orthogonal axes (the key model):**
- **warm / cold** — what you inherit at the *fork instant*. `--fork-session`
  = warm (carries full parent history); a plain new session / worktree =
  cold (blank). Set at *birth*.
- **peer / child** — whether you've *read a role*. Set by the *first read*,
  and revocable. At the fork instant two forks are **symmetric twins** —
  neither above the other. **Hierarchy is conferred by the read, not the
  fork**: the moment a fork reads a role-briefing ("your one job is X, report
  back") it accepts a subordinate frame — it *reads its way into childhood*.
  Authority is constituted by the message ("read this"), not prior to it; a
  dismissed child reverts to a free peer. So the `ding` "read this" doorbell
  is not just task-passing — it is the act that *makes* a parent a parent.
  (Observed live: the naming forkterm woke up still acting as the trunk until
  told to read its mailbox — then it became the naming child.)

**Lanes ≠ worktrees** (Peter's correction — do NOT collapse them):
- **worktree** = filesystem/git *isolation* (own dir + branch; edits can't
  clobber; merge is deliberate). A *mechanism*.
- **lane** = task/role *scope* ("your job is X, these files, this mailbox").
  A *social contract*. A worktree with no lane is an unbriefed twin; a lane
  with no worktree is disciplined-siblings-on-one-tree (the astro-breathing
  "stay off each other's files" etiquette). A forkterm ideally has **both**:
  a lane for scope + a worktree for isolation.
- **RESOLVED (2026-07-14, via work's implementation):** warm-fork vs.
  cold-worktree *composes* — you CAN have both. `--fork-session` resumes **by
  session id**, which is global (not path-scoped), so you resume the parent's
  history *from inside* a freshly-added worktree dir. So `spawn --worktree`
  (without a `--cold` flag) = warm history AND an isolated tree. (Verify the
  session-id env var name on each host before relying on it; work assumed
  `$CLAUDE_CODE_SESSION_ID` feeds `--fork-session`.)

**Mechanism as built (prototype, hand-rolled in `strands/strands/`):**
- Launch: `setsid xfce4-terminal --title=… -e "bash -lc '…claude --resume
  <SID> --fork-session…'"`. `setsid` detaches from the parent tool process.
- Colour: set via **OSC-11/10** on the child tty (like `cld`/`ssp`). **Peer
  colour = a *shade of the parent's* hue** (Peter's rule) — same hue, stepped
  lightness by peer index → kinship is visible. NOT a contrasting colour.
  (First attempt bypassed this and got default-white; repainting the live tty
  with OSC-11 works.)
- Comms: **asynchronous messaging**, NOT signals (Peter's correction —
  don't say "signal"). The unit is an **async message** = write the
  **mailbox file** (payload, durable/inspectable); delivery is via the
  **harness wake mechanism**, not the kernel signal table. A raw OS signal
  (SIGUSR1) reaches the *process* but is never surfaced to the agent loop —
  that dead-ends. But a **background task the forkterm is *waiting on*** IS
  surfaced: its completion re-invokes the agent between turns (the same
  `<task-notification>` channel that fires when any bg job ends). So the
  doorbell mechanism is: **the forkterm arms a background waiter on its
  mailbox (inotifywait / blocking FIFO read / lock) and yields; a peer writes
  the mailbox and releases the waiter; the harness wakes the forkterm with
  the completion event; it reads and acts; then RE-ARMS.** Content out of
  band, notification in band — end-to-end messaging, no signal anywhere.
  - `ding` (`strands/strands/ding`) is the informal name for "send an async
    message that says *read this*". Current prototype only writes the mailbox
    + prints "📬 read this →" on the child tty (reaches the *human* at an
    *unarmed* forkterm). The upgrade is the armed-waiter wake above — then no
    human is needed.
  - **Caveats:** wake fires *between turns* (can't interrupt mid-turn; woken
    when next eligible — fine for a doorbell, not hard real-time); the waiter
    must be **re-armed** after each wake or it rings once (the earlier "old
    doorbell torn down" state); presumes the forkterm runs under *this*
    harness (async notifications), which it does.
  - **Better design than `ding` (2026-07-14, from work's implementation) —
    separate the durable inbox from the wake signal.** `ding` conflates them
    (write mailbox + poke), so a message sent while no waiter is armed is
    lost. Fix: **content → a durable inbox file** (write-always, never lost);
    **wake → a per-forkterm FIFO** (`forkterm wait` = a *blocking read* on the
    FIFO, run as a background command: zero CPU, no polling, no inotify, and
    it's a mechanism the harness wakes on). `send` writes the inbox THEN
    writes a byte to the FIFO. So an unread message is delivered the instant
    the next `wait` arms — nothing lost even with no waiter live. This is the
    successor to `ding`; adopt it when building first-class.
  - **UNPROVEN (highest-value experiment):** "the harness wakes on a blocking
    FIFO-read completing" is still only *reasoned*, by both sides — never
    watched end-to-end. Test: in a real forkterm run `forkterm wait` as a bg
    command, `send` from a peer, confirm the agent loop actually re-invokes
    and reads. If it fires, the autonomous story is real; if not, fall back to
    a short-lived blocking command in a re-arm loop.

- **Why forkterm > fire-and-forget fork (the crux, 2026-07-14):** a plain
  `--fork-session` or a bare sub-agent is a **one-shot** — task at birth, runs,
  returns/dies once; communication is a single pulse at t=0, no *back*, no
  *again*. A forkterm is **persistent + addressable + re-entrant**: because it
  can wait-and-be-woken it has an **inbox**, so you can message it at t=1,
  t=2…n. The relationship is a *channel, not a pulse* — a long-lived
  **correspondent**, not an errand. The mailbox is its address; async
  messaging is the delivery. This — persistence × async messaging = a durable
  address you can keep talking to — is *the* reason forkterm is its own
  category and not just "a fork in a window".

- **`/btw` vs forkterm (2026-07-14, confirmed from `/btw` help):** `/btw` =
  "ask a quick side question without interrupting the main conversation" — a
  built-in **async side-channel into your OWN current session**: slip a note
  in, it's handled without derailing the main thread. This is the harness
  *proving the async-message-into-a-loop primitive already exists* for the
  one-session case. A **forkterm mailbox is that same primitive generalised
  across sessions**: an async message to a *persistent peer* rather than to
  self. Both are async messages into an agent loop — NOT signals. Axes:
  - **recipient:** `/btw` → self (current session); forkterm → a peer session.
  - **direction:** `/btw` self→self (a parallel aside); forkterm parent⇄child
    (ongoing correspondence via a durable address).
  - **persistence:** `/btw` one session; forkterm many, each addressable.
  - **intent:** `/btw` "while we're here, also…" (non-interrupting);
    forkterm "you over there — read this and act."
  The symmetry is the strongest evidence for the vocabulary: the *built-in*
  feature is already async messaging, so `ding`/mailbox is not a hack —
  it's `/btw` aimed at a sibling instead of at yourself.
- **Identity hand-off is the critical fix:** a warm fork defaults to *being
  the parent* (it carries the trunk transcript). Env vars in its shell aren't
  enough — the agent doesn't read them. The launcher must make the *first
  prompt* the identity hand-off ("you are the `<role>` forkterm; trunk
  identity suspended; your task is `<lane>`"), not a file it must be told to
  open.

**First-class plan (not yet built):** `cld forkterm <task>` = warm-fork the
current session into a coloured window (shade-of-parent), open in its own
worktree, with a lane mailbox + the identity hand-off as turn-one, and the
inbox+FIFO doorbell wired. Artefacts so far live in `strands/strands/`
(`ding`, `MAILBOX*.md`); promote into `bin/cld` when the design settles.

**Reference design exists — converge, don't start cold.** Work independently
specced a single `forkterm` CLI from the transfer doc (round-trip: the
paradigm crossed the air gap and came back *advanced*). Subcommand surface to
converge on: `spawn <name> [--cold|--worktree|-m]` (fork into a window with
identity+lane, kinship colour, briefing as message #1; warm by default),
`send`, `reply` (child→parent via `$FORKTERM_PARENT`), `wait [--timeout]`
(arm the FIFO doorbell), `read` (full transcript, a fork's first action),
`peek` (unread count), `list` (swatch/parent/warm-cold/unread), `dismiss`
(revoke the lane → fork reverts to free peer). `name` defaults to
`$FORKTERM_NAME`. **Trunk = just another addressable peer** — it gets a
passive mailbox on first spawn so children can `reply` and it can `wait` on
itself; closes the parent↔child loop symmetrically (our `ding` was
parent→child only). Work's launcher is `wt.exe` (Windows Terminal); ours is
xfce4-terminal — keep the *concept doc* (the public gist) as the shared
source of truth and let each host own its launcher layer.

**Workflow context:** Peter is running 3–4 semi-independent tasks
orchestrated as forkterms off a trunk session. Naming was task 1 (done);
work-transfer (below) was task 2 (done).

**Published for the work Claude (task 2, done 2026-07-14):** the paradigm was
written up dossier-free as a standalone doc `strands/strands/forkterms.md`
(the canonical source, in git) and published as a **PUBLIC gist** so Peter's
**air-gapped work** Claude can pick it up. The gap is real (no ssh/email/sync;
discontinuing GDocs) and — crucially — **work can't paste/curl a hex URL**, so
*public* (discoverable via `gist.github.com/PeterGrecian` or search by title)
beats secret (untypeable hash). Gist:
https://gist.github.com/PeterGrecian/3511c09f5ccddaa1a329d7be6a5374aa
To revise: edit `forkterms.md` → `gh gist edit
3511c09f5ccddaa1a329d7be6a5374aa forkterms.md` (raw URL then serves the
update; one source, no drifting copies). Website route was considered and
NOT needed once the gist went public. Work already has the *strands* repo
(pulled before gh logout), so Part 1 (strands) is live there; the gist adds
Part 2 (forkterms).

## Doorbell investigation — CONCLUDED, with a working tool (handoff from super session 72b7c332, drained 2026-07-16)

Drained from `INBOX-from-super-72b7c332.md` (super session's 400-line handoff;
this is the curated residue — full text was deleted per its own instructions).
This **resolves the "UNPROVEN highest-value experiment"** flagged in the
forkterm section above, and gives the meta-strand its charter + north star.

**North star (make it the meta-strand mission): "empowered to think freely and
not lose work."** The two halves pull against each other — thinking freely
(roaming strands, tangents) is exactly what loses things; normal discipline
buys safety by *taxing* freedom. So the design constraint is sharp:
> **The system's job is to make losing work structurally HARD and capturing
> thought structurally FREE — so Peter thinks without bookkeeping.**
Judge every feature by it. A feature that protects work *by adding bookkeeping*
(a lockfile to clear, a commit to remember, a lane to announce by hand) is only
half-right — it must be automatic. Implication: **`strand_idea` (frictionless
capture) is top priority**; until it exists, capture has friction = lost ideas.

**"Refer, don't drift" (add to the shared session ritual).** When work touches
another strand, do NOT do it here — name the owner and hand the concern over (a
note in its inbox / a message if it's live), preferring *asking* ("is this
yours?") over deciding for it. In a *fabric* (overlapping, no clean walls)
coherence comes from good manners at the boundaries. The super session drifted
repeatedly (built forkterm from a super session, filed into aitooling, wrote
this strand's IDEAS from outside its lane) until Peter named it; the handoff
itself is the fix.

**Doorbell — settled with live evidence (supersedes the UNPROVEN note above):**
- **Push-to-terminal is structurally IMPOSSIBLE, not unreliable.** A `ding`/tty
  poke paints the terminal's *output* surface; a running Claude reads only its
  *input* (the prompt, harness-owned). Proven live: an **idle, willing `victim`
  strand** (launched at 684e3ef, *after* forkterm/mailbox landed, so not stale
  code) ignored a tty ping exactly as busy astro-canon did → limit is
  structural, not situational. Peter's crisp version: *"the terminal got the
  message, the Claude has not read it."* You cannot DELIVER to a Claude.
- **BUT push works via a channel the Claude opens.** A Claude can spend a tool
  call *blocked* on a rendezvous it opened — `read < fifo`, `inotifywait`,
  `cat fifo` — and a sender's write lands *in its context* as tool output.
  **Demonstrated live on the trunk itself** (message arrived via a `cat $FIFO`
  tool call), and Peter confirms message-passing has worked before. The
  variable was always the CHANNEL (terminal-output vs tool-opened-input), never
  "can Claudes be messaged."
- **Fifos don't buffer → messages must PERSIST.** send-to-absent-receiver is
  lost on a bare fifo (proven: a `send` timed out on empty-reader). So the unit
  is a **spool of timestamped files** (survives receiver absence) = *the same
  primitive* as the `ideas/` spool below and the forkterm mailbox above. **One
  spool primitive, several uses** (human→strand ideas; session→strand
  messages) — unify, don't build separately.
- **Pull, at a listening window the session opens.** Can't push a session to
  drain; it must `drain` itself, instant (no blocking read/fifo hang), between
  work units + at session start. Wiring `drain` into the strand ritual + `cld`
  launch is THE remaining piece.

**Working tool exists: `super/bin/strand-mailbox` (commit ea54d10)** —
`send <strand> <msg>` (always succeeds, persists), `drain [strand]` (instant
pull = the listening window), `peek [strand]` (count). Spool in
`$XDG_RUNTIME_DIR/strand-mailboxes/<strand>/` (tmpfs, NOT the git tree). Tested
end-to-end incl. the send-to-absent case. **Caveat (super's own mea culpa):**
it's the *durable-inbox half only* — MISSING THE WAKE (the FIFO + `forkterm
wait` surfaced via `<task-notification>` that this STATE.md's first-class plan
already specced). Treat it as a down-payment, not a rival; the real build is
still "durable inbox THEN poke a per-forkterm FIFO; `forkterm wait` = blocking
read run as a *background* command so its completion re-invokes the agent."

**Herding = meta-strand charter (`/proc` roster + delivery + confirmation):**
- **Roster (sensor):** `/proc/<pid>/cwd` (readable for our own procs, no sudo)
  gives which strand each live Claude is in — ground truth, better than ps.
  `pgrep -x claude` + read each cwd → candidate tool **`super/bin/claudes`**
  (strand + uptime + last-activity). NB the parent `claude` proc does *not*
  carry `CLAUDE_CODE_SESSION_ID`; cwd is the reliable identity.
- **Killer case: decommission** — "laptop off in 20 min; every strand dcp+exit
  or lose uncommitted state." (Peter: lost is irretrievable, wrongly-saved is
  fixable → herd-to-commit at shutdown is the safety net.)
- **Cooperative, NOT authoritative:** a session acts only when it drains its
  own mailbox, and **may reasonably decline** (astro-canon, mid-debug, saw the
  note and rightly kept working). Herding needs a **confirmation loop** (each
  reports done) + escalate-to-human on non-response — never fire-and-forget.
- **Sessions should record their launch commit hash** (Peter's idea) into
  STATE.md or a `.session` file — turns "which sessions run stale code" from
  inference (ps lstart vs git log) into fact; `claudes` gains a "N commits
  behind main" staleness column. Distinguishes old-code-never-heard-of-it from
  the structural tty limit. (Elders like this strand@0997121 predate the
  coordination protocol → a reason to herd-restart them.)

**Two naming seams (meta-strand's call, don't act yet):**
- **`forkterm` breaks the fabric metaphor** (fabric→strands→threads is textile
  all the way; fork+term names its *implementation*). A ply/twist-direction
  name (a thread splitting into plies that run alongside and rejoin) would
  cohere. (Reserved counter-argument already in the forkterm section: the name
  was *chosen* to be silent on the warm/cold × peer/child axes — weigh both.)
- **"term" is surface-bound:** the ROLE is "a parallel peer conversation
  coordinated by mailbox" — could be a web chat, not a terminal. Name the role,
  not the surface.

## ideas/ spool + single-writer IDEAS.md + capture/reader tools (RATIFIED design, 2026-07-16; build later)

Ratified from IDEAS.md but **deliberately not built yet** — it changes the
strand dir layout + ritual for *every* strand, so it needs its own focused
`cld -s strands` session + a considered migration. Don't half-build tooling on
an unratified structure. Surfaced by a real collision this session: parent +
a live aitooling forkterm both wanted to write one `IDEAS.md` → had to
hand-manage "commit only my file." That contention-by-care is the smell.

**Structure (the ratified core):**
- **`ideas/`** = incoming spool, a directory, **one file per idea**, many
  writers, never a shared file → no write contention. Filename = timestamp
  (collision-free by construction).
- **`IDEAS.md`** = the single curated inbox, **one authority writes it**. A
  session *drains* `ideas/*` into it, triages (promote-by-default), empties.
  Mail-system shape: anyone *delivers* to the spool; one agent *processes* it.
- **Same primitive as the forkterm mailbox** (see forkterm section above:
  "mint a timestamped file into a spool dir an owner later drains"). mailbox =
  session→session; `strand_idea` = human→strand. **Build ONE well, the other
  is a thin wrapper — do not build them as two unrelated things.** This is the
  key convergence to preserve.

**Writer — `strand_idea <strand|pwd> [text]`** (makes the spool actually get
used; without frictionless capture the spool stays empty):
- `strand_idea <strand> "one-liner"` → writes directly, no editor.
- `strand_idea <strand>` (no text) → `$EDITOR` on a stubbed file (date +
  host/session provenance + blank body).
- `strand_idea` (no arg) → infer from pwd *only when pwd is a strand dir*
  (v1; no strand↔repo map yet — you're usually in a code repo the strand
  spans, so bare-infer is limited).
- **Goes in `super/bin`, NOT the aifabric portfolio** — it's your-setup glue
  (knows `super/strands/`, your editor, host), like `secrets`/`cld`. The
  strand *method* is portable; this launcher isn't.

**Reader — activity-sorted strand list** (natural reader of the spool; design
*with* the writer against the same structure):
- Order strands by **recency of the newest undrained idea = newest file in
  `ideas/`**. Do NOT use `IDEAS.md` mtime — it's touched on drain/triage, so a
  just-cleaned strand falsely looks fresh; the spool file timestamp is honest.
- Maybe a mini triage dashboard: `name | #pending (spool depth) | latest-idea
  age | last STATE.md change`. Build the simple sorted list first; let columns
  earn their place.
- Naming: bare `cld -s` already lists strands — likely just **add sort+columns
  to it** rather than a cryptic `-ss` (does the list ever want to be
  *unsorted*? if not, one fewer flag). Blocked on `ideas/` existing.

**Migration if built:** ritual becomes "session start drains `ideas/*` →
`IDEAS.md`, triage, delete drained files"; every existing strand gains an
`ideas/` dir (deliberate, not-this-session).

## Two small cld ideas (promoted 2026-07-16; build later)

- **`cld -s` short description per strand** (~10 words after the title). Note:
  overlaps the reader/columns work above — probably land them together, the
  description becomes one column.
- **`cld -e <strand>`** — explain a strand *as it would be to the AI* (dump the
  effective mission/context a session would load). Independent of the spool.

## Pending / loose ends

- The memory symlink is machine-local; other machines would need it
  recreated (runme.bash doesn't know about strands yet; the scaffold in
  cld only creates it on the machine where the strand is first made).
- `strands/astro-storage/` has sessions but no strand anatomy; Peter's
  open session there (which holds the context) was directed to
  self-scaffold from .template + write its own STATE.md (2026-07-11) —
  verify it happened.
- `strands/pip-maintenance/` created and being worked in its own session
  (2026-07-11) — check it gains/has full anatomy.
- No strand has completed a full weekly loop yet — revisit the ritual after
  the first real astro-deliverables session.
- **Sessions archive warming a tepid fork** (promoted 2026-07-23). Can the
  sessions archive warm an otherwise-tepid fork? I.e. briefing generation
  assisted by `sessions search` — the keeper's index as a tepid-warming
  service. Connects the "tepid" vocab + lazy-context ideas: a cold fork gets
  briefed from the transcript archive instead of from nothing.

## Scaffolder symlink bug — FIXED (2026-07-23)

`strands new <name>` and `cld -s <name>` both did `cp -r "$SD/.template" "$DIR"`,
but `.template` is itself a **symlink** (→ `aifabric/method/template`, the
convergence pattern). `cp -r` copies a symlink *as a symlink*, so the new strand
dir became a symlink back to the template — and the scaffolder's `sed
s/{{name}}/…/` then rewrote the **shared template** through it. Hit twice
(ubersitrep 2026-07-22 morning; then `xfer-audio-to-phone`, which left the
template substituted to `xfer-audio-to-phone` + a stray `colour` file).

Fix (2026-07-23): both call sites now use
`cp -rT "$(readlink -f "$SD/.template")" "$DIR"` — `readlink -f` dereferences
the symlink, `cp -rT` copies its *contents* as the destination dir. Verified in
scratch (produces a real dir, not a symlink). Template restored to `{{name}}`
placeholders; stray `colour` trashed; the broken `xfer-audio-to-phone` symlink
removed. If Peter still wants an `xfer-audio-to-phone` strand, re-scaffold it
with the now-fixed `strands new`.

## Vocab: strandterm/strandchat vs forkterm/forkchat (Peter 2026-07-19)

- **strandterm / strandchat** = the RESIDENT things — a strand's live session
  in a terminal / in a browser, *however born*.
- **forkterm / forkchat** = the spawning *mechanisms* only.

This completes the substrate-agnostic active-strand grid: an active strand
shows two faces — strandterms and strandchats. Rename discussions (`in`/`into`,
the forkchat PR) should adopt this split.

## Repo-shape principle — deployment target is not a domain (2026-07-13)

`Berrylands` groups ~24 sub-projects by "runs on a Pi". Verdict: **grouping
by deployment target is the wrong default; group by domain, let deployment be
a property of the code.** Test that exposes it: *if two pieces of code share a
domain but live in different repos because they run on different machines, the
boundary is wrong* — e.g. pwmaudio's speaker electronics is one thing whether
it's deskpi chimes or astro camera-dither, yet astro has to reach across into
Berrylands for it.

**But the converse is the nuance:** when the *machine is the product*
(clocks, radio, gpioviz, the fleet substrate cloud-init-init/pi-fleet/setup_*),
machine-shaped grouping is correct — there's no non-Pi zoeclock. So Berrylands
is really two populations wearing one name: true appliances (keep) vs. domain
code that merely has a Pi node (pwmaudio, servo, gardencam's cloud pipeline —
belongs to its domain).

The rule is **incremental, not a big-bang reorg**: a sub-project leaves
Berrylands the moment a *second, non-Pi consumer* needs it — the capability
lifts into a shared lib/its domain, the thin on-Pi deployment glue stays
Pi-shaped. This is the same split as the strict-Berrylands rule + `super/
services` (non-Pi hosts), one layer down.

**Do we ever backport domain→Berrylands? No — ownership never flows uphill to
the deployment-target repo.** The rule is asymmetric on purpose. Three
domain→Pi flows, only the last is forbidden: (1) a Pi appliance *consumes* a
domain capability — a dependency/import, not a copy (healthy steady state,
e.g. deskpi tones importing the astro speaker lib); (2) a domain incubates
something *genuinely appliance-shaped* and it's *born* into Berrylands — not a
backport but a new appliance, only when machine-is-the-product (no meaningful
non-Pi version); (3) copying domain *source* back into Berrylands so the Pi
has a local copy — the real "backport", **forbidden**: it reintroduces the
drift the strict-Berrylands rule exists to prevent. Feeling the pull to do (3)
is a signal the domain lib isn't packaged well enough to depend on, or the
thing was actually an appliance (case 2). The domain owns the capability;
Berrylands owns appliances and *depends on* capabilities.

**pwmaudio is now that trigger**
(astro speaker-dither is the second consumer); resolve it when the rig goes to
bench, and have `astro-speaker-dither` point here. No repo-shape strand yet —
revisit if this becomes real migration work.

## Decisions

- Strands live in super (not a separate repo) so they ride the existing
  sync/housekeeping loop. (2026-07-10)
- Strand invocation is a flag, not a positional: `cld -s <strand>`, with
  scaffold-on-miss; bare `-s` lists strands. Bare positionals stay claude
  prompt args. (2026-07-11)
- Housekeeping is opt-in: `cld -k`/`--housekeeping` (the k in
  housekeeping) runs pull/check + push bookends; plain `cld` skips them
  (flipped from default-on). `-h`/`--help` = help, per convention —
  `-h`-for-housekeeping was rejected for colliding with it. (2026-07-11)
- Session transcripts (the JSONLs in `~/.claude/projects/…`) stay local —
  NOT moved/committed into strand dirs: the harness owns that layout for
  resume, they can contain secrets, they're bulky, and archiving raw
  transcripts inverts the design (STATE.md/memory are the curated
  product; transcripts are swarf). A git-ignored `sessions` convenience
  symlink is acceptable if wanted. (2026-07-11)
- Sessions are disposable; STATE.md/IDEAS.md are the durable state —
  resume only to finish a task, fresh session per visit. (2026-07-10)
- **A forkterm targets a strand: "forkterm INTO / IN".** (2026-07-16) A forkterm
  peer runs *in* a strand. Preposition carries the distinction: **"forkterm in
  `<strand>`"** = a peer continuing the *current* strand's dialogue; **"forkterm
  into `<strand>`"** = entering a *different/new* strand. "Into" is a **warm
  launch** — the parent hands over live session context (the reasoning so far)
  that a cold `cld -s <strand>` start would lack, then the new strand session
  continues from there. Retire "promoted forkterm" — "promote" is reserved for
  IDEAS→pending; one job per word. See [[forkterms]].
- **Triage default is PROMOTE, not drop.** (2026-07-16) Dropping an idea at
  capture is lossy and silent, decided with the *least* context (fast triage at
  session start); promoting a mediocre one is cheap and reversible (it sits
  visible in pending). So promote by default; **drop is the deliberate act.** The
  inbox already did the filtering — don't double-tax ideas. Trade-off: the lossy
  judgement moves to *pruning the pending list at review*, where you have the most
  context — so the ritual now includes pruning pending, else STATE.md rots into a
  second inbox. Same reversibility instinct as trash-not-rm and delete-last.
