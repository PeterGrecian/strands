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

## ✅ deskpi RECOVERED + camera WORKING; image-shift test RUN (2026-07-30)

deskpi recovered (reflashed **Raspberry Pi OS Lite armhf Trixie** via
`cloud-init-init`); now on the **eth0 dongle** (`deskpi.local` / **.71** on the
`.0.x` LAN — note the pi-fleet `.4.154` entry is stale). GPIO18 amp wiring
untouched. First full end-to-end image-shift test ran this session.

**Camera: NOT a hardware fault — it works.** The 2026-07-30-morning "hardware
fault / no I²C ACK" call was **superseded the same day**: after a ribbon reseat
the IMX219 ACKs and the `imx219 → unicam` media pipeline is ENABLED. We captured
real, detailed images. The `-EREMOTEIO` was an **intermittent ribbon seating**
issue, not a dead module.

**Capture gotcha (recorded):** `rpicam-apps`/libcamera/picamera2 are **barred on
ARMv6** (`ERROR: rpicam-apps currently only supports the Raspberry Pi
platforms`). Capture must go via **plain V4L2** on `/dev/video0`: set sensor
mode on `/dev/v4l-subdev0` (`SRGGB8/640x480`), match the video node (`RGGB`),
grab raw Bayer, debayer with ffmpeg. Max exposure/gain for the dark bench:
`v4l2-ctl -d /dev/v4l-subdev0 --set-ctrl exposure=1759,analogue_gain=232`.

## ⚡ Actuator too feeble — the real blocker now (2026-07-30)

Tone test passed (440/880 Hz audible → GPIO18→darlington→coil chain confirmed).
But the **image-shift test found no measurable camera motion** across three
drives (static 0/100%, 2 Hz sine, 3 Hz slam) — all at the ~0.05 px cross-corr
floor. A first 20 Hz-slam "18% motion-blur, 16σ" result **turned out to be a
scene-drift artifact** (comparing frames minutes apart); a controlled
interleaved static→slam→static re-run showed no difference. **Lesson: always
interleave driven/undriven captures.**

**Root cause = actuator force, not the linkage.** Confirmed by eye at the bench:
"the displacement is tiny — it's a truly feeble speaker." Two limiters: (1) a
*held DC level* makes almost no force (speakers respond to *changing* current →
dither wants sharp commanded *steps*); (2) even fast edges barely move this
small driver. The B882 darlington is NOT the bottleneck — it sources full
current (~0.6 A / ~2.9 W into 8 Ω would be near the rail); the transducer's
BL·Xmax is. Full writeup: `~/Berrylands/pwmaudio/experiments/dither-deflection.md`.

## → NEXT: swap in the 15" speaker (fist-sized magnet)

Peter has a **15" driver** to try. BL ≈ 10–20 N/A (vs ~0.5–1 for the small one)
→ **~15–30× the force at the same current**, plus multi-mm Xmax and a big flat
cone the camera can mount *directly on* — bypassing the µm→tilt coupling loss
that killed the small-speaker test. The problem inverts: expect **too much**
travel, so start at **low duty (~5–10%)** and dial down for px-scale dither.
Then it's a **µm/mA calibration**, not a detection problem — the regime the
strand actually wants. Harness ready to reuse (see below).

## Pending / loose ends

- **Wire the 15" driver + camera; re-run the image-shift test.** Reusable
  harness on deskpi: `/tmp/shift_test.sh <duty> <tag> <n>` (drive GPIO18 + grab
  N raws) and `/tmp/seq.py <cycles>` (tone→DC→rest pattern). Pull raws to a
  numpy host, cross-correlate (FFT phase-corr) + interleaved sharpness. A
  **calibration sweep** (step duty 2/5/10/20%, interleaved capture each, build
  px-shift-vs-current) is spec'd and ready to build.
- **Resonance sweep** — even the small driver gives max excursion at mechanical
  resonance; drive the dither there, not at DC. (Also the cheapest test of the
  force-vs-DC theory.)
- Calibrate µm/mA **loaded** (mount stiffness changes the response) once travel
  is confirmed — now realistic with the 15".
- Repos on deskpi: super/dotfiles/ansible + freshly cloned **Berrylands**
  (pwmaudio tools) + **astro**. `pigpiod` enabled (survives reboot).
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
- Image-shift test ran on deskpi (2026-07-30): camera + capture + detector all
  work, but the small speaker is **too feeble** to move the camera measurably.
  Decision: **stop tuning the small driver; switch to a 15" driver** (huge BL,
  multi-mm Xmax, camera mountable on-cone) and shift the goal from *detection*
  to *µm/mA calibration*. The B882 darlington stays — the transducer, not the
  driver, was the limit. (2026-07-30)
