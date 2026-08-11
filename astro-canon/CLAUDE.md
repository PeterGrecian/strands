# Strand: astro-canon

**Keeps the Canon EOS 2000D running as a remote astro instrument — the
big-sensor, real-optics complement to the Pi cameras.**

The **Canon EOS 2000D** as a remotely-operated
astro instrument, tethered over USB to **muppet** via gphoto2. The
big-sensor, real-optics complement to the Pi cameras (astrocam,
eclipticam): 24 MP APS-C, EF-S 18-55 zoom, remote focus drive.
Weather-gated — each visit is typically "PSU/battery + clear night +
run the tools, then improve them".

Spans **`~/astro`** (tools live in `bin/`: `eos-focus-sweep`,
`eos-star-watch`) and **muppet** (`~/bin/` copies, camera on USB, data
under `~/tmp/eos-focus/` and `~/tmp/eos2000d-test/`). Later: RAW frames
into the astro FITS pipeline, deliverables to mywebsite.

The camera's many tether quirks are recorded in STATE.md — read them
before touching gphoto2; each one cost real debugging time.

**Focus is MANUAL and must not be driven.** The lens is on MF, focused by
hand through the viewfinder ("marker 0", 2026-08-10) — that beat every
automated method by 3x. The night runs `--no-focus`: no rack, no drive,
not even after a power cycle. The `d` coordinate never tracked focus and
is retired. Do not "improve" this by reinstating a focus sweep.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to (usually astro) —
   this strand dir holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
