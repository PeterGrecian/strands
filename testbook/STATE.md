# testbook — state

*Curated summary of where this strand is. Updated at the end of each session.*

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

**Priority rating (feeds ubersitrep re-queue): LOW–MEDIUM.** It's a personal,
non-urgent creative project with no external dependency or decay risk — nothing
breaks by leaving it. But it is *much* closer to done than "stalled since
January" implied: content is drafted, the pipeline provably works, and the
remaining work (art + a build script) is well-defined. Re-queue as a
pick-up-when-in-the-mood project, not an obligation. Bump to MEDIUM only if
Peter wants a finished artifact in hand.

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
