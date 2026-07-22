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

## Pending / loose ends

- Build the imminence/importance filter (step 2) — the real work.
- Decide the escalation ladder: which events → which severity. Does every
  paged event go `--critical`, or is there a tier?
- Decide where the poller runs (always-on Pi via cron vs Lambda timer) and how
  the GCal OAuth token lives there (refresh handling).
- Drop `CronAlarmApp.zip` unless there's a reason to keep it.
- Avoid double-paging: a fired event shouldn't re-page every poll — needs a
  "already alerted" record.

## Decisions

- **Alarms go to xMatters** (2026-07-22, Peter): the delivery mechanism is the
  house `alert` tool → xMatters escalation, not a custom alarm app. xMatters
  is inherently the "requires effort to silence" channel the project wanted.
  Kills the build-an-Android-app path.
