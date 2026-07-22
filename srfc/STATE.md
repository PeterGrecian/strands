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

## BREAKTHROUGH: live diary IS readable headlessly (2026-07-22)

Revisited the site. The booking portal is a **separate host** from the club's
Squarespace site — it's the outsourced ManageOurClub deployment at
**`https://mysurbitonracketfitness.com`** ("mysurbiton"; the club's own
`www.surbiton.org` is a staff member's hobby Squarespace, irrelevant). The full
headless chain now PROVEN in scratch:

1. **Login** — GET `/login.aspx?mode=0`, POST viewstate + `ctl00$maincol$txtUserName`
   / `txtPassword` / `btnLogin`. Earns `.ASPXAUTH` + `ASP.NET_SessionId`. (The
   briefing's `/pages/homepage/login.aspx` path was wrong — it's root `/login.aspx`.)
2. **Break the postback wall** — a cold GET of `resdiary.aspx` bounces to
   homepage (needs originating postback context, not just auth — so a *cookie
   wouldn't have helped*; auth was never the blocker, navigation was). Solved by
   POSTing `__EVENTTARGET=posResourceTile`, `__EVENTARGUMENT=<tileId>` (+ homepage
   viewstate) to `/pages/homepage.aspx`. **Padel tile = `10010`** (Tennis 10008,
   Squash 10009-ish, Table Tennis/Studio 10011 — tile IDs may drift on portal updates).
3. **Parse** — `resdiary.aspx` cells are `<div class="col ...">`:
   `systemcolor_Green`=**available** (shows price+duration), `systemcolor_Blue`=
   **booked** (shows **player names**), `textcolorblack a`=**organised session**
   (Mix In / class / camp), `col titlecol`=court header. BeautifulSoup parses it
   cleanly — proved 66 slots (53 booked / 13 available) across Padel Courts 1–5.

Brittleness caveat: this is the postback route the original investigation warned
about. Auth is solid; parsing depends on tile IDs + cell classes that can shift.
Fine for a personal tool, expect occasional maintenance.

## Booking-horizon rules (Peter, 2026-07-22) — KEY for #2/#5/#6

- **Courts: open 13 days ahead at 09:30** (London). A slot 13 days out appears
  at exactly 09:30; that's the bot-vs-human race moment for #2 and the
  "which court do I win" moment for #5.
- **Mix Ins: open 7 days ahead at 07:00** (London). The moment a Mix-In place
  becomes grabbable for #6.

Implications: snapshot horizon must reach **13 days** (catch a court slot the
instant it opens). Burst-poll around **09:30** (courts) and **07:00** (Mix Ins)
to measure how fast prime slots vanish — the "wake 1 min before the window" case.

## Missions (the reason for live diary access) — Peter's ideas, 2026-07-22

All six run off ONE spine: poll diary → log timestamped snapshots (JSONL) →
diff/analyse over history. Email can't do any of these (it only knows *my* slots).

1. **Holes finder** — stranded 30-min gaps between 90-min blocks; the reliably-
   empty windows to schedule *work meetings into* (avoid coinciding with playable
   holes). Works off ONE snapshot — quickest win. **Build first (after spine).**
2. **Booking-speed / bot stats** — "300ms sprint-reaction" analogy: how fast do
   prime slots vanish after the booking horizon opens (courts 13d/09:30, mix-ins
   7d/07:00)? Suspects others use bots. Needs *burst polling around those exact
   open-times* (deferred; baseline poll is 5-min).
3. **Cancellation timing** — when do cancellations land (3 days out? 2?) so Peter
   knows when to look. Diff snapshots for booked→available; histogram of "cancelled
   Nh before slot."
4. **Cancel → xMatters pop-down alarm** — Peter lives 5 min walk away; page him
   when a *good* slot frees so he grabs it. Real-time diff + existing `alert` path.
5. **Court-preference / "Court 1 stage-fright"** — when you wake 1 min before the
   window opens, which court do you actually win? Old Courts 4&5 vs new 1/2/3?
   Hypothesis: **is Court 1 booked last because you're on show / watched?** Measure
   fill-order + residual-emptiness at equal times across history.
6. **Mix-in reliability** — "if I organise my week around a Mix In, will I get a
   place?" Track each recurring session's fill level over time: does it sell out,
   how many days ahead? Safe-to-plan-around vs gamble.

## Plan / next steps

- **Build the spine**: `diary.py` (login → postback → parse → structured snapshot)
  + a 5-min systemd user timer appending JSONL snapshots to
  `~/.local/state/srfc/diary/`. Capture **Padel only**, **all bookable days**
  (full horizon = **13 days** for courts). Then ship #1 (holes) as first visible
  output; history for
  #2/#3/#5/#6 accrues meanwhile; #4 (alarm) plugs into diff engine + `alert`.
- Scratch proof-of-concept lives in this session's scratchpad (login+postback+parse
  scripts). Promote into real code under srfc (see "where code lives" below).

## Still pending (email-source side)

1. **Where surbiton.py lives** long-term — the email reader stays in
   ~/calendaralarm as calendaralarm's source module. The NEW diary code (`diary.py`
   + spine) is srfc's own — needs a home: likely a real `~/srfc` repo (srfc has
   outgrown being just a calendaralarm source). Decide with Peter.
2. **Booking Reminder vs Confirmation** — both treated as bookings; de-dupe key
   makes double-announce harmless. Low priority.
3. **No live booking to end-to-end verify the page** — next time Peter books,
   confirm a real xMatters page fires ~20m before with the right wording.

## Decisions

- **Email for MY bookings; live diary for the analytics ideas** (2026-07-22,
  Peter): email route (surbiton.py) remains the robust source for paging Peter's
  own confirmed slots. The live diary (mysurbitonracketfitness.com) is now ALSO
  used — it's the only source for availability/cancellations/others' bookings that
  the six missions need. (Supersedes the earlier "email not scraping" decision:
  scraping proved feasible and is worth its brittleness for these use-cases.)
- **Lead 20 min, severity --critical** (2026-07-22, Peter): court bookings page
  20m before start (travel to the club) at HIGH — a paid slot not to be missed.
- **Privacy**: snapshots (incl. other members' names) stored LOCALLY on pip only;
  any output/stats anonymised/aggregated; never published. (2026-07-22, Peter.)
- **Scope Padel only; capture full bookable horizon; poll every 5 min baseline**
  (2026-07-22, Peter). Politeness to a shared third-party server.

## Note for tooling

`strands new srfc` created `srfc` as a *symlink* to the aifabric template (its
`.template` is itself a symlink and `cp -r` copied the link, not contents) —
which briefly corrupted the shared template. Recreated srfc as a real dir with
`cp -rL`. **The `strands new` tool needs `cp -rL` (or a non-symlinked
`.template`)** — worth fixing in super/aifabric.
