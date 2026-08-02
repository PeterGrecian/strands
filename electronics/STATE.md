# electronics — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

**New strand + repo, created 2026-07-23** (from an ubersitrep idea: "we
probably need an electronics repo which sits between home-automation and
hardware and is about stuff I make to interface stuff"). Repo of record:
`~/electronics` (`PeterGrecian/electronics`).

Prior art that belongs to this strand but lives elsewhere for now:
- **`~/Berrylands/pwmaudio`** — the live body of work. "Make a Pi speak via
  PWM" capability on deskpi, plus the dither-rig driver electronics:
  - Stage 1 (done 2026-07-09): 220R → 8R speaker on GPIO18, pigpio
    `hardware_PWM` for clean tones (software PWM warbles on single-core A+).
  - Stage 2 (done 2026-07-09): 2N3904 low-side driver — louder but
    **beta-limited at ~200 mA** (speaker sees 0.5–1.5 V not 0–4.8 V).
  - Stage 2b (done 2026-07-25): **darlington 2N3904 → B882** — 2N3904 drives
    the B882 power stage, coil now pulls full available current. Force cap
    cleared, "the speaker drive works." See `pwmaudio/wiring.md` Stage 2b.
  - Dither tooling: `pwm-sine`, `pwm-pattern`, `pwm-ramp` (MOD_PCT=0 =
    smooth silent 20 kHz ramp, uncommitted). Circuit + findings in
    `pwmaudio/wiring.md`; experiments in `pwmaudio/experiments/`.
  - Gotchas: pigpiod resets socket on >~2000-pulse waves (chunk uploads);
    silence a stuck PWM with `hardware_PWM(18,0,0)`. See memory
    `project-pwmaudio`.
- **`~/astro/design/speaker-dither-rig.md`** — the astro-side design (mostly
  the *why*: sub-pixel dither, ~1 µm/mA, 0.1 px ≈ 0.77 µm, RC fc≈10 Hz).
- **`~/electronics/designs/eos-dc-switch.md`** (2026-07-23) — first design note
  landed: high-side P-MOSFET DC switch (2N3904 NPN buffer + IRF9540/AO3401),
  GPIO/Pico-W driven, distilled from a design chat. Raw chat kept at
  `~/electronics/chats/dcpower-switch`.

## Speaker-dither rig — folded in from astro-speaker-dither (2026-08-02)

`astro-speaker-dither` archived 2026-08-02; its **electrical + mechanical** work
lives here now (the astro *why* / µm-mA calibration / camera-mode choice is in
[[astro-science]]'s dither section). The PoC saga (deskpi bench):

- **Force/range are a SOLVED non-issue.** Small speaker was too feeble (no
  measurable shift); swapped to a **Faital Pro 4FE35** (4" full-range, 8 Ω),
  coil at full rail (5.6 V RMS ≈ 0.70 A / ~3.9 W — darlington delivers full
  current). Repositioned on the cone → **~3 mm cone travel ≈ ~230 px image shift**
  across a 640 frame. Problem **fully inverted: ~1000× too MUCH travel** vs the
  0.1 px ≈ 0.77 µm target. The camera even fell off the cone at big excursions.
- **Response is stick-slip, not proportional** (camera resting *in contact*):
  deadband → snap-to-detent → plateau. **Slow ramps do NOT cure it** (a friction
  contact has no elastic element). Detector is excellent (control 0.008 px, drift
  0.014 px). **Lesson: always interleave driven/undriven captures** (a 20 Hz-slam
  "16σ" result was a scene-drift artifact).
- **Carrier fix:** pigpio `set_PWM_frequency` snaps to a ladder (was 8 kHz,
  audible) — use `pi.hardware_PWM(18,40000,duty*1e6)` (true HW PWM) + shunt cap
  across the coil (**10 µF vital, +100 µF better**; fc ≈ 2.3 kHz/680 Hz) to kill
  the carrier. Watch D882 dissipation (~1 W free-air; keep 100% bursts short —
  fine dither is low-duty so it's fine).
- **NEXT, difficulty-ranked (do FIRST = hardest):**
  1. **Flexure stage + CSI-ribbon strain management — CRITICAL.** Sub-µm *smooth*
     motion needs a **flexure, not bearings** (bearings have ~µm stiction = the
     stick-slip). The **ribbon is the hard part** (stiffness/creep/hysteresis
     fights a soft flexure). Strategy: exploit the ~1000× excess travel to run a
     **stiffer flexure that swamps the ribbon**, then gear down to sub-µm. Design
     note (ribbon + 5 mitigations): `~/astro/design/speaker-dither-rig.md`.
  2. Bond camera→cone rigidly (easy; unblocks a proportional re-test).
  3. **Real DAC** (MCP4725 → linear current driver) — kills the carrier, finer
     low-end than 8-bit PWM. Phase 2; does NOT fix stick-slip; linear D882
     dissipates more → heatsink/current-source.
- Everything electronic + optical is proven (force, range, filtering, capture,
  detector); the remaining work is **mechanical**. Reusable deskpi harness:
  `/tmp/shift_test.sh <duty> <tag> <n>` + `/tmp/seq.py`; a calibration sweep
  (duty 2/5/10/20% interleaved → px-shift-vs-current) is spec'd. Also **drive at
  mechanical resonance** for max excursion, not DC. Data:
  `~/Berrylands/pwmaudio/experiments/dither-deflection.md`.
- **deskpi note:** recovered 2026-07-30 (RPi OS Lite armhf Trixie via
  cloud-init-init), now `deskpi.local`/**.71** on the `.0.x` LAN (pi-fleet
  `.4.154` is stale). ARMv6 bars rpicam/libcamera — capture via plain V4L2 on
  `/dev/video0` (see [[armv6-camera-v4l2-not-rpicam]]).

## EOS power-cycle switch — folded in from astro-canon-power (2026-08-02)

`astro-canon-power` archived 2026-08-02; folded here (it's a DC-power circuit).
Purpose: **power-cycle the Canon EOS 2000D when it hangs** (astro bombards it
with commands → it wedges; this is the watchdog reset, not just remote on/off).
Design of record: `~/electronics/designs/eos-dc-switch.md` (high-side P-MOSFET
IRF9540/AO3401 + 2N3904 NPN level-shifter, Pico-W/GPIO driven). Hardware on hand:
Pico W + P-ch MOSFETs. **Build deferred** — the cheaper first mitigation is the
**astro side rate-limiting its commands** (fewer wedges); build the hatch when
that isn't enough. Open when built: confirm the EOS DC-coupler/dummy-battery rail
(~7–8 V, 5 V vs 7.4 V), Pico via a front-end buck (never VSYS-direct at 7.4 V),
timed off→hold(caps drain)→on in MicroPython. **Astro keeps direct control — no
home-automation/MQTT in the overnight recovery path.** Sibling seam: astro-canon
(the [[astro-canon]] keeper) owns the camera as an instrument; this owns its
power/reset.

## Pending / loose ends

**Priority as of 2026-07-23:** rackinabox is the live bench project (in front of
Peter now). PWM-for-8R is almost finished. The EOS switch dropped in urgency —
see its note.

- **`rackinabox` — LIVE, on the bench now.** CAD + pro-fabricated enclosure for
  fans and electronics: mild-steel rectangular tube, mostly glued, baffled ATX
  PSU, IKEA Lack table as frame. Mechanical/packaging project; scope and whether
  it fully belongs in this strand still TBD, but it's the active build.
- **PWM amp for 8R — driver stage working (2026-07-25).** The PWM-as-DAC /
  driver stage feeding an 8Ω load (pwmaudio line of work). The beta-limited
  2N3904 was the last gap; the **darlington (2N3904 → B882)** clears it — coil
  sees full current. Final circuit + findings written up in `pwmaudio/wiring.md`
  Stage 2b. Feeds the tilt-dither / voice-coil actuator.
- **EOS DC switch — build deferred, still wanted as recovery hatch.** *Why it
  exists:* the **camera itself hangs when astro bombards it with commands**, and
  the switch is the power-cycle recovery. So it's a watchdog reset, not just
  remote on/off. If the **astro side rate-limits its commands** the camera
  behaves better and needs power-cycling less often — that mitigation is the
  cheaper first move, which is why the hardware build is now lower priority. Keep
  the design (`~/electronics/designs/eos-dc-switch.md`); build when the astro-side
  fix isn't enough. Open question when built: 5V vs 7.4V rail (confirm dummy
  battery input), Pico powered via a front-end buck (not VSYS-direct at 7.4V).
- **PWM amp for camera-tilt dithering.** Driver topology for the tilt-dither
  actuator — now a **working darlington (2N3904 → B882)**. Open question whether
  it should instead be a high-side P-MOSFET like the EOS switch; but with the
  darlington passing full force, that's now an optimisation, not a blocker.
  Overlaps the 8R/voice-coil driver work; decide the final topology once.

- **Disk power switch — designed 2026-07-27, ready to build.** Pico-W WiFi
  power switch for a **3.5" USB3 HDD enclosure**: switches one **12V barrel
  in→out** (the enclosure does its own 12V→5V + spin-up internally, so only one
  rail to break). High-side **IRF4905** P-MOSFET + **2N3904** NPN level-shifter
  (Peter's parts; no beta-limit — Q2 only sinks ~1.2 mA gate-pullup current).
  Pico W socketed on-board, powered via an **MP1584 buck** off 12V-in (never
  VSYS-direct at 12V). Laid out hole-by-hole on **board #3** (green
  breadboard-PCB) from the new protoboard inventory. Full design + build order:
  `~/electronics/designs/disk-power-switch.md`. Sibling of the EOS switch.
  *Open before building:* confirm enclosure barrel polarity; set buck 5V out on
  a meter before it touches VSYS; add Cgate only if turn-on dips the supply.
- **Protoboard inventory catalogued 2026-07-27** —
  `~/electronics/designs/protoboard-inventory.md` + photos: 2× strip-of-3, the
  breadboard-PCB (claimed by the disk switch), and a Slice-of-Pi Pi-hat. "Use
  up boards on hand" reference before buying more.
- **Migrate pwmaudio's circuit-design content into `~/electronics`** (decided
  new-repo-now, migrate-later 2026-07-23). Move `wiring.md`, the driver design
  and experiments; leave/duplicate the Pi-specific deploy scripts where they
  run. Preserve history where it's worth carrying.
- ~~**Finish the driver stage**: replace the beta-limited 2N3904.~~ **Done
  2026-07-25** — solved with a **darlington (2N3904 → B882)** rather than the
  BC337 / logic-level MOSFET originally sketched. Coil now sees full current.
- **Voice-coil-as-µm-actuator** for `astro-speaker-dither`: bench build when
  current drivers arrive; calibrate µm/mA **loaded** (mount stiffness changes
  the response). This strand owns the circuit; astro owns the measurement.
- **Decide the schematics format/tooling** for the repo (KiCad? hand-drawn +
  photo? plain-text netlist?) — an area for schematics and design discussion,
  per the founding idea.

## Decisions

- **Spun out as its own repo + strand 2026-07-23**, sitting between
  `home-automation` and `hardware` — the "circuits I build to interface things"
  layer that neither neighbour owns (`hardware` explicitly excludes actuators
  that are another project's deliverable; `home-automation` is off-the-shelf
  integration). Repo `~/electronics`; migrate pwmaudio's design content in
  later rather than big-bang moving it today.
- **Ownership seam:** electronics owns *how a circuit is designed and built*;
  the driven project (e.g. `astro-speaker-dither`) owns *why* and what it
  measures.
- **Driver force problem solved with a darlington (2N3904 → B882), 2026-07-25**,
  not the BC337 / logic-level MOSFET originally listed. The 2N3904 drives the
  B882 power stage; coil pulls full available current. "The speaker drive works."
  Circuit lives in `pwmaudio/wiring.md` Stage 2b until the pwmaudio→electronics
  migration. (Also recorded in `astro-speaker-dither` STATE.)
