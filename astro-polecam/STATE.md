# astro-polecam — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Mission

Replace the v2 (imx219) camera on **astrocam** with a newly-bought **Pi Camera
v3 (standard)** — imx708 sensor — and get it focused and capturing for sky use.

## Glass window over the aperture -> epoch 3 (2026-08-20)

Peter fitted a tempered-glass phone screen protector over the lens aperture for
rain protection and clamped the camera back in place. That is a new calibration
epoch: **`av3sw`, POSINDEX 3, boundary 2026-08-20** (Peter affirmed the date;
the images cannot settle it -- see the clamp, below).

**Rain is not a threat to this camera, and that is now measured rather than
assumed.** Through a fortnight of wet days -- including 3.0 mm on 2026-08-19 --
astrocam held 22 days of unbroken uptime, `throttled=0x0`, and a dT above
ambient stable at ~25-27 C across dry and wet days alike (a box taking water in
sheds heat differently; these curves are superimposable). The wettest night was
also among the best-yielding: 460 frames, verdict clear, 256 stacked, ahead of
the drier 08-17. Nothing about rain needed fixing.

**The enclosure question is answered**: the camera body itself plugs the
aperture, so the box was already genuinely sealed -- the glass adds no
vented->sealed transition and no thermal change. The seal's own arithmetic is
the real desiccant: air sealed in at 20 C / 63% RH has a dew point of ~12.7 C
against a box floor of ~37 C (~24 C of margin), and sits at ~14% RH once warmed
to operating temperature. Silica gel is redundant here -- and a sachet stored
open is worse than none, because gel capacity FALLS with temperature, so a
loaded sachet in a box running 25 C above ambient desorbs into the enclosure.

**The mount is CLAMPED -- a calibration fact worth keeping.** Phase-correlating
the 08-19 and 08-20 max-stacks gives 2 px at half-res (~4 px native = 0.057 deg
= 3.4 arcmin; foreground-only dy=-2 dx=0, peak/sigma 14-25). A remount therefore
returns the camera to within a few pixels, with two consequences: (a) **pointing
cannot date an epoch boundary on this camera** -- a near-zero shift is EXPECTED
across a remount, not evidence the camera stayed put (I concluded the opposite
first time; Peter corrected it); (b) epoch 3 is broken **photometrically, not
geometrically**, so the epoch-2 pole/plate solution is a starting point rather
than a write-off.

**The ~8% transmission loss is textbook, NOT measured.** Fresnel at two uncoated
air-glass surfaces: R = ((1-1.5)/(1+1.5))^2 = 0.04 each, T = 0.96^2 = 0.9216 ->
7.84% = 0.089 mag = 0.118 stops. The load-bearing assumption is *uncoated*; an
AR-treated protector would lose considerably less. Off-axis is a non-issue:
4.4%/surface at the 37.5 deg field edge gives 8.6% at the corner vs 7.8% on
axis, i.e. ~0.9% corner-to-centre and no vignetting gradient. To get the real
number, measure **stars, not sky** -- a fixed star's flux scales by exactly the
transmission factor, whereas 0.12 stops is invisible against night-to-night sky
scatter (08-19 per-hour means ran 96-166, 08-20 ran 132-282).

**Backfill done.** The 08-20 night was captured under epoch 3 but stamped
POSINDEX=2, the config having been bumped the following morning. All 465 frames
re-stamped on muppet (locally, not across the NFS mount), in place, 1.1 s, no
size change, HISTORY card added. Verified 08-20 = {3: 465}, 08-19 = {2: 460}.
NB `max/min/sum.fits.fz` carry no POSINDEX at all -- the derived products sit
outside the stamping convention entirely.

**Not evidence of anything**: the 08-20 night stacked only 96/465 against
210-340 on prior nights. That is weather -- the sky ran bright and swinging
(132-282 vs a steady 96-166 on 08-19), and variability is what defeats the
stacker; the "clear" verdict comes from a 10-minute anchor at 03:00 that
sampled a genuinely clear patch.

## Cover automation landed (2026-08-13)

Good results overnight, but the cover was still open at dawn. Root cause was
**not** a broken servo: nothing was ever commanding it. The gate switched
services on sun altitude and left the card wherever it was last put by hand.
The gate now drives `cover.py` on both edges — verified end-to-end on hardware,
Peter confirming the card by eye in each position. Details in the pending list
below (including the `capture.py`-is-not-the-deployed-path trap).

Two lessons worth carrying:
- **The cover is white card ~2cm above the lens**, so closed reads as uniform
  mid-grey, not dark. Frame **mean** cannot tell it from blue sky (measured:
  120–136 across the whole servo sweep). I spent two days concluding the servo
  was mechanically broken on the strength of that non-measurement. Use spatial
  variance if a detector is ever needed — or just ask the human at the box.
- **Check what actually runs before reading its logic.** The cover automation
  in `capture.py` is elaborate and has never executed; the deployed units are
  the night daemon + gate. The missing `events.log` was the tell.

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
  is harmless (pigpiod inactive). **Now driven automatically by the gate**
  (2026-08-13) — see "Cover automation" below. The cover is a piece of white
  card ~2cm above the lens: closed reads as a *uniform mid-grey*, NOT dark, so
  frame **mean** cannot tell closed from blue sky — use spatial variance
  (uniform card vs structured sky) if a detector is ever needed.
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

Cover was left **open** by hand in this path; superseded 2026-08-13 by gate-driven
cover automation (below).

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
- **Epoch 3 (`av3sw`) opened 2026-08-20** — tempered-glass window + remount (see
  the glass section above). `position_index=3` deployed to astrocam and to the
  repo; epoch 2 now closes at 2026-08-19. Second backfill done (465 frames).
  Deploying it, note the repo copy of `camera.json` on pip was AHEAD of the
  capture host (astro-science's `black_level`/`blackest_observed` work, not yet
  deployed) — so the change was applied to astrocam's own copy rather than
  scp-ing the repo file over, to avoid shipping another strand's undeployed
  edits. Check that diff before any future hand-deploy.

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

## PSF / undersampling investigation (2026-08-01)

Deep-dived the imx708 PSF via the `splay` **bayer_heatmap** tool
(`~/splay/apps/bayer_heatmap.py`) on clear-window frames of 2026-07-31. Reference
frame: `.../2026-07-31/02/1785550053740.fits.fz` (02:07:33 UTC, LENSPOS 1.3).

- **Focus width is flat across the operational dither** — a null result, and the
  *right* kind. Native-red-plane cross-trail σ ≈ 2.2 px (≈4.4 px full-res-equiv,
  FWHM ~5.2 px), essentially constant over the whole D=1.3–1.58 ramp
  (corr(W,D)≈0). Breathing over ±0.15 dioptre is below the star-to-star scatter.
  W = √(W_min² + [k(D−D₀)]²) is flat-then-quadratic near the vertex, so **k is
  unmeasurable in-band; needs a dedicated WIDE-D sweep** to see the quadratic.
  (First pass on the *half-res* green plane reported 5.5 px and looked flat too —
  the decimation ×2 inflated it; the native-red re-measure is the real number.)
- **The PSF is UNDERSAMPLED at focus.** A faint star (peak ~40 ADU above sky, at
  x4343) put ~all its light on a single green photosite: green sum ~3400,
  blue ~189, **red ~0**. This is *not* colour and *not* a defect — it's a
  sub-pixel PSF aliasing onto the dense green quincunx. Proven real, not a hot
  pixel: its centroid marched y 732→660 at **11 px/min** across 7 contiguous
  frames (a hot pixel is fixed; a near-pole star <2 px/min — so it's a normal
  field star, well off the pole).
- **Camera is HEALTHY — all three channels work.** Whole-frame per-phase stats:
  R median 85 / std 7.7 / max 716; bright stars show strong red (R 500–620 ADU
  above sky on peak-~1000 stars). "Red missing" was a **faint-source** effect
  (undersampled core on green, red wing below the red sky floor), not a channel
  failure. Confirmed on two bright stars: x2114 (red star, R×0.91) and x3385
  (neutral, R×1.57 B×1.54).
- **bayer_heatmap BUG found & FIXED** (committed splay `28e1335`): `assume_white`
  had no gain cap, so a near-empty channel (blue on a red star) gave WB **B×447**,
  detonating a few blue noise photosites to 20000–50000 ADU — false "4 blue
  pixels, not a star". Fix: skip balancing a channel whose bright mean <5% of G,
  cap any gain at ×4. Verified: red star→B×1.00 (no explosion), neutral→~×1.5.
- **Green is the channel to work in** — RGGB puts both greens on the cell
  diagonal, so green is 2× the sampling of R/B (a dense quincunx). For
  PSF/position/trail/pole geometry, use green; skip demosaic + WB games.
- **Joined-up trail heatmaps** (one star, 7 frames placed at true (x,y) → one
  continuous streak) made the dither visible directly: the **sawtooth snapback**
  (LENSPOS 1.58→1.30 wrap) shows as a discontinuity in the trail, and the
  breathing modulates brightness/colour along it "about the right amount".
  **Beading** along the trail: header duty cycle is ~100% (EXPTIME 59.9s ≈
  cadence 59.9s), so the beads are the per-frame focus-steps (bright tight vs dim
  fat), not shutter dead time — any real inter-frame gap is sub-0.1s (below
  DATE-OBS resolution). Measuring bead pitch vs 11px/frame would quantify it.

## DIRECTION: sidereal-space static accumulator → moved to astro-science

The sidereal-space static-accumulator direction (the *science* framing that ties
the sub-pixel work together) **moved to the `astro-science` strand 2026-08-02** —
it's cross-cutting theory (drift, dither, undersampling, accumulation), not v3s
camera operations. See `astro-science/STATE.md` ("The thrust"). What stays here
is purely operational: this camera's setup, focus, calibration, and processing
topology. (This strand becomes **astro-polecam** at the device-rename step.)

## Pending / loose ends

- **`occlusion.json` is now stale** — it maps static obstructions, and the
  camera has moved (small, ~3.4 arcmin, but real). This never arose before
  because the camera had never moved *within* its epoch. Re-derive from epoch-3
  frames.
- **Measure the real transmission step** across the 08-19/08-20 boundary by
  stellar photometry, and replace the textbook 7.84% in `position_registry`
  with the measured figure. astro-science has been told the current number is
  theory, so their epoch-relative gate isn't built on an unmeasured constant.
- **Is there ALREADY a window?** IDEAS.md carries a capture-unification note
  that "astrocam already has a transparent cover". If the aperture already had
  a transparent element, the glass is a *second* plate: the incremental step
  stays ~8% so the epoch arithmetic is unaffected, but the absolute
  transmission budget and the ghosting picture are not. Settle it at the box.
- **astrocam root is 94% full** (415 MB free on a 6.8 GB card; /usr is 3.8 GB
  of it, nothing runaway — templog only 374 KB). STATE recorded 89% when the
  templog rotation was set, so it is drifting the wrong way.
- **Mailbox ritual trap (tooling, not this camera)**: `strand-mailbox drain`
  empties the spool but NOT `MAILBOX.md`, so a subsequent `ding --arm --keep`
  re-delivers the stale pointer line and exits at once — the doorbell reads as
  armed but never blocks, and the Stop hook nags every turn. Truncate
  `MAILBOX.md` after acting on mail, then re-arm. Corrections spooled to
  aifabric; a separate unexplained failure (waiters killed with empty outputs
  against an empty mailbox) is spooled there too.
- **For Peter — HTM / tessellation ownership.** astro-science asks whether that
  decision is theirs (they own the map and accumulation theory) with polecam
  holding only what it means for this camera. They also report the HTM +
  progressive-daily-bootstrapping scheme is **written down nowhere** — not in
  either repo, either strand, the ideas spools or the session archive.

- **Not in ansible**: `astrocam-v3-{night,uploader}.service`,
  `astrocam-v3-gate.{service,timer}`, and `/etc/polkit-1/rules.d/50-astrocam.rules`
  were all `install`ed by hand (root-owned). Repo copies of the gate script +
  polkit rule are committed under `astrocam/`, but the systemd unit files and
  the installed polkit rule are NOT ansible-managed — add them to ansible so
  they survive a reimage. eclipticam's equivalents are ansible-managed.
- ~~**No cover automation** (deferred).~~ **DONE 2026-08-13** — the gate now
  drives it. `astrocam_v3_gate.py` calls `cover.py` on the two edges: **open
  before** starting the night daemon, **close after** stopping it (so the
  sensor is never exposed to a moving card, nor capturing into a closed
  cover). Verified end-to-end on hardware — Peter confirmed the card by eye in
  both positions. astrocam commit `002d0a6` (**not pushed**).
  - The gate is stateless and ticks every minute, but a servo is **not**
    idempotent the way `systemctl start` is — re-commanding each tick would
    buzz the SG90 60x/hour. Last commanded position persists in
    `/var/lib/astrocam/cover.json`; it moves only on a change. A failed move
    is logged and *not* recorded, so it retries next tick.
  - **Caveat**: success is inferred from `cover.py` exiting 0, which does not
    prove the card moved. There is no closed-loop feedback.
  - **`capture.py` is NOT the deployed path.** It has full cover automation
    (thresholds, hysteresis, lockout, `events.log`) and none of it has ever
    run — the live units are `astrocam_v3_night_daemon.py` + the gate. Its
    `COVER_DARK_MEAN=80` / `COVER_BRIGHT_MEAN=250` are imx219-era raw-Bayer
    numbers; do not copy them without re-deriving for imx708. The absent
    `events.log` on every night dir is the tell that capture.py isn't running.
- **`cover.py` "closed" is `s.mid()`, which reports `value = -0.2`, not centre.**
  The gpiozero `Servo` isn't symmetric about its range, so "closed" is not the
  midpoint it reads as. Both positions work in practice (verified by eye), so
  this is cosmetic *today* — but it's the first suspect if `closed` ever starts
  underswinging, and it will mislead whoever recalibrates. Unfixed.
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
