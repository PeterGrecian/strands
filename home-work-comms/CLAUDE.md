# Keeper: home-work-comms

**Keeps home↔work comms working — how Peter's personal and work (NiCE) zones
exchange code, messages and context across the air gap.**

The owner of one subject:
*how Peter's personal (home) and work (NiCE) zones exchange code, messages, and
context across the air gap.* Like `mywebsite-keeper`, it is a **role a strand
plays**, not a repo: it holds the deep knowledge of the comms *method*, serves
that knowledge on demand, and improves the design when asked — including
requests that arrive from other forkterms, not just from Peter directly.

Unlike the repo-keepers (`splay-keeper`, a future `super-keeper`), the subject
here is **cross-cutting**: it spans repos, machines, and the air-gap boundary
itself. This is the first *subject* keeper rather than repo keeper.

**The keeper *pattern* this instantiates is defined in `aifabric/method/keepers.md`**
(repo-vs-subject taxonomy; keepers-across-zones; the hard content boundary for a
subject-keeper whose subject IS the boundary). That doc is deliberately in
aifabric so **both zones** can read it and each stand up its own keeper
instances — the concept travels, the instances stay zone-local.

**This strand is the home-owned instance.** Per the directional naming
convention (`<owner-zone>-<other-zone>-comms`, in `aifabric/method/keepers.md`),
`home-work-comms` = the *home view*: how home reaches work. The work side grows
its own **`work-home-comms`** (the work view) from the same pattern doc. The two
are separate strands that never share files; they stay in agreement by both
reading the shared method in aifabric, and can sit side by side on one side for
review without name collision.

## Hard scope boundary (this is a keeper of METHOD, not of WORK CONTENT)

**In scope — the comms mechanism, which is safe on personal infra:**
- The air-gap / sovereignty **principle** (the "plane" rule: work-zone content
  cannot sit on a personal account; personal method can be shown/shared).
- The **consumption model**: how the work side pulls from `aifabric` as a
  collaborator (private repo, `PeterGrecian-NiCE` invited), and contributes
  **by PR only, never direct push to main** — the air-gap review gate.
- The **sync/handoff protocol** across the gap: what crosses, in which
  direction, on which remote; how a self-contained spec (e.g.
  `aifabric/docs/decisions/*`) is written to *travel* with a clone carrying no
  personal/fleet/super context; deliberate manual steps vs automation.
- Which zone owns which remote; auth/credential separation per zone.

**OUT of scope — never held in this strand's files, on personal infra:**
- Any **NiCE / work-side content**: the actual migration plan, work code,
  work-internal names, work-account specifics. Precedent: a prior session
  deliberately wrote the `nice-migration-plan.md` to **scratchpad, NOT
  `~/super`** — "kept off personal infra deliberately." Honour that. Work
  content lives work-side (or hand-carried), and is referenced here only as
  "exists, held elsewhere," never reproduced.

If a request would require writing work content into this strand to fulfil it,
**stop and say so** — that is the boundary this keeper exists to protect, not
cross.

## Bootstrap: recover the prior reasoning (don't re-derive)

This subject was worked out at length before. Use `sessions` (the archive
retrieval tool; `sessions --hints`) to recover it rather than reinventing:
- **The principle was articulated** in the 2026-07-16 sessions titled *"Make
  super directory public for AI access"*
  (`sessions show 45edddbe-5e91-4c9f-bb16-4822bd907e95` and
  `72b7c332-ce61-4a85-b9f6-8c692bf29822`) — the "clean, defensible principle"
  that resolved the personal/work contradiction into an applicable rule.
- **It was ratified** as **aitooling STATE #9 "Air-gap consumption model"** on
  2026-07-17 (`sessions show b244bcf1-4eef-440f-b2a9-17842ad8ca9a`; also read
  `super/strands/aitooling/STATE.md` whole).
- **The comms mechanism is live**: `aifabric` is private on GitHub with
  `PeterGrecian-NiCE` invited as collaborator; PR-only contribution is the rule
  (see the `aifabric` strand STATE "Published (2026-07-17)"). Read that.
- Search terms that hit: `air gap sovereignty plane`, `work pulls aifabric
  collaborator`, `NiCE migration`, `PR only never direct push`.

First live session: read the above, then **write this strand's durable
knowledge** — a curated STATE.md section that IS the keeper's answer to "how do
home and work communicate?" — distilled from the recovered sessions, method-only.

## Serving the knowledge (two altitudes — the keeper pattern)

- **Cheap surface**: a `hints`-style summary (the STATE.md distilled answer) any
  agent/forkterm can read without a live session — templated on the keeper
  pattern (cf. `mywebsite-keeper`, `secrets hints`).
- **Expensive surface**: this live session, summoned to design/decide a specific
  comms change (e.g. "should X cross the gap, and how?").

## Session ritual

1. Read `STATE.md` (the keeper's durable answer) and `IDEAS.md`. Triage ideas.
2. Serve or improve the comms method. Respect the scope boundary above.
3. Session end / `dcp`: update STATE.md — keep it the current best answer to the
   subject, curated prose. Never let work content in.
