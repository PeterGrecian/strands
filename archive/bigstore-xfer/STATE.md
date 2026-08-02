# bigstore-xfer — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Mission

Copy all astro data onto `/mnt/bigstore/astro-data` on **muppet** (a 5.5T
`Expansion HDD`, `/dev/sda1`, near-empty), as a consolidation point, and report
what becomes deletable elsewhere. Started 2026-07-27 with `/mnt/photodisk`.

## Layout convention (decided 2026-07-27)

Match the **house default** already used on `/mnt/bigdisk` and S3:

```
<camera>-frames / <night|day> / <YYYY-MM-DD> / <HH> / frames
```

Rejected: `yyyy/mm/dd/camera/hh` (would be a 3rd convention) and
`night/<date>/<camera>` (minority form, one dir on bigdisk).

## /mnt/photodisk survey (234G used, 335G ST3360320AS spinner)

**Not on the /astro/storage page because it's infrastructure, not tracked astro
storage** — it's an active NFS export (whole disk, in `/etc/exports`) and hosts
the LIVE OpenSearch cluster index + snapshot repo.

| photodisk path | size | nature | copied to bigstore as |
|---|---|---|---|
| `backups/starcam-backup/` (2026-05-20…30, 6 nights) | 106G | astro | `starcam-frames/night/<date>/` |
| `backups/eclipticam-frames/night/` (06-09…24, 12 nights) | 36G | astro | `eclipticam-frames/night/<date>/` |
| `backups/images/` (2003-2013 photos, camcorder) | 61G | personal — **also on pip** | `_non-astro/backups/images/` |
| `backups/audio/` (composers, pop, tapes) | 32G | music — **also on pip** | `_non-astro/backups/audio/` |
| `backups/` misc (pastdev, Dropbox, dev, Documents) | ~630M | old dev backups | `_non-astro/` |
| `opensearch-data/` | 96M | **LIVE OpenSearch index** (muppet node) | mirrored, but reroute is the real fix |
| `osd-snapshots/` | 391M | **LIVE snapshot repo**, NFS-shared to puppy | mirrored, but reroute is the real fix |

### bigstore destination
- `/mnt/bigstore/astro-data/` — mirror target (owned peter).
- Pre-existing unrelated `old_backups` (4.4G) + `old_backups2` (1G): **untouched.**

## OpenSearch cluster topology (verified 2026-07-27)

3 nodes, all docker (`opensearchproject/opensearch:3.7.0`), config in **`osd`
git repo** (`~/osd/cluster/`):

| Node | IP | role | index store (now) | snapshot repo (now) |
|---|---|---|---|---|
| **muppet** | .10 | cluster_mgr+data | `/mnt/photodisk/opensearch-data` bind | `/mnt/photodisk/osd-snapshots` — **NFS server** |
| **puppy** | .11 | cluster_mgr+data | docker vol `osd_opensearch-data` (on its NVMe `/`, 75M) | `/mnt/osd-snapshots` = **NFS mount of muppet:/mnt/photodisk/osd-snapshots** |
| **vole** | .9 | cluster_mgr only (vote tiebreaker) | local vol (no data) | — |

- `path.repo: ["/mnt/osd-snapshots"]` in `~/osd/cluster/opensearch.base.yml`.
- Both muppet `/` and puppy `/` are NVMe SSDs with headroom (109G / 59G free).
- NFS export is **ansible-managed** (`~/ansible` `roles/nfs-server`;
  `/etc/exports` says "do not edit manually"); currently exports whole
  `/mnt/photodisk`.

## Pending / loose ends

### 1. Mirror photodisk → bigstore (DONE & VERIFIED 2026-07-27)
Driver `/mnt/bigstore/astro-data/run-mirror.sh`, log `mirror.log`. File-count
verification: starcam 44,387=44,387 ✓, eclipticam 22,308=22,308 ✓ (both exact,
rsync exit 0). `_non-astro` 94G copied — needed a `sudo` top-up for 13 root-owned
photos in images/2012-13 that the peter-run rsync couldn't read (all already on
pip anyway). bigstore now 234G→ still 5% used, 5.2T free.

### 1b. Merge bigdisk + bigdisk2 → bigstore (IN PROGRESS 2026-07-27)
Second disk. bigdisk is 96%/93% full (~43G free) — the space-pressured one; kept
as tepid spare, but its data comes onto bigstore as the live copy. Driver
`/mnt/bigstore/astro-data/run-bigdisk-merge.sh`, log `bigdisk-merge.log`,
detached (sudo setsid). Merge map (decided with Peter):
- `astrocam-frames/` (513G, **NEW camera**, 45 dated dirs 06-08…07-26) →
  `astrocam-frames/` — dated dirs only, **drop the `2026/` rollup** (it's only
  4.9M of summaries, not duplicate frames).
- **ECLIPTICAM (corrected 2026-07-27 after Peter flagged the two 06-21 dirs look
  identical):** the two bigdisk eclipticam trees are NOT raw-vs-products — they
  are the SAME processed-night dataset in two completeness states (verified: not
  symlink/hardlink, different inodes; per-night file counts show `eclipticam-
  frames/night/` is a consistent SUPERSET, e.g. 06-21 1561 vs 1551, and holds all
  62 `-web.mp4` variants; `night/` has none). bigstore's existing photodisk copy
  is ALSO the thin unprefixed form (1551, no -web). So all three reconcile into
  ONE tree `eclipticam-frames/night/`, copied **thin → rich** so newest wins:
  (a) `bigdisk/night/` folded in, (b) `bigdisk/eclipticam-frames/night/` (rich)
  overlaid, (c) `bigdisk2/eclipticam-frames/night/` (06-25…07-11) added.
  **No separate eclipticam-products/ tree** (that was based on a wrong raw-vs-
  processed read; corrected before the merge reached eclipticam — driver v2).
- `starcam-frames/night/` (05-24…06-04, new dates) + `starcam-backup/`
  (05-20…30, verified byte-identical to bigstore's photodisk copy — checksum
  dry-run showed 0 diffs) → `starcam-frames/night/` (merge, skip identical).
- `audio` + `photodisk-2013` + `glacier-work` → `_non-astro/from-bigdisk/`.
Overlap policy: **verify-then-skip** via `rsync --checksum` (proven: bigdisk
05-20 == bigstore 05-20, 4399 files, byte-identical).

**DONE & VERIFIED 2026-07-27 22:34Z** — all 6 phases rc=0 (astrocam 15:47→20:35,
eclipticam thin→rich→bigdisk2, starcam×2, audio). Verification:
- astrocam 189,131 files / 45 dated dirs, byte total 513G — matches source except
  today's live `2026-07-27` dir (topped up separately; residual diff = camera
  still capturing, expected).
- missing nights **06-12 (2504 files) and 06-15 (1496) now present** (rich copies).
- bigdisk2 06-25…07-11 landed (spot-checked OK).
- **eclipticam night range on bigstore now 06-09…07-26, 48 nights contiguous**
  (photodisk + bigdisk + bigdisk2 + eclipticam-SSD all merged into one tree).
- bigstore now **1.1T used, 4.4T free (20%)**.

### 1c. Update the /astro/storage page + index for bigstore + photodisk (FOLLOW-UP)
The page will **NOT** self-update. Mechanism (found 2026-07-27):
- Page = `~/mywebsite/lambda/routes/astro.py::render_astro_storage`, fed from two
  DynamoDB tables via `mywebsite.py::get_astro_storage_data`:
  **`astro-host-capacity`** (disk bars) + **`astro-storage-inventory`** (per-night
  rows: night,camera,host,path,storage_class,online).
- Source of truth for inventory = **`~/astro/whereisallthedata.csv`** (schema
  `night,camera,host,path,…,storage_class,notes`, ONE ROW PER (night×location)).
  This CSV **is exactly the index summary Peter wants** ("2026-06-21 v3w →
  bigstore, bigdisk2, s3") — it just lacks the new bigstore/photodisk rows.
- Tools already exist in **`~/astro/bin/`**: `storage-report` (df→capacity table),
  `inventory-from-csv` (CSV→inventory table), `astro-where` (query CLI).

To surface bigstore + photodisk:
1. Add muppet mounts `/mnt/bigstore` and `/mnt/photodisk` to `storage-report`'s
   mount list; run it → capacity bars appear (currently tracks only puppy /,
   eclipticam /mnt/ssd, muppet /mnt/bigdisk, /mnt/bigdisk2, ASTROBACKUP USB).
2. Append bigstore (and photodisk-as-shelf) rows for every migrated night to
   `whereisallthedata.csv`; run `inventory-from-csv` → per-night page updates.
This is **`~/astro` repo work**, and should run **after** the copies finish so we
inventory the settled state, not a moving target. NOT this session.

### 1d. eclipticam SSD pull (DONE & VERIFIED 2026-07-27)
eclipticam host = single Kingston SSD `/mnt/ssd` (109G, was 84% full), **one copy
only, no RAID**. Held 07-12…07-26 (15 nights, 86G) — the newest eclipticam data,
existing NOWHERE else (contiguous tail after bigstore's …06-24 and bigdisk2's
06-25…07-11). Pulled muppet←eclipticam over ssh into `eclipticam-frames/night/`.
**All 15 nights verified, file counts exact** (1070…1409/night). SSD now safe to
free (~86G reclaim) — but hold until Peter says so (was single-copy); ideally
after it's in the inventory + S3. NOTE: run the pull as **peter not sudo** (root
on muppet has no key to eclipticam; peter does) — cost an hour of debugging.

### 1e. puppy survey + skycam pull (2026-07-28)
"puppy /383" is a stale page name — puppy's data lives on its **NVMe `/`**
(468G, 89% full) under `/home/peter/`. It's the live capture host. Overlap vs
bigstore:
- `astrocam-frames` (06-08…06-27) — SUBSET of bigstore's 06-08…07-27 (bigstore
  fuller, e.g. 06-20 4209 vs puppy 4203). Redundant, skip.
- `starcam-frames/night` (05-24…06-04) — subset of bigstore's. Redundant, skip.
- **`skycam-frames` (53G, 07-09…07-28, ~20 nights) — NEW camera, not on bigstore
  at all.** skycam has no ship-and-free pipeline (per GLOBAL.md, raw unbounded on
  puppy) → this pull IS the missing ship step. Copying to `skycam-frames/<date>/`
  (bare date dirs, matching astrocam; skycam has no night/day split). Exclude the
  1M `2026/` rollup. IN PROGRESS.

### NETWORKING NOTE (answers Peter 2026-07-28): NO data over the internet.
All bulk copies driven **on muppet over LAN IPs** (192.168.0.10/.11/.66). muppet
is NOT on Tailscale (can't route it — first skycam attempt to puppy's 100.x
Tailscale IP failed "Network unreachable", switched to LAN .11). Tailscale 100.x
was used only for **survey reads from pip** (df/ls/du); even those go LAN-direct
P2P (WireGuard), not via internet/DERP for same-LAN peers. Zero egress cost.

### 1f. eclipticam SSD free — DEFERRED, PETER'S JOB (2026-07-28)
**Do NOT delete anything on the SSD — Peter does deletion himself.** Findings for
when he does: SSD is a LIVE capture disk (`eclipticam-v3w-uploader.service` drains
/dev/shm→night tree; each night finalised ~05:00 the FOLLOWING morning). 90% full,
11G free. Nights 07-12…07-26 are static + verified on bigstore (safe candidates).
**07-27 was NEW (added after the 07-12…07-26 pull) — copying it to bigstore now**
(the only action Peter approved). 07-28 not on disk yet (still in /dev/shm).

### 1g. /astro/storage page rebuilt as FS-matrix (DONE 2026-07-29)
Replaced the uninformative night/camera list with a dense **filesystem matrix**
(`~/mywebsite/lambda/routes/astro.py::render_astro_storage`; deployed via
`./deploy`). rows = day×camera, cols = filesystems. Design decisions:
- night col = **day-of-month only** (month fixed by the /astro/storage/YYYY-MM
  selector); full date on hover.
- camera abbrevs (hardware-versioned): sv1 starcam, av2 astrocam, ev3w/ev1
  eclipticam; av3s + eos (canon) pre-mapped for arrival.
- ALL location columns always shown, order **mup ecl bs · bd bd2 pd pup ab s3**;
  dim header = unused this month. Vertical zebra striping.
- `#` col = how many filesystems hold the night; **orange row = single copy**.
- per-camera format **footnotes** (e.g. "ev3w = mosaic · 4608×2592 · 60 s ·
  ~5 GB/night"), auto-derived.
- sweeps/derivatives hidden by default; `?all=1` + toggle reveals them.
- **bigstore entries populated**: scanned `/mnt/bigstore/astro-data` on muppet
  → 128 items (astrocam 46, starcam 13, eclipticam-v3w 49, skycam 20) upserted
  to `astro-storage-inventory`. Scanner: `muppet:~/scan-bigstore-inventory.py`
  (one-shot; the real fix is teaching the canonical reporter to scan bigstore).
- **CV protection**: `mywebsite/lambda/cv.html` has Peter's unrelated in-progress
  CV rewrite (uncommitted) — git-stashed around every deploy so it never ships.
  Restore stash after any deploy.
- Still TODO for full accuracy: the OTHER filesystems' rows (bd/bd2/pd/pup/ecl)
  are stale/pre-migration, so most nights still read #=1. A proper multi-FS
  scanner (or refreshed whereisallthedata.csv) fills them → real redundancy view.
- mywebsite commits: 27653b6, e90c685, 7ced289.

### 1h. Storage tooling: /astro/disks page + capacity + inventory (2026-07-29)
- **New page `/astro/disks`** (by-filesystem): per disk, one line per camera
  `av2 0608–0727 (46) 525 GB`. `~/mywebsite/lambda/routes/astro.py::
  render_astro_disks` + route in mywebsite.py. Commit `12b2bff`.
- **Inventory populated for ALL filesystems** via one-shot `scan-fs-inventory.py`
  (copied to muppet/puppy/eclipticam ~). Walks only astro trees
  (`-frames`/`starcam-backup`/`night`), infers camera from the tree NAME (NOT
  `/night`, which is a sublevel of every camera — that bug mislabeled puppy's
  starcam as eclipticam; fixed + re-scanned). Skips personal-photo backups on
  photodisk that also have YYYY-MM-DD dirs.
- **Data checks (Peter asked):** puppy has NO eclipticam (only av2/skycam/sv1) —
  the ev3w rows were the `/night` bug. muppet `~/*-frames` are mostly 0-byte
  stubs → stale `mup` rows deleted (130 puppy+home rows purged, puppy re-scanned
  clean).
- **Capacity fixed in the canonical tool** `~/astro/bin/storage-report`
  (commit `338819d`): `EXTRA_MOUNT_GLOBS` now includes `/`, `/mnt/bigstore`,
  `/mnt/photodisk` (+ existing bigdisk/bigdisk2/ssd) → capacity bars now show
  muppet `/`, puppy `/`, bigstore, photodisk. Also added bigstore/bigdisk/
  bigdisk2/photodisk to the astrocam/eclipticam/starcam scan streams.
- **GAP RESOLVED (was "bigdisk astrocam emits 0"):** it was SYMLINKS. Muppet's
  `~/astrocam-frames` → `/mnt/bigdisk/astrocam-frames` (same dev/ino).
  `dedup_aliases` correctly collapsed the two names but its tiebreak KEPT THE ~/
  NAME → the row filed under the `mup` column, not `bd`. `scan_capacity` already
  preferred `/mnt/` names; dedup did the opposite. Fix (astro `31f7421`): flip
  dedup to prefer `/mnt/<disk>/...`. Now storage-report is correct AND
  multi-copy-aware; **ran it for real on muppet** (267 inv + 5 cap, pruned 123
  stale home rows) → **self-maintaining via cron; the one-shot
  scan-fs-inventory.py is no longer needed for muppet's disks.** /astro/disks now
  shows bd's real contents (av2 44, ev3w 32, ...); `mup` gone.
- mywebsite commits this session: 27653b6, e90c685, 7ced289, 7b22f8b, d0fbc68,
  12b2bff. astro: 338819d, 31f7421.

### 1j. photodisk VAULTED (powered down + shelved) (2026-07-29) ✅
**Status: IN THE VAULT** — physically stored as a cold backup. Notified
**astro-storage** via strand-mailbox (its STATE still treated /mnt/photodisk as a
live staging/ship target — that target is now gone; use bigstore).

aifabric-sessions confirmed OSD data can be vaulted/trashed (S3 export = backup
of record) and did the teardown: container detached from photodisk, path.repo
removed, **puppy NFS-unmounted** (the hang risk cleared). Verified live, then
clean power-down from this strand:
1. `exportfs -u 192.168.0.0/24:/mnt/photodisk` (released knfsd)
2. `sync` + `umount /mnt/photodisk` (clean, writes flushed)
3. `hdparm -Y /dev/sdb` + `echo 1 > /sys/block/sdb/device/delete` → /dev/sdb
   gone, USB drive spun down + detached. Data intact — frozen shelf backup,
   all also on bigstore.

**DURABLE FOLLOW-UPS — DONE 2026-07-29:**
- ✅ muppet `/etc/fstab` photodisk line commented out (backup `/etc/fstab.bak-*`).
- ✅ ansible export removed: `inventory/host_vars/muppet.yml` `/mnt/photodisk`
  export commented (ansible `91bad48`, pushed). So neither reboot nor `ansible`
  re-mounts/re-exports it.
- **To bring it back:** power on USB → `echo '- - -' | sudo tee
  /sys/class/scsi_host/hostN/scan` (rescan) → uncomment fstab line + `mount -a`
  → uncomment the ansible export if NFS access wanted again.

### 1i. photodisk power-down BLOCKED on OSD snapshot repo (2026-07-29 — RESOLVED, see 1j)
Hot day → Peter wants photodisk powered down. **NOT SAFE YET.** Checked muppet
live state: OSD **index** IS off photodisk (Move 1 done — named volume on root
NVMe, verified), BUT the **snapshot repo is still on photodisk**:
`/mnt/photodisk/osd-snapshots` (476M) still bind-mounted by the opensearch
container AND HARD-NFS-mounted by puppy (`path.repo=/mnt/osd-snapshots`). Powering
down now would hang puppy + break the cluster snapshot repo (index data safe
though). Confirmed against aifabric-sessions STATE: their "item #3" (photodisk
evacuation) is half-done; S3 export is already their backup-of-record so native
snapshots can retire. **Sent aifabric-sessions a strand-mailbox** (2026-07-29)
asking them to run item #3 step 2 (retire snapshot machinery via their
coordinated-restart runbook). Peter's steer: keep a copy of the repo on the shelf
+ S3 otherwise. **Power-down waits on their reply** — do NOT touch the OSD cluster
from this strand.

### OWNERSHIP (2026-07-28)
- OSD reroute (#2 below) — **being done elsewhere**, not this strand.
- S3 off-site copy — **deferred**.
- Active worklist here: survey puppy /383 · update storage index
  (whereisallthedata.csv) · free eclipticam SSD (verified-safe).

### 2. OpenSearch reroute off photodisk (being done ELSEWHERE — not this strand)
Two independent moves, both decided 2026-07-27:
- **Index store → NVMe:** both muppet and puppy use `/var/lib/opensearch/data`.
- **Snapshot repo → S3** (drop NFS entirely): register an `repository-s3`
  snapshot repo. Removes the NFS-server role + `/mnt/osd-snapshots` mount + the
  muppet-as-NFS-server dependency. Cost ~1–2¢/mo (391M in S3 Standard, 11-nines
  durability; NOT Deep Archive — snapshots must restore on demand).

Target state:
| Node | index store | snapshot repo |
|---|---|---|
| muppet | `/var/lib/opensearch/data` (NVMe) | S3 (`repository-s3`) |
| puppy | `/var/lib/opensearch/data` (NVMe bind, replaces docker vol) | S3 (same bucket) |
| vole | unchanged (no data) | — |

**S3 details:** account `700630586062`, region `eu-west-1`. New dedicated
bucket following the `<thing>-berrylands-eu-west-1` convention →
**`osd-snapshots-berrylands-eu-west-1`**. Repo base_path e.g. `cluster/`.
`repository-s3` is **bundled but NOT installed** in the stock 3.7.0 image →
needs a custom image (`FROM opensearchproject/opensearch:3.7.0` + `RUN
opensearch-plugin install --batch repository-s3`) built on muppet+puppy, or a
shared registry. AWS creds go in the **OpenSearch keystore**
(`s3.client.default.access_key` / `secret_key`), never in compose. Get creds via
`secrets` (make an IAM user/policy scoped to just this bucket).

Touches (now just `osd`, no ansible/NFS):
1. `~/osd/cluster/docker-compose.muppet.yml` — index bind mount →
   `/var/lib/opensearch/data`; use custom s3-enabled image. (staged draft:
   scratchpad `docker-compose.muppet.yml.proposed` — still shows the local-fs
   snapshot mount; UPDATE to drop it + switch image before use.)
2. `~/osd/cluster/docker-compose.puppy.yml` — index bind mount + drop the
   `osd_opensearch-data` docker volume (migrate its 75M first); custom image;
   drop `/mnt/osd-snapshots` mount. (staged draft:
   `docker-compose.puppy.yml.proposed` — index part done; still needs image
   swap + snapshot-mount removal.)
3. `~/osd/cluster/opensearch.base.yml` — `path.repo` no longer needed (S3 repo
   is registered via API, not a filesystem path). Remove/adjust.
4. `~/ansible` `roles/nfs-server` — the `/mnt/photodisk` export for snapshots
   becomes obsolete; remove once photodisk retires (also its whole-disk export).

Runbook (cluster stays quorate: vole + one data node keep it up):
1. Create bucket `osd-snapshots-berrylands-eu-west-1` (eu-west-1); IAM
   user+policy scoped to it; store creds via `secrets`.
2. Build custom s3-enabled image on muppet + puppy.
3. Register S3 repo via API; **take a snapshot into S3 and verify it lists** —
   this is the backup before touching anything.
4. muppet: `mkdir -p /var/lib/opensearch/data`, `chown 1000:1000`; `docker
   compose down`; rsync photodisk `opensearch-data/` → `/var/lib/opensearch/data/`;
   apply compose (new image, new bind, keystore creds); `up -d`; wait green.
5. puppy: migrate docker vol → `/var/lib/opensearch/data`; apply compose; `up -d`;
   wait green.
6. Verify: cluster green, S3 repo readable from both nodes, test snapshot +
   restore-dry-run OK. THEN photodisk osd dirs deletable; NFS export removable.
7. Commit `osd`; later `ansible` (NFS removal) when photodisk retires.

**Timing: plan only this session (Peter's call 2026-07-27). Do not execute.**

## Storage architecture end-state (decided 2026-07-27)

| Disk | Device | Role |
|---|---|---|
| **bigstore** | sda, 5.5T Expansion HDD | **Principal astro store.** To be rehoused into a "12-yr-old enclosure" (out of the current external USB caddy). |
| **bigdisk** | sdc, 931G ST31000528AS (bigdisk 838G + bigdisk2 93G) | **Tepid spare.** Currently 96% / 93% full (~42G free total). **NOT worth reformatting to 1 partition** — nearly full + old. Keep as-is; ideally add **GPIO-controlled power** so it stays spun down until needed. |
| **photodisk** | sdb, 335G ST3360320AS | **Cold shelf backup**, full, frozen at retirement (see below). |

Both old spinners (bigdisk, photodisk) become standby/cold legs; bigstore is the
live home. **No reformat, no bigstore→bigdisk round-trip** (idea raised & dropped
2026-07-27: not worth it for a near-full old disk).

### Redundancy stance (decided 2026-07-27)
- **bigstore holds the single LIVE copy** of astro data (one copy is enough on
  bigstore itself — no on-disk duplication, which wouldn't survive disk death
  anyway).
- **Second copy = the shelved/spare old disks** (photodisk cold + bigdisk tepid),
  **incomplete by design** — just whatever they hold frozen at retirement. Not a
  managed mirror, "better than nothing" on-site leg.
- **S3 off-site copy = DEFERRED** ("will do some S3 when I've caught up"). This is
  the real durable second leg when it lands: Deep Archive ~$0.14/mo for the 142G
  astro (11-nines, off-site), reusing `astro-berrylands-eu-west-1`. Follow-up,
  not this session.

## Photodisk end-state: SHELF IT FULL, don't wipe (decided 2026-07-27)

Peter's call: when photodisk comes out of the machine it goes **on a shelf full
of data** as a last-ditch cold copy ("might save our skin at some stage —
probably not"). So there is **no deletion step** and no need to verify
redundancy-before-wipe. The data rides along frozen at retirement.

Caveats:
- It's a 15-yr-old spinner (ST3360320AS) — treat as the weakest of three legs.
  Real durability = bigstore (live) + S3 (astro cold + OSD snapshots). Photodisk
  is the "nice to have" third leg only.
- **Freeze it clean:** the runbook must end with OSD stopped/rerouted (no
  half-written Lucene segments), NFS export removed, then `umount` — never yank
  a live/mounted disk.

Retirement gate (what makes photodisk *removable*, not *wiped*):
(a) bigstore mirror complete & verified, AND
(b) OSD index rerouted off it (muppet+puppy → /var/lib/opensearch), AND
(c) OSD snapshot repo moved to S3 + NFS export removed, AND
(d) clean unmount.

(No longer tracking "what becomes deletable" — nothing gets deleted. The
photodisk-vs-bigdisk astro overlap check is now moot for deletion; only of
interest if we ever want to reclaim bigdisk space instead.)

## Decisions (2026-07-27)

- Layout: house-default camera-first.
- Scope: mirror **everything** on photodisk (astro + non-astro).
- OSD index store: `/var/lib/opensearch/data` on NVMe for **both** muppet & puppy.
- OSD reroute: planned, not executed, this session.
