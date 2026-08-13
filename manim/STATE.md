# manim — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

**`earth_nights`** (2026-08-13) — astro observing nights drawn as arcs on the
Earth's sphere, from the first observed night through to the midwinter
solstice. Lives in `~/manim`:

- `scenes/earth_nights.py` — the renderer (Cairo + ffmpeg)
- `scenes/solar.py` — dependency-free solar position (NOAA/Meeus)
- `scenes/astro_nights.py` — bigstore reader for all six camera streams
- output: `media/earth_nights.mp4` (1080p60, 45 s, 6.4 MB) — **not uploaded yet**

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
