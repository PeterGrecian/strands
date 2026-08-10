# aifabric-pane-driver — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What this is

The **driver**: the natural-language interface to the deck. Peter speaks
expressively; the driver understands and composes deterministic tools into the
compound task. One per deck, alongside one overview. Split from [[aifabric-pane]]
2026-08-10 — that strand keeps the pane's design (layout, compositor,
thumbnails, terms); this one owns the driver component only. Domain is the deck
and its terms, not the whole fabric. Mission in `CLAUDE.md`.

**Written up for work** in `aifabric/method/`: `panes.md` (the surface, the
driver's two-layer model, and a section on why the driver is itself a strand —
what these two files carry and why they outlive the compositor) and
`identity-verification.md` (the stale-label bug and its fix). Keep those in
sync when the mission or the jargon model changes.

## Jargon (grows from use — the live artefact)

The control vocabulary, curated as it emerges rather than designed up front.
Each entry: what Peter SAYS → what it MEANS → the tools it composes to.

**THE LADDER IS ASPIRATION, NOT ENFORCEMENT** (settled 2026-08-10 by
[[aifabric-pane]], who owns it; Peter: *"sort of - I'll get it wrong from time
to time but it's a good idea"*). Keep the ladder in the WRITING; understand
*window* / *pane* / *term* alike when he speaks; **never correct him mid-flow**.
This is the driver's standing rule for every vocabulary mismatch below.

Observed in Peter's own speech (2026-08-10, first live driving):
- **"this window"** → the term the driver is in. He says *window* for what the
  ladder calls a *term*. Per the rule above: understand it, don't correct it.
- **"<strand> bigger/smaller"** → resize by STRAND NAME, never a term id or a
  position. Confirms strand-name is the natural address (and is exactly why the
  identity guard below matters — the name must resolve to the right term).
- **"make X smaller and Y bigger"** → one utterance, one compound: a relative
  reallocation between two terms, not two independent resizes. When they share
  a column this is a single `resize-pane`.
- **"use idea to tell <strand> about X"** → compose a house tool at a named
  peer. Note he named the TOOL (`idea`) — the vocabulary reaches past deck
  geometry into fabric plumbing, which is a nudge that the deck-only scope may
  be too narrow.
- **"expand as they are used"** / **"quiescent ones shrink over time"**
  (2026-08-11) → attention-driven reflow, stated as a STANDING PREFERENCE about
  how the deck should behave, not a command to execute now. Peter states desired
  behaviour in the present tense; hearing it as an instruction would have me
  hand-resizing terms forever. **Distinguish standing preference from
  instruction** — the former goes to the strand that owns the mechanism, the
  latter gets executed. First clear instance of this mood in his speech.
- **"yes do that"** → a genuine ambiguity signal, not an instruction. It followed
  two proposals; the right move was to do BOTH rather than guess, since they were
  complementary. Treat a bare assent after a menu as "all of it" unless the items
  conflict.
- ~~**"STATUS.md"**~~ → a slip of the tongue, not jargon (confirmed by
  [[aifabric-pane]] 2026-08-10). It IS `STATE.md`; nothing to reconcile. Kept
  struck-through as a reminder that not every mismatch is vocabulary — check
  before pinning one. The silent-mapping instinct was still right.

Candidates inherited from the prototype, NOT yet heard from Peter:
**ribbon** (shrink-but-live, reversible) · **up** / **drop** · **even** ·
**main**. Watch for what he reaches for unprompted; that is the real vocabulary.

## What exists

**PATHS MOVED 2026-08-10**: the deck scripts are now `aifabric/tmux-deck/`
(was `strands/aifabric-pane/poc/`, aifabric `0a151b8`), and
`pane-conductor-helpers.sh` → `pane-driver-helpers.sh` as part of the
conductor→driver scrub (`e778b58`). Verified the identity guard survived the
move and still runs from the new path.

**RENAME GOTCHA** (from that scrub): the rename collapsed two distinct words —
"conductor" was the AGENT, "driver" was the PANE it sat in. Blind `sed` yields
"the driver's driver". Say **"the driver"** for the agent and **"the driver
pane"** for the term.

Inherited from the tmux prototype (now in `aifabric/tmux-deck/`, not yet this
strand's own code):

- **`pane` — deterministic deck verbs** (working, proven live 2026-08-09):
  `list` · `up` · `drop` · `grow` · `even` · `ribbon` · `restore`. Each is
  deck-aware and keeps the keeper registry consistent. **This is the driver's
  real interface** and the artefact most worth carrying across the pivot.
- **`pane-driver-helpers.sh`** — the primitives the verbs wrap
  (`pane_spawn_keeper`, `pane_drop_keeper`, `pane_list_keepers`); registry lives
  in the tmux session env as `PANE_KEEPER_<strand>`.
- **`pane reconcile [--fix]` + a verify-and-refuse guard** (NEW 2026-08-10, this
  strand's first real code): identity is re-derived from the running `aicli`
  argv, and no verb will act on a term whose tag has diverged. See the resolved
  item under Pending, and `aifabric/method/identity-verification.md`.
- **Proven live** (2026-08-03, Peter scored the driver 5/5): a plain Claude
  session in the driver term, sourcing the helpers, IS a working driver — no
  separate agent framework needed.

## Decisions

- **Driver, not conductor.** Peter's preferred word; "conductor" is retired
  (as "cockpit" was). Older docs still say conductor — read it as driver.
- **Natural-language interface over deterministic implementation** (2026-08-10,
  Peter — supersedes the narrower "mechanics deterministic, judgement LLM"
  reading of 08-09). The driver interprets freely; deterministic tools implement
  the compound tasks it composes. Determinism is an implementation property, not
  a limit on interpretation. Backend-independent — survives tmux→browser.
- **Jargon is wanted and grows from USE** (2026-08-10). Dense expressive terms,
  curated into the Jargon section as they recur — not a language designed up
  front. Peter never types the tool syntax to get the effect.
- **Overview and driver stay SEPARATE, designed to merge** (2026-08-10, Peter).
  The overview must stay truthful while the driver is busy/asleep/dead, so it
  keeps its own no-agent refresh path. Merge seam kept open, not taken.
- **Scope: driver component only** (2026-08-10, Peter). Layout, compositor,
  thumbnail strip and terms belong to [[aifabric-pane]]. Defer to it on design.
- **Destination is a web-app component**, not a terminal in a grid — per the
  browser-compositor pivot. Do not build further on tmux.

## Pending / loose ends

- **The vocabulary is the prize — BOTH halves.** (a) *Expressive* : the jargon
  Peter speaks, grown from use (see Jargon above). (b) *Tools* : what the driver
  emits. Re-derive the tool set for a compositor where terms are DOM cells, not
  tmux panes — which are backend-independent (`up`/`drop`/`list`) vs tmux-shaped
  (`even`, `grow <cells>`, `ribbon` all assume a row of fixed-width panes, which
  the downward-scroll model discards)? A `focus`/`bring-to-main` tool is implied
  by the thumbnail strip and has no tmux ancestor. **The two halves need not map
  1:1** — one utterance should routinely compose several tools.
- **Compound tasks are the unit of work.** "Standard layout, astro-canon in
  main" = page rebuild + several spawns + swap + resize. Worth naming the
  recurring compounds as they appear; they are the jargon's natural referents.
- **Driver's own address space.** `pane_index` renumbers on kill; the prototype
  wanted a stable `@slot`. In the DOM this is free (`data-strand`, unclobberable
  — unlike `_NET_WM_NAME`/pane_title). Carry the *requirement*, drop the hack.
- ~~**Identity verification.**~~ **DONE 2026-08-10** — and it was not theoretical:
  the bug recurred live (`%5` tagged `home-automation`, running `hardware`) and a
  resize asked for by name nearly hit the wrong strand. **ROOT CAUSE FOUND:** the
  spawn path is sound (it writes tag + registry atomically with the `aicli` it
  launches); drift comes from a HUMAN typing `aicli <other>` into a live term's
  shell. The tag is written ONCE at spawn and thereafter describes the process
  that *used to* run there. **The registry is authoritative about WHERE a term is
  and stale about WHAT it runs.** Fixed in `poc/pane*`: `_pane_term_strand` reads
  ground truth from tty + `aicli` argv; `_pane_keeper_pane` verifies and REFUSES
  on mismatch; new verb `pane reconcile [--fix]` audits and repairs the deck.
  Design lesson that transfers to the browser: **identity must be re-derived from
  the running process, never cached at spawn** — `data-strand` in the DOM will be
  just as unclobberable and just as stale.
- **Verification belongs IN the tools, not in the driver's discretion.** The
  guard sits in the resolve path every verb shares, so no verb can act on a term
  whose identity is known wrong. A driver that merely *remembers* to check is one
  distracted turn from the 08-09 failure. Generalise this: where correctness
  depends on a check, the tool enforces it.
- **How the driver is addressed in a browser.** In tmux it had a term and a
  prompt. As a web component: text box? persistent? does it stream? Open.
- **Merge seam with the overview** — what the driver renders when it also shows
  status, without owning the refresh.
- **Where driver code lives** — graduate from `aifabric-pane/poc/` into
  `aifabric/bin/` once past POC.

## Found in use 2026-08-10 (both still open)

- **DOORBELL RE-ARM LOOPS — the session ritual is incomplete.** After acting on
  mail, `strand-mailbox drain` empties the SPOOL but **not** `MAILBOX.md`. With
  `--keep` (whose whole point is a non-destructive first read) the re-armed
  waiter then sees a still-full mailbox and rings INSTANTLY, forever. Hit live
  this session. Fix in the moment: `: > MAILBOX.md` before re-arming. **The
  ritual text in every strand's CLAUDE.md says "drain and re-arm" and is missing
  this step** — worth fixing centrally, not per-strand. Plausibly the real
  explanation for the "waiter kept getting reaped at turn boundaries" note in
  `aifabric-pane` session 6b, which was written off as harness turn-cycling.
- **`pane up` cannot serve the live deck.** It needs `PANE_STRANDS_ROW`, which
  is unset on the standard-layout deck (that anchor comes from the original
  bootstrap; the deck in use was built by the standard-layout path). Had to
  split and register by hand to place a term. So the tool layer does NOT
  currently cover the deck Peter actually runs — the verbs assume a shape the
  layout has moved past. Fix belongs with the deck scripts ([[aifabric-pane]]),
  but it blocks the driver, so worth raising rather than working around again.

## Attention-driven reflow — the driver's obligations (raised 2026-08-11)

Peter's standing preference: *"panes should expand as they are used, and
quiescent ones should shrink over time."* The MECHANISM is [[aifabric-pane]]'s
(spooled `20260810T230105Z-Lbu97i`, extending their `…bz8bYS`). What lands on
the driver either way:

- **A hand-set size must PIN the term and suspend its decay.** If Peter asks me
  for a size and the deck quietly undoes it, the surface feels broken and every
  later request is untrustworthy. Any reflow I drive has to respect an explicit
  size as an override, not a suggestion.
- **The driver and overview are FURNITURE, not work** — exempt from decay. The
  driver in particular must stay findable at a constant place and a readable
  size; that is the whole point of the standard layout's diagonal corners.
- **OUTPUT IS THE PRIMARY SIGNAL** (Peter 2026-08-11: *"output is activity —
  arguably more important than input"*, correcting my first recommendation).
  I had proposed human presence driving size and output driving only a mark.
  Backwards: on a surface for watching MANY strands, the human can only be
  present at one, so presence-drives-size leaves every other term permanently
  small however hard it is working — the scatter problem again in miniature.
  Output is the signal that SCALES TO PARALLELISM, and it is what "the strand is
  doing its job" looks like while you are elsewhere. Input mostly marks where you
  already are, and you know where you are.
- **Input's real job is a HOLD, not growth.** A term you are silently reading
  emits neither output nor keystrokes and must not shrink under you. Presence
  suspends decay where you are; it does not drive size.
- **Builders must not be silently squeezed.** Keepers are idempotent and safe to
  shrink; a builder mid-trajectory is not. `splay-tweaks` is on the deck now and
  is builder-shaped — the registry calls it a keeper, which is already slightly
  a lie.

## Waiting on

`aifabric-pane`'s browser-compositor **spike** (`ttyd` + 2 iframes + CSS grid).
Layout is its call, not mine. Once terms are DOM cells, the driver's verb
backend gets rewritten against the DOM — the vocabulary above is what I bring.
