# xmatters — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **Alerting pipeline**: producers call `alert` (super/bin) → API Gateway
  `b5wgk4mp4g` → Lambda `alerting` (source: `~/alerting/lambda/`) → DynamoDB
  `alerting-incidents` + Slack + xMatters Events API. Staleness check runs
  every 5 min via EventBridge (task=staleness).
- **xMatters instance**: `berrylandscomputing.xmatters.com`. Plan "Send Alerts"
  / form "Send Alert", recipient Peter (person UUID in `xmatters.py`). Creds:
  `secrets get /alerting/xmatters-api-key` + `-api-secret` (Basic auth).
  Severity→priority: critical→HIGH, warn/calendar→MEDIUM, xinfo→LOW. Events
  auto-expire after 4h (`expirationInMinutes=240`).
- **Host monitor**: `/opt/monitor/monitor.py` (systemd `monitor.service`,
  runs on muppet at least) — disk/memory/swap/services/SMART checks, 60s loop,
  15-min per-check alert cooldown (`ALERT_COOLDOWN=900`).
- **feeds Lambda** (`~/alerting/feeds/`): BBC/football/stock → Gemini digest →
  alerting API at LOW. An xMatters+Gemini experiment. **Now DISABLED** (see
  below).

## Dedup — what was TESTED against the live API (2026-07-27)

The disk-full storm made 33 *separate* HIGH events because nothing deduped.
I explored two xMatters-native mechanisms and **verified both against the live
instance** (POST /events, read back eventIds). Findings — trust these over
intuition, they cost real experiments:

- **`requestId` does NOT dedup.** It must be a valid **UUID** (a raw
  `dedup-<hex>` string is rejected 400 `validation.common.uuid.invalid` — which
  would have made *every* alert POST fail if shipped blind). Even with a valid
  deterministic `uuid5(namespace, source+normalized-title)`, two POSTs sharing
  the same requestId ~5s apart created **two different events** (96727000,
  96728000). So requestId is a correlation/trace id here, not an idempotency
  key. Do not rely on it for suppression.
- **Plan-level `floodControl` is API-settable but did nothing observable.**
  `POST /plans {id, floodControl:true}` returns 200 and reads back true, but new
  events still showed `floodControl:false` and the duplicate test events were
  NOT suppressed. Real flood control in xMatters is bound to the inbound
  **integration/form** (threshold + window + duplicate-defining properties), not
  a plan boolean — and our path is Events-API-direct with a plan+form, which
  doesn't appear to honour it. (I set the flag true while probing, then **reverted
  it to false** — its original value. Left as-is.)

**Conclusion: neither native mechanism deduped on our API path.** The reliable,
in-our-control fix is **Lambda-side suppression** before calling
`trigger_xmatters`: on `_fire_alert`, look up an open incident with the same
normalized `source+title` within a window (DynamoDB query, or an SSM/marker),
and skip xMatters if found. Deterministic, testable, lives in git. monitor.py
already has a 15-min per-check cooldown, so the Lambda suppressor is a backstop
for other producers + repeats that slip the cooldown. **Not yet implemented —
this is the open decision.** For "still broken, remind me" cadence, drive it off
the existing `expirationInMinutes` (events auto-terminate at 4h) or an explicit
re-fire; xMatters escalation timeouts are the native alternative.

## Pending / loose ends

- **⚠ monitor.service on muppet is STOPPED** (2026-07-27, during disk-full
  alarm storm; new disk arriving that day). Restarts automatically on reboot —
  the disk install will bring it back. If muppet is *not* rebooted, `sudo
  systemctl start monitor` after the swap. Its drop-in
  `/etc/systemd/system/monitor.service.d/disk-threshold.conf` pins disk
  warn/crit to 99/99 — reconsider once bigdisk is replaced.
- **Dedup not yet implemented** — see the tested findings above. Native
  xMatters mechanisms (requestId, plan floodControl) were *disproven* on our
  path; the open decision is whether to add **Lambda-side suppression**.
- **feeds state-save is broken**: SSM param `/alerting/feeds-state` exceeds the
  Standard-tier 4096-char limit, so PutParameter fails every run (feeds has no
  working "already sent" memory). Moot while feeds is disabled; fix (advanced
  tier, or store state elsewhere) before ever re-enabling.
- **Uncommitted → committed**: alerting changes are on branch
  `remove-hourly-digest` (commit 95e487d), **not yet pushed / not merged to
  main**.

## Decisions (2026-07-27)

- **Hourly incident digest removed** — deprecated and throwing hourly
  dynamodb:Scan AccessDenied. Deleted from handler.py + eventbridge.tf; Lambda
  redeployed; 3 EventBridge resources destroyed via targeted apply.
- **feeds schedule disabled at source** — `state = "DISABLED"` set explicitly
  in `feeds.tf` (not console drift). It was xMatters testing, not wanted.
- Did **not** run a blanket `terraform apply` — full plan also wanted an
  unrelated `lambda_runaway` alarm tag change; targeted applies used throughout
  to avoid riding along on drift.
- **Dedup approach reversed after live testing** — initially recommended a
  stable `requestId`; testing proved requestId doesn't dedup and plan
  floodControl doesn't either on our path (see tested findings). No dedup code
  shipped. Lambda `xmatters.py` unchanged from committed baseline (a briefly-
  deployed requestId version was reverted + redeployed clean). Plan floodControl
  left at its original `false`.
