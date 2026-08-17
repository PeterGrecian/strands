# aifabric — IDEAS inbox

*Collection point for aifabric ideas, from any active strand or forkterm.
Triaged at session start: **promote by default** to STATE.md pending (dropping
is the deliberate, considered act — see the strands meta-strand).*

> **Use the `idea` tool to add an idea:** `idea "<your idea>"` (or pipe it in)
> drops a clobber-safe one-file-per-idea note into `ideas/`, so concurrent
> writers can't collide — no need to touch this file. `idea --hints` for
> details. Hand-appending below the line still works as a fallback: add a `—
> <strand>, <date>` tag and **append only**, never rewrite existing entries.

<!-- new ideas below this line — append, don't rewrite (prefer the `idea` tool → ideas/) -->

- (inbox drained 2026-07-17: rename→aifabric actioned; air-gap model → STATE #9;
  strand-system/forkterm ideas → strands/strands/IDEAS.md. Awaiting new ideas.)

the beauty of forkchat is it works over the internet 
if there are 2 arguments to idea the 1st is the strand the 2nd is the text


cld should be in aifabric and should be symlinked to aicli


if idea has n arguments and the first is an existing strand, use that as the strand


when I /exit does the waiter close cleanly


still not getting terminal titles and we desperately need terminal raising.  once things get complicated its impossible to find anything.  and forkterm didn't, so a bug


dcp is vital to the aifabric because it updates STATE.  it's a bit obscure though and ambiguous.  maybe it also needs refining


we could go through sessions to get a metric of how sucessful strands are at their tasks and how often they fail to do their prime job.  particularly applies to keepers.  we could refine STATE with this and git history analysis.  we could tune dcp so it is reluctant to change state of successfull keepers, and does so only if the session was particularly sucessful


we probably need a strand for improving tools and one for more general ideas.  another idea - autocompletion for idea on the strand


some sessions just seem to get off on the wrong foot and the agent seems dim.  I should score those, in fact I should regularly give marks out of 5 for the performance of the agent, so maybe I'll get some idea of what works


Practical build for the keeper-vs-development strand kinds (theory lives in the
`strands` strand; aifabric owns the practical stranding — Peter 2026-08-02:
"aifabric is practical stranding, strands is strand theory"). Build once the
theory settles:

- .template: a keeper vs dev scaffold variant. Keeper scaffold carries a
  METRICS block in STATE (the defined health measures) + a "modify STATE
  sparingly" note; dev scaffold carries the moving-frontier STATE shape (dcp
  worklog: moved/next/blocked).
- A declared-kind field on a strand (frontmatter or a marker file) so tooling
  can branch: the daily-sitrep scheduled agent reads keeper METRICS not prose;
  the review ledger applies cadence to keepers and least-recently-reviewed
  rotation to dev strands.
- The scheduled sitrep agent itself (reads all keepers' metrics blocks, posts
  an overnight report) — a concrete aifabric tool once keepers carry metrics.
  DECIDED 2026-08-02: it's a **GENERAL tool in aifabric/bin, NO new repo** —
  "read these keepers' metrics → post a report", sibling of strand-mailbox/ding/
  sessions. The astro daily sitrep is its first CONFIG/instance (the 4 astro
  keepers), not a bespoke astro script. The schedule (cron/routine) + output
  destination are config, not code — the routine points at the aifabric tool.
  Blurbs source: ubersitrep/docs/blurbs.md is the canonical one-line map (the
  sitrep could reuse the same keeper-STATE-reading path).

Driven by the astro re-org (ubersitrep 2026-08-02): polecam/eclipticam/canon/
storage = keepers needing metrics blocks; astro-science = development.


.template needs a `blurb` stub (practical build → aifabric, per "aifabric is
practical stranding, strands is strand theory"). Context: as of 2026-08-02 every
existing strand ships a <strand>/blurb file (line 1 = plain-text one-liner shown
VERBATIM in the aicli listing — no 12-word cap, no markup strip; blank line; then
detail paragraph(s) for `aicli --about`). But `strands new` / `aicli -c` scaffold
from .template, which has NO blurb file — so new strands fall back to the
CLAUDE.md-paragraph path (12-word cap, cuts mid-clause). Fix:

- Add `.template/blurb` with a placeholder line 1 + guidance, e.g.:
    <one-line summary — plain text, verb-first for keepers "Keeps …", object-first
    for development strands (drop the verb); the first ~40 chars are what the list
    shows>

    <a short detail paragraph, shown by `aicli --about <strand>`>
- So a freshly scaffolded strand shows a real (if placeholder) blurb and the
  author edits ONE obvious file, not the CLAUDE.md opener.
- Couples with the keeper-vs-dev scaffold variant idea (same spool): the blurb
  stub's line-1 hint differs by kind (Keeps… vs object-first).
- Watch the .template-via-symlink corruption gotcha (memory
  [[template-corruption-via-symlink]]): edit the real template with
  cp -RT "$(readlink -f …)", don't write through the symlink.

Blurb-writing rules live in ubersitrep/docs/blurbs_howto.md (the theory/philosophy
belongs to the `strands` strand; this stub is the practical embodiment).


idea should auto complete strnd names.  what happens if the first word is not a strand name?


aifabric-tmux: drive a tmux session FROM an agent to organise strand terminals
on ONE plane. Instead of N separate xfce4-terminal windows (each a strand, hard
to see/raise — see backend-clobbers-net-wm-name, forkterm raise bug), lay them
out as tmux panes in a single window the agent arranges: split, title, focus,
resize under agent control. Relates to the sovereignty / "one plane" framing.
Pairs with xtg6x6 (titles/raising) and forkterm.

--- design thinking (Peter + session, 2026-08-03) ---

WHY TMUX IS NORMALLY CONFUSING, and why this design dodges it:
tmux confusion = (1) the hidden prefix key (Ctrl-b then a key — a mode you must
remember you're in); (2) the overloaded session/window/pane hierarchy; (3) YOU
have to hand-drive the layout with cryptic chords. This idea inverts #3: the
AGENT drives tmux, you never press Ctrl-b. tmux stops being an interface you
operate and becomes a RENDERING SURFACE the agent arranges. The confusing part
(being your own window manager) disappears.

MENTAL MODEL (one sentence): one OS window; inside it the agent lays out a pane
per strand — splitting, titling, focusing, resizing on command — so all strands
live on one plane you look at, instead of a scatter of terminal windows you hunt
for in the taskbar.

CONTROL MODEL — DECIDED: OUTSIDE CONDUCTOR (chosen over self-arranging strands
and over a plain no-agent CLI). A dedicated "conductor" agent sits OUTSIDE tmux
and drives it via the plain `tmux` CLI (split-window, select-pane, resize-pane,
select-layout, kill-pane, send-keys). Strand sessions run INSIDE panes, each a
normal `aicli` session UNAWARE it's in tmux. You talk to the conductor in plain
language; it rearranges the plane. Rejected: self-arranging strands (every
strand needs tmux-awareness; panes fight over the layout) and a no-agent
friendly CLI (still you driving, just nicer verbs).

Conductor vocabulary is a handful of tmux primitives:
  "start ansible"                 -> split-window 'aicli ansible' + re-tile
  "focus astro-storage"           -> select-pane -t <id>
  "make it bigger"                -> resize-pane
  "ansible + housekeeping side by side" -> select-layout / swap-pane
  "close housekeeping"            -> kill-pane -t <id>
  "show everything"               -> select-layout tiled
Payoff: ONE window in the taskbar, not eight — which by itself dissolves the
raise/title mess (nothing to raise BETWEEN; it's all one plane).

THE PLANE HAS A FIXED THREE-ZONE FRAME (Peter, 2026-08-03) — not arbitrary
panes, but a persistent frame with strands filling the middle:

  +-------------------------------------------------+
  |  OVERVIEW  — live-refreshed readout (top)       |
  |  strand list · unread-mail flags · LIVE/idle ·  |
  |  suggestions                                    |
  +----------------------+--------------------------+
  |  ansible             |  housekeeping            |  strand panes
  +----------------------+--------------------------+  (middle,
  |  astro-storage (focused, larger)               |   conductor-arranged)
  +-------------------------------------------------+
  |  > you talk to the conductor here (driver)      |  bottom (your input)
  +-------------------------------------------------+

Three zones, three decisions LOCKED:
- DRIVER (bottom) = where YOU type to the conductor. The one interactive control
  you touch: "focus astro" / "start ansible" / "close housekeeping". Everything
  above is arranged FOR you, not by you.
- OVERVIEW (top) = a LIVE-REFRESHED readout — a script that repaints on a timer
  (strand list, unread-mail count from the unified mailbox, LIVE/idle,
  suggestions like "drain housekeeping (2 msgs)" / "astro-storage idle 3h —
  close?"). The pi-fleet dashboard, but for strands. Read-only, always current,
  INDEPENDENT of whether the conductor is mid-turn.
- STARTUP with no strands = a LAUNCHER MENU. Empty plane greets you with the
  pickable strand list + mail-aware suggestions ("resume housekeeping? it has
  mail"). Pick a number or tell the conductor. A home screen for the plane.

KEY STRUCTURAL CONSEQUENCE — separation of concerns: overview ("what's true") is
just a status script and does NOT depend on the conductor being awake, so you
always see current state even while it's thinking. The conductor owns only the
MIDDLE (strand panes) and reads the BOTTOM (your input). Clean split: what's true
(overview) / what I ask (driver) / the work (strand panes).

OVERVIEW = SUMMARY, NOT A LIST (Peter, 2026-08-03). Listing all ~37 strands is
noise. The overview headlines "N strand(s) live of TOTAL [names]", surfaces ONLY
strands WITH unread mail (actionable, from the unified mailbox), and shows a
compact cleft usage line (5h used% + rate + runs-out warning). Suggestions area
below. POC of this rendered well.

PANES HOST KEEPERS — they're idempotent (Peter, 2026-08-03). A KEEPER is a
bounded steady-state concern (maintain + answer; blurb starts "Keeps", the same
signal aicli uses for CLD_STRAND_KIND). Keepers are safe to spin up / tear down /
restart on the plane — no fragile in-progress trajectory. So keepers are the
plane's natural residents; BUILDERS (with a trajectory you'd disrupt) stay in
their own window. ~17 keepers exist. This makes the plane a "keeper cockpit":
the idempotent maintenance strands laid out together, builders elsewhere.

POC STATUS (2026-08-03): built and LOOKED AT — Peter likes the layout. NOW ITS
OWN STRAND: aifabric-pane (scaffolded 2026-08-03). Scripts moved to
aifabric-pane/poc/ (aifabric-tmux-poc.sh builds the 3-zone pane from outside via
the tmux CLI, never attaches; aifabric-tmux-overview.sh = summary readout). Dummy
strand panes (no real aicli burned). Verdict on single-pane-vs-scatter: YES,
proceed. Further work continues in the aifabric-pane strand, not here.

SNAGS TO DESIGN AROUND (carry these into the build):
1. WAKE MODEL CHANGES SHAPE (and improves) — SETTLED by the overview. Today a
   strand "raises its window" for attention (badly — the forkterm bug).
   Single-plane has no window to raise; instead a strand with mail simply LIGHTS
   UP in the top overview readout (unread flag), and the conductor can suggest
   "bring housekeeping forward." Attention becomes a GLANCE UP, not an
   interruption — no window-raising at all. Ties to the just-unified ding +
   strand-mailbox model (commit c17a0b4): the overview reads the same mailbox.
2. PER-STRAND COLOUR moves from background to border. Each strand terminal now
   has its own background colour (the `colour` file). Panes in one window share
   one terminal palette — no per-pane background. tmux CAN colour pane borders +
   the per-pane status line, so identity moves to coloured border + titled
   status. Different feel, not worse.
   - Transparency does NOT rescue per-pane colour: transparency is a property of
     the whole terminal window, so every pane sees the same wallpaper behind it —
     can't tint ansible red and housekeeping blue that way. tmux `pane-style
     bg=...` (3.5 supports it) DOES give a per-pane background, but it's opaque
     and paints OVER any transparency — so it's borders+transparency OR opaque
     per-pane bg, not both. For the plane, lean on coloured BORDERS + status line
     (robust across re-tiling) and treat transparency as whole-window aesthetic.
   - FUTURE OPTION (parked, not for POC): fork the terminal code (patch
     xfce4-terminal / a VTE-based terminal) to support genuine per-pane
     background images or tints. Big yak-shave; only if borders+status prove
     insufficient after the POC.
3. NESTING = prefix-key hell. Conductor-in-tmux, or ssh into a plane, gives
   tmux-in-tmux. RULE: the conductor drives tmux from OUTSIDE via the CLI and is
   NEVER itself a tmux client (send-keys/split-window, never `attach`). Keeps you
   out of the prefix key entirely.
4. EXISTING `--tmux` FLAG. aicli ALREADY has `--tmux` ("wrap the session in a
   tmux viewport"). Before building, read what it does — this may EXTEND that
   seam, or be a different single-session idea we supersede. First triage action.

DIRECTION: POC FIRST (agreed 2026-08-03). Don't design-to-completion or fork the
terminal — build a proof of concept and LOOK at it. Single-plane-vs-scattered is
a taste question, not a technical one; settle it before investing.

POC scope (minimal, throwaway ok):
  - One tmux window, the three-zone frame: overview (top), 2 strand panes
    (middle), a driver pane (bottom).
  - Drop two REAL strand sessions into the middle panes via the tmux CLI from
    outside (split-window 'aicli <strand>'); conductor NEVER attaches.
  - Coloured pane borders + titles for identity (no terminal fork).
  - Overview = a dumb repainting script: list strands + unread-mail flag (read
    the unified mailbox), refresh on a timer. No suggestions yet.
  - Driver pane: just a prompt you type into (wire it to a real conductor agent
    later; for the POC even manual tmux commands typed there prove the layout).
Then judge: does one plane beat scattered windows? If yes, build the conductor
agent + launcher menu + suggestions. If no, stop cheap.
First triage action regardless: read aicli's existing `--tmux` (snag 4).


THE FIELD ASSUMES THE SESSION IS THE ATOM; THE FABRIC SAYS IT'S THE STRAND. (Method insight, 2026-08-03, from the aifabric-pane session.)

Two exhibits of the same blind spot in how people think about AI-assisted work — both treat a single chat/session as the fundamental unit:

1. /remote-control (Claude Code's new native slash command; aicli run_remote already wraps the CLI flag). It bounces ONE conversation to your phone / the web. The unit it assumes is 'a chat'. From a fabric's point of view that's bouncing ONE THREAD off the loom. True 'fabric remote' would put the OVERVIEW on the phone (N live, who has mail, cleft) and let you tap into any strand — the overview terminal built today IS already that remote surface, and tmux-attach-the-whole-deck is a truer primitive than single-session remote.

2. 'Vibe coding', as people mean it = LINEAR sessions: one human <-> one agent, one conversation, one screen, realtime, turn by turn. Attention is the bottleneck; you vibe ONE thing at a time; the session IS the work.

The fabric refutes both. Unit of work = the STRAND (a standing cross-repo workstream), not the session. Sessions are DISPOSABLE; strand state persists in git. The human is OVER the loop, not IN it: glance at the overview, drop into a strand when it lights up (mail/flags), bounce out. Keepers are idempotent so strands MAINTAIN THEMSELVES and ASK FOR YOU rather than needing continuous presence. Every aifabric-pane design choice (overview = summary not list; idempotent keepers; identity survives title-clobber; mondrians; deck>page>terminal) exists to make linear presence UNNECESSARY.

Why it matters: vibe coding scales to one person's realtime attention and no further. A fabric scales PAST it — parallel strands, self-maintaining, attention spent on WHICH strand not on babysitting one. The atom is wrong: it's not the chat, it's the strand; the surface isn't the session, it's the fabric. Belongs in the method doc. See [[aifabric-pane]] for the concrete surface.


# aifabric ideas/ spool

**One file per idea.** This is the clobber-safe inbox for aifabric ideas from any
active strand or forkterm — the per-strand `ideas/` spool (see the `idea` tool /
`ideas-keeper` design in `super/strands/strands/IDEAS.md`).

## How to drop an idea (until the `idea` tool exists)

Write a **new file** — never edit someone else's, never append to a shared file.
Concurrency-safety is by construction: unique filenames can't collide.

Filename: `YYYYMMDDThhmm-<strand>-<pid>.md` (timestamp + your strand + pid), e.g.
`20260717T0912-astro-canon-4412.md`. Use UTC for the timestamp (repo convention).

Suggested body:

```markdown
---
strand: <your-strand>
date: 2026-07-17
host: <host>
---

<the idea, in your own words>
```

Triaged at aifabric session start: promote-by-default into `STATE.md` pending,
then the file is swept to `~/.trash` (never `rm`). `README.md` is not an idea and
is never swept.

