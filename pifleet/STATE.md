# pifleet — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- Mission (2026-07-20): pifleet owns **fleet membership + dashboard/liveness**
  for all always-on hosts, Pi or not. The dashboard is `Berrylands/pi-fleet`
  (the "source of truth" board). Changing hosts to *make* the fleet healthy is
  the sibling **ansible** strand's job — see the seam below.

## Pending / loose ends

- **vole → first-class fleet member.** Decided vole belongs on the board (x86,
  always-on, 192.168.0.9). Blocked on the reporter degrading cleanly on a
  non-Pi host (it assumes SD card + `pi-` prefix). Implementation lives in the
  ansible strand's IDEAS.
- **Reporter cadence 1→5 min + immediate-on-boot** — decided with Peter
  (whole-fleet). Implementation + Lambda-threshold lockstep in the ansible
  strand.
- IP discrepancy resolved: vole is **.9**, not .17 (stale note corrected).

## Decisions

- **Seam with ansible strand** (2026-07-20): pifleet decides *what the fleet
  should look like* (membership, health); the **ansible** strand *implements &
  rolls it out* onto hosts. pifleet owns that vole is *up*; aifabric owns what
  vole is *for*.
- **pi-fleet → fleet rename**: acknowledged as correct-in-principle (mixed-arch
  fleet) but parked as ride-along tech-debt, not a standalone chore. Tracked in
  the ansible strand.
