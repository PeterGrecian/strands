# astro-v3s — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Mission

Replace the v2 (imx219) camera on **astrocam** with a newly-bought **Pi Camera
v3 (standard)** — imx708 sensor — and get it focused and capturing for sky use.

## First night + calibration fixes (2026-07-30)

**Night 1 (2026-07-29 session) captured cleanly and unattended: 373 dark-sky
frames**, gate started at dusk (~21:12 UTC, sun −10°) and stopped at dawn
(~03:xx). Frame mean ~106 (real dark sky, not saturated). Focus dither swept
0.5–1.5 all night — visible as **"tadpole" star trails** (tight in-focus end →
fat defocused head; a free visual focus readout confirming breathing is modest).

Peter's verdict: **videos excellent, brightness curves wrong, sky inverted.**
Both defects were single stale imx219-era config values — fixed 2026-07-30:

- **Pedestal 512 → 105.** Chart plots `log2(mean/pedestal)`; with imx708 dark
  floor ~106 and pedestal still 512 the curve floored at −2.3 stops. Measured
  105.5 floor from deep-night (00–03 UTC) frame means; set pedestal=105 (just
  under, same convention as the old 512). Commit `astro` @ 82021b1.
- **rotate_180 true → false** (the inversion Peter spotted — Polaris above the
  pole not below). The imx708 streaming engine rotates 180 IN-CAPTURE, but
  camera.json still had rotate_180=true so the **render stage**
  (`astro.present.render` np.rot90, via `bin/nightly-cam`/`sum-sweep`) rotated
  AGAIN → 360 → inverted. Verified against the code. Raw FITS were already
  correct (single in-capture rotation) — hence videos looked fine; only the
  rendered/published deliverables double-rotated. Now matches imx219's single
  downstream rotation AND eclipticam-v3w (rotate_180 unset). Commit `astro` @
  4aadfea.

**Reprocessing Night 1 with the fixes**: run on **astrocam itself** (`bin/nightly-cam
--camera astrocam --night 2026-07-29 --no-derot --publish`), because the
processing topology is unclear — puppy's `~/astrocam-frames` is an empty local
dir (no NFS mount to bigdisk), so puppy is NOT currently processing astrocam
despite camera.json `processing.host: puppy`. astrocam reaches its own frames
(its `~/astrocam-frames` = the bigdisk NFS mount) and has `nightly-cam`.
`--no-derot` because pole_prior is stale.

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
- **Enclosure — sealed plastic box, BY DESIGN (do not vent)**: the whole board
  equalises to one temperature (no SoC hot-spot). ~54.5°C idle, ~70°C under
  stacking load, `throttled=0x0` (never throttled) — well within the Pi 4's
  80°C throttle / 85°C cap. The seal is deliberate: in winter the board's own
  heat keeps the internals **above dew point**, preventing condensation on the
  lens/sensor/board (dew ruins frames + risks the hardware). So the warm sealed
  box is an ANTI-DEW feature, NOT a thermal fault — do not add ventilation.
  (Contrast: puppy overheats/thermal-reboots in hot weather; astrocam does not.)

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

**Sun-altitude gate now in place** (eclipticam-style): `astrocam-v3-gate.timer`
fires a per-minute oneshot (`astrocam_v3_gate.py`) that starts/stops
`astrocam-v3-night.service` on the sun-altitude boundary — night below −10°
(astrocam camera.json threshold = eclipticam-v3w), day above −8° (hysteresis).
Night service boot-autostart **disabled** (gate owns it); uploader stays
always-on. Committed `PeterGrecian/astro` @ 0018d7c.

- **Gated on SUN ALTITUDE only, not brightness**: the imx708 pedestal is stale
  (imx219 value) so `astro-state`'s brightness tier was calling +12° daylight
  "night". Sun altitude is robust until the pedestal is remeasured. (astro-state
  still runs and writes state.json, but the gate ignores its brightness verdict.)
- **polkit `50-astrocam.rules`** lets peter toggle the services without sudo
  (mirrors 50-eclipticam.rules). Gate uses `systemctl --no-block` so a 60s
  in-flight exposure drain (up to TimeoutStopSec=90) doesn't outlive the tick.
- Verified: gate correctly stops the service in daylight, both start & stop
  paths work via polkit as peter.

Cover left **open** by hand (no auto cover control in this path).

## Brightness pedestal — DONE (2026-08-01, incl. live website)

The imx708 brightness-chart pedestal is settled and **verified on the live site**
(www.petergrecian.co.uk/astro/astrocam):
- **pedestal = 50** — gives **≥1 stop of winter footroom** (Peter's requirement).
  Darkest observed clear summer sky = frame-mean 100.5 → reads log2(100.5/50)
  ≈ 1.0 stop; winter can darken a further full stop before flooring. NB 50 is
  BELOW the sensor black level (~62-64) — a deliberate low reference for
  footroom, not a physical black level. Chart shape + clear/cloudy split
  unchanged, shifted +1 stop. (History: imx219 512 → imx708 105 → 99 when the
  clear floor turned out 100.5 → 50 for winter footroom.) astro @ e854c54.
- **Live website uses it**: the page pulls `astrocam/brightness-combined.png`
  from S3. Rebuilt via `combined-brightness --camera astrocam --publish` on
  muppet (all 4 nights re-plotted at pedestal 50); verified the clear night
  (2026-07-31) now bottoms at ~5.7 stops with the floor far below — no
  flooring, footroom present. Tonight's auto-run keeps it current.
- **Prereq fixed**: muppet's astro checkout was stale (pedestal 105); pulled to
  e854c54. (Had the recurring identical-to-origin bin/storage-report local edit
  blocking the pull — confirmed byte-identical, discarded, no loss.)
- `sky_clear_max_stops` 4→5 to track the shift (interim; re-derive from imx708
  clear/cloudy nights).
- **Pre-existing plot bug flagged (NOT mine, NOT pedestal-related)**:
  `bin/combined-brightness` draws the clear/cloudy line at `2 ** SKY_CLEAR_MAX_STOPS`
  (= 2**5 = 32, off-scale) instead of at the stops value itself. The axis is
  already in stops, so the `2**` is wrong. Cosmetic; the "+5" label is right,
  the line position is not. Fix separately.

## Camera-generation index (POSINDEX) — 2026-07-30

The imx219→imx708 swap is a hard calibration-epoch boundary. Made it explicit
+ indexed (astro @ 7ee1489):
- `camera.json position_index=2` + `position_registry` documenting each
  generation (1=av2/imx219, 2=av3s/imx708: sensor, bayer, resolution, dates,
  per-epoch calibration). **Increment on any future camera/lens/mount change.**
- Streaming engine stamps `POSINDEX` in every FITS (optional field; eclipticam
  unaffected). Verified live: imx708 frames carry POSINDEX=2.
- Aligns with astro-storage's av2/av3s-by-date labelling; gives them a
  per-frame signal too.
- **Backfill DONE (2026-07-30)**: last night's 373 v3 frames stamped POSINDEX=2
  (verified 373/373, data intact, atomic writes). Guarded on CAMERA==imx708.
  Ran ON muppet against `/mnt/bigdisk/...` directly — see migration gap below.
  (imx219 history still unstamped — epoch clear from CAMERA header + date.)

### ⚠️ bigdisk→bigstore cutover migration gap (2026-07-30)

astro-storage repointed astrocam `~/astrocam-frames` from bigdisk
(192.168.0.10=muppet:/mnt/bigdisk) → **bigstore**
(muppet:/mnt/bigstore/astro-data/astrocam-frames) mid-session. But pre-cutover
nights were **NOT migrated**: `2026-07-29` (373 frames + stacks) exists ONLY on
`/mnt/bigdisk/astrocam-frames/2026-07-29`; bigstore has no such dir yet. So
astrocam can't see last night via the new mount. **Data is SAFE on bigdisk**,
just not moved. Flagged to astro-storage to migrate 07-29 (+ any other pre-07-29
nights) to bigstore. NB the POSINDEX backfill was done on the bigdisk copy so it
survives the migration — the copy should pick up the stamped versions.

## Temperature logging — dirty logger live (2026-07-30)

astrocam is the only outdoor camera, so temp tracking done dirty (not the
long-mooted pi-fleet feature). `astrocam-templog.timer` appends
`utc,cpu_temp_c` to `~/astrocam-templog.csv` every 2 min (rotates at 1 MB —
root is 89% full). Source in astro repo `astrocam/astrocam-templog.*` @ 3f3a99a;
deployed copies are hand-placed (add to ansible with the other units).
- CPU temp only — no board ambient sensor (sealed box, no I²C temp chip). Pair
  with an external ambient reading (weather API for the location) for true
  ΔT-above-ambient. imx708 die temp is in picamera2 metadata if per-frame
  sensor temp is ever wanted (would touch the capture path — not done).
- Purpose: validate the ΔT-above-ambient model (ambient now ~20°C → ~57°C
  internal ≈ +37°C), catch summer throttle risk (35°C ambient + stacking could
  near the Pi4 85°C cap), confirm winter dew margin (−5°C ambient → ~+32°C
  internal, above dew). Tonight is the first full curve (capture on = warmer).

## Automated processing — FIXED & WORKING (2026-08-01)

**First fully-autonomous night: 2026-07-31 processed end-to-end with zero
intervention.** Capture (381 frames) → auto-stack at dawn 03:48 UTC → published
to S3 04:57 (brightness chart, max-stack, poster JPEGs, sweep videos). The
max-stack confirms all fixes on a real deliverable: correct pole/orientation
(rotate_180 fix), sharp thin trails (1.4 focus), right stretch (pedestal 105).
verdict=clear, 144/381 stacked (partial cloud).

**The fix that did it: the muppet symlink repoint** (bigdisk→bigstore, below).
Once muppet's stage-1 read/wrote state.json on the disk where frames actually
land, the dawn `pending_process` flag flipped and the dispatcher fired. The
"astro-state silence" seen 2026-07-31 was just because it was daytime (no dawn
transition to trigger on) — it came alive at the real dawn.

**Still to tidy** (not blocking — processing works): astrocam is still
double-assigned in `/etc/default/astro-{state,process}` on BOTH muppet and
puppy (one-host rule). muppet is the active/working owner; clear astrocam from
puppy's lists. Coordinate with astro-storage (mailed 2026-07-31, no reply yet).

### History — the diagnosis (2026-07-31)

Last night (2026-07-30, cloudy) captured fine but was NOT processed. Chased it
to the end — it is **not** a missing-pipeline problem, it's **bigstore-cutover
fallout** in the existing stage-1/stage-3 chain:

- Processing is a built dispatcher: `astro-process` (stage 3) watches per-camera
  `state.json` (written by `astro-state`, stage 1); when the dawn
  `pending_process` flag flips it runs `publish-night-cam`. Host ownership is
  set by `/etc/default/astro-process` `CAMERAS`, NOT camera.json
  `processing.host` (that field is doc-only). Rule: exactly ONE host per camera.
- **Bug 1 (fixed)**: muppet's `~/astrocam-frames` symlink still pointed at the
  OLD `/mnt/bigdisk/astrocam-frames` (pre-cutover). New frames capture to
  bigstore. So muppet's astro-state read/wrote state.json on the stale empty
  bigdisk path → dawn flag never seen by the dispatcher. **Repointed to
  `/mnt/bigstore/astro-data/astrocam-frames`** (muppet's LOCAL bigstore disk,
  /dev/sda1) — now sees last night. (First attempt wrongly used the NFS client
  name `/mnt/muppet/bigstore`; corrected to the local path.)
- **Bug 2 (OPEN)**: astrocam is DOUBLE-ASSIGNED — `CAMERAS="--camera astrocam"`
  on BOTH muppet (astro-process active) AND puppy (astro-process inactive), for
  both astro-state and astro-process. Violates one-host rule.
- **Bug 3 (OPEN)**: even after the symlink fix + astro-state restart, muppet's
  astro-state writes NO astrocam state.json (silent, no log, manual tick
  produces nothing). Stage-1 still not producing the trigger. Needs deeper
  look.
- Decision (Peter): **muppet owns astrocam stage-1 + stage-3** (data local
  there, gigabit, dispatcher already active); clear astrocam from puppy.
- **Handed to astro-storage** (their cutover caused it) to agree host
  assignment + path realignment rather than me re-wiring the dispatch chain
  solo. puppy's 100 Mb/s link also rules it out for 9 GB/night unless a
  capture-time 2nd copy lands locally (Peter's idea) — noted for later.
- Queue idea (Peter): a real job-queue for muppet dawn contention
  (eclipticam+astro-canon+astrocam) is worth doing but is NOT what's blocking
  astrocam — the dispatcher already exists. Deferred as separate work.

## Pending / loose ends

- **Not in ansible**: `astrocam-v3-{night,uploader}.service`,
  `astrocam-v3-gate.{service,timer}`, and `/etc/polkit-1/rules.d/50-astrocam.rules`
  were all `install`ed by hand (root-owned). Repo copies of the gate script +
  polkit rule are committed under `astrocam/`, but the systemd unit files and
  the installed polkit rule are NOT ansible-managed — add them to ansible so
  they survive a reimage. eclipticam's equivalents are ansible-managed.
- **No cover automation** (deferred). The gate handles day/night service
  switching but does NOT move the cover (eclipticam moves the cover on the
  flip). Cover is currently manual/open. Add cover open-on-night /
  close-on-day if wanted.
- **Processing topology unclear / puppy not mounting astrocam frames.**
  camera.json says `processing.host: puppy`, but puppy's `~/astrocam-frames` is
  an empty local dir — no NFS mount to bigdisk (192.168.0.10:/mnt/bigdisk/
  astrocam-frames, which IS exported to the LAN). puppy rebooted after
  overheating; the mount may have been manual/transient and lost, or puppy was
  never the real processor. Night-1 reprocess was therefore run ON astrocam.
  Decide the intended processor and make its frame access durable (fstab/mount
  unit) so nightly processing isn't ad-hoc. **puppy overheats in hot weather**
  (thermal reboots) — factor that into whether it should own processing.
- **RECALIBRATE remaining stale fields from real imx708 sky** (imx219/v2-lens/
  3280×2464 era): pole_prior_xy, plate_scale, occlusion tile map, and
  `sky_clear_max_stops` (4.0 — per-sensor clear/cloudy divider on the
  stops-above-pedestal scale, which shifted with the new pedestal; needs a few
  clear vs cloudy imx708 nights). *(pedestal DONE 2026-07-30 = 105.)*
- **Focus SETTLED at ~1.4 (2026-07-30, astro @ 851ebd3)**. Peter read Night-1
  star trails directly: LENSPOS **~1.4 is the sharp stellar focus** (tight
  sidereal streak), the low end (0.5) is a fat defocus blob, focus improves
  steadily UP the ramp. lens_position 1.0→1.4; dither now **1.3–1.6 step 0.02**
  (16 positions, dense bracket around 1.4). Verified live: sawtooth steps
  1.30,1.32…1.44 exactly. Takes effect tonight.
  - Corrects two wrong earlier signals: the daytime-tree probe (said ~1.0 —
    trees are finite-distance, focus lower than infinity) and a crude FWHM
    script (said low end sharp — it grabbed faint moving sources). **Trails are
    authoritative; my rough px measurements were not — don't trust them.**
  - **PSF vs eclipticam**: eclipticam gets ~1px; astrocam's best trail is
    tighter than the fat low-end but the raw-px gap is partly GEOMETRY —
    astrocam is the STANDARD v3 (~4.74mm, ~66° FOV), ~1.7× finer plate scale
    than eclipticam's WIDE v3w, so a star spans ~1.7× more px here. **Compare
    PSF in arcsec (via plate scale), not raw px.** Whether a real optical gap
    remains after that conversion is still open.

## Decisions

- Reuse eclipticam's `astro.capture.streaming` engine; astrocam gets a thin
  night daemon, not a rewritten loop (2026-07-29).
- Focus lp=1.0 (probed), with night dither 0.5→1.5 step 0.1 (2026-07-29).
- Night exposure/gain: match eclipticam-v3w (~59.9s @ gain 1.0) — this moves
  astrocam from short-exposure×coadd star-trails to 60s single frames
  (2026-07-29).
- Rotation 180 in capture (mount inverted) — via streaming engine's
  `rotation_180`, matching rpicam-still `--rotation 180` used for test frames.
