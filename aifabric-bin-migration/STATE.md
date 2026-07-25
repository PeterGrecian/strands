# aifabric-bin-migration — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Mission

Finish the `super/bin` → `aifabric/bin` tool migration by **reconciling the two
DIVERGENT tools** `bin-shadows` flags: **`cld`** and **`sessions`**. A dedicated
sub-strand so this doesn't race the live `aifabric` session (there was one at
scaffold time — dup-session avoidance, per strand-ps -s aifabric).

## What exists (context, 2026-07-25)

Five strand/session tools already graduated cleanly to `aifabric/bin` on
2026-07-25 (`strands`, `strand-ps`, `strand-mailbox`, `forkterm`,
`cld-statusline`) — canonical there, no super symlink, PATH puts `aifabric/bin`
first. `ding`, `forkchat`, `idea` are same-inode symlinks (already converged).
`aicli`, `spool`, `recolour` are aifabric-only.

**The convergence model** (see `bin-shadows --help`): settled tools are real in
`aifabric/bin`, symlinked (or absent) from `super/bin`, with `aifabric/bin`
FIRST on PATH. Safe only while every shared name resolves to the SAME file. A
**DIVERGENT** duplicate (two different real files, same name) means aifabric
silently shadows super — that is the hazard to fix here.

## The two divergences to reconcile

- **`cld`** — `aifabric/bin/cld` is a symlink → `aicli` (the graduated
  multi-backend launcher). `super/bin/cld` is a **different, older real file**
  (~17 KB, the strand launcher: `-s <strand>`, `-k` housekeeping, `--remote`,
  scaffolding). Decide: does `aicli` fully supersede super's `cld` (then
  super/bin/cld → symlink to aicli, or delete), or does super's `cld` have
  behaviour `aicli` lacks that must fold in first? **`cld` is load-bearing daily
  — do not break it.** Note super's `cld` computes `STRANDS_DIR="$BIN/../strands"`
  (location-relative); if it ever moves to aifabric/bin, fix that coupling the
  same way the five moved tools were fixed (resolve ~/strands independently).
- **`sessions`** — BOTH real and different: `aifabric/bin/sessions` (~16.6 KB)
  vs `super/bin/sessions` (~17.1 KB). Diff them, pick canonical (aifabric),
  fold any super-only behaviour in, converge (super → symlink or delete).

## Method

1. `diff super/bin/cld` vs the `aicli` it shadows; `diff` the two `sessions`.
   Understand what each super-side file does that the aifabric side may not.
2. Decide canonical + fold in deltas. Prefer aifabric as home.
3. Converge super-side to a symlink (or remove if PATH-order makes it dead).
4. **Verify:** `bin-shadows` must end **0 divergent**. Smoke-test the real
   flows: `cld -s <strand>` (launch/scaffold), `cld --remote`, `sessions search`
   / `sessions show`. Don't declare done on a diff alone — run them.
5. Commit per-repo, fastidious scope. Update this STATE + the aifabric strand's
   "bin migration" section when done.

## Pending / loose ends

- Reconcile `cld` (vs aicli) — the daily-driver launcher; highest care.
- Reconcile `sessions` (two real files) — the transcript-archive CLI.
- After both: confirm `bin-shadows` is clean; report back to ubersitrep /
  the aifabric strand.

## Decisions

- Done as a dedicated sub-strand (not in the live aifabric session) to avoid a
  duplicate-session race (2026-07-25).
