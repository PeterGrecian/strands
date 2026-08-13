---
register: house
date: 2026-08-13
kind: handling-convention
---

# Delimiters point at wording, not at spelling

## Before (the implicit rule Claude was following)

> Text inside `"…"` or `_italics_` is deliberate character-for-character —
> preserve it verbatim.

## After (Peter's correction)

> The delimiter marks **which words** he means. It asserts nothing about the
> letters inside. He can and does put a misspelling inside either without
> noticing.

## Why

Peter: he uses quotes to point at specific wording, and italics for emphasis
*or* to signal that reading between the lines is appropriate — and is "quite
capable of putting a misspelling inside both delimitations and not be aware of
it".

Two claims were being collapsed into one. *This wording is deliberate* and
*these characters are as intended* are separate, and only the first is carried
by a delimiter. The naive verbatim rule would enshrine a typo in a decision
record precisely where the wording is load-bearing.

Live instance the same session: `"considdered_prose"` was proposed in quotes as
a strand name. The quotes meant *this word, consider it* — not *these eleven
characters*. Scaffolded as `considered-prose` (spelling normalised, and
underscore → hyphen to match every other strand in the estate).

**The rule:** normalise inside delimiters; quote his rulings corrected, because
the choice of word is his and the orthography is not the point.

**Also noted:** the implicature use of italics — an invitation to infer
something unstated — is distinct from emphasis and is the one to slow down on.
Flattening it into plain emphasis loses what he meant.

## Estate consequence

Decision records inherit typos through quotation. STATE files carry many
verbatim rulings which propagate into commits, blurbs, and eventually public
repos. **Correct on capture, not on export** — by export time a phrase has been
copied five places and only one gets fixed.
