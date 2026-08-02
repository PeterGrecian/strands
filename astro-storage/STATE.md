# astro-storage — state

*Updated 2026-08-02*

## frames_root is config-truth; navigation is inventory-driven (2026-08-02)

Chased down an idea ("home-dir `ln -s` to automounts cause delay; unreferenced —
config not OS level") and it surfaced a stale-location bug + shipped two tools.

- **`frames_root` = single source of truth in `camera.json`.** `astro/config.py`
  `CameraConfig.frames_root` already existed as the intended seam; the values
  just pointed at `~/…` home-dir symlinks (extra resolve + autofs delay, hid the
  physical path). Repointed astrocam + eclipticam `frames_root` at the real
  bigstore location, and converted the two uploaders
  (`astrocam_v3_uploader.py`, `v3w_uploader.py`) — which bypassed config with
  hardcoded `Path.home()/…` — to read `CameraConfig.frames_root`. pip's
  `~/astrocam-frames` + `~/eclipticam-frames` symlinks removed (harmless there).
- **Discovered the bigstore migration** (see memory
  `astro-frames-bigstore-migration`): all four streams consolidated onto
  muppet's **bigstore** (Seagate USB, `/mnt/bigstore/astro-data`, NFS-exported)
  ~2026-07-30. Old `/mnt/bigdisk` frozen at 2026-07-29; pip NFS-mounts *that*,
  so anything globbing it stops at the 29th. This is the "hardcoded roots go
  stale" failure in the flesh.
- **`cdf <cam> [when]`** (new): cd's the shell into an astro night dir.
  `a`/`e`/`s` (skycam intentionally not in the inventory since 2026-07-05).
  **Inventory-only**: resolves location from `astro-storage-inventory` DynamoDB
  (`super/bin/cdf-path` does the query + host→pip mount translation; the `cdf`
  shell fn in dotfiles does the cd). No hardcoded roots — follows the data as it
  moves disks. A miss errors "run storage-report on the store host" (a gap in
  the inventory is a thing to fix, not to guess around). Fixes the reported
  `cdf a → 29th`; now correctly → 2026-07-31.

**Per-host divergence noted (not yet resolved):** `frames_root` in `camera.json`
is one string but muppet's own path (`/mnt/bigstore/astro-data/…`) differs from
pip's view (`/mnt/muppet/bigstore/…`). Fine for read tooling via the inventory;
watch it if capture/processing runs on multiple hosts.

## POLICY: 3+-copy surplus is clearable (Peter, 2026-07-31) — record, don't act yet

Companion to the bigstore-primary invariant. bigdisk will be **rationalised at
some stage** (taken offline or made nearline). Ahead of that:

**Rule (RELIABILITY-WEIGHTED copies, Peter 2026-07-31):** copies are not equal —
count a **weighted score** per (camera, night), not a flat integer:
- **1.0 (solid):** bigstore, bigdisk/bigdisk2, S3/Glacier tar (incl. the
  non-canonical `glacier-app-archive` bucket), astrobackup, puppy origin.
- **0.5 (flaky / at-risk):** **photodisk** (flaky hardware — and currently
  shelved offline, so "will it spin up again" risk) and **USB thumb drives** (main
  risk = physically losing them).
- **excluded (0):** eclipticam's SSD (`/mnt/ssd`) — live working scratch, not a
  retention copy.

**Clearable surplus** when **weighted score ≥ 3.0**; after clearing, every night
must retain **≥ 2.0** weighted. Purpose: free space for **2nd copies** of nights
that have only ~1 (goal = every night has a safe 2nd copy, not 3+ of some while
others have 1).

**Which copy to clear: least-valuable, case-by-case** (NOT a blind rule). Usually
the bigdisk/bigdisk2 copy (the disk being rationalised), but judge per night —
never clear bigstore (primary); prefer keeping canonical cold path
(`astro-berrylands-eu-west-1`) over `glacier-app-archive`; when equal, drop the
flaky 0.5 copy first.

**DO NOT ACT YET** — record only. Execute when bigdisk is actually rationalised.
Freeing = `trash` (recoverable) for on-disk copies, never rm; verify retained
copies first.

**Snapshot (2026-07-31 inventory), weighted-score bands:**
- < 2.0 (mostly single-copy): **20 nights** ← priority (need a 2nd copy)
- 2.0–2.9: 90 nights (leave)
- ≥ 3.0: **25 nights** ← clearable surplus
- **0 nights currently carry a flaky (0.5) copy** — photodisk is shelved/out of
  the inventory and no thumb-drive astro copies are registered, so the weighting
  doesn't change today's numbers (identical to the unweighted count). It's a
  **forward guard**: the moment photodisk returns as nearline, or a night's only
  redundancy is a thumb drive, those copies count half — so e.g. bigstore(1) +
  photodisk(0.5) + thumb(0.5) = 2.0 is NOT clearable surplus. Re-derive live
  (weighted) before acting.

The 25 clearable are mostly `{S3/Glacier, bigdisk|bigdisk2, bigstore}` trios
(astrocam 06-09/16/26; eclipticam-v3w 06-25..07-11; starcam 05-20..05-30); two
4.0 nights (eclipticam-v3w 07-04, starcam 05-20).

## astrocam v2→v3s page labelling — DONE + verified live (2026-07-31)

astrocam swapped imx219/v2 → imx708/v3s on 2026-07-29 (astro-v3s strand's work).
`/astro/storage` now labels the eras distinctly: nights **≥ 2026-07-29 = av3s**,
earlier = av2. Mechanism: `storage-report` maps camera name by night date
(`_SENSOR_SWAPS` / `_cam_for_night`); the page's `CAM_ABBR` already had
`astrocam-v3s→av3s`.

**Two bugs found + fixed by checking the actual DynamoDB (not trusting the commit):**
1. The fix was applied only in `scan_host` (capture-path) but **not**
   `scan_extra_streams` (the disk-root scan of /mnt/bigdisk + /mnt/bigstore).
   Result: swapped nights got an av3s row AND lingering av2 rows (which also
   blocked pruning). Fixed — split now applied in both paths (astro `8c40e8f`).
2. muppet's astro checkout was 38 commits behind with an uncommitted
   `storage-report` — but that uncommitted diff was **fully redundant** with
   origin (bigstore-xfer multi-root work already committed there); the ONLY unique
   content was my av3s split, which origin also had. Stashed the redundant change
   (recoverable), fast-forwarded muppet to origin.

Verified live: 3 astrocam-v3s rows (07-29 ×2, 07-30), **0 stale av2 rows ≥07-29**;
re-scan pruned 5. Page is clean.

**Note (astro `8c40e8f` unpushed on pip):** the scan_extra_streams fix is
committed on pip + synced to muppet by file copy, not pushed. Push when convenient
so other hosts' scans get it.

## INVARIANT: bigstore is primary — it holds every stream in full (Peter, 2026-07-31)

**Rule:** `bs` (muppet `/mnt/bigstore/astro-data`, 5.5T) is the **primary** store
and must hold **every astro stream in full** — astrocam, eclipticam, starcam,
skycam. **All other disks (bigdisk, bigdisk2, capture-host SSDs) are SECONDARY
copies.** New capture targets bigstore. Reconciliation = **add-only `rsync -a`**
into bs (never `--delete` — preserves bs-only nights like squashed/migrated ones),
followed by a `--checksum` verify. Freeing a secondary is safe only once the night
is verified on bs.
- **photodisk is RETIRED to the vault** (bigstore-xfer, 2026-07-29): powered down,
  shelved as cold backup, fully duplicated on bs; muppet fstab + ansible export
  removed (durable). `/mnt/photodisk` is **no longer a staging/ship target** —
  bigstore is the consolidated live store. (Any old STATE note using photodisk for
  staging — e.g. squash-starcam-night — needs a bigstore-based target instead.)

**Reconciliation done this session (2026-07-31):**
- **astrocam — COMPLETE on bs.** 06-09..07-27 already present; **copied+verified
  07-28 (13G, 4704 files) and 07-29 (4.4G, 1040 files, the v3s first night)**
  bigdisk→bigstore (local disk-to-disk on muppet, 0 data-diffs each). 07-18/19 are
  correctly bs-only (bigdisk freed). 06-08 is an empty stub.
- **eclipticam — already COMPLETE on bs** (50 nights/237G). bigdisk (16n) +
  bigdisk2 (17n) hold only redundant subsets — every secondary night is already on
  bs (the tangled 3-tree overlap from STATE was pure duplication). bigdisk2's
  year-nested `2026/06/DD/` tree is 51 stub files (metadata, not raw) — noise.
- **starcam — already COMPLETE on bs** (13 nights/198G). bigdisk starcam-backup's
  5 nights (05-20,22,23,26,30) all present on bs with matching counts. photodisk +
  muppet ~/starcam-backup empty; puppy origin nights all within the bs range.
- **skycam — NOT complete; needs auto-cleanup pipeline** (see below).

**skycam gap → asked ubersitrep (2026-07-31):** skycam raw on puppy is **unbounded**
(pressure GC retired 2026-07-01, no ship-and-free replacement). Peter wants
auto-cleanup. Mailboxed ubersitrep to decide ownership (astro-storage is the
natural fit — it owns per-stream ship-and-free). The pipeline: ship puppy raw →
bigstore, then free puppy. 53G already on bs. **Awaiting ubersitrep's read.**

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

**BUILT + TESTED LIVE this session (works end-to-end):**
- **`super/bin/eclipticam-ship-night`** — the eclipticam back half. **rsync over
  SSH** (not the NFS mount) SSD → `peter@muppet:/mnt/bigstore/astro-data/…`,
  `--checksum` verify (zero DATA diffs), then **`rm`** (not `trash`) nights
  outside the 3-night safety window. Fail-safe (muppet down / rsync rc≠0 / verify
  diff ⇒ non-destructive bail + retry). `--go`/`--keep`/`--host`/`--addr`/
  `--help`/`--hints`.
- **Two bugs found & fixed by live testing (both would have bitten in prod):**
  1. `rsync -a` over the NFS mount hit `chgrp: Operation not permitted`
     (`all_squash` export) → **code 23** → tool read it as "copy failed, never
     free." **Fix: rsync-over-ssh** — files land owned by peter on muppet
     natively; `-a` works; +`-z` compression, `--partial` resume. (Peter's call,
     revised from an initial "keep the mount".)
  2. Freeing via `super/bin/trash` filled eclipticam's **15G root fs to 100%** and
     reclaimed **no SSD space** — `~/.trash` is a different filesystem from
     `/mnt/ssd`, so `trash` cross-fs-COPIES. **Fix: `rm` the SSD dir**, reached
     only after byte-verify on bs (the verified bs copy is the retained copy;
     that's how "never rm the last copy" is honoured here).
- **LIVE RESULT (2026-07-29):** shipped 9 nights (07-20..07-28) to bs, all
  checksum-verified; freed the 6 oldest, kept newest 3. **SSD 53%→19% (~36G
  reclaimed)**; root fs untouched. The chronically-91%-full SSD problem is solved
  by this tool. The 28th (the specific test night) independently checksum-verified
  clean SSD-vs-bs (0 differing files).
- **Decoupling:** because the ship path is now ssh, **eclipticam no longer needs
  the bs NFS mount at all** — only astrocam's direct-write half needs the ansible
  mount now.
- **`eclipticam-ship-night.{service,timer}`** (staged in strand dir, not yet
  installed) — daily ~09:00 Europe/London oneshot. Hand-install or fold into
  ansible to make the nightly cadence automatic.

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
