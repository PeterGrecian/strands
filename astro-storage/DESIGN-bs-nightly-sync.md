# Design: end-of-night sync to bigstore 'bs' — two-camera topology

*Drafted 2026-07-29 (astro-storage strand). Refines the inbox idea
`end-of-night-sync-to-bs` into a concrete, asymmetric two-camera design.*

## Ground truth (verified 2026-07-29, not assumed)

- **bs** = `/mnt/bigstore/astro-data` on **muppet** (192.168.0.10), 5.5T, **1.2T
  used / 21%**. Exported NFS **sync**, mounted **soft** at `/mnt/muppet/bigstore`
  on eclipticam + puppy + pip (ansible strand; rollout has reached eclipticam —
  the mount is live there today).
- The house tree already exists on bs, populated by the **bigstore-xfer** backlog
  migration: `astrocam-frames/` (525G), `eclipticam-frames/night/` (231G),
  `starcam-frames/` (198G), `skycam-frames/` (53G). Layout is
  `…/<cam>-frames/night/<YYYY-MM-DD>/…` (eclipticam) and `…/astrocam-frames/<YYYY-MM-DD>/…`.
- Those `run-*.sh` scripts on bs are **one-shot backlog pulls** (they truncate
  their log each run, hard-code date ranges, no cron/timer). They are NOT the
  recurring nightly sync. **The recurring sync is this strand's seam** — that's
  what we build.

### astrocam (192.168.0.67) — already an NFS-direct writer, to the WRONG disk

- Rootfs is a **6.8G SD card, 90% full, 694M free** — effectively **no local
  staging**.
- `astrocam-capture.service` runs `astro/astrocam/capture.py`, which writes
  summed FITS **directly over NFS** to `FRAMES = ~/astrocam-frames`, i.e.
  `192.168.0.10:/mnt/bigdisk/astrocam-frames` — the **old 839G bigdisk, 97%
  full** (the actual disk-pressure problem). Mount is already `soft`
  (`timeo=30,retrans=3`).
- `~13G/night`. Capture already wraps writes in `try/except OSError` (capture.py
  ~L387) and logs `events.log` next to frames.
- `/var/lib/astrocam-buffer` tmpfs (50M) exists in fstab but is **empty/unused**;
  the "double-buffer" in capture.py is in-RAM frame co-adding, not a disk spool.

### eclipticam (192.168.0.66) — stages on local SSD, bs mount already live

- Captures to **`/mnt/ssd/eclipticam-frames`** (109G SSD, **91% full, 9.8G
  free**). `eclipticam-v3w-uploader.service` drains `/dev/shm` → the SSD night
  tree (`V3W_FRAMES_ROOT=/mnt/ssd/eclipticam-frames`). `~6G/night`.
- bs mount **is live**: `muppet.local:/mnt/bigstore/astro-data` → `/mnt/muppet/bigstore`
  (soft, autofs, `x-systemd.idle-timeout=60`).
- Link to muppet is the **powerline bridge, ~100Mbit real** → 6G ≈ **~8–10 min**
  end-of-night. Fine nightly, painful for backlog.

## The asymmetry (Peter's decisions, 2026-07-29)

| | astrocam | eclipticam |
|---|---|---|
| Local staging | none (6.8G SD) | 109G SSD |
| Link to muppet | LAN (fast) | powerline ~100Mbit |
| Write model | **direct to bs** (repoint capture mount) | **stage-then-copy** (SSD → bs) |
| bs role | live capture target | end-of-night rsync target |
| Local free | n/a (nothing local) | **ship-and-free after verify** |

## Part 1 — astrocam: repoint capture mount bigdisk → bs

**Decision: repoint** (not add a same-host copy — both disks are on muppet;
bigdisk at 97% is the problem, so moving capture *onto* the 5.5T disk both
gives astrocam room and stops feeding the full disk).

Change: capture.py's `FRAMES = ~/astrocam-frames` stays the same *path*; we
repoint what that path is a mount of.

`/etc/fstab` on astrocam, replace:
```
192.168.0.10:/mnt/bigdisk/astrocam-frames  /home/peter/astrocam-frames  nfs soft,intr,timeo=30,retrans=3,_netdev 0 0
```
with:
```
muppet.local:/mnt/bigstore/astro-data/astrocam-frames  /home/peter/astrocam-frames  nfs soft,intr,timeo=30,retrans=3,_netdev 0 0
```
(target subdir already exists on bs and holds the migrated backlog, so nights
continue in the same `<YYYY-MM-DD>/` tree — no discontinuity.)

**This fstab change belongs in the ANSIBLE strand** (host_vars `astrocam.yml` —
it currently has no client mount; the export doctrine there covers muppet).
Coordinate: astrocam must be added as a bs *mounter*. Flagged to the sibling
ansible forkterm.

Rollout: unmount old, mount new, restart `astrocam-capture.service`, confirm a
frame lands under `/mnt/bigstore/astro-data/astrocam-frames/<tonight>/`.

### Mount-drop safety (Peter: "local tmpfs spool + drain")

A soft mount returns **EIO** if muppet drops mid-night. Chosen behaviour is a
local spool + drainer so a drop doesn't lose the night — but astrocam has only
**694M free on the SD**, so the buffer is necessarily shallow (a long outage
still overflows; muppet maintenance is scheduled/rare, so acceptable).

Concrete shape (small, additive — capture.py already catches OSError):
- Grow the existing `/var/lib/astrocam-buffer` tmpfs from 50M to a modest size
  (e.g. **256M**, still comfortably within 8G RAM) as the spill area.
- On write, capture.py already `try/except OSError`. Extend the except: on EIO,
  write the summed FITS to `/var/lib/astrocam-buffer/<night>/…` instead and log.
- A lightweight **`astrocam-buffer-drain`** oneshot+timer (every ~2 min): if the
  bs mount is writable, `mv` any spooled frames into `FRAMES/<night>/` and clear.
  If the buffer fills before drain, capture logs a gap and drops (matches the
  "gap, recover next mount" tolerance) — the spool converts a *brief* drop into
  zero loss, and only a *long* drop into a bounded gap.

Deferred detail: exact tmpfs size + drain interval to tune once bs capture is
live and we can watch real EIO frequency. Starts simple; a plain write-through
(no spool) is the fallback if the spool proves unnecessary.

## Part 2 — eclipticam: end-of-night rsync SSD → bs, then ship-and-free

**New tool: `super/bin/eclipticam-ship-night`** (to build) — runs ON eclipticam
(driven from a systemd timer there), per house direct-routing rule (bytes go
SSD → bs over the mount, not relayed through pip).

Mechanism & cadence:
- **Cadence**: systemd timer once/day, well after night ends — e.g.
  **`OnCalendar` ~09:00 Europe/London** (capture is night-only; by 09:00 the
  night tree is complete and static). Not tied to capture stop — just a safe
  daily window.
- **Copy**: `rsync -a --info=stats2` from
  `/mnt/ssd/eclipticam-frames/night/<night>/` → `/mnt/muppet/bigstore/eclipticam-frames/night/<night>/`.
  Loop over any night dirs on the SSD not yet confirmed on bs (handles a missed
  day — catches up multiple nights).
- **Verify before free**: after rsync, a **`rsync -ac --dry-run` (checksum)
  compare** pass over that night; only if it reports **zero differences** is the
  night considered safely landed. (Mirror ship-astro-data's verified-copy
  discipline — cheap at 6G, the safety gate for deletion.)
- **Ship-and-free with a safety window**: keep the **most recent N=3 nights** on
  the SSD as a rolling safety buffer; verified nights **older than N** are
  **trashed** (`super/bin/trash`, → `~/.trash/YYYY-MM-DD/`, recoverable 14 days
  on puppy) — never `rm` (house rule). 6G/night × 3 = 18G resident; keeps the
  91%-full SSD from filling while retaining a local hot window.
- **Soft-EIO tolerance** (ansible doctrine): if the bs mount is down (EIO / rsync
  rc≠0), **do nothing destructive** — log, exit non-zero, **retry next night**.
  Never free a night that didn't verify. The safety window absorbs a few missed
  nights.
- `--dry-run` default + `--go`, `--help`/`--hints` per house convention.

## Part 3 — how bs fits squashing / cold-archive (STATE.md schedule)

bs = **principal live astro store** (per mission). This sync lands nights
**full-cadence** onto bs. The relationship to squash + cold-archive:

- **bs is where nights live and get squashed in place.** Nights land full, age,
  then `squash-starcam-night`-style reduction runs **on bs** (sum8/sum2), on the
  RRD resolution schedule — squashed form kept ~forever. bs is the home of the
  O(1) squashed pyramid.
- **cold-archive-night** ships keepers / pre-squash nights to Deep Archive as
  the **offsite copy of record**. bs holds the hot copy; Glacier holds the
  insurance. bs is **not** freed by cold-archive — it is the durable local store.
- This sync is **agnostic** to the squash/cold-archive *cadence* — it only
  guarantees "the night is on bs, full-cadence, verified." Squash + cold-archive
  are downstream consumers of the bs tree, unchanged by this design.

**OPEN (Peter, TBD 2026-07-29):** the precise squash/cold-archive *relationship*
to bs (permanent hot record + squash-in-place, vs. landing-zone-then-free) is
deferred to Peter's data-reduction day ([[data-reduction-day]] /
[[glacier-every-day]]). This design deliberately does not force that choice: it
lands verified full-cadence nights on bs and stops there. Whichever way the
squash schedule goes, it consumes the bs tree this sync produces.

## Build order & dependencies

1. **DEP (ansible strand, in flight):** bs export live on muppet + mounts on
   clients. Eclipticam mount already live. **astrocam is not yet a bs mounter**
   — needs adding to ansible host_vars before Part 1 rollout.
2. **Part 2 (eclipticam ship-and-free)** — buildable now (mount is live). Lowest
   risk, biggest immediate win (91%-full SSD). Build `eclipticam-ship-night`,
   dry-run, verify one night, then enable timer.
3. **Part 1 (astrocam repoint)** — after ansible adds the astrocam bs mount.
   Repoint fstab, restart capture, watch a frame land. Add the buffer/drain
   spool as a follow-up once base repoint is proven.

## Cross-strand notes

- → **ansible strand**: add **astrocam** as a bs NFS *mounter* (host_vars
  `astrocam.yml`, mount `muppet.local:/mnt/bigstore/astro-data/astrocam-frames`
  at `/home/peter/astrocam-frames`, soft). This replaces its current bigdisk
  mount. Coordinate rollout so capture isn't writing to a dead path.
- → **bigstore-xfer strand**: the recurring nightly sync (this design) supersedes
  the one-shot `run-*.sh` backlog pulls for the ongoing case; backlog scripts
  can retire once caught up.
