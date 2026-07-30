# cloud-init-init — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What this strand is

Bootable-Pi-image creation via the `Berrylands/cloud-init-init` repo:
`configure-sd-card.sh` writes a Raspberry Pi OS image to an SD card and
provisions it (WiFi, SSH keys, AWS creds, cloud-init user-data) so the Pi
self-provisions on first boot. Spans `Berrylands/cloud-init-init` (the tooling)
and the fleet hosts it images.

## What exists / done (2026-07-30)

**Wrote + recovered deskpi.** deskpi (Pi A+, ARMv6) had been left unbootable by
a prior `rpi-update`. Reflashed it with a fresh **Trixie 2026-04-21 armhf** card
via `configure-sd-card.sh` — this both provisioned deskpi *and* recovered it.
Then wrote a **second identical spare card** as a drop-in backup. deskpi now
boots, is on the eth0 dongle (`deskpi.local` / .71), and is SSH-reachable.

**Two writing patterns proven:**
- **On starcam** (the former skycam/gardencam Pi, used as a card-writing
  station): armhf image staged on the **puppy NFS mount** because starcam's own
  rootfs is tiny (478 MB free). starcam has no AWS CLI / no `*.pub`, so that
  card came out with **no WiFi and an empty `authorized_keys`** — had to be
  fixed by hand afterwards.
- **On pip**: image copied from puppy to `/opt/raspios-imgs/`, written locally.
  pip has AWS CLI + SSH pubkey, so the spare card got **WiFi (from SSM),
  peter's password hash, and a populated `authorized_keys`** — SSH-reachable
  out of the box. **Preferred writing host when the card can be at pip.**

**Fixed two repo bugs** (committed + pushed in `Berrylands`, `7b9b6ad`):
1. A `CACHE_DIR` env var couldn't override `cloud-init-init.conf` — the conf is
   sourced *after* reading the env, silently clobbering it. With the default
   `/opt/raspios-imgs` absent, the image wasn't found and **dd was silently
   skipped**, reconfiguring the old image instead of writing fresh. Now the env
   value wins.
2. `authorized_keys` was left empty when the writing host had a private key but
   no `id_ed25519.pub` (headless Pis). Now the pubkey is derived via
   `ssh-keygen -y`. Verified end-to-end on the pip-written spare.

**Repos are pre-cloned onto the card** (`super`, `dotfiles`, `ansible` into
`/home/peter/`) — but at the *writing host's* snapshot, not necessarily latest
`origin/main`. The card now in deskpi (written on starcam) carries super
`05b0169` / dotfiles `3c5def1` / ansible `e8fbd5e`; the spare (pip) carries
pip's snapshots. Consumers can `git pull` on first boot if they need current
code. Messaged [[astro-speaker-dither]] about this.

## Pending / loose ends

- **2.9G armhf image cached at `pip:/opt/raspios-imgs/`** — keep for future
  armhf writes, or `trash` to reclaim space. (Also cached on puppy NFS.)
- The **deskpi camera fault** is a separate strand ([[astro-speaker-dither]]) —
  confirmed hardware (IMX219 no I²C ACK, survives reflash). Not this strand.
- `download-image.sh` is hardcoded to arm64 / `/opt/raspios-imgs`; doesn't help
  for armhf or an alternate cache dir. Minor — worth generalising if reused.

## Decisions

- **Prefer writing on pip** when the card can be physically at pip: it has AWS
  CLI (WiFi + password from SSM) and an SSH pubkey (populated authorized_keys).
  A headless Pi as writing station leaves those steps incomplete.
- **Pi A+ / ARMv6 boards MUST get 32-bit armhf** (`--armhf`), not arm64.
- **Never `rpi-update` an ARMv6 board** — current firmware dropped ARMv6 and
  bricks it (this is what made the deskpi recovery necessary).
