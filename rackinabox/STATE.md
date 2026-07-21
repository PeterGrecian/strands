# rackinabox — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **Deliverable repo:** `~/rackinabox/` — LIVE on GitHub (private):
  https://github.com/PeterGrecian/rackinabox.
  - `DESIGN.md` — canonical spec (+ flat-build revision note).
  - `cad/panels.py` — **flat laser-cut panel generator** (ezdxf): baseboard,
    4 finger-jointed walls w/ steel-tube pass-throughs, fan panel → `cad/export/*.dxf`.
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

## Pending / loose ends

- Shelf count/heights: currently 2 rows (z=20,160) hard-coded in panels.py —
  confirm against real laptop heights, parametrise if 3.
- PSU baffle + dual-chamber divider not yet in the flat panel set (only the
  outer shell + shelves are). Add divider panel + PSU cutout.
- Leg sockets + dovetail rear cable panel not yet ported to panels.py DXF.
- Nest all panels onto a sheet layout for the laser quote.
- Confirm real ATX PSU dims for the baffle cutout.
- Decide magnet vs gravity-hook for side walls (rear settled = magnet).

## Decisions

- Shelves: 12×12×1.5 mm mild steel square tube (cheap, non-sagging, ~80% open).
- Joinery: 3D-printed plug-and-slot connectors, Araldite-bonded; no drilling.
- No polystyrene near the PSU (fire + reflective) — open-cell foam / scrap only.
- Design lives in `~/rackinabox/`, not in the strand dir; strand holds curation.
