# astro-storage — state

*Updated 2026-07-29*

## bs nightly sync — two-camera topology (2026-07-29)

Full design: **`DESIGN-bs-nightly-sync.md`** (this dir). Refines the inbox idea
`end-of-night-sync-to-bs` into a concrete asymmetric design, ground-truthed
against both cameras on 2026-07-29.

**bs** = muppet `/mnt/bigstore/astro-data` (5.5T, 1.2T/21%), NFS **sync** export,
**soft** mounts at `/mnt/muppet/bigstore` (ansible strand owns the mount; live on
eclipticam already). House tree already populated by the bigstore-xfer backlog
pull (`<cam>-frames/night/<date>/`); the `run-*.sh` on bs are **one-shot backlog
migrations**, NOT the recurring sync — that's this strand's seam.

**The asymmetry (Peter's decisions):**
- **astrocam → DIRECT to bs.** Already an NFS-direct writer but to the *wrong*
  disk: capture.py writes to `~/astrocam-frames` = the old 839G bigdisk (**97%
  full**). Fix = **repoint that mount bigdisk → bigstore**. No local staging
  (6.8G SD). Mount-drop safety = local tmpfs spool + drain (shallow, 694M free;
  fine for rare scheduled muppet maintenance). *Blocked on ansible adding
  astrocam as a bs mounter* (see hand-off below).
- **eclipticam → STAGE-then-COPY.** Powerline link ~100Mbit → can't write capture
  direct. Captures to local SSD (`/mnt/ssd`, **91% full**), then end-of-night
  rsync SSD → bs, **verify, ship-and-free** (keep newest 3 nights local).

**BUILT this session:**
- **`super/bin/eclipticam-ship-night`** — the eclipticam back half. rsync SSD →
  bs, `--checksum` dry-run verify (zero diffs), then `trash` (never rm) nights
  outside the 3-night safety window. Soft-EIO tolerant (bs down ⇒ non-destructive
  bail + retry next run). `--go`/`--keep`/`--help`/`--hints`. **Verified with a
  real dry-run on eclipticam against the live bs mount** (16 nights detected,
  newest 3 protected, `trash` resolves via `~/super/bin` fallback since super/bin
  isn't on eclipticam's login PATH). Not yet run with `--go`.
- **`eclipticam-ship-night.{service,timer}`** (staged in strand dir, not
  installed) — daily ~09:00 Europe/London oneshot. Hand-install or fold into
  ansible.

**bs vs squash/cold-archive (Part 3):** this sync is deliberately **agnostic** —
it lands verified full-cadence nights on bs and stops. bs = principal live store;
squash-in-place + cold-archive-night are downstream consumers of the bs tree.
The precise relationship (permanent-hot-record + squash-in-place vs
landing-zone-then-free) is **TBD — Peter deferred it to the data-reduction day**
([[data-reduction-day]] / [[glacier-every-day]]).

**HAND-OFF → ansible strand:** add **astrocam** as a bs NFS *mounter* (host_vars
`astrocam.yml`): mount `muppet.local:/mnt/bigstore/astro-data/astrocam-frames` at
`/home/peter/astrocam-frames` (soft), **replacing** its current bigdisk mount.
Coordinate rollout so capture isn't writing to a dead path. Until then Part 1
(astrocam repoint) is blocked; Part 2 (eclipticam) is unblocked and built.

**Next actions:**
1. Enable Part 2: `eclipticam-ship-night --go` on one old night, confirm land +
   verify + trash, then install the timer. Biggest immediate win (91% SSD).
2. Part 1 after ansible adds the astrocam bs mount: repoint fstab, restart
   `astrocam-capture.service`, watch a frame land on bs; then add the tmpfs
   spool/drain follow-up.

## Data relocation tooling (2026-07-18)

## Data relocation tooling (2026-07-18)

`super/bin/ship-astro-data` — copy an astro tree to roomier storage, **verified,
copy-only, direct-routed**. Sibling of squash-starcam-night: that one *shrinks*
in place, this one *relocates*. Key rules it enforces:
- **Copy only** — source never touched; a human does the delete afterwards.
- **Direct routing** — a remote→remote transfer is driven ON the source host so
  bytes go straight src→dst, never relayed through the box you typed on (pip).
  To ship puppy→muppet you `ssh puppy '...'`; pass `--dst-addr <IP>` (from
  `resolve-host`) because mDNS can hand back a flaky link-local IPv6.
- **Verified** — after the copy, a `--checksum` compare pass; success is only
  reported if it's byte-clean.
- **Dry-run by default** — nothing moves without `--go`.
- Has `--hints` (AI surface) + `--help` (human), per house convention.

**DONE (2026-07-18/20) — two root disks relocated + freed:**
- muppet `~/starcam-backup` (112.7 GB) → `/mnt/photodisk/backups/starcam-backup`
  (local). puppy `~/eclipticam-frames` (56 GiB, static, last capture 2026-06-25)
  → muppet `/mnt/photodisk/backups/eclipticam-frames` (driven on puppy, direct).
  Both checksum-verified (0 diffs, exact file/byte match — twice for eclipticam).
  Peter deleted both sources 2026-07-20: **muppet / 94%→47% (118G free), puppy /
  88%→72% (127G free).**
- ship-astro-data verify had a false-positive (inherited `--info` stats read as
  diffs — cried wolf on both clean copies); fixed + regression-proven (super
  82168fb). Fails-safe, so no risk, but now correct.

**Still tangled — eclipticam exists in 3+ trees on muppet** (not reconciled):
`/mnt/photodisk/backups/eclipticam-frames` 56G (→06-25, the shipped copy),
`/mnt/bigdisk/eclipticam-frames` 74G/60,963 files (→07-04),
`/mnt/bigdisk2/eclipticam-frames` 85G/22,747 files (→07-12). Overlapping backlog
copies from the 2026-07-12 rsync + Deep-Archive episode; which are redundant is
unresolved — a future dedupe/reconcile job (Peter deferred it 2026-07-20).

TODO next: reconcile the 3 eclipticam trees; roomy-disk targets for the rest of
puppy's ~345 GB (astrocam 132G, starcam 122G) — photodisk won't hold it all, so
squash-first or another big disk.

## Squash tooling + method (2026-07-17)

The front-half squash is now a tool: **`super/bin/squash-starcam-night`**
(built this session; not yet on muppet's PATH — copied to `~/` and run there).

**Method** — an unsquashed starcam night is hour buckets `HH` (full-res raw,
2592×1944, ~5 GB/hr) + `HHb` (half-res twin, ~1.5 GB/hr). Canonical squashed
form (mirror an already-done night e.g. 2026-05-30): per hour keep
`HH-sum8` (raw summed ×8 via `astro/bin/pair-sum --n 8`) + `HHb-sum2`
(b-twin ×2), **delete the raw** `HH`/`HHb`. pair-sum accumulates in uint32 →
lossless; only temporal resolution is spent. Night ~40 GB → ~6–8 GB (~0.17×).

**Photodisk staging** — bigdisk is ~95% full, so we can't write sums before
freeing raw. The tool works one hour at a time: sums → staging on
`/mnt/photodisk/backups` (218 G free; note: photodisk root is root-owned,
only `backups/` is peter-writable), verify (dims/NSUMMED/uint32), *then*
delete that hour's raw and move the small sums into place. Peak extra on the
target disk ≈ one hour of sums (~700 MB), never the whole night. Ctrl-C-safe
between hours.

**Bookkeeping after a night** (mirror other squashed nights, not automated):
`~/astro/whereisallthedata.csv` (zero raw/binned bytes, set raw_sum8 +
binned_sum2, notes "squashed sum8+sum2") and DynamoDB `astro-storage-inventory`
(night+loc key, `shrunk=true`, `bytes.on_disk`, `fmt.res_class="sum8 mosaic"`).
`/astro/storage` renders from these.

**KEEPERS — never squash.** Clearest night of each ISO week, marked "★ keeper"
on `/astro/storage/<month>`. As of now: **2026-05-23, 2026-05-28**. (This
session started to squash 05-23 by mistake before the page flagged it a keeper;
the partial sum8 was removed, raw intact.)

## What this strand owns (Peter, 2026-07-13)

astro-storage is the **one unified system** for astro data's whole lifecycle:
- **Data-size reduction** — squashing (temporal-resolution reduction +
  spatial sum8/sum2), the primary lever against the t² cost growth.
- **Disk management** — the on-disk footprint across the fleet (capture hosts,
  muppet's big disks, USB sticks), keeping capture hosts from filling.
- **Glacier** — Deep Archive backup of the reduced/keeper nights.

These are not three projects; they're one policy. Retention = a resolution
schedule (see IDEAS.md, the t² argument), and glacier is where each stage's
durable copy lands.

## The two systems — keep them separate

- **astro cold pipeline (THIS strand's tool)** — `astro/bin/cold-archive-night`
  → `s3://astro-berrylands-eu-west-1/cold/…` (Deep Archive), tracked in
  `astro-storage-inventory` DynamoDB + `whereisallthedata.csv`, surfaced on
  `/astro/storage`. Works on **squashed, manifested** nights; endpoint is
  "sources deleted". **This is the canonical path for astro data.**
- **glacier-app** — a *separate product prototype* (storage-app for
  images/friends), bucket `glacier-app-archive`. **Not for astro data.**
  It has its own repo/ledger/web catalog. Lives at `~/glacier-app`.

**Wrong turn, now reconciled (2026-07-12/13):** 17 eclipticam nights
(2026-06-25..07-11) got shipped to Deep Archive via glacier-app by mistake,
because this session reached for the product instead of `cold-archive-night`.
Decision: leave the bytes where they are (they're safe), don't re-upload —
just make `/astro/storage` tell the truth. `astro/bin/report-glacier-app-nights`
upserts deep-archive rows for those nights pointing at the glacier-app bucket,
notes-flagged "not the canonical astro cold path". Page now correct;
2026-07-04 shows both copies (it exists in each system). Future astro nights
go through `cold-archive-night`.

## Storage pressure map (2026-07-13)

| Host | Volume | State |
|---|---|---|
| muppet | /mnt/bigdisk (839G, 15yo Seagate, USB3) | ~91% — astro streams ~735G are the bulk; images/ 61G archived, deletable |
| muppet | /mnt/bigdisk2 (93G, same spindle) | 93% — holds eclipticam backlog copy (90G) |
| eclipticam | /mnt/ssd 112G | ~88% — 17 nights in Deep Archive; **Peter deleting the archived nights** to reclaim ~76G |
| pip | / (233G NVMe) | 89% — /mnt/cog 98G stale pre-2015 copies, 61G archived/deletable |
| puppy | skycam raw | unbounded, no ship-and-free yet (pre-existing warning) |

## Done

- 2026-07-17: **first real squash pass** using new `squash-starcam-night`.
  Squashed 05-21 (bigdisk `starcam-backup`, 40G→11G) and 05-24 (bigdisk
  `starcam-frames/night`, 39G→9.7G) to sum8+sum2, sources deleted. bigdisk
  95%→89% (42G→100G free). CSV + DynamoDB updated (muppet loc rows shrunk=true).
  Keepers 05-23, 05-28 left untouched. Note: **each night still has a raw
  duplicate elsewhere** — 05-21 raw on muppet NVMe export `~/starcam-backup`
  (root fs 94%), 05-24 raw still on puppy `~/starcam-frames/night`; those copies
  are NOT squashed and their inventory rows correctly still say raw. Squashing
  those second copies is the logged next-fruit (the NVMe export especially,
  root disk is tight).
- 2026-07-10: muppet /mnt/bigdisk* maintenance unblocked (holder was knfsd +
  NFS clients, not stale processes). Capture restored same day.
- 2026-07-11/12: photo collection (17,889 files, 65.4 GB, 38 archives) →
  Deep Archive via glacier-app — this is glacier-app's *correct* use (images).
- 2026-07-12: eclipticam 85G backlog rsynced to muppet bigdisk2, then 17 nights
  shipped to Deep Archive (via glacier-app — the wrong tool, see above).
- 2026-07-13: `/astro/storage` reconciled to reflect the true state.

## Key facts

- eclipticam→LAN is powerline-capped ~100Mbit; fine for nightly ship
  (~10 min), painful for backlogs.
- Retention doctrine: ship-and-free per stream; pressure-based garbage
  collector retired 2026-07-01.
- `cold-archive-night` reads `/mnt/astrobackup/<cam>/<mode>/<night>/` (needs
  MANIFEST.sha256), streams tar to Deep Archive, upserts inventory. Its
  documented "future work" is exactly the squash (raw→sum8/sum2) step.

## Next

- **Build the squashing pipeline** (raw → sum8/sum2) — the missing front half
  of `cold-archive-night`'s intended flow, and the real lever on the t² cost.
  See IDEAS.md for the retention-schedule design day.
- **starcam pass** (lowest fruit): 228G on bigdisk (frames 122G +
  starcam-backup 106G) + muppet:~/starcam-backup NFS export; likely dedupe +
  squash + cold-archive, not new pipeline.
- **astrocam pass**: biggest single stream (336G, live NFS capture).
- The astro streams on bigdisk (~735G) are the real disk pressure.
