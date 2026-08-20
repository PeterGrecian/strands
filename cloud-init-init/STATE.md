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

## pog — an x86 job this strand's tooling does not cover (2026-08-16)

Peter wants **pog** (HP Compaq Elite 8300 SFF, Ivy Bridge amd64) booted from an
**SD card in a USB reader**, to serve as a **bench box for the disk question** —
somewhere to test drives over its internal SATA, which gives native SMART where
the fleet's USB bridges are blind (cf. `seagate-expansion-blocks-sat`). pog has
no disk of its own: its SSD is in eclipticam, so booting off removable media is
how it runs without buying one.

**`configure-sd-card.sh` cannot do this and should not be stretched to.** It is
Raspberry Pi OS + cloud-init only and explicitly refuses x86 (`:92`, `:960`).
This is a plain OS install onto a removable device — in this strand's *domain*
(writing bootable cards from pip) but not its *tooling*.

**Route chosen: Ubuntu Server 26.04 LTS installer.** Confirmed published as
`ubuntu-26.04-live-server-amd64.iso`, 2.7 GiB, dated 2026-04-20, "Resolute
Raccoon". Note there is **no `26.04.1` point release yet** — only `26.04/`
exists alongside `24.04.2/3/4`. That is fine here: the usual reason to wait for
`.1` is hardware enablement for *new* silicon, and every driver a 2012 Ivy
Bridge needs has been in-kernel for a decade.

**Route considered and dropped: preinstalled image.** Ubuntu publishes **no
preinstalled amd64 image** (those are arm64-only; the amd64 download is an
installer ISO). Debian does — `debian-13-generic-amd64.raw`, 3.0 GiB, published
as `.raw` so no `qemu-img` conversion — and the `generic` variant (not
`genericcloud`, which is stripped to virtio and would not boot bare metal)
would have worked headless via a `nocloud` seed, the exact mechanism
`configure-sd-card.sh:870-877` already implements. **Dropped once a screen was
confirmed available**, since the installer route was Peter's preference and a
display makes it free of cost.

**The display question resolved itself.** VGA→HDMI was thought to be the
obstacle; it is the genuinely hard direction (VGA is analogue, so it needs a
powered active converter with an ADC, ~£15 and often flaky — unlike
DisplayPort→HDMI, which is a passive ~£5 adapter). **Moot: Peter has a monitor
with a VGA input**, so it is one plain VGA cable and nothing to buy.

*Worth keeping regardless of install route:* a screen is the bench-box
diagnostic tool. This machine's known failure mode
(`pog-hp-8300-ram-15v`) **passed the BIOS memory test but failed under GRUB** —
only visible with a display attached.

**Open, blocking the download:**
- **A spare USB stick for the installer** — the installer route needs *two*
  removable devices (stick + target card), which is the cost Peter was
  originally trying to avoid. **Not the Patriot 29G**: this fleet has already
  caught it throwing read errors booting an installer and rejecting
  `dd oflag=direct`.
- **Disk space at pip** — 92% full, 19G free, against a 2.7G ISO. See the armhf
  loose end below.

**Expect on the day:** F9 for HP's boot menu (F10 = BIOS setup); if the stick
does not appear, enable **Legacy/CSM** — 2012 HP USB boot is happier there.
When installing, **identify the target card by size** — both devices are USB and
Subiquity shows two similar-looking disks; installing onto the booted stick is
the classic error.

## Pending / loose ends

- **2.9G armhf image cached at `pip:/opt/raspios-imgs/`** — keep for future
  armhf writes, or `trash` to reclaim space. (Also cached on puppy NFS.)
  **Now live**: pip is at 92% / 19G free and the pog ISO needs 2.7G. Asked
  Peter to decide; unanswered.
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
- **x86 hosts are out of scope for `configure-sd-card.sh`.** The script refuses
  non-ARM by design (it chroots into an ARM rootfs). Writing a bootable card for
  an x86 box is a normal OS install, done with that OS's own installer — do not
  grow the script an amd64 branch for one-off bench machines. The *transferable*
  part is the `nocloud` rootfs-seed trick (`:870-877`), which works on any
  distro's cloud image if a headless self-provisioning card is ever wanted.
