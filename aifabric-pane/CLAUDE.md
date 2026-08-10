# Strand: aifabric-pane

**The single pane of glass for stranding — one surface through which you see and
drive every strand.** This strand IS the driver of that pane: it drives a tmux
session from an agent so all your strands live on ONE surface you look at, instead
of a scatter of terminal windows you hunt for in the taskbar.

"Pane of glass" (not "plane"): one window, laid out as a fixed three-zone frame,
that you watch and work everything through. A thread of [[aifabric]] (the pane is
part of the practice cloth); grew out of aifabric idea `20260803T144642Z-ZAMrik`,
which holds the full design.

## The pane (three-zone frame)

```
+-------------------------------------------------+
|  OVERVIEW  — live summary: "N live of TOTAL",    |  top
|  unread-mail flags, a bit of cleft, suggestions  |  (status, read-only)
+----------------------+--------------------------+
|  keeper strand       |  keeper strand           |  middle
+----------------------+--------------------------+  (panes, driver-arranged)
|  > you talk to the driver here                  |  bottom (you type here)
+-------------------------------------------------+
```

- **Driver model — drive from OUTSIDE.** The driver drives tmux via the
  plain `tmux` CLI (split-window / select-pane / resize-pane / send-keys) and is
  NEVER itself a tmux client (never `attach`) — that keeps everyone out of
  prefix-key hell. You never press Ctrl-b; you talk to the driver in its pane
  at the bottom and it rearranges the middle. ("Driver", not "conductor" —
  renamed 2026-08-10; see memory `driver-not-conductor`.)
- **Panes host KEEPERS.** Keepers are idempotent (steady-state maintain+answer,
  no fragile trajectory), so they're safe to spin up / tear down / restart on
  pane 0. Builders have a trajectory you'd disrupt; they stay in their own
  window.
- **Overview is a SUMMARY, not a list.** Headline count + only strands WITH mail
  (from the unified ding+strand-mailbox model) + a compact cleft usage line.
  Independent of the driver being awake — pure status.
- **Attention = a glance up.** A strand with mail lights up in the overview; no
  window-raising (which never worked — see [[backend-clobbers-net-wm-name]]).

## Status / where to look

POC built and liked (2026-08-03). **Code lives in the aifabric repo at
`~/aifabric/tmux-deck/`** (moved there 2026-08-10 — it used to be this strand's
`poc/`; the strand keeps curation + data only: `mondrians/`, `colour`, `SCORE`):
- `aifabric/tmux-deck/aifabric-tmux-poc.sh` — builds the 3-zone pane from outside
  via the tmux CLI (never attaches). `tmux attach -t plane` to view.
- `aifabric/tmux-deck/aifabric-tmux-overview.sh` — the summary readout.
- `aifabric/tmux-deck/restart-deck.sh` — rebuild the live deck from a mondrian.
Full design + open questions: `aifabric/ideas/20260803T144642Z-ZAMrik`.

## Session ritual

1. Import spooled ideas with `idea --import`, read `STATE.md` + `IDEAS.md`.
2. Triage new ideas with Peter: promote to STATE.md, or drop; delete from IDEAS.
3. Work. Code goes to the repo it belongs to (POC scripts -> aifabric repo for
   now); this dir holds curation only.
4. Session end / `dcp`: update STATE.md — what moved, what's pending, decisions.
