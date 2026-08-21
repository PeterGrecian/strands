# Strand: spend

**Keeps every recurring bill in view — what we pay, to whom, for what, and
whether it is still earning its place.**

The estate spends money in more places than any one strand can see. GLOBAL.md
names *three billed providers* (AWS, GCP, Cloudflare) and gives the rule —
estimate before you spend, check the consoles at session start and end — but
until this strand existed **no one owned the rule**. The gate proved it twice:
*"how much is R2 costing"* returned no candidate at all (ubersitrep STATE,
2026-08-14), and *"the Chromebook Gemini + storage offer"* mis-routed to
`astro-storage` on the word *storage* (2026-08-18). Two sightings of one hole.

## What it owns

- **The cloud providers** — AWS (Lambda, DynamoDB, S3, API Gateway, SSM), GCP
  (Compute Engine, GCS incl. `petergrecian-secrets`), Cloudflare (DNS, WAF,
  Pages, R2). What each actually costs per month, what the free-tier floor is,
  and which line items are drifting.
- **Consumer and per-seat subscriptions** — Google One / AI Premium, Anthropic,
  and anything else billed monthly to a personal account rather than a project.
  These are invisible to every cloud console, which is exactly why they belong
  somewhere.
- **Offers, trials and their expiry dates.** A bundled trial is a future bill
  with a date on it. Trials that lapse into paid subscriptions are the estate's
  most likely silent cost.
- **The judgement, not just the ledger:** is this line still worth paying for?
  What would it cost to leave? What is the cheapest thing that would do?

## What it does NOT own

- **Storage lifecycle and retention policy** — `astro-storage`'s. This strand
  cares what a byte *costs*; astro-storage decides which bytes exist and for how
  long. Expect to hand work sideways often.
- **Archive mechanism** — `glacier-app` owns Deep Archive photo archiving.
- **Provisioning** — spinning a VM up or down is `hardware` / the relevant
  strand's; the auto-shutdown *rule* is GLOBAL.md's and enforced everywhere.
- **Usage observability for Claude itself** — `cleft` / `cleft-plus`.

The boundary is: **this strand owns the bill; other strands own the thing being
billed for.** A finding here usually becomes a request there.

## Repos and surfaces it spans

No repo of its own yet. It reads consoles (AWS Cost Explorer, GCP Billing for
`petergrecian-personal`, the Cloudflare dashboard, one.google.com) and the cost
conventions in `super/GLOBAL.md`. If it grows a tool, that tool belongs in
`aifabric/bin` or `super/bin` by the usual rule, not here.

## Session ritual

1. Import spooled ideas with `idea --import`, then read `STATE.md` and
   `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir holds
   only curation files.
4. **Before quoting a number, check it.** A remembered cost is a stale cost;
   this strand's whole value is being the place where the figure is current.
5. Session end (or on `dcp`): update STATE.md — what changed, what is pending,
   decisions made. Curated prose, not a log.
