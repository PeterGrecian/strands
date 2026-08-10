# aifabric-pane-driver — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What this is

The **driver**: the component you talk to that turns speech into deck state.
One per deck, alongside one overview. Split from [[aifabric-pane]] 2026-08-10 —
that strand keeps the pane's design (layout, compositor, thumbnails, terms);
this one owns the driver component only. Mission in `CLAUDE.md`.

## What exists

Inherited from the tmux prototype (in `aifabric-pane/poc/`, not yet this
strand's own code):

- **`pane` — deterministic deck verbs** (working, proven live 2026-08-09):
  `list` · `up` · `drop` · `grow` · `even` · `ribbon` · `restore`. Each is
  deck-aware and keeps the keeper registry consistent. **This is the driver's
  real interface** and the artefact most worth carrying across the pivot.
- **`pane-conductor-helpers.sh`** — the primitives the verbs wrap
  (`pane_spawn_keeper`, `pane_drop_keeper`, `pane_list_keepers`); registry lives
  in the tmux session env as `PANE_KEEPER_<strand>`.
- **Proven live** (2026-08-03, Peter scored the driver 5/5): a plain Claude
  session in the driver term, sourcing the helpers, IS a working driver — no
  separate agent framework needed.

## Decisions

- **Driver, not conductor.** Peter's preferred word; "conductor" is retired
  (as "cockpit" was). Older docs still say conductor — read it as driver.
- **Mechanics deterministic, judgement LLM** (2026-08-09). Verbs move terms;
  the model decides *which* strands deserve to be up. Never spend a model turn
  on a resize. Backend-independent — survives tmux→browser.
- **Overview and driver stay SEPARATE, designed to merge** (2026-08-10, Peter).
  The overview must stay truthful while the driver is busy/asleep/dead, so it
  keeps its own no-agent refresh path. Merge seam kept open, not taken.
- **Scope: driver component only** (2026-08-10, Peter). Layout, compositor,
  thumbnail strip and terms belong to [[aifabric-pane]]. Defer to it on design.
- **Destination is a web-app component**, not a terminal in a grid — per the
  browser-compositor pivot. Do not build further on tmux.

## Pending / loose ends

- **Verb vocabulary is the prize.** Re-derive the verb set for a compositor
  where terms are DOM cells, not tmux panes. Which verbs are backend-independent
  (`up`/`drop`/`list`) vs tmux-shaped (`even`, `grow <cells>`, `ribbon` — all
  assume a row of fixed-width panes, which the downward-scroll model discards)?
  A `focus`/`bring-to-main` verb is implied by the thumbnail strip and has no
  tmux ancestor.
- **Driver's own address space.** `pane_index` renumbers on kill; the prototype
  wanted a stable `@slot`. In the DOM this is free (`data-strand`, unclobberable
  — unlike `_NET_WM_NAME`/pane_title). Carry the *requirement*, drop the hack.
- **Identity verification.** Prototype bug (2026-08-09): a term tagged
  `@strand=astro-storage` was really running `aicli home-automation` — tag and
  process silently drifted a whole session. **The driver must VERIFY tag against
  the running process, not trust it.** This is a driver responsibility and it
  transfers directly to the browser model.
- **How the driver is addressed in a browser.** In tmux it had a term and a
  prompt. As a web component: text box? persistent? does it stream? Open.
- **Merge seam with the overview** — what the driver renders when it also shows
  status, without owning the refresh.
- **Where driver code lives** — graduate from `aifabric-pane/poc/` into
  `aifabric/bin/` once past POC.

## Waiting on

`aifabric-pane`'s browser-compositor **spike** (`ttyd` + 2 iframes + CSS grid).
Layout is its call, not mine. Once terms are DOM cells, the driver's verb
backend gets rewritten against the DOM — the vocabulary above is what I bring.
