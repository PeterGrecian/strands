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

## ✅ Faital Pro 4FE35 MOVES the camera — but stiction/detent (2026-07-31)

Swapped to a **Faital Pro 4FE35** (4" full-range, 8 Ω pro driver). Camera
resting **in contact** with the cone. Coil measured **5.6 V RMS ≈ 0.70 A /
~3.9 W** — full rail; darlington delivers full current. **The camera moves —
big range (up to ~30 px at 100% duty).** Force is no longer the blocker.

**But the response is a stiction/detent staircase, not proportional:**
deadband 0–19% → **snaps to 2.0 px at ~22%** → flat plateau 22–50% → jumps on
up (10/13/23/30 px). Control 0.008 px, drift 0.014 px — detector is excellent,
steps are real. Cause: camera only *in contact*, not bonded — cone travel below
threshold is lost to slack, then it breaks free into a new seated position.
**Unusable for dither** (needs continuous monotonic sub-px steps). Full data:
`~/Berrylands/pwmaudio/experiments/dither-deflection.md`.
(Watch **D882** dissipation — ~1 W free-air; keep 100% bursts short. Fine dither
is low-duty so it's fine.)

## 🎯 Repositioned camera → ~3 mm travel, ~230 px range — TOO MUCH (2026-07-31)

Repositioned the camera on the cone → coupling transmitted far better. New
sweep: deadband to 3% → 7 px @ 6% → ~30 px @ 9–25% → **154 px @ 37% → ~230–245
px (frame-edge saturation) @ 50–88%**. **Peter: the cone is moving ~3 mm.**
That's ~230 px image shift across a 640-wide frame. Then **the camera literally
fell off the cone** at the big excursions (relaxed start-vs-end = 232 px → never
returned). Also added output filtering by ear: **10 µF vital + 100 µF better**
(shunt C across the coil; coil supplies the L+R — fc ≈ 2.3 kHz / 680 Hz; kills
the audible 10 kHz PWM carrier).

**The problem has fully inverted: ~1000× too much travel, not too little.**
Design target is 0.1 px ≈ 0.77 µm; we get ~3 mm ≈ thousands of dither steps at
high duty. Force/range are a solved non-issue. The whole game is now (1) attach
the camera *securely* (it fell off — resting-in-contact won't survive the
travel), and (2) operate at the **bottom ~5% of duty**, where 1 count ≈ a
fraction of a px. Sub-px dither lives at ~1–4 duty counts.

## 🔬 PoC PROVEN — response is stick-slip; carrier was 8 kHz (2026-07-31)

Full chain validated: current → ~3 mm cone travel → ~230 px image shift,
resolved to ~0.008 px. But two findings define the next phase:

- **Stick-slip, not proportional.** Camera resting *in contact* → deadband then
  snap-to-detent. **Slow ramps do NOT cure it** (a friction contact has no
  elastic element to creep through) — tested: 0 up to ~duty 30, then jumps to an
  ~8 px plateau. At high duty the camera **flew off the cone**.
- **Carrier was 8 kHz, not 20 kHz** — pigpio `set_PWM_frequency` snaps to a
  ladder; 8 kHz is dead in the audible band. Fix: `pi.hardware_PWM(18,40000,
  duty*1e6)` (true HW PWM) → inaudible + coil L / shunt cap kill it harder. The
  10 µF shunt cap made it non-painful; +100 µF better.

## 🧪 Little-speaker coupling experiments — all NULL (2026-08-01)

Two attempts to get proportional sub-px motion out of the **little** speaker
(GPIO18 → darlington → little coil), both NULL; the Faital sat underneath only
as a passive rest platform (unpowered):

- **Magnet-tipped little speaker resting on the Faital.** Glued magnets to
  little speaker + camera for an "elastic" coupling. Fine sweep (0–48 counts),
  3 runs averaged: flat at 0.07–0.12 px (≈ the ~0.05 px floor), fit
  0.0034 px/count → 255 ≈ 0.9 px, non-monotonic. The one real effect was a
  **duty-24 slam** that on the first sweeps **latched** the resting stack 5–90 px
  (intra-group MAD 70) — the old detent failure.
- **Diaphragm cut free from the surround ("compliance surgery").** Scalpel-cut
  most of the diaphragm from the surround so the cone floats on the spider →
  higher compliance/throw. 3 runs averaged: **instability GONE** (every level
  stable at intra MAD ~2.4 incl. duty 24, clean return to zero) but **still no
  motion** — flat 0.08–0.24 px, fit 0.0002 px/count (255 ≈ 0.05 px = nothing).

**Verdict: the little speaker fundamentally lacks the force; compliance was
never its bottleneck.** Closes the little-speaker line (resting / magnet / cut
all NULL). This is consistent with — and does not change — the 07-31 finding
that the **Faital driven directly** already gives ~230 px range: the path with
both force and good coupling is the Faital, not the little speaker.

**Infra notes this session:** the Faital draws ~0.7 A / 3.9 W off the Pi 5V rail
and **browns out the SoC** (`Undervoltage` dmesg spam → 0-byte camera grabs; an
undervolt even wedged the IMX219 pipeline, `modprobe -r imx219` segfaulted and
dropped `/dev/v4l-subdev0`, **recovered only by reboot**). **Decision: Faital on
a separate 5V+ supply** (shared GND only) before the direct-Faital sweep.
Harness hardened to verify each frame == 307200 B and re-grab on short read
(`deskpi:/tmp/fine_sweep2.sh`) so brownouts can't silently hole the data.
Full data: `~/Berrylands/pwmaudio/experiments/dither-deflection.md`.

## → NEXT: the flexure stage (CRITICAL, hardest — do FIRST)

Peter's difficulty-ranked roadmap (2026-07-31):
1. **Flexure stage + camera-ribbon strain management — CRITICAL, do first.**
   Sub-µm *smooth* motion needs a **flexure, not bearings** (bearings have
   ~µm stiction = the stick-slip we measured). The **CSI ribbon is the hard
   part** — its stiffness/creep/hysteresis fights a soft flexure and
   reintroduces stick-slip through the cable. Strategy: exploit the ~1000×
   excess travel to run a **stiffer flexure that swamps the ribbon**, then gear
   down to sub-µm. Full design note (ribbon problem + 5 mitigations) now in
   `~/astro/design/speaker-dither-rig.md` (Bench PoC section).
2. Bond camera→cone rigidly — easy; unblocks a proportional re-test meanwhile.
3. **Real DAC** (MCP4725 → linear current driver) — easy quality upgrade, kills
   the carrier, far finer low-end resolution than 8-bit PWM. Phase 2; does NOT
   fix stick-slip. NB linear D882 dissipates more → heatsink/current-source.

Everything electronic + optical is proven (force, range, filtering, capture,
detector). The remaining work is mechanical. Harness ready (see below).

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
