# astro-v3s — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Mission

Replace the v2 (imx219) camera on **astrocam** with a newly-bought **Pi Camera
v3 (standard)** — imx708 sensor — and get it focused and capturing for sky use.

## Where we are (2026-07-29 — camera swapped & commissioned to capture)

**The v3 is physically installed and imaging.** Capture engine commissioned and
tested end-to-end; **not yet wired to autostart** (see hazard below).

- **Camera detected**: imx708 at `/base/soc/i2c0mux/i2c@1/imx708@1a`, native
  4608×2592 RGGB. Ribbon orientation on the Pi 4 CSI: silver contacts face the
  HDMI side, blue stiffener faces USB/Ethernet (this was correct all along).
- **Config fix that made it detect**: `astrocam/camera.json` aside, the boot
  config `/boot/firmware/config.txt` had `camera_auto_detect=0` +
  `dtoverlay=imx219` pinned at lines 54–55, overriding the earlier
  `camera_auto_detect=1`. Both commented out → auto-detect picks up imx708.
  Backup: `config.txt.bak-v2-20260729`.
- **Cover**: SG90 servo on GPIO18, `~/astro/astrocam/cover.py {open|closed}`
  (min=open, mid=closed). Cycled fine repeatedly. gpiozero software-PWM warning
  is harmless (pigpiod inactive). Currently **open**.

## Focus — PROBED, lp = 1.0

- Swept LensPosition against distant daytime trees (rotation 180 needed — mount
  is inverted). Sharpness (JPEG size proxy + eye) peaked ~1.0–1.4; **Peter
  probed and chose lp=1.0**. Focus breathing minimal across the sweep.
- **Very different from eclipticam-v3w's 3.15** — because that's the WIDE lens.
  Do not reuse 3.15 for the standard v3.
- Night daemon **dithers 0.5→1.5 step 0.1** around 1.0 so the sharpest true
  focus can be picked from real stars (per-frame LENSPOS/LENSPREP headers).

## Capture engine — DONE via eclipticam reuse

Decided (2026-07-29): **reuse eclipticam's shared `astro.capture.streaming`
engine** rather than patch astrocam's old imx219 loop. astrocam already had the
engine (`astro/capture/streaming.py`, byte-identical to eclipticam's) +
`astro/config.py CameraConfig`.

Written, deployed, committed (`PeterGrecian/astro` @ 51a83c3):
- **`astrocam/camera.json`** — sensor→imx708, bayer→RGGB, resolution→4608×2592,
  new `capture` block (night_exposure_us 59_900_000, night_gain 1.0,
  lens_position 1.0, focus_dither 0.5/1.5/0.1). Stale calibration fields
  (pole_prior_xy, plate_scale, pedestal) flagged STALE in their notes.
  Backup: `camera.json.bak-imx219-20260729`.
- **`astrocam/astrocam_v3_night_daemon.py`** — thin wrapper mirroring
  `v3w_night_daemon.py`; reads camera.json capture block, env overrides.
- **Tested end-to-end**: 12 FITS written, shape 2592×4608 uint16, CAMERA=imx708,
  BAYERPAT=RGGB, focus dither stepping confirmed (LENSPOS 0.5→1.0…, LENSPREP
  lags = real VCM settle). Exposure matched eclipticam (~60s/g1) per decision.

## Autostart — WIRED & CAPTURING (2026-07-29)

astrocam is now **night-only** (day capture deprecated, as eclipticam) and
capturing automatically:
- **`astrocam-v3-night.service`** (enabled+running) — the streaming daemon,
  venv python, tmpfs buffer `/var/lib/astrocam-buffer/v3`.
- **`astrocam-v3-uploader.service`** (enabled+running) — `astrocam_v3_uploader.py`,
  drains tmpfs → NFS flat night tree `~/astrocam-frames/<night>/HH/`.
- **Old `astrocam-capture.service` DISABLED + stopped** — reboot hazard gone.
- **Verified end-to-end**: imx708 4608×2592 RGGB FITS reach NFS with correct
  CAMERA/BAYERPAT/EXPTIME=59.9 headers and per-frame LENSPOS focus dither.
- **Committed & pushed**: `PeterGrecian/astro` @ 51a83c3 (rebased onto origin).

Runs continuously with no sun-altitude gate (chosen 2026-07-29 for the star
test tonight). Daylight frames just saturate harmlessly (guard = 95% of uint16
ceiling); they carry no astronomy but cost disk — watch buffer/NFS if it stays
sunny. Cover left **open** by hand (no auto cover control in this path).

## Pending / loose ends

- **Service units not in ansible**: `astrocam-v3-{night,uploader}.service` were
  `install`ed by hand into `/etc/systemd/system/` (root-owned). eclipticam's
  equivalents are ansible-managed — add astrocam's to the ansible repo so they
  survive a reimage.
- **No sun-altitude day/night gate or cover automation** (deferred). If wanted
  later, mirror eclipticam's per-minute `capture.py` tick + cover-on-flip.
  Right now it captures 24/7 and the cover is manual.
- **RECALIBRATE from real imx708 sky** (all imx219/v2-lens/3280×2464 era, now
  invalid): pole_prior_xy, plate_scale, pedestal, and the occlusion tile map.
- **Confirm true stellar-infinity focus** on stars tonight — daytime trees are
  finite distance; real infinity may want slightly below 1.0. The dither covers
  0.5–1.5 so tonight's data will show it. Pick the sharpest LENSPOS from stars,
  then narrow/centre the dither (or pin it) on that value.

## Decisions

- Reuse eclipticam's `astro.capture.streaming` engine; astrocam gets a thin
  night daemon, not a rewritten loop (2026-07-29).
- Focus lp=1.0 (probed), with night dither 0.5→1.5 step 0.1 (2026-07-29).
- Night exposure/gain: match eclipticam-v3w (~59.9s @ gain 1.0) — this moves
  astrocam from short-exposure×coadd star-trails to 60s single frames
  (2026-07-29).
- Rotation 180 in capture (mount inverted) — via streaming engine's
  `rotation_180`, matching rpicam-still `--rotation 180` used for test frames.
