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

## Pending / loose ends

**Work unit 1 — the frame-naming / run-tag audit across all cameras** (do this
first). Cheap, cross-cutting, cashes in the canon lesson, and it proves the
strand reads *across* devices before it tries to refactor daemons. Questions:
can `astrocam_v3_night_daemon` / `v3w_night_daemon` restart mid-night, and if so
do their stems collide? Is there a shared naming convention or three? Outcome
should be a stated **pipeline rule** (run-tagged stems; one capture = one
frame), owned here, applied everywhere — not three local fixes.

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
- **Who owns the canon's capture-side code?** `canon-nightly` is explicitly
  DELIVERY (astro-science) and says so in its header; astro-canon is the device
  keeper. The EOS capture tools (`eos-capture`, `eos-focus-cycle`, `eos-sequence`,
  `eos-night-watch`) are the *capture* half and by the three-layer split belong
  here — but are not currently claimed by anyone. Settle with Peter.
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
