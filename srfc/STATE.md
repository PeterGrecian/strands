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

## Pending

1. **Fix the year-inference bug** in `surbiton._extract` — "bump a year if past"
   is fragile; produced 2027 for a noon sample when given today's date. In the
   real path it uses the email's `internalDate` so it's OK live, but harden it +
   add year-boundary tests.
2. **Wire surbiton.py into calendaralarm** as a source in `alarm.py` (alongside
   GCal + rules), de-duped via its `surbiton:...` keys. Decide lead time (Peter
   wanted longer for travel — 30–45m?) and severity.
3. **Where surbiton.py lives** long-term — stay in ~/calendaralarm as the source
   module, or move out. Open question for Peter.
4. **Booking Reminder vs Confirmation** — currently both treated as bookings;
   decide whether to rely on confirmations only.

## Decisions

- **Email route, not scraping** (2026-07-22, Peter): booking diary is a brittle
  ASP.NET postback flow; club emails are the robust source.

## Note for tooling

`strands new srfc` created `srfc` as a *symlink* to the aifabric template (its
`.template` is itself a symlink and `cp -r` copied the link, not contents) —
which briefly corrupted the shared template. Recreated srfc as a real dir with
`cp -rL`. **The `strands new` tool needs `cp -rL` (or a non-symlinked
`.template`)** — worth fixing in super/aifabric.
