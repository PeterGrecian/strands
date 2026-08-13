# Strand: considered-prose

**Keeps house voice improving by capture — proposed wording, Peter's edit, the
diff stored, so the next suggestion is better.**

Prose that has been *weighed* — where someone stopped and chose. This strand
owns the choosing, not any one deliverable.

The mechanism is a loop, going forward: **Claude proposes wording → Peter edits
it → the pair is captured**. Accumulated pairs make the next proposal better,
few-shot rather than fine-tuned. The cost is near zero because Peter edits the
wording anyway; the only new work is *not letting the edit evaporate*.

**Not a style guide.** A guide is read once and violated by whoever is actually
writing, and design docs are a write-mostly graveyard. The corpus is primary;
a stated rule is an optional summary extracted only when a pattern recurs often
enough to earn one. This mirrors the estate-wide call that evidence beats
declaration (cf. [[ubersitrep]]'s keeper roster: derived, not declared).

## What goes in a pair

`pairs/<timestamp>-<slug>.md` — before, after, and **why**.

The capture test: **did the meaning survive while the wording changed?**

- **Meaning survived, wording changed** → a taste ruling. **Capture it.**
- **The after is more *correct*** (fact wrong, mind changed, audience shifted)
  → an edit, not a style signal. **Do not capture** — it would teach something
  false.
- **Spelling/orthography** → never a pair. Peter is dyslexic; spelling in
  identifiers is normalised silently and is not a style judgement. See the
  `peter-is-dyslexic` memory.

Tag each pair with its **register** — `export` (essay, CV, README, public
repos: audience is a stranger, failure mode is insider shorthand) or `house`
(STATE, blurbs, commits: audience is Peter or a future session, failure mode is
verbosity and log-not-prose). The registers want opposite advice in places, so
an untagged corpus is two voices with no way to separate them.

A pair without a *why* is still worth keeping, but it is weaker evidence — only
Peter knows why some edits happened, so ask when it is not obvious.

## Capture ritual

Deliberately low-tech, because a mechanism with ceremony gets used twice and
stops. **When Peter rewords something and it matters, he says so; Claude spools
the pair.** No tool yet. If volume justifies one it belongs in `aifabric/bin`
(theory/practice boundary — the tool is practice), not here.

Capture at the moment of the edit. Retrospective capture does not happen — the
roster learned this lesson the hard way (derived ad hoc, used, evaporated).

## Seeded from live work, never from git archaeology

Do **not** mine old diffs for pairs. Reconstructing intent from a blurb rewrite
whose reasoning is gone encodes Claude's guess at Peter's taste as if it were
Peter's taste. Every pair must have known provenance: proposed X, edited to Y,
in a context both remember.

## Two pairs banked before the strand existed (2026-08-13)

Both are handling conventions rather than sentence craft — expect more of that
category than expected:

1. **Quote a deliberate ruling; paraphrase an aside.** A quoted line in a
   durable record becomes the canonical phrasing. Peter's wry aside about
   dyslexia was quoted as evidence in a memory and pulled — the fact stood
   without it. Quote when the *wording is the decision* ("driver, not
   conductor"); paraphrase when the wording was just how a fact arrived.
2. **Delimiters point at wording, not at spelling.** `"…"` and `_italics_` mark
   *which words* Peter means; they assert nothing about the letters inside.
   Normalise inside them; quote his rulings corrected. Never enshrine a typo
   because it arrived in quotes.

**Estate consequence:** decision records inherit typos through quotation. STATE
files carry many verbatim rulings, which then propagate into commits, blurbs,
and eventually public repos. **Correct on capture, not on export** — by export
time a phrase has been copied five places and only one gets fixed.

## Kind

**Keeper**, unusually clearly: it defends a context and refines a remit, with no
frontier to march toward. It has no builder phase — the corpus starts empty and
the strand is steady-state on day one. Any build work (a capture tool) belongs
to `aifabric`.

## Session ritual

1. Read `STATE.md` and `IDEAS.md`; drain the mailbox.
2. Capture pairs as they arise — that is the work, not a side-effect.
3. Periodically re-read the corpus: has a pattern recurred enough to state as a
   rule? If so, write it *as a caption over its pairs*, never freestanding.
4. On `dcp`: update STATE.md with what the corpus is learning, not a log of it.
