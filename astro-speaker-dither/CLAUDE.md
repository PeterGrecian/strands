# Strand: astro-speaker-dither

**Placeholder** (created 2026-07-13). Sub-pixel dither by *physically nudging
the camera* with a speaker/voice-coil actuator driven as a PWM DAC — the
commanded-dither mechanism, as opposed to VCM focus-breathing
(`astro-breathing`) or drift itself. Child of the umbrella strand
`astro-subpixel`; see its STATE.md (the "Dither sources" section) for the
current design.

Goal: break the position↔gain degeneracy and measure the intra-pixel /
fixed-pattern response by stepping the image across the sensor by known
sub-pixel amounts. The star that needs it most is **Polaris** (static on the
same pixels forever → no free dither from drift or breathing there).

- **Repos**: astro-side design + capture flags in `~/astro`
  (`astro/design/speaker-dither-rig.md`); the **Pi-specific rig code lives in
  `~/Berrylands/pwmaudio`** — PWM-as-DAC electronics shared with the deskpi
  speaker-tone work. This strand dir holds only curation files.
- **Hardware** (from astro-subpixel design): PWM-as-DAC (~10 kHz carrier) +
  RC (fc≈10 Hz) + current driver; 3-point corner mount, ~1 µm/mA, so
  0.1 px ≈ 0.77 µm. Parts ordered; bench build + µm/mA calibration (loaded)
  pending drivers.
- **Camera modes** (per astro-subpixel): astrocam = 2-axis between-frame
  stepping; v3w = 1-axis continuous S-streak; zenith cam = drift-clocked.

## Status

**Pre-hardware placeholder.** Exists so the speaker mechanism has a home and
this strand can be pointed at from `astro-subpixel`. Goes active when the
current drivers arrive and the rig is on the bench. Until then, the design
of record is `astro-subpixel` + `astro/design/speaker-dither-rig.md`.

Memory symlink is machine-local and created on first `cld -s
astro-speaker-dither` (see `.template/` recipe in `bin/cld`).

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to (astro or pwmaudio) —
   this strand dir holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
