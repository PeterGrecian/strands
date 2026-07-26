# astro-speaker-dither — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

**Driver working (2026-07-25).** The PWM-as-DAC speaker drive now delivers full
force: the beta-limited single 2N3904 (~200 mA, ~1/3 force) was replaced with a
**darlington (2N3904 → B882)**, clearing the Stage-2 current cap. "The speaker
drive works." See `~/Berrylands/pwmaudio/wiring.md` Stage 2b and
`experiments/dither-deflection.md`. This clears the last electrical blocker; the
remaining questions are mechanical (deflection / camera image-shift).

The design of record is still the parent strand `astro-subpixel` (STATE.md
"Dither sources") and `astro/design/speaker-dither-rig.md`. The Pi-specific
PWM-DAC code is in `~/Berrylands/pwmaudio` (shared with the deskpi speaker-tone
work; see the `pwmaudio` memory). The driver/circuit build is slated to migrate
into the [[electronics]] strand + `~/electronics` repo (created 2026-07-23).

## Pending / loose ends

- **Mechanical: see actual travel now that force is adequate.** Optical-lever
  by eye showed nothing at ~200 mA (2026-07-09); retry with the darlington's
  full force, then the real detector — mount the rig to tilt a camera and look
  for sub-pixel image shift.
- Calibrate µm/mA **loaded** (mount stiffness changes the response) once travel
  is confirmed.
- Decide first target camera/mode: astrocam between-frame stepping is the
  simplest (no smear, no phase sync); Polaris photometry on a v3s/pole cam
  is the real prize (needs the dither because it never drifts off its pixels).
- Confirm what part of the pwmaudio electronics is reusable vs. what needs a
  higher-current driver for the actuator. **The circuit side now has a home:**
  the [[electronics]] strand + `~/electronics` repo (created 2026-07-23) owns
  the driver design/build; this strand owns the astro *why* and the µm/mA
  calibration. The pwmaudio driver work is slated to migrate into
  `~/electronics` (see electronics STATE).

## Decisions

- Speaker dither spun out of `astro-subpixel` as its own (placeholder)
  strand 2026-07-13, symmetric with `astro-breathing`, so all three dither
  mechanisms have a home. Activates on bench build. (2026-07-13)
- Driver force problem solved with a **darlington (2N3904 → B882)** rather than
  the originally-sketched BC337 / logic-level MOSFET. Strand is now past
  placeholder — driver works, mechanical validation is next. (2026-07-25)
