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

- **SMB share on muppet for the Chromebook: DONE + VERIFIED** (2026-08-16,
  commit `c7b55e3` in `~/ansible`, pushed). Peter is getting a Chromebook, and
  **ChromeOS has no NFS client** — its Files app speaks SMB only — so muppet's
  astro store is published a second way. New `samba-server` role, wired into
  `site.yml` behind `enable_samba_server`, live on muppet.
  - **Share is `/mnt/bigstore/astro-data` only** (as `\\muppet.local\astro`,
    rw), NOT the whole of bigstore or bigdisk. Peter's call: the NFS exports of
    those whole disks expose personal dirs (audio/, Backup/, images/) and the
    Chromebook has no reason to see them. This is the narrower of the two
    postures now live on muppet.
  - **Deliberately mirrors the nfs-server doctrine**: LAN-only
    (`hosts allow 192.168.0.0/24` + `bind interfaces only`), and
    `force user/group = peter` so an SMB write is indistinguishable on disk
    from an NFS `all_squash` write. Verified: files land `peter:peter` 0664.
  - Hardening: SMB1 off (min protocol SMB2 — ChromeOS/macOS/Windows all refuse
    SMB1 anyway), `nmbd` disabled (mDNS/DNS resolve the fleet; NetBIOS is just a
    broadcast listener), `map to guest = never`, smb.conf rendered under
    `testparm` validate. Missing share paths *warn* rather than being served as
    an empty writable dir — bigstore is a USB disk, the same failure mode the
    nfs-server generator mask guards against.
  - **Password is in secrets at `/samba/muppet-peter`** (hint added, `super`
    commit `04235e0`). Non-obvious: samba keeps its **own** password database
    via `smbpasswd`, so this is NOT muppet's login password. The role only
    creates the account when absent, so rotation needs
    `sudo smbpasswd -x peter` on muppet first. Passed at run time:
    `-e "samba_password=$(secrets get /samba/muppet-peter)"` — never in the repo.
  - **Verified from pip with smbclient**: browse, read, write, delete all work;
    wrong password → `NT_STATUS_LOGON_FAILURE`, anonymous → `ACCESS_DENIED` at
    tree connect, SMB1 → refused at negotiation.
  - **Not yet done — the Chromebook itself.** The hardware hasn't arrived. When
    it does: Files app → Add SMB file share → `\\muppet.local\astro`, user
    `peter`, password via `secrets copy /samba/muppet-peter` (copy, don't print).
    If `muppet.local` doesn't resolve on ChromeOS, fall back to `\\192.168.0.10\astro`
    (muppet's pinned static). Untested against real ChromeOS until then.
  - **Android/VLC (2026-08-16, same day).** VLC for Android speaks SMB and works
    on the home LAN — server `192.168.0.10` (the IP, NOT `muppet.local`:
    Android mDNS is patchy and VLC's share dialog often won't resolve `.local`),
    user `peter`, share `astro`. **Away from home does NOT work and won't
    without a decision**: muppet is not on Tailscale (no `100.x`, tailscaled not
    even installed), and `interfaces`/`hosts allow` are LAN-only by design.
    Adding it = install tailscale on muppet + add `tailscale0` to BOTH lists;
    deliberately not done unasked, it widens exposure. (Aside: pixel-6a has been
    offline on the tailnet 9+ days.)
  - **Password changed to a 4-word passphrase** (~55 bits, 27 chars) because the
    24-char random string was unthumbable on a phone keyboard and VLC gives no
    useful error on mistype. Rotation exercised the documented footgun for real:
    the role only creates the account when absent, so it needed
    `sudo smbpasswd -x peter` on muppet FIRST, then a re-run. Verified new works
    / old gives LOGON_FAILURE.
  - **`secrets copy` HANGS on pip** — blocked past a 120s timeout, so the
    clipboard path is broken here, not just awkward for a phone. Notable because
    `secrets hints` recommends `secrets copy` for exactly this
    phone/web-login case. Worked around by writing the value to `~/z` (mode
    600) for hand-copying; that file should be `trash`ed once the phone is
    connected — secrets holds the authoritative copy. **Root cause not
    investigated** — likely a clipboard-manager block under X11; worth a look
    since it silently breaks the documented workflow.
  - **Two real bugs found + fixed** while checking the phone question
    (commit `b1ce3cf`): (1) the template *commented* that `bind interfaces only`
    enforced LAN-only but **never emitted the directive** — smbd was on
    `0.0.0.0:445`, docker0 included, with `hosts allow` the only gate; (2) the
    handler **reloaded** smbd, which re-reads smb.conf but does **not re-bind
    sockets**, so the fix showed in `testparm` while `ss` still had the old
    bind — a network-exposure change silently not applying. Handler is now a
    restart. Verified `ss`: `0.0.0.0:445` → `127.0.0.1` + `192.168.0.10` only.
    Lesson worth keeping: **for samba, verify with `ss`, not `testparm`** —
    testparm shows intent, ss shows reality.
  - **NB `super` was pushed on branch `cdf-astro-nav`, not main** — that branch
    was already checked out with unrelated unmerged work. The secrets hint rides
    along on it; needs merging to main with the rest of that branch.

## Pending / loose ends

- **puppy `/etc/default/astro-process` cleanup** (low prio, from astro-storage
  mail 2026-08-03): the file still names `CAMERAS='--camera astrocam'`, stale
  from before the bigdisk→bigstore cutover. astrocam stage-1+3 now runs on
  muppet; puppy's astro-process/astro-state services are INACTIVE (only
  astro-latest-links.timer runs), so it's a dormant artifact, not a live
  conflict — but it violates the one-host rule on paper. Next time we touch
  puppy config, clear `astrocam` from its `/etc/default/astro-process` (no
  astro-state default file there).

- **Fleet git-repos divergence sweep: DONE** (2026-08-03, prompted by
  housekeeping mail; results corrected after housekeeping VERIFY caught an
  over-optimistic first report). Ran the `git-repos` role across all 7 reachable
  hosts to clear the BEHIND-clone backlog. `safe_pull` stashed dirty trees
  (grep-able `ansible-auto <iso>`, recoverable on-host); no true ahead+behind
  divergence anywhere. Skipped offline: deskpi, xoverpi, starcam. Final state,
  re-verified vs origin after fetch: muppet, puppy, vole, eclipticam, astrocam,
  cloudcam(Berrylands), homepi all `## main` clean.
  - **homepi was a real MISS in the first pass** (role reported changed=1 /
    failed=0 but super stayed behind 103, Berrylands behind 241, **busclock
    behind 26**). Root cause is a genuine config bug — see the drift-sweep item
    below. Fixed for now by hand `pull --ff-only` of all three homepi repos (all
    → `## main` clean); the structural fix is pending (needs Peter, edits
    inventory/user). busclock isn't in the ignored group_vars either — another
    hand-cloned homepi repo, not role-managed anywhere — but synced regardless.
  - **housekeeping's other flags were false alarms** (confirmed by them): puppy
    astro + muppet Berrylands are present-but-unmanaged (not in those hosts'
    git_repos), correctly untouched — same category as cloudcam super. Net
    genuine misses across the whole sweep = homepi's three repos only.
  - **eclipticam astro restored to main**: was on deprecated `moon-net-marking`
    (ahead 41, dirty 2). Role stashed the 2 files (`ansible-auto 2026-08-03T14:26:32Z`,
    labelled "On moon-net-marking") and checked out main. The dead branch is
    **left on-host** for manual delete (Peter agreed to drop it).
  - **cloudcam drift found + fixed**: first run FAILED on git *dubious-ownership*
    — `/home/peter/ansible` was `root:root` (an old root-made clone), but the
    role runs git as `peter`. Tree was clean on main, so `sudo chown -R
    peter:peter /home/peter/ansible` on cloudcam; re-ran clean. (Its other repos
    super/dotfiles were already `peter:peter`. Note cloudcam's `peter` is **uid
    1001**, an old hand-made account, and it has no strands clone.)
  - **astrocam run needed the peter override**: pi-sudo still broken (below), so
    ran with `-e ansible_user=peter` (peter has NOPASSWD there) — 3 changed OK.
    Its `dotfiles` (behind 11, dirty) is deliberately NOT in astrocam's
    git_repos — capture Pis omit dotfiles (stow symlinks read dirty). Expected.
  - **cloudcam super(behind 159)/dotfiles(behind 11) are NOT sweep misses**:
    cloudcam's `host_vars/cloudcam.yml` overrides git_repos to **Berrylands
    only** (Pi Zero 2 W, 362 MB). super/dotfiles are present-but-unmanaged, so
    the role never touches them. Whether cloudcam *should* manage super is a
    Peter call, not a bug.

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
  - **astrocam added as the 3rd bs writer — DONE + LIVE + VERIFIED**
    (2026-07-30, with Peter, urgent). astrocam swapped to IMX708/v3 on 07-29
    and had to come off the 97%-full bigdisk. Repointed `~/astrocam-frames`
    from `192.168.0.10:/mnt/bigdisk/astrocam-frames` to
    `muppet.local:/mnt/bigstore/astro-data/astrocam-frames` (fleet-default
    soft automount), replacing the `configure-sd-card.sh` fstab line. New
    `inventory/host_vars/astrocam.yml` is the durable record.
    - **Corrected the mailbox's model of the write path**: the live NFS
      writer is **`astrocam-v3-uploader.service`** (drains a tmpfs
      `/var/lib/astrocam-buffer` to the NFS night tree), NOT
      `astrocam-capture.service` (disabled/legacy). Night capture is
      sun-gated by `astrocam-v3-gate.timer`. So there *is* local staging
      (tmpfs) — the mailbox's "no staging, capture writes direct" was stale.
    - **Rolled out in the daytime gate-idle window** (sun_alt=40, tmpfs
      empty): stop uploader → umount bigdisk → rewrite fstab → daemon-reload
      → start automount → restart uploader. Verified: `findmnt` = bigstore
      nfs4 source, `df` = 5.5T/21%/4.3T free (off the 97% bigdisk), uploader
      drains cleanly, gate resolves the mount, reboot-safe (automount from
      `_netdev`). Migrated history (→07-27) visible on bigstore. fstab backed
      up to `/etc/fstab.bak-20260730-095824`. Pinged astro-storage to confirm
      tonight's v3 frames land + do the capture.py header fixes.
    - **KEY CAVEAT — ansible can't manage astrocam**: the `pi` user's sudo is
      broken on astrocam (prompts for a password; `ansible.cfg` sets
      `become_ask_pass=False`), so any `--limit astrocam` run fails at the
      first `become`. The `peter` user *does* have passwordless sudo, so this
      swap was done by hand as peter. **Fixing pi-sudo on astrocam is now a
      real drift-sweep item** (was a super-memory note; now confirmed + blocks
      ansible ownership of the host).
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
- **BUG: `group_vars/homepi.yml` is misfiled — needs Peter** (found 2026-08-03).
  `inventory/group_vars/homepi.yml` (100 lines: git_repos, `ansible_user: pi`,
  `pi_packages`, `users`, `dotfiles_*`) is **silently ignored** — there is no
  `[homepi]` inventory GROUP; homepi is a HOST in `[stationary]`. group_vars are
  keyed by group name, so none of it loads. Proof: `ansible homepi -m debug -a
  var=git_repos` → *undefined*. Consequence caught this session: homepi's
  super/Berrylands never sync (only `git_repos_global`/ansible does). Also note
  it would set `ansible_user: pi`, but homepi actually connects as `peter` (from
  the inventory host line) — so the ignored file's intent and the live behaviour
  already disagree. **Fix**: merge `group_vars/homepi.yml` into the existing
  `host_vars/homepi.yml` (they overlap on `enable_pi_fleet`; the group one also
  flips ansible_user + enables aws/gh roles + packages — real blast radius, so a
  human should do the merge and re-apply, not an autonomous run). Repos synced by
  hand for now.
- **General fleet-maintenance catch-up** (drift sweep): sweep `~/ansible` for
  config drift / half-applied roles. Known seeds: vim-default-editor pending on
  starcam/deskpi/xoverpi; **astrocam `pi`-user sudo broken — reconfirmed
  2026-08-03 (git-repos sweep needed `-e ansible_user=peter` to run; `become` as
  `pi` fails, `peter` NOPASSWD works). Fix so `pi` gets passwordless sudo like
  the rest of the fleet.** cloudcam `/home/peter/ansible` root-ownership was
  found + fixed during the 08-03 sweep (chown'd to peter:peter) — watch for
  other root-made clones on the fleet.
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
