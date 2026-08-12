# astro-capture — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Strand kind: DEVELOPMENT (declared 2026-08-11)

ubersitrep left keeper-vs-dev unsettled when it wrote this strand's mission
(2026-08-09). Declaring it **development**: there is a real build backlog with a
moving frontier (the unification migration below), not a steady state to
custody. Revisit once the migration lands and the shared module stops changing —
at that point it plausibly becomes a keeper.

## What exists

**The charter's work is already written down, unowned, in
`astro/design/capture-unification.md`** (214 lines). Adopting it as this
strand's backlog is the strand's founding act — it is exactly "the unified
capture pipeline that all the astro cameras share".

**Ground truth checked 2026-08-11 — the design doc's own status line ("design,
not implemented beyond the eclipticam v3w streaming daemon", 2026-06-15) is
STALE. More has landed than it admits:**

| Piece | Design says | Actually (verified 2026-08-11) |
|---|---|---|
| `astro/capture/streaming.py` | exists | ✔ exists |
| eclipticam v3w on shared module | ✔ done | ✔ `eclipticam/v3w_night_daemon.py` imports `astro.capture.streaming` |
| **astrocam** → shared module (**migration step 1**) | "least painful first", TODO | ✔ **ALREADY DONE** — `astrocam/astrocam_v3_night_daemon.py` is a thin wrapper over the same `StreamingConfig, run`; old imx219 `astrocam/capture.py` retired 2026-07-29, `astrocam-capture.service` disabled |
| `uploader.py` / `modes.py` / `host.py` / `__main__.py` | target shape | ✘ **not written** — `astro/capture/` holds only `__init__.py` + `streaming.py` |
| starcam → shared module (step 3) | TODO | ✘ moot — **starcam RETIRED** (camera decommissioned 2026-08-02) |
| skycam → shared module (step 4) | TODO | ✘ still in `Berrylands/gardencam` |
| eclipticam v1 | — | ✘ `eclipticam/v1_night_daemon.py` does **not** import the shared module — hand-rolled, the cross-camera gating case |

**So the migration is further along than the doc claims and the remaining
ladder is shorter than it reads.** Two live cameras (astrocam imx708 +
eclipticam v3w) already share the streaming engine. First job of the first
working session: **correct the design doc's status section** so it stops
misrepresenting the frontier.

**The EOS 2000D is outside all of this.** Every unification note is
Pi/picamera2; the canon is a USB/gphoto2 body (`bin/eos-capture`,
`bin/eos-focus-cycle`, `bin/eos-sequence`, …) and appears nowhere in the
migration ladder. Whether it ever joins the unified module is an open question
(see below) — it may be honest for it to stay out.

## The founding lesson — canon's 08-10 bugs were CAPTURE-layer, not device-layer

astro-canon's best-night session (2026-08-10, astro `c7132b9`) fixed three bugs.
Read through this strand's lens, **two of them are this strand's charter almost
word for word** — "night/session structure, frame naming":

1. **Restart stem collision.** Pass numbering restarts at 1 after an abort, so a
   re-run silently **overwrote the previous run**. Fixed by stamping a per-run
   UTC `RUN_TAG` into the stem. This bug destroyed ~1,000 frames on 07-28 and,
   on 08-10, the only frames containing an aircraft.
2. **Burst firing.** Drive mode is Continuous Shooting, so holding the full
   press for the whole download window fired ~20 frames of which exactly ONE was
   downloaded — pure shutter wear on a body rated ~100k actuations.
3. (`eos-focus-sweep` used the wedging `Immediate` — that one *is* device-level,
   astro-canon's.)

**Neither #1 nor #2 is canon-specific in principle.** Any camera whose
sequence numbering restarts after an abort has the overwrite bug; "one capture
= one frame" is a pipeline invariant, not a DSLR quirk. Verified 2026-08-11:
`RUN_TAG` appears **only** in `bin/eos-focus-cycle` — the Pi daemons have no
equivalent, so if they can restart mid-night they may carry the same silent
overwrite. **Unaudited, not yet a known bug** — that audit is work unit 1.

This is *why* the strand exists: three capture codebases that are 90% the same
drift independently and bugfixes get ported by hand (the design doc's own
opening argument), so a fix found on one camera never reaches the others.

## How unification works — the pipeline is built FROM the camera work (Peter, 2026-08-11)

**"Share the conventions, not the code path."** Peter's framing, and it settles
the architecture of the whole strand — not just the EOS question:

> astro-\<camera\> has the camera-specific work; capture has the pipeline,
> **unified using the former — wrapped tools maybe**; astro-science does the
> deliverables.

**This inverts the direction of the original design.** `capture-unification.md`
reads bottom-up-by-absorption: write one generic engine, then *migrate* each
camera into it until the per-camera dirs hold "only camera.json". Peter's model
is the other way round: the per-camera work is **legitimately, permanently
camera-specific and stays put**; the unified pipeline is assembled **from** those
parts — **wrapping** them rather than absorbing them. Unification is a *layer
over* the device work, not a solvent that dissolves it.

Consequences, in order of how much they change:

1. **The EOS is not an awkward exception — it is the normal case seen clearly.**
   Under absorption, gphoto2/USB vs picamera2/CSI is an architectural embarrassment
   that has to be either forced in or excluded. Under wrapping it is unremarkable:
   the EOS has its own capture mechanism, like every camera does, and the pipeline
   wraps it. The reason it *looked* exceptional is that two Pi cameras happen to
   share a mechanism (`streaming.py`) and that coincidence got mistaken for the
   architecture.
2. **`streaming.py` is demoted from "the engine" to "one shared implementation."**
   It is what astrocam and eclipticam v3w happen to have in common — genuinely
   worth sharing, verified picamera2-shaped throughout (`cam_idx`, libcamera
   `bayer_format` strings, `lens_position` as a VCM dioptre, `rotation_180`
   mirroring an `rpicam-still` flag). None of that is meaningful for a DSLR. It
   should stay the Pi cameras' shared path and stop being the thing everything
   else is measured against.
3. **The unified layer's real substance is the CONVENTIONS**, which are exactly
   the things the canon bugs proved are cross-camera: run-tagged stems (never
   silently overwrite a re-run), one capture = one frame, night/session
   structure, frame naming, hand-off to storage. Those bind the EOS and the Pi
   cameras equally — and none of them require a shared code path. **Work unit 1
   (the run-tag audit) is therefore not a warm-up: it is the first real piece of
   the unified layer.**
4. **The migration ladder is re-read, not abandoned.** eclipticam v1 and skycam
   still want to move onto `streaming.py` — but now because *they are Pi cameras
   that would genuinely share that mechanism*, not because "everything must end
   up in the module". That is a better reason and it survives contact with the
   EOS. The design's target shape (`uploader/modes/host/__main__`) still stands,
   with the caveat that it is a wrapper layer, not an absorber.
5. **"Wrapped tools maybe" is the open bit.** What the wrapper *is* — a thin
   uniform CLI (`capture --camera <name>`) over per-camera implementations, a
   Python interface, or just a shared convention plus a scheduler — is
   undecided, deliberately. Per the design's own instruction it should
   crystallise **through use**. First honest test: a wrapper that can start a
   night on the EOS *and* on astrocam without either caring which it is.

**~~TODO: fold this into `astro/design/capture-unification.md`~~ DONE
2026-08-12** (astro `bac34ba`). The doc now carries the corrected direction in
its status block, and "Target shape" / "Migration order" each open with an
admonition that they are written in the superseded absorption model. Its status
table is also corrected (astrocam migrated, starcam decommissioned not pending).

## Owned code — the EOS capture tools (Peter, 2026-08-11)

**astro-capture owns the EOS capture tools.** Settled by Peter. Note this means
the strand owns real code from day one, and that its first-owned code is the
camera *outside* the picamera2 unification — which sharpens rather than muddies
the charter: the strand is the acquisition layer for **every** instrument, not
just the Pi ones.

Surveyed `astro/bin/eos-*` (13 tools) 2026-08-11 and classified by layer. The
`eos-` prefix is not a reliable guide — three of them are not capture:

**OURS — capture / acquisition (9):**

| Tool | What it is |
|---|---|
| `eos-capture` | the core: capture frames over gphoto2 with a sane workflow |
| `eos-sequence` | long-exposure star sequence over gphoto2/USB |
| `eos-bulb-run` | long-exposure (bulb) capture run |
| `eos-focus-cycle` | blind focus-experiment capture on stars — **holds `RUN_TAG`**, the only place in the estate it exists (see work unit 1) |
| `eos-focus-sweep` | star-focus sweep over gphoto2/USB |
| `eos-focus-tonight` | arms tonight's focus-cycle run, detached + logged (scheduling) |
| `eos-night-watch` | overnight "can we see stars yet?" ritual (session structure) |
| `eos-star-watch` | wait for a cloud gap, then run the sweep (scheduling/gating) |
| `eos-psf-dither` | night PSF / focus-dither **capture** tool |

Plus `services/eos-focus.service` (the systemd unit arming the above).

**NOT ours — leave with the current owner (4):**

| Tool | Layer | Owner |
|---|---|---|
| `eos-cr2-to-fits` | the CR2→FITS **adapter** — the delivery seam itself | astro-science |
| `eos-star-psf` | offline per-`d` PSF **measurement** (next-day analysis) | astro-science / astro-canon |
| `eos-psf-view` | renders PSF heat maps from the above | astro-science / astro-canon |
| `eos-power` | 12V dummy-battery feed off/on/cycle — **device hardware** | astro-canon (with [[electronics]] for the DC switch) |

`eos-power` is the interesting boundary case: capture *calls* it (the recovery
ladder power-cycles a wedged body), but powering a specific camera is device
specifics, and the 90s-not-10s rail-down rule is astro-canon's hard-won
knowledge. **Ruling: astro-canon owns it, astro-capture is a consumer.** The
recovery *policy* (when to escalate) is capture's; the *mechanism* is the
keeper's.

**Correction (2026-08-12): the live nightly capture path is
`eos-focus-cycle --no-focus`, NOT `eos-capture --no-focus`.** `eos-capture`
has no such flag — the flag is on `eos-focus-cycle`, and
`services/eos-focus.service` arms exactly that. `bin/canon-nightly` is the
*delivery* chain (astro-science), not capture. This matters for the dormancy
marking: `eos-focus-cycle` is **half dormant** — its focus-driving `d`-grid is
retired, but the binary itself runs every night, so it must not be disarmed.

**Consequence for the focus regime:** the `d`-schedule machinery
(`eos-focus-cycle`, `eos-focus-sweep`, `eos-focus-tonight`, `eos-star-watch`) is
now **ours and largely dormant** — astro-canon retired the `d` apparatus on
08-10 (focus by eye at "marker 0", lens on MF, nights run `--no-focus`), having
established that `d` tracked nothing. Do **not** delete these: the sweep tooling
is how a *future* body or a re-seated lens would be re-characterised, and
`eos-focus-cycle` is where `RUN_TAG` lives. But they should be clearly marked
dormant/calibration-only so nobody mistakes them for the nightly path. The live
nightly capture path is `eos-capture` + `--no-focus`.

## Pre-flight check 2026-08-12 (eclipse night) — READ THIS PATTERN

Peter asked for a capture-readiness check before the 2026-08-12 partial
eclipse. Findings worth keeping:

**All three hosts were STALE and nobody would have noticed.** pip was 10
commits ahead of origin (never pushed); muppet, astrocam and eclipticam were
all 13 behind. So the `Immediate` fix committed that same morning had reached
**no camera**. Pushed, and pulled on all three — now all on `ba4c96a`.
**Ritual: a capture fix isn't done when committed, it's done when pulled on
the host that captures.** Check `git status -sb` on pip *and* each host.

**The pull was blocked on all three hosts by hand-copied untracked files**
(`bin/canon-nightly`, `bin/eos-cr2-to-fits`, `services/canon-nightly.*`,
`canon/camera.json`). All were byte-identical to the incoming versions except
muppet's `canon/camera.json`, which was the *older* pip-split version. Deploying
by `scp` instead of committing is what caused this; it will recur until the
canon delivery files are deployed from git.

**`~/dotfiles/bin/` is a SECOND copy of the capture tools, and it is the one
that RUNS.** `eos-focus.service` executes `/home/peter/bin/eos-focus-cycle`
→ `~/dotfiles/bin/eos-focus-cycle`, *not* `~/astro/bin/`. Updating the astro
repo does **not** update the live capture path. Checked: the only difference
was this session's comment header (logic identical, already on Press Full), so
tonight was never at risk — but a real fix could have been "committed, pulled,
and still not live". Synced by hand. **This deserves a proper fix (symlink or
deploy step) — currently tracked nowhere.**

**Astrocam's SD card is at 92% (552 MB free).** Not a threat: `frames_root`
(`~/astrocam-frames`) is an NFS automount onto muppet's bigstore (4.1 T free)
and the tmpfs buffer had zero backlog. Worth watching, not fixing tonight.

**Canon duty cycle FIXED 2026-08-12: 45.0s -> 38.2s period, 67% -> 78% duty**
(astro `0e7bf03`, live before the Perseid peak). Peter asked whether the EOS
double-buffers. It does not — it is a mechanical-shutter DSLR, so some dead
time is real — but the dead time was almost entirely **software**:

**`--wait-event-and-download=Ns` waits EXACTLY N seconds.** It does not return
when the file lands. gphoto2(1): *"A `--wait-event=5s` will take exactly 5
second."* So `wait = secs + 12` was not a timeout, it was 12 s of guaranteed
idle per frame. Measured on real 30 s subs: window 33s -> 1/2, **34s -> 2/2**,
36s -> 2/2, so readout+download is **~4 s** — the other ~8 s was pure waste.
Cut to `secs + 6`. Verified through the real `capture()` path: **3/3 frames,
38.2 s each, dead steady.**

Margin is +6 not +4 deliberately: **a missing file is the WEDGE TELL** —
`capture()` returning False escalates via `recover()` to a **12 V power cycle**.
Trimming to the measured minimum would turn ordinary jitter into false wedges
and cost the night. Do not cut further without re-measuring on this body; the
figure is exposure-dependent.

**The remaining ~2 s of per-frame overhead is NOT recoverable — tested and
rejected 2026-08-12.** After the +12→+6 win, the leftover dead time is the
per-frame `gp("--set-config","viewfinder=0")` (~0.5 s, the only extra gphoto2
process per frame) plus a hardcoded `time.sleep(1.0)` settle. Both look like
dead weight in `--no-focus` mode: nothing engages live view between frames
(`--capture-preview` appears only in `prime()` and `_drive()`, both focus
operations), so there is seemingly nothing to turn off and nothing to settle.

**Measured A/B on the real body, alternating control/lean over 3 pairs:**

| variant | period | duty | result |
|---|---|---|---|
| control (current) | 38.05 s | 79% | **3/3 GOT** |
| lean (no viewfinder=0, no settle) | 36.53 s | 82% | **1/3 GOT — lean00, lean01 NO FILE** |

So it buys 1.52 s/frame and **loses two frames in three**. The `viewfinder=0`
+ settle is load-bearing even when nothing obviously engaged LV — consistent
with the code's own note that capturing with LV up "silently fails on this
body". Left exactly as is. **Do not re-attempt without a mechanism-level
explanation**; a NO FILE is the wedge tell and escalates to a 12 V power cycle,
so this variant would also have thrashed the recovery ladder all night.

**Conclusion: ~38 s / ~78-79% duty is this body's practical floor** at 30 s
subs with the current mechanism. Further gain needs a different mechanism
(solving bulb for longer subs), not more trimming.

**Event-driven forms do NOT work on this body** (tested, all returned instantly
with no file): `=FILEADDED`, `=CAPTURECOMPLETE`, and bare counts (`=3`). Bare
`FILEADDED` with no timeout **blocks forever**. The timed window is the working
mechanism — so the fix is to size it, not replace it.

**59 s subs are NOT available.** 30 s is the max reliable *timed* exposure on
the 2000D; beyond that needs bulb, which the code calls "an unsolved gphoto2
rabbit hole". Peter's "59s on, 1s off" ideal is a picamera2 shape; the DSLR's
realistic ceiling is ~78% at 30 s. Raising it further means solving bulb.

*Testing gotcha that cost time:* with `capturetarget=Memory card` gphoto2 writes
**`.CR2` uppercase**; a probe checking only `dt.cr2` reported false "NO FILE"
and made a healthy camera look wedged. The real code's `_find()` already handles
both cases. Camera was restored to as-found state (`capturetarget=Internal RAM`,
30 s, ISO 1600, RAW) and `eos-focus.service` restarted 10:36Z so the running
process carries the new margin.

**Night-capture override: CONSIDERED AND DROPPED (Peter + analysis, 2026-08-12).**
Peter asked for an override letting night-type capture run at any time, to use
the eclipse as a darkening and catch Perseids/stars. Worked through, it fails on
two independent grounds and the second is the general lesson:

1. **90% obscuration is only 3.3 stops** (~1 heavy cloud). At maximum the sky
   equals an uneclipsed sun at **+1°** — sunset brightness, ~9 stops short of
   stars. Totality is ~20 stops; essentially all the drama is in the last 1%,
   which is why 1999 is not a guide to a 90% partial.
2. **Duty cycle, not exposure, is what catches meteors** (Peter's correction —
   the decisive point). A meteor is sub-second, so it is caught only if the
   shutter is open when it happens. Night capture is 59.9 s at 59.9 s cadence
   = ~100% duty. Any daylight-safe override exposure (~2 ms) gives ~3e-6% duty
   — **effectively zero**. So an override would spend the eclipse shooting
   frames that *cannot* catch the thing it was requested for. **Rule: judge a
   capture change by duty cycle first; a short exposure is not a small meteor
   loss, it is a total one.**

Not built, deliberately. The eclipse window has no capture value for this goal.

**The real prize tonight needs no override: a MOONLESS PERSEID PEAK.** A solar
eclipse only occurs at new moon, so eclipse day *guarantees* zero lunar washout
on the 12/13 Aug peak. Normal gating (astrocam/eclipticam 20:40Z, canon 20:57Z)
covers the whole night. Measured duty cycles from 2026-08-11: **astrocam 100%
(426 frames, 59.90 s median gap, zero dropouts >70 s, 20:44-03:48Z)** —
the best meteor instrument here; **canon 67%** (30 s subs at 45 s cadence,
477 frames, 21:01-03:39Z), losing 15 s/frame to USB download. If canon duty
cycle is ever worth improving, that download gap is the target.

**The eclipse is not capturable by this estate, and that is by design.**
Real timings (Royal Observatory, London): first contact **17:17Z**, max ~90%
**18:12Z**, last contact **19:06Z** — sun altitude +19.3° falling to +2.6°,
in the **west**, in daylight. Every camera is night-gated (astrocam/eclipticam
−10°, canon −12°) and earliest capture is **20:40Z — 94 minutes after last
contact**. Worse, pointing rules it out anyway: astrocam is polar-aligned
(north, pole in frame), eclipticam-v3w looks south, and daytime capture was
*deliberately retired* estate-wide on 2026-07-06 (`design/retire-moon-marking-v1.md`)
— `eclipticam/capture.py` still ticks every minute but shoots nothing by day.
The only instrument that could image it is the EOS: a tripod body needing a
human to point it west at a low sun, with a **solar filter** (90% still
destroys a sensor and an eye). That is a per-device astro-canon job, not a
pipeline change. **Do not "fix" this by lowering a night gate.**

## Pending / loose ends

**~~Work unit 1 — the frame-naming / run-tag audit~~ DONE 2026-08-12**
(astro `bac34ba`). Answer: **the estate is sound on "a frame name is never
reused"** — the canon's 08-10 restart-collision bug has **no latent twin** in
the Pi daemons. But they satisfy the rule by three unrelated mechanisms:

| Camera | Naming | Mechanism |
|---|---|---|
| astrocam, eclipticam v3w | `<epoch_ms>.fits.fz` | monotonic wall clock (shared `streaming.py`) |
| skycam | `<epoch_ms>.jpg` | **same convention, arrived at independently** in `Berrylands/gardencam` |
| eclipticam v1 | `NNNN.fits.fz` | scans the hour dir for `max(seq)+1`, so a restart *continues* |
| EOS 2000D | `<RUN_TAG>_pNN_iNN_dNN` | per-run UTC tag (gphoto2 pass numbering restarts; a clock doesn't) |

Verified empirically on astrocam 2026-08-11: 426 frames, 426 distinct names,
min gap 59.79 s vs 1 ms name resolution. `epoch_ms` is carried unchanged
through the upload seam — no renumbering. **The finding is therefore a
convention observation, not a bug list**, and it is written into
`design/capture-unification.md` as the unified layer's first real content
("The conventions — what actually binds every camera").

*One theoretical hole recorded, deliberately not fixed:* `epoch_ms` collides
if two frames land in the same millisecond, and the writer doesn't check. At
~60 s cadence that's ~5 orders of margin. **Revisit before adding any burst
mode**, or if NTP can step the clock backwards mid-night.

**~~Work unit 1b — take delivery of the EOS tools~~ DONE 2026-08-12**
(astro `bac34ba`):
- **The `Immediate` sweep found three more, including the live path.**
  `bin/eos-capture` had a *bare* `Immediate` with **no matching release** —
  worse than the `eos-focus-sweep` case fixed on 08-10. `eos-sequence` and
  `eos-star-watch` had the mismatched press-Immediate/release-Full pattern.
  All now on Press Full / Release Full; no bare `Immediate` remains. This
  vindicates the "fix applied where it bit, not swept" suspicion exactly.
- **Dormancy marked, with a distinction that nearly went wrong:**
  `eos-focus-cycle` is **half dormant** — its `d`-grid is retired but
  `--no-focus` is the live nightly path armed by `eos-focus.service`. The
  three wrappers are dormant outright. Nothing deleted.
- ~~astro-canon left files staged-but-uncommitted~~ — checked, clean.

**Next up (suggested):** eclipticam v1 → shared module, the multi-camera-per-host
case. The audit gives a concrete reason to touch v1 anyway: its `max(seq)+1`
directory scan is O(frames) per write and is the one naming scheme that would
*not* survive two writers on the same hour dir — worth retiring in favour of
the house `epoch_ms` convention when it migrates.

**Then, the shortened migration ladder** (design's order, corrected for what is
already done and for starcam's retirement):
- **eclipticam v1 → shared module.** Now the most interesting migration, not
  skycam: it is the multi-camera-per-host case (v3w's mode gates whether v1
  captures at all), which is what `astro/capture/host.py` is *for*. The design
  warns this boundary is a hard part — get it wrong "and every camera will start
  sprouting cross-camera hooks".
- **skycam → shared module.** Cosmetic class; validates the `"exposure_us":
  "auto"` AE path. Still living in `Berrylands/gardencam`. Production camera —
  the design's rule stands: migrate one at a time, leave the old daemon running
  until the new one shows a full clean week, don't refactor in place.
- **Move daemons out of `Berrylands/gardencam` into `astro/`.** Once skycam is
  the last thing there, gardencam can probably retire.
- `uploader.py` / `modes.py` / `host.py` / `__main__.py` crystallise **through
  use**, per the design's own instruction — not up front.

**Open questions:**
- ~~Does the EOS ever join the unified capture module?~~ **SETTLED 2026-08-11
  (Peter): share the conventions, not the code path.** See "How unification
  works" below — this is the strand's architecture, not just an EOS ruling.
- ~~Who owns the canon's capture-side code?~~ **SETTLED 2026-08-11 (Peter):
  astro-capture owns the EOS capture tools.** See the ownership section below.
- Design doc's own opens, still open: `host.json` per-host or fleet-level;
  mode-trigger DSL (string expr vs structured — design leans structured); where
  the sun-altitude calc lives (probably a new `astro.location`).

## Decisions

- **Strand kind = development** (2026-08-11) — see top. Not a keeper yet.
- **`astro/design/capture-unification.md` is adopted as this strand's backlog**
  (2026-08-11). The strand dir holds curation only; the design doc and the code
  stay in `~/astro`, which is where changes commit.
- **Hardware ideas redirected, not promoted** (2026-08-11, honouring the
  2026-08-09 triage note): keep-camera-cold / thermal dark current / Peltier
  experiments / shroud + box / servo-driven cover are **per-device hardware**,
  so by the three-layer split they belong in the relevant `astro-<camera>`
  keeper, not here. Spooled to [[astro-canon]] and astro-polecam; IDEAS.md
  cleared. The one genuinely-this-strand idea in that inbox ("this is for the 4
  different cameras, general capture") is just the strand's own charter and needs
  no promotion.
- **The capture/delivery seam holds** (Peter, 2026-08-09): capture puts frames on
  disk and "should just work"; astro-science's adapter consumes that output and
  never reaches into it. A failure at delivery that turns out to be capture-side
  bounces back here / to the camera keeper.
