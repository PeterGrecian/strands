# Strand: astro-breathing

**Works out sub-pixel sampling from focus breathing — small VCM focus dithers on
eclipticam's v3w that shift the image radially by fractions of a pixel.**

Sub-pixel sampling on eclipticam's v3w (IMX708 Wide) by exploiting **focus
breathing**: small LensPosition (VCM) changes produce a mild magnification
change, radially shifting the image on the sensor by fractions of a pixel.
A ladder of focus positions gives a dithered frame set from a rigidly
fixed camera; combining them (drizzle / multi-frame super-resolution)
recovers detail beyond the native ~80″/px sampling.

Core insight: the VCM does not need to be repeatable — each frame's actual
magnification is measured from the stars themselves, so hysteresis and
stiction are harmless as long as the lens *moves*. Commanded lp is a
shift generator, not a control variable.

- **Repos**: code in `astro/` (eclipticam-specific under `astro/eclipticam/`,
  shared tools in `astro/bin/`); deployment via `ansible` role
  `eclipticam-astro`. This strand dir holds only curation files.
- **Hardware**: eclipticam (192.168.0.66), camera 0 = IMX708 Wide,
  full-res 4608×2592, SRGGB10, manual-focus via LensPosition 0–15 dpt.
- **Data**: frames land on puppy via the NFS mount at
  `~/eclipticam-frames/` in the canonical day/night layout.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
