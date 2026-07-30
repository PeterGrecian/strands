# aicli — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

**Many-terminal window management (2026-07-30).** With ~9 strand terminals open
at once, two things now work reliably on pip (X11/XFCE):

- **Title = strand name, and it holds.** aicli sets the X11 window title via
  `xdotool set_window --name "$WINDOWID"` (survives `MiscTitleMode=TITLE_HIDE`,
  which only blocks the escape-sequence route). But an *active* backend rewrites
  `_NET_WM_NAME` to its per-turn summary every turn, so a one-shot write reverts.
  Fixed with `reassert_title_loop` — a background loop that re-applies the strand
  name every 3s for the session's lifetime, killed cleanly on exit by the same
  EXIT handler that restores colours (`TITLE_REASSERT_PID`).

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

## Pending / loose ends

- The hand-started backfill titlekeepers for the currently-open sessions are
  ad-hoc (not durable across reboot, no clean stop). Fine as a bridge — every
  *relaunched* session self-manages via aicli's built-in loop. No action needed
  unless we want an `aicli --titlekeep-all` housekeeping command.
- aicli working tree also carried a pre-existing unrelated edit (`-a|--archive`
  → long-form-only `--archive`, freeing `-a` to match `strands -a`). Committed
  together with the window-management work this session.

## Decisions

- **Window-id over title for raise/focus.** Titles are clobbered by the backend
  every turn; the launch-time `$WINDOWID` is stable. Store it in `.wid`.
- **Persistent reasserter, not one-shot.** Chosen over trying to disable the
  backend's per-turn title writes (no clean switch found; reasserter works
  regardless of backend).
