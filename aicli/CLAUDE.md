# Strand: aicli

The `aicli` launcher itself — the backend-agnostic strand session tool
(`~/aifabric/bin/aicli`, invoked as `aicli` or `cld`). This strand is where
aicli's own behaviour gets developed and hardened: strand resolution, terminal
colour/title, window-manager integration, raise/focus, backend launch, and the
post-session housekeeping/doorbell wiring.

- **Primary repo:** `PeterGrecian/aifabric` (`~/aifabric`), `bin/aicli`.
- **Related:** `PeterGrecian/strands` (`~/strands`) for `.gitignore` of aicli's
  per-launch droppings (`.title`, `.tty`, `.wid`); `dotfiles` for the
  xfce4-terminal `MiscTitleMode=TITLE_HIDE` setting aicli relies on.

## Session ritual

1. Import spooled ideas with `idea --import`, then read
   `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.

**Load-bearing daily tool:** test aicli changes with a real launch/raise before
committing.
