# Strand: muppet-status

**Keeps muppet (and puppy) healthy as hosts — network/dongle config, NFS
mounts, hardware quirks kept working.**

Host-level health of muppet and its sibling puppy: network profiles and dongle
swaps (interface-agnostic NM config), static IPs, NFS write recovery, hardware
notes. Detail lives in memory (`project_puppy_network.md`,
`project_muppet_hardware.md`); this strand curates the host state.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
