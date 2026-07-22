# calendaralarm — state

*Curated summary of where this strand is. Updated at the end of each session.*

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
- **Importance ladder decided (first cut):** default paged event → `--warn`
  (xMatters MEDIUM); title prefixed `!!` → `--critical` (HIGH); event marked
  `transparency: transparent` (shown *free*) → skipped; all-day events → skipped
  (no time to be imminent for). Rationale: colorId is null on all of Peter's
  events, so importance can't lean on colour — default to paging any imminent
  timed appointment, with `!!` as the opt-in escalation.
- **De-dupe done:** fired event ids recorded in
  `~/.local/state/calendaralarm/fired.json` (48h TTL), so a poll won't re-page.
- **Verified** in `--dry-run`: all-day events filtered out, timed events decided
  and produce a well-formed `alert` command, injected fired-record suppresses
  the matching event. No live xMatters page sent yet (dry-run only).

## Pending / loose ends

- **Arm it.** No live page has been sent and no cron is installed (deliberate —
  arming a real pager is Peter's call). To go live: `crontab -e` →
  `*/5 * * * * $HOME/calendaralarm/run.sh`. First live run will page for real.
- **Placement decision needs Peter.** The poller needs the GCal token, which
  lives only on **pip** (a laptop, not always-on). For a reliable pager it
  should migrate to an always-on fleet host (homepi) with token + venv copied
  over — or become a Lambda timer (but then the token/refresh must live in the
  cloud). Interim: cron on pip covers hours the laptop is up.
- Tune `--lead-minutes` and the severity tiers once it's run against real days.
- Drop `CronAlarmApp.zip` unless there's a reason to keep it (still present).

## Decisions

- **Alarms go to xMatters** (2026-07-22, Peter): the delivery mechanism is the
  house `alert` tool → xMatters escalation, not a custom alarm app. xMatters
  is inherently the "requires effort to silence" channel the project wanted.
  Kills the build-an-Android-app path.
