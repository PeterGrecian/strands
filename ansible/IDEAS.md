# ansible — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->

## pi-fleet reporter cadence: 1 min → 5 min, immediate first report
Decided with Peter 2026-07-20 (whole-fleet, not per-host). Change the reporter
timer so hosts POST every 5 min instead of every minute, and report
immediately on boot rather than after 1 min.
- `Berrylands/pi-fleet/systemd/pi-fleet-status.timer` AND the ansible template
  `~/ansible/roles/pi-fleet/templates/pi-fleet-status.service.j2` — wait, the
  *timer* is the committed one; confirm whether ansible deploys the committed
  timer file or has its own. Set `OnUnitActiveSec=5min`, `OnBootSec=0`.
- **Must move in lockstep:** widen the Lambda offline threshold in
  `Berrylands/pi-fleet/lambda-handler.py` to tolerate 5-min gaps (≈2–3×), or
  every host flaps offline between reports. Read the current threshold first.
- Roll out fleet-wide via ansible, in waves, capture undisturbed. Verify hosts
  still show green on the board and a rebooted host appears immediately.
- 80% cut in Lambda/DynamoDB writes + journal spam; cost is coarser offline
  detection (~10–15 min). Fine for a status board; tiebreaker-drop *alerting*
  belongs in aifabric/OpenSearch land, not here.

## Add vole to the fleet as a first-class member
vole (Acer C720, x86, 192.168.0.9) is always-on and ansible-managed but is not
a Pi — it has no SD card and a non-`pi-` hostname. The reporter assumes both
(`HOSTNAME.replace('pi-', '')`, `/sys/block/mmcblk0/device/cid`). Decide with
pifleet how vole appears on the board, then make the reporter degrade cleanly
on a non-Pi host so vole reports sane CPU/mem/disk/uptime without SD/serial
fields. (This is where the pi-→fleet renaming debt naturally surfaces — see
below; do it *here* if the reporter needs surgery anyway.)

## TECH DEBT (not now): pi-fleet → fleet rename
The fleet is mixed-arch; the `pi-` naming is a lie load-bearing in code
(`replace('pi-', '')`, `mmcblk0` SD-card assumptions), the ansible role name,
systemd unit names, env vars, and the Lambda API path. Renaming the *system*
(not just the repo) is a real migration with live-capture blast radius for zero
new capability. **Don't do it standalone.** Let it ride along if/when the
reporter needs surgery anyway (e.g. the vole-degrade work above). Note only.

## General fleet-maintenance catch-up
Standing item: sweep `~/ansible` for config drift and half-applied roles across
the fleet. Seed with anything found. (e.g. vim-default-editor pending on
starcam/deskpi/xoverpi; astrocam sudo broken — see super memory.)
