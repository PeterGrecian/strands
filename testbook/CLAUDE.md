# Strand: testbook

**Builds an assisted sleep-listening app for Android — spoiler-safe,
landmark-based rewind for listening while falling asleep.**

Mission (as of 2026-07-25 — pivoting): an **assisted sleep-listening app**
for Android. Peter listens to audiobook readings to fall asleep; the app solves
the four problems that breaks: (1) how long to set the sleep timer, (2) how to
wind back to the last thing you actually registered before drifting off, (3)
synopses for complex works, (4) reader notes (e.g. Shakespeare) interspersed
with the text at the right moments. *Götterdämmerung on the Go* becomes the
first fully-authored title and the template for the annotation format — not the
product itself.

**Lineage:** this strand has morphed twice. It began as a **print** listening-
guide to Wagner's Götterdämmerung (5"×8" KDP paperback), then became a **website**
page (`Götterdämmerung on the Go` on petergrecian.co.uk), and is now morphing
into the **app**. The Wagner content and its per-scene synopsis + interspersed-
notes structure carry forward as the app's first title and authoring template.

**Repos:** `~/testbook` holds the existing Wagner content (markdown, and the
built PDF pipeline — see STATE). The app will need its own repo/build (Android;
Peter's Android repos: T3, blescape, nightsound). Deliverable = the app; the
Wagner guide is seed content.

**The original print design brief is `~/testbook/README.md`; the app vision is
in STATE.md.**

## Session ritual

1. Import spooled ideas with `idea --import`, then read
   `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
