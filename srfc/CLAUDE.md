# Strand: srfc — Surbiton Racket & Fitness Club

Integrate Peter's **Surbiton Racket & Fitness Club** (SRFC) padel/tennis court
bookings into the alerting fleet. Forked out of `calendaralarm` (2026-07-22)
when the club-bookings work grew into its own thing.

**The deliverable:** produce Peter's list of upcoming court bookings, so
`calendaralarm` can page him a lead-time before each one (via `super/bin/alert`
→ xMatters). Keep the seam clean: **srfc = "what are my bookings"**,
calendaralarm = "page me about imminent things".

## The chosen mechanism: booking emails, not scraping

The club runs **ManageOurClub** (ASP.NET WebForms). Its booking diary
(`/pages/resource/resdiary.aspx`) is a stateful postback flow — a plain GET
302s to an error page — so scraping is brittle. Instead we read the club's
booking emails from `noreply@surbiton.org` via Gmail (`gmail.readonly`,
headless — the existing `~/.config/gcloud/gmail-token.json`). Robust; survives
site changes.

Email types (subject → body): "Your Booking Is Confirmed" / "Booking Reminder"
carry `Court N on <Weekday> <D> <Month> at <time>`; "Cancellation Confirmation"
removes a slot. Bookings are netted by (court, date, start-time).

## Repos it spans

- **`~/calendaralarm`** — `surbiton.py` (the email reader) currently lives here
  as the pager's Surbiton source. Whether it moves out is an open question.
- **`super/bin/alert`** — xMatters/Slack delivery (via calendaralarm).
- **`secrets` store** — `/surbiton/username`, `/surbiton/password` (headless
  club login works, kept for any future portal need).

## Session ritual

1. Read `STATE.md` (state/decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter; promote or drop; delete triaged entries.
3. Work. Code commits go to `~/calendaralarm` (or wherever surbiton.py lands).
4. On `dcp`/session end: update `STATE.md` — what changed, what's pending.
