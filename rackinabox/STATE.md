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
(steel core / base / lid+walls), single 140 mm downdraught fan, dual-chamber PSU
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
  140 mm silicone gasket has no UK specialist source found (Quiet PC's
  AcoustiFan/Fansis ranges stop at 120 mm); Amazon UK marketplace instead.

## SCOPE CHANGE — the rack is now a CASE, not a laptop shelf (2026-08-12)

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

**Thermal must be re-derived.** The single 140 mm downdraught fan was specced
for 3 idle laptops. The real load is an always-on 65 W CPU + 3 spinning disks +
an NVMe under sustained tiled writeback for hours nightly (it will throttle if
it bakes). Re-check the fan **before** quoting the panels.

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
- **Thermals still un-re-derived** — the 140 mm fan was specced for 3 idle
  laptops; the real load is a 65 W CPU + 3 spinning disks + NVMe under sustained
  tiled writeback for hours nightly. Must happen before committing geometry.
  (Cast walls change this: much higher thermal mass, no panel resonance.)
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
