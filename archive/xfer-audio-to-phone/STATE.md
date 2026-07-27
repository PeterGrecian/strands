# xfer-audio-to-phone — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

Transferring `/mnt/cog/audio` (music collection on pip) to Peter's **Pixel 6a**.
The bulk transfer happened via a zip that Chrome unzipped on the phone. The
files are now organised on the phone for **AntennaPod** (one folder = one feed).

## Status (2026-07-23) — flatten + rename DONE

The on-phone audio lives at `/sdcard/Download/cog-audio/`. Only a **subset** of
the source landed — `composers` (16 GB) and `pop` (7.4 GB) did **not** transfer;
what's there is **116 files, 5.3 GB** across four folders. No `.m3u` playlists
in this subset, so the playlist-path worry never applied.

Flattened to one level and prefixed `z_` (so they cluster at the bottom of
AntennaPod's alphabetical subscription grid, away from real podcasts):

| Folder | Files | Notes |
|---|---|---|
| `z_podcasts` | 18 | Attenborough "A Point of View", was `podcast_archives/DavidAttenborough/<date>/` |
| `z_radio`    | 20 | Gideon Coe + John Peel 60s–90s, was `radio_internet_archives/` |
| `z_speech`   | 38 | Hitchhikers, Feynman, Hobbit, SimonSingh, Ramachandran, WhatIf — **all mixed in one feed** |
| `z_tapes`    | 40 | left with `Temptapes_etc/` subfolder + loose files (not flattened) |

All 116 files verified intact after every move. Nothing risky here anyway: the
zip is still on S3 and the originals are on pip at `/mnt/cog/audio` — three
copies, this is a rearrange-the-copy op.

## Connection — adb over WiFi/tailnet (USB failed)

**USB never enumerated** the Pixel on pip (`lsusb` showed nothing; not an auth
issue — the kernel never saw it). The **wireless** path Just Worked and is now
the channel:

- Android 11+ **Wireless debugging** with pairing code, over the tailnet.
- Phone: `pixel-6a` → `100.102.111.126` (resolves via MagicDNS full name
  `pixel-6a.tailc34ab9.ts.net`; bare `pixel-6a` does **not** resolve on pip).
- Connect/pair ports are **random** and change on toggle/reboot — discovered by
  scanning (`nmap -p 30000-49999`), not hardcoded.

Packaged as a reusable house tool: **`super/bin/adb-wifi`** (self-describing,
`adb-wifi --hints` explains the two-port pairing dance). The stale WSL/Windows
`super/bin/connect-phone` (usbipd/powershell) was removed — pip is native Linux.

## Left for Peter (in AntennaPod, tidy later)

- Old `Temptapes_etc` subscription is now **broken** (folder path changed to
  `z_tapes/Temptapes_etc`) — remove the dead entry, **without** ticking any
  "delete downloaded/media files" option.
- Add the `z_` folders as Local Folder feeds:
  `Download/cog-audio/z_podcasts`, `z_radio`, `z_speech`, `z_tapes/Temptapes_etc`.

## Open questions / possible follow-ups

- `z_speech` mixes six distinct audiobooks/lectures in one feed. Could split
  back into per-work feeds later if the mixing annoys (filenames disambiguate).
- Flat-single-feed-with-name-prefixes was discussed and set aside: the
  folder=feed boundary is also the per-feed settings/queue/resume boundary, so
  distinct listening contexts are worth keeping as separate folders.
- The missing `composers`/`pop` (23 GB) never transferred — phone had ~16 GB
  free. Revisit if Peter wants the music (not just spoken-word) on the phone.

## Decisions

- Channel = **adb over WiFi/tailnet** (wireless debugging), USB abandoned on pip
  (2026-07-23).
- In-place flatten to one level + `z_` prefix; `z_tapes` left un-flattened
  (2026-07-23).
- Reusable tool `super/bin/adb-wifi`; removed Windows-only `connect-phone`
  (2026-07-23).
