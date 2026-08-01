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

**Doorbell arming via a SessionStart hook.** A waiter armed by aicli's launcher
shell is a child of the launcher, not claude, so it can't wake the session —
only a waiter claude spawns as a tracked background task does. So the ritual is
injected, not coded: `aifabric/bin/aicli-session-start-hook` fires on
`SessionStart`, and when `CLD_STRAND_DIR` is set emits
`hookSpecificOutput.additionalContext` telling the session to arm `ding --arm
<mailbox> 0` in the background and drain the spool. Self-gating (plain `claude`
launches emit nothing). Wired into `~/.claude/settings.json` and the durable
`dotfiles/.claude/settings-shared.json`.

## Pending / loose ends

- **`/exit` guard prompt.** The doorbell hook means every strand session has a
  background waiter, so `/exit` always shows "Exit anyway / background / stay".
  "Exit anyway" is correct (the waiter dies with the session; `ding_reap` sweeps
  orphans). If the prompt annoys, consider tearing the waiter down just before
  exit so `/exit` is clean — separate change, not done.

## Open questions (spooled to ideas/, triage next session)

- Deprecate `cld` in favour of `aicli` (portable name; `cld` doesn't work at work).
- Should aicli make continue/resume first-class? (It already works via arg
  passthrough; making it ergonomic pushes against the disposable-session model —
  a philosophy call.)

## Decisions

- **Window-id over title for raise/focus.** Titles are clobbered per-turn; the
  launch-time `$WINDOWID` is stable. Store it in `.wid`.
- **One shared, self-healing supervisor over a per-session loop.** A per-session
  loop dies with no recovery; a daemon that rebuilds desired state from each
  strand's on-disk `.wid`/`.title` survives individual session death. (General
  principle → aifabric-essay.)
