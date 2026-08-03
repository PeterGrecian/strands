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

- ~~Read aicli's existing `--tmux` flag~~ DONE (2026-08-03): `--tmux` is
  UNRELATED — it wraps ONE session in its own tmux for stable scrollback (a
  single-session convenience). It is NOT the pane-of-glass and does NOT help the
  conductor; using it on the conductor risks the tmux-in-tmux nesting the design
  forbids. Correct topology (confirmed live): conductor session launches PLAIN
  (outside tmux) and drives the SEPARATE `plane` tmux session from the CLI. Two
  distinct tmux things: `aifabric-pane` (the conductor session) vs `plane` (the
  surface it arranges, which you attach to full-screen).
- OPEN (from Peter's instinct): "self-hosting" variant — should the conductor's
  driver live INSIDE the `plane` tmux (conductor runs in the driver pane of the
  very plane it arranges)? Appealing, but it's the nesting trap unless the
  conductor still drives via CLI and never `attach`es a nested client. Decide.
- Put REAL `aicli <keeper>` sessions in the panes (replace dummy shells).
- Build the conductor agent (plain-language driver -> tmux CLI).
- Launcher menu on empty startup + live suggestions in the overview.
- Per-strand identity: coloured borders + titles (transparency can't tint
  per-pane; terminal-fork parked). Decide the colour source (each keeper's
  `colour` file).
- Where do the POC scripts finally live — promote from `aifabric-pane/poc/` into
  `~/aifabric/bin/` once past POC.
