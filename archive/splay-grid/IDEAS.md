# splay-grid — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->

- (2026-07-11) **Window resize drops the whole frame cache → visible reload.**
  The `VIDEORESIZE` handler in `splay` (main, ~line 1802) deliberately pops
  every non-FITS Surface from `self.images` and clears `_full_res_cache`. Why:
  JPEG frames are draft/DCT-decoded *at fit-size* (`_load_jpeg_for_fit`, ~5×
  faster than full decode + downscale), so the cache is window-size-specific;
  after a resize every cached frame is the wrong resolution. But it fires on
  *every* intermediate `VIDEORESIZE` during a drag, so the sequence re-decodes
  frame-by-frame — the "reloads when I resize" symptom.
  Fix options (in priority order):
    1. **Debounce** — flag + timestamp on resize, only flush ~150–250ms after
       the *last* event. Highest value, lowest risk; kills the drag waste.
    2. **Don't invalidate on shrink** — cached Surface is already big enough;
       let pygame downscale on blit, re-decode lazily. Only flush on grow.
    3. Lazy per-frame invalidation instead of eager pop-all.
    4. Cache keyed on (path, quantised-window-size) — resize-back hits warm
       cache. Probably overkill; grows memory.
  Note: this is splay-main viewer behaviour, not grid-specific — could argue
  it belongs in splay-mosaics (general viewer). Filed here since it surfaced
  in a grid session; move it at triage if it fits mosaics better.

