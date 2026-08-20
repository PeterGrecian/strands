# hardware — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **muppet** (ThinkPad X13 Gen 2i, headless NFS/compute node) carries external
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

- **pog** — **HP Compaq Elite 8300 Small Form Factor** (Ivy Bridge, ~2012, so
  ~14 yr old; "old when I bought it"). **NOT on the LAN, not in ansible/ssp, and
  currently INCOMPLETE — it is in jeopardy, not a spare machine** (Peter's word,
  2026-08-10): *it still boots, except its SSD is now in eclipticam.* Treat it
  as a machine-shaped hole plus a parts donor, never as available capacity.
  - **RAM: 20 GiB** — deliberate mixed fill of **2 × 8 GiB + 2 × 2 GiB** across
    4 slots (was 4 × 2 GiB DDR3-1333 Samsung M378B5673FH0-CH9). Half the slots
    matched = full speed. **This is the only genuinely scarce thing about pog**
    — the fleet's standing ceiling is ~7.5 GiB (see Decisions).
  - **⚠ MEMORY VOLTAGE TRAP — already paid for once (Oct 2020).** DIMMs **must be
    1.5V**, NOT 1.35V. **Crucial's compatibility site is WRONG** for this model:
    it recommends DDR3L/DDR3U, but HP's manual states the 8300 does not support
    DDR3U and it *"can cause physical damage to the DIMM or invoke system
    malfunction."* Symptom was a general protection fault → GRUB rescue → reseat;
    it **passed the BIOS memory test but failed under GRUB**. Don't re-buy on
    Crucial's advice. Slots run white/black/white/black from the CPU — populate
    **white, white** for max speed; one channel only = single-channel mode.
    (Source: gdrive Google Docs "memory upgrade for pog" + "pog crash", 2020.)
  - **Its SSD is in eclipticam** — Kingston **SVP200S3120G** 111.8 G (matches the
    gdrive note exactly), now `/dev/sda` at **`/mnt/ssd`**, 22 G used / 82 G free.
    Note eclipticam **boots from a 14.9 G Cruzer Blade USB stick** (root 52%
    full), so reclaiming the SSD would not unboot it — it would cost it 22 G of
    data plus its working space. Old (~2012) SandForce drive: the least
    trustworthy part of this story.
  - **Assessment (2026-08-10): pog is POOR value as an answer to the redundancy
    gap.** Reviving it means taking working storage off a live capture Pi to run
    an Ivy Bridge box that idles ~30-50 W (≈£40-80/yr always-on) and is well
    below pip single-core — **not** a daily driver, **not** a compute upgrade.
    The £0 shuck + a modest offsite subset beat it per pound.
  - **Where it could still earn a place:** as a **storage host** its age barely
    matters and it beats muppet structurally — **internal SATA (native SMART, no
    USB bridge → the bigstore blindness problem simply doesn't exist)**, mains
    power, replaceable sockets, real cooling. If ever taken up, **buy it a disk**
    rather than borrowing eclipticam's back.
- **homepi** — the **home-services host: Home Assistant + Tailscale exit node**
  (recorded 2026-08-13; previously only referenced in passing as the SSH
  bastion / exit node `100.127.158.37`). Not part of the compute or storage
  tiering — it carries the *always-on household* services, so its availability
  requirement is different in kind from the astro fleet's: HA going down is
  felt immediately in the house, and the exit node going down affects remote
  access to everything. **Keep it out of experiments.**

- **nit** (specced 2026-08-12, **NOT YET BOUGHT**) — the **renewal machine**:
  a storage/compute server, and the first deliberate renewal purchase this
  strand has made rather than a repair. Peter: *"the ancientness of my hardware
  I think is a liability and I'm trying to renew it."* It has **no case** — it
  goes in rackinabox as bare board + PSU + disks, which is what turned that
  strand from a laptop shelf into a chassis project.

  **Role.** Written to at night, processes the data, then ships it to muppet
  for long-term storage — **muppet stays the archive of record.** Past data is
  copied back and crunched (~an hour), and the whole dataset may be
  re-examined roughly monthly. Ingest is **pipelined** (chunk N+1 ships while
  chunk N crunches), so the monthly pass is compute-bound and **gigabit is
  sufficient** — 2.5 GbE buys nothing.

  **Spec.** Ryzen 5 5600 (6c/12t, 65 W) · B550 mATX · 2×16 GB DDR4-3200 (two
  slots free; B550 takes 128 GB) · 512 GB TLC NVMe accumulator · ~512 GB SSD
  workspace · 3× 3.5" SATA · the ATX PSU already earmarked for rackinabox.

  - **DDR4 not DDR5 — the load-bearing decision.** Structural DRAM price
    crisis: DDR5 spot +307% Sept–Nov 2025, no forecast relief before late 2027;
    per-GB ~$16.20 DDR5 vs ~$7.64 DDR4. **32 GB of DDR4 costs less than 16 GB
    of DDR5**, so this also retires the fleet's standing ~7.5 GiB RAM ceiling.
    The AM5 counter-argument is CPU upgrade runway (Zen 6, support through
    2027) — but this fleet doesn't re-CPU at mid-life, it runs machines until
    the interfaces wear out (pog 2012, muppet X1 Gen 9, vole 2013). An upgrade
    path we won't walk isn't worth 2× on memory. **Revisit only if serious
    local LLM inference lands here** (that's a bandwidth workload).
  - **B550 over X570 deliberately** — X570's chipset fan is a noise liability
    in a silent enclosure. B550 also commonly gives 6 SATA vs ~4 on consumer
    AM5: the "obsolete" platform is the better-provisioned one for a disk box.
  - **⚠ OPEN BLOCKER — B550 lane sharing.** Two M.2 (accumulator + workspace)
    plus 3× 3.5" SATA plus possibly an OS SSD sits right at B550's edge: many
    B550s **disable two SATA ports when the second M.2 is populated**. Read the
    specific board's **block diagram**, not the marketing page, before ordering.
  - **The accumulation buffer defines the machine.** Subpixel sampling,
    bucket-sorted by brightness so different qualities of data accumulate
    separately: ~5 × 50k² × 3 int32 ≈ **150 GB, non-volatile**. Not a file
    cache — a dense persistent accumulator. Work is **tiled** to fit RAM/L3, so
    the access pattern is streaming read-modify-write, not random thrash.
    (Algorithm belongs to the astro strands; recorded here only because it sets
    the hardware.) **512 GB not the 256 GB first suggested**: 150 GB on a
    256 GB part runs ~60% full, shrinking the dynamic SLC cache and leaving
    little for wear-levelling, and small NVMe parts are slower on sustained
    write (fewer dies to stripe).
  - **Tiling vindicates 32 GB.** Because tiles fit RAM/L3, the "more RAM buys
    crunch throughput" argument weakens — 2×16 is genuinely enough, with the
    free slots as the cheap upgrade if that stops being true.
  - **OS placement UNDECIDED.** The OS caches to RAM and is a once-per-boot
    read, so performance barely cares. Options: partition the workspace SSD
    (root ~50 G), a separate small SATA SSD, or a thumb drive with logs
    written elsewhere (Peter's temptation). Argued against an *unpartitioned*
    shared device — a full workspace wedging root on a headless box is the bad
    failure mode. **Thumb-drive caution, from this fleet's own record:** the
    Patriot 29G threw read errors booting an installer and rejects
    `dd oflag=direct`; eclipticam boots from a 14.9 G Cruzer Blade at 52% full.
    USB sticks have no real wear-levelling and fail without warning — a poor
    boot device for a machine whose *purpose* is renewing ancient hardware. If
    the stick wins anyway: logs to tmpfs/workspace, and keep a written image.
  - **Coupling unchanged:** nit + rackinabox is consolidation, so the offsite
    subset ([[redundancy-not-capacity]]) is still required alongside.
  - Peter's closing note: *"the algorithm and hardware will evolve as
    required"* — this is a starting position, not a frozen BOM.

- **deskpi** — a Pi **A+ (ARMv6, 32-bit)** per `templates/app-deskpi.conf` in
  cloud-init-init. **MUST be flashed armhf** (Trixie Lite armhf), NOT arm64 —
  the fleet default `trixie_lite_64bit` will not boot on it. 512 MB RAM total →
  `gpu_mem=16`. Role: SD-card writing station + armhf build-host helper, cycling
  old Pis one card at a time to triage keep-vs-recycle. Last seen on subnet
  **192.168.4.x** (stale pi-fleet entry, currently down). See
  [[armv6-camera-v4l2-not-rpicam]] for the wider ARMv6 constraints.
- **starcam** (verified 2026-07-30) — the Pi formerly used as skycam/gardencam,
  now the **SD-card writing station** (USB card reader appears as `/dev/sda`).
  **Dual-homed:** eth0 `192.168.0.52` (default route) *and* wlan0
  `192.168.0.59` live simultaneously. Its local `Berrylands/cloud-init-init`
  clone was **stale** (configure-sd-card.sh dated May 30 vs pip's Jun 5) with
  **no `--armhf` support** → `git pull` before writing armhf cards for deskpi.

- **zog** (recorded 2026-08-18) — **Lenovo Chromebook Plus 14**, ARM64, bought
  as **travel / portable dev and relief for pip as a main driver**. The second
  strand of the renewal push alongside nit: nit renews the *server*, zog renews
  the *daily driver*. **MediaTek Kompanio Ultra 910** (1× Cortex-X925 + 3×
  Cortex-X4 + 4× Cortex-A720, ARMv9 with SVE2/bf16/i8mm), **16 GB LPDDR5x
  soldered**, **128 GB internal**, ~68 Wh battery, fanless. Genuinely fast —
  ahead of pip single-core and in a different league from muppet or vole. Full
  spec in memory `reference_zog_hardware`.

  **The structural fact that governs everything: work happens inside a Crostini
  VM, not on the metal.**
  - **Hostname inside is `penguin`, always** — never `zog`. Anything keying off
    `hostname` gets the wrong answer here.
  - **NAT'd behind ChromeOS** on `100.115.92.26/30`. Outbound to the LAN works
    (pings puppy, 5.7 ms); **inbound does not** — sshd runs but only on the NAT
    address. **No fleet host can reach zog.** Tailscale not installed.
  - **zog is a client of the fleet, never a member of it.** It cannot host a
    service or be addressed by another host. **Do not add it to ansible
    inventory or pi-fleet as a normal host.** If it ever needs reaching, the
    route is Tailscale on the *ChromeOS* side, not container port-forwarding.
  - Linux sees only a **10 G virtual root disk** (2.8 G used) — growable from
    ChromeOS settings, but it will not grow itself when it fills. With 128 G
    total shared with ChromeOS, **zog holds no data**: fetch–work–ship only.
  - **No GPU, thermal, cpufreq, SMART or DMI exposed.** `lspci` claims an Intel
    440FX on an ARM machine (virtio behind a fake QEMU bus) — ignore it.
    `systemd-detect-virt` says `none`; that is a lie of omission.
  - **Battery wear is invisible from Linux** (`cycle_count` 0, `health`
    Unknown) — check it on the ChromeOS side.
  - **Kernel is ChromeOS's** (6.6.119, built 2026-05-30) — updated by ChromeOS,
    not apt. Fleet kernel practice does not apply. Userland is Debian 13.5.
  - **Toolchain gap:** `git`/`gh`/`python3`/`stow` present; **`aws`, `gcloud`,
    `node`, `rclone` all MISSING.** Strand machinery works (super, strands,
    ansible, dotfiles, aifabric, osd all cloned) but nothing touching AWS, GCP
    or gdrive does yet. All four have arm64 builds — just not installed.
  - **RAM is the one unfixable spec:** 16 GB soldered, ~9.8 GiB to the
    container, **no swap**, and it was at 7.7 G used after ~3 h. Watch it.

  **In use (Peter, 2026-08-18): battery life and screen are both excellent** —
  and those are the two things you feel daily, so they, not the core count, are
  the real case for zog as pip-relief. The one regret is that **the screen is
  glossy** — "might not be entirely suitable, but swings and roundabouts".
  Worth being conscious of for bright-room or outdoor work, and for anything
  where a dark image is on screen. A known trade against the panel quality, not
  a deal-breaker.

### Laptop identity, cooling geometry and rackinabox mounting (2026-08-20)

**Two model records were wrong or missing, corrected from DMI over SSH:**

- **muppet is a ThinkPad X13 Gen 2i (20WK00AVUK), NOT an X1 Carbon Gen 9.**
  Recorded wrong here (3 places) and in `project_muppet_hardware`; both fixed.
  `product_version` says X13 Gen 2i and 20WK is the X13 Gen 2 machine type.
  **Matters for the dead-screen repair** — panel assemblies, bottom covers and
  fans are not interchangeable with an X1 Carbon.
- **pip is a ThinkPad X390 (20Q1000LUK)**, i5-8265U Whiskey Lake. Its model was
  recorded nowhere before — only the CPU.

**Cooling geometry of the five laptops.** All the fanned ones take air in
through a grille on the **bottom cover** — a face, not an edge. None has a
hinge intake. What sits at or near the hinge is *exhaust*, on some of them.

| Host | Model | Exhaust | Vertical mount: edge UP |
|---|---|---|---|
| pip | ThinkPad X390 | left side, rear | left edge up (sideways) |
| muppet | ThinkPad X13 Gen 2i | left-rear | left edge up (sideways) |
| vole | Acer C720 | left-rear (lower confidence) | left edge up (sideways) |
| puppy | ASUS VivoBook X515EA | rear, through the hinge gap | hinge up (trackpad down) |
| zog | Lenovo Chromebook Plus 14 | **fanless** | any; both faces clear |

**Rule: exhaust edge up.** Two effects align — the vent joins the rising column
instead of fighting it, and the fin stack ends up above the CPU so the heat
pipe gets gravity-assisted condensate return instead of pumping uphill through
the wick. Hinge-down is the one to avoid: on puppy it points exhaust straight
into the incoming air.

**Applied by Peter 2026-08-20.** ⚠ **Provenance caveat:** the vent positions
above are model-level knowledge, not eyeballed. A bench check (load the CPU,
feel which edge blows hot) was proposed and Peter reported the orientation done,
but the per-machine findings were never relayed — so treat the table as
*predicted and adopted*, not measured. Cheap to confirm next time the machines
are handled; vole is the least certain and the least important (15 W Haswell
Celeron, headless, idle).

**Rack: a stainless wire dish drainer, adjustable pitch, FORCED bottom-to-top
airflow** (Peter, 2026-08-20). Wire is nearly pure open area, so the slots
barely obstruct flow, and vertical mounting means dust falls out rather than
settling on the intake grilles.

- **Pitch ~40 mm uniform** = thickest laptop (~20 mm: puppy, vole) + ~20 mm
  clear gap. pip/muppet are ~17 mm so they get a little more. **Keep the gaps
  equal** — in forced air the flow takes the widest channel, so unequal gaps
  starve the narrow slots.
- **Space-saving variant if slots run short:** the intake is on one face only,
  so laptops can be paired lid-to-lid with a narrow gap and bottom-cover-to-
  bottom-cover with a wide one. The flow bias then works *for* you. Costs
  simplicity; only worth it if pitch is actually tight.
- **Blank the empty slots and the end gaps.** Bypass air is usually what
  decides whether a forced-air box works — if there is an easier path from
  inlet plenum to outlet than through the laptop gaps, the air takes it and the
  machines sit in dead zones.
- **Fan sizing.** At 0.57 W/K per CFM: ~100 W of laptops + 2 spinners needs
  ~20 CFM for a 10 K bulk rise; with nit later (~250 W total) ~50 CFM. Free-air
  fan ratings collapse under the back-pressure of a loaded rack, so derate ~half
  → **2× 120 mm running slow**, not one fan at speed.
- **Cost of the vertical scheme:** fan axes become horizontal, so rotor weight
  side-loads the bearings. Blowers tolerate it; expect slightly earlier bearing
  noise over years. Applies to all orientations equally, so it did not affect
  the choice.

**Storage does NOT go in the wire rack.** This is the open part of the build.

- **Orientation spec.** 3.5" drives are rated for any of the six standard
  orientations but only within ~±5° of true. Dish drainers are usually *raked*
  by design. Out of spec, and the lean is the worst case for the next point.
- **Vibration is the real risk, not heat.** bigdisk and bigstore are consumer
  Barracudas with **no rotational-vibration sensors** — no compensation for
  being shaken by a neighbour. A springy undamped wire frame with laptop fans
  coupled into it is close to the worst shared mount. Degrades sustained
  throughput and seek accuracy; not a survival threat, but avoidable.
- **So: rigid deck, elastomer-isolated, sharing no load path with the wire
  rack.** Grommeted standoffs, or foam under a ply/ali shelf.
- **Disks low, in the inlet air; laptops above.** Laptops answer heat by
  throttling — visible, recoverable. Disks answer by dying quietly. Give the
  coldest air to the component that cannot report distress. Costs the laptops
  little (~6–9 W per spinner into the stream). Target 30–45 °C on the drives.
- **Turn the enclosures to face the flow.** IcyBox / ASM1051 / Seagate shells
  are designed as free-standing passive coolers with vents at the ends — inside
  forced air they do *better* than on a desk, but only if the box blows
  *through* them rather than across them.

**⚠ The IcyBox shuck is now a PREREQUISITE, not a parallel job** (was pending
item 3, "before/during the rack build"). Once bigstore is inside a sealed
forced-air enclosure, **drive temperature is the number you most need — and the
Seagate bridge (0bc2:2038) will not give it to you.** 1.4 TB of astro data,
SMART-blind, in a box whose thermal behaviour is unproven. Restore the
instrument before you need to read it. See [[seagate-expansion-blocks-sat]].

**⚠ OPEN ARCHITECTURE QUESTION the rack forces — decide before cutting panels.**
nit is specced with 3× 3.5" SATA and an ATX PSU; there are exactly two external
3.5" spinners. Moving them onto nit's SATA would delete in one move the USB
bridges, the wall-warts, the pending £15 powered hub **and** the SMART
blindness — precisely the interface/power/thermal failure class rackinabox
exists to fix. **But** STATE has muppet as the *archive of record*, with nit
processing and shipping to it; hanging the archive off nit inverts that —
muppet would reach its own archive over the network, and **nit stops being
disposable / casually power-cyclable**. Assessment: native SATA with real SMART
on a machine with a proper PSU is structurally better than four cheap bridges
on a shared feed, and "archive of record" can follow the disks. Peter's call.
It determines whether the build needs a disk deck for USB enclosures or drive
bays for a board, so it gates the panel work.

**Handed off 2026-08-20:** the whole mounting scheme above was mailed to the
`rackinabox` strand (orientation table, pitch/blanking/fan sizing, the
disks-out-of-the-wire-rack reasoning, and the two items that gate its panel
work — the shuck prerequisite and the nit-SATA question). rackinabox owns the
build; this section is hardware's view of it, kept here because it is where the
machine-level facts live.

**Flagged, not chased:** muppet's fan was at **3478 RPM with CPU at 61 °C**, and
puppy's at **3500 RPM**, on machines that should have been near idle. Noticed
while checking fan presence; not investigated.

## Pending / loose ends

**Priority order as of 2026-08-10** (the session that closed the migration and
solder items, so the old "disk emergency" framing is gone):

1. **nit — buy the renewal machine** (specced 2026-08-12, see below). The one
   open blocker is the **B550 block-diagram check** (M.2 ↔ SATA lane sharing);
   OS placement is still undecided. Gates rackinabox, which is now its case.
2. **rackinabox — PRIORITISED by Peter.** The *structural* fix for the interface/
   power/thermal failures this strand keeps rediscovering. Owned by the
   `rackinabox` strand; hardware's view of the coupling is in `IDEAS.md`.
   **Must be paired with the offsite subset — it is consolidation, not
   redundancy.** Now also **nit's enclosure** — the panel set needs a board
   deck, drive mounting and I/O cutout before any laser quote.
3. **IcyBox shuck (£0)** — 1.4 TB of astro data is SMART-blind. **PROMOTED
   2026-08-20 to a prerequisite of the rack build**, not a parallel job: a
   sealed forced-air box makes drive temperature the critical number, and the
   Seagate bridge cannot report it. See the 2026-08-20 mounting section above.
4. **Offsite copy of the irreplaceable subset** (R2, free egress) — waiting on
   astro-storage to size it. Mailed 2026-08-10.
5. **Powered hub (~£15)** for the tether — site it in the rack.

*Closed 2026-08-10:* 6 TB migration ✅, photodisk retired ✅, 12V solder ✅.
*Settled:* pog is a liability, and out on physical grounds (doesn't fit an
enclosure specced for laptops).

**New demand on this strand from `astro-serving` (2026-08-16).** A design
sketch (`cld-strand-astro-serving.md`, Drive 2026-08-15; now transcribed into
the `astro-serving` strand, which was scaffolded for it) proposes splitting
processing from serving — **nit** processes, a new box **tin** serves rendered
frames to browsers. Three hardware items were spooled to `ideas/` on
2026-08-15; they are **sequenced, not independent**:

1. **NAS with real parity — the prerequisite, and it does not exist.** The
   design scopes redundancy tightly and correctly: the only thing that cannot
   be lost is the *captured frames*, everything downstream being reproducible
   while the pipeline is in git. It then assumes those frames sit on a NAS with
   parity. Today they sit on **bigstore — one SMART-blind copy**. So the
   design's most protected component is in fact our least protected one. This
   is the same gap as "Redundancy is the real on-prem/cloud difference" above,
   now with a second strand depending on it.
2. **tin — a new quiet, low-power, always-on serving box.** Resident frame
   sets, modest CPU. **Do not spec or buy before the NAS decision** — the
   storage topology (does tin hold a copy, or mount from nit / the NAS?) is
   explicitly undecided there, and may make tin much thinner than imagined.
3. **nit's 64 GB ceiling — verify it is reachable.** The design says nit
   "eventually wants 64 GB". nit is deliberately AM4/DDR4 (see Decisions).
   Check the board's DIMM count, currently-populated slots, and max per slot
   before treating that as a plan: 64 GB across 2 populated slots means
   *replacing* DIMMs, not adding. Re-check the B550 M.2↔SATA lane-sharing
   blocker while the spec is open anyway.

**One constraint this strand contributed back:** the serving box belongs on the
**wired** side of the house, near the bytes — pip's 4.9 vs 34 MB/s measurement
([[compute-follows-the-data]]) means no amount of client-side bandwidth
adaptation rescues a server sitting behind a slow radio link.


- **muppet USB socket wear — one socket confirmed worn, rest verified sound
  (2026-08-10).** Found via astro-canon: the Canon EOS 2000D's escalating PTP
  wedges (0x2019 / -110) were **mechanical, not firmware** — the USB2 socket had
  gone physically loose from heavy insert/remove cycles. Moving the camera to a
  USB-C port via adapter + USB3 hub fixed it: enumerates at 480M, config write
  stuck first time. See [[eos-wedges-were-a-worn-usb-socket]].
  - **Audit done this session — the wear is CONFINED to one port.** Over 7 days
    of muppet's kernel log, **every** USB error is on **port `3-7`** (7 ×
    `device descriptor read/64, error -71`, plus "device not accepting address"
    / "not responding to setup address") and **no other port has logged a single
    error**. That is the worn socket, now vacated — the camera sits on `3-5`
    behind the Genesys hub at 480M. Leave 3-7 empty, or treat it as
    keyboard/mouse-only; do not put anything that matters on it.
  - **The disks are NOT affected — checked, clean.** Both live disks are on
    **Bus 4** (USB3), a different controller path from the worn Bus-3 socket:
    bigstore (5.5T Expansion, `0bc2:2038`, uas, 5000M) and sdc (ST31000528AS via
    ASMedia ASM1051 `174c:5106`, 5000M). No UAS resets or IO errors in 11 days
    (the only hits, Jul 27/29, are the known 6 TB inspection replug + photodisk).
    **sdc SMART: PASSED, 0 realloc / 0 pending / `UDMA_CRC_Error_Count = 0`,
    8602 POH.** Zero CRC errors is the specific negative signal for a marginal
    cable/socket — so the bigstore data risk the idea raised is real in principle
    but **not currently materialising**. bigstore itself stays SMART-blind until
    the shuck (see 6 TB runbook / [[seagate-expansion-blocks-sat]]).
  - **Standing check, cheap to repeat:** `lsusb -t` (disks must read **5000M**,
    camera **480M** — a worn path silently drops to 12M) and
    `UDMA_CRC_Error_Count` on any SMART-visible disk. Re-run when anything on
    muppet's USB misbehaves, *before* building a software theory.
  - **THE REAL COST — why this outranks its £0 part price (2026-08-10).** Judge
    this fault by consequence, not components. It cost **missed camera time on a
    rig that only works on clear nights** (unrepeatable — a lost clear night is
    gone), plus **two weeks of Peter's and Claude's time** chasing firmware
    theories that could never have found it. **astro-canon is a saga** largely
    because of this one socket. A £0 part with a very expensive, silent,
    progressive failure mode.
  - **✅ DECIDED — powered hub as sacrificial front-end.** Put a ~£15 powered hub
    in front of the tether. Two reasons, the second underrated at first: wear
    lands on a replaceable part instead of a soldered-on laptop socket; and **a
    hub fails LEGIBLY** — swappable, testable, you can watch it enumerate —
    whereas a laptop socket fails as a two-week mystery. **No shared-feed
    objection any more:** the 12V disk feed is soldered and separate, so the hub
    carries only the camera. This is what the camera de-facto has now; make it
    deliberate.
  - **Open question — is muppet the right astro tether host at all?** It's
    flagged in GLOBAL.md as "spare, difficult-to-use screen", is deliberately
    headless, and is an old laptop in daily service. Not urgent (the rig is
    healthy again), but it belongs in the new-laptop capacity thinking under
    Decisions rather than being answered on its own.
  - **DIAGNOSTIC LESSON — keep.** This presented as firmware for two weeks and
    every theory was a software theory. Two habits would have caught it: (1)
    check `lsusb -t` link speed and suspect the **physical path** before
    theorising about firmware; (2) distinguish **yield from rate** — frames/night
    stayed flat (96-135) the whole time the rig degraded because the recovery
    ladder clawed nights back, while the real damage showed in frames/**hour**
    (38-44 → 26-35) and nights starting 00:22-00:51 instead of 22:30. **Flat
    totals hid a live fault.**

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

### 6 TB migration runbook — ✅ DONE (verified 2026-08-10)

**✅ MIGRATION COMPLETE — done by astro-storage, verified live 2026-08-10.**
`/dev/sda1` is **ext4** (as decided), mounted at **`/mnt/bigstore`**, holding
**1.4 TB** in `astro-data` (+ `old_backups` 4.4 G, `old_backups2` 1018 M swept
up from the old disks), **4.2 TB free (25% used)**. **photodisk (sdb) is
RETIRED and no longer attached** — the 274-pending-sector drive is off the
machine, so the single-copy-on-a-dying-disk exposure is **closed**. bigdisk
(sdc) remains attached as XFS at `/mnt/bigdisk` + `/mnt/bigdisk2`.

**Value check (2026-08-10):** 1.4 TB on bigstore ≈ **£90/TB one-off** vs S3
Standard ≈ $32/mo (~£25) for the same 1.4 TB — pays back in ~5 months, before
egress ($0.09/GB to read the bulk back). **On-prem is the right home for astro
bulk; this disk is earning its keep.**

**⚠ STILL OPEN — the shuck.** bigstore is still behind the **Seagate Expansion
bridge (0bc2:2038)**, which firmware-blocks ATA pass-through → **1.4 TB of
astro data on a disk whose health cannot be read.** The IcyBox shuck (£0) is
the one remaining physical job on this disk. See
[[seagate-expansion-blocks-sat]].

*Historical runbook below — kept for the inspection findings and the
bridge/SMART evidence; the migration steps themselves are done.*

**Inspection findings (2026-07-27), attached to muppet over USB:**
- Presents as `sda`, **5.5 TiB**, factory-fresh: single **exFAT** data partition
  (`Expansion`) + 200 M vfat EFI partition, only **41 MB used** (Seagate
  bundleware: `Start_Here_*`, `Warranty.pdf`, `Seagate/`, `.VolumeIcon.*`) —
  **nothing of ours on it.** To be reformatted **single ext4 partition**
  (DECIDED 2026-07-27) — its role is **principal storage**, old disks become backups.
- **⚠ USB bridge blocks SMART — CONFIRMED EXHAUSTIVELY 2026-07-31.** This is the
  **Seagate Expansion enclosure** (USB id **0bc2:2038**). Live re-probe on muppet
  (5.5TB = `/dev/sda`) proved **NO** `-d` flag recovers SMART: `sat`/`sat,12`/
  `sat,16` → "unsupported field in scsi command"; `usbjmicron`/`usbsunplus`/
  `usbcypress` all fail; only `-d scsi` answers and it reports "SMART support:
  Unavailable". `-T permissive` also tested → all-blank fields, "SMART Disabled",
  zero attributes (it only tolerates a failed command, can't make the bridge
  accept ATA pass-through). So the shuck is *forced*, not merely preferred — no
  software flag exists. (Also confirmed real capacity **6.00 TB** / 6,001,175,125,504 bytes.)
  By contrast the **ASMedia ASM1051** bridge (174c:5106, now serving the 1 TB
  ST31000528AS = `/dev/sdc`, health `PASSED`, 0 realloc/pending/CRC, 8369 POH)
  passes `-d sat` fine. Device letters shuffle across replugs — identify by-id.
  See memory `seagate-expansion-blocks-sat`. **DECISION SETTLED → SHUCK** the
  drive out of the Seagate enclosure onto a spare/£6 generic ASM/JMicron bridge
  *before* committing it as primary, to restore SMART and match the rest of the
  fleet. (Peter's disks are all USB-on-cheap-bridge already, so this is the known-good
  path, not a downgrade.) Reformat/migrate is bridge-independent, so bridge swap
  can happen before or after — but confirm SMART on the *final* bridge before
  declaring it "principal". Do NOT rely on the Seagate bridge long-term.
  - **SHUCK TARGET DECIDED (2026-07-27): the ancient IcyBox enclosure passes SATA
    SMART through** → put the 5.5TB in the IcyBox = full health visibility, **£0,
    no new bridge to buy.** So the plan is: shuck out of the Seagate enclosure →
    into the IcyBox → that's the principal. Later, **once photodisk (sdb) is
    shelved**, its freed generic adapter can host the 5.5TB if the IcyBox is
    wanted back; interchangeable. Net: never blind, nothing bought. (This settles
    the "shuck vs Seagate-bridge" question — answer is shuck-into-IcyBox.)
- Note the earlier runbook assumed a mains-brick 3.5" desktop drive; as delivered
  it enumerates as a bus-powered-style Expansion. Still: give it its **own** power
  feed, never the shared USB feed that caused the 2026-07-15 fault.

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
   couldn't be read. This sweeps up starcam 05-21 (40G). **SKIP eclipticam
   `day/` (21G)** — DECIDED 2026-07-26: abandoned moon-tracking frames (Peter
   switched to Altair), not worth the read-wear on a dying disk. ddrescue
   file-by-file / exclude that path, or just don't copy it back on reload.
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


- **muppet shared-power fault — ✅ SOLDER DONE (2026-08-10). CLOSED.** The 12V
  power feed **is now soldered** (solder + heatshrink, per the Decisions rule —
  not Wago). This was the root cause of the 2026-07-15 event and it is fixed;
  the lesson is learnt and codified. Consequence for the powered-hub question
  above: **the disks have their own soldered 12V feed**, so a hub would carry
  only the camera and reintroduces **no** shared-feed risk. History below kept
  for the failure signature.
  The 2026-07-15
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

- **muppet's condition: INTERFACES worn, compute/storage HEALTHY (2026-08-10).**
  Measured this session, against a "muppet is worn out, only worth £100"
  hypothesis — the evidence **does not support** retiring the machine:
  - Internal NVMe (SKHynix 256G): **Power On Hours 31,601** (~3.6 yr), **134
    power cycles**, **Percentage Used 2%**, Available Spare 100%, 24.7 TB
    written. Decades of write endurance left. *(Caveat: this is the drive's
    hours; it would carry over if the NVMe were ever moved between machines —
    134 cycles for a mostly-on laptop makes it plausible as muppet's own.)*
  - **Unsafe Shutdowns 56 of 134 — but all HISTORIC.** Last shutdown was
    textbook clean (`Syncing filesystems` → SIGTERM → `poweroff.target` →
    journal stopped in order). The XFS recoveries at 2026-07-15 19:07 were the
    *external* sdc disks replaying after the power event — **host clean,
    external disks dirty**, which is exactly the distinction that matters.
  - Uptime 24 days; **zero sleep/hibernate events in 7 days**;
    `mem_sleep=[s2idle]` only (no `deep`), `HibernateDelaySec=60` — harmless on
    an always-on headless box, but the hibernate path is effectively untested
    here. **Keyboard is in good condition.**
  - **Conclusion: muppet's failures are exclusively at the PHYSICAL INTERFACES**
    — USB socket (worn), backlight (dead half, won't-fix), power feed (now
    soldered). Not the silicon, not the storage, not the software discipline.
  - **The operative judgement is not "worn out" but "past the point where its
    interfaces can be trusted with something that must not fail silently."**
    The astro tether is exactly such a thing. So: keep muppet as headless
    NFS/compute (a role needing neither screen nor pristine sockets), but stop
    letting it be a **single silent point of failure** for time-critical
    capture — hence the powered hub, and the open host question above.
- **Spend priority follows from the above (2026-08-10).** The fleet's real gap
  is **no longer capacity or storage** — bigstore is migrated and earning
  £90/TB, photodisk is retired, the solder is done. Remaining, cheapest first:
  **(1) the IcyBox shuck (£0)** — 1.4 TB currently SMART-blind; **(2) powered
  hub (~£15)**; **(3) durability** — bigstore is a **single copy** of 1.4 TB,
  and that, not capacity, is the genuine cloud case. If taken: **Cloudflare R2**
  ($0.015/GB-mo, **egress free** ≈ $21/mo for 1.4 TB) over **S3** ($0.09/GB
  egress makes read-back punitive). Whether it's worth it depends on how much
  of the 1.4 TB is reproducible vs irreplaceable — **astro-storage's call.**
  New-laptop thinking is unchanged and stays non-urgent (see below).
- **REDUNDANCY IS THE REAL ON-PREM/CLOUD DIFFERENCE — and we currently have
  NONE (2026-08-10, Peter's framing).** The £90/TB comparison above prices
  **capacity**, where on-prem wins outright. It does **not** price
  **durability**, where the two aren't comparable: S3 is 11 nines across three
  AZs; **bigstore is one disk, one bridge, one USB socket, one house.** Peter's
  position stated plainly: *can't achieve AWS levels, but currently has no
  redundancy at all.* Three distinct exposures, only one of which is about the
  disk:
  1. **Single copy of 1.4 TB.** photodisk's retirement took the duplicated
     nights with it; `old_backups*` on bigstore are only 5.4 G — not a second
     copy of anything meaningful.
  2. **SMART-blind** behind the Seagate bridge → **no early warning.** photodisk
     gave weeks of notice via pending-sector creep; bigstore would give none.
     First symptom = data loss.
  3. **Correlated failure** — one host, one feed, one room. Theft/flood/fire
     takes everything regardless of disk health.
  - **Do NOT reflexively buy a second 6 TB disk.** A second disk on the same
    machine addresses only (1) — now the *least* likely failure, with photodisk
    gone and the 12V soldered — costs ~£200, and does nothing for (2) or (3).
  - **The goal is not AWS parity; it is to stop being at ONE.** Two cheap moves
    cover most of the gap: **the shuck (£0)** restores the *warning time*
    (fixes 2), and **an offsite copy of the irreplaceable SUBSET** fixes (1)
    and (3) together. Full 1.4 TB on R2 ≈ $21/mo, but if the keeper subset is
    ~200 G that is **~$3/mo** for geographic redundancy — a different
    proposition entirely. **Sizing that subset (irreplaceable vs reproducible
    vs superseded) is astro-storage's call; hardware owns stating the
    exposure.**
- **muppet's dim screen: WON'T FIX — flogging a dead horse (2026-07-22).**
  Symptom is dim, worse on the *left-hand side* → classic backlight/LED-driver
  (edge-lit panel not propagating light across), not GPU (no artefacts) and not
  software. Realistic fix = whole panel-assembly swap on an X13 Gen 2i
  (cheap-ish part, fiddly job). But muppet is **deliberately headless** (NFS/
  compute, driven over SSH) — a working screen adds nothing to its role. Decision
  stands: leave it headless, don't diagnose or swap the panel.
- **Fleet ceiling is RAM, not cores (2026-07-22).** *(Amended 2026-08-10: **pog**
  — HP Elite 8300 SFF — has **20 GiB**, nearly 3× this ceiling. It does NOT
  change the conclusion: pog is incomplete (SSD in eclipticam), off-LAN, Ivy
  Bridge, and ~30-50 W idle. Real capacity exists in a cupboard but is not
  usable capacity — see "What exists".)* All three x86 boxes sit at
  ~7.5 GiB: pip (i5-8265U Whiskey Lake — the fleet's *slowest* CPU), muppet
  (8-core Tiger Lake), puppy (i5-1135G7 Tiger Lake, fastest clock). So demoting
  pip to a compute node buys little (weakest CPU; muppet+puppy already cover
  compute). If Peter buys a new laptop, it becomes the daily driver; pip's best
  second life is bench/spare, not compute. Don't buy dedicated compute unless a
  specific workload is CPU-starved — current astro/OpenSearch pressure is
  disk/retention, not CPU.
- **New laptop = non-urgent shopping quest, driven by future capacity
  (2026-07-22).** ***SUPERSEDED 2026-08-13 — the prediction came true and the
  answer is NOT a laptop. See "Duty-cycle tiering" below.*** Not a fix-it-now:
  fallback if pip pops is already covered (phone + keyboard, or another host +
  monitor). The forward driver is that **muppet and puppy WILL get overloaded**
  at some stage — so the eventual buy should add a genuinely capable third x86
  node: **more than 8 GiB RAM** (the standing fleet ceiling) and a CPU newer
  than pip's, not a like-for-like pip replacement. It becomes daily driver; pip
  drops to bench/spare fallback.
  *(What it got right: overload was the forward driver, and RAM was the ceiling.
  What it got wrong: it was still shopping for a **laptop**, which the puppy
  thermal-halt evidence disproves — the workload cooks laptop chassis
  regardless of silicon. nit is a desktop, and it is dedicated compute, which
  this entry also advised against.)*

- **DUTY-CYCLE TIERING — the fleet's organising principle (2026-08-13).**
  Peter: *"I want pog then nit to take over the high power stuff and
  muppet/puppy to do redundant 2nd tier storage."*

  | Tier | Machines | Duty |
  |---|---|---|
  | High-power compute | **pog** (stand-in) → **nit** | crunching; hot, mains, real cooling |
  | 2nd-tier redundant storage | **muppet + puppy** | low-duty IO, cool — **plus OpenSearch data nodes** |
  | Cluster tiebreaker | **vole** | voting-only, no data (Acer C720) |
  | Home services | **homepi** | Home Assistant + Tailscale exit node |

  **⚠ muppet and puppy are NOT idle in this scheme — they are the OpenSearch
  cluster** (with **vole** as the voting-only tiebreaker it was bought to be —
  quorum 2/3, cluster stays writable through any single-node outage). So "2nd
  tier storage" means *storage + a live database role*, not a cool parking
  space. Two consequences:
  - **Their thermal budget is not free.** OpenSearch is a JVM with a resident
    heap and background merge/indexing IO — real, if bursty, load. Moving the
    astro crunch off them is still a large reduction, but it does **not** take
    them to idle, and puppy's lid-closed halt is a cluster-availability event,
    not just a lost file server.
  - **Storage redundancy and cluster redundancy ride the same two machines.**
    Losing muppet or puppy costs a data copy *and* an OpenSearch data node at
    once — correlated, not independent. Worth remembering when sizing the
    offsite subset, which is the only copy not on this pair.

  **The evidence this is built on — two machines, ONE CPU, both cooked.**
  puppy (ASUS VivoBook X515EA) and muppet (ThinkPad X13 Gen 2i) both run
  the **same i5-1135G7**. So the fleet's compute problem was never silicon
  speed — it is that a 28 W laptop part in a laptop chassis cannot hold a
  sustained load:
  - **puppy: THERMAL HALT, not throttling.** With the **lid closed on hot
    days** it would **suddenly halt** — firmware cutting power at critical, not
    slowing down. Lid-closed blocks the keyboard-deck airflow path these thin
    chassis rely on. For a box NFS-exporting live camera frames that is an
    **outage**, not a slowdown. puppy was effectively *disqualified* from the
    heavy work; the load did not migrate to muppet by choice.
  - **muppet is the last laptop standing** under that load, and was measured at
    **80 °C during astro processing on a hot August day** (2026-08-13). There is
    no third laptop behind it.

  **Consequences that correct earlier reasoning in this file:**
  - **nit's case is DUTY-CYCLE CORRECTION first, performance second.** It is not
    replacing a slow machine — it replaces an *appropriately fast machine in the
    wrong package*. (nit ≈ **2.3×** muppet/puppy multi-core, and more like ~3×
    on hour-long work once their throttling is counted; but the reason to buy is
    that laptops keep halting, not the multiple.)
  - **Two laptops as redundant storage is a FEATURE, and it retires an earlier
    objection.** This file previously argued nit should take the archive because
    muppet's disks are USB-bridged and SMART-blind. Peter's scheme is stronger:
    two *independent machines* each holding a copy is what
    [[redundancy-not-capacity]] actually asks for ("stop being at one").
    **Redundancy beats observability here** — the SMART-blindness objection is
    withdrawn as a reason to move the archive.
  - **It puts muppet and puppy on a duty cycle they can survive.** Serving files
    is bursty and cool. Their 2%-worn NVMe and clean shutdown record
    ([[muppet-interfaces-worn-not-silicon]]) say the silicon has years left *if
    the load is right*. This also answers the standing open question "is muppet
    the right astro tether host?" from the other end: not the wrong host, the
    **wrong load**.
  - **⚠ NEW single point of compute.** nit (and pog before it) becomes the only
    machine that crunches — today muppet at least limps. Acceptable (a compute
    outage delays work; a storage outage loses data) but be deliberate: **keep
    pog alive as a warm spare after nit arrives**, which reverses the "retire
    pog when nit is bought" condition floated earlier.
  - **The rack now holds only the hot machine.** muppet and puppy stay *outside*
    the enclosure as storage, so its thermal problem is one 65 W CPU + disks,
    not three laptops + a server — and the shelf-height question stops being
    about laid-flat laptops at all.
  - **⚠ Do not repeat the mistake a third time.** Two chassis have now failed
    this workload thermally. Putting a 65 W desktop CPU + 3 spinning disks into
    a sealed cast-walled box whose fan was specced for *three idle laptops* is
    the same error again. **The rackinabox thermal re-derivation is now the
    highest-risk open item in either strand.**
  - **It argues for buying sooner.** Every hot night spends muppet's remaining
    life on a job nit should be doing — a real cost against "wait for DRAM
    prices to ease by 2027".
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
