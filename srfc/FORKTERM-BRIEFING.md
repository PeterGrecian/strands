# Briefing: srfc strand (forked from calendaralarm, 2026-07-22)

You are the **srfc** keeper — Surbiton Racket & Fitness Club integration. You
were forked out of the `calendaralarm` strand because the club-bookings work
grew into its own thing (Gmail parsing, ManageOurClub investigation, cancellation
netting) and no longer belongs inside calendaralarm's "un-ignorable alarm" mission.

## The relationship to calendaralarm
calendaralarm is the **pager**: read a source → decide imminence/importance →
fire `super/bin/alert` (Slack + xMatters) → de-dupe. It already has two live
sources (Google Calendar timed events, and `rules.yaml` recurring rules) and is
**armed** via a systemd user timer on pip (`calendaralarm.timer`, 1-min poll). A
real xMatters page fired successfully at 14:44 today.

**srfc owns the Surbiton *source*.** The deliverable is: produce the list of
Peter's upcoming court bookings, which calendaralarm then pages a lead-time
before. Keep the seam clean — srfc = "what are my bookings", calendaralarm =
"page me about imminent things".

## What's already built and PROVEN (in ~/calendaralarm)
- **`surbiton.py`** — reads booking emails from Gmail (`noreply@surbiton.org`)
  and returns upcoming, non-cancelled bookings. VERIFIED: parses 14
  confirmations + 6 cancellations from real mail; all time formats work
  (`10:30am`, `11am`, `4pm`, `12:30noon`); nets out cancellations by
  (court, date, start-time) key. Currently returns "none upcoming" — correct,
  as all current slots are past or cancelled.
- Uses the existing **`~/.config/gcloud/gmail-token.json`** (gmail.readonly) —
  works headlessly, no MCP needed, so the systemd poller can use it.

## Credentials (stored correctly this session)
- `/surbiton/username` = peter.grecian@gmail.com, `/surbiton/password` = <token>
  in the `secrets` store (SSM+GCS). A **headless login works** (ASP.NET viewstate
  POST to `login.aspx?mode=0`, fields `ctl00$maincol$txtUserName/txtPassword`).

## Key investigation findings
- Site is **ManageOurClub** (ASP.NET WebForms). Booking diary is at
  `/pages/resource/resdiary.aspx` but it's a **stateful postback flow** — a plain
  GET 302s to an error page (`/default.aspx?aspxerrorpath=...`). Navigation is via
  `__doPostBack('...posResourceTile...')`. So **scraping the diary is brittle**;
  we chose the **email route** instead (Peter's decision) — robust, survives site
  changes.
- Booking emails from `noreply@surbiton.org`, three subjects:
  "Your Booking Is Confirmed", "Booking Reminder", "Cancellation Confirmation".
  Body/snippet format: `Padel Court N on <Weekday> <D> <Month> at <time>[ to <time>]`.
  No year in text — inferred from email received date.

## KNOWN BUG to fix first
`surbiton.py` year-inference is fragile: the `_extract` "if in the past, bump a
year" logic produced **2027** for a 12:30noon sample when passed today's date as
the received date. In the real `upcoming_bookings` path it uses the true
`internalDate` so it's OK, but the logic needs hardening (a booking is always
near-future relative to *its own* confirmation email). Write a couple of unit
tests around year boundaries.

## Pending / next steps
1. Fix + test the year-inference bug.
2. Wire `surbiton.py` as a source into calendaralarm's `alarm.py` (a 3rd/4th
   source alongside GCal + rules), de-duped with the `surbiton:...` keys it
   already emits. Decide the lead time (Peter wanted longer for travel — 30–45m?)
   and severity. Coordinate via mailbox with the calendaralarm/ubersitrep sessions.
3. Decide where surbiton.py lives long-term — probably move it OUT of
   ~/calendaralarm into its own place if srfc grows, or keep it there as the
   calendaralarm source module. (Open question for Peter.)
4. Handle "Booking Reminder" as a source too (club's own day-before reminder) —
   or rely only on confirmations. Currently both are treated as confirmations.

## First actions
Read calendaralarm's STATE.md and CLAUDE.md for the pager design. Then `dcp`-seed
this strand's STATE.md from this briefing, fix the year bug, and report to the
ubersitrep parent via `strand-mailbox` when surbiton is wired into the pager.
