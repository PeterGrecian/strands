# astro-canon-power — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- Nothing built yet. Strand created 2026-07-21 from a home-automation
  power-control discussion. Hardware on hand: one unused Pico W, P-channel
  MOSFETs.

## Pending / loose ends

- **Confirm camera supply voltage** — check the EOS 2000D DC coupler /
  dummy battery rail (likely ~7–8 V). Drives MOSFET + gate-drive choice.
- **Design the switch** — P-FET high-side on the DC rail, with an
  N-ch/NPN level-shifter so the 3.3 V Pico W GPIO can fully turn the P-FET
  off. Pick parts from the MOSFETs on hand.
- **Write MicroPython** — timed power-cycle: off → hold (several s for caps
  to drain) → on. First Pico W project.
- **Wire the trigger to astro** — how muppet's capture tooling asks the
  Pico W for a reset (simple HTTP endpoint on the Pico W is the likely
  shape; stays inside astro's trust boundary, no broker).

## Decisions

- **Astro keeps direct control of this reset — no home-automation control
  plane.** The overnight recovery path must not depend on MQTT / Home
  Assistant. General home-automation switch/sensor nodes are a separate
  concern (home-automation strand); this rig is astro-specific.
- **Pico W + P-channel MOSFET, on/off only.** No PWM/sensing needed for a
  power-cycle. Chosen partly to learn MicroPython on a low-stakes node.
- **Sibling seam:** astro-canon owns the camera as an instrument (gphoto2
  tether on muppet); astro-canon-power owns only its power/reset.
