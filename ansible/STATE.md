# ansible — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- Strand scaffolded 2026-07-20. Mission: apply & maintain config across the
  fleet (edit `~/ansible`, roll out, verify). See CLAUDE.md.
- **aifabric + strands provisioned across laptop-class hosts** (2026-07-22,
  commit `280ee14` in `~/ansible`, pushed + rolled out). Handed over from the
  super-to-aifabric strand (see FORKTERM-BRIEFING.md). `git-repos` role clones
  `aifabric` + `strands` on laptop-class hosts only (pip, muppet, puppy, vole)
  — never fleet-wide. Two new role tasks: `trust_github.yml` (seed github.com
  into known_hosts) and `link_strands.yml` (symlink `super/strands -> strands`,
  since it's gitignored in super — guarded to refuse clobbering a real dir).
  **Rolled out & verified on all four hosts:**
  - muppet, puppy: stale super checkout (tracked `strands/` as real files) was
    migrated cleanly — the super pull removed the 175 tracked files, then the
    symlink landed. NFS + skycam undisturbed.
  - vole: first-ever private clone. Two blockers found & fixed — empty
    known_hosts (fixed by `trust_github.yml`) and **no fleet SSH key** (vole
    had no `~/.ssh/id_ed25519`; copied the shared fleet key
    `SHA256:CvosCos…peter@muppet` from pip, mode 600). vole never had super
    cloned before this either — now has super+aifabric+strands.
  - pip was already hand-provisioned to the same end-state.
  - Every host: `super/strands` symlink resolves, 0 strands files tracked in
    super, tooling reads through the link.
  - **Follow-up (hardware/vole):** vole's SSH key was placed by hand, not
    ansible-managed — same as the rest of the fleet (the shared key isn't in
    ansible; only `authorized_keys` is, via the `users` role). If fleet key
    distribution ever gets automated, vole should be included.

## Pending / loose ends

- **aifabric+strands rollout: DONE** (see What exists). Unblocks the
  super-to-aifabric strand's PATH-flip (`~/aifabric/bin` before `super/bin`) —
  mailboxed 2026-07-22.

- **bigstore 'bs' NFS export/mount: DONE + ROLLED OUT + VERIFIED** (2026-07-29
  with Peter). `bs` = `/mnt/bigstore` on **muppet** (5.5T, the principal live
  astro store). Export the astro subtree `/mnt/bigstore/astro-data`
  (rw,**sync**,all_squash→peter); mounted at `/mnt/muppet/bigstore` on
  **eclipticam + puppy** (the end-of-night sync writers) and **pip** (browse).
  eclipticam + puppy were NFS *servers* only — both now also NFS *clients*.
  - **Options doctrine — resilience over speed** (Peter's steer: muppet
    maintenance must never force a fleet reboot again; write speed not
    critical). **Soft automounts** + **sync** export, not hard/async: a hard
    mount would wedge clients in D-state when muppet drops; soft fails EIO
    instead. The astro-storage sync must tolerate the odd EIO and retry next
    night.
  - **Verified on all four hosts**: real NFS4 mounts confirmed via `findmnt`,
    real writes land on the export (write+cleanup OK on all three clients),
    muppet + eclipticam own exports still active, eclipticam **live capture
    undisturbed** (astro-state/process + v3w-uploader + capture.timer all fine).
  - **Three rollout findings, all handled:**
    1. **puppy uses the IP `192.168.0.10:`, not `muppet.local`** — puppy's mDNS
       resolves `muppet.local` to a flaky link-local IPv6 (the astro-storage
       trap); matched its existing working osd-snapshots mount. eclipticam+pip
       use the hostname (they resolve IPv4 cleanly).
    2. **A fresh `x-systemd.automount` fstab line doesn't mount until its
       `.automount` unit is started** — the role's `daemon-reload` regenerates
       the unit but doesn't start it, so the first write hit the *local*
       mountpoint dir (false-positive "WRITE OK"). Caught via `findmnt`, cleaned
       the stray local file, `systemctl start`ed each automount. Now durable —
       the fstab entries auto-start on reboot too.
    3. **Fixed a real `nfs-server` role bug**: the generator-mask task symlinked
       into `/etc/systemd/system-generators/`, which doesn't exist on a host
       that never had a local generator override (failed on eclipticam; muppet
       had it by luck). Added a task to ensure that dir first — mask is now
       portable. Re-applied eclipticam cleanly.
  - **Seam**: the *dynamic* sync half (write the night onto this mount) is in
    the **astro-storage** strand's inbox — now unblocked, this mount exists.
  - **Pre-existing drift surfaced, NOT yet fixed**: muppet's `exportfs -ra`
    handler now reports `failed=1` because the retired
    `/home/peter/starcam-backup` export line points at a dir deleted from disk.
    Harmless (bigstore export landed fine; role tolerates missing dirs at
    runtime) but every future `--tags nfs` run on muppet flags failed until the
    stale line is dropped from `muppet.yml`. Candidate for the drift sweep.

Standing / not-yet-scheduled items (were in IDEAS.md, promoted 2026-07-29):
- **pi-fleet reporter cadence 1→5 min + immediate-on-boot** (decided 2026-07-20,
  whole-fleet). Set `OnUnitActiveSec=5min`/`OnBootSec=0` in the timer; confirm
  whether ansible deploys the committed `pi-fleet-status.timer` or its own.
  **Lockstep**: widen the Lambda offline threshold (`pi-fleet/lambda-handler.py`)
  to ≈2–3× or hosts flap offline between reports. Roll out in waves.
- **Add vole as a first-class fleet member**: reporter must degrade cleanly on a
  non-Pi host (`HOSTNAME.replace('pi-','')` + `mmcblk0` SD assumptions break on
  vole). Decide board appearance with pifleet. This is where the pi-→fleet
  rename debt naturally surfaces — do it here if the reporter needs surgery.
- **pi-fleet → fleet rename**: tech debt, ride-along only, never standalone
  (naming is load-bearing in code/units/env/Lambda path; live-capture blast
  radius, zero new capability).
- **General fleet-maintenance catch-up** (drift sweep): sweep `~/ansible` for
  config drift / half-applied roles. Known seeds: vim-default-editor pending on
  starcam/deskpi/xoverpi; astrocam sudo broken (super memory).
- **Recurring maintenance schedule** (idea, 2026-07-22): stand up a cadence for
  the drift sweep (scheduled `/loop` or cron routine) rather than ad-hoc.
  Decide interval + form with Peter; ties into the drift-watch role.

## Decisions

- **Seam with pifleet** (2026-07-20): pifleet owns *membership + dashboard
  liveness*; this strand owns *making changes stick on hosts*. pifleet decides
  what the fleet should look like; ansible implements & rolls it out.
- **Cadence** (2026-07-20, with Peter): whole-fleet 5 min + `OnBootSec=0`, not
  a per-host vole override. Requires an ansible re-deploy and a lockstep Lambda
  threshold change.
- **bs mounts favour maintenance-resilience over throughput** (2026-07-29, with
  Peter): all bigstore NFS mounts stay **soft** and the export **sync**, not
  hard/async. Rationale: muppet maintenance previously forced a fleet-wide
  reboot; a hard mount hangs clients in D-state when the server drops, soft
  fails EIO instead. Write speed is explicitly not a priority. Consumers (the
  end-of-night sync) must retry-next-night on EIO.
