# astro-science — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->


the 3 live cameras are difficult to compare currently.  The deliverables and science needs a revamp so the true detail of the findings can be presented.  I'd also like a downloadable impress your friends pack


Meteor/transient detection is a MISSING DELIVERABLE — the pipeline currently throws them away.

Peter spotted meteors by eye scrubbing the 2026-08-10 sweeps (canon frames 109 + 117 of 329). Confirmed by falling back to individual subs: TWO single-frame events —
  23:51:42 UTC 2026-08-10 (54px, ang 150.4)
  00:05:14 UTC 2026-08-11 (97px, ang 85.8)
Each present in EXACTLY ONE 30s sub, absent from neighbours => genuine transients, not satellites/aircraft (which step across consecutive subs). Perseid build-up (peak Aug 12-13); different angles => independent events. astrocam caught one the same night too, so BOTH cameras saw them.

THE GAP: the accumulator outlier-rejection design classes meteors WITH planes and cosmic rays as 'non-sidereal => reject' so they don't co-add. Correct for the accumulator — but it means a real detection is DISCARDED, never catalogued. And the catalogue's confidence model is built on PERSISTENCE, the one property a one-frame transient lacks by definition. So transients currently fall through every crack in the science layer.

PROPOSED: a transient deliverable that runs on the SAME non-sidereal test already specified for rejection — reuse the machinery, invert the disposal. Reject from the stack AND emit to a transients table (t_utc, camera, x/y, angle, length, peak, ablation profile). Single-sub presence is the discriminator and it is cheap: my crude detector found both events in one pass over 13 subs.

WHY IT MATTERS: 'what does a year-scale urban dataset yield' is this strand's whole question, and meteor RATE vs shower calendar is a real result an all-night all-sky archive can produce that a targeted telescope cannot. Two cameras seeing the same night also opens crude triangulation.

CAVEATS: sweep windows are 10-min stacks and SMEAR the brightness profile — I misread the 117 streak as a flat-profile satellite from the stack; the single sub proved it transient. So any classifier must run on SUBS, not sweep frames. Ablation profile (brighten-then-fade) needs raw CR2 not JPEG for the highlight range.

Staged frames: ~/tmp/meteor-0810/w109 + w117 (time-named full-res JPEGs for splay).


splay launch/IPC gotchas hit while viewing the 2026-08-10 meteor subs (2026-08-11):

1. IPC command syntax is 'key:NAME' with a COLON, not a space. 'splay --send "key space"' and 'splay --send "key RIGHT"' are both rejected as 'unknown command'; the correct form is 'splay --send key:RIGHT' / 'key:HOME'. Names are pygame K_ names without the prefix. Only 'open', 'clear' and 'key' exist — there is no 'pause' or 'goto' command, so positioning on a specific frame means HOME then N x key:RIGHT.

2. A splay started as a plain background job DIES when the launching shell exits — the socket vanishes and '--send' then reports 'no running instance'. Launch it with setsid + nohup + </dev/null + disown to survive. This matters for any agent/script that starts splay in one tool call and drives it in a later one.

3. --no-autoplay is what you want when opening a set to inspect a SPECIFIC frame; otherwise it starts playing immediately and you have to catch it.

Possible tool improvement: a 'goto <basename-or-index>' IPC command would remove the HOME+N-arrows dance, which is fragile (miscount and you are on the wrong frame with no feedback). Also worth having '--send help' list the valid commands instead of rejecting 'help' as unknown.


CONTRAIL is a missing class in find-transients (Peter, 2026-08-12: 'the meteor looks like a contrail' — he was right).

Candidate was EOS 2026-08-11 sweep frame 312/339. Verdict: CONTRAIL, not meteor. Evidence from neighbouring sweep frames (305, 311, 320, 330):
- ABSENT in 305 and 311, PRESENT in 320, still present but visibly BROADENED and diffused by 330.
- Crosses the whole frame, both ends off-screen.
- Diffuse soft edges, not a thin hard filament; same lit-cloud quality as the skyglow-lit cloud around it.
- These are the last frames of the night (sky mean 84->123 across them) so it is lit from below by DAWN TWILIGHT.

A meteor lasts <1s and is in exactly ONE sub. This persists over many minutes AND SPREADS.

THE GAP: design/transients.md and find-transients only know satellite vs meteor. A contrail scores ends_touching=2 and persists>>1, so it lands as 'satellite' — harmlessly (it is correctly rejected as non-meteor) but WRONGLY classified. Aircraft/contrails are also named in accumulator-outlier-rejection.md as things that must not co-add, so the estate already cares about them.

PROPOSED discriminator — WIDTH GROWTH OVER TIME. It cleanly separates the two persistent classes:
  satellite : thin, CONSTANT width, moves position frame to frame, ends off-screen
  contrail  : starts thin then BROADENS and softens, drifts slowly with wind, ends off-screen
Measure perpendicular FWHM per sub and fit d(width)/dt; a positive trend is a contrail. Also: satellites traverse the field in a single sub (they streak); a contrail is stationary-ish and persists across subs as a STATIC feature.

Also worth noting the contrail is a genuine CLOUD-VERDICT concern, not just a classifier one: it is a lit linear cloud, so it lifts the frame mean and could pull an otherwise-clear night toward 'cloudy' — related to the pedestal/scs double-duty trap.

NB the eyeball trap keeps repeating: this looked meteor-like in ONE sweep frame; only the NEIGHBOURING frames disproved it. Same lesson as 'sweep frames cannot classify' — but note here the neighbours in the SWEEP were sufficient, no need for subs, because persistence over minutes is exactly what a stack shows well.


nightly-cam:277 still defaults night = args.night or last_completed_night() — same dawn/noon trap as the canon-nightly bug (876a45c). Harmless today because canon-nightly always passes explicit --night, but it is a loaded gun if nightly-cam is ever scheduled directly or run by hand at dawn. Consider making it match canon-nightly's night_of()+fallback, or refuse to default at all and require --night.


DETECTOR CALIBRATION INVERTED -- measured 2026-08-13 against Peter's 38 splay
probes (the first real ground-truth set; "the mouse is within 30px of the
meteor").

RESULT: recall 1 HIT / 37 miss. 16 probes landed in frames where the scan found
NOTHING; 21 matched only a feature 200-750 px away, i.e. something else. The
single hit was npx=43 -- inside the very population I had proposed to threshold
away as noise.

WHY: at three missed probes the signal IS there and IS above threshold --
local diff max +118/+104/+95 vs thr ~+34, comfortably 3x over -- but each
raises only 5/9/12 pixels above it. MIN_PX=40 discards all of them.

SO THE SIZE MODEL WAS BACKWARDS. I had argued real meteors were the big
features (the confirmed 135 px and 2598 px events) and that the dense 40-70 px
population was a noise shoulder to cut. In fact the two bright ones are rare
outliers and Peter's ~20 typical meteors are SHORT FAINT streaks of a handful
of pixels. That is why he found so many by eye, and why "often 2 on 1 frame"
is plausible rather than absurd.

CONSEQUENCE: npx (area) is the wrong discriminator at the faint end -- a real
meteor and a noise clump can both be ~10 px. Needs a different axis:
  - SHAPE at low pixel counts: even 8 px in a line is collinear; noise clumps
    are not. PCA elongation on the raw suprathreshold pixels, no MIN_PX gate.
  - PEAK/CONTRAST rather than area: these sat 3x over threshold.
  - the estate's existing geometric test (both ends interior) still applies.
  - median-subtraction across the night (STATE's blocking fix) is still the
    right way to drop the floor so faint streaks clear it by more.

METHOD NOTE: this is the third time eyeballing beat the numbers (foliage run,
08-11 contrail, now this). The probe log is the asset -- 38 graded points
beats any amount of tuning on 3 frames. Grade FIRST, tune second. Also: match
probes to the streak's EXTENT, not its bbox centroid; a 224 px streak clicked
near one end is ~110 px from its centre and scores a false miss.


EPOCHS PAGE -- the HISTORICAL picture, which is bigger and messier than the
"current epoch" badge suggests (Peter, 2026-08-13: "the historical situation -
v1 astrocam for the first few weeks"; "astrocam has had 3 cameras as I
recall"; "eclipticam has 2 cameras but the v1 is currently not used").

MEASURED FROM DISK + FITS HEADERS (astrocam-frames, 62 nights):
  epoch 1 av2  imx219 3280x2464 BGGR : 47 nights 2026-06-08..2026-07-28 = 76%
  epoch 2 av3s imx708 4608x2592 RGGB : 15 nights 2026-07-29..2026-08-12 = 24%
So "the first few weeks" UNDERSTATES it: the v2 era is the MAJORITY of the
astrocam archive by 3:1. The epochs page is therefore not a status badge
("we are on epoch 2") but a MAP OF AN ARCHIVE THAT IS MOSTLY NOT THE CURRENT
CAMERA. Any year-scale result that spans 2026-07-29 crosses a hard calibration
boundary; that is this strand's central question, so the page is load-bearing
science documentation, not decoration.

EPOCH 1 FRAMES CARRY NO POSINDEX AT ALL. The header was introduced WITH epoch 2
(first seen 2026-07-29). Checked 2026-06-10 / 07-01 / 07-20 / 07-28: all
POSINDEX=None, CAMERA=imx219. So 76% of the archive is epoch-UNSTAMPED and its
epoch is inferable only from sensor/resolution/bayer. The page should say this
plainly, and any epoch-aware tooling must FALL BACK to sensor+resolution rather
than trust POSINDEX to exist.

THIRD ASTROCAM CAMERA -- UNRESOLVED, ASK PETER. The registry has 2 entries and
the frame headers show exactly 2 sensors (imx219 -> imx708 at 07-29); no av3w
or third label anywhere in the repo. But a swap of one v3 module for another v3
would NOT change CAMERA=imx708, so a third PHYSICAL camera could be invisible
in the data. If there was a third, the registry is incomplete and the page
would be publishing a wrong history. Resolve before building.

ECLIPTICAM IS MODELLED DIFFERENTLY -- and has NO epoch mechanism at all:
  eclipticam/camera.json, eclipticam-v1/, eclipticam-v3w/ ALL have
  position_index=None and NO position_registry. The epoch system was only ever
  applied to canon + astrocam.
  Its two cameras are SEPARATE CONFIG FILES, not epochs, because both are
  physically present on ONE Pi simultaneously (v1 = OV5647 2592x1944,
  v3w = IMX708 4608x2592). Confirmed 2026-08-12: only v3w/ has frames; v1 is
  IDLE (Peter: "the v1 is currently not used").
  => The page needs TWO concepts, not one: SUCCESSION (astrocam/canon: epoch N
  replaces N-1 in time) and COEXISTENCE (eclipticam: two cameras on one host,
  one currently dormant). A single "current epoch" field cannot express the
  second.

ALSO A LIVE CONFIG BUG (not just docs): astrocam camera.json still carries
plate_scale_deg_px=0.019 and pole_prior_xy=[1945,1823] -- which the registry
itself records as the EPOCH 1 (av2) values -- while plate_scale_notes and
pole_prior_notes both say "STALE ... INVALID after the imx708 swap ... must be
re-solved". So the CURRENT camera is running with the OLD camera's geometry in
live config. (pedestal is fine: live 50 is a deliberate 2026-08-01 winter-
footroom re-derivation that supersedes the registry's 105.) An epochs page
rendering registry-vs-live would surface exactly this class of drift.


that's ok we can workout the epocs from the images, it's just that I want to do all time sweeps of the data.  I've got an idea...

[KEPT UNTRIAGED 2026-08-16 — the idea itself was never captured. Searched the
session archive: no elaboration anywhere, and the ideas/ spool is empty. Only
Peter has it. ASK NEXT SESSION.
Partial progress that may or may not be the same thought: an all-time sweep
crosses the 2026-07-29 imx219->imx708 boundary, and quaternion epoch
composition (camera-moved-signal.md's "all epochs land on ONE sphere") is what
makes that well-posed. See STATE "THE MAP — geometry layer settled 2026-08-16".]


[TRIAGED 2026-08-19 — the WHOLE-DATASET QUALITY PASS and its CROSS-REF are
now folded into STATE.md ("Whole-dataset quality pass"). The epoch model they
asked for is MEASURED: three capture modes, identified by saturation ceiling
(the POSINDEX-absent fallback this entry needed), and the epochs are on one
photometric scale via a single 1.54 scalar. Still open from below: the THIRD
ASTROCAM CAMERA question (Peter only), the epochs PAGE itself, and Peter's
unstated "I've got an idea" for the all-time sweep.]
