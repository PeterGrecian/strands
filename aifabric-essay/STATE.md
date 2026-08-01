# aifabric-essay — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- Strand scaffolded 2026-08-01 (from `ubersitrep`, discussing non-naive AI
  usage). See `CLAUDE.md`.
- **Purpose is CV material.** Peter is job-hunting for "wise AI" work. The
  essay is evidence for a claim about him — practical, sophisticated use of AI
  via aifabric. Reader = a hiring reader who was not in the room.
- **Two halves, two places:**
  - *Usage* (the evidence) = the **work draft**, on Peter's work machine — the
    record of aifabric actually being used. Not in this repo / not on this LAN.
  - *Wisdom* (the thesis) = **this strand's deliverable** — why the usage is
    wise. This is what gets written here.
- The two are complementary, not a fork to reconcile: usage = proof, wisdom =
  interpretation. But the wisdom should stay honest to what the usage draft
  actually shows — pull the real examples from it, don't invent flattering ones.

## The thesis (Part 2 skeleton — captured 2026-08-01)

The single principle: **push cost to where it's disposable; keep the
irreplaceable context lean — and only when the payoff justifies it.**

- Context is the scarce resource (not compute, not tokens in the abstract).
- The main working session is irreplaceable; forks/scratch dirs/OpenSearch
  docs/subagents are disposable. Route expensive ops out of the former into the
  latter. *Pay once in the disposable place, not every time in the precious one.*
- Non-naive ≠ "use the fancy tool" — it's matching machinery cost to output
  value. Counter-examples that keep the argument honest: `/compact` at a
  never-continued session; warm-forking when cold + a `sessions` seed suffices;
  digesting throwaway sessions.

Worked instances to cite (all live in sibling strands):
- `dispatch` — the coordination tax; three lanes route cost off the parent
  (`aifabric/docs/decisions/dispatch.md`).
- session-digest idea — attacks *retrieval* cost, not storage; pay at
  ingest-time so retrieval-time is cheap (`aifabric-sessions`, idea spooled
  2026-08-01).
- strand ledger — least-recently-reviewed rotation; scratch strands kept out of
  it so the signal stays clean.

## Pending / loose ends

- [ ] Reconcile with the work-side draft (does it exist? where? git or local?).
- [ ] Decide deliverable location + format (`aifabric/essay/`? single doc?).
- [ ] Draft Part 1 (the *what*) — inventory the method's actual pieces from
      `aifabric` rather than re-describing from memory.
- [ ] Draft Part 2 (the *why*) — build from the thesis skeleton above.

## Decisions

- 2026-08-01: this is its own strand, deliberately above the tool-owning
  `aifabric` strand and distinct from `ubersitrep`. It owns the *argued prose*;
  the others own the tools and the live-state narrative respectively.
