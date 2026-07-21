# astro-speaker-dither — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

**Placeholder only (2026-07-13).** No bench build yet. The design of record
is in the parent strand `astro-subpixel` (STATE.md "Dither sources") and
`astro/design/speaker-dither-rig.md`. The Pi-specific PWM-DAC code is in
`~/Berrylands/pwmaudio` (shared with the deskpi speaker-tone work;
see the `pwmaudio` memory).

## Pending / loose ends

- Bench build when the current drivers arrive; calibrate µm/mA **loaded**
  (mount stiffness changes the response).
- Decide first target camera/mode: astrocam between-frame stepping is the
  simplest (no smear, no phase sync); Polaris photometry on a v3s/pole cam
  is the real prize (needs the dither because it never drifts off its pixels).
- Confirm what part of the pwmaudio electronics is reusable vs. what needs a
  higher-current driver for the actuator.

## Decisions

- Speaker dither spun out of `astro-subpixel` as its own (placeholder)
  strand 2026-07-13, symmetric with `astro-breathing`, so all three dither
  mechanisms have a home. Activates on bench build. (2026-07-13)
