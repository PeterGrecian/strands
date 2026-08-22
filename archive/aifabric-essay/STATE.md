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

## Skills — a third instrument (2026-08-16)

Peter asked how strands and skills relate, and whether to write `SKILL.md`s. The
answer became both a new essay strand and the estate's first four skills.

**The distinction:** strands and skills both answer *context is the scarce
resource*, but attack different halves — a strand amortises **state** (don't
re-derive where you got to), a skill amortises **procedure** (don't re-derive how
it's done). *A strand is a noun with history; a skill is a verb without one.* If
it needs to know what happened last time, it's a strand. The cost asymmetry is
the argument: a skill loads **on demand**, so it costs nothing in sessions that
don't need it, where a strand's CLAUDE.md is paid in full at every launch.
Anything always-loaded that only matters occasionally is **a procedure paying
rent as state** — the main thesis applied to *instructions* rather than sessions.

**Peter's sharpening:** a house tool is a **two-layer artifact** — the
deterministic layer (the script) and the judgement layer (when to invoke it, in
what order, what *not* to do instead). So the house-tool convention is both a
skill *and* a source of skills. The skill is **the residue that doesn't fit in
`--help`**; judge candidates by that ratio, not by tool importance.

**Built** (in `~/dotfiles/.claude/skills/`, symlinked — whole-repo `stow` aborts
on pre-existing conflicts): `house-tools`, `dcp`, `strand-ideas`,
`compute-follows-the-data`. See the `house-tool-skills` memory for mechanics.

## Pending / loose ends

- [ ] Reconcile with the work-side draft (does it exist? where? git or local?).
- [ ] Decide deliverable location + format (`aifabric/essay/`? single doc?).
- [ ] Draft Part 1 (the *what*) — inventory the method's actual pieces from
      `aifabric` rather than re-describing from memory.
- [ ] Draft Part 2 (the *why*) — build from the thesis skeleton above.
- [ ] Write the skills section into Part 2 — three spooled ideas hold the
      material (`Mx2GF3` two-layers, `uMIrNm` frictionless-wrong-path, plus the
      trigger-design notes). Strongest new material in the strand.
- [ ] **Strip GLOBAL.md.** The four skills currently *duplicate* rules that are
      still always-loaded, so the win is unrealised — the payoff is deleting the
      always-loaded copies. Needs Peter's call on what stays always-loaded
      (fleet topology, cost rules) vs on-demand. This is itself essay material:
      the refactor is the thesis in action.
- [ ] Build `oncompute <path> -- <cmd>` (spec in `uMIrNm`) — removes the friction
      asymmetry rather than relying on a rule firing.

## Decisions

- 2026-08-01: this is its own strand, deliberately above the tool-owning
  `aifabric` strand and distinct from `ubersitrep`. It owns the *argued prose*;
  the others own the tools and the live-state narrative respectively.
- 2026-08-16: skills are a **third instrument** alongside strands and tools, and
  belong in the essay's argument — not merely a Claude Code feature note. Three
  transferable rules came out of building them, each learned by getting it wrong
  first:
  - **Trigger on Peter's actual phrasing.** `strand-ideas` missed "tell super
    that X"; he had to type "use idea to…" to compensate. *The signal that a
    description is wrong is the human working around it* — not outright failure.
  - **Trigger on what is visible at write-time, not knowable only at run-time.**
    The compute rule began as "jobs over ~1 min", which cannot fire: duration is
    discovered at second 90, when the laptop is already hot. Data locality (a
    path under `/mnt/<host>/`) is visible in the command before it runs.
  - **Name a skill after the principle, not the tool.** Peter said "use
    cpuworker", but that tool is deprecated and does the opposite;
    `compute-follows-the-data` survives the tool being replaced.
- 2026-08-16: **a convention broken constantly is competing with an easier wrong
  path**, not failing on discipline. The NFS automounts make the wrong path
  frictionless *and invisible*, so there is no moment of decision at which a rule
  could apply. Fix with a mechanically-visible trigger or by removing the
  asymmetry — never with a louder always-loaded rule. This is the strongest
  single argument the strand has acquired, because it explains *why* the
  always-loaded one-liner style fails on its own terms.
- 2026-08-16: **the best skill is one never invoked by name.** A skill that only
  works via `/name` has pushed retrieval cost back onto the human, which is what
  the always-loaded file was already doing badly. Description-matching is the
  point; the slash is the fallback.
