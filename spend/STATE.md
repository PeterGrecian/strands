# spend — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Founded 2026-08-18 — as a missing keeper, on the second sighting

Scaffolded by `ubersitrep` (the gate), not by a session that needed it. The
trigger: Peter asked about the **Chromebook Plus / Gemini / storage offer**, and
`to-whom` returned `astro-storage` **[13]** — matched on the word *storage*, and
wrong. That is the second time the gate has come up empty on money: *"how much is
R2 costing"* returned **no candidate at all** on 2026-08-14 (ubersitrep STATE).

Two independent mis-routes on the same subject is the missing-keeper signal
ubersitrep's brief says to watch for — a subject that recurs and that every
blurb says is someone else's job. Hence a keeper from day one rather than the
usual builder start: the subject is bounded and steady-state, and it exists to
*serve answers* ("what does X cost us, and is it worth it").

**Scope ruled by Peter at founding:** the offer is **account-level, not
device-level** — *"I think I can use it on my phone too. And pip."* That is
correct for Google One AI Premium (Gemini Advanced in the app on Android, at
gemini.google.com from any machine, and the 2 TB is account-wide Drive quota, so
the `~/gdrive` rclone mount inherits it). So the Chromebook is only how the offer
*arrived*; it is not what the offer is *about*. That ruling killed the narrow
`chromebook` framing and set this strand's remit at **the bill, not the device**.

## What exists

- `CLAUDE.md` mission, `blurb`, `colour` (`8f4700`), `dirs` (`~/super`).
- Nothing measured yet. **No figure in this strand has been checked against a
  console.** Every cost below is inherited from `GLOBAL.md`, not verified.

## Pending / loose ends

1. **First work unit: the Chromebook Plus / Google One offer** — spooled to
   `ideas/`. What exactly is bundled, what it is worth, what it costs when the
   trial lapses, and whether the 2 TB changes any archive thinking.
   **⏰ Assumed expiry 2027-08-18** (Peter, at founding, on a 12-month trial —
   **confirm the actual date at one.google.com**; it is the single most
   load-bearing unverified fact in this strand).
2. **The R2 question that went unanswered on 08-14** — *how much is R2 costing?*
   Still unanswered. It is now this strand's, and it is the cheapest possible
   proof the strand works.
3. **A first real pass over all three consoles.** AWS Cost Explorer, GCP Billing
   (`petergrecian-personal`), Cloudflare. GLOBAL.md says to check them at the
   start and end of any session that spins up cloud resources; nobody has owned
   whether that actually happens.
4. **Find the subscriptions nobody is looking at.** Anything billing monthly to a
   personal account is invisible to every cloud console — that is the class of
   cost most likely to be silently running.
5. **Does this want a tool?** A re-runnable cost reader that emits a file would
   fit the estate's grain (derivation observes, Peter judges — ubersitrep STATE,
   2026-08-13). Do the manual pass first; the manual version teaches what to
   automate. Any such tool lives in `aifabric/bin` or `super/bin`, not here.

## Decisions

- **2026-08-18 — remit is the bill, not the thing billed for.** This strand owns
  what a line costs and whether it is worth paying. The strand that owns the
  underlying thing owns the fix: retention → `astro-storage`, archive →
  `glacier-app`, machines → `hardware`, Claude usage → `cleft-plus`. A finding
  here normally becomes a request there.
- **2026-08-18 — free storage is a deferred deletion obligation, and that is the
  price.** Peter, seeing it immediately: *"I would have to systematically delete
  from gdrive leading up to 18/8/2027."* Correct — grow into the 2 TB and the
  exit is either a triage job against a hard deadline (back under **15 GB across
  Gmail + Drive + Photos combined**, and Photos is the one people forget) or a
  subscription you are now locked into. Over-quota is not data loss on day one
  but it is severe: reads work, **uploads and Gmail delivery stop**, and content
  is at risk after a sustained period.
  **RULE that dissolves the obligation: nothing may live in gdrive that does not
  live somewhere else too.** Use the 2 TB only as a *second* copy of data whose
  primary is on bigstore / S3 / R2. Then lapsing costs nothing — delete the whole
  mirror in one action, no triage, no deadline. The trap only closes if something
  becomes unique there. Note this is the same conclusion the astro-backup
  question reached from the other side (fine as redundancy, wrong as a tier), and
  it **generalises past this offer** — it is the right posture toward any free
  storage tier the estate is ever given.
- **2026-08-18 — the offer has a REAL use, and it is disaster recovery.** Peter
  named the scenario: *"bigstore breaks and I lose all the data… until next
  spring it would be useful."* Checking `astro-storage`'s redundancy ledger
  (snapshot 2026-07-31) sharpened it and **corrected the framing above**: only
  **20 of 135 nights are < 2.0 weighted copies** — 115 already survive bigstore
  dying. So the ask is not a 1.5 TB mirror, it is **a second copy for ~20 nights,
  roughly 300–400 GB** — which is a goal astro-storage had already stated and was
  waiting on space for. That is a much better fit than the tiered-storage use I
  argued against, and the difference came entirely from reading the ledger rather
  than reasoning about the volume.
- **2026-08-18 — the value window closes BEFORE the obligation, and that
  dissolves the deletion worry.** Value ends ~spring 2027; trial expiry
  ~2027-08-18. Four to five months of slack, so the exit is one `rclone purge`
  of one directory, not the systematic triage Peter was picturing. If diminishing
  returns have *not* arrived by spring it becomes a **dated decision** — pay
  ~£8/mo or fall back to Glacier — not a trap. **⏰ Put a spring 2027 review
  somewhere it will fire.**
- **2026-08-18 — Drive competes with Glacier, not with nothing, and the honest
  advantage is RESTORE cost.** astro-storage already ships to Deep Archive
  (`astro-berrylands-eu-west-1`), which holds 400 GB for well under $1/month — so
  on pure storage price Drive wins nothing, and if those 20 nights still lack a
  second copy the blocker is almost certainly **effort, not cost**. What Drive
  genuinely adds: pulling 400 GB back out of Deep Archive is **~$36 in egress
  plus a ~12 h wait**; out of Drive it is **£0 and immediate**. For the copy you
  would actually reach for in a disaster that is a real difference — and it is
  the first case found where a consumer subscription beats the cloud path on
  something that matters. *(Both figures need checking against live pricing
  before anyone acts on them.)*
- **2026-08-18 — consumer subscriptions are in scope, not just cloud.** They are
  the ones no console shows. GLOBAL.md's "three billed providers" table
  undercounts for exactly this reason.
- **2026-08-18 — Google One ≠ GCP, and the distinction is load-bearing.** Same
  Google identity, separate billing relationship: Google One AI Premium is a
  consumer subscription (one.google.com); GCP is project
  `petergrecian-personal` (console.cloud.google.com). Two further conflations to
  keep straight: **Drive ≠ GCS** (Drive is consumer sync — no S3 API, no
  lifecycle rules, no Coldline tier, so it is not somewhere astro raw can live
  under astro-storage's invariants), and **the Gemini app ≠ the Gemini API**
  (the offer bundles the consumer app; AI Studio / Vertex usage bills through
  GCP and no API credit comes with it).
