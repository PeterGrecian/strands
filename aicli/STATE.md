# aicli — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

**Many-terminal window management (2026-07-30).** With ~9 strand terminals open
at once, two things now work reliably on pip (X11/XFCE):

- **Title = strand name, and it holds.** aicli sets the X11 window title via
  `xdotool set_window --name "$WINDOWID"` (survives `MiscTitleMode=TITLE_HIDE`,
  which only blocks the escape-sequence route). But an *active* backend rewrites
  `_NET_WM_NAME` to its per-turn summary every turn, so a one-shot write reverts.
  Held by a **title supervisor** (see 2026-08-01 below), which superseded the
  original per-session `reassert_title_loop`.

- **Raise via the window manager.** `raise_strand` previously had only a
  Windows/PowerShell path, so `aicli -r <strand>` always failed on Linux. Added
  `raise_x11`: activates by the **exact window id** recorded at launch
  (`wmctrl -i -a 0x<hex>`, fallback `xdotool windowactivate`), then title-match
  as last resort. Window-id is primary because titles get clobbered per-turn.
  The id is written to `<strand>/.wid` at launch alongside `.tty`/`.title`.
  `aicli <live-strand>` with no backend args already defaulted to raise; it now
  has a working Linux path, so both bare `aicli <strand>` and `aicli -r <strand>`
  raise the terminal.

Sessions already open when the fix landed were backfilled: window ids discovered
live via `/proc/<pid>/environ` `WINDOWID` (all terminals share one xfce4-terminal
server pid, so wmctrl's pid can't map them), `.wid` written, and a per-window
detached titlekeeper started (self-exits when the window closes).

**Title reset on exit (2026-07-31).** The reassert loop kept the strand name on
the window for the session's life, but the EXIT handler only killed the loop and
restored *colours* — it never cleared the *title*, so a closed session left the
strand name on the window forever (we set `_NET_WM_NAME` directly, so nothing
else reverts it). Fixed: `restore_terminal_title_on_exit` writes xfce4-terminal's
default `Terminal - user@host: PWD` back via the same `xdotool set_window --name`
path, called from `restore_terminal_colours_on_exit` right after the loop is
killed (so it fires on every exit path and can't be clobbered by a live tick).
`TTY_PWD` is captured before aicli cd's into the strand, so the restored title
reflects the launching shell's directory.

**Doorbell arming moved to a SessionStart hook (2026-07-31).** Strands kept
forgetting the `ding --arm` ritual, so mail piled up unread. It *can't* be done
in aicli's code: a waiter armed by the launcher shell is a child of the launcher,
not claude, so its completion re-invokes nothing — only a waiter CLAUDE spawns as
a tracked background task wakes the session. So the fix injects the instruction
instead. `aifabric/bin/aicli-session-start-hook` is a `SessionStart` hook that,
when `CLD_STRAND_DIR` is set (i.e. a strand session), emits
`hookSpecificOutput.additionalContext` telling the session to arm `ding --arm
<mailbox> 0` as a background task and drain the spool. Self-gating: plain `claude`
launches emit nothing. Wired into `~/.claude/settings.json` **and** the durable
`dotfiles/.claude/settings-shared.json` (so `claude-settings-merge` keeps it
across machines / the live file's runtime rewrites). Takes effect next launch.

**Title supervisor — self-healing, replaces the per-session loop (2026-08-01).**
The original `reassert_title_loop` was a background child of *one* aicli shell:
if it died (a system wedge — e.g. the autofs/puppy-mount hang that froze `stat`
and `xdotool`-adjacent work earlier that day — or a stray signal), nothing
restarted it and that window's title drifted to the backend's per-turn summary
**permanently**. Observed live: several long-running sessions (ubersitrep,
cleft-plus, astro-canon, astro-v3s, …) had lost their loops and their titles;
only freshly-launched sessions still held. The current code wasn't itself
broken (a fresh launch keeps its loop) — the flaw was that a dead loop never
recovers.

Replaced with a **single self-healing supervisor daemon** decoupled from any one
session:
- `run_title_supervisor` — every 3s walks `strand-ps --live-strands` and
  re-stamps each strand's window (`.wid` → `.title`) via `xdotool`. One daemon
  serves *all* live strands, so any individual session (or its aicli parent)
  dying can't stop titles being maintained for the rest.
- `ensure_title_supervisor` — called on every launch (replaced the old
  `reassert_title_loop` call site). Spawns a `setsid`-detached singleton guarded
  by `flock -n` on `~/.config/aicli/title-supervisor.lock`; a duplicate spawn's
  flock fails and it exits instantly (no pileup). Also touches a `.wanted` flag.
- `--title-supervisor` — hidden re-entry arg the detached daemon runs as (not in
  `--help`).
- **Retirement:** daemon self-exits after 2 empty sweeps (~6s of zero live
  strands) so it never lingers past the last session.
- **Two race fixes from a `/code-review high` pass:** (1) *stale/recycled `.wid`*
  — a strand kept live by a no-`$WINDOWID` session (tmux/ssh/forkterm; the `.wid`
  write is gated on `$WINDOWID`) leaves an old `.wid` whose X11 id may have
  recycled to another app; the daemon now guards with `xprop WM_CLASS ~ terminal`
  before stamping, so it never titles a foreign window. (2) *retire-vs-launch* —
  a launch landing inside the ~6s retirement countdown would find the lock held,
  not spawn, and be left with no supervisor once the daemon exited; the `.wanted`
  flag (touched by every `ensure`, consumed each sweep) cancels retirement so a
  session starting during the window is never orphaned.

Verified end-to-end: singleton under concurrent launches, self-heal (clobbered
title restored within one sweep), WM_CLASS guard skips a non-terminal window,
`.wanted` flag cancels retirement, real throwaway-strand launch bootstraps then
cleanly retires. All live strand windows re-titled; supervisor left running.
(`gardencam` was skipped — launched by a pre-title aicli, no `.wid`; self-fixes
on next launch.)

## Pending / loose ends

- The old ad-hoc backfill titlekeepers are obsolete — the title supervisor
  (2026-08-01) now maintains every live strand's title from one daemon, which is
  exactly the `--titlekeep-all` behaviour that was mooted here. Nothing to do.
- aicli working tree also carried a pre-existing unrelated edit (`-a|--archive`
  → long-form-only `--archive`, freeing `-a` to match `strands -a`). Committed
  together with the window-management work this session.
- The doorbell hook means every strand session now reliably has a background
  waiter running, so `/exit` always shows the "Exit anyway / background / stay"
  guard. For a strand, **Exit anyway** is correct — the waiter is meant to die
  with the session and aicli's post-backend `ding_reap` sweeps any orphan. If the
  prompt gets annoying, consider having aicli tear the waiter down just before
  exit so `/exit` is clean (separate change, not done).

## Decisions

- **Window-id over title for raise/focus.** Titles are clobbered by the backend
  every turn; the launch-time `$WINDOWID` is stable. Store it in `.wid`.
- **Persistent reasserter, not one-shot.** Chosen over trying to disable the
  backend's per-turn title writes (no clean switch found; reasserter works
  regardless of backend).
- **One shared supervisor, not a per-session loop (2026-08-01).** A per-session
  loop dies with no recovery; a single daemon that reads each strand's `.wid`/
  `.title` from disk and covers the whole live set survives individual session
  death — the deeper fix over restarting a fragile per-session helper.
