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

## Build decision (locked)

- **Flat laser cut, single 6 mm, finger-jointed corners, DXF for SendCutSend.**
  Supersedes the 9mm-walls + 3D-printed-plug shell for the enclosure.
- Corner-parity **verified** (ring scheme; mating edges tile exactly, no
  overlap/gap) — see the check in the parity-fix commit.
- Design is a silent home-server enclosure under an IKEA LACK table: 3-layer
  nested architecture (steel core / MDF base / LACK lid+walls), single 140 mm
  downdraught fan, dual-chamber PSU thermal quarantine, carpet as acoustic sink,
  tool-less two-step teardown. Full detail in `~/rackinabox/DESIGN.md`.

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

**⚠ Do not nest/quote the sheet layout until the board deck, drive mounts and
I/O cutout are in `panels.py`** — otherwise the quote is for an obsolete set.

**Coupling (unchanged):** this makes the rack *more* consolidated. The offsite
subset is still required alongside — consolidation is not redundancy.

## Pending / loose ends

- Shelf count/heights: currently 2 rows (z=20,160) hard-coded in panels.py —
  **re-derive against nit's board deck + cooler height** (was: real laptop
  heights), parametrise if 3.
- PSU baffle + dual-chamber divider not yet in the flat panel set (only the
  outer shell + shelves are). Add divider panel + PSU cutout.
- Leg sockets + dovetail rear cable panel not yet ported to panels.py DXF.
- Nest all panels onto a sheet layout for the laser quote.
- Confirm real ATX PSU dims for the baffle cutout.
- Decide magnet vs gravity-hook for side walls (rear settled = magnet).
- Screw joinery open Qs: insert grip in 6 mm (M4 heat-set wants ~8–9 mm
  engagement; 6 mm is shy — accept reduced grip or add a face boss); and
  whether 3 screws/corner is enough or they should tie to the shelf rows.

## Decisions

- Shelves: 12×12×1.5 mm mild steel square tube (cheap, non-sagging, ~80% open).
- **Joinery (revised 2026-07-31): screwed and demountable.** Tab-and-slot
  (finger joints) locate the panels and carry the shear; **M4** screws hold it
  closed and let it come apart — supersedes the earlier "plug-and-slot,
  Araldite-bonded, no drilling" line (which conflicted with the tool-less
  teardown goal). Caveat: M4 nut across-flats is 7 mm > the 6 mm material, so a
  true edge-trapped captive nut does **not** fit a 6 mm edge — use **M4
  threaded inserts (heat-set/press) or corner blocks** seated on the panel
  *face*, not an edge nut pocket. M4 clearance is already the fan-mount value in
  panels.py (`FAN_HOLE_D = 4.5`), so it's consistent.
- No polystyrene near the PSU (fire + reflective) — open-cell foam / scrap only.
- Design lives in `~/rackinabox/`, not in the strand dir; strand holds curation.
