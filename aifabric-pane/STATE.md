# aifabric-pane — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What this is

The single pane of glass: one agent-driven tmux surface (OVERVIEW / keeper panes
/ DRIVER) replacing scattered strand terminal windows. This strand is the
conductor. Split out of [[aifabric]] on 2026-08-03; full design in
`aifabric/ideas/20260803T144642Z-ZAMrik`.

## WENT LIVE 2026-08-03 (session 2) — real keepers, conductor-driven, Peter 5/5

The whole design ran live and Peter loves it ("this is *so* cool", scored the
driver pane 5/5). Live `pane` tmux session with the conductor (this session) in
the driver pane puppeteering real keepers via the tmux CLI:

- **Real `aicli` keepers spawned live** into the middle via `pane_spawn_keeper`:
  ansible (took over placeholder), then ubersitrep (split right). Both booted
  real Claude Code sessions. Registry-by-name held through every id shuffle.
- **DYNAMIC frame beat the rigid template.** By hand we evolved a two-column
  layout Peter much prefers over the full-width 3-zone strip: OVERVIEW top-left
  (short, ~10 rows) + ansible full left column; ubersitrep + DRIVER stacked
  right. `join-pane -v` moves the driver into a column; per-pane `resize-pane -y`
  tunes heights. **Full-width panes are NOT wanted** — narrower panels read
  better (Peter). Getting pane shapes right dynamically (3x4 etc.) is the next
  prize → idea `20260803T165701Z-3OUK4A`.
- **Overview is now a CURSES `top`-for-strands** — `poc/aifabric-tmux-overview.py`
  (replaces the `.sh` repaint loop). One row per strand: STATE (LIVE/idle) · PID ·
  TTY · UPTIME · MAIL · **SCORE**. LIVE + mail rows sort to top; quiet tail
  collapses to "+N idle" so it fits the ~9-row OVERVIEW zone. Peter: "the overview
  is perfect."
  - **Fixed the reported bug:** old `.sh` ran `cleft` every 5s (no cache) →
    exhausted the endpoint's frequency budget (`API error 429`). Curses version
    runs THREE cadences — clock 1s, roster 5s, **cleft 300s** — with exponential
    429 back-off (cap 1h) and keeps the last good reading shown as "(stale Nm)".
  - **SCORE column** reads a plain `<strand>/SCORE` file each roster tick.
    `aifabric-pane/SCORE=5` written (Peter's 5/5). Scoring a strand = write that
    file. → idea `20260803T165701Z-q3Mt9b`.
- **Gotcha (cost 2 rebuilds this session):** these panes have NO fallback shell —
  `Ctrl-C` to a pane running `exec python3 …` exits the shell and KILLS the pane.
  Overview now runs under `while true; do python3 …; sleep 1; done` so Ctrl-C
  restarts the readout instead of destroying the pane.

## Earlier POC (2026-08-03 session 1)

- `poc/aifabric-tmux-poc.sh` — builds the 3-zone tmux session `plane` from
  OUTSIDE the tmux CLI (never attaches; captures pane IDs, renumber-proof).
  (Superseded by the self-hosting bootstrap + the live two-column frame above.)
- `poc/aifabric-tmux-overview.sh` — the original repaint readout (superseded by
  the curses `.py`; keep only as reference for the cleft-cadence bug it had).

## Decisions

- **Conductor is a tmux-CLI puppeteer that LIVES IN the driver pane** (decided
  2026-08-03, resolves the self-hosting question). It runs as a plain process in
  plane's bottom driver pane and arranges the sibling panes above it with plain
  `tmux split-window / send-keys / select-pane`. The real invariant is NOT "stay
  outside" — it's **never NEST tmux and never re-`attach`**: a process *in* a
  pane is not a tmux client, so there's ONE server, ONE prefix (yours), no
  nesting trap. You attach to plane once (the human client); you talk to the
  conductor in the driver pane; you never touch Ctrl-b.
- **Adding a keeper needs NO special machinery** — the conductor just does what a
  human would: `tmux split-window -t plane …` then `send-keys 'aicli <keeper>'
  C-m` into the new pane. No `--tmux`, no `--pane` flag, no orphan logic; the
  keeper is a plain `aicli` Claude session in the pane.
- **Panes host KEEPERS** — idempotent, safe to spin up/tear down/restart.
  Builders stay in their own window.
- **Overview is a SUMMARY not a list** — "N live of TOTAL", mail-only, a compact
  cleft line. Reads the unified ding+strand-mailbox model (aifabric commit
  c17a0b4).
- **Name:** "pane" as in single-pane-of-glass (not "plane").

## Pending / next

- ~~Read aicli's existing `--tmux` flag~~ DONE (2026-08-03): `--tmux` is
  UNRELATED — it wraps ONE session in its own tmux for stable scrollback (a
  single-session convenience). It is NOT the pane-of-glass and does NOT help the
  conductor; using it on the conductor risks the tmux-in-tmux nesting the design
  forbids. Correct topology (confirmed live): conductor session launches PLAIN
  (outside tmux) and drives the SEPARATE `plane` tmux session from the CLI. Two
  distinct tmux things: `aifabric-pane` (the conductor session) vs `plane` (the
  surface it arranges, which you attach to full-screen).
- ~~"self-hosting": does the conductor's driver live INSIDE plane?~~ DECIDED
  2026-08-03: YES. Conductor runs in plane's driver pane and puppeteers via the
  tmux CLI. Safe because "in a pane" ≠ "attached client" — no nesting (see
  Decisions).
- Put REAL `aicli <keeper>` sessions in the panes. BUILT + VERIFIED 2026-08-03
  (mechanism only, no live Claude burned). New POC files in `poc/`:
  - `aifabric-pane-selfhosted.sh` — self-hosting bootstrap: builds the frame,
    launches the conductor as `aicli aifabric-pane` INTO the driver pane, starts
    the strands row as one placeholder. Refuses to run inside tmux.
  - `pane-conductor-helpers.sh` — the conductor's hands: `pane_spawn_keeper`,
    `pane_drop_keeper`, `pane_list_keepers`. Sourced into the driver pane.
  Verified live: placeholder-reuse (1st keeper), split (2nd), idempotent respawn,
  registry list, drop, re-even, error paths. Frame stayed intact throughout.
  KEY FINDINGS (both cost a rebuild):
  1. `select-layout even-horizontal` FLATTENS the whole window (destroys the
     3-zone frame). Even the strands row by hand: resize each row pane (found via
     shared `#{pane_top}`) to window_width/N. Never window-wide select-layout.
  2. Pane identity must NOT use `#{pane_title}` — Claude Code rewrites it to
     "✳ Claude Code" every turn (tmux twin of backend-clobbers-net-wm-name).
     Track keeper→pane_id in the tmux SESSION ENV (`PANE_KEEPER_<strand>`), prune
     stale entries on resolve. See memory `pane-title-clobbered-by-claude`.
  ~~STILL UNTESTED: real `aicli` in a pane + conductor calling helpers.~~ DONE
  live 2026-08-03 session 2 (see WENT LIVE above) — worked end to end.
- **Dynamic pane-shaping (the next prize):** make the conductor COMPUTE an N×M
  grid from live keeper count + zone needs, instead of by-hand splits. The
  two-column frame we built by hand is the target shape to reproduce
  automatically. → idea `20260803T165701Z-3OUK4A`.
- **Overview features Peter asked for:**
  - Effectiveness SCORE column — DONE (minimal: `<strand>/SCORE` file). Next:
    a `score <strand> <n>` helper so the driver writes it, not by hand. → idea
    `20260803T165701Z-q3Mt9b`.
  - Per-keeper CONTEXT/TOKEN count — HARD (each keeper is its own Claude process;
    no local interface; only screen-scrape the statusline, clobber-prone). Parked
    as aspiration. → idea `20260803T165701Z-3v1Bli`.
- Build the conductor agent (plain-language driver -> tmux CLI). Note: proven
  this session that a plain Claude session in the driver pane, sourcing
  `pane-conductor-helpers.sh`, IS the conductor — no separate agent needed yet.
- Launcher menu on empty startup + live suggestions in the overview.
- Per-strand identity: coloured borders + titles (transparency can't tint
  per-pane; terminal-fork parked). Decide the colour source (each keeper's
  `colour` file).
- Where do the POC scripts finally live — promote from `aifabric-pane/poc/` into
  `~/aifabric/bin/` once past POC. The curses overview `.py` is the graduation
  candidate.
