# cv — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Context (read this first)

Peter is repositioning his CV to find **consultancy / short-term contract /
advisory work**, moving toward retirement — he wants lighter, more connected,
more *sustainable* work after **14-hr days for 10+ months** (his GitHub attests).
Underlying brief, bigger than the CV: *"I want to work differently now."* He's
been building alone, in a vacuum where colleagues aren't interested in the
method — a real push-reason. Wants to be **around people who care about these
things**, to pass findings on and take others' ideas in.

**Status as of 2026-08-02:** lots of strategy done, spine locked, **no final
prose written yet**. Peter is **on holiday next week** (paper notebook, NO
laptop — his way of relaxing; will think + research by hand), then a
post-holiday re-entry week. Original 15-Aug launch is **soft** — resume when
*ready*, not to a date. Rested-and-sharp beats on-time-and-tired for a document
whose whole thesis is that it's better than the competition. **Do not push him
to grind this before the break.** The holiday is the "let it rest" buffer.

## The deliverable's shape (LOCKED)

**Two pages: page 1 = the idea, page 2 = the history.**
- Page 1 sells the future (the consultant offer); page 2 grounds it in 30 years
  of range as *proof the method is trustworthy*.
- **Refinement from research:** page 1 must use **standard CV section headings**
  (Profile → Approach/AI Fabric → Key Achievements/Skills), NOT a free-form
  manifesto. Recruiters need "visual anchors"; niche pitch-deck formats backfire.
  So: *unconventional in content, conventional in scaffolding.*
- HTML `/cv` has no pages — the 2-page split is really the **PDF** (the client
  deliverable). Website can stay one scroll. Settle output format later.

## The pitch / spine (LOCKED)

- **Offer = AI-enablement / capability transfer:** "I make your team's
  AI-assisted engineering actually work, then hand it over." Turns his solo
  achievement into something a client buys. Also resolves the vacuum: hired
  *because* a team wants what he knows, job is to leave them able to do it.
- **Explicit availability line** near the top (consultancy / short contracts /
  advisory). Label roles **"Consultant"** in the title line.
- **30-year range = depth-to-rent / adaptability** (consultant research: "momentum
  not movement"). Stop apologising for/de-emphasising the history — for a
  consultant it's an asset. It just lives on page 2 so it doesn't crowd the idea.
- **Values throughline:** knowledge that compounds — share findings, absorb
  others' ideas, build tools so nothing is re-learned. This mirrors AI Fabric
  itself (strands/keepers/archive) one level up (human teams).

## The killer concrete proof (the differentiator)

At his **current NiCE Ltd (CXone)** role — Cloud Network IaC Engineer,
**Sep 2025–present**, permanent (but CV frames the *offer* as consultancy):
- Makes **bulk CloudFormation + Terraform changes that are OTHERWISE IMPRACTICAL**
  — sweeping, consistent change across many stacks where colleagues do a handful.
  (Say "otherwise impractical," NOT "impossible" — defensible.)
- IaC is **manipulated programmatically in Python** — that's the *mechanism*
  behind bulk change (scripting transformations over templates, not hand-editing).
- **Extensive VPC flow-log analysis the team hadn't done before** — a second
  "otherwise impractical → now routine" proof, in the *analysis* dimension.
- **Automated change pipeline that HE supervises** (human-in-the-loop = Peter;
  agent proposes, he reviews/approves before deploy). This is the *safety* answer
  that makes high volume a virtue not recklessness.
- **DO NOT use "lines of code changed" as the metric** — discredited unit, reads
  as churn/verbosity. Frame as "bulk changes otherwise impractical / large-scale
  refactors landed safely." Keep the magnitude, respect the unit.
- **Air-gap:** state *his own* contribution/output ("I introduced flow-log
  analysis"), never describe NiCE's internal systems/numbers. Method flows
  personal→work only; AI Fabric never contains NiCE content.

## AI Fabric — how to write it (concrete, NOT buzzword soup)

Principle: **concrete practice first, keyword riding quietly alongside as an
anchor.** Every claim = something he actually did, so a scanner catches the term
AND a skeptical senior engineer nods. Keyword-dense line lives in **Skills**
(ATS feed); the **AI Fabric section is pure concrete prose** with each keyword
once, in parentheses, after the thing it names.

The four concrete threads (strongest first):
1. **The correcting archive** (his best material): he asks agents *"what did we
   conclude about X?"*, *"didn't we go down this rabbit hole?"*, *"that's not what
   happened last time."* → memory the AI is **accountable to**; he corrects it
   with evidence. Keep those 3 verbatim questions — vivid, best single thing.
   Honest: it's **lexical/full-text** retrieval (local OpenSearch), **human-
   initiated RAG** — say "retrieval-augmented" but don't imply vector/embeddings.
2. **Keeping beyond MCP:** MCP self-describes the *interface* (name + input schema
   via tools/list); his **hints surfaces** self-describe the *use* (conventions,
   gotchas, current state — e.g. `secrets hints`). Static schema string vs. living
   curated context. Frame as *beyond/on top of* MCP, never *instead of* (he uses
   MCP). Include "MCP" — high-value keyword he genuinely exceeds.
3. **Strands:** durable, git-backed, *editable* memory so a fresh session resumes
   where the last left off — vs. lossy, un-editable chat history.
4. **Families / forkterms:** structured, addressable agent groups (who forked from
   whom, who reports to whom, who talks) vs. wasteful *fire-and-forget* parallel
   agents that start cold, re-derive context, duplicate work.
- **Evaluation gap:** research says "no eval mentioned = disqualifier." Frame his
  self-checking tooling / supervised pipeline as evaluation/verification of agent
  work — thin but present.

**Applied to (proof it's not theoretical) — 3 domains:**
- **Production IaC** at NiCE (the paid, serious, current proof — lead with this).
- **Shipped apps:** TerseTransportTimes (live K2 bus + Surbiton–Waterloo train
  app). [CONFIRM: live/daily-use vs prototype?]
- **Urban astronomy / "beautiful skies":** end-to-end imaging pipeline (capture on
  Pi fleet → cloud storage → processing → published dashboards). [Public URL to
  link? e.g. on petergrecian.co.uk — a link makes it real & clickable.]

## Where the CV lives / mechanics

- **Source of truth (deployable):** `~/mywebsite/lambda/cv.html`, served at
  **www.petergrecian.co.uk/cv** (Lambda; route in `mywebsite.py` ~L2577). NOT
  hidden — robots.txt *allows* /cv; it's just unlinked from the home page.
  **Not yet deployed** — all edits this session are local only.
- **Editing/mangling surface:** Google Doc **"Peter Grecian CV 2026"**, id
  `19oV-vcoqxbRJaWHfsTw4KiEFmjbvWyzlZSJgf7h3VQM` (native GDoc, owned by Peter).
  Created via Drive MCP connector from markdown.
- **Round-trip:** Doc → download as markdown (Drive MCP) → convert to the
  cv.html template (`.section`/`.job-title`/`.job-dates`/`.highlight`) →
  overwrite HTML body → deploy. Easy, EXCEPT: (a) regenerate-not-merge, so ONE
  source of truth at a time — while Peter edits the Doc, the Doc wins; (b) GDoc
  export inserts smart-quotes & **em-dashes** — must normalise on the way back
  (Peter dislikes em-dashes — strip them). Turn-taking to avoid clobbering: when
  the tool writes the Doc, Peter pauses editing.
- The stray `~/gdrive/gdrive/Peter Grecian CV 2026.md` was **deleted** (to Drive
  Trash) — it triggered the texteditor.co add-on. Doc + HTML are canonical.

## Edits already made to cv.html this session (all LOCAL, undeployed)

- Rewrote Profile to lead with AI/real-world-tasks + VFX+science roots.
- Added the **AI Fabric section** (currently 4 flowing paragraphs, coined terms
  bold; **manywrapper demoted/removed**; forkterms→families framing; em-dashes
  stripped). NOTE: predates the "page of idea" restructure and the
  consultant/capability-transfer sharpening — **will be rewritten**.
- Restructured Experience: NiCE (Sep 2025) top; Freelance (Feb–Aug 2025);
  grouped **VFX & Pipeline Engineering** (MPC, Soho, Method) and **Cloud Platform
  & Compute** (DeepMind, merged Crystal Ski+BMJ 2015–2024).
- Date fixes reconciled to LinkedIn: Method Feb–Dec 2014; DeepMind Mar 2012–Feb
  2014 (+ "built machine room to train early AI systems"); Soho freelance ends
  Feb 2012 (was overlapping DeepMind).
- **Deleted** Publications & Presentations section (stale + AI-Fabric repetition).
  Trimmed AI Fabric echo from Highlights.

## Pending / open questions (for Peter, post-holiday)

- **Silverfit wording:** "fitness charity" → he wants **"sport and exercise
  charity"** (said yes, NOT yet applied). Own entry vs. bullet?
- **Crystal Ski + BMJ:** currently MERGED into one "2015–2024" entry (loses
  individual titles/dates). Keep merged or split back out?
- **TerseTransportTimes status** — live/daily vs prototype?
- **Astronomy public URL** to link?
- **Year count:** MPC started 1994 → "30 years" accurate (he changed "15+"→"20+";
  30 is right). Confirm the number he wants.
- **IaC verb:** "manipulate" → prefer concrete "generate/refactor/migrate".
- **Whole document is still to be WRITTEN** — strategy is done, prose is not.

## Decisions

- Target: **consultancy / short contracts / advisory**, capability-transfer offer.
- **Two-page: idea then history**, standard section headings on page 1.
- Concrete-first, keyword-anchored; keyword-dense Skills line for ATS.
- Metric = "bulk changes otherwise impractical", NOT lines-of-code.
- Launch is readiness-gated, not date-gated. Rest first (10 months of 14-hr days).
- Research phase is CLOSED (AI-angle + consultant-genre + structure all done —
  further searching = procrastination pulling toward the generic mean).

## Related

- `aifabric-essay` strand — the argued evidence behind the "wise AI" pitch.
- LinkedIn: one external recommendation on record (Alex Hooper, ex-BMJ Head of
  Platform: "strong analytic skills, tenacity with intricate problems,
  right-sizing & cost-reduction, great team player") — worth surfacing.
