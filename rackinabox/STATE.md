# rackinabox — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **Deliverable repo:** `~/rackinabox/` — LIVE on GitHub (private):
  https://github.com/PeterGrecian/rackinabox.
  - `DESIGN.md` — canonical spec (+ flat-build revision note).
  - `cad/panels.py` — **flat laser-cut panel generator** (ezdxf): baseboard,
    4 finger-jointed walls w/ steel-tube pass-throughs, fan panel → `cad/export/*.dxf`.
    Now emits **M4 corner screw provision** (clearance + insert bores),
    **tab-aware** via `tab_centres()`/`pick_screw_z()` so every screw lands
    mid-tab in solid material on both mating panels (`SCREW_*` params).
  - `cad/render.py` — reproducible DXF→PNG preview (cut / M4 clearance /
    insert colour-coded) → `renders/<name>_dxf.png`.
  - `cad/assembly.scad` — 3D walkthrough (assembled + exploded); `renders/`.
  - `cad/rackinabox.scad` — 3D printed parts (fan template etc.).
  - `.venv/` (gitignored): ezdxf, boxes, matplotlib.

## Build decision — REOPENED 2026-08-12: cast walls, not laser-cut panels

**The flat laser-cut route is no longer the plan.** Peter has built with
**cardboard shuttering + sand/PVA composite** before (a speaker cast in place,
clingfilm-wrapped, horizontal shuttering with a cardboard top face, mix "quite
runny" so it self-levels and takes the pattern's shape faithfully). That method
now supersedes the DXF path for the walls.

**Material split — each does what it is good at:**

- **Walls = cast sand/PVA composite.** This is where the acoustics live. Mass
  and damping is what kills noise; a thin stiff panel (6 mm ply) is light and
  *rings*. Sand-loaded composite is heavy for its stiffness and lossy
  (grain-to-grain friction turns vibration into heat) — same principle as
  sand-filled speaker stands. **Thickness becomes free**, which dissolves the
  6 mm-derived problems below.
- **Baffle = high-quality cardboard / foam board.** A baffle is a *flow
  divider*, not a sound barrier: light, stiff enough to hold shape, easy to cut
  and adjust once real airflow is visible. Vindicates the dual-chamber design —
  the ~30 mm baffle floor always did a pneumatic job (sealing against
  recirculation), never a sonic one.
- **Fan panel = the light, cuttable material too.** Peter has hole saws; a
  hole saw is exactly the right tool for the one round cut in the design.

**The fan must NOT be cast in.** Its frame is **exactly 1 mm** at the wall.
Dense slurry poured around a thin-walled 140 mm square tube pushes inward on all
four sides; blade tip clearance is well under a millimetre, so even slight bowing
causes a blade rub — precisely the noise the box exists to prevent. 1 mm is also
almost nothing for the cast to key into. And the fan is the most
maintenance-prone part in the box (bearings, dust) while casting is the least
reversible method available. It stays in the light, replaceable material.
If anything *is* ever cast around: use a **sacrificial former** (wrapped 140 mm
block, pulled after the pour) leaving a socket, never the fan itself.
**Applies ×4 under the 2026-08-13 cooling scheme** — and more forcefully: four
cast-in fans would be four irreversible commitments to the most
maintenance-prone, most likely-to-be-revised parts in the box. Cut the holes,
mount the fans in the light replaceable material.

**Still to establish about the composite:** sand:PVA ratio; behaviour at
fixings (a screw may crush/pull out where it would hold in timber — if so, cast
in captive fixings or embed timber corner blocks while wet); panel thickness
(sets both cure time and pressure on anything embedded). **Cure is slow** — PVA
cures by water loss, thick sand-loaded panels dry outside-in over days and will
warp if dried unevenly or unrestrained, so cast flat and weighted. **Fire:** PVA
softens with heat and cardboard burns — keep composite and foam away from the
PSU chamber, consistent with the existing no-polystyrene-near-PSU rule.

**Next experiment: one test panel**, not the whole box — weight, does it take a
screw, real cure time. That single pour answers more than any amount of CAD.

**Joinery superseded too:** screws + corner posts, not finger joints. Posts
locate the panels, so panels become plain rectangles — no corner parity, no
kerf, no tool-radius concern. This also fixes the unresolved M4 grip problem
(inserts want 8–9 mm engagement, 6 mm was shy): screws go into a post, not a
panel edge.

**What survives from the old plan:** the architecture, not the fabrication.
Silent home-server enclosure under an IKEA LACK table, 3-layer nested design
(steel core / base / lid+walls), ~~single 140 mm downdraught fan~~ **4-fan
top/bottom scheme at 5 V (see "Cooling architecture")**, dual-chamber PSU
thermal quarantine, carpet as acoustic sink, tool-less teardown. Full detail in
`~/rackinabox/DESIGN.md`. `cad/panels.py` still generates a valid finger-jointed
DXF set (corner parity verified, M4 tab-aware screws) — **kept for reference,
but it is no longer the build**; its fan bore and finger joints are superseded.

## Ruled out 2026-08-12 — do not re-research

- **No one sells a 414 mm panel with a 140 mm bore.** (Note: the box is
  **414 mm** external — 402 inner + 2×6 — not 450.) Every off-the-shelf "fan
  plate" is a ~150 mm *cover* plate for blanking an unused PC fan slot. At our
  size the panel *is* the enclosure wall, so the fan hole was never separable
  from the panel order. Hole saw + light panel now answers this anyway.
- **All pull-through rubber fan mounts fail on a thick panel.** Acousti AFM03B
  states **max panel thickness 1.8 mm**; Noctua NA-SAV2/NA-SAV4 are sheet-steel
  parts — SAV4's "extra long" is for thicker *fans* (pawls numbered for
  10/14/15/20/25 mm fan bodies), not thicker panels. Decoupling therefore comes
  from a silicone gasket + machine screws, or from bedding in a compliant
  material — not from rubber pins.
- **SendCutSend UK shipping is UNCONFIRMED** — US-based; their shipping terms
  detail free US and $19 Canada, no UK option surfaced. The whole DXF plan
  rested on them. Moot if casting wins.
- **UK DXF cutting fallback if ever needed:** [Cut Online
  CNC](https://www.cut-online.co.uk/) (nr London) takes DXF/DWG, cuts
  MDF/ply/acrylic/aluminium to 50 mm on a 2440×1220 bed, 7-tool changer doing
  profiling/engraving/**pocketing**. Caveat: a router has finite tool diameter,
  so internal corners come out radiused — finger joints and the 12.3 mm square
  tube pass-throughs would need **dogbone relief** added to the generator.
  Others: Timberite (Canterbury, 01227 765011), Cworkshop, Woodsheets.
- **Bought parts that remain valid and cheap:** Arctic 140 mm fan grill **£1.19**
  at [Scan UK](https://www.scan.co.uk/shop/computer-hardware/cooling-air/system-and-case-fan-grilles)
  — worth it for a fan firing down at ankle height over carpet and cables.
  *(2026-08-13: now **×4** at £1.19 each, still trivial. The bottom pair are
  intakes at floor level over carpet — grills there are about keeping carpet
  fluff and cables out of the blades, and a **filter** on the intake pair is
  worth considering, which is also the argument for positive pressure.)*
  140 mm silicone gasket has no UK specialist source found (Quiet PC's
  AcoustiFan/Fansis ranges stop at 120 mm); Amazon UK marketplace instead.

## COOLING ARCHITECTURE — settled 2026-08-13 (supersedes the single downdraught fan)

**Scheme: 2× 140 mm bottom (intake) + 2× 140 mm top (exhaust), all 12 V fans
run at 5 V, plus provision for a couple of 120 mm local fans inside.**
Supersedes the single 140 mm downdraught fan throughout this file.

**Why top/bottom rather than downdraught:** it works *with* convection —
cold intake low, hot exhaust high — instead of pushing air down against a
rising plume.

### The arithmetic (do not re-derive)

A 140 mm fan shifts ~120 m³/h. Air at ~25 °C: ρ≈1.18 kg/m³, c_p≈1005 J/(kg·K)
→ volumetric heat capacity ≈ **1190 J/(m³·K)**.

    120 m³/h = 0.0333 m³/s  →  0.0333 × 1190 ≈ 40 W/K per fan (ideal)

**Derate for reality** — static pressure in a sealed box with grill + baffle
(×0.6), deliberately slow/quiet RPM (×0.5), recirculation/short-circuit
(×0.7) → **≈8 W/K per fan in situ**.

| Config | Ideal | In situ | ΔT at 150 W |
|---|---|---|---|
| 1 fan | 40 W/K | ~8 W/K | ~19 °C |
| 2 top + 2 bottom | 80 W/K | ~16 W/K | ~9 °C |

**⚠ How fans combine — the trap.** *Parallel* (2 side-by-side at the top):
**flow adds**. *Series* (top and bottom, same air passing both): **pressure
adds, flow does not.** So 4 fans ≈ 2× the flow of one, not 4×. And the
**local 120s are internal recirculation — they contribute ~0 W/K of net heat
export.** Their entire value is cutting component-to-air thermal resistance at
the disks and NVMe, which have no heatsinks. The W/K budget is a single
shared box property, spent once — *not* a per-fan allowance to multiply up.

### The real reason for 4 fans: acoustics, not capacity

Fan noise scales ≈ RPM⁵ while airflow scales ≈ RPM. Four fans at ~40% RPM
deliver the same air as one at high RPM for a tiny fraction of the acoustic
power (~20 dB quieter each; four sources only sum to ~+6 dB). **More fans,
slower** is the silent-PC answer. Secondary wins: **redundancy** (1 of 4
failing is a capacity dip, not a thermal event — important for a headless box
holding data) and **coverage** (two bottom intakes = one under the disks, one
under the board, attacking the dead-pocket problem directly).

### What the margin is FOR

With 4 fans there is so much thermal headroom that **the design goal becomes
acoustic and structural, not thermal**. Plausibly run all four at 5 V, never
exceed ~10 °C rise, and get an inaudible box. **Spend the margin on silence,
not on a restrictive layout.**

**ΔT is the easy half.** Air rise is small next to the silicon-to-air drop:

    T_cpu = T_ambient + ΔT_air + (P × R_heatsink)

A stock Wraith cooler is ~0.3–0.5 °C/W → at 80 W that's **24–40 °C above local
air**, dwarfing the 2–10 °C air rise. To improve CPU temps you change the
*heatsink*, not the fans. The **disks are the opposite case** — no heatsink at
all, so they need air moving *across* them; three stacked 3.5" drives with no
gap is the classic dead-pocket failure, and bulk exhaust temperature will read
cool while a drive cooks. Disks want to stay under ~45 °C.

### Build rules

- **Intake area is now the binding constraint**, not fan capacity. 4× 140 mm
  wants ~4 × 150 cm² of free area. In a cast wall that is a lot of material
  removed — it is a **structural** question for wall thickness, and it is four
  hole-saw cuts. **140 mm likely exceeds Peter's hole saw set; 4× 120 mm still
  gives ~176 m³/h ideal and is the safer bet for the tools actually owned.**
- **Pressure balance — decide deliberately.** Match top and bottom counts and
  ideally the same model. Slight **negative** (top wins) is usual for a sealed
  box; **positive** if you want filtered intake and no dust ingress. Get it
  wrong and hot air leaves through every unsealed seam — and with cast walls
  the seams are wherever panels meet posts.
- **Local 120s = provision, not fitted.** Put in mounting points and a spare
  5 V feed; add them only if the disks *measure* hot. Do not fit on spec.
- **⚠ 12 V fans at 5 V may not START.** They run happily once spinning but
  many (sleeve-bearing, unbranded) will not start from cold at 5 V — and a fan
  that fails to start after a power cut is a **silent thermal failure in a
  headless box**. Either test each fan starts from cold at 5 V before
  committing it, or run **PWM fans at 12 V on a low duty cycle**, which keeps
  full starting torque.
- **Use 3-pin/4-pin and read the tach.** On 2-pin at 5 V there is no feedback,
  so the first sign of a dead fan is a thermal event. This fleet has form for
  silent progressive failures (the muppet USB socket) — a fan that fails
  *legibly* is worth the extra wire.

### Feedback control — Pi optional, and NOT in the safety path

Idea (Peter): neat closed-loop control with a Pi. Sensing is nearly free —
`smartctl -A` for disk temps, `k10temp` for CPU, `nvme smart-log` for the
accumulator — so only actuation is being added. **The control target is
acoustic**: not "keep it cool" (there is 5× margin) but "run as slowly as
possible under a threshold". The real prize is **telemetry** — fan RPM and
temps logged means a failing fan or a clogging intake shows up as *drift*,
not as a thermal event.

- **⚠ FAIL-SAFE RULE: fans default to FULL SPEED when uncommanded.** Never let
  a crashed Pi, a full SD card or a failed boot become a thermal event on the
  box holding the data. PWM does this naturally (no signal = 100% duty). Wire
  it so the controller **slows** fans from a safe default, never **enables**
  them from off. A dead Pi must mean a noisy box, not a cooked one.
- **Check the motherboard first.** B550 boards have 4-pin PWM headers with
  BIOS fan curves tied to CPU temp — zero extra hardware, no new failure mode.
  Likely covers the top/bottom pair. The Pi's *unique* contribution is
  **disk-temperature-driven** control, which motherboard headers cannot do
  (they cannot see SMART). Honest split: motherboard drives CPU-linked fans,
  Pi drives disk-local fans + logging.
- `fancontrol`/lm-sensors **on nit itself** could drive PWM headers from SMART
  temps with no separate Pi at all — one less machine, one less failure mode.
  A Pi only wins if control must survive nit being down, or be OS-independent.

### Open — the load figure is not pinned down

Peter cited **80 W**; the earlier estimate here was **130–160 W** (65 W CPU +
3 spinning disks at ~6–8 W each + board + in-box PSU losses). At ~8 W/K in
situ that is 10 °C vs 20 °C rise — and 20 °C above a 25 °C August room starts
to matter for disks. **Settle the real figure before finalising fan count and
intake area.**

## SCOPE CHANGE — the rack is now a CASE, not a laptop shelf (2026-08-12)

Peter is buying **nit**, a storage/compute server (Ryzen 5 5600, B550 mATX,
2×16 GB DDR4, 512 GB NVMe accumulator + ~512 GB workspace, 3× 3.5" HDD, the
already-earmarked ATX PSU). **He has ruled out buying a tower case — this
enclosure is nit's case.** Full spec lives in the `hardware` strand's STATE.md.

Why a tower was dropped: the locked design gives ~140 mm per shelf (steel tube
rows at z=20/160, sized for laid-flat laptops); a tower is 350–450 mm. Same
physical argument that already ruled pog out.

**New geometry the panel set does not have — these gate the laser quote:**

- **mATX board deck** — 244×244 mm, 9-hole standoff pattern. New geometry, not
  a variation of the shelf rows.
- **3.5" drive mounting** for 3 disks (+ possibly one 2.5" OS SSD) — side rails
  or a bay bracket, with **decoupling grommets**: 3 spinning disks are the
  noisiest thing in the box and would otherwise defeat the silent-enclosure goal.
- **Rear I/O shield cutout** — standard mATX rectangle, new in the wall panels.
- **Shelf heights re-derived** — a board deck + CPU cooler is a different
  z-budget from a laptop. Feeds the existing "2 rows or 3" question.
- **PSU divider** was already pending — now load-bearing, not optional.

**Thermal — RE-DERIVED 2026-08-13, see "Cooling architecture" above.** The
single 140 mm downdraught fan was specced for 3 idle laptops; the real load is
an always-on 65 W CPU + 3 spinning disks + an NVMe under sustained tiled
writeback for hours nightly. Answer: **2× top + 2× bottom at 5 V**, which has
ample capacity — the binding constraints are now **intake area** (structural,
in a cast wall) and the **disks' local airflow**, not fan capacity.

**Acoustics are load-bearing, not nice-to-have** — nit runs at *night*, which
is exactly when the house is quiet and when the capture pipeline needs it.

**⚠ Superseded by the cast-walls decision above** — there is no sheet to nest
and no laser quote to get. The board deck, drive mounts and I/O cutout are still
*required geometry*, but they are now features of a cast/screwed build, not DXF
panels. Do not resume nesting work.

**Coupling (unchanged):** this makes the rack *more* consolidated. The offsite
subset is still required alongside — consolidation is not redundancy.

## Pending / loose ends

**Next action: pour one test panel.** ~300×300 at a chosen thickness. Measure
weight, whether it takes a screw directly, and real cure time. Everything else
downstream depends on those three numbers.

- Capture the composite recipe from Peter: **sand:PVA ratio**, and whether the
  speaker build was a layered laminate or a single pour (established: single
  horizontal pour, cardboard top face, runny mix).
- **Decide wall thickness** — free now, sets mass, cure time, and fixing depth.
- Fixings in the composite: does a screw hold, or are cast-in inserts / embedded
  timber corner blocks needed? Plan before pouring — it must be done wet.
- Corner post material + section (timber vs aluminium angle).
- ~~Thermals un-re-derived~~ **✅ DONE 2026-08-13** — see "Cooling
  architecture". What it leaves open: **(a) settle the real load figure**
  (80 W vs 130–160 W); **(b) intake area vs cast-wall structure** — 4 holes is
  a lot of material out; **(c) confirm hole-saw size actually owned** (140 mm
  likely unavailable → 4× 120 mm is the fallback); **(d) pressure balance**
  positive vs negative; **(e) test 12 V fans start from cold at 5 V**.
  (Cast walls help: much higher thermal mass, no panel resonance.)
- Shelf count/heights: was 2 rows (z=20,160) for laid-flat laptops — **re-derive
  against nit's board deck + cooler height**.
- PSU baffle + dual-chamber divider — now **foam board**, not a cut panel.
  Confirm real ATX PSU dims for the cutout. Keep combustibles clear of the PSU.
- Leg sockets + rear cable access still unresolved in the new scheme.
- Decide magnet vs gravity-hook for side walls (rear settled = magnet) — may be
  moot if walls are heavy castings held by posts.
- Fan size may be set by **which hole saw Peter actually owns** — 140 mm is
  large for a hole saw (many sets stop at 127 mm). A 120 mm fan is an acceptable
  answer if that is what the tool cuts. Check the set before finalising.
  **Now ×4 cuts, not ×1** — so this gates more of the build than it did, and
  4× 120 mm (~176 m³/h ideal) is still ample. Check the set early.

## Decisions

- Shelves: 12×12×1.5 mm mild steel square tube (cheap, non-sagging, ~80% open).
- **Joinery (revised again 2026-08-12): screws + corner posts.** Posts locate
  the panels and carry the load, so panels are plain rectangles. Supersedes the
  finger-joint scheme of 2026-07-31 (which itself superseded the Araldite-bonded
  plug-and-slot). This resolves the M4 grip problem rather than working around
  it: heat-set inserts want ~8–9 mm engagement and 6 mm was shy — irrelevant
  once screws drive into a post instead of a panel edge.
- No polystyrene near the PSU (fire + reflective) — open-cell foam / scrap only.
- Design lives in `~/rackinabox/`, not in the strand dir; strand holds curation.
