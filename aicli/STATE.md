# aicli — state

*Curated summary of where this strand is. Rewritten (not appended) each session
to describe current behaviour; git holds the history.*

## What exists

**Window titles = strand name, held by a shared supervisor.** aicli sets the X11
window title via `xdotool set_window --name "$WINDOWID"` (survives
`MiscTitleMode=TITLE_HIDE`, which only blocks the escape-sequence route). An
active backend rewrites `_NET_WM_NAME` to its per-turn summary every turn, so a
one-shot write reverts. A single **title supervisor** re-asserts it:

- `run_title_supervisor` — a `setsid`-detached daemon; every 3s it walks
  `strand-ps --live-strands` and re-stamps each strand's window from its recorded
  `.wid` → `.title`. One daemon serves all live strands.
- `ensure_title_supervisor` — called on every launch; spawns the daemon as a
  singleton guarded by `flock -n` on `~/.config/aicli/title-supervisor.lock` (a
  duplicate spawn's flock fails and exits — no pileup), and touches a `.wanted`
  flag.
- `--title-supervisor` — hidden re-entry arg the daemon runs as (not in `--help`).
- Retires after 2 empty sweeps (no live strands). The `.wanted` flag, consumed
  each sweep, cancels retirement when a launch races the countdown, so a session
  starting then is never left without a supervisor.
- Guards a stale `.wid` (a no-`$WINDOWID` session — tmux/ssh/forkterm — can leave
  an old `.wid` whose X11 id was recycled) with `xprop WM_CLASS ~ terminal`
  before stamping, so it never titles a foreign window.

(Supersedes the original per-session `reassert_title_loop`, which died with no
recovery when its one shell was disrupted — see aifabric-essay for that lesson.)

**Raise via the window manager.** `raise_strand` → `raise_x11` activates by the
exact window id recorded at launch (`wmctrl -i -a 0x<hex>`, fallback `xdotool
windowactivate`), then title-match as last resort. Window-id is primary because
titles get clobbered per-turn; it's written to `<strand>/.wid` at launch beside
`.tty`/`.title`. Both bare `aicli <strand>` (raises a live strand) and `aicli -r
<strand>` work on Linux/XFCE.

**First-class continue (`-C` / `--continue`).** Resumes the launch dir's most
recent Claude session (passes `--continue` to the backend). Short flag is
capitalised because `-c` is already `--create`. Claude-only — guarded against
copilot (`die`), against `--create` (a new strand has no session), and against
`--remote` (which spins up its own session). A *live* strand launched with `-C`
opens a fresh continuing terminal instead of raising the existing window
(`$CONTINUE -eq 0` added to the raise condition). Continue is keyed to the launch
dir like everything else, so it resumes *that strand's* own history.

**Backend switching is exposed, not just settable.** `-d`/`--default` already
persisted the backend; now it's discoverable: the strand-listing header shows the
current default under the `aicli` name (`strands:  (backend: claude — aicli -d to
change)`), suppressed under `cld` (which always forces claude, so annotating there
would mislead). Bare `aicli -d` prints the current default + the switch command
instead of erroring. `--claude` / `--copilot` are per-launch shorthands for
`--backend <name>`.

**Strand KIND: keeper vs builder, declared by the blurb.** A strand is a *keeper*
(bounded concern — owns/serves one subject, steady state) if the first word of its
`blurb` summary line is `Keeps`; otherwise a *builder* (active development, a
trajectory) — the default, incl. no blurb file. `strand_kind()` reads it; aicli
exports `CLD_STRAND_KIND` (export path + launch path), and the SessionStart hook
injects a kind-specific line so the session opens *knowing which it is* (keeper →
maintain + resist scope-creep; builder → drive + curate STATE.md). Reuses blurb
line 1 rather than adding a `kind` file — the summary sentence is the declaration.
Concept documented in `strands/README.md`. Today no strand ships a blurb, so all
are builders until declared.

**Strand summaries: list line vs full mission (`--about`).** The listing summary
(`strand_blurb`) is line 1 of a `<strand>/blurb` file if present (verbatim), else
derived from the first prose paragraph of `<strand>/CLAUDE.md` (markup stripped,
12-word cap). No strand currently ships a `blurb` file — all summaries come from
CLAUDE.md, recomputed each listing (edit the mission's first sentence to change
one). `aicli --about <strand>` (long-form only, `-a` stays reserved) prints the
full mission: the same summary line, then the rest of the prose. This gives the
`blurb` file a two-part format — line 1 = list summary, blank line, then detail
paragraph(s) shown only by `--about` — so a one-liner can be followed by a
paragraph without bloating the one-row-per-strand listing.

**Listing order is alphabetical by default; `-t` for last-use.** Bare `aicli`
lists strands sorted by name (explicit `sort -k1` so it holds regardless of
locale). `-t`/`--time` restores the old ordering — last use (newest first), name
as the stable tiebreak. Composes with `-l`/`-L`. Alphabetical is the default
because a fixed position makes a strand findable by eye/muscle memory; last-use
order shuffles it around. The filters (`-l`, `-L`, `-x`) are unaffected.

**Doorbell arming via a SessionStart hook.** A waiter armed by aicli's launcher
shell is a child of the launcher, not claude, so it can't wake the session —
only a waiter claude spawns as a tracked background task does. So the ritual is
injected, not coded: `aifabric/bin/aicli-session-start-hook` fires on
`SessionStart`, and when `CLD_STRAND_DIR` is set emits
`hookSpecificOutput.additionalContext` telling the session to arm `ding --arm
<mailbox> 0` in the background and drain the spool. Self-gating (plain `claude`
launches emit nothing). Wired into `~/.claude/settings.json` and the durable
`dotfiles/.claude/settings-shared.json`.

**Doorbell nag: a Stop hook re-arms the discipline, not the waiter.** The doorbell
was unmanned most of the time because a waiter rings once and the model forgot to
re-arm. Key constraint: a hook CANNOT arm a wake-capable waiter — only a waiter
CLAUDE spawns as a tracked background task wakes the session; anything a hook
spawns is untracked and wakes nothing. So the re-arm stays a model action, and
the fix is to NAG reliably: `aicli-stop-hook` fires every turn end, self-gates on
`CLD_STRAND_DIR`, and — only when `ding --check <mailbox>` finds no live waiter —
injects a re-arm instruction via `hookSpecificOutput.additionalContext` (honored
on Stop; the session continues and acts on it). When a waiter is already up it
emits nothing (must stay silent, else it would block the session from ever
stopping). New `ding --check` leg: exit 0 if a live-owner `--arm` waiter watches
that mailbox, else 1. Wired into `settings.json` + durable
`dotfiles/.claude/settings-shared.json`. (Live pickup may need `/hooks` or a
restart once — the settings watcher only loads Stop on reload.)

**Strands root resolution tolerates the standalone-clone layout.** The chain is
`$STRANDS_DIR` → `~/.config/aicli/config` → `~/.config/idea/config` →
`bin/../strands` → **`~/strands`** → derived from `$PWD`. The `~/strands` step was
added 2026-08-18: `bin/../strands` only resolves when aifabric sits *beside*
strands inside a parent (the `~/super/aifabric` layout), so a host that clones
each repo straight into `~` matched nothing and aicli died with "can't locate
strands" — first seen on zog. The same chain is duplicated in
`aicli-completion.bash` (`_aicli__strands_dir`), which broke independently and in
a quieter way: completion silently offered nothing for `aicli`, `cld -s` and
`idea`, since `_idea_complete` shares the helper. Both are fixed; the two copies
now cross-reference each other in comments, but a single resolver (or the
completion calling aicli for the answer) would end the drift.

## Pending / loose ends

- **`/exit` guard prompt.** The doorbell hook means every strand session has a
  background waiter, so `/exit` always shows "Exit anyway / background / stay".
  "Exit anyway" is correct (the waiter dies with the session; `ding_reap` sweeps
  orphans). If the prompt annoys, consider tearing the waiter down just before
  exit so `/exit` is clean — separate change, not done.

## Open questions (spooled to ideas/, triage next session)

- Deprecate `cld` in favour of `aicli` (portable name; `cld` doesn't work at work).

## Decisions

- **Window-id over title for raise/focus.** Titles are clobbered per-turn; the
  launch-time `$WINDOWID` is stable. Store it in `.wid`.
- **One shared, self-healing supervisor over a per-session loop.** A per-session
  loop dies with no recovery; a daemon that rebuilds desired state from each
  strand's on-disk `.wid`/`.title` survives individual session death. (General
  principle → aifabric-essay.)
- **Continue/resume IS worth making first-class** (resolved the old open
  question). It already worked via arg passthrough, but `-c` collides with
  `--create` and the passthrough was undiscoverable; a real `-C` flag with proper
  guards is ergonomic without undermining disposable sessions — resume is opt-in,
  the default is still a fresh session.
- **Capitalised `-C` for continue** because lowercase `-c` is `--create`. `-C`/`-c`
  are confusable but the long forms (`--continue`/`--create`) disambiguate, and
  keeping `continue` on the `c` letter is more memorable than an unrelated letter.
- **Expose the backend default in the listing, don't just make it settable.** A
  persisted default the user can't see is a footgun; showing it in the header (and
  via bare `-d`) makes switching obvious. Suppressed under `cld` because `cld`
  ignores the saved default.
