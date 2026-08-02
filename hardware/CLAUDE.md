# Strand: hardware

**Keeps the physical infrastructure sound — disks, CPUs, ethernet, power,
cooling across the fleet, maintained consciously not reactively.**

## Mission

The physical-infrastructure **and conscious-maintenance** strand: **disks,
CPUs, ethernet, power, cooling** across the fleet and workstations, **plus the
deliberate upkeep of the machines** — firmware, OS updates, desktop config, and
dotfiles drift. Concerned with the reliability and physical health of the
machines themselves — what they're built from, what keeps them running, and
keeping them consciously maintained (changelog-in-hand, not nag-popup) so
one-off fixes get codified (ansible/dotfiles/`cld -k`) and survive reinstalls.

*(Absorbed the former `pip-maintenance` strand, 2026-07-17 — its firmware/OS/
desktop-upkeep remit lives here now, not as a separate strand.)*

**In scope:** storage devices (spinning disks, SSDs, thumb drives — health,
mounts, power feeds, failure/replacement), CPU/thermal (throttling, cooling,
fans, heatsinks), networking hardware (NICs, USB ethernet adapters, cabling,
link speeds, powerline bridges), power delivery (rails, connectors, PSUs,
brown-outs), and the physical build/wiring of hosts. **Also conscious
maintenance**: firmware (fwupd/UEFI/rpi-eeprom, reviewed via `cld -k`, not
popups), OS updates, desktop config, and drift from dotfiles — codified into
ansible/dotfiles so fixes survive reinstalls and cover the whole fleet.

**Out of scope:** peripherals and actuators that are the deliverable of some
*other* project — SG90 servos (busclock/deskpi), Pi cameras (gardencam/astro),
sensors, etc. Those are hardware in the literal sense but belong to their own
strands. The line: this strand cares about the *host as a machine*, not the
*things a host drives*.

**Repos it spans:** mostly `ansible` (host_vars, network/mount config) and
`super` (this curation dir, memory). Physical fixes (soldering, re-seating,
disk swaps) happen at the bench and are recorded here, not committed anywhere.
Deliverables are: a trustworthy fleet, and curated state in `STATE.md` +
cross-repo memory (`super/memory/project_*_hardware.md`,
`project_lan_*`, `project_*_network.md`).

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
