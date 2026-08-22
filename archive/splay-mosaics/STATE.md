# splay-mosaics — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- (new strand — nothing recorded yet)
- `~/splay` repo is the visual-techniques lab; its old `TODO.md` was absorbed
  into this list and deleted on 2026-07-11.
- Reference implementation for mosaic mode: `splay/apps/bayer_heatmap.py`
  + spec at `splay/design/bayer-heatmap.md`.
- splay backgrounds itself by default (fork + setsid after fail-fast checks;
  `-fg`/`--foreground` stays attached). Done 2026-07-11.

## Pending / loose ends

### Mosaic mode (strand headline)
- Mosaic mode: use the known Bayer pattern from the camera type.

### Splay viewer features
- Variable sum of n frames, loaded into memory.
- White balance adjustment taken from a selection.
- Plot heat map at a viewable scale.
- Subtract a variable background.

## Decisions
