# strands — recurring cross-repo workstreams

This is the `strands` repo (`PeterGrecian/strands`), extracted from `super`.
It is symlinked into place at `~/super/strands`, so every tool and path that
reads `super/strands/<name>/` resolves here transparently.

A *strand* is the unit between "repo" and "session": a long-running theme that
spans several repos and gets revisited periodically. **Sessions are disposable;
the strand's state is curated here, in git.** See `README.md` for the full
model and launching (`cld -s <name>`).

## What lives here

- `<name>/CLAUDE.md` — the strand's mission
- `<name>/STATE.md` — current state, decisions, pending work (the durable memory)
- `<name>/IDEAS.md` + `<name>/ideas/` — inbox for triage
- `<name>/colour`, `<name>/dirs` — per-strand terminal colour and `--add-dir` list
- `.template/` — scaffold for `strands new <name>`

## Committing

Strand changes commit **here** (`~/strands`), not in `super`. `dcp` in a strand
session updates that strand's `STATE.md` and commits to this repo. The strand
*directories* are curation files only — code changes go to the repo the change
belongs to.

## Listening — mailboxes & doorbells (every strand session)

Inter-strand comms only work if sessions *listen*. The mechanism is proven;
what fails in practice is sessions forgetting to arm/drain (verified 2026-07-26:
six live sessions, zero waiters, mail piling up unread). So it's ritual:

- **At session start**: arm the doorbell as a **background task**:
  `ding --arm <strand-dir>/MAILBOX.md 0` — it blocks until mail arrives and its
  completion wakes the session. Also `strand-mailbox drain` the spool.
- **After every wake**: act on the mail, then **re-arm** — a waiter rings once.
- **At checkpoints** (between work units, `dcp`): `strand-mailbox drain` again.
- **Sending**: `strand-mailbox send <strand> <msg>` for async (persists in the
  spool); `echo "..." | ding <pts>` to wake a peer now (resolves the receiver's
  MAILBOX.md from the tty; find the pts with `strand-ps`).

## Relationship to super and aifabric

- **super** = the daily kitchen: tooling (`cld`, `strands`, `strand-ps`), the
  global context (`GLOBAL.md`). It owns the *tools* that drive strands; this
  repo owns the *content*.
- **aifabric** (`PeterGrecian/aifabric`) = the portfolio where the AI working
  method settles as its clean canonical form. "strands" is one of its threads;
  the method doc lives there, the live workstream state lives here.
