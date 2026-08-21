# Setting up a private Google Drive client_id for rclone

**Why:** rclone's built-in shared Drive `client_id` is throttled to uselessness
(uploads reach 100%, hang for minutes on finalisation, time out, restart) and
**is being retired during 2026** — rclone v1.75 warns about it explicitly. The
token currently in SSM `/rclone/config` will stop working on its own. This is
mandatory, not tuning.

**Who:** Peter — browser + Google account required. ~30 minutes.

**Project:** `petergrecian-personal` (console.cloud.google.com)

> Google reshuffles this console regularly (the OAuth screens have moved under
> "Google Auth Platform" in recent revisions). Menu names below may drift —
> the *search box at the top* is the reliable way to reach each page.

---

## 1. Enable the Drive API

APIs & Services → **Library** → search "Google Drive API" → **Enable**.

## 2. OAuth consent screen

APIs & Services → **OAuth consent screen**.

- **User type: External** — required; `petergrecian-personal` is a consumer
  Google account, not Workspace, so Internal is not offered.
- App name: anything (`astro-backup`). Support email + developer contact:
  peter.grecian@gmail.com.
- **Test users:** add peter.grecian@gmail.com.

### ⚠️ THE GOTCHA THAT WILL BITE LATER — publish to production

**Set Publishing status to "In production". Do not leave it in "Testing".**

Apps in **Testing** status issue refresh tokens that **expire after 7 days**.
The backup would then run for a week and silently start failing — the single
worst failure mode for a backup, and one we would not notice for a while
because the ledger only records verified copies.

Publishing an unverified app is fine for personal use: Google caps it at 100
users and shows an "unverified app" interstitial at auth time. Click
**Advanced → Go to <app> (unsafe)** to proceed. Verification is only needed to
remove that warning for third-party users, which we do not have.

## 3. Create the OAuth client

APIs & Services → **Credentials** → **Create Credentials** → **OAuth client ID**

- **Application type: Desktop app** (this is what registers the
  `http://127.0.0.1` loopback redirect rclone needs — do NOT pick "Web
  application", which requires explicit redirect URIs).
- Name it, create, and keep the **Client ID** and **Client secret**.

## 4. Authorise — on a host whose OWN browser reaches its OWN loopback

**The one rule:** Google accepts only `http://127.0.0.1:53682` as the redirect,
and that means the loopback of the machine *running the browser*. So rclone and
the browser must sit on the same machine.

| Host | | Suitable? |
|---|---|---|
| **zog** | Chromebook, aarch64, Crostini | **No** — Chrome runs in ChromeOS, rclone in the Linux container. Different loopbacks. `penguin.linux.test` does not help: Google redirects to the literal `127.0.0.1`. Would need ChromeOS port-forwarding of 53682. **This is what defeated the 2026-08-21 attempt.** |
| **pip** | Linux X390 laptop, 192.168.0.19 | **Yes** — ordinary Linux desktop, browser and rclone share one loopback. Was offline when this was written. |
| **muppet** | 192.168.0.10, Firefox + Chrome installed | **Yes** — needs a graphical session; GLOBAL.md calls its built-in screen difficult, so **use an external display** (Peter's suggestion). |

Do NOT confuse zog with pip: zog is the Chromebook, pip is the Linux laptop.
The 2026-08-21 session got this backwards and wasted an hour on it.

```bash
ssh peter@muppet          # needs a graphical session on that host
rclone config
```

- `n` new remote (or `e` to edit if `gdrive` exists) → name **gdrive**
- Storage: **drive**
- **client_id / client_secret:** paste the ones from step 3 (leaving these
  blank is exactly the bug we are fixing)
- **scope: 1** (`drive` — full access; matches the existing config)
- root_folder_id, service_account_file: blank
- Edit advanced config: **n**
- Use auto config: **y** → browser opens → approve (via the unverified-app
  warning) → "Success!"

Verify:

```bash
rclone about gdrive:      # expect ~5 TiB total
```

## 5. Store it so no host has to repeat this

```bash
secrets put /rclone/config "$(cat ~/.config/rclone/rclone.conf)"
```

`roles/apps/gdrive-sync` now deploys this to puppy (added 2026-08-21 — the
`rclone` role that used to be the only deployer is gated on `enable_rclone`,
set only in `group_vars/laptops.yml`, which is why puppy never had it).

Then on puppy:

```bash
cd ~/ansible && ansible-playbook playbooks/site.yml -l puppy --tags gdrive-sync
rclone about gdrive:                       # confirm from puppy
cd ~/astro && ./bin/gdrive-sync --limit 50 # the real test
```

## 6. Re-arm only after a verified RESTORE

`enable_gdrive_sync: false` in `inventory/host_vars/puppy.yml` and the timer is
disabled. Before re-enabling: pull a frame back down and byte-compare it with
the original. *An untested backup is not a backup.* Also revisit
`--bwlimit=2M` — at 8.07 GB/night of new v3 data, the sync must outrun capture.

---

## Alternative worth knowing: `scope = drive.file`

`drive.file` grants access only to files the app itself created — least
privilege, and it is not a *restricted* scope, so it side-steps verification
questions entirely. Attractive for a backup that only ever touches its own
uploads.

**Not recommended here** because rclone with `drive.file` cannot traverse to
find a folder it did not create, so it needs `root_folder_id` pinned to a
pre-made folder, and the 4 frames already uploaded under the old client would
be invisible to it (they would be re-uploaded as duplicates; delete them first
if going this route). Keep `drive` unless the extra confinement is wanted.
