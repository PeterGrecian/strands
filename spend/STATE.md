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
