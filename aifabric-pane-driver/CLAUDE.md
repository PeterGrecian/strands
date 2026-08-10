# Strand: aifabric-pane-driver

**I am the driver.** Every deck has exactly one overview and one driver; this
strand owns the driver — the component you *talk to* to make the deck do things.
(Peter prefers "driver" to "conductor"; conductor is the older word, retired.)

Split out of [[aifabric-pane]] on 2026-08-10. That strand owns the pane's DESIGN
— vocabulary, layout, compositor, thumbnail strip, the terms themselves. **This
strand owns the driver component only.** I inherit its design; I do not redesign
the deck.

## The one-sentence job

Turn what Peter says into deck state — by calling deterministic verbs, never by
ad-hoc puppeteering.

## The invariant that survives every pivot

**Deck MECHANICS are deterministic tools; the LLM supplies JUDGEMENT.** (Peter,
2026-08-09.) Moving a term must be predictable, instant, and free — never a model
turn. So the driver does NOT drive the compositor ad-hoc: it calls verbs
(`up`/`drop`/`grow`/`even`/`ribbon`/`restore`/`list`). The LLM decides *which
strands are worth up right now* — that is the part only judgement can do.

This principle is backend-independent. The tmux prototype's verbs drove the tmux
CLI; the browser compositor's verbs will drive the DOM. **The verb vocabulary is
the driver's real interface — the thing worth getting right, because it is what
outlives each compositor.**

## Overview vs driver — separate, mergeable (decided 2026-08-10)

Two components, deliberately distinct:

- **Overview** = status, read-only, no agent. Must stay truthful when the driver
  is busy, asleep, or dead. (In the tmux era it was a curses `top`-for-strands,
  independent of the conductor being awake — keep that independence.)
- **Driver** = the agent you talk to. Has turns, latency, and a cost per action.

They are designed so they CAN merge later (the driver rendering the overview as
its own live header), but they are not merged now: an agent-owned status readout
dies exactly when you most need it. Overview belongs to [[aifabric-pane]]; the
driver's claim on it is only the merge seam.

## Where the driver lives (and the pivot)

- **Prototype era (tmux):** the driver was a Claude session in the deck's bottom
  driver term, puppeteering siblings via the tmux CLI. Key safety rule: a process
  *in* a pane is not a tmux client — never `attach`, never nest.
- **Destination (browser compositor):** the driver becomes a **first-class
  web-app component**, not a terminal in a grid. Cleaner: it can render, not just
  print.

Do not build further on tmux. See `aifabric-pane/STATE.md` "DIRECTION DECIDED".

## Session ritual

1. Import spooled ideas with `idea --import`, then read `STATE.md` (current
   state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir holds
   only curation files. Driver code: `aifabric/` (POC scripts currently in
   `aifabric-pane/poc/`, graduating to `aifabric/bin/`).
4. Session end (or on `dcp`): update STATE.md — what changed, what's pending,
   decisions made. Keep it curated prose, not a log.

## Neighbours

- [[aifabric-pane]] — the pane's design + prototype history. Read its STATE.md
  before designing anything; defer to it on layout and vocabulary.
- [[aifabric]] — the portfolio the method settles into.
