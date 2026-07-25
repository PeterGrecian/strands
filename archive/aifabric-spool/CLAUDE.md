# Strand: aifabric-spool

Extract the **clobber-safe spool primitive** into one generic house tool,
`spool`, and refit its two current hand-rolled copies onto it: the `idea` tool
(write side) and the `ding` doorbell mailbox (write + drain side). The spool is
the answer to *concurrent writes to a shared file*: instead of many writers
racing one file (lost updates, truncate-before-read), each writer drops **one
file per item** into a directory with a unique name — collisions impossible by
construction. It already appears twice; this strand makes it appear **once**.

## Why this strand exists

The pattern surfaced three times in the aifabric work:
1. `IDEAS.md` concurrent-write worry → solved by the `idea` tool spooling into
   `ideas/` (one file per idea). `idea`'s `spool_idea()` is already generic —
   nothing idea-specific in it.
2. The `ding` **mailbox** has the *same* hazard, unfixed: `cat > MAILBOX.md`
   (sender overwrites an unread message) and the receiver's `: > "$mb"`
   consume-truncate racing a concurrent send. Single-slot file = lost mail.
3. STATE.md dcp collisions (noted, not fixed — one-curator convention for now).

So: build `spool` once, put `idea` and `ding` on top of it.

## Deliverable

**`aifabric/bin/spool`** — a manywrapper-standard house tool (self-describing,
`--hints`), canonical in `aifabric/bin`, symlinked from `super/bin/spool`.
Minimum surface:
- `spool put <dir> [text]` — write one item (text arg or stdin) as a unique
  `YYYYmmddThhmmssZ-XXXXXX` file; echo the path. (= today's `spool_idea`.)
- `spool drain <dir>` — print every pending item in timestamp order and delete
  each as it's read (consume-on-read = rm the file, no truncate race). `--keep`
  to peek without consuming. This is the half that doesn't exist yet — `ding
  --arm` is its first consumer.
- `spool count/list <dir>` — cheap peek (drain's non-destructive cousins).

Then **refit**: `idea` calls `spool put`; `ding` delivers via `spool put` into
`MAILBOX.d/` and its `--arm` loop drains via `spool drain` (keeping the
owner-death self-clean + `--reap` already added, and a legacy MAILBOX.md
compatibility drain). One spool implementation, three call sites.

## Guardrails

- **Don't regress `ding`'s waiter-lifecycle fix** (owner-death self-clean +
  `--reap`, committed aifabric `471796c`). The spool refit sits *inside* that.
- **`super` must keep working** — `idea`, `ding`, `cld` are load-bearing daily.
  Verify each after refit (they're on PATH via symlinks to `aifabric/bin`).
- Portfolio bar: `spool` is a clean, standalone primitive — no fleet coupling.
  It belongs in aifabric proper, not `incoming/`.

## Session ritual

1. Read `STATE.md` and `IDEAS.md`. Triage ideas with Peter.
2. Work. Commits go to the repo the change belongs to (`aifabric` for the tool,
   `super` for symlinks/docs). This dir holds only curation.
3. Session end / `dcp`: update STATE.md — what shipped, what's pending, what was
   verified intact.
