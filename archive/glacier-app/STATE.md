# glacier-app — state

*Curated summary of where this strand is. Updated at the end of each session.
DESIGN.md holds the full design; this file tracks progress against it.*

## What exists (as of 2026-07-11 evening)

- Repo `~/glacier-app` (graduated): ingest/, site/, ledger/.
- Bucket `glacier-app-archive` (eu-west-2) live: **6 archives ingested**
  (scans, 1990s, 2002–2005, ~3.7 GB Deep Archive) with ledger, listings,
  meta, thumbs. Smoke test passed; ingest continuing through year dirs.
- **/glacier contents page live** (2026-07-11, mywebsite d9c04a9 +
  glacier-app f98ed23): `site/render.py` renders static HTML from the
  bucket's ledger+meta (bucket = source of truth) →
  `users/peter/site/index.html`; mywebsite Lambda serves it behind Basic
  Auth (password at SSM `/glacier-app/page-password`, set via `secrets`),
  thumbs 302 to 5-min presigned URLs. IAM scoped to hot surface only
  (site/, thumbs/ — never archives/ or ledger). Verified end-to-end incl.
  401 without auth. **Re-run `site/render.py` after each ingest batch.**
- Owner captions render (Tissot caption on 1990s card).

## Session split (2026-07-11)

Two parallel Claude sessions: **ingest/upload** (owns ingest/, the bucket
writes, and syncing `ledger/ledger.jsonl` to git) and **site/page** (owns
site/render.py + the mywebsite /glacier route). The page renders from the
bucket, so it never conflicts with in-flight ingest — just re-run
`site/render.py` after batches land.

## Pending / loose ends

- Finish the 66 GB ingest (remaining year dirs, camcorder per-event tars,
  misc-2009-2010 junk drawer) — *ingest session*; re-render the page after
  — *site session*.
- Local `ledger/ledger.jsonl` in git lags the bucket — *ingest session*
  syncs when it settles.
- Basic Auth is the v1 gate; Cloudflare Access / per-user auth remains
  the product answer (DESIGN.md privacy section).
- Thumbnail sampling: even-sampling verdict still open (DESIGN.md Q1).

## Decisions

- Extract everything browsable at ingest, while data is hot; Deep Archive
  objects are dark afterwards. (2026-07-10, DESIGN.md)
- Restore unit = tar ≤ 4 GiB; camcorder tarred per event. (2026-07-10)
- Ledger is JSONL in bucket + git now, DynamoDB when the app grows users.
  (2026-07-10)
- Strand-ified 2026-07-11 around Peter's README.md + DESIGN.md.
