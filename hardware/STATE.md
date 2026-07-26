# hardware — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **muppet** (X1 Carbon Gen 9, headless NFS/compute node) carries external
  disks over USB: bigdisk (ST31000528AS, 838G XFS + 93G XFS, ~15yo, distrusted),
  photodisk (360G-class ext4), and a 360GB ST3360320AS. All on a shared USB
  power feed. See memory `project_muppet_hardware`.
- **puppy** (.11) has a Patriot Memory 29GB vfat thumb drive plugged in
  (2026-07-15), currently unmounted — courier-grade, fine for transfer/critical
  subset, not for sole copies. (That Patriot stick is **unreliable** — threw
  read errors booting an installer + rejects `dd oflag=direct`; distrust it.)
- **vole** (.9) — Acer C720 Chromebook, the fleet's x86 always-on micro-node.
  Celeron 2955U (2c/2t, Haswell), **2GB DDR3-1600 SODIMM (UPGRADEABLE — not
  soldered)**, 16GB Kingston SATA SSD (SNS4151, ~9G free; form factor
  unconfirmed — mSATA per model# vs ~M.2 by measurement, check before upgrade),
  Atheros AR9462 WiFi (no
  onboard ethernet). Now coreboot/MrChromebox UEFI (WP screw removed → still
  re-flashable). **Internal screen is half-dead → drive headless over SSH;**
  HDMI works if a monitor is needed. USB ports are finicky (try both). Full
  spec in memory `reference_vole_hardware`; role/setup in `project_vole_c720`.
- **Conscious-maintenance flow on pip** (absorbed from pip-maintenance,
  2026-07-11): the `firmware-updater` snap notifier popup is disabled on pip
  (`sudo snap stop --disable firmware-updater.firmware-notifier`) — an Install
  button with no changelog is a bad security pattern. Instead `cld -k`
  housekeeping runs `fwupdmgr get-updates` → housekeeping.log, so pending
  firmware surfaces at session start for changelog/CVE review before installing.
  UEFI dbx updated 20250902 → 20260402 (CVE-2026-8863, revoked vulnerable
  shim-0.9-era bootloaders).

- **vole** (Acer C720 Chromebook → Debian) — the fleet's first purpose-built
  **x86_64 always-on node**, acquired to be the OpenSearch tiebreaker that no Pi
  can be (Pi 4B is ARMv8.0-a; the AL2023 arm64 image needs ARMv8.2-a — see
  IDEAS triage below). C720 = Haswell Celeron 2955U (x86_64), so it clears the
  floor. Chosen route: **MrChromebox UEFI Full ROM** (WP screw removed, ChromeOS
  gone) + **Debian 13 stable** minimal (SSH-server, no desktop). Hostname
  **vole** (ssp alias `v`, free colour). As of 2026-07-18: **Debian 13.6.0
  amd64 netinst written + SHA256-verified to the Patriot 29G USB** (the old
  Ubuntu-2023 live installer on it was overwritten — that stick had migrated
  from puppy to pip). Physical flashing + install is the next bench session.

## Pending / loose ends

- **muppet photodisk (sdb, ST3360320AS 360G) is FAILING — retire on 6 TB arrival
  (2026-07-25).** Not the 2026-07-15 power event this time — the drive itself is
  dying. SMART: **274 Current_Pending_Sector** (unreadable *now*), **190
  Reallocated_Sector_Ct**, **305 Reported_Uncorrect**, 312 ATA errors (recent all
  UNC on READ DMA EXT), 37,974 power-on hours (~4.3 yr). `overall-health: PASSED`
  is misleading — the attributes say end-of-life. Ran **hot at 46 °C** (sdc sat at
  34 °C same chassis); **a cooling fan was put on the drive → dropped to 38 °C**,
  so thermal risk is handled for the bridge period. **6 TB Seagate bought
  2026-07-26, arrives 2026-07-27** — full migration runbook + target state below
  ("6 TB migration runbook"). Short version: ddrescue sdb (dying) onto it first,
  then sdc; verify; reformat sdc→unified tepid archive + sdb→emergency copy.
  - **This disk was cog's old system disk.** Mounted at `/mnt/photodisk` (ext4,
    sdb1), 257 G used. **Correction to the 2026-07-16 note below:** starcam-backup
    lives HERE on photodisk (`/mnt/photodisk/backups/starcam-backup`), *not* on
    muppet's root fs as previously recorded.
  - **Backup-coverage map built 2026-07-25** (what has a 2nd copy vs single-copy on
    the dying disk):
    - ✅ **SAFE** — `images` 61 G, `audio` 32 G, Dropbox/pastdev/dev/Documents:
      full 2nd copy on **pip `/mnt/cog`** (a local copy of the cog system disk;
      NOT the NFS mounts — pip's `~/eclipticam-frames`, `~/astrocam-frames` are
      autofs NFS mounts *back to muppet*, not copies, and pip has only 27 G free
      so it can't hold the bulk). `audio` also on bigdisk.
    - ✅ **secured today** — rsync'd starcam nights **05-20, 05-22, 05-23** (+ the
      already-present 05-26, 05-30) from sdb → **bigdisk** (sdc, healthy: 0
      pending/realloc, 8221 h). 5 of 6 nights now duplicated. bigdisk at ~35 G free.
    - ❌ **STILL SINGLE-COPY on dying sdb** (too big for bigdisk's 35 G free; wait
      for 6 TB): **starcam 2026-05-21 (40 G)** and **eclipticam-frames/day (21 G)**
      (bigdisk has eclipticam `night/` ~54 G but not `day/`).
    - **S3 does NOT hold the raw starcam backup** — `starcam-berrylands-eu-west-1`
      is only 1.3 G (published site: frames/nights/sightings/videos), and
      `astro-berrylands-eu-west-1` (73 G) has astrocam/eclipticam prefixes but not
      the starcam dated dirs. So this rsync closed a real gap.
  - **Also stop exercising the dying disk:** OpenSearch writes `osd-snapshots` +
    `opensearch-data` onto sdb (osd-snapshots touched 04:37 the morning of
    2026-07-25) — repoint those at bigdisk / the 6 TB. Not yet done.
  - **Alert storm handled (2026-07-25):** tonight's starcam rsync pushed bigdisk
    90→96%, tripping muppet `monitor`'s 95% disk-**warn** → xMatters MEDIUM every
    15 min, plus a daily SMART page correctly reporting sdb's 3 faults. Raised the
    drop-in `/etc/systemd/system/monitor.service.d/disk-threshold.conf` to
    **warn/crit = 99/99** and restarted monitor → muppet went quiet. **This is a
    TEMPORARY bridge — revert to 95/98 once the migration drops bigdisk usage.**
    (NB: restarting monitor re-fires the SMART check immediately — each restart =
    one SMART page; and open xMatters incidents re-notify until **Closed**, not
    just Acknowledged — see [[xmatters-response-close]].) Edit is manual, not
    ansible-managed (the role templates only the base unit).

### 6 TB migration runbook — DISK ARRIVES 2026-07-27

**Disk bought (2026-07-26):** Seagate Expansion **STKP6000400 6 TB** (3.5"
external USB 3.0, £199.99 from scan.co.uk). NB it's a **3.5" desktop drive → has
a MAINS BRICK**, not bus-powered despite the listing; give it its **own** power
feed, not the shared USB feed that caused the 2026-07-15 fault.

**Target state after migration** (collapses muppet's fragile shared-power USB
disk sprawl down to one live drive + two cold copies; nothing to landfill):

| Disk | Role | Power |
|---|---|---|
| **6 TB Seagate** (STKP6000400) | **Primary** live consolidated backup | always on, own mains |
| **sdc** (unified ex bigdisk+bigdisk2) | **Tepid archive** — reformat as ONE volume (ext4, friendlier than XFS for power-cycling) | **network-switched, normally OFF, spin-up on demand** — switch is electronics-strand work (hoped: Pi Pico W high-side switch) |
| **sdb** (ST3360320AS, dying) | **Emergency-only tertiary** copy — reformat, reload, shelf. NOT a reliable copy (274 pending sectors); label physically **"DYING — emergency only"**. Kept because a flaky 3rd copy beats none if the 6 TB fails. | shelved (cold) |
| **ATX PSU** (was feeding the disk array) | freed → **rackinabox** | — |

**Steps (order matters):**
1. **Plug in 6 TB, identify the bare drive + SMR check** (~2 min):
   `sudo smartctl -i /dev/sdX | grep -iE "Device Model|Model Family|Rotation Rate"`
   and `cat /sys/block/sdX/queue/zoned`. 7200rpm → likely CMR; 5400rpm + zoned!=none → SMR.
   SMR is FINE for this job (one sequential bulk write) — just note+label it.
2. **ddrescue sdb FIRST** (it's the dying one) onto the 6 TB. **ddrescue, NOT
   cp/rsync** — cp stalls on the 274 pending sectors; ddrescue logs them and
   continues. Keep the ddrescue **mapfile** and check which sectors (if any)
   couldn't be read. This sweeps up the two single-copy items (starcam 05-21 40G,
   eclipticam day/ 21G) — *unless* skipping the abandoned moon-tracking `day/`.
3. **Copy sdc** (bigdisk+bigdisk2, ~892 G used) onto the 6 TB — plain rsync/cp is
   fine (healthy disk). Total onto 6 TB ≈ 1.15 TB → fits with ~4.8 TB spare.
4. **VERIFY before reformatting anything** — checksums / file counts / test reads.
   Never be single-copy at any moment. Only after verify:
5. **Reformat sdc as ONE unified ext4 volume**, reload from the 6 TB → tepid
   archive. **Safe-power rule:** power to sdc must only ever be cut *after*
   sync → unmount → `hdparm -Y` spindown; mount only after spin-up. Wrap in a
   script; the network switch (electronics strand) is a dumb actuator called by it.
6. **Reformat sdb, reload, shelf + label** as emergency-only. (A `badblocks`-style
   write pass first surfaces/remaps the pending sectors so you know what you're storing on.)
7. **Free the ATX PSU** → rackinabox.


- **vole — FLASHED ✅, Debian installing (2026-07-19).** The screen problem was
  cracked: MrChromebox **UEFI Full ROM flash SUCCEEDED** (confirmed on-screen:
  Board PEPPY, Haswell, Fw WP Disabled → option 2). vole is now a UEFI PC.
  **How we finally drove it:** the dead-half was the *internal panel*; the HDMI
  monitor worked but ChromeOS put the UI on the (primary) broken panel with
  HDMI as an empty extended desktop — **Ctrl+⛶ (fullscreen key) toggled display
  MIRRORING** → UI appeared on HDMI → Ctrl+Alt+T at the login screen opened
  crosh → `shell` → ran `firmware-util.sh`. Menu read via **phone photos of the
  HDMI screen** (synced to pip ~/Downloads, Claude read them). That combo —
  mirror-to-HDMI + phone-photo readback — is the reusable trick for this laptop.
  Then: Patriot USB stick threw **read errors mid-boot** (flaky bridge, as
  feared) → re-wrote Debian to the **8GB SD card** instead (byte-verified on
  pip: readback SHA == ISO SHA) and booted that cleanly. Also note: the C720's
  USB ports are finicky — one port wouldn't enumerate the stick, the other did.
  Debian installed ✅ (minimal, hostname vole, user peter, **no sudo** — a root
  pw was set instead; networking is **ifupdown**, no NetworkManager). Reachable
  over **WiFi at 192.168.0.17** (real Debian OpenSSH — pip's key installed via
  scp, key-auth works). **RAM = 1.7Gi → the 2GB SKU** (keep lean; small OS heap).
  Disk 13G root, 11G free. **USB ethernet dongle** (Naxiang/SZNX 100M,
  ec:9a:0c:13:a3:8d) is *detected* as `enxec9a0c13a38d` but DOWN/unconfigured —
  a software gap (no NM), not a fault.
  - **Templated into ansible (committed 2026-07-19):** `inventory/hosts` →
    `[laptops]`; `host_vars/vole.yml` modelled on puppy (headless always-on
    power/tlp, ssp alias `v`, lean roles for 2GB — no desktop/aws/vscode).
    **Provision once sudo exists:** `ansible-playbook playbooks/site.yml
    --limit vole --ask-become-pass`. Peter is sorting sudo (fleet way, not a
    hand-hacked `su`). Static IP + the ethernet dongle left as TODOs in
    vole.yml (WiFi DHCP .17 for now).
  - **sudo DONE** (2026-07-19): `sudo` + `passwd` were already installed;
    `usermod -aG sudo peter` (as root via `su -`; peter's PATH lacks /usr/sbin
    so run usermod as root) + installed pip's sudoers (passwordless `%sudo`).
    Passwordless sudo confirmed from pip.
  - **Static IP DONE**: pinned to **192.168.0.9** on WiFi via ifupdown
    (/etc/network/interfaces, wpa creds inline — .9 free, in the .2–.11 static
    pool). NOT NM-managed → ansible network role doesn't apply; static lives in
    ifupdown. Hit a **DNS-clobbered-on-boot** bug (minimal install had no
    `resolvconf`; a dhcpcd template wiped resolv.conf each boot) → fixed with
    `resolvconf` + nameservers in resolv.conf.d/base. Reboot-verified: comes up
    clean on .9 with DNS + internet. ansible inventory + host_vars updated.
  - **Tiebreaker join HANDED OFF to aifabric-sessions** (2026-07-19): wrote a
    full briefing to `strands/aifabric-sessions/IDEAS.md` + a mailbox ping.
    That strand owns certs/SAN/compose; hardware's deliverable (a trustworthy
    x86 node at a stable address) is complete.
  - **Remaining (lower priority):** run `ansible-playbook site.yml --limit vole`
    to finish provisioning (dotfiles/docker/watchdog); optionally migrate WiFi
    ifupdown→NetworkManager so the static+DNS become ansible-managed; the USB
    ethernet dongle (enxec9a0c13a38d, detected, DOWN) if wanted.

- **[superseded] vole flash was BLOCKED on a half-dead screen** — kept for the
  hard-won remote-access findings below (still valid if the mirror trick ever
  fails). Where it stood:
  - **State of vole:** stock ChromeOS firmware (nothing flashed, not bricked),
    **Developer Mode ON**, **WP screw removed** (`wpsw_cur`=0 expected), on the
    LAN as **192.168.0.17**. The old ChromeOS was wiped/damaged mid-attempt; we
    **rebuilt it from a peppy recovery USB** (Google image
    `chromeos_12239.92.0_peppy_recovery_stable-channel_mp-v3.bin`, written on
    pip) → back to a working dev-mode ChromeOS.
  - **The blocker:** vole's **HDMI output has a dead half** AND — crucially —
    the ChromeOS **VT2 text console only renders on the internal panel, not
    HDMI** (HDMI is only driven by the *graphical* session). So the MrChromebox
    menu prints where Peter can't read it. Can't drive it remotely either:
    ChromeOS dev-mode **sshd would not start** (`ps` confirmed none running;
    read-only `/etc/ssh`, no host keys; `ssh-keygen -A` writes to the wrong/RO
    dir; removable media doesn't auto-mount at the VT console). vole CAN ssh
    *out* to pip (password auth), but that only lands a shell on pip.
  - **Assets staged on pip:** Debian 13.6.0 netinst on the Patriot USB (verified);
    `~/tmp/vole-sshd.sh` + `~/tmp/go.sh` = scripts that make host keys in `/tmp`
    and start sshd on `0.0.0.0:22` (dodges RO `/etc/ssh`); a FAT card labelled
    **VOLE** (the ex-recovery 8G card) carrying the script. On vole the card
    mounts as **/dev/sdc1** (odd letter — mount it explicitly, it doesn't
    auto-mount at the VT console).
  - **HARD-WON REMOTE FINDINGS (so we don't relearn them):** vole's ChromeOS
    dev sshd, once started with host keys in /tmp, **does answer** — the crypto
    works with explicit legacy algos (`KexAlgorithms=diffie-hellman-group14-sha1,
    …-group1-sha1,…-group-exchange-sha1`; `HostKeyAlgorithms=ssh-rsa`;
    `PubkeyAcceptedKeyTypes=+ssh-rsa`). pip's OpenSSH 10 **cannot** append these
    with `+` (they're removed) — must **set them explicitly**. **Inbound to
    vole:22 from the LAN did NOT work; the REVERSE TUNNEL did** — on vole:
    `ssh -N -R 2222:localhost:22 peter@192.168.0.61`, then pip connects to
    `localhost:2222`. **Password auth ALWAYS failed** even with the correct
    password (`smash`) because sshd was run `UsePAM=no` and ChromeOS passwords
    need PAM — so **use KEY auth** (put pip's `id_ed25519.pub` in
    `/root/.ssh/authorized_keys`, pubkey doesn't need PAM). The tunnel is
    fragile (dropped repeatedly). Net: the remote route is *possible* but too
    flaky to trust for an irreversible flash.
  - **RESUME when a fully-working display is available** (any other HDMI
    monitor/TV → the flash is a 5-min job once the menu is readable), OR once
    the **[[usb-hid-keyboard]]** rig exists (type the flash keystrokes blind).
    Do NOT flash through the fragile ssh/card channel — it's an irreversible
    step. Next action on a good screen: boot ChromeOS graphical → crosh
    (Ctrl+Alt+T) → `shell` → run the MrChromebox script → **UEFI Full ROM**,
    back up stock firmware to a spare USB first, then boot the Debian stick.
  - Then the original integration steps below still apply.
- **vole fleet integration (after the flash):**
  1. Debian minimal install (SSH server, no GNOME), hostname `vole`, peter user
     + `~/.ssh/id_ed25519` key.
  2. add `v=vole|vole.local|<green/yellow/cyan/grey>` to `~/.config/ssp`;
     add vole to ansible inventory (docker + common roles); confirm RAM SKU with
     `free -h` (2GB vs 4GB — sizes the OpenSearch heap).
  3. *Cluster (aifabric-sessions strand owns this step):* copy `cluster/` +
     `cluster-certs/` to vole, add its IP to `discovery.seed_hosts` +
     `cluster.initial_cluster_manager_nodes`, regen node.pem with vole's IP in
     the SAN, run the voting-only compose (`node.roles=cluster_manager`, no
     data) → quorum 2/3, cluster stays writable through any single-node outage.
  - Note: dd to USB sticks here needs **no `oflag=direct`** — the Patriot/card
    USB bridges return EINVAL on O_DIRECT (`dd: IO error: Invalid input`); plain
    buffered dd is fine.
- **Spun out [[usb-hid-keyboard]] strand (2026-07-19)** — a Pi-in-USB-gadget-mode
  keyboard emulator to drive undrivable targets (dead screens, BIOS, no-net
  boxes). Born directly from this vole pain. If it had existed, tonight's flash
  would have been trivial.


- **muppet shared-power fault — power-feed solder still OPEN.** The 2026-07-15
  power event dropped bigdisk (sdc) *and* photodisk (sdb) off the USB bus at
  once — shared power-feed fault, not disk failure. **Data side is now fully
  recovered (2026-07-16):** muppet was powered off for maintenance, rebooted;
  bigdisk XFS recovered clean on boot; photodisk (sdb1, ext4, UUID
  4732fe64-…-647cfe20c88b — the disk that threw the JBD2 journal error)
  fsck'd clean (exit 0, nothing lost — backups/ + temp/, 96G), remounted rw,
  write-tested. SMART on both Seagates PASSED — confirms power event, not drive
  damage. **[UPDATE 2026-07-25: photodisk/sdb has since genuinely FAILED — 274
  pending sectors etc. — see the top of Pending. That 2026-07-16 "PASSED, not
  drive damage" reading no longer holds for sdb; it's now end-of-life.]**
  **Root cause NOT yet fixed:** photodisk is back on the *same* USB
  power feed. The connector solder job (solder+heatshrink, not Wago) is the
  outstanding physical fix — do it at the bench when convenient.
- **Fixed the disappearing-disk symptom:** photodisk had NO fstab entry (was a
  runtime-only mount) — that's why it never returned after reboot. Added
  `UUID=… /mnt/photodisk ext4 defaults,nofail,x-systemd.device-timeout=10s 0 2`
  (matching bigdisk's nofail style; fstab backed up, validated, daemon-reloaded).
  Now auto-mounts and survives reboots; `nofail` means a future blip won't wedge
  boot. Doesn't prevent another mid-write hit — that still needs the solder fix.
- **NFS clients were hanging — root cause found & fixed (2026-07-16).** After the
  reboot muppet's `nfs-server` was `inactive`: the `nfs-server-generator`
  auto-emits a hard `RequiresMountsFor=` for every path in `/etc/exports`, and
  photodisk (no fstab entry then) wasn't mounted → dependency failed → ALL four
  exports went dark → clients (astrocam, pip) hung. Started the server (fixed the
  immediate hang; astrocam recovered). **Hardened so one flaky disk can't down
  all exports again:** masked `nfs-server-generator` (→ /dev/null) so
  `RequiresMountsFor=` is now empty — verified: nfs-server starts regardless of a
  missing export mount. Note an empty `RequiresMountsFor=` in a drop-in does NOT
  clear it (additive directive); masking the generator is the working fix. Done
  via ansible `roles/nfs-server` (generator mask + tolerate-missing exportfs
  drop-in); daemon-reexec'd. Deployed + committed to ansible.
- **starcam camera retired, but its data still needs processing (2026-07-16).**
  [Location correction 2026-07-25: the frames are on **photodisk/sdb** at
  `/mnt/photodisk/backups/starcam-backup`, not muppet's root fs — see the failing-disk
  entry at the top of Pending.] The starcam *camera* is retired; its ~106 GB of raw
  FITS frames (~44k files, 2026-05-20…05-30) **still need
  processing**, so the `starcam-backup` NFS export STAYS live (muppet exports it,
  pip mounts it at `~/starcam-muppet` to process). Withdraw the export + reclaim
  the 106 G (which is a third of muppet's 94%-full root) only once processed.
  (Briefly removed the export then restored it when Peter clarified the frames
  need processing — net: export unchanged, hardening + starcam retirement noted.)
  **Scope note:** the frame *processing* itself is astro-pipeline work, NOT this
  strand — hardware owns the disk/export plumbing that makes the frames
  reachable, not what's done with them.

- **Fleet disk-pressure watch (2026-07-18).** Recurring capacity signal worth a
  standing eye: puppy root hit **100% full** (all camera raw in /home/peter —
  astrocam 132G, starcam 122G, eclipticam 56G, skycam 52G; the GLOBAL.md
  "unbounded raw" risk realised) — freed to ~89% during the aifabric session.
  pip root also at 97% (6.7G free), which flood-blocked OpenSearch index
  creation at the 95% watermark. Fixing puppy's camera ship-and-free retention
  is astro/astro-storage's job, but the *disk pressure* is a fleet-health item
  here. Consider a **fleet disk-usage alert** if none exists (pi-fleet already
  reports disk%; an `alert`-backed threshold trigger would close the loop).

- **Codify the firmware-notifier-disable as an ansible task** (workstation role)
  so it covers muppet and survives a pip reinstall (absorbed from
  pip-maintenance). Possible bigger version: fleet-wide "firmware posture" —
  fwupd on laptops, rpi-eeprom on Pis.

## Decisions

- **muppet's dim screen: WON'T FIX — flogging a dead horse (2026-07-22).**
  Symptom is dim, worse on the *left-hand side* → classic backlight/LED-driver
  (edge-lit panel not propagating light across), not GPU (no artefacts) and not
  software. Realistic fix = whole panel-assembly swap on an X1 Carbon Gen 9
  (cheap-ish part, fiddly job). But muppet is **deliberately headless** (NFS/
  compute, driven over SSH) — a working screen adds nothing to its role. Decision
  stands: leave it headless, don't diagnose or swap the panel.
- **Fleet ceiling is RAM, not cores (2026-07-22).** All three x86 boxes sit at
  ~7.5 GiB: pip (i5-8265U Whiskey Lake — the fleet's *slowest* CPU), muppet
  (8-core Tiger Lake), puppy (i5-1135G7 Tiger Lake, fastest clock). So demoting
  pip to a compute node buys little (weakest CPU; muppet+puppy already cover
  compute). If Peter buys a new laptop, it becomes the daily driver; pip's best
  second life is bench/spare, not compute. Don't buy dedicated compute unless a
  specific workload is CPU-starved — current astro/OpenSearch pressure is
  disk/retention, not CPU.
- **New laptop = non-urgent shopping quest, driven by future capacity
  (2026-07-22).** Not a fix-it-now: fallback if pip pops is already covered
  (phone + keyboard, or another host + monitor). The forward driver is that
  **muppet and puppy WILL get overloaded** at some stage — so the eventual buy
  should add a genuinely capable third x86 node: **more than 8 GiB RAM** (the
  standing fleet ceiling) and a CPU newer than pip's, not a like-for-like pip
  replacement. It becomes daily driver; pip drops to bench/spare fallback.
- **Firmware updates are reviewed consciously via `cld -k` housekeeping**, not
  installed from unexplained desktop popups. (2026-07-11, from pip-maintenance)
- **Connectors: solder + heatshrink, not Wago.** Wago lever-nuts are for
  solid-core mains in fixed junction boxes; they back out under the mechanical
  stress/vibration of a disk power lead. For power feeds we rely on, use
  soldered + heatshrink (permanent) or a proper crimped connector (removable).
  This is the intended fix for the muppet shared-power fault above.
- **No reboot to clear a dropped-disk error.** A reboot doesn't re-seat a loose
  power lead and risks not getting the device back — the fix is targeted
  re-enumeration (re-plug), not a full restart. Power the machine *off* only if
  it's safer for doing the physical bench work, not to "clear the error".
