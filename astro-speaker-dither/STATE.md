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

## ⚠️ deskpi DOWN — recover first (2026-07-29)

## ✅ deskpi RECOVERED — camera fault is HARDWARE (2026-07-30)

deskpi is booting again and the IMX219 problem is now pinned to hardware.

**Recovered** by reflashing the SD card with fresh **Raspberry Pi OS Lite
armhf (Trixie, 2026-04-21)** via `cloud-init-init` (recovery-plan Option 4).
Written from **starcam**, image staged on **puppy NFS**, card fixed up on
**pip**. deskpi boots cleanly on the ARMv6-valid kernel, now on the **eth0
dongle** (`deskpi.local` / .71). The rpi-update boot disaster is fully behind
us. GPIO18 amp wiring untouched.

**Camera: confirmed hardware fault.** On Trixie (libcamera, not the Stretch
`start_x` path), added `dtoverlay=imx219` to `/boot/firmware/config.txt` and
rebooted. The imx219 driver now probes the correct bus/address and the sensor
**does not ACK**:
`imx219 10-0010: failed to read chip id 219 / -EREMOTEIO (-121)` on i2c bus 10,
addr 0x10. This is the same "no I²C ACK" symptom as the Stretch investigation —
now **reproduced across a full OS/firmware/kernel reflash + correct overlay**.
Software is proven correct → the sensor isn't responding. Cause is **ribbon
(seat/crack/oxidation) or a dead IMX219 module**.

**Next (hands-on):** reseat both ribbon ends, then swap-test — a known-good
camera on deskpi, and this IMX219 on another Pi — to condemn module vs. Pi CSI
connector. Full detail + dmesg in
**`~/Berrylands/pwmaudio/experiments/deskpi-camera-recovery.md`**.

Also fixed: `peter`/`pi` added to the `video` group (fresh card left them out;
`vcgencmd`/libcamera were throwing `/dev/vcio` / dmaHeap permission errors).

**Lesson (kept): never `rpi-update` an ARMv6 Pi (A+/B+/Zero).** apt/OS Raspbian
stays current for these boards; `rpi-update` bleeding-edge firmware does not
track ARMv6.

## Pending / loose ends

- **deskpi recovered; camera blocked on hardware (see above).** The image-shift
  test needs a working camera on deskpi. Software is proven correct
  (`dtoverlay=imx219`, driver probes i2c-10/0x10) — the IMX219 gives no I²C ACK
  (`-EREMOTEIO`) even after a full reflash, so it's a ribbon or dead-module
  fault. **Next: reseat + swap-test the camera hardware.** (`gpu_mem` currently
  16; bump to 128 only once a camera actually ACKs.)
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
