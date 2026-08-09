# aifabric-pane — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What this is

An **aifabric-pane**: one agent-driven surface (overview + keeper terminals +
driver) replacing scattered strand terminal-emulator windows. This strand is the
conductor. Split out of [[aifabric]] on 2026-08-03; full design in
`aifabric/ideas/20260803T144642Z-ZAMrik`.

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

## Session 6b (2026-08-09) — standard layout, live rearranging, two bugs found

Drove the live deck hands-on with Peter (attached-conductor). Outcomes:

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

Attached-conductor session (this session drove the live deck from the driver
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
  to-the-conductor. Predictable, instant, free, self-documenting; LLM reserved for
  judgement, and even the conductor CALLS these verbs rather than driving tmux
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
  2. **Driver pane now runs the conductor** — `driver` slot launches
     `aicli --new aifabric-pane` (the strand that IS the conductor), not a bare
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
  PUBLISHES needed rows to `aifabric-pane/.overview-rows`; a conductor watcher
  (`pane_fit_overview_watch` in the helpers) resizes the pane to match — "just
  tall enough", grows/shrinks as the roster changes.
- **Terminals show their strand name (clobber-proof).** Set a per-pane `@strand`
  option (Claude can't rewrite it, unlike the title) + `pane-border-status top`
  with a border-format reading `@strand`. Survives `swap-pane` (labels travel
  with the pane). TWO identity stores now: `PANE_KEEPER_*` (deck env, for the
  conductor to FIND) + `@strand` (per-pane, for the border to SHOW).
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
  `Ctrl-b 0/1/n/p/w` (the one place you DO touch the prefix); conductor drives
  pages prefix-free.
- **Cross-page terminal move proven:** swapped the live ubersitrep keeper out of
  page 0 into its own page via `join-pane` across windows; the empty page's
  shell took its slot. **Registry-by-name survived the move** (`PANE_KEEPER_*`
  still resolved) — identity holds across pages, not just within one.
- **Terminology nailed down** (see VOCABULARY section). Peter rejected "cockpit"
  and "single pane of glass"; ladder is an aifabric-pane → deck → page →
  terminal. HyperCard page-stack direction spooled.

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
- ~~Per-strand identity: coloured borders~~ DONE 2026-08-03 (session 5): each
  terminal's border tinted from its strand's `colour` file; text labels dropped
  (prompt says what it is). Colour source decided = the strand `colour` file.
  (Transparency per-pane tint / terminal-fork still parked.)
- Where do the POC scripts finally live — promote from `aifabric-pane/poc/` into
  `~/aifabric/bin/` once past POC. The curses overview `.py` is the graduation
  candidate.
