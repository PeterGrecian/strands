# calendaralarm — state

*Curated summary of where this strand is. Updated at the end of each session.*

## → PRODUCT PIVOT + design spec (2026-07-22/23) — read this first

The strand grew from "the pager" into a **personal alarm product**. A design
spec exists (published Artifact — ask Peter for the URL; source at
`scratchpad/calendaralarm-design.html`, v0.3). Two live-fire lessons reshaped it:

1. **Delivery was wrong.** The real 15:45 rule fired via **Slack** and Peter's
   verdict was *"my alarms was much more effective"* — the phone alarm made
   noise, demanded dismissal, was in-hand. So the target is **a real phone alarm
   (audible, dismiss-requiring, snoozable)**, not a message. This reopens the
   founding "xMatters, no custom app" decision. See [[delivery-must-be-a-real-alarm]].
2. **xMatters stays anyway** — two other reasons: it's a **canary** for Peter's
   work on-call settings, and a way to **understand how xMatters works**. So
   delivery is a **per-alarm channel choice** (phone alarm / xMatters / both /
   Slack-soft), NOT a severity tier. **"Severity" is dropped** from the UI.

**Authoring model** ([[alarm-authoring-model]]): the "new alarm" form leads with
**radio buttons for schedule type** — one-off / weekly (every 7d) / days-of-week
/ "it's complicated". Real cases: dentist (one-off), running club (weekly),
morning wakeup (daily set), **padel mix rotation** (the complicated one). The
rotation is computable: 3 groups × 1hr back-to-back (this week 18:30 adv / 19:30
int / 20:30 beg), Peter is **intermediates** (19:30 now), slot advances +1/week,
`(anchor_slot + weeks) % 3`. A **snooze button** is required.

**Store decision:** source of truth → **DynamoDB behind mywebsite** (which
already runs Lambda + API GW + Dynamo + PWA — on existing rails). Webapp = CRUD
+ NL-entry page. Home = grow the calendaralarm strand (srfc stays its email
source child).

**OPEN, ask next session:** (a) THE question — how to deliver a real phone alarm
(push+sound / Android full-screen intent / companion app; pip is now on
Tailscale with the phone reachable at 100.102.111.126 — relevant); (b) which
weekday padel is on (NOT Tuesday) + lead; (c) auth on the webapp; (d) build
order confirmed: schedule model+one-off → store → phone delivery → API/webapp.

## First backlog visit (2026-07-22)

Reviewed via the ubersitrep backlog rotation (first live run of the ritual).
The repo was dormant since 2026-04-01 (~4 months) and marked "confirm
drop/revive" — Peter revived it with a decisive reframe: **the alarms go to
xMatters.**

## What exists

- **`~/calendaralarm/upcoming.py`** — a working Google Calendar reader: lists
  the next 10 events (`calendarId=primary`, `singleEvents`, `orderBy=startTime`)
  via OAuth. Client secret at `~/.config/gcloud/calendar-client.json`, token
  cached at `~/.config/gcloud/calendar-token.json` (readonly scope). This is
  the input side and it works.
- **`CronAlarmApp.zip`** — leftover artefact of an earlier Android alarm-app
  attempt. Almost certainly drop (the xMatters route makes a custom app
  unnecessary).
- **`super/bin/alert`** (house tool) — POSTs to an alerting Lambda that fans out
  to Slack + xMatters by severity: `--info` (Slack only), `--xinfo` (xMatters
  LOW), `--warn` (MEDIUM + AI appraisal), `--critical` (HIGH + AI appraisal).
  This is the un-ignorable delivery the project needed — already built.

## The design (this then that)

The project's hard part — an alarm that *can't* be swiped away — is already
solved by xMatters. So the build collapses to a thin bridge:

1. **Read** upcoming events (have it: `upcoming.py`).
2. **Decide** which events are imminent + important enough to page for
   (the missing middle — a lead-time + importance filter; e.g. flagged events,
   or a keyword/calendar-based rule, N minutes ahead).
3. **Escalate** via `alert` at the right severity (`--critical` for the
   can't-miss ones; maybe `--warn`/`--xinfo` for softer nudges).
4. **Schedule** the poller (cron on an always-on host, or a Lambda on a
   timer — decide where it runs; it needs the GCal token).

## Built (2026-07-22, keeper session)

The bridge exists and works end-to-end. Committed to `~/calendaralarm`
(`bc7af07`): **`alarm.py`** + **`run.sh`** + README.

- **Read → decide → alert** is wired. `alarm.py` reads upcoming *timed* events
  (via the existing readonly OAuth token, auto-refreshed), keeps those starting
  within `--lead-minutes` (default 15), and calls `super/bin/alert`.
- **Importance ladder (revised 2026-07-23 — see below):** default paged event
  → `--critical` (xMatters HIGH); title prefixed `~~` → `--warn` (soft nudge,
  opt-*down*); event marked `transparency: transparent` (shown *free*) →
  skipped; all-day events → skipped (no time to be imminent for). Rationale:
  colorId is null on all of Peter's events, so importance can't lean on colour
  — default to paging any imminent timed appointment. (First cut used `--warn`
  as the default with `!!` opting up; that proved too quiet — reversed.)
- **De-dupe done:** fired event ids recorded in
  `~/.local/state/calendaralarm/fired.json` (48h TTL), so a poll won't re-page.
- **Verified** in `--dry-run`: all-day events filtered out, timed events decided
  and produce a well-formed `alert` command, injected fired-record suppresses
  the matching event. No live xMatters page sent yet (dry-run only).

## Recurring-meeting rules + bank holidays (2026-07-22, keeper)

Peter wanted "every weekday at 15:45, page 2 min before, not on holidays / bank
holidays." Built as a **second alert source** (both, per his answer), committed
`cb88f11`:

- **`rules.yaml`** — human-editable standing meetings: `days` (Mon-Fri /
  Mon,Wed,Fri / daily), `at` (local HH:MM), `lead_minutes`, `severity`,
  `skip_holidays`. Ships with his 15:45 Mon-Fri / lead 2 / warn rule.
- **`rules.py`** — parses the file; a rule is "due" when its meeting time is
  within `lead_minutes` of now on a matching weekday, skipping bank holidays.
- **`holidays.py`** — england-and-wales bank holidays from
  `gov.uk/bank-holidays.json` (no key), cached daily, stale-cache fallback.
- **`alarm.py`** — rules feed the *same* de-dupe + alert path as GCal events;
  de-duped by name+date so a rule pages once/day.
- **`requirements.txt`** added (incl. PyYAML) for venv rebuilds on migration.

Scope note: "holidays" resolved to **UK bank holidays only** for now. Peter's
own days-off (leave) are NOT yet wired — would need reading them from a calendar
(deferred; ask how he marks leave if he wants it).

Verified end-to-end: rule fires at 15:44 on a weekday, not before the window,
not after the meeting, not on weekends, not on the 31 Aug bank holiday.

## LIVE — first real xMatters page fired (2026-07-22, keeper)

The timer is **armed** (`systemctl --user enable --now calendaralarm.timer`, on
pip) and the whole path is proven end-to-end against real xMatters:

- A temporary test rule paged for real at 14:44 — incident URL returned
  (`.../incident/calendaralarm-20260722-134403-513312`), recorded in
  `fired.json`, and the next poll did **not** re-page (de-dupe held). Test rule
  then removed; state reset to `{}`.
- **Bug found + fixed** (`090be6d`): the first test (14:35) silently didn't
  fire. A rule's window was `[meeting - lead, meeting]`, so a `lead_minutes:0`
  rule was a zero-width instant the 1-min poll always overshot (:02 past). Added
  a 90s trailing `GRACE` (> one poll interval) → `[meeting - lead, meeting +
  90s)`. lead-0 rules now fire, and no meeting can fall between two polls.

So calendaralarm is now a working, scheduled, un-ignorable pager. Both sources
(GCal timed events + rules.yaml) live.

## Scheduling — decided: systemd user timer (2026-07-22, Peter)

Not cron — a **systemd user timer**. `systemd/calendaralarm.{service,timer}`
(in the calendaralarm repo): oneshot service runs `run.sh`; timer `*:0/5`
(every 5 min), `Persistent=true` to catch a poll missed while the laptop slept.
User units run as `peter` (venv + GCal token in reach) and linger is enabled on
pip, so they run without an active login. Installed as symlinks into
`~/.config/systemd/user/`, currently `linked` + **inactive** (not armed).
Verified: units pass `systemd-analyze verify` clean; transient systemd-run of
`run.sh --dry-run` exited 0.

## Severity raised to HIGH + response convention (2026-07-23, Peter)

**A real meeting was missed** because it paged at `--warn` (xMatters MEDIUM) —
too quiet to reach him. Fixed by defaulting everything to `--critical` (HIGH):

- `rules.yaml` — the 15:45 "Afternoon meeting" rule: `warn` → `critical`.
- `alarm.py` `decide_severity` — default timed calendar event: `--warn` →
  `--critical`. Marker convention **inverted**: `~~`-prefix now opts *down* to
  `--warn` (soft nudge); the old `!!`-opts-up marker is gone (HIGH is default).
- `rules.py` — fallback default for a rule omitting `severity`: `warn` →
  `critical`.
- Verified: rule loads as `critical`; normal event → `--critical`, `~~` event →
  `--warn`, transparent → skipped. Timer picks it up on next poll (no restart).

**xMatters response convention — Close** ([[xmatters-response-close]]): when an
alarm fires, **Close** it (not just Acknowledge). Each alarm is a fire-and-forget
nudge — nothing re-escalates (de-dupe = one page per event/day), so Acknowledge
buys nothing and leaves a growing pile of open incidents. Close tidies it away.
(Acknowledge-then-Close is the *real* on-call lifecycle — worth practising since
xMatters here is also a canary for Peter's work on-call, but not required.)

## Pending / loose ends

- **Arm it.** Timer is installed but inactive — arming is Peter's deliberate
  act: `systemctl --user enable --now calendaralarm.timer`. First live run pages
  for real. (`systemctl --user list-timers` / `journalctl --user -u
  calendaralarm.service -f` to watch.)
- **Placement still open.** The GCal token lives only on **pip** (a laptop, not
  always-on), so the timer only fires during laptop-up hours. For a reliable
  pager, migrate the timer + token + venv to an always-on fleet host (homepi),
  or move to a Lambda timer (then the token/refresh must live in the cloud).
- Tune `--lead-minutes` once it's run against more real days. (Severity tiers
  now settled: HIGH default — see 2026-07-23 section.)
- Drop `CronAlarmApp.zip` unless there's a reason to keep it (still present).

## Decisions

- **Alarms go to xMatters** (2026-07-22, Peter): the delivery mechanism is the
  house `alert` tool → xMatters escalation, not a custom alarm app. xMatters
  is inherently the "requires effort to silence" channel the project wanted.
  Kills the build-an-Android-app path.
- **Alarms page at HIGH, respond with Close** (2026-07-23, Peter): default
  severity is `--critical` (MEDIUM proved too quiet — a meeting was missed); on
  receipt, **Close** the xMatters incident rather than only Acknowledge, since
  nothing re-escalates. See the 2026-07-23 section for the code changes.
