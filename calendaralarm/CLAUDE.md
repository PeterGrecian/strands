# Strand: calendaralarm

**Makes calendar events fire an un-ignorable alarm — one that takes active
effort to silence, via the phone app + xMatters bridge.**

Make calendar events fire an **un-ignorable alarm** — one that takes active
effort to silence — to stop important appointments being missed. The original
problem (Google/clock reminders are too easy to swipe away) still stands; what
changed is the *delivery mechanism*:

**The alarms go to xMatters.** That's the whole reframe. xMatters is the house
escalation channel that already demands acknowledgement — it's exactly the
"can't be dismissed with a flick" alarm the project always wanted, and it's
already built and wired into the fleet via `super/bin/alert` (Slack + xMatters
by severity: `--xinfo` LOW, `--warn` MEDIUM, `--critical` HIGH). So the hard
part — an alarm you can't ignore — is solved; calendaralarm becomes the thin
bridge that decides *which* events are worth escalating and fires `alert`.

Shape: **calendar reader → imminence/importance decision → `alert --critical`.**
The reader already exists (`~/calendaralarm/upcoming.py`, Google Calendar API
via OAuth). The missing middle is the "what's imminent and important enough to
page me" logic and the scheduler that runs it.

## Repos it spans

- **`~/calendaralarm`** — the deliverable. `upcoming.py` (working GCal reader),
  a leftover `CronAlarmApp.zip` (old Android attempt — probably drop).
- **`super/bin/alert`** — the xMatters/Slack delivery (house tool; don't
  reinvent). See its header for severity presets.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to `~/calendaralarm` (or the relevant repo) — this strand
   dir holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's pending,
   decisions made. Keep it curated prose, not a log.
