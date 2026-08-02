# How to write a strand blurb

*Blurb-writing philosophy, owned by **ubersitrep** (its whole-estate-picture
charter — the blurbs are the estate's one-line map). This is the how-to, not a
registry: each blurb lives in its own strand's CLAUDE.md opener (single source of
truth). The live view is `aicli` with no args. Written 2026-08-02.*

## What a blurb is

A blurb is the strand's one-line answer to *"what is this, and why would I care?"*
It's what the `aicli` listing shows next to the strand name, and the first thing a
fresh session (or Peter, weeks later) reads to orient. A **1-liner** followed by a
**paragraph**: the 1-liner is the map pin; the paragraph is the detail.

## The rules

**1. The first ~40 characters are the crucial ones.** The listing column is
narrow — it truncates around 40 chars. Whatever matters must be at the *front*.
This single fact drives most of the other rules.

**2. Say the non-obvious thing — never restate the name.** The reader already
sees the strand name. "The über-sitrep — the top-level situation report" is dead
weight (übersitrep already means that). Lead with what the name *doesn't* tell
you: the job, the stakes, the TWIMC ("to whom it may concern").

**3. No category-label prefix.** "Recurring workstream:", "Mission:", "Role:",
"Placeholder" — all waste the crucial front chars restating a *type*. Cut them.
The blurb states content, not classification.

**4. Verb choice encodes the strand KIND — and must earn its chars:**
- **Keeper strands → start with "Keeps …".** A keeper is a steady-state
  custodian; "keeping X" genuinely differs from "X" (ongoing custody vs the
  thing), so the verb carries real meaning and earns its place. Keepers hold a
  stable spec + metrics; their STATE changes sparingly.
- **Development strands → DROP the verb; lead with the OBJECT.** "Builds / Works
  out / Makes / Writes" is superfluous — a development strand obviously *makes*
  its thing, so the verb only burns the crucial first ~7–8 chars. Start with the
  thing itself. The *absence* of "Keeps" is what signals "development".

**5. One line, then a paragraph.** Line 1 is the ≤40-crucial one-liner (it must
stand alone — the listing shows only this). Then a blank line, then a paragraph
of detail (shown by `aicli --blurb`, and as the CLAUDE.md opener). Keep line 1
tight; put spans, repos, and nuance in the paragraph.

**6. A dash-clause after the pin is good.** "X — the concrete detail" reads well:
the pin lands in the first clause, the "—" hands off to specifics. Just make sure
the pin (before the dash) is the ≤40-char part that survives truncation.

## Worked examples

| Before (bad) | After (good) | Why |
|---|---|---|
| The über-sitrep — the top-level situation report | Keeps the whole-estate picture — where everything is and where it's going | restated the name → says the job |
| Recurring workstream: a Pico W power-cycle rig… | Keeps the Canon EOS 2000D power-cyclable — a Pico W rig… | dropped the label prefix, keeper verb |
| Mission: apply and maintain configuration… | Keeps fleet configuration applied and current… | dropped "Mission:", keeper verb front |
| Builds a silent laser-cut home-server enclosure… | A silent laser-cut home-server enclosure — flat finger-jointed panels… | dev strand → drop "Builds", lead with the object |
| Builds RA/Dec graticule and star-name overlays… | RA/Dec graticule and star-name overlays on astro frames… | dev → object-first; "RA/Dec" is in the crucial 40 |

## The mechanics (how the listing finds a blurb)

`aicli`'s `strand_blurb()` reads, in order:
1. **`<strand>/blurb`** if that file exists — line 1 is the listing summary; the
   rest is the `--blurb` detail. (A dedicated file, if you want to decouple the
   blurb from the doc body.)
2. **otherwise the CLAUDE.md opener** — the first paragraph after the `#` heading,
   up to the first blank line, with `**bold**`/`` `code` `` stripped and lines
   beginning `*(` skipped (so a `*(provisional…)*` note is invisible to the
   listing but stays in the file).

Today no strand carries a `blurb` file, so **the CLAUDE.md opener IS the blurb** —
write line 1 of the opener as the ≤40-crucial one-liner, blank line, then the
paragraph, and the listing picks it up automatically.

## Keeper vs development — the deeper distinction

The verb rule (4) rests on the strand-kind taxonomy (theory owned by the
`strands` strand): **keepers** are steady-state custodians (cadence visits,
sparse STATE, defined metrics); **development** strands progress a task to done
(moving-frontier STATE every session). A blurb's opening verb is the quickest
public signal of which kind a strand is — so getting it right is part of keeping
the estate legible, not just cosmetic.
