# astro-canon — state

*Curated summary of where this strand is. Updated at the end of each session.*

## ★★★ BEST NIGHT YET — 460 frames, zero wedges (2026-08-10 → 11)

**The camera worked all night, unattended, for the first time.**

| | 2026-08-10 | previous fortnight |
|---|---|---|
| frames | **460** | 96–135 |
| span | 22:03 → 04:37 (6.6 h) | 3.0–5.3 h |
| rate | **70/h** | 26–44/h |
| wedges / recoveries | **0** | routine |
| restarts | **0** (one run tag) | frequent |
| focus drift | none — FWHM 2.25–2.63 px, first frame to last | unmeasurable |

15 GB, RAW to `eos-frames/2026-08-10/`, JPEGs to `eos-frames-live/2026-08-10/jpeg/`.
The recovery ladder never fired, so the plug remains UNTESTED in anger.

## ★★★ FOCUS SOLVED — by eye, through the viewfinder (2026-08-10)

**Peter set focus by hand with the lens on MF, looking through the optical
viewfinder.** That datum is **"marker 0"**. It beat every automated method
outright:

| method | edge/std |
|---|---|
| driven `d`-schedule, all day | 0.035 |
| best metric-guided ring bracket | 0.055 |
| **viewfinder by eye** | **0.151** |

Confirmed on stars that night: median star FWHM 2.25–2.63 px across 6.6 h.
A distant-treeline focus DID transfer to true infinity — no nudge needed.

**Do not drive focus on this body.** The lens stays on MF; the ring stays put.
The night runs with `--no-focus`, which never racks and never drives — *not even
after a power cycle*, since a rail-drop cannot move a mechanical ring. That is
also what makes leaving recovery armed safe: a reset can no longer cost the focus.

### `d` never tracked focus at all
The whole `d` apparatus was measuring nothing. Sharpness on 2026-08-08 split by
**pass** (p2/p3 ≈ 205, p1/p4 ≈ 53–73), not by `d` — every `d` from 5 to 15
averaged the same, with within-`d` spread larger than any between-`d` difference.
All V-curve/peak conclusions in the older sections below are WITHDRAWN.

## ★★★ THREE BUGS FIXED (2026-08-10, astro `c7132b9`)

1. **Burst firing — the big one.** Drive mode is Continuous Shooting, so a held
   full press fires continuously. The old capture held the press for the WHOLE
   download window (30s+ at night); a 2s hold measured **~20 frames**, a 1s hold
   3 — and exactly ONE was ever downloaded. The rest was pure shutter wear on a
   body rated ~100k actuations. Now: press, release after **0.2s**, then
   download. One frame per capture. (~460 actuations last night, not ~9,000.)
2. **Restart stem collision** — pass numbering restarts at 1 after an abort, so
   a re-run silently overwrote the previous run. Stems now carry a per-run UTC
   `RUN_TAG`; verified two runs into one dir grow it. This bug destroyed ~1,000
   frames on 07-28 and, on 08-10, the only frames containing an aircraft.
3. **`eos-focus-sweep` used `Immediate`** (which wedges this body) paired with a
   mismatched `Release Full`. Now Press/Release Full + burst-tolerant handling.

Also `splay` (`2ea92bc`): the probe line now records `RES=` and
`VIEW=<zoom>+<panx>,<pany>`, and the help states that x/y are **native
full-res source pixels which must NOT be rescaled** — that was true before but
undocumented, and cost a long detour hunting a plane at x=6562 in a 6000-wide frame.

## ✔ CAMERA BACK — it was a worn USB socket (2026-08-10)

The "camera off the bus" and the escalating wedges were **mechanical**: muppet's
USB2 socket had gone loose from heavy use. Peter moved the camera to a **USB-C
port via an adapter + USB3 hub**; it enumerated at 480M and a config write stuck
first time. Mechanical wear ramps continuously, which is exactly the
rare→constant shape a software change never would have.

**The measurement that cracked it:** frames/night were FLAT (96–135) while the
rig degraded — a dying camera gives falling yield. What actually decayed was
frames/HOUR (38–44 → 26–35) and night start time (22:30 → 00:22–00:51). The
recovery ladder was working and hiding the fault from the frame count.
Check `lsusb -t` link speed (must be 480M) and suspect the PHYSICAL path before
building firmware theories.

**Still open:** the Matter smart plug is unreliable (found switched OFF mid-day
2026-08-10, which produced a fake "wedge + failed recovery" cascade). A Zigbee
replacement is on order (~2026-08-13). Recovery stays ARMED meanwhile — an
intermittent reset beats none, and `eos-power` verifies by USB Dev number so a
lying plug reports rc=3 rather than being mistaken for a camera fault.

## ★★★ PLUG REPLACED + power-cycles now VERIFIED (2026-08-09)

**Smart plugs have proved outrageously unreliable — the reset path now checks
the plug's work instead of trusting it.**

**The plug swap.** The Currys Sandstrom (node 4) was binned and replaced with a
**Realwe Innovation plug, node 7** (commissioned in [[home-automation]], which
also rewrote `eos-power` to resolve the plug by **VENDOR** — `MATTER_VENDOR=
'Realwe'`, attr 0/40/1 — with `MATTER_NODE=7` only as fallback, so future swaps
need no code edit. **Match vendor, not product**: the node-4 ghost still on the
fabric is also named '...Smart Plug'.)

- **muppet was running a STALE `eos-power`** — hardcoded `MATTER_NODE = 4`,
  pointing at the dead ghost node. The vendor-resolving rewrite existed only in
  `~/astro/bin/` and had never been deployed, so the reset path was down on
  muppet regardless of which plug was fitted. **Deploying is a separate step
  from editing — check muppet's copy, not just the repo.**
- New plug verified end-to-end: `eos-power cycle` → rc=0, camera **Dev 107 →
  108**. Mains switching still drops the 12V rail through the DR-E10 adapter and
  **10 s is still sufficient** — no `--secs` bump needed for the Realwe.

**THE REAL FIX — `cycle` now VERIFIES the rail dropped** (astro `a778bfd`).
A genuine power cut forces the camera to re-enumerate with a **NEW USB Dev
number**; `eos-power` records it before and confirms it changed after. Until
now, `eos-power` returned rc=0 as soon as the WebSocket command was *ACKed* —
so **a lying plug and a genuinely uncurable wedge were indistinguishable**, both
surfacing as `post-cycle: STILL WEDGED`. New exit codes:

| rc | meaning |
|---|---|
| 0 | cycled **and verified** (Dev changed) |
| 2 | plug unreachable / command failed — the reset never ran |
| 3 | **PLUG LIED** — ACKed but Dev unchanged; mains never dropped |
| 4 | camera never came back on the bus |

`eos-focus-cycle` treats **rc=3 as a plug fault, not a camera fault**: it
**refunds the power budget** (nothing was reset, so a working plug later in the
night keeps its cycles) and Slacks that the reset never happened. The STILL
WEDGED alert can now say *positively* that the rail did drop — i.e. a genuine
power-resistant wedge. Both paths tested on hardware: real cycle → rc=0 (Dev
108→109); `--secs 0` (too short to drop the rail) → **rc=3 PLUG LIED**.

**2026-08-08 night — 104 frames, then two aborts; VERDICT SUSPECT.** Ran
22:07→02:26 well: **104 CR2 + 108 JPEG** in `~/tmp/canon-focus-nightly/
2026-08-08/`, four passes, wedges clearing normally. From 02:26 cycles started
returning `STILL WEDGED`; breaker aborted at **02:58**, and the 03:13 restart
repeated it and aborted **03:53** (`NRestarts` 21). **But this ran on the dying
Sandstrom**, which vanished from Wi-Fi at 08:43 the same morning (CHIP Error
0x32 timeouts → "Marked node as unavailable" 08:45 → "considered offline"
09:29; never in homepi's ARP table; homepi itself up 35d, matter-server 13d, HA
5w — infrastructure was fine, the plug was not). **3 RECOVERED / 4 STILL WEDGED
interleaved within one hour is the signature of a flaky plug, not a dead one** —
a dead plug fails every time. So last night's failures are **more likely plug
flakiness than a new cure-resistant wedge class**, and should NOT be taken as
evidence of one. Tonight's run on the Realwe arbitrates — and now, whichever it
is, the logs will say which.

**Do NOT raise `--power-budget` yet.** It was pending, but more budget against a
lying plug buys thrashing, not frames. Revisit once cycles are provably cutting
power.

**Still unvalidated (home-automation's caveat, unchanged):** whether mains
switching clears a *genuine* Class-B wedge is STILL unproven on this plug —
today's test cycled a **healthy** camera, which proves the mechanism, not the
cure. Only a live wedge settles it.

## ~~FOCUS: `d` IS REAL~~ — WITHDRAWN 2026-08-10 (`d` never tracked focus)

**Peter reviewed frames 1–119 of the 07-28 night by eye (d-major order) and
marked the sharp ones. That verdict, not `eos-star-psf`, is now the reference.**

```
  d0 :  0/18       d3 :  0/38      <- 114 frames at d0..d4, NOT ONE sharp
  d1 :  0/19       d4 :  0/19
  d2 :  0/20       d5 :  1/5       <- first sharp frame appears at d5
```

- **`d` is a genuine, working coordinate.** A meaningless label could not
  produce 114 consecutive rejects and then sharp frames starting exactly at d5.
  d0–d4 sit at/near the far hard stop, past infinity — exactly as predicted.
  **This retires the "is d relative / decoupled?" worry**: the rack pins, the
  zero is real (the frozen-tail test of 2026-07-22 stands).
- **Sharp frames occur throughout d5–d9.** Of 20 metric-predicted-sharp frames
  Peter judged "most very sharp", spanning **d5, d6, d8, d9** — so the sharp
  region is genuinely broad and picking a middle value is sound. **d7 chosen**
  for capture (never itself judged — in the 07-28 schedule d7 only appears at
  i18/i21, inside the unreviewed block; d8 is the better-evidenced fallback,
  7 of the 20 sharp picks).

**THE METRIC CANNOT ARBITRATE FOCUS.** `eos-star-psf`'s cross-width correlates
**r = 0.964 with streak LENGTH**, at a fixed length/width ratio of ~2.13 — i.e.
it is measuring whole-blob size, not defocus. Cloud-glow counted as stars
inflates both axes together. This is the **compactness-filter blocker already
recorded on 2026-08-02 and never built**; until it is, treat every V-curve as
suspect. Peter: *"your metric is suffering from interference from clouds etc."*

**Therefore every pooled-frame focus conclusion is withdrawn**, including
"d8 sharpest, 2.54 px" and the three-peaks/d5-d8-d14 result — those pooled
frames across power cycles and cloud states. What survives is the by-eye
verdict above.

**Analysis traps hit this session (all cost real time):**
- **Absence of a mark ≠ judged blurred.** Statistics over unreviewed frames
  produced two confident, wholly false findings (a d-histogram "confirming"
  physics, and a "sharpness decays with pass position, zero after i12"). Always
  establish the reviewed WINDOW first and restrict to it.
- **The schedule confounds d with position-in-pass.** d8/d9 sit early (i00,
  i06, i09), d0/d1/d4/d7 only late (i14–i23) — so a naive d-curve partly reads
  slot, not focus. Any future comparison must control for seq_i.
- **`prev_d` is not free either** — the fixed comb means the preceding d is
  largely determined by the current one.

## ⚠ DATA LOSS: restart stem collision destroyed ~1000 frames (2026-08-09)

When the service aborts and restarts mid-night, **pass numbering restarts at 1**,
so the second run writes the same stems (`p01_i00_d15`) and **overwrites both
the CR2 and the JPEG** of the first run. Across the 15 nights: **2,518 manifest
rows survive as only 1,500 files.**

| night | rows | cr2 | collided |
|---|---|---|---|
| 2026-07-28 | 255 | 234 | **0** ← the only clean night |
| 2026-08-06 | 218 | 110 | 97 |
| 2026-08-07 | 198 | 101 | 87 |
| 2026-08-03 | 197 | 96 | 90 |

**Use 2026-07-28 for any analysis** — it is the only night with no collisions.
**Fix (not yet done): put the run start-time or a UUID in the stem** so a
restart cannot overwrite the earlier run.

## FRAMES SHIPPED to bigstore (2026-08-09)

All 1,500 CR2 + 1,543 JPEG + 15 manifests (51G) now at
**`/mnt/bigstore/astro-data/eos-frames/<night>/`** on muppet =
**`/mnt/muppet/bigstore/eos-frames/`** from pip, so nights are splayable over
NFS with no copy. Checksum-verified (0 content diffs on 3 sampled nights, 0
zero-byte files).

- **Nights 07-25 → 07-30 exist ONLY on bigstore** — a `--go` ship-and-free run
  freed them from the nvme after byte-verifying them. Everything 07-31 onward
  is duplicated. All data intact; those four just aren't in two places.
- Capture still writes to the **nvme** (`~/tmp/canon-focus-nightly/`), which
  never drops off the bus; ~22G/night at the fixed-focus rate, 78G free.
  **There is still NO recurring ship** — this was a one-shot copy, so the nvme
  grows unbounded. `eclipticam-ship-night --src/--dst` does the job and is the
  obvious basis for a nightly timer.
- **Bug fixed in `eclipticam-ship-night`** (super `998ec99`): `--keep N` larger
  than the number of nights protected **NOTHING** (bash returns empty for
  `${a[@]:(-N)}` when N > len), i.e. the exact inverse of the flag's promise,
  most dangerous when someone passes a big --keep to be safe. Now clamped.

## ~~PEAK HUNT~~ — SUPERSEDED 2026-08-10 (focus is manual now; `d` is meaningless)

Ran the d5–d15 peak-hunt schedule (2026-07-31 night, 105 frames, clean
autonomous run — **no wedges**, 21:44→03:18 UTC). Analysed with
`eos-star-psf 2026-07-31 --dmin 5 --dmax 15` + `eos-psf-view`. **Did NOT
bracket the peak** — and the reason is instructive:

- **The night was PARTLY CLOUDY** (Peter: clear only from ~02:10 BST /
  01:10 UTC to dawn, with a short cloudy bit even then). The by-d **stamp
  grid is the giveaway**: d5/d8/d9/d14/d15 rows = crisp diagonal star
  streaks; d6/d7/d10/d11/d12/d13 rows = big amorphous **orange glow blobs**
  = cloud, which the detector wrongly counted as fat "stars". So the
  V-curve's d10–d13 hump is CLOUD, not defocus.
- **Restricting to the clear window** (frames ≥01:10 UTC) sharpens it but
  can't fully clean it (the cloud was intermittent, hitting scattered
  passes): clear-window medians d5 4.1, **d9 3.64**, d14 **3.16**, d15 4.23
  px — with a noisy 7–9 px hump still across d10–d13 (residual cloud).
- **What we CAN trust:** **d9 sharp on three independent measures now**
  (07-28 shelf, 07-31 all-night, 07-31 clear-window) — solid. **d14 also
  reads sharp** (3.16 px, 732 clean stars) — a real new signal, not
  obviously cloud. **Still no clear turning point**: d15 (4.23) is barely
  above d14, so the far edge isn't past the peak. Either the sharp region
  is very broad (d9–d14) or there's field-dependent focus.

**THE BLOCKER (root cause, now clear): `eos-star-psf` counts cloud-glow as
stars.** A diffuse bright blob (cloud lit by LP) is large, round, low-
gradient — nothing like a compact star streak — but it passes the current
area/peak filters. A time cut only partly removes it. **Fix = a
COMPACTNESS filter** (reject large low-gradient / low-elongation blobs;
the streak vs blob distinction the stamp grid shows by eye). This both
salvages last night AND makes every future partly-cloudy night usable.
Recommended next step (Peter leaning yes, not yet greenlit): harden the
detector, re-run 07-31, then a clear night confirms.

## ~~FOCUS MEASURED — d8 sharpest~~ — WITHDRAWN 2026-08-10 (metric measured cloud/blob size)

The pending "full-res CR2 PSF analysis" is **built and run** — the designed
next-day pipeline is now two real tools (astro `1246766`), and the answer is in.

**Tools (astro/bin, deployed to muppet ~/bin):**
- **`eos-star-psf`** (runs on muppet — has rawpy) — measures focus on the
  **LINEAR GREEN Bayer plane**: no demosaic (so no moiré / interpolation smear;
  green alone is faithful on this fine sensor — Peter's call, no R/B WB scaling).
  30 s subs **trail** the stars ~5–8 px, so a round FWHM would measure the drift,
  not focus. Metric = the streak's **CROSS-width** (minor PCA axis) — trailing-
  immune. Reuses `fit-distortion-trails`' extraction idiom (asinh stretch →
  threshold → label → per-blob PCA). Masks the fixed reflection at ~(1170,1585)
  and the bottom foreground band. Writes `psf.csv` + `psf.npz` (star stamps).
- **`eos-psf-view`** (runs on pip — has matplotlib) — renders the heat maps:
  per-star stamp grid, **by-focus-d stamp rows** (the money plot), cross-width-
  vs-(x,y) field map, and the V-curve; opens in splay. **Split by design:** raw
  decode near the data (muppet), plotting near the display (pip); muppet has no
  matplotlib and doesn't need it.

**Result (2026-07-28 night, 234 frames):**
- **d8 sharpest at 2.54 px cross-width**, on a **flat d5–d9 shelf**
  (d5 2.60, d6 3.67, d8 2.54, d9 3.70 px). **Confirms Peter's by-eye pick of
  d8.** ~2.5 px best vs ~30 px first-light defocus = **12× tighter**.
- **The V-curve zigzag (d4,d7 spikes to ~6 px) is a SAMPLING ARTIFACT, not
  focus.** The d-schedule samples d3/d6 heavily (43 frames) but d4/d7 lightly
  (20) → the sparse d's have 73–229 stars vs ~2000 for the well-sampled d's, and
  their medians are polluted by foreground glow that leaked the filters. **Trust
  only the well-sampled d's** (d5,d6,d8,d9). The by-d stamp grid shows this
  starkly: d5/d6/d8/d9 rows = clean bright diagonal streaks; d3/d4/d7 = faint
  dots + glow blobs.
- **Shelf never turns back up before d9** → **best focus may lie PAST d9** —
  extend the grid next night (deferred; not done this session).

**Gotchas banked building this:**
- **`measure_frame` was O(labels × pixels)** — a per-label `np.where(lbl==i)`
  loop over 555k noise labels (threshold too low) hung >120 s per frame.
  Fix: raise detection threshold (asinh sky-noise floor ~60 → default 150),
  and vectorise via `np.bincount` area-filter + `ndimage.find_objects`
  bounding-box slices (touch only real blobs). Now ~1 s/frame, ~3 s end-to-end.
- **Buffered stdout over ssh hides progress** — `python3` redirected to a file
  or piped over ssh buffers fully; a run looks hung when it's fine. Use `-u`,
  and to *watch* a long run, poll for the output **artifact** (psf.npz) not the
  log.
- **rawpy decode is only ~0.7 s/frame on muppet** (idle) — never the bottleneck;
  when a run drags, suspect the analysis (labels), not the decode.

## ★★★ STARS CONFIRMED + wedge autonomy proven in production (2026-07-26 → 07-28)

Two nights that closed the loop end-to-end.

**Night 1 (2026-07-26) — ⅔ lost to a PROBE-BLIND wedge; found and fixed.**
- Pass 1 perfect (24/24 frames), then wedged 23:18 UTC with a NEW flavour:
  config writes fail with **"PTP Timeout" / port timeout (-10)**, NOT the known
  0x2019/-110 busy signature. `wedged()`'s string blacklist didn't match → the
  recovery ladder NEVER ENGAGED → the relay never fired (Dev# unchanged all
  night) → breaker aborted every 15-min restart; paged 00:41 BST. 36 good
  frames survive.
- Morning: camera still wedged; **`eos-power cycle` CLEARED A GENUINE CLASS-B
  WEDGE** (Dev 014→015 at 480M, config writes stick, capture fires) — the last
  untested link in the autonomy chain, now proven on a real wedge.
- **Fix (astro `aa93424`, deployed to muppet): `wedged()` is SUCCESS-BASED** —
  ANY unclean config write (rc≠0 or any error text) counts as wedged; no
  signature blacklist to fall behind. Plus **forced escalation**: on the 3rd
  consecutive NO-FILE frame, `recover(force=True)` goes gentle-release →
  straight to power cycle even when the probe passes (grace window skipped —
  it polls the probe, which is blind by definition in this mode).
- Upstream research: this wedge is documented and UNRESOLVED on this exact
  body under all its names (gphoto2 #497 Rebel T7, #538 1500D, libgphoto2
  #979). muppet's libgphoto2 2.5.31 is newer than every affected report — no
  upstream fix exists; power-cycling is the only cure. Our Matter-plug
  autonomy is ahead of anything upstream.
- The 36 garden frames (aim was still low): salvage analysis confirmed **d9
  sharpest on rigid ~10–15 m targets** (matches the daytime car calibration);
  windblown foliage is useless as a focus metric in 30 s subs.

**Night 2 (2026-07-27, re-aimed at open sky) — 221 good frames, STARS.**
- Daytime aim-check: open sky, tree fiducial now bottom-LEFT (was b-right).
- Ran 22:38→04:09 (dawn): **221 good / 18 failed over ~10 passes**. The
  probe-blind wedge recurred ~every 90 min; forced recovery cleared it **5×**
  (~3 frames + 6 min each). Budget (4/run) ran out 02:54 → breaker abort +
  03:07 page → the 03:22 service restart (fresh budget) power-cycled,
  recovered, and shot to dawn. Total wedge cost ≈ 18 frames.
- **STARS CONFIRMED by drift**: the brightest source moves coherently
  ~12 px/min (sidereal) across hours of frames — e.g. (2092,854) 22:35 →
  (2348,660) 23:01 → (2658,366) 23:35 (half-res coords). First
  star-confirmed frames from the capture pipeline.
- **Fixed artifact at ~(1170,1585) half-res** — internal reflection/glow,
  same pixel all night, ~60–90 px across, peak ~70 after boost. It poisons
  any naive brightest-source metric; analysis tools must MASK it.
- **Focus V-curve is real.** Best-per-d FWHM (half-res JPEG; metric floor
  ~8 px from smoothing): d0–d4 = 26, 26, 20, 16, 11 → **SHELF 8–11 px across
  d5–d9**. The JPEG metric saturates on the shelf. d9 shows the highest peak
  concentration (hint only — different stars confound). Picking the winner
  inside d5–d9 needs **full-res linear-CR2 PSF fitting**; and the shelf never
  turns back up, so consider extending the grid PAST d9 next night.

**Pending (from these nights):**
- ~~Full-res CR2 PSF analysis of the d5–d9 shelf frames.~~ **DONE** —
  `eos-star-psf`/`eos-psf-view`; d8 sharpest on a flat d5–d9 shelf (see
  the focus-measured section above).
- ~~Mask the fixed artifact in the analysis tools.~~ **DONE** — masked in
  `eos-star-psf` (disc at ~(1170,1585) half-res, R=95).
- ~~Extend the d-grid past d9.~~ **DONE + ARMED** (astro `1e6ab39`) —
  `eos-focus-cycle`'s DEFAULT_D_SCHEDULE is now the **peak-hunt d5–d15**
  comb (drops always-blurred d0–d4, reaches 6 Near-2 steps past the old
  far end, keeps d5 as low anchor; every setpoint 5–15 gets a ~3-min pair;
  30 images/pass). Deployed to muppet and the **service was RESTARTED**
  (it's a persistent process that had the old schedule in memory — a
  redeploy alone wouldn't take until restart). Tonight's run will hunt the
  peak. **Next morning: `eos-star-psf 2026-07-31 --dmin 5 --dmax 15` then
  `eos-psf-view` — does the V-curve finally turn back up, and where?**
  (Physical note: if d15 hits the near hard stop those frames just repeat
  the stop — harmless, tells us the travel limit. Old d0–d9 comb still
  reachable via `--schedule` if the peak proves to be below d5.)
- Run `eos-star-psf` on **2026-07-27** too and check the d8 shelf
  reproduces across nights before fully trusting it (offered this session,
  Peter chose to bank the tools first).
- ~~Raise `--power-budget`~~ **ON HOLD (2026-08-09)** — the premise ("relay
  proven cheap and effective") no longer holds: the Sandstrom was ACKing without
  switching. More budget against a lying plug buys thrashing. Revisit once
  verified cycles (rc=0, Dev changed) show the Realwe reliably cuts power.
  Still open: suppress the page when a fresh-budget service restart is imminent.
- Why does the wedge recur ~every 90 min? Correlate with runtime / d /
  frame count — looks systematic, possibly long-exposure-count related.

## ★★★ CAPTURE PATH FIXED + tonight's run armed (2026-07-24 session)

Three real capture bugs found and fixed — these had been silently sabotaging
every capture-heavy session (they're why escalation was disabled and why the
camera kept wedging). All committed to astro, deployed to muppet, validated on
real captures:

1. **`eosremoterelease=Immediate` → AF-lock wedge (THE big one).** `Immediate`
   triggers autofocus *before* firing; on a dark/blank sky **AF cannot lock**,
   so the shutter hangs half-pressed and the camera wedges busy (`0x2019 PTP
   Device Busy` / `-110 I/O in progress`) — a Class-B firmware wedge only a 12V
   pull clears. **Fix: `eosremoterelease="Press Full"` (fires directly, no AF
   wait) + always `"Release Full"` after.** This supersedes the old
   `Immediate`+`None` idea (a held Immediate also wedges, but the AF-lock is the
   root cause). Applied to eos-focus-cycle, eos-psf-dither, eos-night-watch.
2. **Lowercase `%C` case mismatch (the real "capture/download failed").**
   gphoto2's `--filename …%C` expands to a **lowercase** extension
   (`probe_000.cr2`), but the tools looked for uppercase `.CR2` → `os.path
   .exists` failed on every good frame → every probe logged "capture failed"
   and `--once` exited having done nothing. **Fix: case-insensitive `_find()`.**
   THIS, not the wedge, is why the focus runs produced no data early on.
3. **`fullres` brittleness** — hardcoded `==(6000,4000)` embedded-JPEG match and
   unconditional `open(.CR2)`. Fixed: take the **largest** embedded JPEG; don't
   crash when a JPG/CR2 is absent (the old "missing-file crash").

**Camera-handling lesson: NEVER `pkill -9 gphoto2` mid-capture.** It killed the
process holding the PTP session while the shutter was pressed (before Release
Full) → instant wedge. The tools' own Press→Release flow is safe; only forced
mid-flight kills strand a held shutter. To stop a run cleanly, `systemctl --user
stop <unit>` (lets the current frame finish) — don't kill -9 gphoto2.

## ★★★ The "cloud" all evening was the CAMERA POINTING AT THE CEILING LIGHT (2026-07-24)

A humbling correction. Repeated "clouded out / 93% full flat raw" verdicts were
**wrong** — the sky was clear and star-rich all night (astrocam pulled loads of
star trails, `petergrecian.co.uk/astro/astrocam/night/2026-07-23`, colour-sweep
video). The EOS was **pointed indoors at the room's ceiling light + lampshade.**
The bright diffuse glow filling every frame = the ceiling light; the hard-edged
blob at frame bottom = the lampshade; 93% well-fill = an indoor lamp, not LP
cloud. **A bright-flat raw is NOT necessarily cloud — it can be wrong aim / a
local light source.** The brightness metric cannot tell "LP cloud" from "indoor
lamp"; both saturate. astrocam sharing the garden is the cross-check: if the EOS
lacks stars astrocam has, suspect the EOS rig (aim/focus/foreground), not the
weather. **Fix applied by Peter: surrounded the camera with black paper** to
kill stray light; camera to be re-aimed at open sky.

## Tonight's capture design — `eos-focus-cycle` d-schedule (2026-07-24)

Peter's design, built and validated end-to-end (raws + boosted JPEGs +
manifest + dawn-safe loop all confirmed on real captures):

- **`d` = MEDIUM (Near-2) steps from the ∞ hard stop.** Star focus is in
  **d=0..9** (d=9 = daytime play-car focus; true star focus a hair inside that,
  ~7–9, since ∞ is slightly *far* of 15 m). Medium-only for now — **Near-1 fine
  dither deferred** until the sharpest d is known.
- **Pairing constraint:** need same-d images ~3 min apart for motion/blink star
  confirmation (stars drift, hot px don't). At ~1 image/min, a group of 3 foci
  shot twice puts each d's pair 3 images (~3 min) apart.
- **The swapped d-schedule (24 images/pass):**
  `9 6 3 · 9 6 3 · 8 5 2 · 8 5 2 · 6 3 0 · 6 3 0 · 7 4 1 · 7 4 1`.
  Groups of 3 spaced by 3 (max spread); each group shot twice → 3-min pair per
  d; groups walk the comb down to cover d=0..9. The **630-before-741 swap**
  evens out the twice-sampled d=3 & d=6 (their inter-pair gap 14→8 min).
- **Re-rack every image** to the far stop → d×Near-2 (hysteresis-consistent,
  Peter's choice — costs ~45s/image drive overhead, ~85s/image total).
- **Sun gate (astrocam-style):** waits for sun < −12° (nautical dark) before
  starting, stops at dawn (sun > −9°). Dependency-free NOAA sun-altitude formula
  (muppet has no ephem). Surbiton 51.395°N/−0.292°E baked as default. Tonight's
  dark window ≈ **22:45 → 03:45 BST (~5h)** → **~210 images, ~8–9 passes**, each
  d ~8–16 subs.
- **Deliverables = boosted JPEGs stretched from LINEAR raw** (percentile 50–99.9;
  faint stars emerge from below the JPEG tone curve — first-light lesson), in
  `out/jpeg/`, **named d-FIRST: `d03_p01_i00.jpg`** so `splay out/jpeg/` groups
  every frame of one focus-d together in time order → **blink a d-block to see
  stars drift.** Raw CR2s stay pass-first (capture order). manifest.csv logs
  t_utc, pass, seq_i, d, got_file, jpeg per frame.

## ★★★ ARMED — autonomous nightly capture + self-recovery (2026-07-25)

Capture is now armed to run **every night automatically, like astrocam.** No
manual arming needed.

**`eos-focus.service`** — a **system** service on muppet (installed to
`/etc/systemd/system/`, `enabled`, `Restart=always`), runs `eos-focus-cycle`
forever. The tool self-gates on the sun: sleeps through the day (polls every
2 min), wakes at nautical dark (~22:45 BST), captures the d-schedule, stops at
dawn, then the service loops back to waiting. Each night's data lands in a
**dated subdir** `~/tmp/canon-focus-nightly/<YYYY-MM-DD>/` (so one long-running
service separates nights). Survives reboots. Verified starting + waiting-for-
dark 2026-07-25. Gotcha fixed: `%h` in a *system* service expands to `/root`,
not `User=peter`'s home — the ExecStart path is hardcoded.
- watch: `journalctl -u eos-focus.service -f`
- next morning: `splay ~/tmp/canon-focus-nightly/<date>/jpeg/`  (grouped by d)
- stop/disable: `sudo systemctl stop|disable eos-focus.service`
- (`eos-focus-tonight`, the systemd-run --user launcher, remains for one-off
  manual runs — but the service is now the normal path.)

**Wedge self-recovery protocol** (in `eos-focus-cycle`, built around the live
lesson that *transient busy states self-clear — don't power-cycle on the first
sign*). On a capture returning NO FILE:
1. **gentle release** (Release Full + None + viewfinder=0) + settle 15s, re-test
   — clears the common transient (Mode A).
2. **grace window** — poll up to **60s** for a self-clear (Mode A that's a bit
   slow) before touching power. Wedges are bimodal (Mode A clears in ~15s;
   Mode B never self-clears), so 60s is enough to tell them apart without
   dead-waiting.
3. **LAST RESORT: `eos-power cycle`** (smart-plug mains cut) — only if still
   wedged after the grace window, capped by `--power-budget` (default 4/run) so
   a hard fault never thrashes the relay. After a cycle: wait for
   re-enumeration → prime → restore exposure → re-shoot the frame.

**Escalation / notifications** (smart-plugs are NOT generally reliable, so a
misfiring reset must never be silent):
- **Reset misfires → Slack heads-up** (`super/bin/alert --info`, Slack-only, no
  page), on BOTH failure paths: (a) the `eos-power cycle` command itself fails
  (plug unreachable / homepi / matter-server down → reset never ran); (b) the
  cycle returns success but the camera is **STILL WEDGED** after re-enumeration
  (the plug may have reported success without actually cutting power). Peter
  learns the plug is flaky even if the run later recovers or aborts.
- **Recovery fully exhausted → xMatters `--critical` PAGE** at the circuit
  breaker (`--max-consec-fail`=6 failed frames), once per night (`.paged`
  marker). The night is being lost; needs a human.
- So the ladder: transient self-heals silently → reset works silently → reset
  misfires = Slack → all exhausted = page.

**Circuit breaker + anti-thrash** (learned the hard way 2026-07-25, when a
missing `websockets`/PATH bug crashed recovery and `Restart=always` thrashed
63× for zero frames): after `--max-consec-fail` consecutive failures the tool
exits CLEANLY (camera unrecoverable — don't grind the night); the service's
`RestartSec=900` bounds worst-case restarts to ~4/hr; and all external calls
(`eos-power`, `alert`) resolve by absolute path and NEVER raise.

**`eos-power` (off/on/cycle/status)** — controls the dummy-battery feed (the
only reset that clears a Class-B wedge). **WIRED 2026-07-26** to a **Matter
smart plug** (strand option (b): switch mains to the DR-E10 adapter rather than
a GPIO relay in the 12V line — coarser, whole-adapter, but no new hardware).
`_relay_set()` now drives the plug over the HA python-matter-server WebSocket
API (`ws://homepi.local:5580/ws`, `commission_with_code`/`device_command`, On/Off
cluster). Config at the top of `eos-power`: `MATTER_WS`, `MATTER_VENDOR`,
`MATTER_NODE`, `PLUG_ON_POWERS_CAMERA=True`. off/on/cycle/status all verified
against the plug (cycle: off → hold `--secs` → on, rc=0). Degrades safely: if
matter-server is unreachable or the node isn't commissioned it prints the
failure and exits non-zero (recovery logs "power-cycle unavailable" rather than
hanging).

  - **Plug: SUPERSEDED — see the 2026-08-09 section at the top.** The plug is
    now a **Realwe Innovation, node 7**, resolved by vendor. The original
    **Currys Sandstrom** (VendorID 5470 / ProductID 9217, node 4) was binned
    2026-08-09 as unreliable; its ghost node remains on the fabric. The
    commissioning + BLE-on-homepi setup below still describes how plugs get
    onto the fabric — that part stands. See [[home-automation]] STATE.
  - **POWER-CYCLE MECHANISM CONFIRMED LIVE (2026-07-26).** Ran `eos-power
    cycle` on muppet with the camera healthy, watching lsusb: camera dropped
    **OFF BUS within 3s** and re-enumerated with a **NEW Dev number (013→014)**
    at **480M**. So mains switching DOES drop the 12V rail — the default **10s
    is sufficient**, bulk caps did not hold it up; no `--secs` bump needed.
    (Still want to catch a genuine Class-B wedge to confirm the cycle *clears
    the wedge*, not just power-cycles a healthy cam — but the mechanism is
    proven.)
  - **DEPENDENCY on muppet: `websockets` python module.** eos-power imports it
    to reach the matter-server; it was NOT installed (import failed → the tool
    returned "unavailable"). Installed `pip install --break-system-packages
    --user websockets` (16.1.1); verified importable in a clean/service-like
    env, so the eos-focus.service recovery path can power-cycle.
  - **DEPENDENCY:** the plug is on Wi-Fi and driven via homepi's matter-server;
    a homepi/Wi-Fi/matter-server outage takes the reset path down. The old
    GPIO-relay option (a) remains the more-direct fallback if this proves flaky.
  - **TODO (astro-canon owns): make the reset path survive a homepi
    reprovision.** homepi's matter-server is a hand-run `docker run` (April, no
    ansible/compose); the BLE fix that makes commissioning work
    (`--bluetooth-adapter 0`, `-v /run/dbus:/run/dbus:ro`, `--security-opt
    apparmor=unconfined`, `--network=host`, `hci0` up) lives only in the running
    container. A rebuild silently loses BLE → the reset path breaks. Add an
    ansible role (or a checked-in run script + `hci0`-up step) capturing that
    container. Astro-canon owns this because the reset path is *its* recovery
    dependency, even though the container is home-automation/ansible territory.
    ([[home-automation]] STATE keeps only a pointer.)

## Focus-experiment algorithm — `eos-focus-cycle` (for the next clear night)

**Philosophy: capture BLIND, analyse NEXT DAY.** Finding stars is hard enough;
don't measure focus live. Step through a deterministic focus grid, tag every
frame with its exact focus coordinate, analyse offline. Tool:
`astro/bin/eos-focus-cycle` (on muppet `~/bin/`).

**The grid (Peter's spec):**
- **MEDIUM = Near-2** setpoints: focus-start ±4 → 9 setpoints (default centre b9,
  the daytime car estimate; stars at ∞ are near but not identical).
- **FINE = Near-1** dither: 0–8 within each medium (Near-1 is sub-pixel — dead on
  coarse targets but moves the PSF fractionally; today's dither confirmed it).
- **1 × 30s RAW sub per position** (30s = max reliable timed; bulb >30s unsolved).
- Grid = 9×9 = 81 positions/cycle ≈ 54 min; a ~90-min dark window ≈ 1.6 cycles,
  ~100+ subs. **Cycle repeats while the gap lasts** (repeats give statistics for
  the medium:fine ratio + hysteresis).

**Traversal (Peter's choice — rigor over speed):** RE-RACK to the far hard stop
and re-approach each medium fresh via anti-backlash, so every coordinate is
reached the same way (hysteresis-consistent). Costs drive overhead; buys
trustworthy coordinates.

**Exposure:** moderate fixed ISO 1600 (focus > gain — a sharp PSF needs far less
gain; if PSF isn't ~few px, the fix is focus not ISO), RAW, f/5.6, 30s.

**Next-day analysis (offline, per Peter):** for each frame → stretch raw → find
the star (confirm via motion between frames) → measure PSF **FWHM AND peak/area,
cross-checked** → plot PSF vs (medium, fine) → best focus = the minimum; also
yields the medium:fine step ratio, the subpixel dither, and focus breathing
(star absolute position vs focus). `cr2-to-fits` feeds the astrocam pipeline.

## ★★★ FIRST LIGHT — the EOS 2000D has stars (2026-07-23)

**Confirmed stars in the EOS frames from the cloudy night of 22–23 July.** Found
the morning after by taking the dark-window **20s streak subs' CR2 raw** and
applying an aggressive percentile stretch (brighten in post, on LINEAR data —
lo/hi ≈ 2–6 of 255, i.e. the sky was genuinely faint). Stars that were
**invisible in the JPEG** (crushed below the tone curve — the night-3 lesson,
proven again) emerged clearly. **Confirmed the definitive way: sources MOVE
between the two ~10-min-apart probe frames** — a hot pixel is welded to the
sensor and cannot move; drift = real stars.

**But the stars are WILDLY DEFOCUSED — this is now the #1 issue.** Measured on
a confirmed star (probed in 2 frames, drifted 734→968 px = motion-confirmed):
**FWHM ≈ 30 px, full blob ≈ 169 px** (a sharp star is FWHM ~2-3 px). Peak only
477 above sky 823 — because the light is smeared over ~22,000 px. The night run
**never applied the focus procedure** (captured at whatever blurred position the
lens sat at) — so first light was achieved DESPITE being ~100px out of focus;
focused frames will be dramatically better.

**Focus is the master control, not gain (Peter's key insight).** Defocus spreads
the light over ~3000× the area, making each pixel ~3000× fainter — which is what
tempted us toward high ISO. Fix the PSF (30px → few px) and the star becomes a
bright point needing FAR LESS gain, with the sky unsaturated. **Rule: if the PSF
isn't ~few px, reduce gain and fix focus first.** Tonight's #1 job: run the
Near-2 focus procedure ON A STAR (rack far stop → Near-2 toward peak, watch PSF
shrink), bracket around it (daytime car-focus at 15m ≠ exactly ∞), THEN capture.

Lessons this cements:
- **RAW is non-negotiable** — the stars were always there, buried under the
  8-bit tone curve. Brighten by stretching linear raw in post, never trust the
  JPEG for faint-star presence.
- **The 20s streak-test verdict "0 streaks / all hot pixels" was a FALSE
  NEGATIVE** — 20s wasn't long enough for trails to clear the threshold, and it
  ran on JPEG-equivalent data. The metric isn't wrong in principle, but needs
  longer subs AND to run on stretched raw. (Motion-between-frames is the more
  robust confirmation — cheaper than long streaks.)
- Pipeline validated: `cr2-to-fits` + `rawpy` on muppet; and a dark night frame
  DOES compress well (30s CR2 18 MB → fits.fz 8.3 MB, 2.2× smaller — the size
  win appears on real dark data, not the bright daytime test).

## WHERE WE ARE (end of 2026-07-22 session)

The focus problem is **cracked** after 3 weeks stuck. This session, in order:
the lens wasn't moving at all (no-op bug fixed) → built a validated metric
(wheel-box Tenengrad) → mapped the step ladder (**Near 2 = the real focus
tool**, reaches Tenengrad 105, *sharper than AF*; Near 1 fine/dead-on-coarse;
Near 3 coarse) → quantified hysteresis → validated a power-cycle-proof focus
recipe → built + verified two night tools.

**Tonight (2026-07-22) ran cloudy — no stars, but the tooling leapt forward.**
`eos-night-watch` launched 22:00, now running as a **systemd --user unit**
(`systemctl --user status eos-night-watch`; nohup/setsid over ssh kept dying on
logout — systemd-run is the reliable detach). It probes every 10 min
(ISO1600/4s/f5.6), logs brightness, and confirms stars by **STREAKS** (see
below). Currently `--no-escalate` (log-only) — the auto-science path had bugs
(missing-file crash, false hot-pixel triggers) so it's disabled tonight.

**STREAK CONFIRMATION is the definitive star test (Peter's method), now built
and verified live.** Stars DRIFT with Earth's rotation and streak in a long
sub; hot pixels are fixed to the sensor and stay round dots. So: bright=cloud,
dark gap=candidates, and a 20s sub settles it — streaks=stars, dots=hot px. No
dark-frame/mask tuning needed. Verified tonight: a probe flagged **517
candidate sources**, the 20s streak sub found **0 streaks / 92 dots → correctly
"no stars"** (all hot pixels). This cuts through the night-1/3 hot-pixel trap
that fooled us all evening. Geometry: 55mm ~13.8"/px, drift ~15"/s ~1.1 px/s →
20s ≈ 24px streak, easily resolved. **Saturation:** 20s at ISO1600 would clip
the LP sky (bg was 71 at 4s) — so the streak sub runs at **ISO 400** (low gain
keeps sky off the 255 ceiling; drift is geometric, unaffected). Hot-pixel mask
(`~/tmp/canon-night/hotpx.npy`, 276 fixed px from two cloudy frames) also folded
into the cheap-probe detector.

Sky trend tonight: bg median 116→101→71 (darkening/twilight), but every
"source" streak-tested as hot pixels. SD card ~empty (~620 frames); frames
download to muppet live, so card capacity is a non-issue.

**Perspective (Peter):** first star took *weeks* with the Pi cameras, mag-6 +
known orientation took *months*. A cloudy first night here is expected — the
durable win is the tooling (focus cracked, streak-confirm, PSF tool), not
photons. Not chasing the full astro pipeline for first light.

**In progress (Peter, cloudy-night build):** the **EOS power-cycler hardware** —
MOSFET/relay in the 12V dummy-battery feed (the ONLY reset that clears a
firmware wedge; see Reset ladder). Software TODO when it exists: an `eos-power`
off/on/cycle interface + auto-cycle-on-wedge hooks so the night tools
self-recover instead of dying till morning; after any cycle the tools must
PRIME (bare preview + throwaway drive) before driving. See the astro-canon
idea spool.

**Next session:** check `journalctl --user -u eos-night-watch` +
`~/tmp/canon-night/brightness.csv` — did it clear, any streak-confirmed stars/
planes? Fix `eos-psf-dither`'s missing-file crash (probe path needs the
embedded-JPEG fallback) before re-enabling `--escalate`. Then, on a real gap:
Near-1 dither analysis (fine:medium:coarse ratio, subpixel reconstruction,
focus breathing), and re-tune science exposure for the LP sky.

## ★ BREAKTHROUGH (2026-07-22) — the lens WAS NOT MOVING for 3 weeks

The whole "extreme difficulty with focus" — the flat sweeps, the identical
`foc_NN` frames, the "stuck→burst→stuck / lens can't do small steps" model —
was very largely an artefact of **`manualfocusdrive` being silently ignored.**
The lens was **not moving at all** in most drives. Proven decisively today:

- **Setup:** camera on a clean closed window aimed at a child's play car
  (~15 m) + distant trees (~20 m) — both effectively at infinity for 55 mm,
  so one focus setting has both sharp. AF-locked sharp on the car (white LV
  box). Fixed measurement region = the car, boxed via splay `p`-key probes
  (`~/.splay-probes.log`): **box (2740,780)–(3280,1340)** on the 6000×4000
  frame. Metric = laplacian variance of that crop; **sharp ≈ 19**, and the
  real Large Fine JPEG now downloads (use `.JPG`, not the embedded extract).
- **The trap:** driving with `--set-config viewfinder=1` as its **own call**,
  then `--set-config manualfocusdrive="Near 3"` as separate calls, **moves
  nothing.** Ran ±12 units, then C=10 (30-unit) anti-backlash overshoots
  (`b=0..15`): lap-var **dead flat 18–19.5**, crops **byte-identical**. The
  element never budged. This is exactly the STATE.md tether-recipe warning,
  but its impact was massively underappreciated — it invalidates the earlier
  focus model.
- **The fix (verified):** issue `--capture-preview` **and** the drive **in
  ONE gphoto2 invocation**, interleaving `manualfocusdrive=None`:
  `gphoto2 --capture-preview --set-config manualfocusdrive="Near 3"
  --set-config manualfocusdrive=None …` (repeat the pair N times in the same
  command). With this form, **20× Near 3 dropped car-box lap-var 19 → 8.6 and
  the car was visibly, wildly blurred** (Peter: "blurred!"). Separate
  `viewfinder=1` calls do NOT satisfy the live-view precondition;
  `--capture-preview` in-invocation does.
- **Switch stays on AF** (`focusmode: One Shot`). Do NOT move it to MF — MF
  hands focus to the physical ring and locks out the electronic drive; AF is
  correct for USB `manualfocusdrive`.
- **DRIVE RELIABILITY (2026-07-22):** `--capture-preview` MUST be in the SAME
  invocation as the drive — this is non-negotiable. **Tried "hold live view
  open (`viewfinder=1`) then drive BARE" to dodge the intermittent hang: it
  RE-INTRODUCED THE NO-OP BUG** — 15× bare Near-2 left the wheel flat at
  Tenengrad 3.1, lens never moved. `viewfinder=1` held open does NOT satisfy
  the precondition; only `--capture-preview` in-invocation does. **Lesson
  (again): exit 0 ≠ lens moved — always verify motion by the metric, never by
  exit code.** The `--capture-preview`+drive form *does* intermittently hang
  ~50 s (fussy proprietary path); live with it via **timeout + one retry** per
  drive, and **prime** after any (re)start (standalone `--capture-preview` +
  one throwaway drive to absorb the first-call hang). Do NOT "optimise" to bare
  drives.
- **PROCESS PILEUP is self-reinforcing — kill-all-and-settle before retrying.**
  When drives started hanging *reliably* (not intermittently), the cause was a
  **pile of timed-out gphoto2 processes** fighting over the USB device (each
  hung 40 s holding a claim), which also spiked muppet load to 7+. Firing new
  drives on top made it worse. Fix: `pkill -9 gphoto2; sleep 2-3`, let load
  settle, then re-prime. After cleanup, `--capture-preview`+Near-3 ran in **2 s
  each**. So a "reliable hang" usually means stuck processes, not a camera
  wedge — clean them first. (Muppet's OpenSearch sessions-index idles at ~3%
  CPU; it was NOT the cause today, though if the hourly ingest goes continuous
  it could start competing with the fussy USB timing.)
- **BUT: one drive command per gphoto2 invocation — never batch many.** A
  20×-drive single invocation (40 `--set-config`s) *hung for 12 min* when the
  camera re-enumerated mid-drive (`error -71`, Dev 091→092): the process stuck
  on `anon_pipe_read` holding a stale claim on interface 0, blocking all other
  gphoto2 access ("Could not claim the USB device… resource busy"). Batching
  widens the window for a mid-flight re-enum to hang the call. Drive in a loop
  of separate invocations, each `--capture-preview` + one drive + `None`.
- **Slow vs hung:** to tell a stuck gphoto2 from a merely-slow one, check
  `ps -o etime,stat`, `/proc/<pid>/wchan` (a hung one sits in `anon_pipe_read`
  / `S` making no progress) and `dmesg | grep 3-7` for a mid-drive re-enum. If
  the device number has *changed* since the process started, its PTP session
  is dead — killing it is then safe (no live session to corrupt).

**Consequences / TODO:**
- **`eos-capture` / `eos-focus-sweep` are suspect** — if they drive via
  separate `viewfinder=1` calls, their sweeps moved nothing and every
  V-curve/`foc_NN` result is noise. Audit and fix them to the in-invocation
  `--capture-preview` form before trusting any sweep.
- **Re-examine the whole focus model.** The backlash/"can't do small steps"
  story may be partly or wholly the no-op bug, not lens mechanics. Re-run the
  hysteresis experiment (walk b via C≫lash overshoot) now that the lens
  actually moves — the metric (car-box lap-var) is validated and tracks focus.
- AF locking the play car (white box) at ~15 m = genuine sharp focus for the
  20 m trees too (same DoF) — a good, repeatable sharp anchor for daytime work.
- **Car focus sits right at the far/infinity end.** Coarse Far-3 bracket from
  the 20×-Near blur: only the *first* Far-3 step (c01) was even moderately
  sharp (lap-var 9), then it fell to a frozen 7.0 tail = the **far hard stop**
  (a real repeatable zero reference). So best focus is a few Near units in
  from the hard stop, and Far-3 strides right over the narrow peak — fine
  (Near-1) steps needed to land it. Peak sharp ≈19; the coarse sweep never
  reached it.

## Field orientation — a TREE fiducial at bottom-right (2026-07-23)

The EOS dawn frames (probe/streak captures at ~04:00–04:23 BST, before full
saturation — 04:33+ are solid 255) show the camera's foreground: **a tree at
bottom-right of frame.** This is a fixed fiducial → **we know exactly which
patch of sky the EOS is pointed at.** Value:
- Anchors the frame to a known bearing/altitude — a shortcut toward the
  "known orientation" milestone (which took *months* on the Pi cameras).
- The astrocam (Pi) has its own tree at bottom-LEFT of *its* frame and shot
  clear star trails the same night (petergrecian.co.uk/astro/astrocam/night/
  2026-07-22, `max.jpg`). Both cameras share the garden foreground → their
  fields overlap in a known way; astrocam trails tell us which sky the EOS
  tree-corner looks at.
- **TODO:** `p`-probe the tree's exact corner in an EOS frame to record precise
  pixel coords for the fiducial; cross-reference bearing with the astrocam.

**Also learned (streak-test length):** the astrocam pulls visible star trails
from **1-minute** subs (its 10-min frames are 10×1-min stacks). Our EOS streak
test was only **20s** — too short to register trails through this LP, which is
why it saw only hot pixels while the astrocam saw stars. Next EOS night wants
**≥1-min subs**; the 2000D caps at 30s timed, so this needs **bulb mode**
(`--set-config bulb=1` … hold … `bulb=0`) for minute-plus integration.

## Metric FIXED — wheel box + Tenengrad (2026-07-22)

lap-var on the whole-car box was **not tracking focus** — it mis-ranked frames
vs Peter's eye (called b1_near "fairly sharp" → lap-var floor 7.4; b2_far best
→ only 11.1) because it's swamped by JPEG block noise and **cloud brightness
drift** (crop mean swung 147→181 between frames as cloud illumination changed).
Fix, validated:
- **Region:** tight box on the play-car **wheel** (hard, high-contrast, curved
  edges at all orientations), from splay probes: **(2847,1137)–(2947,1237),
  100×100** on the 6000×4000 frame.
- **Metric:** **Tenengrad** (mean squared Sobel gradient), NOT laplacian
  variance. Ranks frames as the eye does: blur floor ≈1–2, moderate ≈9, sharp
  ≈27. Read off the full-res `.JPG` crop.
- **Hysteresis now stark:** at commanded b=2 (Near-3 units from far stop),
  **far-approach Tenengrad 27.1 vs near-approach 3.6** — a huge gap. Direction
  of approach determines whether you hit focus AT ALL. Confirms the a→b-via-C
  rule is decisive, not just helpful. Best focus ≈ b2 reached via far-approach
  (rack to far stop, Near-3 ×(2+C), Far-3 ×C back; C=5).
- **Near-1 is dead motion** (separate confirmation): 20× Near-1 off the far
  stop stayed flat 6–7, no peak, byte-near-identical frames. The lens genuinely
  cannot do Near-1; minimum useful step is **Near 3**. (The old "can't do small
  steps" was RIGHT about Near-1 — but earlier it looked like Near-3 was dead
  too, which was the viewfinder=1 no-op bug, not mechanics.)

## ★★ Near 2 (MEDIUM) is the real focus tool — much sharper than Near 3 (2026-07-22)

The step-size question resolved, and it's a big deal. gphoto's `manualfocusdrive`
choices are 3 step SIZES per direction (Debian bug #778916; docs): **Near/Far 1 =
fine (numeric 0/4), 2 = medium (1/5), 3 = coarse (2/6)** — NB the labels are
inverted from intuition (1 is the *finest*, 3 the *coarsest*). We had only ever
tested 3 (coarse, works) and 1 (fine, DEAD on this lens). **Never tested 2 —
until now, and it's the winner:**
- From the far stop, `Near 2` single steps: wheel Tenengrad
  **1.76 → (n2_3) 1.89 → (n2_6) 4.53 → (n2_9) 104.9** — a clean sharp peak
  at **≈9 Near-2 steps**, and **Tenengrad 105 vs the Near-3 coarse peak of only
  ~27**. Near-3 strode OVER the true peak; Near-2 lands IN it.
- So the usable focus ladder on this EF-S 18-55 is: **Near 1 = dead (rounds to
  zero), Near 2 = the fine-focus tool (works, ~5× finer than Near 3), Near 3 =
  coarse bracketing.** Peter's "fine × 5 = medium" instinct pointed the right
  way — medium is the missing usable increment.
- **REVISED focus recipe (supersedes the b2/Near-3 one below):** rack to far
  stop → coarse-bracket with Near 3 if needed → **fine-focus with Near 2 to the
  peak (~9 steps from stop on the car)**. Best-focus is much sharper than the
  earlier "b2" ever was. Re-do the hysteresis / dither sizing with Near-2 steps.

## Blind-focus recipe — VALIDATED, reproduces across a power cycle (2026-07-22)

The daytime terrestrial focus (car/trees at 15–20 m, ≈ infinity for 55 mm)
distils to a repeatable command sequence, wheel-box Tenengrad ≈ sharp:

1. **Prime live view first** (esp. after any power cycle / re-enumeration):
   one standalone `gphoto2 --capture-preview` before any drive. **The FIRST
   `--capture-preview`+drive after a fresh enumeration HANGS** (50 s timeout,
   `error -70`-adjacent) — a bare `--capture-preview` clears it, then drives
   work instantly. New quirk, add to the recipe.
2. **Rack to the far hard stop:** 6× `Far 3` (frozen = pinned; the repeatable
   zero reference).
3. **Far-approach to b=2:** `Near 3 ×7` (= b2 + C=5 overshoot), then
   `Far 3 ×5` back. Final move is Far, so lash is taken up consistently.

Verified: after a full power cycle (fresh Dev, focus reset), this landed the
wheel at Tenengrad **13.0** (peak was 16.4; the gap is cloud-brightness, not
focus). Best focus = **b2**, peak is **narrow** (±1 Near-3 step → <1 Tenengrad).

- **For stars (infinity):** infinity is slightly FAR of the 15–20 m car focus,
  i.e. toward the stop from b2 — but the far hard stop appears to sit *past*
  infinity (b0/b1 at the stop measured blurred), so true infinity focus is a
  hair inside the stop, near b1–b2. Tonight: fine-check around b2 on a real
  star with the PSF/FWHM metric (brightness-independent, unlike Tenengrad).
- **Tool robustness:** the sweep tools must fall back to the embedded CR2 JPEG
  when the Large Fine `.JPG` doesn't download (it's intermittent — a b4 capture
  crashed a sweep on a missing `.JPG`). `verify_b2.py` has the fallback.

## Night PSF tool built + verified — `eos-psf-dither` (2026-07-22)

New tool `astro/bin/eos-psf-dither` (deployed to muppet `~/bin/`, committed
astro `1545c84`). On a clear gap it finds the brightest compact source (star OR
plane), runs a **Near-2 focus sweep** (2D-Gaussian FWHM per step), drives back
to best focus, then a **Near-1 fine dither** serving Peter's three uses:
1. **fine:medium:coarse step ratio** — Near-1 shift is sub-pixel; measurable on
   a PSF even though "dead" on coarse daytime targets.
2. **subpixel centroid dither** — for super-resolution beyond pixel sampling.
3. **focus breathing** — track the source's ABSOLUTE position vs focus step.
Logs FWHM(x,y), subpixel centroid, peak, ellipticity, flux, background to CSV.

Sky logic: **light pollution → cloud = BRIGHT**, clear = darker; so shoot when
background is LOW or FALLING (not "dark"). Planes are valid targets to ~1am
even under cloud. `--bright-gate` sets the shoot threshold.

**Dry-run verified end-to-end** on the daytime car (exit 0): probe→brightness
gate→Near-2 sweep→drive-back→Near-1 dither→PSF fit→CSV all ran. Daytime FWHM
values are junk (no real point source) but plumbing is proven. Notably the
Near-1 dither DID move the centroid sub-pixel (3767.07→3767.38→3766.98) —
fine steps register at the PSF level, which uses 1-3 depend on.

Tonight: `eos-psf-dither` (loop, gap-gated) once pointed at sky; tune
`--focus-start` (~9 daytime, stars are at ∞ so maybe 1-2 less) and
`--bright-gate` from the first probe's background reading.

## Tonight's plan (2026-07-22 session arc)

In order, each step splayed and metric-checked:
1. **Fine-focus experiment** — from the far hard stop, Near-1 single steps
   through the peak: locate best focus AND re-test whether Near-1 actually
   moves the element (the old "can't do small steps" claim, now the drive
   works). Then hysteresis: approach the same focus from Near vs Far with
   overshoot C to measure the loop width → gives the **dither overshoot size**.
2. **Move camera behind the window glass, repeat** — same car box, same
   metric, glass in vs out: quantifies what the glass costs (the eclipticam
   "had to move it 8 cm off the window" mystery — measure it here). Fix if it
   hurts is physical distance from glass, not focus.
3. **Point at sky** — reframe to the real astro target.
4. **Set timers / exposure for tonight's capture** (`eos-sequence`).

**Focus dither at night:** the reason we may need to dither focus is the lash
— inconsistent approach direction lands the element in slightly different
places. Dither = always approach the focus target from ONE direction with an
overshoot ≥ the loop width. The fine-focus/hysteresis experiment (step 1) is
what sizes that overshoot. So the daytime experiment directly feeds the night
recipe.

## Reset ladder — what actually resets this camera (read first)

Two independent failure classes, and they respond to different resets. Don't
reach for the wrong one. Ordered cheapest → most physical; verified from the
2026-07-13/15 sessions.

**Class A — slow link (enumerates at 12M, not 480M).** Comms work, downloads
crawl (~1 MB/s). This is a *link* problem, curable in software:
1. **Just wait / poke it.** The flaky link often drops and re-enumerates on
   its own, landing at **480M** — the cheapest fix, no command needed. Check
   `lsusb -t` for the Imaging line at 480M.
2. **sysfs deauthorize/reauthorize** — the reliable software bus reset,
   *does* re-enumerate at 480M (verified 2026-07-13):
   `echo 0 | sudo tee /sys/bus/usb/devices/3-7/authorized; sleep 2;`
   `echo 1 | sudo tee /sys/bus/usb/devices/3-7/authorized`. Path is `3-7`
   (bus 3, port 7). This is THE remote reset — use it, not usbreset.
3. **Reseat/replace the mini-B** at the camera end if 12M becomes the norm.

**`usbreset` is a dead end — do not try it.** Both forms fail on this device:
`usbreset 04a9:32e1` (VID:PID) → "No such device"; `usbreset
/dev/bus/usb/003/084` (correct path form) → *also* "No such device found"
even though lsusb confirms the device is right there. The binary simply can't
reset this camera. Use the sysfs authorized toggle instead.

**Class B — firmware wedge (`-110 I/O in progress`, or config WRITES silently
rejected).** Comms/`--summary` still work and the model reads correctly, but
capture/preview is stuck or `--set-config` doesn't stick. **No software reset
clears this** — usbreset, the sysfs authorized toggle, AND a full USB
re-enumeration all leave it wedged, because the state is *inside the camera's
firmware*, not the link or the host PTP session. It also **survives a muppet
reboot**. Only a true camera power-down clears it — and here's the trap:
- **The dummy-battery PSU holds the USB device alive across a power-switch
  flip** — after flipping the switch the device kept the *same* Dev number
  (084), proving it never left the bus. So the physical power switch does
  NOT reset it.
- **To actually power the logic rail down: pull the mini-B cable at the
  camera OR pull the 12V dummy-battery feed for ~10 s, then reconnect.** A
  *new* Dev number on re-enumeration confirms the reset took. This is the
  only cure for Class B.

## Capture wedge — full card + write-rejection (2026-07-15 eve → paused)

Trying to run the focus **hysteresis** experiment (`eos-capture moves`,
`<from>-<to>.jpg` naming, e.g. `--targets 6,20,6,30,6,0,6`) — blocked by
capture failures. Root causes untangled:

- **The "power issue" was the supply switched OFF.** Once on, muppet + bigdisk
  + camera all came back fine (bigdisk mounts by UUID; USB disks shift
  letters, fstab already uses UUID). Not instability.
- **The SD card was FULL** (81 MB free) — the real original cause of "capture
  fails silently": shutter fires, PTP props change, but no file written.
  Cleared it: this gphoto2 build has **no `--format`**; use
  `gphoto2 --folder /store_00020001/DCIM/100CANON -D` (delete-all) → 15.6 GB
  free. NB this **wiped the hand-held shots IMG_9737–9809** (Peter said just
  format; those were not saved off first).
- **grab() was card-only** — it listed the card then get-file'd by name, so it
  failed in Internal RAM mode. FIXED: now fires `eosremoterelease` then
  `--wait-event-and-download` to `<stem>.%C` (works in RAM or card). Committed.
- **Remaining blocker — capture still wedged after all the above.** Config
  *reads* work but **all config WRITES are silently rejected** (`iso=400`
  stayed 200; `eosremoterelease` → "sufficient quoting" error). Survives USB
  re-enumeration and muppet reboot → it's a **camera-firmware wedge**. The
  **dummy battery holds the logic rail up, so the camera power switch does NOT
  reset it.** Camera also re-enumerating a lot (Dev 028→054 in one session).
- **TOMORROW'S RESTART (do this first):** fully power the camera down —
  **pull the 12V feed / dummy battery for ~10 s**, reseat the mini-USB firmly,
  then on. Verify: `lsusb -t` Imaging at 480M and *stable* (no re-enum storm);
  a config WRITE sticks (`--set-config iso=400` then read back 400); then a
  test `eos-capture grab` downloads a file. Only then run the hysteresis
  `moves`. Storage: write to muppet nvme `~/tmp/canon-focus` (USB disks are
  fine now but nvme is simplest); splay reads via copy to pip.
- Card is now empty (capturetarget=Memory card). Hand-held IMG_9737–9809 gone.

## Power issue interrupted work (2026-07-15, midday)

A **power problem** (ongoing "for a while") knocked things over mid-session:
- **bigdisk (sdc3, USB) unmounted itself** when the drive dropped off USB.
  Data intact — disk healthy, just remounted (`sudo mount /dev/sdc3
  /mnt/bigdisk`). Expect it to keep dropping while power is unstable; the
  15yo-Seagate distrust stands. **photodisk (sdb1) also threw an I/O error**
  in the same event — both USB disks are power-affected.
- **Switched capture storage to muppet's internal nvme** (`~/tmp/canon-focus`)
  which doesn't drop on power glitches. splay reads via a JPEG copy to pip
  (pip-local, stable). bigdisk/NFS unreliable during the outage.
- **Camera capture then wedged**: enumerates fine (Device on bus, gphoto
  `--summary` works, battery 100%) but `eosremoterelease` capture returns
  nothing (the familiar PTP-busy-after-live-view wedge, aggravated by the
  power instability). Did NOT chase the full reset chain — not worth it while
  power is unstable. **Hysteresis `moves` experiment paused until power
  settles.** Tool is committed/deployed and ready to run.

## Focus model — lens throw characterised by eye (2026-07-15)

Ends the standing "focus never validated" problem. Corrects earlier wrong
assumptions (that manualfocusdrive was silently ignored; that the dirty
window blocked sharpness). Diopter coordinate = **Near-1 steps from the far
(infinity) hard stop**, named `foc_<NN>.jpg` by `eos-capture focus`.

- **The lens moves fine.** 25× Near-3 racked focus all the way from the
  garden to the near limit — a sharp photo of the **window glass** a few cm
  away (`mf_after.jpg`). So `manualfocusdrive` works; the STATE note about it
  being silently ignored did not apply this session.
- **The throw is strongly NON-LINEAR.** Almost the entire useful landscape/
  astro range (infinity → mid-garden) is squeezed into a thin sliver at the
  **far end, ~foc_00–07** — those frames were visually *identical* (only wind
  moved the foliage). Everything beyond spends the rest of the (long) travel
  on near focus:
    THE DRIVE MOVES IN BURSTS, THEN STALLS — not simple backlash. From a
    Near-going sweep off the far stop (foc increasing 00→39), Peter's eye:
    - foc_00–13 : identical, NOT sharp (would not detect stars) — element not
      moving here.
    - foc_14–24 : **progressively sharper** — the element IS moving through
      this range (real, monotonic focus change).
    - foc_27–39 : identical again — stalled / not moving.
    So motion happens in a middle burst (≈14–24), bracketed by stuck zones.
    A one-time 15-step Near "lash takeup" did NOT fix it (foc_00–18 still
    flat with --backlash 15).
  - **Best explanation (and probably honest, not a bug): the lens CANNOT do
    small focus steps.** `manualfocusdrive Near 1`/`Near 2` are below the
    focus-by-wire motor's minimum actionable increment, so small requests
    round to zero motion; the element only lurches once accumulated demand
    crosses a threshold. That explains the stuck→burst→stuck pattern, why the
    15-unit takeup didn't help, and why *big* decisive drives (25× Near 3
    reached the window glass) always work. NB the exact commands issued were:
    `Far 3`×14 (rack), then `Near 3`×5 (the "15" takeup — coarse 3-unit
    moves, not fifteen 1-unit), then constant `Near 2` per captured frame;
    `foc_NN` is just the running unit-sum label, the command was identical
    each step. Each `drive()` also tears down + rebuilds live view
    (`--capture-preview` … then `viewfinder=0`) around the move.
  - **Consequence: focus this lens with BIG moves only — `Near 3`/`Far 3`,
    never `Near 1`.** Small steps are fiction. Find focus by driving in
    `Near 3` chunks watching for the sharpness peak; accept coarse resolution.
  - **CRUCIAL: the sharp end of the moving burst (~foc_14) reaches genuinely
    sharp, star-detecting focus — as good as the AF `8Z` shot.** So manual
    `manualfocusdrive` CAN reach true focus after all; we are NOT dependent on
    AF. BUT because the drive moves in unpredictable bursts, the diopter
    number is NOT a reliable coordinate between sweeps — "foc_14 from the far
    stop" may not reproduce. The sharp position exists and is *findable* (watch
    sharpness climb through the moving burst, stop at the peak), just not
    addressable by a saved step count.
  - **Practical focus procedure:** drive in `Near 3` chunks (never `Near 1`)
    watching a hard-edged crop / the eye in splay; when sharpness climbs then
    peaks, stop — that's focus. Don't trust a remembered foc_NN (the burst
    behaviour means it's not reproducible). AF remains the fast alternative
    and lands sharp effortlessly.
    - foc_15    : *moderately* blurred (UK "quite").
    - foc_39    : very blurred — well down the near slope.
    - ~foc_75   : sharp again on the window glass (near limit).
  So Near-1 IS fine enough to resolve focus on the slope; foc_00–07 look
  identical because they are genuinely all in focus (DoF), not because the
  step is too coarse.
- **AF is the reliable focus method on this rig.** The camera's own
  autofocus (hand-held half-press) produced a *shockingly sharp* frame
  (`...T124038Z.jpg` = "8Z", sharp≈89 vs ~10 for every manual foc_NN). The
  manual foc_NN frames never matched it — but note "8Z" was a *different aim*
  (deeper into the scene / trees) at a good AF lock; the point stands that AF
  produces sharp results effortlessly where manual step-hunting struggled.
  gphoto2 can also fire AF via the `autofocusdrive` toggle
  (`focusmode: One Shot` = switch on AF).
- **The dirty window is a red herring for sharpness.** "8Z" and the
  window-glass frame are both sharp *through* the grubby glass — it's
  transparent enough. The blocker was always hitting the thin infinity
  focus, not the glass. (Correction to the "dirty-window reckoning" below.)
- **Consequences for astro:**
  1. **Backlash must be defeated first.** Small same-direction focus steps
     from a stop don't move the element (~13 steps of slack observed). Fix =
     dither: overshoot the target and approach from a consistent direction so
     the lash is always taken up (Peter's "out and back" — e.g. drive to
     foc_15, then back to foc_03, so the final approach is always from the
     far side). `eos-capture`'s current sweep (naive Near-1 from the far
     stop) is wrong: it captures 13 identical stuck frames before the drive
     engages. Needs an anti-backlash drive primitive.
  2. AF on a bright star/planet sidesteps lash entirely — good backup.
  3. `eos-capture focus` defaults (wide `--steps 15`) are wrong for astro;
     add a tight foc_00–06 micro-sweep mode, or an AF-trigger mode.

## Night 4 → morning (2026-07-14) — clouded out, then the dirty-window reckoning

- **Clouded out.** Cross-checked our own JPEGs: night sky was
  light-pollution-orange lit cloud, rare/fleeting gaps. No usable star
  data. A focus-lottery grabber (cycle diopter + fixed exposure, wait for
  a lucky gap coincidence) ran but never caught a clear-gap/sharp-diopter
  coincidence.
- **THE key realisation (retroactively explains everything): the camera is
  shooting through a DIRTY WINDOW.** The window isn't clean, and we were
  getting sharp *reflections* of the camera/scene in the glass. So the
  garden was never sharp not because of focus but because it's imaged
  through grimy glass a few cm away. Certain "in-focus" frames had actually
  locked onto the window plane (dirt/reflection), not the garden — you
  can't have the near dirty glass and the far garden both sharp, and the
  glass scatters the garden light. **No focus tuning fixes this; the fix is
  physical:** clean the window, open it, or take the camera outside.
  Peter's plan: hand-held photo (AF switch already on AF) away from the
  glass — the correct move, it removes the window entirely.
- **Focus mechanics learned along the way (still valid for a clean path):**
  - The lens DOES move — visible blur change when driven decisively. Earlier
    "zero focusing effect" was because **Near-1 steps are visually
    invisible**; use Near/Far **3** for sweeps.
  - Software focus metrics (laplacian variance) are **unreliable through
    moving cloud AND on textured scenes** (garden foliage/gravel). The eye
    in splay is the judge.
  - **AF is available**: `focusmode: One Shot` (switch on AF), and
    `autofocusdrive` toggle can fire AF via gphoto2. Not needed for
    hand-held.
- **Tooling now lives in the repo (Peter's workflow: write Python, commit,
  push, pull on muppet — no more heredoc/nested-quote scripts):**
  `astro/bin/eos-capture` — `grab` (fire → download RAW+JPEG named by muppet
  UTC → report centre brightness to steer next exposure) and `focus`
  (big-step sweep, frames named **`foc_<diopter>.jpg`** where diopter =
  Near-1 steps from far stop; sets file mtime to muppet UTC). muppet has a
  full astro checkout on main — deploy via `git checkout origin/main --
  bin/eos-capture` (muppet has unrelated local changes, so don't full-pull).
- **splay is THE viewer for these sessions** — `splay <dir>` hands off to
  the running instance, auto-reload shows new frames live. Don't render
  inline / copy to ~/tmp. Spun off a **splay-ai-discovery** strand
  (`super/strands/splay-ai-discovery/`) capturing splay UX findings +
  Peter's request: default sort → `added`, and the bug that `added`
  degenerates to name-order on initial dir load.
- **Camera clock**: this body's `--set-config datetime` takes the epoch as
  **UTC directly** (no local offset) — set to true UTC epoch, EXIF-verified.
  But muppet (NTP-synced) is authoritative; `eos-capture` stamps filenames +
  mtime from muppet UTC regardless of the camera.
- **Card**: still not formatted (never got to it); night-3 data safe on pip.
  Daylight/night test frames now up to ~IMG_9736 on the card.

## Dummy-battery PSU installed & verified (2026-07-13)

- **The 2–2.5 h live-view budget is gone.** The DR-E10 dummy battery /
  mains PSU is fitted; the camera presents a steady **100 %** gauge and
  no longer sags under live view. Sweeps and continuous `eos-star-watch`
  can now run all night — the drain that used to gate live-view work no
  longer applies. Card sequences already didn't need it.
- **Tether re-verified end-to-end on muppet** over the mains-powered rig:
  gphoto2 talks (`Canon EOS 1500D` on usb:003,084), RAW+JPEG
  capture-and-download works (18 MB CR2 + 484 KB JPEG pairs, fast).
- **480M self-heal confirmed.** Camera first enumerated at **12M** (the
  night-3 "not running at top speed" state); it dropped and re-enumerated
  on its own at **480M** without touching the plug. So: on a slow link,
  a clean disconnect/reconnect is the first, cheapest fix — check
  `lsusb -t` for the Imaging line at 480M. (For the reset options and why
  `usbreset` doesn't work here, see the **Reset ladder** at the top.)
- `capturetarget` restored to **"Memory card"** at session end —
  camera is sequence-ready. (Exposure left at daylight ISO 200 / f/8 /
  1/500; `eos-sequence` sets its own at run start.)
- A few daylight test frames (IMG_9641–9643) now sit on the card after
  night 3's IMG_9637; card was not formatted. Harmless.

### Daytime ballpark-focus attempt (same session) — method learned, tether blocked it

- **Goal**: ballpark-focus the lens in daylight on a terrestrial target
  (tree ~4 m out the window) rather than weak stars. Camera was pointed
  at mostly-sky; a sunlit tree sat in the bottom-right / right edge.
- **Live-view preview sweeps DON'T work for focus on foliage.** Two
  sweeps (`~/tmp/day-focus-sweep.py` on muppet) driving the lens and
  measuring gradient energy on the tree crop came back **flat**
  (1.3–1.9, no V/peak). The 1056×704 live-view JPEG is too downsampled /
  compressed to resolve the fine leaf detail that focus sharpens. Good
  for *framing/exposure*, useless as a focus metric on diffuse subjects.
- **Full-res capture + laplacian-variance on a tight target crop is the
  right method** (`~/tmp/day-focus-fullres.py`). A single 6000×4000 frame
  gave lap-var **22** on the tight sunlit-tree crop vs **~0** for sky —
  real, focus-sensitive signal. Metric: variance of the 4-neighbour
  Laplacian over the crop.
- **Capture recipe refinement** (worked, then went flaky): after
  live-view use, `--capture-image-and-download` fails **0x2019 PTP Device
  Busy** (AF can't lock on sky). The working path is to **split** it:
  `--set-config eosremoterelease=Immediate` as its OWN call, THEN a
  separate `--wait-event-and-download=8s` (longer than 2 s). Also drop
  live view (`viewfinder=0`) + settle before still capture.
- **Blocked by the flaky mini-B tether.** Over the session the link
  re-enumerated ~4× (device 083→084→102→108). A long unattended full-res
  sweep loop hung when a `gphoto2` call was mid-flight during a
  re-enumeration; single captures then became intermittent (release
  fires, nothing downloads). This is the standing "reseat/replace mini-B"
  item biting — **not worth grinding on live**. Real focus should be a
  night job on stars anyway (raw-domain, hot-pixel-masked).
- **Two separate weaknesses, confirmed distinct (2026-07-13):**
  1. **Physical mini-B connector** — flaky, re-enumerates, one hard
     `error -71`. A blow on plug+socket *stabilised it* (Dev held steady,
     previews 5/5, 480M) — so the connector responds to cleaning but is
     inherently weak. Keep a spare cable.
  2. **Camera capture path** — even with the tether steady AND after a
     fresh enumeration, full-res still capture became **intermittent**
     (release fires, nothing downloads; worked twice early, then didn't).
     Live view kept working throughout, so it's the still/PTP path, not
     the link. **This is the entry-level body showing its age:**
     `--abilities` reports capture as *"No Image Capture, No Open
     Capture, Canon EOS Capture, Canon EOS Capture 2"* — i.e. it
     implements only Canon's **proprietary** EOS capture opcodes, not
     generic PTP `InitiateCapture`. That's why plain `--capture-image` is
     fussy and `eosremoterelease` is mandatory, and why the capture
     sequence is state-sensitive. Firmware `deviceversion=3-1.1.0`;
     driver matches it as **EOS 1500D** (the stripped-down tier). The
     API surfaces the design limits (proprietary-only capture) but NOT
     the USB-layer flakiness (that's dmesg/`lsusb -t` only).
- **Left over**: the two sweep scripts live on muppet under `~/tmp/`
  (`day-focus-sweep.py`, `day-focus-fullres.py`) — reference for a proper
  `eos-focus-sweep --daytime` mode if wanted. Frames in
  `~/tmp/day-focus*/`. Live view is currently disengaged; lens was driven
  toward the far end mid-attempt (position not recorded — re-sweep).

## Night 3 (2026-07-12) — first real dataset, hot-pixel reckoning

- **291 × 10″ ISO 1600 f/5.6 RAW+JPEG subs** (IMG_9347–9637, ~10.8 GB),
  01:44–03:15 via new `bin/eos-sequence`. Copied to pip
  `~/tmp/eos-night3/card/` (card reader, 23 MB/s); card safe to format.
  Last dark frame IMG_9581; dawn brightens the tail. Stacks + FITS in
  `~/tmp/eos-night3/` (sum/max/min as .npy and .fits).
- **Hot pixels masquerade as stars — the night's big lesson.** ~1000
  warm px (≈50 visually obvious) at 10″ ISO 1600. Every bright compact
  "star" in JPEG analysis (peak ~150, FWHM 2–3 px, including the
  "Polaris" fixed for 2 h) was a hot pixel; real stars in JPEGs peak
  only ~15 DN over sky (tone curve + NR crush them) and show as Peter's
  eyewitness *blurred streaks*. **Per-pixel MIN across a session is the
  cheap, excellent hot-pixel map** — subtract/mask before any star
  detection. Map: `astro/calib/eos2000d-hotpixels-2026-07-12.csv`.
- **Focus therefore NOT validated.** The sweep ran end-to-end (24
  steps, V-curve, best step 8, --goto-best worked mechanically) and its
  metric did respond to lens motion, but the post-sweep "2.3 px FWHM"
  verification measured hot pixels. Whether step 8 was truly sharp is
  an open question for the CR2s. eos-focus-sweep's detector needs the
  hot-pixel mask folded in before the next sweep.
- Unaligned mean-stack of a rotating field dilutes stars ~1/N —
  useless for trails (use per-pixel max, and exclude cloudy frames or
  they wipe the max); the mean is instead a good sky-glow/sensor
  reference. Trails were *still* invisible in the JPEG max — real-star
  signal is that weak in JPEG; raw domain needed.
- **LP-E10 with live view off barely drains**: gauge still 100% at the
  last frame; camera died (clean USB disconnect) at 08:30, ~7 h on.
  The 2–2.5 h budget applies to live-view work (sweeps), not sequences.

## USB reliability hardening on muppet (2026-07-14)

Research (gphoto community + Canon forums) confirmed the 2000D/1500D-tier
bodies are the fragile end of the range, and split the flakiness the same
way STATE.md already did: (1) the **proprietary-only EOS capture path** is
inherent to this tier (not a fault) — `eosremoterelease` mandatory, PTP
Busy after live view is widely reported; (2) the **physical
disconnect/re-enumeration** half is cable + power + USB autosuspend, and
libgphoto2 #647 shows nobody found a *software* cure for that half — it's
hardware. Applied the two safe, community-proven levers on muppet:

- **USB-autosuspend disabled for `04a9:32e1`** via
  `/etc/udev/rules.d/90-canon-eos-usb.rules` (`power/control=on`). Attacks
  the "drops off the bus on idle → re-enumerates" failure directly.
  Verified: after reload+trigger, `/sys/bus/usb/devices/3-7/power/control`
  reads `on` and speed `480`. (Note: `power/autosuspend` reads back `2`,
  not `-1` — modern kernels clamp/ignore that node; `power/control=on` is
  the one that governs suspend, and it's set.)
- **gvfs-gphoto2-volume-monitor masked** for peter
  (`systemctl --user mask …`, symlinked to /dev/null). Stops the desktop
  auto-grabbing the camera on plug-in, so the reactive `gio mount -u`
  dance is no longer needed. Verified `gphoto2 --auto-detect` still owns
  the camera cleanly afterwards.

Both are reversible (delete the rule / `systemctl --user unmask`). Still
the **top hardware buy**: a **powered USB hub** between camera and muppet
(the single most-repeated community fix for the disconnect cycle) plus a
short ferrite'd known-good mini-B cable.

## What exists

- **Working tether** (2026-07-08): EOS 2000D (04a9:32e1, reports as
  "EOS 1500D" in auto-detect) on muppet over USB/gphoto2. Capture,
  download, exposure control (M mode), remote focus drive all proven.
  Solid mini-USB (mini-B) cable fitted — the first cable silently
  re-enumerated ~10×/20 min; watch `dmesg` device numbers if flakiness
  returns.
- **`bin/eos-focus-sweep`** (astro repo + muppet `~/bin/`): drive lens
  to far stop → step Near → frame per step → star-FWHM metric →
  best step, `--goto-best` re-drives there. Validated in daylight at
  f/5.6 (in-focus vs defocused gradient energy 31 vs 4.5 on a fixed
  probe crop). Night validation still pending (weather).
- **`bin/eos-sequence`** (astro repo + muppet `~/bin/`): back-to-back
  timed exposures to the **SD card** — no per-frame download, so the
  degraded USB link doesn't gate cadence (~19 s/frame for 10″ RAW+JPEG).
  Press-then-release per frame (a held `eosremoterelease=Immediate`
  re-fires in continuous drive); `FILEADDED` events confirm each frame;
  battery/card-space logged every 10 frames; `--until HH:MM` deadline;
  waits out USB re-enumerations. Reads back camera settings at start —
  a rejected `--set-config` still exits 0 (`shutterspeed=10` silently
  stayed at 4; the token for Canon 10″ is `10.3`).
- **`bin/eos-star-watch`**: periodic test frame; counts compact
  star-like sources — clouds/no-stars give a telltale ~43 px
  flat-window moment "FWHM", which it rejects; on a clear gap it runs
  the sweep `--goto-best` automatically. Logs to `outdir/watch.log`;
  survives broken stdout pipes.
- **Tether recipe** (each item cost real debugging):
  - Camera Wi-Fi ON disables USB entirely (no enumeration). Wrench menu
    → Wireless → Wi-Fi → Disable.
  - Auto power-off drops it off the bus; set Disable. No wake-on-USB —
    the power switch is physical and final.
  - `manualfocusdrive` only moves the lens inside ONE gphoto2 invocation
    where live view is engaged by a `--capture-preview` first; interleave
    repeated steps with `manualfocusdrive=None`. Otherwise silently
    accepted and ignored (EOS_ErrorForDisplay in `--debug`).
  - Lens AF/MF switch must be AF (`focusmode: Manual` = switch on MF).
  - Plain `--capture-image` refuses to fire if AF can't lock (blank sky):
    use `eosremoterelease=Immediate` + `--wait-event-and-download`.
  - After a long exposure the camera stays busy several seconds
    (processing/LENR) — viewfinder=1 fails 'I/O in progress'; settle
    ≥ exposure time, retry ~5×.
  - Mode dial is physical; `autoexposuremode` looks writable but isn't.
  - gphoto2 flags are order-sensitive: `--force-overwrite --filename`
    before capture actions.
  - `capturetarget` is a mode switch: "Internal RAM" for tethered
    download workflows (sweep/watch), "Memory card" for sequences.
    **Currently left on "Memory card"** (night 3); sweep/watch tools
    that expect RAM downloads still work — gphoto2 downloads either way
    with `--wait-event-and-download` — but card fills.
  - The flaky-tether re-enumeration returned on night 3 (5 bounces in
    5 s as the sweep's focus drive started) and the camera came back at
    **USB 1.1 full speed** ("not running at top speed" in dmesg) —
    downloads ~1 MB/s. Reseat the mini-B plug by daylight; check
    `lsusb -t` for 480M.
  - gvfs on muppet's desktop can claim the camera on plug-in:
    `gio mount -u gphoto2://...` first.
- **Data** on muppet: `~/tmp/eos2000d-test/` (daylight tests + card
  backup in `from-camera/`), `~/tmp/eos-focus/night1|night2/` (cloudy
  sweeps), `~/tmp/eos-focus/watch-*/` (overnight watch frames).

## Pending / loose ends

- **CR2 → FITS / raw-domain analysis** — the decisive next step:
  install `rawpy` on pip, demosaic a few night-3 CR2s, and answer (a)
  how sharp step-8 focus really was, (b) whether stars are strong
  enough in raw for stacking. 14-bit linear data; JPEGs are exhausted
  as evidence. Then stack (rotation alignment — field rotates about
  the pole; astro-subpixel material).
- **Fold the hot-pixel mask into eos-focus-sweep / eos-star-watch**
  star detectors (load calib CSV, or compute a live min-map from the
  sweep's own frames) — without it they measure hot pixels.
- **Reseat/replace the mini-B tether — now the top blocker.** On
  2026-07-13 it re-enumerated ~4× in one session (083→084→102→108) and
  a replug once failed to enumerate at all (`error -71`, `device not
  accepting address`). It hung a full-res capture loop and made single
  captures intermittent. Get a known-good mini-B cable / reseat firmly
  before any capture-heavy session. Also worth an auto-check in the
  tools: read `/sys/bus/usb/devices/3-7/speed` after any re-enumeration,
  force a reconnect (the **sysfs authorized deauth/reauth** — see Reset
  ladder; NOT usbreset, which fails on this device) if it reads 12; wrap
  gphoto2 calls so a mid-flight re-enumeration doesn't hang.
- **Night-3 raws live only on pip** (`~/tmp/eos-night3/card/`, 11 GB,
  disk at ~94%) — decide keep/thin/move (muppet bigdisk?) before it
  bites. Card itself can be formatted for the next session.
- **Sensor dust**: several motes visible at small apertures. Map with a
  deliberate f/22 sky frame; blower before serious use.
- **55 mm sweep step calibration** — night 3 partially answered this:
  the default 24 × Near-1 steps produced a V-curve whose minimum
  (step 8) looked unambiguous, and the metric did respond to lens
  motion. But the probe "stars" were contaminated by hot pixels, so
  re-judge after the detector uses the hot-pixel mask.
- Zoom is manual and not parfocal — zoom first, focus second; re-sweep
  after any zoom touch.
- **Dedicated tether host if sessions-index ingest goes continuous**
  (promoted 2026-07-23; conditional, not-now). Today the fussy gphoto2
  drive path hung when muppet load spiked — root cause was a stuck-gphoto2
  pileup (self-inflicted), *not* OpenSearch (idles ~3% CPU). But the
  aifabric-sessions ingest is currently HOURLY; if it goes CONTINUOUS it
  would compete with the camera's timing-sensitive USB path more often. If
  that starts biting the drive path, move the tethered EOS off muppet to a
  dedicated host. Candidate `vole` (Acer C720) is NOT ready — parked
  mid-flash to MrChromebox UEFI, half-dead screen, 2 GB RAM, and it's the
  aifabric x86 tiebreaker node. Moving the tether is a real project: install
  gphoto2, replicate the udev autosuspend rule (04a9:32e1 power/control=on),
  mask gvfs-gphoto2-volume-monitor, port the whole tether recipe. A Pi could
  also serve. Revisit only if muppet load actually starts biting.

## Decisions

- Tools are plain Python in astro `bin/` (no astro package deps) so they
  run on muppet's system python (numpy + PIL only).
- Deploy = `scp` to muppet `~/bin/` (no checkout on muppet yet).
- Focus metric: moment-based FWHM of brightest blobs, hot-pixel-resistant
  (3×3 smooth before peak pick); ~43 px = flat-window signature = "no
  stars", used as the cloud discriminator.
- Frames stay on muppet under `~/tmp/` (persists across reboots);
  nothing ships to S3 until there's a real deliverable.
