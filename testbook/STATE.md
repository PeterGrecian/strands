# testbook — state

*Curated summary of where this strand is. Updated at the end of each session.*

## PIVOT — 2026-07-25: from print/web guide to an assisted sleep-listening app

Same session as the first review below. Peter wants to morph testbook a third
time — print → website → **app**. This is now the strand's forward direction;
the review below records where the *print* project got to (its content and
pipeline become seed material, not the deliverable).

### The vision

An **Android app** for people who listen to audiobook readings to fall asleep.
It solves four problems that ordinary players + a timer don't:

1. **Sleep-timer length** — no good fixed answer; too short = you wake to reset
   it, too long = hours wasted playing to an asleep listener.
2. **Wind-back-to-comprehension** — when you drift off and wake, find the last
   point you actually *took in*, without scrubbing around half-asleep.
3. **Synopsis** for complex works (Götterdämmerung; a dense novel).
4. **Interspersed reader notes** — Shakespeare et al. need glosses woven *into*
   the text at the right moments, not in a separate appendix.

### The core mechanic (Peter's design — this is the whole app)

**Rewind by narrative landmark, not by time.** On resume the app does *not* ask
"how many minutes back?" It asks **spoiler-safe comprehension questions** keyed
to plot beats you've already passed:

> "Did you get to where Bilbo meets the dwarves?" → tap **yes** → it asks about
> the *next* beat → the moment you tap **no / not sure**, playback resumes from
> the **start of that beat**.

A few-tap recognition walk back to the last thing you registered — fast, doable
half-asleep, no scrubbing. **Spoiler constraint is essential:** each prompt may
only describe a beat *behind* your furthest-heard position and must be a
*recognition* cue, never a *preview* of what's coming. So beats are walked
backward from the furthest point reached, and prompts are written to reveal
nothing ahead.

### The unifying data structure

Three of the four problems reduce to one thing: **a timeline of spoiler-safe
narrative landmarks, each with an audio timestamp.** The same beat list drives
comprehension-rewind (2), anchor points for interspersed notes (4), and the
synopsis (3). **This is exactly what testbook already is** — scenes with
track/time boundaries + synopsis + interspersed performer/plot notes. The print
guide is the first fully-authored title and the template for the per-work
authoring format. testbook content is reused, not discarded.

The fourth (timer length, 1) is solved by **history, not asking** — same
philosophy as the rewind. The comprehension-rewind already reveals, each night,
roughly where the listener stopped registering (the furthest beat *not* reached
on resume ≈ sleep onset). Logging that over several nights gives a personal
"you typically fade ~18–25 min in" estimate — per title and per reader, since a
gripping book keeps you up longer than a dull one — which becomes the **default
timer suggestion**. So the two features feed each other: rewind *produces* the
sleep-onset data that tunes the timer.

### Layered content per landmark — audio vs. TTS

Refinement (2026-07-25): a landmark doesn't hold *one* stream, it holds **N
layers**, and the audio-vs-synthesised question is answered **per layer**:

- **Reading of the work** = **real recording, never TTS.** Performance needs
  acting; synthesised voice is worse than nothing here. Bring-your-own audio
  (commercial audiobook, or public-domain LibriVox — solo or full-cast
  "dramatic"). The app plays the file, doesn't generate it.
- **Commentary / reader-notes / synopsis** = **TTS is fine, by design.** It's
  explanatory, not performed ("the Wife of Bath is Chaucer's most famous
  pilgrim…"). Shown on screen and optionally spoken via TTS. This is the layer
  Peter authors — the value-add, and exactly what testbook already is.
- **Translation / modernisation** = middle ground — TTS acceptable (it's a gloss,
  not a performance), real recording nicer if available.

So the authoring format is **N layers per landmark**, not a fixed reading+note.
Different works stack different layers:

| Work | Layers per chunk/landmark |
|---|---|
| Plain novel (The Hobbit) | reading + occasional note |
| Götterdämmerung | music/reading + synopsis + performer/plot notes |
| **Canterbury Tales** | **original Middle English + modern English + commentary** |

### MVP direction: Canterbury Tales in ~2-minute triplets

Peter's chosen concrete MVP (2026-07-25): **Canterbury Tales**, sequenced in
**~2-minute chunks**, each chunk a **triplet** played in order —
**(1) original Middle English → (2) modern English → (3) commentary** — before
moving to the next chunk. Why it's a *better* MVP than plain Shakespeare or a
novel: Middle English genuinely *requires* the modern-English layer, so the
multi-layer structure isn't optional polish — the app earns its keep on the
first tale. The small self-contained triplet is also inherently sleep-friendly:
no cliffhanger to keep you awake, natural pause points, and the modern+commentary
layers mean drifting off mid-chunk loses little.

**The link to GotG (Peter's words: "the link to GotG is there"):** identical
shape. testbook scene = one vinyl side = synopsis + interspersed notes; Canterbury
chunk = ~2 min = original + gloss + commentary. Same landmark-timeline-with-
layered-content structure, different layer count. Götterdämmerung, Canterbury,
and a plain novel are one app with N tuned per work.

**"Götterdämmerung with TTS interludes" (Peter, 2026-07-25) — and it may be the
better MVP.** The layered model resolves the awkwardness flagged in the first
review (Wagner is an *opera*, not an audiobook — it didn't fit a "reading+notes"
app). Now it fits perfectly: layer 1 = the **Barenboim music** for a vinyl-side
chunk (real recording, obviously never TTS); layer 2 = a **TTS interlude** —
Peter's existing scene synopsis + "listen for this leitmotif" notes — dropped
*between* the sung sections. Same triplet shape as Canterbury.

Why this may beat Canterbury as the first build: **the content already exists.**
The 16 scene synopses + performer/leitmotif notes are written; the recording is
a known 69-track / 4h27 timeline; the vinyl-side "scene" boundaries are already
the landmarks. Canterbury needs a modern-English translation authored from
scratch and has iffy Middle-English audio sourcing. Götterdämmerung needs
neither — shortest path to a working demo, and it's the truest expression of
the print→web→app morph (the print book *becomes* the app's first title).

**Two candidate MVPs, both captured; pick at build time:**
- *Götterdämmerung* — content ready, timeline known, best morph story. But BYO
  Barenboim recording, and music+interlude interleaving is the playback pattern.
- *Canterbury* — the layered structure is most *necessary* here (ME needs
  translation), but layers 2–3 must be authored and layer-1 audio sourced.

### Decisions captured this session

- **Platform: Android native.** Peter listens on his phone (pixel-6a, on the
  tailnet); wants offline, screen-off playback and real timer/notification
  control. He already has Android repos (T3, blescape, nightsound) as prior art.
- **Rewind = landmark comprehension questions**, spoiler-safe, as above. This is
  the defining feature. (Not time-based skip, not auto drift-detection.)
- **Timer default = learned from previous nights.** Estimate sleep-onset from the
  rewind data (furthest beat not reached ≈ where they faded) and suggest a timer
  from the running history, per title/reader. History-driven, not a fixed value.
- **Reading = real recording; commentary = TTS.** Per-layer, not per-app. Never
  synthesise the performed reading; TTS the explanatory layers freely.
- **Content = N layers per landmark**, not fixed reading+note. Layer count tuned
  per work.
- **MVP = one of two, decide at build time.** *Götterdämmerung* (Barenboim music
  + TTS synopsis/leitmotif interludes — content already exists, best morph story)
  or *Canterbury Tales* (~2-min triplets, ME → modern EN → commentary — structure
  most necessary but content must be authored/sourced). Both are the same
  layered app; GotG is the shorter path to a demo.
- **Scope for now: capture the vision only.** No app repo yet, no build. Revisit
  to design/spike when Peter picks it up.

### Open questions for the next app session

- **Content authoring format** — how to encode {landmark label, audio timestamp,
  spoiler-safe recognition prompt, **and N content layers** (reading-audio ref,
  modern-EN text/audio, commentary text-for-TTS)} per title. Generalise
  testbook's markdown into this. Canterbury (first tale) is the MVP corpus.
- **Middle-English audio sourcing** — layer 1 for Chaucer is the hard one:
  LibriVox has Canterbury Tales but ME-pronunciation quality varies a lot.
  Layers 2 (modern EN) and 3 (commentary) Peter authors/generates + TTS.
- **Where do the audio + timestamps come from?** BYO audiobook file + manual/
  assisted beat-tagging? Aligning a known reading to the landmark list is real
  work. For Canterbury the ~2-min chunking gives natural landmark boundaries.
- **TTS engine** — on-device Android TTS vs. a better cloud/neural voice for the
  commentary layer (offline-at-night matters; screen-off playback).
- **Licensing / commercial-vs-personal** — public-domain-only path (LibriVox +
  Furness/PD commentary + own notes) keeps a sellable app clean; Folger TEI is
  CC-BY-NC (personal only); commercial audiobooks are BYO-from-own-library.
  Decide early — it constrains sources.
- **Timer suggestion logic** — approach decided (learn sleep-onset from prior
  nights' rewind data; see above). Open: cold-start default before any history;
  whether onset inference is reliable enough from the rewind alone or wants a
  nudge from nightsound (snore-onset) / phone-idle signals.
- **New repo** vs. extend an existing Android repo. Likely new.

---

## First review — 2026-07-25

First-ever review visit (via ubersitrep backlog rotation; repo last touched
2026-01-30, never formally reviewed). This was a review pass, not a build.
Verdict below; details follow.

**One-line status:** content is *substantially drafted and good*; the build
pipeline *works today on this machine*; the only real gap to a finished
booklet is **artwork (zero images exist) + a committed build script**.

### 1. Content — substantially drafted, not skeletal

Two parallel source sets, both real prose (not stubs):

- **Scene tree** (`01_prologue/` … `05_reference/`, `06_performers.md`):
  ~34k words. The rich, expansive "everything" draft — e.g.
  `01-norns.md` alone is 340 lines with synopsis, per-track notes, leitmotifs,
  performer bios, a Macbeth parallel, staging notes. All 16 scenes + reference
  + performers are written. This is the source-of-truth content.
- **Paginated `pages/`** (`p03.md`…`p61.md`, odd = text): ~10k words. The
  deliberately *condensed* print versions — one tight page each, already cut to
  fit the 5"×8" spread. Even pages are image placeholders (`pXX.jpg.txt`).
  Dedication ("For Sue"), copyright, contents all present.
- `THEBOOK.odt` is a **hand-started LibreOffice assembly** — the Norns spread is
  already laid out in it. So the LibreOffice manual-layout path was also begun.

Content is the strand's strength. It is essentially done in draft; what remains
is condensing/curation, not writing from scratch.

### 2. Build pipeline — WORKS TODAY (this was thought to be the blocker; it isn't)

The stall recorded in `TODO.md` was framed as a toolchain problem ("how to run
on Windows? Overleaf has no facing-page mode; Acrobat has no refresh"). **On
`pip` (Linux) that whole framing dissolves** — pandoc 3.1, pdflatex, lualatex
and libreoffice are all installed. I built real PDFs end-to-end:

- `pages/` (condensed print source) → **40-page** 5"×8" PDF (text only; +~20
  image pages would land right at the ~60pp target). Rendered page 1 visually:
  clean typeset dedication + copyright, correct trim size. This is a genuine
  printable artifact.
- Full scene tree → **162-page** 5"×8" PDF (2.7× target — confirms the scene
  tree is the "long" draft and `pages/` is the intended print source).
- Engine reality: **pdflatex works**; `lualatex` has a broken font cache;
  `xelatex` is *not actually installed* (pandoc reports the name but the binary
  is absent). So build on **pdflatex**.
- One trivial gotcha: the digital-only nav lines (`[← Back]`, `─` rules) use
  Unicode box-drawing/arrow glyphs that pdflatex can't render. Stripping those
  lines (`sed -E '/[←→─│┌┐└┘━]/d'`) fixes it — and they don't belong in a print
  book anyway. That one-line filter was the entire "blocker."
- `imp.bash` referenced in TODO **was never created** — it only ever existed as
  a plan snippet. The 8-up A6→A4 `pdfpages` imposition is unbuilt (and is likely
  unnecessary: KDP wants single-page-per-leaf PDF, not a home-printed booklet —
  see decisions).

### 3. Single biggest blocker to a finished printable booklet

**Artwork.** `find artwork -type f` for images returns **zero** — every image is
a README placeholder or a `pXX.jpg.txt` stub. The book is designed 50/50 as
image-left / text-right; with no images it's half-empty. The Gimp line-drawing
plan (README) was never started. This, not the toolchain, is what's actually
missing. Secondary: no committed build script (each build is ad-hoc).

### 4. Recommended next move + priority

**Next move (small, high-leverage, ~1 session):** commit a `build.sh` to
`~/testbook` that does the proven path — strip nav glyphs → pandoc → pdflatex →
5"×8" PDF from `pages/` — so "md → PDF" is one command and no longer mythical.
That converts the project from "stalled on tooling" to "stalled on art," which
is a truer and more motivating framing. Then the real work is **artwork**:
decide public-domain/Wikimedia photos vs. Gimp line-drawings, produce the ~20
images, drop them into the even pages.

Also worth a decision: **KDP vs. home-printed booklet.** README targets KDP
paperback (single-page PDF, perfect binding) — if that's the real goal, the
whole A6-imposition/`imp.bash`/booklet thread in TODO.md is a dead end and
should be deleted. The Windows/Overleaf/Acrobat worries are moot: build on pip.

**Priority rating (feeds ubersitrep re-queue): LOW–MEDIUM *for the print book*.**
It's a personal, non-urgent creative project with no external dependency or
decay risk. But it is *much* closer to done than "stalled since January"
implied: content is drafted, the pipeline provably works, and the remaining work
(art + a build script) is well-defined.

**NOTE — superseded by the app pivot (see top of file).** As of 2026-07-25 the
strand's forward direction is the sleep-listening app, not finishing the print
book. The print artifacts (content + PDF pipeline) become seed material for the
app. For the re-queue: rate the *strand* on the app ambition (a real build,
higher energy, clear killer feature — MEDIUM, and rising if Peter engages),
while the print book itself stays a LOW-priority "finish someday" side output.

## Pending / loose ends

- **Artwork: ~20 images, none exist** — the real blocker. Choose sourcing
  approach (Wikimedia public-domain photos vs. Gimp stylised line-drawings).
- **Commit a `build.sh`** to `~/testbook` (proven pdflatex path; strip Unicode
  nav glyphs first). Currently every build is ad-hoc.
- **Decide KDP vs. home booklet.** If KDP: delete the A6-imposition / `imp.bash`
  / 8-up-on-A4 plan from `TODO.md` (dead end for perfect-bound POD).
- **Reconcile the two source sets** — scene tree (long) vs. `pages/` (condensed).
  `pages/` is the print source; keep the scene tree as the research backing, or
  fold decisions back. Don't let them drift.
- **Page breaks:** pandoc flows `pages/` files together (dedication + copyright
  shared a page in the test). Add explicit `\newpage` / per-page rendering so
  one source page = one printed page.
- **Merged branch history:** `claude/002-fix-markdown-import` already merged; a
  few stale `claude/*` remote branches remain — harmless, could prune.

## Decisions

- **Build on pip with pdflatex**, not Windows/Overleaf. xelatex isn't installed;
  lualatex's font cache is broken. pdflatex + a Unicode-strip pre-pass is the
  path. (2026-07-25)
- `pages/` is the intended **print** source; the scene tree is the long-form
  research draft. (Observed, 2026-07-25 — confirm with Peter.)
