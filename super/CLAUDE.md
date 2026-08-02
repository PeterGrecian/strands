# Strand: super

**Keeps the super meta-repo — the daily-kitchen tooling, conventions and global
context that drive everything else.**

The `~/super` meta-repo: house tools (`secrets`, `resolve-host`, `alert`,
`trash`, …), the global context (`GLOBAL.md`), and cross-repo conventions. The
*content* of strands lives in the `strands` repo; super owns the *tooling and
conventions* around them. (Note: aicli/strand tooling moved to `aifabric` —
super no longer symlinks into it.)

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
