# gardencam — state

*Created 2026-07-31 (forked from an astro-storage session that started the skycam
cleanup work and realised it's a distinct project → new strand).*

## DONE (2026-07-31): skycam incoming cleanup deployed

`skycam-cleanup-incoming` is **written, tested, deployed, and committed**. The
unbounded-growth problem is solved.

**What shipped:**
- Tool lives in `Berrylands/gardencam/skycam-cleanup-incoming` (+ `.service` /
  `.timer`). Committed on branch `gardencam-skycam-cleanup-incoming` (not yet
  pushed / no PR — do that next session or on request).
- On puppy: tool installed to `/usr/local/bin/skycam-cleanup-incoming`; daily
  system timer `skycam-cleanup-incoming.timer` at **04:30 UTC**, service runs as
  user `peter`, enabled + verified (`Result=success`).
- **First live run reclaimed 56G**: `~/skycam-frames` 67G → 11G; root fs free
  158G → 215G (52% used). Verified: safety window (newest 3 nights) intact,
  07-18's unencoded tail (hrs 00–07) correctly kept.

**Surprise found during testing (worth remembering):** nights **07-09..07-17**
survive as tiny (~100K each, ~800K total) remnant dirs with real jpgs but NO
processed mp4 (their `~/skycam-processed/<date>` dirs don't exist — processing
only began ~07-18). The tool correctly keeps them (deliverable-gated), so they
sit forever as harmless noise in the dry-run output. Negligible bytes; left
alone. Also a stray root-owned `~/skycam-frames/2026/07/` (1.2M) — the tool's
`YYYY-MM-DD` regex safely ignores it.

---

## Original problem (now solved — kept for context)

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

**Tool behaviour (as deployed):** runs on puppy. Per-hour: delete incoming
`<date>/<HH>/` iff `sky_<ymd>_<HH>.mp4` exists non-empty in processed. Newest
`--keep N` nights (default 3) always kept (covers the actively-capturing current
night). `rm` not trash (raw is disposable + same-fs trash wouldn't bound growth
— the house rule's disposable exemption). Dry-run default (`--go` to act),
`--help`/`--hints`.

## S3 for skycam — investigated 2026-07-31 (per-camera; springcam keeps S3)

Decision framing (Peter, in CLAUDE.md): S3 is **per-camera**. Keep for springcam
('garden' — its S3 stills feed `combined_timelapse_lambda`); drop for skycam
('sky' — YouTube is the deliverable; per-hour S3 copies grow ∝ t², never read).

**Blocker found (important):** dropping skycam's S3 upload is NOT a one-line
toggle, because the **YouTube day-video build re-downloads the hourlies FROM S3**.
`rerender_cloudcam_day.py` sources hourlies from `~/skycam-rerender/` (empty) and
falls back to S3 download every run — verified in puppy's journal. So S3 is
currently load-bearing for the deliverable, even though the mp4s are created +
consumed on the same host (wasteful round-trip). See memory `skycam-s3-roundtrip`.

**Plan (agreed direction, Peter): make ffmpeg-local self-sufficient.**
1. Fix `rerender_cloudcam_day.py` to source hourlies from local `~/skycam-processed/`
   first (S3 fallback only for old dates whose locals are gone). ← NEXT
2. Verify a YouTube day-build works local-only (no S3 reads).
3. THEN set `S3_UPLOAD=0` on `skycam-processor.service` (puppy).

**Code DONE (committed-ready, NOT deployed):** `S3_UPLOAD` env toggle added to
`skycam_processor.py` (default "1" — protects springcam/others; sets `self.s3=None`
→ flows through every `if s3 is not None` guard, disabling uploads AND switching
the per-hour idempotency gate from the S3 head-check to local-mp4-exists).
`S3_UPLOAD=0` line staged in `skycam-processor.service` but must stay unset live
until step 1+2 land. Do NOT deploy `S3_UPLOAD=0` before the rerender fix.

**Existing 114GB cost recovery (Peter: "add S3 lifecycle expiry", window TBD):**
- `skycam/videos/` = 2221 objs / **114GB** (the ∝ t² dead weight); `skycam/rerender/`
  = 163 objs / 34.5GB (day videos; left alone). No lifecycle config exists yet.
- Drafted rule scoped to `Prefix: skycam/videos/` (safe — springcam is under
  `springcam/` + bucket-root `garden_*`/`thumb_garden*`/`averaged*`, untouched).
  Draft at scratchpad `skycam-videos-lifecycle.json` (30-day expiry). **Window not
  finalised** (Peter: "lets think"). NB expiry must exceed how far back a day is
  ever re-rendered — currently same-day, but that's coupled to the round-trip
  above; once step 1 makes rerender local-source, `skycam/videos/` stops being
  read at all and the window can be short.

## Other open
- **Push the branch + open a PR** for `gardencam-skycam-cleanup-incoming` in the
  Berrylands repo (committed, not pushed). The S3-toggle code above will be a
  second commit / branch.

## Seam with astro-storage
astro-storage owns the astro streams (keep-forever, bigstore-primary). This strand
owns gardencam/skycam (disposable raw, YouTube deliverable). The astrocam *capture
code* lives in the gardencam repo for historical reasons but its DATA is
astro-storage's. Don't send skycam data to bigstore as a keep-forever copy.
