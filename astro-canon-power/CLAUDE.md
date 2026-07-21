# Strand: astro-canon-power

Recurring workstream: a **Pico W power-cycle rig** to remotely reset the
**Canon EOS 2000D** astro camera when it hangs. The camera is tethered
over USB to **muppet** via gphoto2 (see the sibling **astro-canon**
strand, which owns it as an instrument); this strand owns only the
*power*: cutting the camera's DC supply, holding it off long enough for
the rails to drain, and restoring it — an unattended-recovery reset.

**Scope seam (decided):** astro owns its own recovery — the reset stays
*direct*, close to the camera, minimal moving parts. It does **not** go
through a general home-automation control plane (no MQTT / Home Assistant
dependency in the overnight capture recovery path). The general
home-automation strand owns ambient switch/sensor nodes; this strand owns
this one astro-specific reset. Sibling: **astro-canon** (camera as
instrument, gphoto2 tether quirks).

**Mechanism (decided):** Pico W (Peter has one, unused) + P-channel
MOSFET high-side switching the camera's DC rail. Just on/off — a timed
power-cycle pulse, no PWM/sensing. First real use of the Pico W; a
low-stakes node to learn MicroPython on.

**Watch items** (from design discussion, verify before wiring):
- Confirm the camera's actual supply voltage (dummy-battery / DR-E10-style
  coupler is ~7–8 V, not 5 V) — sets the MOSFET and gate-drive design.
- P-FET high-side on a >3.3 V rail: the Pico W's 3.3 V GPIO can't pull the
  gate to the load voltage, so it won't fully turn *off*. Standard fix is
  an N-channel/NPN level-shifter driving the P-FET gate.
- Cameras have large caps — the off-hold must be long enough (several
  seconds) for rails to actually drain, or the reset won't take.

Deliverables: MicroPython firmware on the Pico W + wiring notes live here
/ in astro; the control trigger integrates with astro's capture tooling
on muppet, not with home-automation.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to (usually astro) —
   this strand dir holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
