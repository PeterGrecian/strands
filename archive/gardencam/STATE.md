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

## S3 for skycam — investigated 2026-07-31 (NOT droppable yet; more coupled than thought)

Decision framing (Peter, in CLAUDE.md): S3 is **per-camera** — keep springcam, drop
skycam. Turned out **skycam's S3 is far more load-bearing than the framing assumed**;
the "just stop uploading" plan was tried, broke things, and was **rolled back**.

**What `skycam/videos/` actually feeds (all confirmed live):**
1. **YouTube day-build** — `rerender_cloudcam_day.py` re-downloaded the hourlies from
   S3 every run. ✅ FIXED this session (see below) — no longer needs S3.
2. **`gardencam-daily-concat` lambda** — deployed + wired to `s3:ObjectCreated` on
   `skycam/videos/*.mp4` (verified in bucket notification config). Each hourly upload
   fires it → daily concat → feeds `combined_timelapse_lambda` (sky-over-garden, a
   **springcam-facing** deliverable; code present, may not be currently deployed).
3. **Website `/skycam/videos` gallery** (`mywebsite/lambda`) reads the prefix.

So (2)+(3) still depend on the per-hour S3 upload. **Dropping skycam's S3 is a
multi-part design change (AWS pipeline + website), not a processor toggle.**

**What actually shipped this session:**
- ✅ **Rerender local-source fix** — `rerender_cloudcam_day.py` now sources hourlies
  from local `~/skycam-processed/<date>/` first (cached-rerender-dir, then S3
  fallback). Verified on puppy: built the 07-30 day mp4 (643MB) from local files,
  zero S3 downloads for present hours. **Deployed on puppy + committed.** Pure
  improvement, kept regardless of the S3 question.
- ✅ **`S3_UPLOAD` toggle** added to `skycam_processor.py` (default "1" = on; sets
  `self.s3=None`, flowing through every `if s3 is not None` guard — disables uploads
  AND switches the per-hour idempotency gate from the S3 head-check to
  local-mp4-exists). **Committed, default ON, NOT wired into the service.**
- ⏪ **Tried `S3_UPLOAD=0` on puppy (~14:51–16:18 UTC), then ROLLED BACK** once the
  lambda/website coupling surfaced. Service is back to `s3_upload=True`. The 2 hours
  encoded during the window (07-31 hrs 13,14) were **backfilled to S3** by hand, so
  no gap in daily-concat / gallery. Lesson: `skycam/videos/` is an integration point,
  not a dead-end — check bucket-notification wiring + website before flipping.

Both code changes are on branch **`gardencam-skycam-s3-toggle`** (2 commits). They're
safe to merge as-is (nothing turns S3 off). puppy runs them as working-tree edits.

**Existing 114GB — lifecycle NOT applied.** `skycam/videos/` = 2221 objs / **114GB**;
`skycam/rerender/` = 163 objs / 34.5GB. A 7-day expiry was drafted + approved, but
**not applied** — the daily-concat lambda + website gallery still read this prefix,
so expiry can't happen until the drop-S3 design (below) removes those readers.
Draft (7-day, scoped to `skycam/videos/`, springcam-safe) at scratchpad
`skycam-videos-lifecycle.json`.

**To actually drop skycam's S3 (future work), all readers must move off it:**
- daily-concat / combined-timelapse: run locally on puppy (like the rerender now
  does), or retire if the sky-over-garden composite isn't wanted.
- website `/skycam/videos` gallery: point at YouTube, or retire.
- THEN `S3_UPLOAD=0` + lifecycle-expire the 114GB is safe.

## Other open
- **Push the branch + open a PR** for `gardencam-skycam-cleanup-incoming` in the
  Berrylands repo (committed, not pushed). The S3-toggle code above will be a
  second commit / branch.

## Seam with astro-storage
astro-storage owns the astro streams (keep-forever, bigstore-primary). This strand
owns gardencam/skycam (disposable raw, YouTube deliverable). The astrocam *capture
code* lives in the gardencam repo for historical reasons but its DATA is
astro-storage's. Don't send skycam data to bigstore as a keep-forever copy.
