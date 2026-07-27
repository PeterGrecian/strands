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

## Key learning — xMatters CAN dedupe (2026-07-27)

The disk-full storm created 33 *separate* HIGH events because nothing
deduped. xMatters has native mechanisms — I was wrong to say it couldn't:

- **`requestId`** on the Events API is an idempotency key: two POSTs with the
  same `requestId` collapse to one event (no second notification). It only ever
  *suppresses*, never triggers/retriggers. `xmatters.py` sets none today, so
  every POST is unique.
- **Form-level Flood Control** (xMatters web UI, per-form) suppresses
  substantially-identical events within a window. Our events come through with
  `floodControl: false`.

**Recommended dedup fix** (not yet done): set a **stable** `requestId =
hash(source+title)` with **no time bucket** in `xmatters.py`. A time bucket is
a trap — wall-clock-aligned buckets re-page across boundaries (as little as 2
min apart) and drip forever for a stuck condition. Stable hash + monitor.py's
existing 15-min cooldown = one page per distinct problem. Neither approach
auto-re-notifies if still broken; that needs an xMatters escalation timeout.

## Pending / loose ends

- **⚠ monitor.service on muppet is STOPPED** (2026-07-27, during disk-full
  alarm storm; new disk arriving that day). Restarts automatically on reboot —
  the disk install will bring it back. If muppet is *not* rebooted, `sudo
  systemctl start monitor` after the swap. Its drop-in
  `/etc/systemd/system/monitor.service.d/disk-threshold.conf` pins disk
  warn/crit to 99/99 — reconsider once bigdisk is replaced.
- **Dedup not yet implemented** — see Key Learning above. Decision (stable
  `requestId` vs. enabling Flood Control on the form) still open.
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
