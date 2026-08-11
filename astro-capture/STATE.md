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

**Consequence for the focus regime:** the `d`-schedule machinery
(`eos-focus-cycle`, `eos-focus-sweep`, `eos-focus-tonight`, `eos-star-watch`) is
now **ours and largely dormant** — astro-canon retired the `d` apparatus on
08-10 (focus by eye at "marker 0", lens on MF, nights run `--no-focus`), having
established that `d` tracked nothing. Do **not** delete these: the sweep tooling
is how a *future* body or a re-seated lens would be re-characterised, and
`eos-focus-cycle` is where `RUN_TAG` lives. But they should be clearly marked
dormant/calibration-only so nobody mistakes them for the nightly path. The live
nightly capture path is `eos-capture` + `--no-focus`.

## Pending / loose ends

**Work unit 1 — the frame-naming / run-tag audit across all cameras** (do this
first). Cheap, cross-cutting, cashes in the canon lesson, and it proves the
strand reads *across* devices before it tries to refactor daemons. Questions:
can `astrocam_v3_night_daemon` / `v3w_night_daemon` restart mid-night, and if so
do their stems collide? Is there a shared naming convention or three? Outcome
should be a stated **pipeline rule** (run-tagged stems; one capture = one
frame), owned here, applied everywhere — not three local fixes.

**Work unit 1b — take delivery of the EOS tools** (falls out of the 08-11
ownership ruling, and pairs naturally with the run-tag audit since `RUN_TAG`
lives in one of them):
- **Mark the `d`-schedule tools dormant/calibration-only** in their own headers
  (`eos-focus-cycle`, `eos-focus-sweep`, `eos-focus-tonight`, `eos-star-watch`)
  so the retired regime cannot be mistaken for the nightly path. Keep them.
- **Check for stale `Immediate` usage across all 9 owned tools.** `eos-focus-sweep`
  had it (fixed 08-10, astro `c7132b9`) and it *wedges this body*; the fix was
  applied where the bug bit, not swept. Same class as the run-tag gap.
- **`eos-capture --no-focus` is the live nightly path** — confirm nothing else is
  still armed to drive focus (see [[eos-focus-by-viewfinder-marker-0]]).
- ~~astro-canon left `eos-focus-cycle` / `eos-power` staged-but-uncommitted~~ —
  **checked 2026-08-11: both committed and clean.** astro-science's 08-09 note
  about "untouched capture files left staged by their own strand" was overtaken
  by `c7132b9` the next day. Nothing to rescue; noted so the stale claim does not
  get re-inherited.

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
- **Does the EOS ever join the unified capture module?** gphoto2/USB vs
  picamera2/CSI is a real architectural gap, and forcing it in may cost more than
  it buys. But the run-tag lesson shows the *conventions* (naming, session
  structure, one-capture-one-frame) should be shared even if the *mechanism*
  cannot be. Provisional lean: share the conventions, not the code path.
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
