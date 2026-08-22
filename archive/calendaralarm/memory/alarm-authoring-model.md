---
name: alarm-authoring-model
description: calendaralarm authoring UI — radio buttons for schedule type (one-off/weekly/days-of-week/complicated), real cases, snooze required, no severity
metadata:
  type: project
---

How Peter wants to *author* an alarm (2026-07-22) — this overrides my earlier
"severity + schedule kinds" abstraction:

**The primary control is a radio-button pick of schedule type:**
- **one-off** — a single date+time (e.g. *dentist*).
- **weekly** — **every 7 days** from a start date (may drift off a fixed
  weekday). Distinct from days-of-week.
- **days of week** — a named-day set, e.g. Mon+Wed+Fri (e.g. *running club*,
  *morning wakeup* = daily set).
- **"it's complicated"** — the catch-all for irregular patterns.

**Real alarms that must be expressible:** dentist (one-off), running club,
morning wakeup (daily), **padel mix rotation** (the "complicated" case).

**Padel rotation, CONFIRMED (Peter, 2026-07-22):** 3 groups play 1 hour each,
back-to-back, on a fixed weekday (session e.g. 18:00–21:00 = slots
18:00/19:00/20:00). The group order rotates weekly, so *his* start-time advances
one slot each week and wraps after 3 weeks. It's **computable from an anchor** —
no manual/email step. Model it as:
  { kind: "rotation", weekday, slots: ["18:00","19:00","20:00"],
    anchor_date, anchor_slot_index, cycle: len(slots), direction: +1 }
Given anchor (e.g. 2026-07-28 → slot 1 = 19:30), every future week's slot is
`(anchor_slot + weeks_since_anchor) % 3`. Alarm fires a lead before his slot.
This is the general "rotation" schedule kind — good template for other rotating
patterns.

**Real values (2026-07-22/23):** slots are **18:30 / 19:30 / 20:30** (this week
advanced / intermediates / beginners respectively). Peter is **intermediates** →
19:30 this week (anchor_slot 1). Still OPEN: **which weekday** padel mix is on
(he said "different day" — NOT Tuesday, which I'd assumed) and the **lead time**.
Ask next session before building the padel alarm.

**A snooze button is required** — when an alarm fires it must be snoozable, like
a phone alarm. This is a delivery/interaction requirement the message channels
(Slack/xMatters) can't do; it pushes toward real phone-alarm delivery
([[delivery-must-be-a-real-alarm]]).

**No "severity"** — dropped from the authoring UI (see
[[delivery-must-be-a-real-alarm]]); he doesn't think in tiers.

**How to apply:** the webapp "new alarm" form leads with these radios; each
reveals the right fields (date picker / start-date / day checkboxes / the
complicated editor). Natural-language entry compiles to the same records. Keep
the stored schedule model extensible enough to hold whatever "rotation" turns
out to be.
