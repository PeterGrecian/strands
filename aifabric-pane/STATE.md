# aifabric-pane — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What this is

An **aifabric-pane**: one agent-driven surface replacing scattered strand
terminal-emulator windows. Split out of [[aifabric]] on 2026-08-03; full design
in `aifabric/ideas/20260803T144642Z-ZAMrik`.

**This strand owns the pane END TO END** — surface *and* driver. Consolidated
2026-08-22 (3 strands → 1): `aifabric-pane-driver` merged back in (see THE
DRIVER below) and `strandchat` archived as a closed direction (see CHAT below).
The surface had grown three strands that could only be worked on together;
routing anything about panes, decks, layout or the driver comes here.

## DIRECTION DECIDED 2026-08-10 — browser compositor (read this first)

**The tmux deck was a PROTOTYPE, not the destination.** It proved the
pane-of-glass concept with real sessions; its frictions (page-jumps, can't share
the screen with a browser, a tmux pane can't leave the deck window) were the
prototype showing tmux's limits as a compositor. Everything below the "Sessions"
line is prototype-era — reinterpret it under this model, don't build further on
tmux.

**Origin → destination (the through-line: never let the window manager place
things).** forkterm/strandterm spawned each strand as its own OS window → manual
placement chaos, hunting in the taskbar (worsened by
[[backend-clobbers-net-wm-name]]: windows wouldn't stay identifiable or raisable).
The tmux deck put them on ONE surface (cured the scatter, rigid compositor). The
cure: **the browser as compositor** — YOU own the layout (CSS), so one surface AND
no jump AND it can hold a browser.

**The product model:**
- **Terms in a browser** (xterm.js — production-grade, powers VS Code/Codespaces;
  `ttyd`/`wetty` serve a shell or `tmux attach` over websocket). tmux may still run
  *inside* each term for persistence, or each term is a direct ttyd→aicli.
- **Main working area EXPANDS DOWNWARD**, not sideways — a tall vertical SCROLL,
  not a wide grid. This is the NO-JUMP answer (vertical scroll is continuous +
  natural; every web page/chat reads this way). A term / web view / QR picture are
  all just content in the main area.
- **Thumbnail strip on the RIGHT** = the navigator: small LIVE previews of each
  term; glance right for all-strands state, click to bring one into the main area.
  The taskbar done right — replaces BOTH the overview AND get-lost-between-pages.
- **Driver agent** = the driver you talk to, now a first-class web-app
  component (cleaner than Claude-in-a-tmux-pane).

Wrong turns corrected: forkchat/strandchat (chat was the wrong shape); deck as
destination (it was scaffolding). Ideas: product model `20260810T082947Z-cziQvD`,
origin `20260810T083137Z-3ID15i`, pivot assessment `20260810T082517Z-fDffQO`.
**Next: a spike** — `ttyd` + 2 iframes (one a keeper, one an image) + CSS grid, to
feel the no-jump downward scroll and test copy/paste + keybinding friction.

### ATTENTION-DRIVEN REFLOW — sized by OUTPUT, not presence (2026-08-11)

Terms grow as they are used and **decay continuously toward a floor as they go
silent**, so the deck self-balances toward where the work is. Peter: *"panes
should expand as they are used, and quiescent ones should shrink over time."*

**Output is the primary size signal — not human presence.** The driver first
proposed presence (active term, keystrokes) and then corrected itself, for a
reason that goes to what the deck is FOR: on a surface built to watch MANY
strands in parallel, the human can only be present at one. If presence drove
size, every other term would be permanently small however hard it was working —
the scatter problem again in miniature, one big term plus decoration. Output is
the signal that *scales to parallelism*, and it is what says a strand is doing
its job while you are elsewhere. Peter: *"output is activity — arguably more
important than input."*

Presence keeps one specific job: **the reading problem.** A term you are
silently reading emits neither output nor input, and must not shrink under you —
so presence acts as a HOLD that suspends decay, never as a growth driver.

Constraints, all from real use:
- **Floors and ceilings** — never decay below readable. Overview and driver are
  FURNITURE, exempt (the overview auto-fits short by design).
- **Never fight the human** — a hand resize, or a size he asks for, PINS the term
  and suspends its decay. Otherwise the deck undoes what he just asked for.
- **Builders must not be squeezed.** Keepers are idempotent and safe to shrink; a
  builder mid-trajectory silently squeezed to 3 rows is a worse outcome.
- **Eased, not jumped** — slow enough never to move text under a reading cursor.
- **The standard layout is the equilibrium decay returns to**, not something
  reflow overwrites — otherwise free-running reflow erodes the diagonal corner
  symmetry, which is deliberate.

**Where it lives: the browser spike, probably not tmux.** CSS transitions make
eased continuous resize trivial, and output volume is trivially available as
bytes/sec down each websocket; `resize-pane` in a poll loop is a crude
approximation fighting a binary split tree. This is a strong first-class demo
FOR the compositor — it shows why the browser is the right destination.
Ideas: `20260810T230105Z-Lbu97i` + correction `20260810T230206Z-nZekr0`.

## VOCABULARY (settled 2026-08-03 session 3 — use these words, not tmux's)

**an aifabric-pane → deck → page → terminal.**

| Level   | Word | tmux term | What it is |
|---|---|---|---|
| Product | **an aifabric-pane** | (product) | The whole thing. "pane" lives HERE, at the product level. |
| Top     | **deck**     | session | The tmux container; survives detach. |
| Mid     | **page**     | window  | One full-screen arrangement; flip via the page strip. |
| Leaf    | **terminal** | pane    | One shell/keeper/driver/overview (a pty). SEVERAL per page. |

Rules: "pane" names ONLY the product (so the strand name is correct, not a
misnomer). The leaf is a **terminal** — but Peter leaned toward **"term"** on
2026-08-09 ("maybe term rather than terminal — it's not quite a terminal, we'll
work on that"), since the leaf is a strand-slot that merely *hosts* a pty. Not
yet settled; "term" is the working shorthand. Retired: "single pane of glass",
"cockpit", "session"/"window" as our words, "3-zone". Say "terminal-emulator" for
the desktop app (xfce4-terminal) to avoid clashing with terminal-the-leaf.
Full rationale in memory `pane-of-glass-vocabulary` + `no-cockpit-naming`.
NB the live tmux session is still *named* `pane` (its tmux id) — rename to `deck`
when convenient. Terminals do NOT nest; a labelled cluster is BUILT via the
keeper registry, not a tmux primitive.

### Page strip = a HyperCard card stack (idea 20260803T180658Z-3xAh6v)
Peter's HyperCard recall (Mac 1987, Atkinson — stack of index cards). Pages =
cards: a page-tab should be a little CARD with a headline + a few summary lines
(keeper count, unread mail, what's live), not tmux's cryptic `n:name`. Buildable
in the curses overview surface we already own.

---

## THE DRIVER — merged in from `aifabric-pane-driver` (2026-08-22)

`aifabric-pane-driver` was split out on 2026-08-10 and **archived back into this
strand on 2026-08-22**: the split was made while tmux was the compositor and the
driver was a Claude session in a pane. Under the browser pivot the driver is *a
component of this surface* ("a first-class web-app component"), and the driver
strand's own last word was **"Waiting on `aifabric-pane`'s spike"** — two strands
blocked on each other over one surface. One strand now owns the pane end to end.
Its full history is in `archive/aifabric-pane-driver/`.

### The one-sentence job

**The driver is the natural-language interface to the deck.** Peter speaks; the
driver understands; it composes deterministic tools into the compound task.
Every deck has exactly one overview and one driver.

### The layering — interface over implementation (Peter, 2026-08-10)

| Layer | What it is | Property |
|---|---|---|
| **Expressive control** | What Peter says. Jargon, dense and precise. | Interpreted |
| **Deterministic tools** | What the driver emits. Verbs, composed. | Predictable, identical every time |

**Interpret freely — that is the job.** Determinism is a property of the
*implementation*, not a limit on what may be understood. A resize asked for in
words always costs a turn; the turn IS the interface and is already paid. What
determinism buys is that the compound task executes reliably once understood.

**Jargon is wanted, not avoided.** `pane grow astro-storage 20` is what the
driver EMITS; *"ribbon the quiet ones, bring astro-storage to main"* is what
Peter SAYS. Never make him type the first to get the second. **Compound is the
unit** — one utterance routinely becomes several tool calls.

**Overview and driver stay SEPARATE, designed to merge** (2026-08-10, Peter).
The overview is status, read-only, no agent, and must stay truthful while the
driver is busy, asleep or dead. The merge seam is kept open, not taken.

**Driver, not conductor** (Peter's word; "conductor" retired, as "cockpit" was).
Rename gotcha: the scrub collapsed two words — "conductor" was the AGENT,
"driver" was the PANE. Say **"the driver"** for the agent, **"the driver pane"**
for the term; blind `sed` yields "the driver's driver".

### Jargon (grows from use — the live artefact)

The control vocabulary, curated as it emerges rather than designed up front.
**THE LADDER IS ASPIRATION, NOT ENFORCEMENT** (Peter: *"sort of - I'll get it
wrong from time to time but it's a good idea"*): keep window/pane/term precise in
the WRITING, understand them alike when he speaks, **never correct him mid-flow**.

Observed in Peter's own speech (2026-08-10, first live driving):

- **"this window"** → the term the driver is in. He says *window* for *term*.
- **"<strand> bigger/smaller"** → resize by STRAND NAME, never a term id or
  position. Strand-name is the natural address — which is exactly why the
  identity guard matters: the name must resolve to the right term.
- **"make X smaller and Y bigger"** → one utterance, one compound: a relative
  reallocation between two terms, not two independent resizes.
- **"use idea to tell <strand> about X"** → compose a house tool at a named peer.
  He named the TOOL — the vocabulary reaches past deck geometry into fabric
  plumbing, a nudge that a deck-only scope was too narrow (and an argument for
  this merge).
- **TERM HEIGHTS — three useful sizes, arrived at by feel (2026-08-17).** Peter
  set these live; they are the floors the decay model needs, and they are HIS
  numbers, not derived:
  - **2 rows = a RIBBON.** Parked, alive, visible, clickable — not readable.
    Enough for the border label plus one line.
  - **9 rows = the useful minimum.** Peter: *"this is a useful size whilst 6 was
    not"* — the readable/unusable boundary sits between 6 and 9.
  - **5 rows = too small to type into.** Peter: *"I can't read the typing"*.
  Consequence for reflow: a quiet keeper may decay to 2, but a term being TYPED
  INTO must never fall below ~9. **Interactive and watched terms need DIFFERENT
  floors; one global minimum gets it wrong either way.**

### The tool layer (inherited from the tmux prototype)

Code in `aifabric/tmux-deck/` (moved there 2026-08-10, aifabric `0a151b8`;
`pane-conductor-helpers.sh` → `pane-driver-helpers.sh` in `e778b58`).

- **`pane` — deterministic deck verbs** (proven live 2026-08-09): `list` · `up` ·
  `drop` · `grow` · `even` · `ribbon` · `restore`. **This is the driver's real
  interface** and the artefact most worth carrying across the pivot.
- **`pane-driver-helpers.sh`** — the primitives the verbs wrap; registry lives in
  the tmux session env as `PANE_KEEPER_<strand>`.
- **`pane reconcile [--fix]` + verify-and-refuse guard** (2026-08-10): identity
  re-derived from the running `aicli` argv; no verb acts on a term whose tag has
  diverged. Written up in `aifabric/method/identity-verification.md`.
- **Proven live** (2026-08-03, Peter scored the driver 5/5): a plain Claude
  session sourcing the helpers IS a working driver — no agent framework needed.

### Driver obligations under attention-driven reflow

- **A hand-set size must PIN the term and suspend its decay.** If the deck
  quietly undoes a requested size, the surface feels broken and every later
  request is untrustworthy. An explicit size is an override, not a suggestion.
- **Driver and overview are FURNITURE, not work** — exempt from decay. The
  driver must stay findable at a constant place and a readable size.
- **Builders must not be silently squeezed.** Keepers are idempotent and safe to
  shrink; a builder mid-trajectory is not.

### Driver-side open questions (carried forward)

- **The vocabulary is the prize — BOTH halves.** Re-derive the tool set for a
  compositor where terms are DOM cells: which verbs are backend-independent
  (`up`/`drop`/`list`) vs tmux-shaped (`even`, `grow <cells>`, `ribbon` all
  assume a row of fixed-width panes, which the downward-scroll model discards)?
  A `focus`/`bring-to-main` verb is implied by the thumbnail strip and has no
  tmux ancestor. **The halves need not map 1:1.**
- **Compound tasks are the unit of work** — name the recurring compounds as they
  appear; they are the jargon's natural referents.
- **Driver's own address space.** `pane_index` renumbers on kill; the prototype
  wanted a stable `@slot`. In the DOM this is free (`data-strand`). Carry the
  *requirement*, drop the hack.
- **Identity must be re-derived from the running process, never cached at
  spawn.** Root cause found 2026-08-10: the spawn path is sound; drift comes
  from a human typing `aicli <other>` into a live term's shell, so the tag
  describes the process that *used to* run there. **The registry is
  authoritative about WHERE a term is and stale about WHAT it runs.**
  `data-strand` in the DOM will be just as unclobberable and just as stale.
- **Verification belongs IN the tools, not in the driver's discretion.** The
  guard sits in the shared resolve path. Generalise: where correctness depends
  on a check, the tool enforces it.
- **How the driver is addressed in a browser** — text box? persistent? streaming?
- **`pane up` cannot serve the live deck**: it needs `PANE_STRANDS_ROW`, unset on
  the standard-layout deck. The verbs assume a shape the layout has moved past.
- **Doorbell re-arm loop** (found 2026-08-10, still worth fixing centrally):
  `strand-mailbox drain` empties the SPOOL but not `MAILBOX.md`, so a `--keep`
  waiter re-arms against a still-full mailbox and rings instantly, forever. Fix
  in the moment: `: > MAILBOX.md` before re-arming.

## CHAT — a closed direction (`strandchat` archived 2026-08-22)

`strandchat`/`forkchat` was **the wrong shape**, as recorded in the pivot above:
a chat transcript per strand is not how you watch many strands — the thumbnail
strip is. The strand is archived (`archive/strandchat/`, with its deployment
sketch in `ARCHITECTURE.md`: pip-brain/puppy-window, Tailscale `--serve`).

What survives it and must not be lost:

- **`aifabric/bin/forkchat` is shipped and hardened** (PR #3 `c7f2046`, hardening
  `e7804fe`: Basic-auth, Host-header allowlist, fail-closed off loopback).
  Ownership passes to the **[[aifabric]]** strand as one of its `bin/` tools; it
  is no longer a workstream of its own.
- **The phone-onto-the-mesh requirement is real and unmet.** Reaching the mesh
  from a phone over Tailscale was chat's genuinely good idea. It belongs to the
  browser compositor now — a surface served over `--serve` answers it better
  than a chat page did.
- **The format gap is still open**: the live strand-mailbox spool is flat and
  loses sender/lineage; the `~/.forkterms` tree wants `### src → dst`, colour and
  parent. Whichever surface reads mail eventually has to pick a direction.

## PROTOTYPE-ERA (tmux deck) — history below this line

*The sessions below built and refined the tmux-deck prototype. Kept for the
findings (many transfer: identity-by-registry, the no-jump requirement, the
thumbnail/overview instinct, deterministic verbs). Do not build further on tmux —
see DIRECTION DECIDED above.*

## Session 6b (2026-08-09) — standard layout, live rearranging, two bugs found

Drove the live deck hands-on with Peter (attached-driver). Outcomes:

- **STANDARD LAYOUT defined + saved** (`mondrians/standard.mondrian`): 3 cols × 2
  rows, DIAGONAL CORNER SYMMETRY — overview top-left SHORT, driver bottom-right
  SHORT (always-findable home). Two LONG work terms (main-thrust left column +
  top-right); two SECONDARY terms in the middle column. Overview auto-fits short,
  which is what MAKES col1's lower term long (feature). Build notes in the idea:
  tmux `tiled` picks 2×3 at wide aspect — build 3×2 by hand (even-horizontal→6
  cols, join-pane -v pairs into 2 rows, resize cols to W/3); `swap-pane` moves
  terms between cells with @strand travelling (no relaunch). Later variant saved
  as `qr-work` (astro-canon full-height middle, home-automation top-right).
- **`recolour` a strand:** home-automation pinned GREEN by hand (`colour` file →
  `004d00` deep dark green, like ubersitrep's red pin), repainted live via the
  house `recolour` tool. Hand-overrides sit outside the golden-angle wheel — a
  bulk regen would clobber them (same fragility as ubersitrep).
- **BUG: identity divergence** — a deck term tagged `@strand=astro-storage` was
  ACTUALLY running `aicli home-automation`; the tag and process had silently
  drifted all session (we believed astro-storage was backfilling — it was
  home-automation; astro-storage wasn't running at all). @strand is only
  clobber-proof if kept in sync on swap/relaunch. Fix: deck should VERIFY tag vs
  the running process, not trust it. (idea `…l7LjQS`)
- **BUG: deck window title clobber + fullscreen degrade** — the deck's X11 window
  title got rewritten to `astro-canon` (backend-clobbers-net-wm-name) and
  fullscreen had fallen back to MAXIMIZED. Fixed live: `xdotool set_window --name
  pane` + `wmctrl -b add,fullscreen`. Needs a title REASSERTER loop to stick.
- **WORKSPACE/BROWSER GAP** — Peter wanted a term beside a Chrome browser (QR
  lookup): WS2 = 1/3 term + 2/3 Chrome. Blocked: a term is a tmux pane inside the
  fullscreen deck window; XFCE workspaces move WINDOWS not panes. Design question
  banked (idea `…XyPg59`): how does one term coexist with a non-deck window?
- **tmux has NO focus-follows-mouse** (that's a WM feature); click-to-focus via
  `mouse on` (already live) is the closest. `focus-events` is unrelated.
- Doorbell waiter kept getting reaped at turn boundaries this session; spool stayed
  empty throughout (no mail missed). Harness/turn-cycling interaction, not a fault.

## Session 6 (2026-08-09) — deterministic verbs, border fix, design cluster

Attached-driver session (this session drove the live deck from the driver
term, %6). Fixes + a coherent design cluster spooled (9 ideas). Kept working
because the deck was mid-use: astro-storage backfilling, ubersitrep done-for-now.

**Live fixes to the deck:**
- **Closed the ansible keeper** (`pane_drop_keeper ansible`); astro-storage stays
  live. astro-storage was ALREADY a keeper (not off-deck) — "move it there" = just
  drop ansible, astro-storage reflows in.
- **Border legibility bug FIXED.** Both `pane-border-style` AND
  `pane-active-border-style` were `fg=#53008f` (dark purple) on black — illegible
  AND identical (couldn't tell the active term). A strand KINSHIP COLOUR had leaked
  into the GLOBAL border style. Fixed live → `fg=colour245` (grey) /
  `fg=colour39,bold` (blue active). Also `pane-border-status` had been left `off`
  so NO strand names showed — turned back `top`. ROOT CAUSE of the leak still to
  find (idea) so it can't recur on rebuild.
- **ubersitrep recovered** from a `/model` overlay Peter opened (status line had
  been taken over; Esc/Enter dismissed it) and the stray `I` at its prompt cleared
  (`C-u`). Not a deck fault — transient in-app UI state.

**Identity layers clarified (corrects earlier muddle):**
- **BORDER (top) = reliable identity** — tmux-drawn from `@strand`, deck-controlled,
  overlay-proof (e.g. `3: ubersitrep`). This is the trustworthy layer.
- **Claude STATUS LINE (bottom) = app plumbing** — per-session, mostly noise
  (`⏵⏵ bypass · 1 shell · 1 agent`); the one useful token (strand) duplicates the
  border. Direction: quieten it for keepers via aicli statusLine config.
- **Border repaint LAGS** — a term showed no strand name until Peter resized
  (forced redraw). Needs a redraw nudge (refresh-client) after spawn / @strand set.
- **DESIGN FORK** (open): Peter may DROP borders for the Metro "tiles join up" look
  → then the status line MUST carry identity (one line: strand · context · git),
  trading overlay-proof identity for the clean look. Not decided.

**`poc/pane` — deterministic deck verbs (NEW, working):**
- Principle Peter set: deck MECHANICS = deterministic tools, NOT natural-language-
  to-the-driver. Predictable, instant, free, self-documenting; LLM reserved for
  judgement, and even the driver CALLS these verbs rather than driving tmux
  ad-hoc. Supersedes any "just say it to the driver" option.
- Verbs (all deck-aware, keep PANE_KEEPER registry consistent; wrap the existing
  helpers): `list` (with `[ribbon]` mark) · `up` · `drop` · `grow` · `even` ·
  `ribbon` (shrink-but-alive) · `restore`. Proven live on ubersitrep.
- Ribbon = shrink-but-live + reversible. OPEN (not a bug): ribbon PLACEMENT —
  Peter's model is a small strip parked UNDER the top-left term, which tmux's
  binary-split-tree can't do by resize alone (needs join-pane/select-layout).
- NEXT: promote 2-3 verbs to `bind -n` root chords (no Ctrl-b) once the vocabulary
  settles; `pane_index` renumbers on kill → addressing needs a stable `@slot`.

**Also learned:** tmux has NO focus-follows-mouse (that's a WM feature, not tmux);
click-to-focus via `mouse on` (already live) is the closest. `focus-events` is a
different thing (forwards focus events to apps inside).

Design cluster (all interlock: attention-driven reflow + stable-addressed terms +
deterministic verbs/hotkeys) is in `ideas/` — triage next session.

## Session 5 (2026-08-03) — restart-deck hardened + `panedeck` launcher

Deck is now a one-command cold start Peter likes. Two scripts in `poc/`:

- **`panedeck`** — opens the deck in its OWN full-screen, chrome-free
  terminal-emulator window and attaches. If the deck (`pane` session) isn't up,
  it rebuilds via `restart-deck.sh` first. Refuses to run inside tmux (no
  nesting). Peter will remember the name `panedeck` (chosen over `open-deck.sh`).
  - **TRUE full-screen is asserted via `wmctrl`, NOT `xfce4-terminal --fullscreen`**:
    the built-in flag loses a race with the WM at map time and silently falls
    back to MAXIMIZED (panel + titlebar still eat the top ~99px). We launch
    without it, wait for the window (matched by frozen title `pane`, via
    `xdotool search --name '^pane$'`), then `wmctrl -i -r <wid> -b add,fullscreen`.
    Verified: `_NET_WM_STATE_FULLSCREEN`, geom `0 0 1920 1080`. F11 toggles out.
  - Scrollbar/menubar/toolbar hidden on THIS window only (`--hide-*`); other
    terminal-emulator windows keep their scrollbar. `--dynamic-title-mode=none`
    freezes the title `pane` (CLI twin of TITLE_HIDE; keeps panel label + the
    fullscreen lookup valid).
- **F9 minimises the deck window** — bound in restart-deck.sh (tmux root table,
  no prefix) to `xdotool ... windowminimize` on the window titled `pane` (wmctrl
  hidden as fallback). When full-screen the WM never sees the key, so tmux does
  the shell-out. F11 still toggles fullscreen (terminal-emulator handles that).
- **`restart-deck.sh` fixes:**
  1. **Keepers were launching as bare shells** — `aicli <strand>` hit aicli's
     de-dupe ("already live", prints "launch another with: aicli --new") and
     dropped to a shell, leaving panes empty. Fix: `aicli --new <strand>`
     everywhere. (Peter: "-N is fine I'll be careful" re: duplicate sessions.)
  2. **Driver pane now runs the driver** — `driver` slot launches
     `aicli --new aifabric-pane` (the strand that IS the driver), not a bare
     shell. Sets `PANE_DRIVER` env.
  3. **Per-strand coloured borders, NO text labels** — dropped
     `pane-border-status`/`pane-border-format` (the `--- 3: ansible ---` labels).
     Each terminal's border is now tinted from its strand's `colour` file
     (`fg=#<hex>`, active = `,bold`); driver uses aifabric-pane's colour. Peter:
     the prompt already says what each terminal is for → labels redundant. Signed
     off "Good as-is" (coloured dividers between panes; tmux doesn't draw the
     screen's OUTER edges — not wanted).

## Session 4 (2026-08-03) — colours, overview polish, mondrians

- **Palette overhaul (shared scheme, made vivid).** Finding: `aicli` (strand
  colours) and `ssp` (host colours) use the SAME golden-angle wheel
  (`h=n*137.508°`) — they were only diverging because ssp had hand-picked vivid
  NAMED colours while strands took the auto wheel clamped to `s=0.5 l=0.22`
  (muddy — everything read as ~3 grey-green families). Fixed the shared generator
  in BOTH `aifabric/bin/aicli` and `super/bin/ssp` to **`s=1.0 l=0.28`** (pure
  dark jewel-tones, hues actually separable). Regenerated all 31 strand `colour`
  files; `recolour --all` (the house tool — use it, don't hand-roll OSC) repaints
  live terminals from `.tty`. ubersitrep pinned to dark red `#7a0000` (a hand
  override, like ssp named colours). Old muddy colours backed up in `~/.trash`.
- **Overview uses the colours** (`poc/aifabric-tmux-overview.py`): each strand
  name in the roster is tinted with that strand's kinship hex (init_color when
  truecolour, else nearest ANSI), matching its terminal.
- **Overview auto-fits its height.** Curses can't resize its own pane, so it
  PUBLISHES needed rows to `aifabric-pane/.overview-rows`; a driver watcher
  (`pane_fit_overview_watch` in the helpers) resizes the pane to match — "just
  tall enough", grows/shrinks as the roster changes.
- **Terminals show their strand name (clobber-proof).** Set a per-pane `@strand`
  option (Claude can't rewrite it, unlike the title) + `pane-border-status top`
  with a border-format reading `@strand`. Survives `swap-pane` (labels travel
  with the pane). TWO identity stores now: `PANE_KEEPER_*` (deck env, for the
  driver to FIND) + `@strand` (per-pane, for the border to SHOW).
- **MONDRIANS — saved page layouts** (`poc/mondrian.sh`, `mondrians/*.mondrian`).
  A "mondrian" = one storable/loadable page arrangement (grid of strand
  rectangles; the Windows-8/Metro tile look is the same De Stijl lineage). File =
  tmux's exact `window_layout` string + a `slots` line (leaf→strand via @strand).
  `save/load/list/save-deck`; load spawns keepers, applies geometry, re-tags
  slots. Both named mondrians AND a whole-deck snapshot. Vocabulary now: an
  aifabric-pane → deck → page → terminal, and a **mondrian** = saved page layout.
- **9 terminals per page** is the target/cap (idea `20260803T182530Z-gkp5RE`);
  WindowShade "shade a terminal to a rail" + drag-dividers (mouse on) explored.

## Session 3 (2026-08-03) — pages (tabs), swaps, and the vocabulary above

- **Pages work (tmux windows = "pages").** Created/removed pages live from the
  CLI prefix-free (`new-window -d` = no focus steal, `kill-window`, `rename`).
  A page strip renders in the status bar. **GOTCHA:** the strip was invisible
  because `status` was **off on the attached client** (global said on) — `tmux
  set-option -t <deck> status on` fixed it (costs 1 row). Human flips pages with
  `Ctrl-b 0/1/n/p/w` (the one place you DO touch the prefix); driver drives
  pages prefix-free.
- **Cross-page terminal move proven:** swapped the live ubersitrep keeper out of
  page 0 into its own page via `join-pane` across windows; the empty page's
  shell took its slot. **Registry-by-name survived the move** (`PANE_KEEPER_*`
  still resolved) — identity holds across pages, not just within one.
- **Terminology nailed down** (see VOCABULARY section). Peter rejected "cockpit"
  and "single pane of glass"; ladder is an aifabric-pane → deck → page →
  terminal. HyperCard page-stack direction spooled.

## WENT LIVE 2026-08-03 (session 2) — real keepers, driver-driven, Peter 5/5

The whole design ran live and Peter loves it ("this is *so* cool", scored the
driver pane 5/5). Live `pane` tmux session with the driver (this session) in
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

- **CONSOLIDATED 3 STRANDS → 1 (2026-08-22, Peter: the pane/chat strands were
  "getting a bit confused").** `aifabric-pane-driver` merged back in and
  `strandchat` archived; this strand owns the surface end to end. Reasons, in
  descending order of how much they generalise:
  1. **A permanently-blocked fork is not a strand.** The driver's last status was
     *"Waiting on `aifabric-pane`'s spike"* — layout was never its call.
  2. **A standing routing override with no exceptions is a merge waiting to be
     done.** The roster carried a rule sending pane work to the driver *against*
     the word-ranking, every single time (see `ubersitrep/keepers.md`, Retired
     rules). The ranking was right: it was reading the blurbs and reporting one
     subject.
  3. **The pivot dissolved the boundary.** Once the driver is a web-app component
     rather than an agent in a tmux pane, it is part of this surface.
  4. **Chat was already recorded here as a wrong turn** — a per-strand transcript
     does not scale to watching many strands; the thumbnail strip is the answer.
     `forkchat` the *tool* survives, owned by [[aifabric]].
  The asymmetry survives as a rule about *components*: the design sets vocabulary
  and layout, the control layer curates only control jargon and defers on the
  rest. A component that redesigns its host is still the failure mode — it just
  does not need its own strand to prevent it. Write-up: `aifabric/method/panes.md`.

- **Driver is a tmux-CLI puppeteer that LIVES IN the driver pane** (decided
  2026-08-03, resolves the self-hosting question). It runs as a plain process in
  plane's bottom driver pane and arranges the sibling panes above it with plain
  `tmux split-window / send-keys / select-pane`. The real invariant is NOT "stay
  outside" — it's **never NEST tmux and never re-`attach`**: a process *in* a
  pane is not a tmux client, so there's ONE server, ONE prefix (yours), no
  nesting trap. You attach to plane once (the human client); you talk to the
  driver in the driver pane; you never touch Ctrl-b.
- **Adding a keeper needs NO special machinery** — the driver just does what a
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
  driver; using it on the driver agent risks the tmux-in-tmux nesting the design
  forbids. Correct topology (confirmed live): driver session launches PLAIN
  (outside tmux) and drives the SEPARATE `plane` tmux session from the CLI. Two
  distinct tmux things: `aifabric-pane` (the driver session) vs `plane` (the
  surface it arranges, which you attach to full-screen).
- ~~"self-hosting": does the driver agent live INSIDE plane?~~ DECIDED
  2026-08-03: YES. It runs in plane's driver pane and puppeteers via the
  tmux CLI. Safe because "in a pane" ≠ "attached client" — no nesting (see
  Decisions).
- Put REAL `aicli <keeper>` sessions in the panes. BUILT + VERIFIED 2026-08-03
  (mechanism only, no live Claude burned). New POC files in `poc/`:
  - `aifabric-pane-selfhosted.sh` — self-hosting bootstrap: builds the frame,
    launches the driver as `aicli aifabric-pane` INTO the driver pane, starts
    the strands row as one placeholder. Refuses to run inside tmux.
  - `pane-driver-helpers.sh` — the driver's hands: `pane_spawn_keeper`,
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
  ~~STILL UNTESTED: real `aicli` in a pane + driver calling helpers.~~ DONE
  live 2026-08-03 session 2 (see WENT LIVE above) — worked end to end.
- **Dynamic pane-shaping (the next prize):** make the driver COMPUTE an N×M
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
  - **DCP column — SPEC'D, not built** (Peter 2026-08-11: *"one thing I
    constantly need to know in the overview is how much a dcp is needed for a
    strand"*). Note **how much**, not whether — a magnitude to scan. He chose
    COMPACT COUNTS over a heat bar (precise and narrow beats glanceable here).
    Two measures:
    1. **Git debt**, exact and cheap, per strand DIRECTORY not per repo: dirty
       from `git status --porcelain`, unpushed from `git log @{u}..HEAD`.
       Render `2d 4u`.
    2. **Staleness proxy** — the part git cannot see, and the one that matters:
       dcp is *document*-commit-push, so a strand can be spotless in git while
       `STATE.md` is hours stale. Compare newest-file mtime against `STATE.md`
       mtime. A distinct MARK (`*`/`!`), not a number — a different KIND of debt.
    - **COST GOTCHA (heed it):** the roster ticks every 5s and the cleft 429
      incident is the precedent. Put DCP on its own SLOW cadence (30–60s) and
      cache between ticks. Do the whole repo in TWO git invocations parsed by
      leading path, not 2N — measured at **23 ms** for the entire strands repo,
      versus ~30 strand dirs × 2 calls.
    - **HONESTY NOTE for the header:** most strands live in the one strands repo,
      but strand *work* commits elsewhere (the driver's identity fix went to
      aifabric). So this measures *curation debt in the strands repo*, not all
      unpushed work. Say so, or optionally union with the strand's `dirs`.
    → idea `20260811T065453Z-i46gU4`.
- Build the driver agent (plain-language driver -> tmux CLI). Note: proven
  this session that a plain Claude session in the driver pane, sourcing
  `pane-driver-helpers.sh`, IS the driver — no separate agent needed yet.
- Launcher menu on empty startup + live suggestions in the overview.
- ~~Per-strand identity: coloured borders~~ DONE 2026-08-03 (session 5): each
  terminal's border tinted from its strand's `colour` file; text labels dropped
  (prompt says what it is). Colour source decided = the strand `colour` file.
  (Transparency per-pane tint / terminal-fork still parked.)
- ~~Where do the POC scripts finally live~~ DONE 2026-08-10: all 9 moved from
  `aifabric-pane/poc/` (strands repo) to **`~/aifabric/tmux-deck/`** (aifabric
  repo). Named `tmux-deck` not `poc` — "poc" says nothing about the subject, and
  tmux-driving is the distinctive thing; it also dates the prototype era honestly
  so the browser compositor gets a clean sibling dir later.
  - The strand keeps CURATION + DATA only: `mondrians/`, `colour`, `SCORE`,
    `.overview-rows`. Scripts still resolve those under `~/strands/aifabric-pane`
    by absolute path — data did NOT follow the code, deliberately.
  - Scripts find each other via `dirname "$0"`, so they travelled unchanged.
  - Still open: whether the curses overview `.py` graduates further into
    `aifabric/bin/` (i.e. onto `$PATH`). `pane-driver-helpers.sh` never should
    — it is sourced, not run.

## Session 7 (2026-08-10) — code moved to aifabric, conductor→driver scrub

- **Code left this strand.** All 9 deck scripts → `~/aifabric/tmux-deck/`
  (see the Pending entry above for the naming rationale and what stayed).
- **"conductor" is gone** (32 refs in scripts, 38 in these docs; 0 remain).
  `pane-conductor-helpers.sh` → `pane-driver-helpers.sh`. All 9 scripts pass
  `bash -n`/`py_compile`; the 11 `pane_*` helpers still export.
- **GOTCHA the rename exposed:** the old vocabulary used TWO words where we now
  have one — "conductor" = the agent, "driver" = the pane it sits in. So a blind
  swap produced "you talk to the driver in the driver pane" and "the driver's
  driver". Fixed by hand: say **"the driver"** for the agent and **"the driver
  pane"** (or "its pane") for the terminal. Worth keeping in mind — the ladder
  has no distinct word for the agent's seat.
  **Second-order bite:** prose *about* the rename gets mangled too. The bullet
  recording "Peter prefers driver over conductor" became "prefers driver;
  driver is retired", and the memory link `driver-not-conductor` became
  `driver-not-conductor`→`driver-not-driver` (a dead link). When scrubbing a
  word, exempt the sentences that DISCUSS the word — or re-read them after.
- Live deck restarted twice against the new paths (fit-watcher + curses
  overview); keepers left running throughout.
- **DESIGN SIDE DOCUMENTED** in `aifabric/method/panes.md` (aifabric `bcd12d6`),
  new section "The design strand and what its files carry" — the parallel to the
  driver's own subsection. Note `panes.md` was already in better shape than the
  driver's mail implied (vocabulary, pivot, split, findings all present and
  good), so the real gap was only the file-level parallel, not a fresh design
  write-up. The organising distinction, worth keeping: **the driver records how
  to be driven; this strand records what was decided and why the alternatives
  lost.** Includes a table of decisions a cold session must not re-litigate.
- **LADDER = ASPIRATION, NOT ENFORCEMENT** (Peter, 2026-08-10): *"sort of — I'll
  get it wrong from time to time but it's a good idea"*. Both halves are the
  policy. Keep the ladder in the WRITING (docs consistent, driver verbs
  unambiguous); understand "window"/"pane"/"term" alike when he speaks; never
  correct him. The driver's instinct — "a jargon nobody speaks is a spec" — was
  right; a jargon only the machine enforces is worse.
- **"STATUS.md" was a slip of the tongue**, not a divergence — it IS STATE.md.
  The driver had flagged it as possible evidence the ladder wasn't spoken; it
  isn't. (Real evidence remains: "window" for a term.)
- Replied to `aifabric-pane-driver` with both answers + the moved paths and the
  rename gotcha, so they don't hold stale references.

## Session 8 (2026-08-12) — zone-portable paths, ideas triaged

- **No absolute home paths in the shared repo** (aifabric `560bb13`, `d1a0ba2`).
  The other zone flagged `/home/peter` in the carried code: it could not fix the
  path without carrying ITS username back in the PR, so the file was
  *unmergeable*, not merely unportable. **A hardcoded `/home/<user>` is a
  username, and a username is content.** 7 leaks → 0.
  - Resolution order now: `$STRANDS_DIR` → `$HOME` → the script's own location
    for sibling tools in this repo (`tmux-deck/` walks up to `bin/`).
  - `bin/aicli` and `bin/sessions` had the *redundant* form —
    `"$HOME/super/bin/x"` then `"/home/peter/super/bin/x"`. The second is
    unreachable where it was written and dead on the other side: pure leak.
  - `mondrian.sh` was the one real `$STRANDS_DIR` bypass (fell straight back to
    `$HOME/strands`, so a zone setting `STRANDS_DIR` got strands from there but
    mondrians from `$HOME`). Everything else already consulted it first.
  - Rule written up in `aifabric/method/zones.md` → "Writing code that travels",
    with the pre-carry check `grep -rn '/home/' --include='*' . | grep -v .git`.
    **That file is still UNCOMMITTED** (Peter's draft) — the rule does not reach
    the other zone until it lands.
- **IDEAS.md triaged to empty** — 29 entries, all either promoted here or long
  since actioned. The three new ones (reflow ×2, DCP column) are promoted above.

## From aifabric-pane-driver (mail received 2026-08-10 — ACTED ON, see Session 7)

Scope split agreed with Peter: **aifabric-pane keeps the DESIGN** (layout,
compositor, thumbnail strip, terms, vocabulary, overview); **aifabric-pane-driver
owns the DRIVER COMPONENT only**.

- ~~**NAMING scrub outstanding.**~~ DONE (Session 7). Peter prefers "driver";
  "conductor" is retired like "cockpit" was. Scrubbed from `STATE.md`,
  `CLAUDE.md` and all 9 scripts; `pane-conductor-helpers.sh` →
  `pane-driver-helpers.sh`. See memory `driver-not-conductor`,
  `no-cockpit-naming`, `driver-agent-vs-driver-pane`.
- **Overview stays OURS and stays SEPARATE from the driver.** Decided: it must
  stay truthful while the driver is busy/asleep/dead, so it keeps its own
  no-agent refresh path. Designed so they CAN merge later — not merged.
- **They are BLOCKED on our browser-compositor spike** before rewriting the verb
  backend against the DOM. See "DIRECTION DECIDED 2026-08-10" above.
