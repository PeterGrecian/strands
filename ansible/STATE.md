# ansible — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- Strand scaffolded 2026-07-20. Mission: apply & maintain config across the
  fleet (edit `~/ansible`, roll out, verify). See CLAUDE.md.

## Pending / loose ends

Everything is still in IDEAS.md awaiting triage into here. Headline items:
- pi-fleet reporter cadence 1→5 min + immediate-on-boot (fleet-wide; Lambda
  offline threshold must move with it).
- Add vole as a first-class fleet member (reporter must degrade cleanly on a
  non-Pi host).
- pi-fleet → fleet rename: tech debt, do only as a ride-along, never standalone.
- General fleet-maintenance catch-up (drift sweep).

## Decisions

- **Seam with pifleet** (2026-07-20): pifleet owns *membership + dashboard
  liveness*; this strand owns *making changes stick on hosts*. pifleet decides
  what the fleet should look like; ansible implements & rolls it out.
- **Cadence** (2026-07-20, with Peter): whole-fleet 5 min + `OnBootSec=0`, not
  a per-host vole override. Requires an ansible re-deploy and a lockstep Lambda
  threshold change.
