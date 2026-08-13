# manim — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

**`earth_nights`** (2026-08-13) — astro observing nights drawn as arcs on the
Earth's sphere, from the first observed night through to the midwinter
solstice. Lives in `~/manim`:

- `scenes/earth_nights.py` — the renderer (Cairo + ffmpeg)
- `scenes/solar.py` — dependency-free solar position (NOAA/Meeus)
- `scenes/astro_nights.py` — bigstore reader for all six camera streams
- `scenes/pointing.py` — per-camera-EPOCH boresight + FOV, sourced and
  certainty-tagged (8 epochs across 6 streams)
- output: `media/earth_nights.mp4` (1080p60, 45 s) — **not uploaded yet**

The globe is tilted 23.44°, lit from screen-left, and pitched up 34° so
Berrylands' latitude circle is presented face-on rather than edge-on. Each
night is an arc centred on local midnight: a dim wide band for the
astronomical night available (sun below −10°, the fleet's own capture gate),
with one coloured arc per camera that actually ran, its length the hours
captured. Timeline interpolates between nights, then projects weekly to
2026-12-21.

**The point it makes:** ~4.3 h of observable night at midsummer against
~13.9 h at midwinter — 3.2×, from nothing but axial tilt. Midwinter is when
this fleet gets its observing time.

## Data coverage (as extracted 2026-08-13)

167 night-records, 2026-05-21 .. 2026-08-12, ~316k frames:

| stream | nights | span | notes |
|---|---|---|---|
| eclipticam | 65 | 06-09..08-12 | |
| astrocam | 59 | 06-09..08-12 | |
| eos | 18 | 07-25..08-12 | from `manifest.csv` |
| starcam | 11 | 05-21..06-04 | older summary schema |
| skycam | 10 | 07-18..07-27 | re-binned by `night_of()` |
| canon | 4 | 08-08..08-12 | |

Cameras routinely exceed 100% of the −10° window (astrocam 117%, skycam 163%)
— they start before the gate and run past it. Expected, not a bug.

## Finding: the EOS field is ~8x smaller than the design doc assumed

EXIF from the CR2s on bigstore: the 2000D shoots at **53mm (2026-08-08) and
55mm (2026-08-10..)** on the EF-S 18-55 kit zoom — not the 18mm assumed by the
nesting table in `design/accumulation-bucket-refinement.md`. Real field 22.9 x
15.4 deg (354 sq deg) against the assumed 63.6 x 45.0 (2,862). So the DSLR is
the **smallest field and the deepest instrument** in the estate (~13.8"/px),
and the containment hierarchy is stronger than the doc's own table showed.
The 53->55mm step falls exactly on the position_index 1->2 boundary (the
by-eye "marker 0" refocus). Worth feeding back into the astro repo — the
design doc's table is still wrong there.

## Correction: skycam is a v1 Pi camera (2026-08-13)

First drawn at 120x30 deg on a guess, making it the widest field in the fleet
(10,800 sq deg). Peter caught it: it's a v1 Pi for cloud timelapse. Frame EXIF
confirms `ov5647` / `Raspberry Pi` — same sensor and stock lens as eclipticam
v1 and starcam, so the measured plate_scale 0.0206 applies (53.4 deg). Frames
are a 16:9 1296x728 crop of the full sensor field, so vertical ~30 deg.
**1,602 sq deg, a 6.7x overstatement corrected.** Lesson: an `assumed` value
should never be allowed to dominate the picture — check the frames' EXIF
before guessing a field.

## Decisions

- **Cairo + ffmpeg, not manim.** The repo README already documents manim
  OOMing past 6 GB on long single-play animations with updaters. A rotating
  globe is exactly that shape. Peak RSS here is ~690 MB and flat.
- **No ephem/skyfield.** Solar position is ~30 lines of NOAA/Meeus in
  `solar.py`, validated against known London sunrise/sunset times and the
  ±23.44° solstice declination. Keeps the venv as installed.
- **Night = sun below −10°**, matching the fleet's own capture gate
  (`camera.json` `state.sun_altitude_night_deg`), not civil (−6) or
  astronomical (−18) twilight — so the arcs track when the cameras genuinely
  consider it night.
- **Arcs, not a textured sky-dome.** Chosen so the epoch/midwinter story is
  the visual, not decoration.

## Pending / loose ends

- **Not published.** `render-and-upload.sh` only handles manim-rendered
  scenes (`media/videos/<stem>/1080p60/<Class>.mp4`); `earth_nights` writes to
  `media/` directly, so it needs either a flag or a small generalisation
  before it can go to S3 / the `/manim` page.
- Frame thumbnails riding the arcs were part of the original idea but are not
  implemented — only astrocam/eclipticam/canon have posters (`max.jpg` etc.);
  eos and skycam have none.
- `sun_direction()` in `earth_nights.py` is now unused (the sun vector is
  built directly in view space); harmless, but could go.
- The projected-forward segment is weekly and flat — it shows no cameras,
  which is honest but visually empty for the last third of the clip.
