---
name: delivery-must-be-a-real-alarm
description: For calendaralarm, a message (Slack/xMatters) is NOT an alarm — the phone's audible dismiss-requiring alarm is what actually works; aim delivery there
metadata:
  type: project
---

**calendaralarm's delivery target was wrong.** On 2026-07-22 the real "Afternoon
meeting" rule fired and reached Peter via Slack (`--warn` = Slack + xMatters
MEDIUM). His verdict: *"my alarms was much more effective."* Why the phone alarm
beats a Slack/xMatters message, in his words: **it made noise, it demanded
action (you must actively dismiss it), and it was in his hand.** A notification —
even to xMatters — is a passive banner; a phone alarm is an *alarm*.

**Decision (Peter, 2026-07-22):** the default delivery for an authored alarm
should be **a real phone alarm** — investigate driving an actual audible,
dismiss-requiring alarm on the phone (push + sound), not just a message. This
**reopens the strand's original "alarms go to xMatters, no custom app" framing**
(see calendaralarm/CLAUDE.md): xMatters solved *escalation/acknowledgement on the
fleet*, but it did not deliver the phone-alarm experience that actually stops him
missing things.

**BUT keep xMatters too — it has a second purpose (Peter, 2026-07-22):** routing
real alarms through xMatters is a **live test of his work xMatters settings** —
the on-call config that must actually work when he's paged for the job. Every
calendaralarm that fires via xMatters is a free canary that his escalation path
is configured correctly. The phone alarm doesn't give him that.

So phone alarm and xMatters are **not competitors** — different ends:
- **Phone alarm** = the *effective* delivery (noise, demands dismissal, in-hand,
  and **snoozable** — a snooze button is a required behaviour).
- **xMatters** = kept for TWO reasons (Peter, 2026-07-22): (a) *canary* — firing
  real alarms through it continuously tests his work on-call settings; (b) a way
  to **understand how xMatters works** — a live sandbox for learning the tool.

**"Severity" is out (Peter, 2026-07-22):** he doesn't think in info/warn/critical
tiers — that's engineering jargon. Don't surface severity in the authoring UI.
Delivery channel is a per-alarm choice; the loudness/urgency is implied by the
channel, not a separate severity field.

**How to apply:**
- Treat "send a message" and "raise an alarm" as different deliverables — the
  project wants the second for effectiveness, AND xMatters for the canary value.
- Design delivery as **per-alarm channel choice** (phone alarm / xMatters / both
  / Slack-soft), not one global target. Some alarms want the loud phone alarm;
  some (or the same ones) also want to exercise xMatters.
- Explore real phone-alarm delivery: high-priority push that plays a sound and
  needs dismissal (Android full-screen intent / small companion app / push
  service), not just a message. Revisit whether a custom app is back on the table.
- This is a bigger design lever than the schedule model — surface it as THE
  open question in the design spec.

Related: [[drain-mailbox-after-fork]]
