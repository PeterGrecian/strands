# gardencam — state

*Created 2026-07-31 (forked from an astro-storage session that started the skycam
cleanup work and realised it's a distinct project → new strand).*

## Immediate work in flight: skycam incoming cleanup

**Problem:** `skycam_processor.py` (in `Berrylands/gardencam`, runs on puppy as
`skycam-processor.service`) encodes incoming jpgs → hourly mp4s → S3 + YouTube,
but **never deletes the incoming jpgs**. So `~/skycam-frames` on puppy grows
unbounded — **67G now**, on the root NVMe (468G, 65% used, 158G free). The old
pressure-based GC was retired 2026-07-01 and skycam never got a replacement.

**Ground truth (verified 2026-07-31):**
- incoming: `~/skycam-frames/<YYYY-MM-DD>/<HH>/*.jpg` (bare-date, 24 hour dirs/night)
- processed: `~/skycam-processed/<YYYY-MM-DD>/sky_<YYYYMMDD>_<HH>.mp4` (25G total)
- puppy nights present: 07-09 .. 07-31 (still actively capturing today)
- **completion gate is clean**: complete nights 07-25..07-28 show exactly 24
  incoming hours ↔ 24 processed mp4s (1:1). 07-29 = 24 incoming / 18 mp4s
  (hours 18–23 not yet encoded → per-hour gating keeps them). `enc_<...>_tmp`
  dirs in processed = in-progress encodes (skip).

**Decision (Peter):** skycam raw is **disposable** — the mp4/YouTube encode is the
final product. So cleanup does NOT ship raw anywhere (no bigstore, unlike astro):
once the deliverable exists, **delete** the raw hour. (Even S3 may be unnecessary
now — see IDEAS.)

**Tool DRAFTED (not yet tested/deployed):**
`Berrylands/gardencam/skycam-cleanup-incoming` — runs on puppy. Per-hour:
delete incoming `<date>/<HH>/` iff `sky_<ymd>_<HH>.mp4` exists non-empty in
processed. Newest `--keep N` nights (default 3) always kept (covers the
actively-capturing current night). `rm` not trash (raw is disposable + same-fs
trash wouldn't bound growth — the house rule's disposable exemption). Dry-run
default (`--go` to act), `--help`/`--hints`. **NEXT: dry-run on puppy, verify it
keeps unencoded hours + the safety window, then `--go`, then a daily timer.**

## Open questions / IDEAS
- **Is S3 still needed?** Deliverable is YouTube; S3 (`gardencam-berrylands-...`)
  may be redundant cost. See https://www.petergrecian.co.uk/gardencam/s3-stats.

## Seam with astro-storage
astro-storage owns the astro streams (keep-forever, bigstore-primary). This strand
owns gardencam/skycam (disposable raw, YouTube deliverable). The astrocam *capture
code* lives in the gardencam repo for historical reasons but its DATA is
astro-storage's. Don't send skycam data to bigstore as a keep-forever copy.
