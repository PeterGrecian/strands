# electronics — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->

## Network power-switch for muppet's sdc tepid archive (2026-07-26, from hardware strand)

muppet's sdc disk is becoming a **tepid archive**: normally powered OFF,
spun up on demand over the network to read/refresh, then powered down again
(saves spindle hours/heat, isolates it from power events). Needs a
**network-controlled power switch** for the disk's power feed.

- **Hoped design (Peter):** a **high-side switch** driven by a **Pi Pico W**
  (WiFi → GPIO → switch). "We'll see" — not committed.
- **The seam with the hardware strand:** the switch must only be an actuator.
  muppet's side owns the *safe* sequence (sync → unmount → `hdparm -Y`
  spindown) and calls the Pico W's power-off **only after** the disk is
  unmounted; on power-on it waits for spin-up before mounting. Yanking power
  from a mounted XFS/ext4 volume corrupts it — the exact 2026-07-15 muppet
  fault. So define a small control API/GPIO contract the muppet script drives.
- Context: this frees muppet's shared-USB power sprawl (the fault source);
  the ATX PSU currently feeding the disk array goes to **rackinabox**.
- Hardware-strand side (target state + safe-power sequence) is recorded in
  `strands/hardware/STATE.md` under the 6 TB migration runbook.
