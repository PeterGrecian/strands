# Strand: cloud-init-init

**Keeps the bootable-Pi-image tooling working — `configure-sd-card.sh` writes
and self-provisions a Pi OS card so a new Pi comes up ready.**

Bootable-Pi-image creation via the `Berrylands/cloud-init-init` repo:
`configure-sd-card.sh` writes a Raspberry Pi OS image to an SD card and
provisions it (WiFi, SSH keys, AWS creds, cloud-init user-data) so the Pi
self-provisions on first boot. Spans `Berrylands/cloud-init-init` (the tooling)
and the fleet hosts it images.

## Session ritual

1. Import spooled ideas with `idea --import`, then read
   `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
