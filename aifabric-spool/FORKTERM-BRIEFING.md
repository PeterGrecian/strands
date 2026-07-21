# Turn-one briefing — aifabric-spool

You are a forkterm launched into the **aifabric-spool** strand. Read `CLAUDE.md`
here (your mission) and `STATE.md`. Your inherited parent identity is suspended;
adopt this one. This file is the warm hand-off from the parent session that
spawned you — the context you need that isn't yet in the curation files.

## Where this came from

The parent session was fixing the `ding` doorbell. It found and fixed a
stale-waiter bug (owner-death self-clean + `ding --reap`, committed aifabric
`471796c`, super `53ce18b`). While there, Peter's worry generalised: the `idea`
tool solved *concurrent writes to a shared file* (`IDEAS.md`) by spooling, but
the **mailbox** and **STATE.md** have the same hazard. Peter's call: **don't
hand-code the spool a second time inside `ding` — extract a generic `spool`
tool and put both `idea` and `ding` on it.** That's your job.

## Concrete starting points (read these first)

- **`aifabric/bin/idea`** — the write side already exists as `spool_idea()`
  (around line 116): `mkdir -p`, `stamp=$(date -u +%Y%m%dT%H%M%SZ)`,
  `file=$(mktemp "$spool/$stamp-XXXXXX")`, `printf %s`. It is already generic —
  lift it verbatim as `spool put`. Then make `idea` call `spool put`.
- **`aifabric/bin/ding`** — the doorbell. Two things to know:
  1. The **SEND leg** (~line 132+) does `cat > "$mailbox"` — the overwrite
     hazard. Change it to `spool put "$mailbox_dir"` (a `MAILBOX.d/` sibling).
  2. The **ARM leg** (~line 90+) drains a single file and `: >`-truncates it —
     the consume-truncate race. Change it to `spool drain` the `MAILBOX.d/`.
     **Preserve** the owner-death self-clean (`owning_session`, `DING_OWNER`,
     the poll loop, `exit 3`) and `--reap` — the spool refit sits *inside* that
     loop, it does not replace it. Keep a legacy `MAILBOX.md` drain for compat.
- The parent **already started** editing `ding`'s header comment toward the
  spool model (the big comment block at the top now describes `MAILBOX.d/`).
  The header prose is done and correct; the SEND and ARM *code* is NOT yet
  converted — that's the actual work. Reconcile the code to match the header
  (or, if you prefer to build `spool` first and rewrite `ding` cleanly, feel
  free — just make the header and code agree at the end).

## Design decisions already made (don't relitigate)

- Spool = **one file per item**, name `YYYYmmddThhmmssZ-XXXXXX` (matches `idea`).
- `spool drain` = print-in-order + **rm each as read** (consume = delete, no
  truncate). `--keep` peeks. `count`/`list` are non-destructive.
- `spool` is canonical in `aifabric/bin`, symlinked from `super/bin` (same as
  `idea`, `ding`). Manywrapper standard: self-describing, `--hints`.
- STATE.md collision is explicitly **out of scope** — noted, one-curator
  convention for now. Don't build STATE.md locking.

## Definition of done

`spool` built + `--hints`; `idea` refitted onto it and still works
(`idea "x"` drops a file); `ding` refitted (send spools, arm drains, waiter
lifecycle intact) and verified end-to-end (two concurrent sends both survive;
consume deletes; owner-death self-clean still fires). `super` daily tools
(`idea`/`ding`/`cld`) verified intact. Then `dcp` this strand.

First turn: confirm what you've read, sketch the `spool` interface back to
Peter, and await go-ahead before the refit.
