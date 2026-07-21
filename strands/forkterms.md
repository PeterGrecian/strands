# Working method: strands + forkterms with Claude Code

A way to organise long-running work with Claude Code so that **sessions are
disposable and the durable state lives in git**, and so that one session can
spawn focused helper sessions in their own terminal windows. Two independent
ideas — adopt either alone:

1. **Strands** — a curated, git-backed "memory bank" for a recurring
   workstream, so a fresh session picks up exactly where the last left off.
2. **Forkterms** — forking the current session into its own terminal window
   to run a scoped sub-task in parallel, coordinated by asynchronous messages.

---

## Part 1 — Strands (the memory-bank pattern)

### The problem
Claude sessions are ephemeral. Relying on `--resume` to carry context is
lossy: long conversations get compacted, and you can't *edit* what the model
remembers — cruft accumulates and you can't prune it. For any theme you
revisit over weeks (a service you keep improving, a migration, a research
thread), you want a **hand-curated state that you control**, not a transcript.

### The unit
A *strand* is the unit **between a repo and a session**: a long-running theme
that may span several repos and gets revisited periodically. Each strand is a
small directory of curated files, kept in version control:

| File | Role |
|---|---|
| `CLAUDE.md` | Mission: what this strand is, which repos/areas it spans, and the session ritual (below). Auto-loaded as project context. |
| `STATE.md`  | **Curated** state: what exists, what's pending, decisions made. **Not a log** — you edit it *down* each session. This is the heart. |
| `IDEAS.md`  | Inbox: append half-formed ideas any time, from anywhere; triaged at the start of the next session. |
| `dirs`      | Extra working directories (one path per line) to add to the session's context. |
| `colour`    | Optional: a terminal background colour (hex) so each strand's window is visually distinct. |

### The loop (the ritual)
1. **Between sessions**: jot ideas into `IDEAS.md` (it's in git — add from any
   machine).
2. **Session start**: Claude reads `STATE.md` + `IDEAS.md`, and triages the
   inbox with you — promote each idea into `STATE.md`'s pending list, or drop
   it. Delete triaged items from `IDEAS.md`.
3. **Work.** Commits go to whatever repo the change belongs to; the strand dir
   holds only curation files.
4. **Session end**: update `STATE.md` — what changed, what's pending, what was
   decided. Keep it curated prose, not a diary. Commit it.

### Why it works
- **You own the memory.** `STATE.md` is editable, prunable, diffable — unlike
  a chat transcript. Bad context gets deleted; good context compounds.
- **Fresh beats resumed.** Because `STATE.md` carries everything a new session
  needs, you *start fresh* for a new visit (weeks apart) and only `--resume` to
  finish an in-flight *task* (days). No dependence on fragile session history.
- **Per-strand isolation.** Claude Code keys its session list and its
  project-scoped memory to the launch directory. So `cd`-ing into a strand dir
  before launching gives that strand its own session history, its own memory,
  and its own auto-loaded `CLAUDE.md` — for free.

### Minimal adoption
- Make a `strands/` (or `workstreams/`) directory in a repo you control.
- For each recurring theme, create `strands/<name>/` with a `CLAUDE.md`
  (mission + the 4-step ritual) and an empty `STATE.md` + `IDEAS.md`.
- Keep a top-level index (one line per strand) if you have several.
- Start each work session by `cd`-ing into the strand dir and launching
  Claude there, so session history/memory scope to it. Optionally wrap that in
  a shell function.
- **The single most important habit: end every session by editing `STATE.md`
  down to the truth.** Everything else is scaffolding around that one act.

### Two supporting conventions (optional but recommended)
- **Layered context files.** Split your Claude project context into layers:
  a *machine-local* file (identity of the box you're on — never shared), a
  *global* file (conventions shared across all your repos), and *per-project*
  files. A top loader `@`-imports the others. This keeps machine-specific and
  shared context cleanly separated and portable.
- **Memory as one-fact-per-file.** Instead of a monolithic notes file, keep a
  `memory/` directory where each file is a single durable fact with a little
  frontmatter (a `type`: e.g. *feedback* = how you want the agent to work;
  *project* = ongoing work state; *reference* = a pointer to an external
  resource). Maintain a one-line index file. Update or delete the file that
  already covers a fact rather than appending duplicates. The point is the
  same as strands: memory you can curate, not a transcript you can't.

---

## Part 2 — Forkterms (parallel scoped sessions in terminals)

### The idea
A **forkterm** is the current Claude session **forked into its own persistent
terminal window** to run a focused sub-task. Unlike a built-in sub-agent
(born to answer one prompt, invisible, gone), a forkterm is a *visible,
persistent* session in its own window that you can talk to directly and that
coordinates with the others through files.

The name is deliberately neutral (it clips "terminal" → "term", like
`xterm`): it names only the mechanism — a forked terminal session — and says
nothing about the two axes below.

### Two orthogonal axes (the mental model that makes this coherent)
- **warm / cold** — *what the fork inherits at birth.* A warm fork carries the
  full history of the session it forked from (Claude Code's `--fork-session`
  does this: it starts a **new** session id seeded with the parent's history,
  so the two diverge independently without clobbering each other's
  transcript). A cold start (a plain new session, or a fresh git worktree)
  inherits nothing. Set once, at the fork instant.
- **peer / child** — *whether it has read a role.* This is the subtle one. At
  the instant of forking, two sessions are **symmetric twins** — identical
  history, neither above the other. **The hierarchy is conferred by the
  read, not by the fork.** The moment a fork reads a role-briefing ("your one
  job is X; report back"), it accepts a subordinate frame — it *reads its way
  into being a child*. Authority is constituted by the briefing message, not
  prior to it, and it's revocable: dismiss the child and it reverts to a free
  peer.

  A practical consequence: **a warm fork defaults to believing it is the
  parent**, because it carries the parent's whole transcript. So the launch
  must hand it its new identity as the *very first thing it reads* — an
  explicit "you are the `<role>` forkterm; your inherited identity is
  suspended; your task is `<this>`." Environment variables in its shell are
  **not** enough; the agent won't consult them unless told. The identity
  hand-off has to be turn one.
- **in / into `<strand>`** — *which strand the fork targets.* A forkterm runs
  *in* a strand: **"forkterm in `<strand>`"** continues the *current* strand's
  dialogue (a same-strand peer); **"forkterm into `<strand>`"** enters a
  *different / new* strand. "Into" is the interesting one: it's a **warm launch
  of a strand** — the parent hands over the live reasoning that birthed the new
  strand, so the new session starts *warmer than STATE.md alone* would make it
  (STATE.md is the cold-start floor; the forkterm adds the parent's in-flight
  context on top). It combines a strand launch (`cd` into the strand dir for its
  own session history + memory) with a warm fork (inherited transcript) and an
  identity hand-off (turn-one briefing: "you are now the `<strand>` session").
  Do **not** call this a "promoted forkterm" — *promote* is reserved for the
  IDEAS→STATE-pending triage move; one job per word.

### Coordinating forkterms: asynchronous messaging (not signals)
Forkterms don't share live memory (each is its own session). They coordinate
**out of band**, by **asynchronous messaging** — and it's worth being precise
that this is *messaging*, not OS signals:
- **A mailbox file** — a known path per forkterm holding its briefing and,
  when done, its reply. Durable, inspectable, diffable. This is the payload
  (content, out of band) and also the forkterm's **address**.
- **A "read this" message** — the only message a parent really needs to send a
  child is *"read this"*: the content lives in the mailbox, the message just
  points at it. (Content out of band, notification in band.)
- **Colour = kinship.** Give each forkterm a terminal background that is a
  **shade of its parent's colour** (same hue, different lightness), not a
  contrasting one. At a glance you can see which windows are children of which
  trunk — family resemblance, not a random palette.

### How the message actually reaches the forkterm (the key mechanism)
Precision matters here, because the naive version is wrong. A raw OS signal
(SIGUSR1 etc.) reaches the *process* but is **not** surfaced to the agent's
loop — that dead-ends, and it's why you must not think of this as "signalling."

What *does* reach the loop is **a background task the session is waiting on**:
when that task completes, the harness re-invokes the agent (the same wake you
get when any background job finishes). So the doorbell is:

> the forkterm **arms a background waiter** on its mailbox (e.g.
> `inotifywait` on the file, a blocking read on a FIFO, or a lock) and
> yields → a peer **writes the mailbox and releases the waiter** → the
> harness **wakes** the forkterm with the completion event → it **reads and
> acts** → then **re-arms** the waiter.

That's genuine async delivery with no human in the loop and no signals
anywhere. Caveats worth knowing: the wake fires **between turns** (it can't
interrupt a turn in progress — fine for a doorbell, not hard real-time); and
the waiter must be **re-armed** after each wake or it only rings once. An
*unarmed* forkterm — one sitting idle at its prompt — still needs a human to
press enter; the message only self-delivers to a forkterm that has armed a
waiter. So "human as router" is a **choice** for a small desk, not a
**constraint**: arm the waiter and the desk self-routes.

**Verified 2026-07-17** (live test, aifabric session): a session armed
`inotifywait` on a mailbox as a background task and ended its turn; a detached
process the harness knew nothing about wrote the mailbox 30 s later; the waiter
released, the harness woke the session between turns, and it read the payload —
no human input anywhere. Both caveats behaved as documented (wake between
turns; waiter rings once). `strands/strands/ding --arm` packages this
receiving leg (consume-on-read, re-arm per wake).

**Orphaned-waiter hazard, and the fix (2026-07-21).** A waiter whose session
ends *abnormally* (SIGKILL, terminal closed, crash — the harness never gets to
kill its background task) is reparented to init and lives forever
(`timeout 0` = wait forever). The next mail written to that mailbox is then
**stolen by the orphan**: consume-on-read truncates the file before the *live*
waiter sees it, so the doorbell silently fails to ring. Two-layer fix:
- **Owner-death self-clean** — at arm time the waiter records its owning
  `claude` session (nearest `claude` ancestor) and re-checks it every ~30s,
  exiting 3 the moment the owner is gone. Handles abnormal exits; ~30s window.
- **`ding --reap`** — sweeps waiters whose recorded owner PID is dead (never
  touches a live session's waiter). `cld` runs it before *and* after every
  session, closing the self-clean window for the common clean-exit case and
  clearing orphans a SIGKILLed prior session left behind.

### This is the same primitive as `/btw` (why it's not a hack)
Claude Code already ships an async-message-into-a-loop primitive: **`/btw`** —
"ask a quick side question without interrupting the main conversation." That
is an asynchronous message into your **own current** session. A forkterm
mailbox is exactly that primitive **generalised across sessions**: an async
message to a *persistent peer* instead of to yourself. `/btw` = talk to
yourself mid-flight; forkterm = talk to a sibling. Because the built-in
feature is already async messaging, the mailbox/doorbell is not a workaround —
it's the same idea aimed at another window.

### Why a forkterm beats a fire-and-forget fork (the crux)
A plain fork (start a fresh or `--fork-session` helper and let it run) is a
**one-shot**: you brief it at birth, it runs, it returns or dies once —
communication is a single pulse at t=0, with no *back*, no *again*. A forkterm
is **persistent, addressable, and re-entrant**: because it can wait-and-be-
woken it has an **inbox**, so you can message it at t=1, t=2, … n. The
relationship is a *channel, not a pulse* — a long-lived **correspondent**, not
an errand. Persistence × async messaging = **a durable address you can keep
talking to**. That is the whole reason a forkterm is its own thing and not
just "a fork in a window."

### Lanes ≠ worktrees (keep these separate)
Two different concerns that are easy to conflate:
- **A worktree** = *filesystem/git isolation.* A git worktree gives a session
  its own checkout dir + branch, so its edits can't clobber another's and
  merges are deliberate. A *mechanism*.
- **A lane** = *task/role scope.* "Your job is X; these files; this mailbox."
  A *social contract* about what a session is responsible for.

You can have either without the other. A worktree with no lane is an
unbriefed twin; a lane with no worktree is disciplined-siblings-sharing-one-
tree (they just have to agree to stay off each other's files). A good
forkterm has **both**: a lane for scope and a worktree for isolation.

**Open tension** (unresolved — flag it if you try to automate): a *warm* fork
and a *fresh worktree* pull against each other — warm-fork carries history
but stays in place; a new worktree is a new dir that starts Claude *cold*.
A forkterm ideally wants warm history *and* an isolated tree; whether the
session history can be forked *into* a fresh worktree needs checking, not
assuming.

### Minimal adoption
You don't need bespoke tooling to get 80% of the value:
1. Open a second terminal, `cd` to the repo (ideally a `git worktree add` of
   it), and start Claude with `--fork-session` (warm) or fresh (cold).
2. Give it a mailbox file (`TASK-<name>.md`) with its identity hand-off + its
   scoped job as the **first thing you paste in**.
3. Let it write its result back into that file; the originating session reads
   it back.
4. Colour the window a shade of the parent's, and title it by role, so your
   desktop stays legible.

---

## The one-paragraph version
Keep a small git-backed directory per long-running theme ("a strand") whose
`STATE.md` is a hand-curated, prunable memory you update at the end of every
session — then start fresh each visit instead of trusting `--resume`. When a
session needs to fan out, fork it into its own terminal window ("a forkterm"),
hand that window an explicit new identity + a scoped task as its first
message, and coordinate through **asynchronous messages** (mailbox files a
peer writes and a waiting forkterm is woken by) rather than shared memory or
OS signals — the same primitive as `/btw`, aimed at a sibling instead of
yourself. Isolate with worktrees, scope with lanes, and remember hierarchy is
created by the briefing, not the fork. The forkterm's edge over a plain fork
is that it's a persistent, addressable **correspondent**, not a one-shot
errand.
