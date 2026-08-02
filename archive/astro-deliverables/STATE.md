# astro-deliverables — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists (as of 2026-07-10)

- **Night pages + calendar** at www.petergrecian.co.uk/astro. Calendar pages
  render from precomputed `<camera>/index.json` (one GET, built nightly by
  `build-calendar-index`) — deployed 2026-06-28.
- **moon-net** deliverable: `moon-extract` / `moon-overlay` / `moon-deliver`
  wired into publish-night-cam; cumulative moon-net render published per
  night. Solver + star-ID still to build.
- **moon-drift.mp4** (tracked-moon clip stitched from the 700×700 crops)
  added to moon-deliver 2026-07-10.
- **"Open in Splay"** flow: night player button → localhost daemon
  `super/bin/splay-launcher` (port 8765) → opens the frames dir in splay.
- **/astro/storage** page watches skycam raw growth on puppy (no
  ship-and-free pipeline yet).

## Pending / loose ends

- `splay-launcher.service` systemd unit is referenced in the daemon's
  docstring but doesn't exist yet.
- moon-net plate-scale solver + star identification.
- **Peter has an adjustment to the deliverables in mind involving both astro
  and mywebsite — to be described next session (noted 2026-07-10).**

## Decisions

- Strand created 2026-07-10. (Move durable design choices here as they're made.)
