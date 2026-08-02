# Strand: home-automation

**Keeps the home's Matter/Zigbee automation running — headless commissioning
via the matter-server WS API on homepi, no phone app needed.**

Home Assistant + Matter/Zigbee device control, run headlessly. HA and
`python-matter-server` run as docker containers on **homepi**; devices are
commissioned via the matter-server WebSocket API (`ws://homepi.local:5580/ws`),
not a phone app or browser UI. Spans the homepi HA stack and the fleet it
controls.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
