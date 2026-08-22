# Strand: aifabric-essay

**The wisdom half of the aifabric story — the argued case for *how and why* to
use AI well, as CV evidence.**

The argued, transferable account
of *how and why* to use AI well. This strand's job is prose, not tooling
(that's `aifabric`) and not live state (that's the other strands).

**Purpose: this is CV material.** Peter is job-hunting for *"wise AI"* work —
practical, better use of AI via aifabric and sophisticated methods. The essay
is **evidence for a claim about the author**: someone who treats AI as a
scarce-context optimisation problem and has built a working method around it.
So the reader is a **hiring reader who was not in the room** — the wisdom has
to be legible to them, not just true.

## Two artifacts, one CV

There are two halves, in two places, feeding one goal:

1. **The *usage* — the work draft (lives at work).** The record of aifabric
   actually being used: the practical, evidentiary side. *What was done.* This
   is the evidence base. It exists (or is started) on Peter's **work machine**,
   not committed to this repo / not on this LAN's `sessions` archive.

2. **The *wisdom* — this strand's deliverable.** The sophisticated account of
   *why* the usage is wise: the thesis the evidence supports. Not a feature
   list — an argument. The through-line (as framed 2026-08-01):
   - **Context is the scarce resource**, not compute or tokens-in-the-abstract.
   - **The main working session is irreplaceable; everything else is
     disposable** (fork windows, scratch dirs, OpenSearch docs, subagents).
   - **Push every expensive operation** (searching, summarising, babysitting a
     delegate, exploring a tangent) **out of the irreplaceable session and into
     something throwaway.** Pay once in the disposable place, not every time in
     the precious place.
   - **Non-naive ≠ "use the fancy tool."** It's *matching the cost of the
     machinery to the value of what it produces* — `/compact` at a
     never-continued dead-end is waste; warm-forking when a cold launch + a
     `sessions` seed would do is waste. The conditional — *when is the clever
     move actually the cheap move* — is the whole argument.

The wisdom justifies the usage: it shows the mechanics are a coherent strategy,
not a bag of gadgets — which is exactly the claim a hiring reader is weighing.
Draw concrete instances from the other strands (`dispatch` = coordination tax;
`aifabric-sessions` digest = retrieval cost; the strand ledger's
least-recently-reviewed rotation) — the usage draft is the proof, the wisdom is
the interpretation.

## Relationship to the other strands

- **`aifabric`** owns the *method and its tools* (the canonical portfolio).
  This strand cites it; it does not duplicate it.
- **`ubersitrep`** holds the *narrative across live workstreams*; this strand
  holds the *argued essay about the method itself*. Different altitude.
- Reuse the `sessions` archive as primary source — the real examples of the
  method working (or failing naively) are in the transcripts.

## Session ritual

1. Import spooled ideas with `idea --import`, then read
   `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
