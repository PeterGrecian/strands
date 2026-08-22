# ansible — state

*Curated summary of where this strand is. Updated at the end of each session.*

**Status (2026-08-22): vole now has single-address wired/WiFi failover, and it
is ansible-managed.** The reachable fleet is converged and rclone works.
muppet, puppy, pip, zog, vole and eclipticam all run upstream rclone 1.75.0 on
Peter's own OAuth client (`drive.file`), verified against Drive with no
retirement notice. The six offline Pis pick the role up on their next converge.

## What exists

- **vole: single-address wired/WiFi failover on `bond0`** (2026-08-22,
  `~/ansible`, `network` role). vole's `.9` now lives on an ifupdown
  active-backup bond rather than on a physical link, so it survives either link
  dying without ever appearing twice on the subnet. This was the
  "prefer wired, fall back to WiFi, same IP" item; Peter's call was to scope it
  to vole rather than do the whole fleet, because vole is the only host where
  the same-address constraint is hard (its `.9` is pinned in the OpenSearch
  compose `network.publish_host` + published ports, the other nodes'
  `discovery.seed_hosts`, and the shared node cert SANs).

  What it took, and the three things that would bite anyone repeating it:
  - **The old dongle was junk, not misconfigured.** STATE.md previously recorded
    it as "enumerated, PHY has link, never brought up — pure config gap,
    hardware fine". That was wrong. The Naxiang/SZNX `35b5:3510` (a fake-gigabit
    unit) bound to **usb-storage**, exposed no netdev at all, and reset every
    ~20s. Peter binned it. The replacement `35b5:3500` binds `cdc_ether`
    correctly → `enxec9a0c13dad6`, 100 Mbps. Only then was there anything to
    bond.
  - **`fail_over_mac=active` is mandatory with a WiFi slave.** An 802.11 station
    cannot accept frames for a MAC other than the one that associated, so the
    bond must adopt the active slave's MAC instead of imposing its own.
  - **ifupdown silently skips `wpa-` options on a bond slave.** The first
    cutover produced a bond that looked healthy but whose WiFi slave was
    `NO-CARRIER` / "Not connected" — a dead backup that only shows up when you
    need it. Association is now owned by `wpa_supplicant@wlp1s0.service`.
    Related: `bond-primary` in the `bond0` stanza is applied before any slave
    exists and is silently rejected (`Primary Slave: None`); it is set from the
    primary slave's own `post-up` instead.

  **Failover verified, not assumed** (2026-08-22): downing ethernet moved the
  active slave to `wlp1s0` with `.9` intact, the gateway reachable, and
  OpenSearch still answering on `.9` (HTTP 401 = up, wants auth); restoring
  ethernet reclaimed it via `primary_reselect always`. **OpenSearch never
  restarted** — the `docker-proxy` sockets bound to `192.168.0.9:9200/9300`
  survived the address moving between interfaces, so the container has been up
  4 weeks throughout.

  Codified as `network_bond_*` in `roles/network` (`bond.yml` +
  `templates/interfaces-bond.j2`), enabled in `host_vars/vole.yml`. Second
  converge is `changed=0`. Two deliberate choices in the role: **no handler
  restarts networking** (tearing down the bond is exactly how you strand a
  headless host — changes land on disk and take effect at reboot or a manual
  cutover), and **the PSK is not in git** (the task is skipped unless a hashed
  psk is passed via `--extra-vars`, needed only on a rebuild).

- **zog onboarded; fleet SSH keys made declarative** (2026-08-18, `~/ansible`
  `21fd607`, pushed). zog is a new ChromeOS crostini laptop (Debian 13, arm64,
  hostname `penguin`). Onboarding it by hand exposed that adding a machine meant
  N manual `ssh-copy-id` runs and a chicken-and-egg on the GitHub key. Four
  changes:
  - **`fleet_authorized_keys`** in `group_vars/all.yml` + additive
    `ansible.posix.authorized_key` tasks in `roles/users`. One entry per machine;
    applied to muppet, puppy, vole and verified idempotent (second run
    `changed=0`). Deliberately **not** gated on `users`, which laptops never
    define. Note the module will not prune a key merely deleted from the list —
    revocation goes through **`fleet_revoked_keys`** (`state: absent`).
  - **`bootstrap.sh` pulls over HTTPS** with the gh credential helper instead of
    `git@github.com:`, so `gh auth login` (browser, no key) is the only human
    step on a fresh machine.
  - **muppet/puppy addressed by static IP.** `.local` does not resolve from
    crostini (no mDNS resolver), so the statics are pinned like vole already was.
    vole added to `network_hosts_entries`.
  - **`tailscale` role added**, wired into site.yml but **off everywhere** —
    needs `enable_tailscale` plus an auth key at runtime. Motivated by zog being
    NAT'd behind ChromeOS on `100.115.92.x`: it can dial out to the LAN, but
    nothing on the LAN can dial in. Undecided, deliberately.
  - `host_vars/zog.yml` trims the laptops profile to what a container can own
    (no xfce/tlp/power, no docker/smartmontools/powertop).
- **zog now calls itself zog** (2026-08-19, `~/ansible` `9ce87c7`, pushed).
  ChromeOS names every crostini container `penguin`, so zog had never been told
  what machine it is — and tools stamp the *kernel* name, not the inventory
  name. osd-ingest had already been patched round it with `OSD_HOST=zog`;
  `alert` (`hostname -s`) was the next to bite. Pinned once in the `network`
  role rather than seam by seam: `network_hostname_manage` /
  `network_hostname` (defaults to `inventory_hostname`) / `network_hostname_aliases`,
  off by default, opted in from `host_vars/zog.yml`.
  - **`/etc/hosts` line is written before the rename, and keeps *both* names**
    (`127.0.0.1 zog penguin`). Sudo can then resolve whichever name it finds,
    so the open question — whether ChromeOS re-stamps `/etc/hostname` when the
    container restarts — degrades to "the rename quietly reverted" instead of a
    `unable to resolve host` warning on every sudo. **Untested until the next
    ChromeOS reboot**; check `hostname` then, and if it did revert the fix is a
    user-level oneshot, not more ansible.
  - Verified on zog: hostname / `hostname -s` / `/etc/hostname` all `zog`, sudo
    silent, both names resolve, re-run `changed=0`.
  - **Side effect worth having:** this was zog's first `network` converge, so it
    also picked up the managed `/etc/hosts` block — muppet, puppy, cloudcam and
    vole resolve by name from crostini for the first time (it has no mDNS).
  - **Resolver gate fixed** (`~/ansible` `d98563c`, pushed). The role's
    systemd-resolved tasks keyed off `/etc/systemd/resolved.conf` *existing*,
    which is a different question from whether resolved is the resolver;
    they now hang off `systemctl is-active systemd-resolved`.
    **The severity was measured, and the nsswitch line is not the dangerous
    one** — tested on zog with resolved inactive and nss_resolve not installed,
    the `resolve [!UNAVAIL=return]` chain still resolved everything, because an
    absent module returns UNAVAIL and falls through. It bites only when resolved
    *runs* without upstream DNS: NOTFOUND hits the `return`. The genuinely
    unsafe one was the avahi task — masking avahi for a daemon that isn't there
    leaves no mDNS responder at all; latent only because pip alone sets
    `network_mdns_responder`, and to `avahi`. No behaviour change on any
    reachable host: old and new gates agree everywhere today (muppet/puppy conf
    + daemon both present, pip/vole/zog neither).
  - `playbooks/set_hostname.yml` is now redundant cruft: hardcoded to
    `192.168.4.138` (puppy's old address) and carrying an unrelated sudoers
    task. Fold or delete.

- **Pending drift applied to muppet, puppy and vole** (2026-08-19, from zog, in
  two waves). All three now carry the managed `/etc/hosts` block, so muppet,
  puppy, cloudcam and vole resolve by name on each; re-run `changed=0`.
  - **puppy's nmcli drift was one field, not the IP.** The `--check` `changed`
    looked alarming on the sole NFS server, so it was inspected before applying:
    method/address/gateway/DNS were already correct and only
    `connection.autoconnect-priority` differed (-999 vs the role's 100). The
    module `con modify`s without reactivating — NetworkManager's audit line
    confirms only `connection.timestamp,connection.autoconnect-priority`
    changed, the link never dropped (uptime 2w6d intact), and NFS stayed active
    with all exports. Worth remembering: an nmcli `changed` is not by itself a
    reason to fear a bounce, but it is always worth reading first.
  - Each host's own name still resolves to `127.0.1.1` locally (the distro's
    own line, above our block). Normal, left alone.
- **Clones across the fleet were well behind; managed ones now current**
  (2026-08-19). Measured before pulling rather than assumed: strands was **162
  behind** on both muppet and puppy, aifabric 20, ansible 9, super 1, plus astro
  86 behind on puppy and Berrylands 109 on muppet. Nothing was *ahead*
  anywhere, so no unpushed work was at risk. `--tags git-repos` on muppet then
  puppy brought every managed repo to origin/main.
  - **The two worst stragglers are unmanaged and stayed behind**: puppy has an
    `astro` clone and muppet a `Berrylands` clone that are **not in those hosts'
    `git_repos`** — so no ansible run will ever pull them. That, not the run
    cadence, is why "clones are behind generally". Decision needed: add them to
    host_vars, or delete them as leftovers.
  - muppet's astro tree had one untracked `.bak`; `safe_pull` stashed it as
    designed. Note muppet:astro now carries **six** stashes going back to
    2026-06 — the auto-stash is accumulating, and nobody is popping them.
- **Unrelated cruft noticed, not fixed:** puppy warns
  `Permissions for /etc/netplan/01-network-manager-all.yaml are too open` on
  every NetworkManager reload, and site.yml's `always`-tagged "Pull super
  repository" pre-task clones the *ansible* repo into `/opt/super_repo` on
  puppy alone (legacy; fires on every playbook run whatever the tags).

- **Still hand-managed:** the pre-existing host-to-host keys (vole carries
  muppet's, muppet its own) are outside `fleet:*` and undescribed anywhere — the
  gap if a true "who can reach what" inventory is ever wanted.

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
  - **Chromebook (zog) setup: DONE + VERIFIED** (2026-08-21). The hardware arrived
    and the share was added in the ChromeOS Files app to `\\192.168.0.10\astro`.
    - In order to access it from the `zog` Linux container, the share was right-clicked
      in Files and **Shared with Linux**. It appears in the container via 9p bridge
      under `/mnt/shared/SMB/<hash>` or `/mnt/chromeos/SMB/<hash>`.
    - A stable symlink **`~/bigstore-astro`** was created pointing to the hash path,
      so scripts have a reliable path. Verified read/write works, and files land as
      `peter` on muppet. Note: `df` inside the container halves the reported capacity.
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

- **rclone: fleet-wide install/auth — DONE on the reachable laptop-class hosts,
  RESIDUAL elsewhere** (2026-08-22, from mailbox "ensure rclone is installed on
  all hosts"). `roles/rclone` rewritten: it now installs the **pinned upstream
  release** (`rclone_version: 1.75.0`) to `/usr/local/bin` and **removes the
  distro package** — Debian 13 and Ubuntu 24.04 both ship 1.60.1 (2022), and
  puppy had ended up carrying *both* binaries, so `which rclone` was the only
  way to know what you got. `enable_rclone` moved to `group_vars/all.yml`
  (fleet-wide); `rclone` dropped from `common_packages` so one thing owns it.
  - **The FUSE mount is now opt-in** (`rclone_mount`, default false). That
    separation is what makes the role safe fleet-wide: "installed and
    authenticated" no longer drags a permanent Drive mount onto a capture host.
    No host had the mount running anyway — GLOBAL.md's `~/gdrive` is aspirational.
  - **Config deploy is `force: no`** (`-e rclone_force_config=true` to push a
    rotation). rclone REWRITES `rclone.conf` on every OAuth access-token
    refresh, so an unconditional copy reported `changed` on every converge and
    rolled the live token back to SSM's — whose access_token expired
    2026-03-18. Verified the two differ *only* in `access_token`/`expiry`: the
    `refresh_token` is identical, which is why deploying from SSM authenticates
    anyway. Same treatment applied to the duplicate copy in `roles/apps/gdrive-sync`.
  - **Credential fetch is gated on the aws CLI existing, not on `enable_aws`.**
    zog had `enable_aws` true but no `aws` binary — intent is not fact. A host
    that wants the credential, has no aws CLI *and* no existing rclone.conf now
    **fails loudly**; one that already has a config gets a warning that a
    rotation will not reach it. Silent skipping is exactly how puppy came to run
    gdrive-sync against a token-less config. *(zog's gap closed 2026-08-22:
    `--tags aws --limit zog` installed aws-cli 2.36.29, re-run `changed=0`. No
    code change was needed — the `aws-cli` role was already wired to
    `enable_aws`, it had simply never been run on zog, and the credentials had
    been placed by hand at onboarding so the host looked configured. The gate
    the rclone role now applies is what would have caught it.)*
  - **Verified**: muppet (had **no rclone at all**), puppy (dual binaries
    reconciled), zog — all 1.75.0, `rclone about gdrive:` returns the quota,
    re-converge `changed=0`.
  - **Rolled out to five hosts**: muppet, puppy, zog, vole, eclipticam — all
    `rclone v1.75.0`, all re-converging `changed=0`. The rest of the fleet was
    offline (astrocam, cloudcam, deskpi, homepi, starcam, xoverpi) and picks the
    role up on next converge.
  - **Role bug found on vole: `unzip` was assumed, not ensured.** The upstream
    release is a zip and vole had no unzip, so `unarchive` failed through every
    handler. `unzip` is in `common_packages`, but a role must not depend on
    `common` having run first — same class of latent portability bug as the
    nfs-server generator-dir one. Role now installs it.
  - **`pip` fixed and converged** (2026-08-22). Three separate faults stacked:
    (1) the inventory had `ansible_host=localhost ansible_connection=local`, so
    `--limit pip` from zog silently targeted *zog* and `ansible pip -m ping`
    returned SUCCESS while the real pip was untouched — now
    `ansible_host=192.168.0.61`; (2) the address had drifted (pip is a **DHCP
    lease** above the .12 pool start — muppet/puppy are pinned below it; pip
    wants a reservation or it will drift again), fixed in `/etc/hosts` by Peter
    and now declared in `network_hosts_entries`; (3) zog could not SSH to pip
    because `~/dotfiles/.ssh/config` sets `IdentitiesOnly yes` with a single
    `IdentityFile ~/.ssh/id_ed25519` for all of `192.168.0.*`, so the **shared
    fleet key `id_ed25519_b` (`SHA256:CvosCos…peter@muppet`) was never offered**
    — and pip lacked zog's own key. Bootstrapped once with
    `-e ansible_ssh_private_key_file=…/id_ed25519_b`; the `users` role then
    installed zog's key, and plain `ssh peter@pip` now works.
    **Root cause still live**: that single-IdentityFile line means any host
    whose key isn't yet distributed is unreachable from zog. Worth a second
    `IdentityFile` line in dotfiles.
  - pip verified: rclone 1.75.0, `scope = drive.file`, new client, no
    retirement notice.
- **Own Google OAuth client: DONE, LIVE, and durable** (2026-08-22). rclone's
  shared client_id is being retired "during 2026". Peter's Desktop-app client is
  in SSM as **`/rclone/client-id` + `/rclone/client-secret`** (AWS only — no host
  reachable today has `google-cloud-storage`, so **`secrets sync` is still
  owed**). `/rclone/config` now holds the new credential; the previous
  shared-client config is kept at
  `scratchpad/rclone.conf.ssm-previous` and per-host backups
  `~/.config/rclone/rclone.conf.bak-sharedclient`.
  - **Scope is now `drive.file`, not `drive` — that was the whole game.** Full
    `drive` is a *restricted* scope: "Publish app" stays greyed, and leaving
    Testing needs verification plus a third-party security assessment. Apps in
    Testing have their refresh tokens **expired by Google after 7 days**, so the
    restricted-scope path *cannot* produce a durable headless credential no
    matter how the client is rebuilt. This is why the earlier multi-day attempt
    (a few months back) could never have succeeded. `drive.file` is
    non-sensitive: publishable with no verification, no expiry, and least
    privilege — the token cannot touch anything rclone did not create.
  - **Cost of `drive.file`, accepted by Peter**: rclone can no longer see the
    ~488 MiB uploaded under the shared client. A re-seed is needed. This bears
    on the unverified-RESTORE question that keeps `enable_gdrive_sync: false` on
    puppy — the old upload is now invisible to the tool that would restore it.
  - **Publishing required an App domain after all.** App name + support email +
    developer contact were not enough: the Audience page showed "Your app's
    OAuth configuration is incomplete". The missing part was **Branding → App
    domain** (home page + privacy policy). Note the greyed *Save* there means
    "form not dirty", NOT "form valid" — that misreading cost two rounds.
  - **Privacy policy: DEBT PAID** (2026-08-22, `mywebsite` `fc0e7c8`, deployed).
    `https://www.petergrecian.co.uk/privacy` had been entered to satisfy
    publishing while the site's catch-all returned the homepage for any path —
    so the consent screen cited a policy that did not exist. `mywebsite` now has
    a real `/privacy` route and template stating what is actually true: the
    client holds `drive.file` (sees only files it created), runs as rclone on
    Peter's own machines against his own Drive, and sends nothing anywhere but
    Google's APIs; it also documents the site's own DynamoDB request logging.
    Allowed in `robots.txt`. Live and verified.
  - **Verified live** on muppet, puppy, eclipticam and zog: `scope = drive.file`,
    `rclone about gdrive:` returns the quota with **no retirement notice**, and a
    real write→list→delete round trip against Drive succeeded. vole skips the
    credential (no aws CLI) and has the binary only. Rolled out with
    `-e rclone_force_config=true`.
  - Project is **`sublime-state-506311-v9`** (number 240837326956) — NOT
    `petergrecian-personal`, and not the project holding the calendar/photos/ytm
    clients (822459252559). The Drive API had to be enabled on it by hand.
  - Console trail worth not re-deriving: audience had to be flipped Internal →
    External (the "can only be used within its organisation" block); Peter
    cannot add himself as a **test user** — project owners are "ineligible"
    because they can already consent; the support-email dropdown offers only
    groups he owns (`pppgrecian@googlegroups.com`), which is cosmetic.
  - **Open question**: `rclone_deploy_config` is gated on the aws CLI existing,
    which is broad — eclipticam got the credential because it happens to have
    aws, not because it runs gdrive-sync. With `drive.file` the blast radius is
    small (the token can only reach files rclone made), but narrowing this to
    hosts that actually sync would be tidier.
  - **Mechanics that worked, for next time**: ChromeOS's browser cannot reach
    the crostini container's loopback, so `rclone config reconnect` is the wrong
    tool (it also has no `--auth-no-open-browser` flag). Use
    `rclone authorize "drive" <id> <secret> --auth-no-open-browser` as a
    background task, then `xdg-open` the consent URL — garcon hands it to
    ChromeOS Chrome, and the redirect lands back on the container's listener.
    Terminal-wrapped URLs get truncated when copied; `xdg-open` avoids that
    entirely, and there is no `xclip` in the container.
  - **Corrected a wrong root cause on the record**: puppy.yml and the
    gdrive-sync role both blamed the `enable_rclone` gate and called puppy a Pi.
    puppy is a laptop, in `[laptops]`, and `enable_rclone` has always resolved
    **true** for it (`ansible puppy -m debug -a var=enable_rclone`). The real
    cause was that the `rclone` role had simply never been run there. Both
    comments fixed.
  - **Uncommitted in `~/ansible`** at time of writing.

- **Triaged in from `ideas/` 2026-08-16** (three items; the fourth, a forkchat
  UI-zones note, belongs to an aifabric-pane strand and was left for it):

  - **astrocam v3 units are NOT ansible-managed — a reimage loses them**
    (from astro-polecam, 2026-08-13). Hand-installed root-owned on astrocam:
    `astrocam-v3-night.service`, `-uploader.service`, `-gate.service` +
    `.timer`, and `/etc/polkit-1/rules.d/50-astrocam.rules` (lets peter toggle
    the services without sudo — the gate needs it). Repo copies of the gate
    *script* and polkit rule are in `~/astro/astrocam/`, but the unit files and
    the *installed* rule are unmanaged. **Escalated by the cover automation
    landing on top**: the gate now drives the lens cover (opens before the night
    daemon, closes after, position in `/var/lib/astrocam/cover.json`), so a
    reimage no longer just loses config — it leaves the lens sitting open all
    day. **eclipticam's equivalents ARE ansible-managed, so the pattern exists**
    — likely just extending that role to astrocam. Not urgent, no deadline; it's
    the last hand-installed corner of an otherwise-automated camera.

  - **vole's bond has NOT been reboot-tested** (2026-08-22). The config is
    right on paper — `auto bond0`, `allow-hotplug` on both slaves, `bonding` in
    `/etc/modules-load.d/`, `wpa_supplicant@wlp1s0` enabled — and the cutover
    was done live rather than by reboot precisely to avoid bouncing a
    voting-only tiebreaker that has been up 4 weeks. The one untested path is
    cold start, where `bond0` comes up before the hotplug slaves enrol. Worth a
    reboot at a moment when a walk to the machine is acceptable; the half-dead
    internal display makes console recovery unpleasant but not impossible.
    `/etc/network/interfaces.pre-bond` is still on the host as the escape
    hatch.

  - **USB ethernet dongle inventory** (2026-08-22, swept while answering "are
    any of ours actually gigabit?"). **Only muppet's is** — an ASIX AX88179
    (`0b95:1790`), linked at 1000 Mbps, though muppet's own notes say bus
    placement caps it near 280 Mbps. The rest are 100M parts and honest about
    it: puppy has a Realtek RTL**8152** (`0bda:8152`, the Fast Ethernet sibling
    of the gigabit 8153 — one digit apart and easy to mis-buy) at 100 full;
    vole and pip both have Naxiang SZNX `35b5:3500` "LAN 100M". The only
    dishonest unit was the binned `35b5:3510`. **vole's links at 100 HALF
    duplex** where the others get full — likely cable or port negotiation
    rather than the adapter; worth a different cable next time someone is at
    the machine.

  - **pip is addressed in inventory by its *lower-priority* link** (2026-08-22).
    pip is live dual-homed: ethernet `.19` at route metric 100 and WiFi `.61` at
    metric 600, both DHCP. The inventory says `ansible_host=192.168.0.61` — the
    WiFi address — so ansible reaches pip over exactly the link pip itself
    deprioritises, and a WiFi blip loses the host while ethernet is healthy.
    Same class as the pip address drift already recorded above. Not fixed here:
    the tidy answer is a DHCP reservation on the ethernet MAC, which is a router
    change, and pip is a laptop that is not always on the wire at all — so it
    may be that pip simply should not be pinned to either address.

  - **The house WiFi PSK is not in the secrets store.** It lives cleartext in
    vole's `/etc/network/interfaces.pre-bond` and (hashed) in its
    `wpa_supplicant-wlp1s0.conf`, and nowhere central. This is what stops the
    bond role being fully self-sufficient: a rebuilt vole needs the PSK passed
    by hand via `--extra-vars`, and it blocks any WiFi rescue path on other
    hosts. Deliberately not fixed unilaterally — putting the house WiFi key
    into SSM + GCS is Peter's call, not a side effect of a networking task.

  - **Fleet audit for the same drift** (2026-08-22, run from zog). Three hosts
    carry a second link the OS never uses, but each is blocked differently, so
    the "rescue path everywhere else" half of the decision is **not** done:
    - **homepi** — eth0 `.53` (DHCP), `wlan0` down, radio enabled, 3 APs
      visible, and **no WiFi profile in NetworkManager at all**. The most
      valuable candidate: it is the bastion, so losing its cable costs fleet
      entry. Blocked only on the PSK above.
    - **muppet** — USB eth `.10`, with **both** `wlp0s20f3` and the built-in
      `enp0s31f6` idle. It explicitly sets `network_wifi_disabled: true`, a
      deliberate "WiFi is a dual-homing nuisance" decision. Adding a rescue
      path there reverses an existing call, so it needs Peter, not a patch.
    - **astrocam** — eth0 `.67` (DHCP), `wlan0` down. Blocked by the known
      `pi`-sudo breakage: ansible cannot `become` on this host at all, so
      nothing can be rolled out to it until that is fixed.
    - **eclipticam** and **puppy** have no WiFi hardware — nothing to do.
    - **deskpi, starcam, xoverpi** did not answer ping while astrocam,
      cloudcam and eclipticam did from the same host, so they are likely
      genuinely down rather than a crostini routing artifact. That is pifleet's
      call, noted here only because it limited the audit.
    - **cloudcam** refused both `pi` and `peter` keys from zog — not audited.

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

- **`zip` added, and the reason zog was never converged at all** (2026-08-22,
  `~/ansible` `0e1ead5`, pushed). Chasing a one-line packaging fix turned up the
  real fault. `zip` did join `unzip` in `common_packages` — no host had it
  declared, so anything that had to *build* an archive failed late, after the
  smoke tests passed. But the dry run then failed on zog, and that failure was
  the interesting one:

  **`Set gpu_mem=16 for headless Pis` was gated on `ansible_architecture in
  ['armv6l','armv7l','aarch64']`.** zog is an aarch64 ChromeOS crostini laptop,
  so it matched, and the task hard-failed on a missing
  `/boot/firmware/config.txt` — which **aborted zog for the entire rest of
  `site.yml`**. That is why zog had no aws CLI despite `enable_aws: true` since
  onboarding, and why it looked converged when nothing past `common` had ever
  run on it. Architecture is not a test for "is a Pi". Now gated on the boot
  config existing, which also picks up the pre-Bookworm `/boot/config.txt`
  without a second task.

  Lesson worth keeping, and the same one as the samba `ss`-vs-`testparm` note
  above: **a host that fails early in a play looks identical to a host that was
  skipped.** Nothing reported zog as unconverged — the gaps only showed up when
  something concrete (`./deploy`) tried to use the machine. A `PLAY RECAP` with
  `failed=1` on one host is not cosmetic; it means every later role was silently
  not applied there.

  Rolled out and verified: zog, muppet, pip, puppy, vole and eclipticam all
  re-converge `changed=0`, all have `zip`, and eclipticam still has
  `gpu_mem=16` so the Pi path is intact.

- **zog completed `site.yml` for the first time** (2026-08-22, `~/ansible`
  `5054e50`, pushed). Following the aarch64/Pi fix above, a full run surfaced
  two more faults of exactly the same shape — a hardcoded assumption that was
  false on this host, failing hard and taking everything downstream with it.

  - **`vscode` hardcoded `arch=amd64`** in the Microsoft apt repo line.
    Microsoft publishes arm64 at that same repo, so the hardcode described
    nothing real; it just made `code` uninstallable on zog. The role then
    hard-failed and **aborted nodejs, claude-code, rclone, claude-oauth-sync
    and ansible-auto** — all of which had therefore never run on zog either.
    Now mapped from `ansible_architecture`, same idiom as `roles/rclone`.
  - **`gcp`'s keyring trio reported `changed` on every converge**: `force: yes`
    download, `changed_when: true` dearmor, and the armored copy deleted at the
    end so the next run always re-fetched. Gated on the dearmored keyring
    existing. This one matters beyond tidiness — a host that is permanently
    "changed" is indistinguishable from one that has genuinely drifted, which
    is precisely what `drift-watch` is supposed to tell us.

  zog now runs the whole playbook `failed=0` and re-converges at `changed=2`.
  The two residuals are always-changed by design: the dotfiles install script
  (forced by `dotfiles_install_force`) and `git-repos`' pre-pull stash. Both
  could take a `changed_when` if drift-watch noise ever becomes a problem.

  **Three of these in one session** — aarch64-means-Pi, amd64-means-x86,
  gcp-key-always-changed — says the roles were written against the fleet as it
  was (amd64 laptops + armv7 Pis) and zog is the first host that is neither.
  Expect more of it on the next unusual host. The tell is always the same: a
  `PLAY RECAP` with `failed=1` that nobody reads, because the host it is about
  looks fine from the outside.

  Side note worth knowing: `git-repos` **stashes the control node's own dirty
  `~/ansible` before pulling** (`safe_pull.yml`, deliberate, warns, message
  `ansible-auto <iso8601>`). Editing roles on zog and then running `site.yml`
  on zog will stash the edits mid-run. Nothing is lost — `git stash list` then
  `pop` — but commit before converging and it never comes up.

- **apt was completely broken on pip** (2026-08-22, `~/ansible` `e02ffed`,
  pushed). Found while checking the vscode arch fix had not regressed the amd64
  laptops. The VS Code `.deb` installs and maintains its **own** deb822 source
  at `/etc/apt/sources.list.d/vscode.sources` signed by
  `/usr/share/keyrings/microsoft.gpg`; the role also wrote `vscode.list` for the
  same repo signed by `/etc/apt/keyrings/packages.microsoft.gpg`. apt refuses to
  read its **entire** source list when one repo carries two `Signed-By` values,
  so **no package could be installed or updated on pip at all** — nothing to do
  with VS Code.

  Two things about this are worth remembering more than the fix:

  - **Nothing reported it.** pip was on the pi-fleet board, reachable, running.
    The fault only surfaced because `site.yml` failed on the `vscode` tag. Had
    nobody run that tag, pip would have sat there un-updatable indefinitely.
  - **The playbook could not repair it.** The play's own `Update package cache`
    task is tagged `always` and runs before any role, so it hit the broken apt
    and aborted before reaching the role that would have fixed it. It needed one
    manual `rm` (backed up at `/root/vscode.list.bak-2026-08-22`) to break the
    cycle. Worth knowing that ansible cannot bootstrap itself out of a broken
    apt source.

  The role is now bootstrap-only: if `vscode.sources` exists it removes its own
  `vscode.list` and leaves the package to manage the repo. zog has no
  `vscode.sources` yet so the bootstrap path still applies there; the cleanup
  fires on whichever converge follows Microsoft adding it.

  Swept the rest of the fleet afterwards — `apt-get update` reports no errors on
  zog, pip, puppy, muppet, vole or eclipticam. The six offline Pis are unchecked.

  Loose end: pip's `/etc/apt/sources.list.d/google-chrome.list` has the same
  repo on lines 3 and 4, which apt warns about on every update. Harmless today,
  same shape as the fault above.

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
