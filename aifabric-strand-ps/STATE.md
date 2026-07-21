# aifabric-strand-ps — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **`super/bin/strand-ps`** (built 2026-07-21) — process-centric view of running
  Claude sessions, the dual of `strands list`. One row per live `claude`: PID,
  TTY, uptime, strand, cwd — mapped via `/proc/<pid>/cwd` (ground truth, never
  stale; same technique `strands`' `live_cwds()` uses for its LIVE flag).
  Modes: bare table; `-s <name>` filters to one strand; `-q` emits bare PIDs;
  `--hints` AI-facing. Documented in `super/CLAUDE.md` tools list.

  This is the "real `strand-ps` / shared entry point" that aifabric PR #5's
  method-graduation note gestured at. Before it, `strand-ps` was a *phantom* —
  a name proposed in that note, never on disk, called by nothing (verified
  against the 2026-07-21 home-work-comms session and its correction idea
  `20260721T185600Z-UbAP9m`).

## Pending / loose ends

- **forkterm dup-session guard** (aifabric owns forkterm): `forkterm into <strand>`
  should consult `strand-ps -s <strand>` (or shared `live_cwds()`) and warn
  "a live session already has cwd in this strand — raise it? (y/N)" before
  launching a duplicate. `strand-ps -s <name>` is the check to call. Origin:
  the 2026-07-21 duplicate-aifabric-sessions near-miss (operator error, but the
  guard would have caught it). Ideas: `aifabric/ideas/20260721T184439Z` +
  its correction `20260721T185600Z`.
- **forkterm window-raise** (`forkterm ls` / `forkterm raise <strand|id>`):
  windows aren't identifiable — set an immutable `--role`/WM_CLASS at launch,
  then `wmctrl`/`xdotool` to raise. Pairs with the dup-guard (shared live-window
  registry). Idea: `aifabric/ideas/20260721T185421Z`. Pure forkterm work.

## Decisions

- `strand-ps` is process-centric; `strands list` stays strand-centric. They are
  duals over the same `/proc` ground truth, not redundant. No `.tty` marker
  scheme exists or is wanted — `/proc/<pid>/cwd` is authoritative.
- Dup-detection is `strand-ps -s <name>` returning >1 row. Kept `-s`
  filter-based (not column-parsing) so counts are exact regardless of display.
