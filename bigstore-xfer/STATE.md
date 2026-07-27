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

### 2. OpenSearch reroute off photodisk (PLANNED — do NOT improvise)
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
