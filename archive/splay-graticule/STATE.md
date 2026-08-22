# splay-graticule — state

*Curated summary of where this strand is. Updated at the end of each session.*

## 2026-07-14 — astrocam moved to FITS; overlay flipped + rescaled

The astrocam pipeline no longer emits JPEG sweeps — nightly output is now
**full-res FITS** candidate frames (`<night>/<hh>/NNNN.fits.fz`, 3280×2464,
OV5647 BGGR, unbinned). Peter hit two symptoms viewing them in splay:
*upside-down images* and *the graticule doesn't fit*. Two distinct causes,
both now fixed:

- **Upside-down** = a splay render bug. FITS is bottom-up (row 0 = bottom, DS9
  convention); splay blitted it top-down, so FITS rendered flipped vs every
  other frame type and vs the top-origin overlay. Fixed: `_read_fits_image`
  now `np.flipud`s at load — the single entry point, so render / hot-pixel
  mask / native_size / probes all share one top-origin frame. (splay `5f18aec`,
  pushed.)
- **Doesn't fit** = the epoch fit was authored against the old 1640×1232 JPEG
  sweep; FITS is 3280×2464 (exactly 2×). Chose to **scale the JPEG fit ×2**
  rather than reclick: pole×2 → (930.0,1332.5), k÷2 → 0.02081 deg/px, phi/
  parity/spin unchanged (the Y-flip means both frames are top-origin, same
  handedness). Regenerated `_epoch.{reg,wcs,fit}.json` on the mount with
  `--ref-frame …/2026-07-13/01/3201.fits.fz --margin 1800`.
- **Validated** against real FITS brightness: Kochab lands within (−2,0) px
  (peak 15.8×median), Schedar within ~10 px (8.7×) — opposite sides of the
  frame, so parity is right, no mirror. Fainter anchors (Polaris 2.5×, Deneb
  1.8×) confirm the inherited ~0.3–0.5° error; fine to navigate by.

**Recommended next:** a fresh click-refit on a FITS frame (5 named-star probes
→ `make-epoch-graticule --anchor`) would tighten the pole/edge error the ×2
scale inherited from the binned-JPEG fit. Deferred — the ×2 overlay is usable.

## What exists (as of 2026-07-11)

- **splay overlay engine** (`~/splay/splay`, pushed to origin/main):
  - DS9 `.reg` parser handles circle/point/box/**line/vector/polygon**, and
    captures `tag={...}` per shape.
  - **Scope hierarchy** frame → sequence → day → epoch, most-specific-wins,
    resolved by walking up the dir tree (`foo.reg`, `_sequence.reg`,
    `_day.reg`, `_epoch.reg`). Paths resolved to **absolute** at launch so the
    walk-up reaches the tree root (a relative launch broke this once).
  - **Rotation:** day/epoch overlays are sky-fixed at a reference orientation;
    splay rotates them about the pole by
    `(frame_utc − ref_utc) × 15.041 × screen_spin`. Frame UTC from FITS
    DATE-OBS, else per-dir index→UTC from summary.json, else mtime.
  - Keys: `o` toggle, `O` cycle scope, `Ctrl-o` cycle tagged layer; `r`
    reload clears the `.reg` cache. HUD shows scope/layer/rotation.
  - State files now record launch `cwd` + absolute `paths`
    (`~/.splay-loaded.json`) — a reader can kill & relaunch to the same place.
    Commits: e63adb6, 0eca194, a730a50, 3ebbc0b.

- **Overlay generator** `~/astro/bin/make-epoch-graticule` (on astro
  `main`, pushed). Emits `_epoch.reg` + `_epoch.wcs.json` (+ `_epoch.fit.json`)
  at a camera's frames_root. Two modes: `--wcs-json` (reuse a fit) or
  `≥3 --anchor NAME X Y` (least-squares fit pole/scale/roll, reports RMS).

- **Live astrocam overlay** at `/mnt/muppet/astrocam-frames/_epoch.{reg,
  wcs.json,fit.json}`, script-produced. Original JPEG-sweep fit: pole
  ~(465,666), k≈0.0416 deg/px (150″/px), joint Deneb+Cassiopeia fit **RMS
  0.29°**, ref = 2026-07-07 frame_00071. **Superseded 2026-07-14** by the ×2
  FITS-coord fit above (pole (930,1332), k≈0.0208) — see the 07-14 section.
  Stars labelled: Polaris, Deneb, Vega, Capella, Kochab, Pherkad, Alderamin,
  the Cassiopeia W, Mizar, Dubhe, Merak.

## Pending / loose ends

- **Exact cursor-restore** on splay relaunch (`--start-at` / read
  `.splay-frame.json`) — relaunch currently lands on frame 1, not the frame
  Peter was viewing.
- **Real solve** (`solve-field` + SIP) to tighten edge distortion — the
  single-scale gnomonic leaves edge stars ~0.4–0.5° off. Blocker was flat-flux
  extraction on the binned Bayer stack; fix = feed a proper source list.
- Overlays only exist for astrocam. eclipticam v1/v3w would each need their
  own epoch fit (different sensor/orientation; v3w uses moon-anchor star ID).
- No `_day.reg`/`_sequence.reg` in use yet — epoch is the only populated scope.

## Decisions

- Strand created 2026-07-11.
- **No PRs** — merge branches to main and push directly (or commit to main).
  Confirmed 2026-07-11.
- WCS is a **hand fit, not a plate solve** — deliberate, because solve-field
  won't extract usable quads from the binned Bayer stacks. Navigate-by
  accuracy (~0.3°) is the accepted target.
- `.reg` shapes are **sky-fixed**; rotation happens in splay at draw time
  (not baked per frame). One epoch fit serves all nights until a camera move.
- **CCW-with-time = negative screen angle** (`screen_spin = -1`), because a
  y-down image makes +angle clockwise. This bit us once; it's the default.
