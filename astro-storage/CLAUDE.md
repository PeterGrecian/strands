# Strand: astro-storage

**Keeps astro data under control — the full storage lifecycle (squash, ship,
retain) of every camera stream as one system.**

## Mission

Own the full storage lifecycle of the astro data streams (astrocam,
eclipticam, starcam, skycam) as **one unified system**:

1. **Data-size reduction** — squashing: temporal-resolution reduction +
   spatial sum8/sum2. The primary lever against t² cost growth.
2. **Disk management** — keep capture hosts and muppet's big disks from
   filling; ship-and-free per stream (no pressure-based GC — retired
   2026-07-01).
3. **Glacier** — Deep Archive backup of reduced/keeper nights.

Retention is a *resolution schedule*, not keep-vs-delete: recent nights at
full cadence, older nights progressively squashed, squashed form kept ~forever
(the RRD pyramid → O(1) storage). See STATE.md / IDEAS.md.

> **Squash is DORMANT (Peter, 2026-08-12)** — we don't squash much now, because
> there is more storage: bigstore is 5.5T at **27% used, 4.0T free**. Squash is a
> **disk-pressure** tool, and the pressure that justified it (bigdisk 97%,
> bigdisk2 93%) went away when the streams moved to bigstore. The t² argument
> above still holds long-term, so this is dormancy, not retirement — **revisit
> when capacity tightens**.
>
> Two things that do *not* change: **`cold-archive-night` still requires
> squashed+manifested input**, so anything bound for Deep Archive still gets
> squashed on the way; and **squashing is not a redundancy measure** — it shrinks
> the single copy, it does not make a second one. Don't reach for it to answer a
> "this night has only one copy" problem.

## Canonical tools

- **`super/bin/squash-starcam-night`** — the squash front-half (built
  2026-07-17). Reduces an unsquashed starcam night (`HH` raw + `HHb` twin) to
  its canonical `HH-sum8` + `HHb-sum2` products in place and deletes the raw,
  staging sums on a roomy disk so it's safe when the target disk is full. Header
  documents the full method + post-hoc bookkeeping. **Never run on a keeper
  night** (marked ★ on `/astro/storage/<month>`).

## Canonical tools (in the `astro` repo)

- **`astro/bin/cold-archive-night`** — the astro cold path: squashed+manifested
  night → `s3://astro-berrylands-eu-west-1/cold/…` Deep Archive, upserts
  `astro-storage-inventory` DynamoDB, updates `whereisallthedata.csv`. Its
  documented "future work" (the squash front-half) is still TODO.
- **`astro/bin/storage-report`** — scans each host's on-disk astro data +
  capacity → DynamoDB; `/astro/storage` page renders it.
- **`/astro/storage`** page — the truth surface (mywebsite `lambda/routes/astro.py`).

## NOT this strand

**glacier-app** (`~/glacier-app`, bucket `glacier-app-archive`) is a separate
*product prototype* (storage-app for images/friends). It must not carry astro
data. In one session 17 eclipticam nights landed there by mistake; they were
reconciled on the page (`report-glacier-app-nights`), not moved. Don't reach
for glacier-app to archive astro data — use `cold-archive-night`.

## Launch

`cld astro-storage` — read STATE.md (current pressure + in-flight),
IDEAS.md (inbox). Update both on `dcp`.
