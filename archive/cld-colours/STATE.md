# cld-colours — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- `super/bin/cld` (→ `aifabric/bin/aicli`) sets the terminal background
  per strand via OSC 11/10 (like ssp): colour applied before claude
  launches, restored to `#1a1a1a` after. Works in plain and `--tmux`
  modes (set on the outer terminal before tmux starts); `--remote`
  untouched.
- **Restore is now guaranteed on every exit path** (2026-07-26). It used
  to leak the strand colour: (a) the reassert loop — which re-paints the
  colour at 0.2/1/3/8s to survive the backend retitling — kept firing for
  up to 8s *after* a short session ended, clobbering the restore; (b) the
  restore was a single straight-line statement, skipped on signal exits
  and unreachable past `exec copilot`. Fixes: reassert job is tracked
  (`REASSERT_PID`) and killed before restore; an EXIT trap plus
  INT/TERM/HUP handlers guarantee restore; copilot runs as a child (not
  exec) so the trap fires; `restore_terminal_colours_on_exit` is guarded
  against double-emit and writes to the real tty. Verified via pty
  harness (clean exit + real Ctrl-C both end on `1a1a1a`, once).
- Colours are stored as rrggbb hex in `<strand>/colour` — in git, so
  portable across machines, hand-editable to override. Auto-assigned on
  first launch: n × 137.508° (golden angle) on the hue wheel at S=0.5
  L=0.22, where n = number of strands already coloured. Foreground picked
  by luminance (light text on dark, black on light).
- Bare `cld -s` listing shows a truecolor swatch next to each coloured
  strand.
- `super/bin/cld-statusline` (wired into `~/.claude/settings.json`
  statusLine): every Claude Code session shows its launch dir's basename
  at the bottom of the TUI — on the strand's colour swatch when a
  `colour` file exists — plus model and cwd-if-different. Zero-token
  replacement for `!pwd` when juggling many concurrent strands. cld also
  sets the terminal window title to `cld <strand>` (best-effort; Claude
  Code may retitle during the session).
- New-machine propagation is mechanised (no hand step): durable settings
  keys (statusLine, tui, defaultMode, autoUpdatesChannel) live in
  `dotfiles/.claude/settings-shared.json`;
  `dotfiles/bin/claude-settings-merge` jq-deep-merges them into the live
  `~/.claude/settings.json` (shared wins, runtime/machine keys kept —
  live file can't be a stow symlink because Claude Code rewrites it, the
  xfce4-panel.xml failure mode). Wired into `runme.bash`, `dot`, and the
  ansible `claude-code` role (stat + command, changed_when on "updated").
  Documented in dotfiles/CLAUDE.md. Verified: idempotent, merges into
  partial and missing files.
- This strand claimed n=0: `#541c1c` (dark red). Verified end-to-end
  with a stubbed `claude` binary; first 20 generated hues are well
  separated.

## Pending / loose ends

- Other strands get colours lazily as they're next launched — nothing to do.
- Found in passing: `stow -t $HOME .` currently fails wholesale on pip
  (pre-existing conflicts: xfce4-panel.xml, mimeapps.list, a couple of
  .desktop files, and the absolute memory symlink under
  `.claude/projects/`). Since `dot` runs stow with `set -e`, it dies
  before reaching the settings merge on such machines. Dotfiles hygiene
  issue, not this strand's — but it gates the `dot` entry point.
- ~~ssp quirk: puppy colour `7` (off-palette)~~ — fixed. The live
  `~/.config/ssp` already had puppy on `purple`; the bogus `7` was only
  in ssp's embedded default-config template (would regress on a fresh
  machine). Now `53` (purple) there too, matching the live config.
- Possible future: converge ssp onto the same arbitrary-hex mechanism
  instead of its fixed 14-colour palette.

## Decisions

- Colours are keyed **per strand** (not per repo/dir).
- Generated, not curated: golden-angle hue sequence gives an effectively
  unlimited palette ("I would use more colours if I could"), dark
  backgrounds only.
- Durable assignment lives in the strand dir in git, not machine-local
  config — same strand, same colour, every machine.
