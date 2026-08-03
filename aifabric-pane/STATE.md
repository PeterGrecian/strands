# aifabric-pane — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What this is

The single pane of glass: one agent-driven tmux surface (OVERVIEW / keeper panes
/ DRIVER) replacing scattered strand terminal windows. This strand is the
conductor. Split out of [[aifabric]] on 2026-08-03; full design in
`aifabric/ideas/20260803T144642Z-ZAMrik`.

## What exists (POC, 2026-08-03)

- **Working POC, and Peter likes the layout.** Two scripts in `poc/`:
  - `poc/aifabric-tmux-poc.sh` — builds the 3-zone tmux session `plane` from
    OUTSIDE the tmux CLI (never attaches; captures pane IDs so layout is
    renumber-proof). Verified: OVERVIEW top / two keeper panes middle / DRIVER
    bottom.
  - `poc/aifabric-tmux-overview.sh` — the summary readout (repaints every 5s).
- **View it:** `tmux attach -t plane` in a full-screen terminal (build first if
  gone: run `poc/aifabric-tmux-poc.sh`). Remove: `tmux kill-session -t plane`.
- Strand panes are DUMMY shells in the POC — no real aicli sessions burned.

## Decisions

- **Conductor drives from OUTSIDE, never attaches** (no tmux-in-tmux; you never
  touch Ctrl-b). You talk to the conductor in the driver pane.
- **Panes host KEEPERS** — idempotent, safe to spin up/tear down/restart.
  Builders stay in their own window.
- **Overview is a SUMMARY not a list** — "N live of TOTAL", mail-only, a compact
  cleft line. Reads the unified ding+strand-mailbox model (aifabric commit
  c17a0b4).
- **Name:** "pane" as in single-pane-of-glass (not "plane").

## Pending / next

- Read aicli's existing `--tmux` flag — it may already be half of this (FIRST).
- Put REAL `aicli <keeper>` sessions in the panes (replace dummy shells).
- Build the conductor agent (plain-language driver -> tmux CLI).
- Launcher menu on empty startup + live suggestions in the overview.
- Per-strand identity: coloured borders + titles (transparency can't tint
  per-pane; terminal-fork parked). Decide the colour source (each keeper's
  `colour` file).
- Where do the POC scripts finally live — promote from `aifabric-pane/poc/` into
  `~/aifabric/bin/` once past POC.
