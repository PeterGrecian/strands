# srfc — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Forked from calendaralarm (2026-07-22)

Split out when the Surbiton club-booking work outgrew calendaralarm's mission.
calendaralarm is the pager (source → imminence → alert → de-dupe, armed via a
systemd timer on pip; first real xMatters page fired 14:44 today). **srfc owns
the Surbiton source** — producing the upcoming-bookings list calendaralarm pages.

## Built + proven

- **`~/calendaralarm/surbiton.py`** — reads booking emails from
  `noreply@surbiton.org` via `gmail-token.json` (gmail.readonly, headless).
  Parses "Your Booking Is Confirmed" / "Booking Reminder" (court + date + time),
  nets out "Cancellation Confirmation" by (court, date, start-time). VERIFIED
  against real mail: 14 confirmations + 6 cancellations parsed; time formats
  10:30am / 11am / 4pm / 12:30noon all handled. Returns "none upcoming" now —
  correct (all current slots past or cancelled). Committed (`5cef0ce`).
- **Credentials** stored correctly: `/surbiton/username` = peter.grecian@gmail.com,
  `/surbiton/password` in the secrets store. Headless ASP.NET login works
  (viewstate POST to `login.aspx?mode=0`).

## Done this session (2026-07-22)

- **Year-inference bug fixed + tested** (`8e2e498` in ~/calendaralarm). Replaced
  the fragile one-directional "bump +1y if past" with `_resolve_year`, which
  picks the candidate year {recv-1, recv, recv+1} nearest the confirmation email
  (future-preferring). Robust across Dec↔Jan both ways, no double-bump to 2027,
  skips invalid 29-Feb candidates. New `test_surbiton.py` — 11 tests, all pass.
  Real path still runs clean ("none upcoming", correct).
- **surbiton wired into calendaralarm as the 3rd source** (`72e1fd1`). `alarm.py`
  now iterates `upcoming_bookings(now)`, pages those within a **20-min** lead
  window at **--critical** (HIGH), de-duped on the `surbiton:...` key. Wrapped in
  try/except so a Gmail hiccup degrades this source without stopping the poll.
  Proven with an injected in-window booking (fires) + out-of-window (suppressed).
  The armed pip poller picks it up automatically — LIVE.

## Pending

1. **Where surbiton.py lives** long-term — stays in ~/calendaralarm as the source
   module for now (import is `from surbiton import upcoming_bookings`). Move out
   only if srfc grows its own code. Open question for Peter.
2. **Booking Reminder vs Confirmation** — currently both treated as bookings;
   decide whether to rely on confirmations only (reminders could double-announce
   a same-day slot, though the de-dupe key makes that harmless).
3. **No live booking to end-to-end verify the page** — all current slots are
   past/cancelled. Next time Peter books, confirm a real xMatters page fires
   ~20m before with the right wording.

## Decisions

- **Email route, not scraping** (2026-07-22, Peter): booking diary is a brittle
  ASP.NET postback flow; club emails are the robust source.
- **Lead 20 min, severity --critical** (2026-07-22, Peter): court bookings page
  20m before start (travel to the club) at HIGH — a paid slot not to be missed.

## Note for tooling

`strands new srfc` created `srfc` as a *symlink* to the aifabric template (its
`.template` is itself a symlink and `cp -r` copied the link, not contents) —
which briefly corrupted the shared template. Recreated srfc as a real dir with
`cp -rL`. **The `strands new` tool needs `cp -rL` (or a non-symlinked
`.template`)** — worth fixing in super/aifabric.
