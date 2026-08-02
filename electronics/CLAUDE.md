# Strand: electronics

**The circuits that interface things — driver circuits, level shifters,
PWM-as-DAC, the bench layer between software and actuators.**

## Mission

The **things Peter makes to interface things** — electronic circuit design and
construction. The bench strand: driver circuits, level shifters, PWM-as-DAC
stages, RC filters, transistor/MOSFET drivers, sensor front-ends, connectors
and power feeds for the actuators and interfaces he builds by hand. Where a
schematic gets drawn, a circuit gets breadboarded, and findings ("beta-limited
at ~200 mA", "chunk uploads >2000 pulses") get written down so the next build
starts from knowledge, not from scratch.

**It sits *between* `home-automation` and `hardware`:**
- `hardware` = *the host as a machine* — disks, CPUs, power rails, firmware,
  cooling. Explicitly out-of-scope there: "peripherals and actuators that are
  the deliverable of some other project."
- `home-automation` = Zigbee/WiFi/Pi *integration* of off-the-shelf smart-home
  kit.
- `electronics` = the **circuits Peter designs and builds himself** to interface
  one thing to another — the soldering-iron-and-oscilloscope layer neither of
  the other two owns. The actuator/driver that `hardware` pushed out and that
  `home-automation` doesn't cover lands here.

**In scope:** circuit design (schematics, component choice, biasing), bench
construction (breadboard → veroboard → PCB), PWM-as-DAC + RC-filter DAC stages,
transistor/MOSFET/driver stages and their current/beta limits, level shifting,
connectors/wiring/power feeds for home-made interfaces, and the design-discussion
+ measurement record behind each. Reusable capabilities (e.g. "make a Pi speak
via PWM", "drive a voice coil as a µm actuator") live here as designs; the
host-specific deployment code can live in the driven project's repo.

**Out of scope:** the *host machine* itself (→ `hardware`), off-the-shelf
smart-home integration (→ `home-automation`), and the *science/deliverable* a
circuit serves (e.g. what sub-pixel dither *measures* → `astro-speaker-dither` /
`astro-subpixel`). The line: electronics owns *how the circuit is designed and
built*; the driven project owns *why*.

## Repos & neighbours

- **Repo of record:** `~/electronics` (`PeterGrecian/electronics`) — created
  2026-07-23. Home for schematics, design discussions, and circuit build notes.
- **Migration candidate:** `~/Berrylands/pwmaudio` — the PWM-DAC / 2N3904 driver
  work (`wiring.md`, `bin/`, `experiments/`) is exactly this strand's material.
  Its circuit-design content should migrate into `~/electronics` later (the
  Pi-specific deploy scripts may stay in pwmaudio or the driven project). See
  memory `project-pwmaudio`.
- **Downstream consumer:** `astro-speaker-dither` (+ `astro-subpixel`) drives the
  voice-coil-as-µm-actuator built here; that strand owns the astro *why*, this
  one owns the *circuit*.
- **Neighbours:** `hardware` (host machines), `home-automation` (smart-home
  integration).

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Circuit-design/build content commits to `~/electronics`; deploy code
   commits to the repo it runs on — this strand dir holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's pending,
   decisions made. Keep it curated prose, not a log.
