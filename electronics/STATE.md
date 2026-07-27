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
