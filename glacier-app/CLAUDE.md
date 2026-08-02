# Strand: glacier-app

**Builds photo archiving to S3 Deep Archive — a prototype now, an app later.**

Photo archiving to S3 Deep Archive — prototype now, app later. The pitch
(Peter's README.md): friends pay £10 *once, when the phone goes in the
washing up*, not £10/month. Prototype: archive Peter's ~66 GB of photos
from muppet (`/mnt/bigdisk/images`) with a permanently-browsable surface
(ledger, listings, thumbs, meta) and static `/glacier` pages. **DESIGN.md
is the design of record** — read it before doing anything; README.md is
the original idea sketch. Spans **`~/mywebsite`** (the /glacier pages);
ingest runs on **muppet** via ssh (data is local there). The ledger
(`ledger.jsonl`) is committed to this dir in git as well as living in the
bucket.

## Session ritual

1. Read `STATE.md` (current state, decisions), `IDEAS.md` (inbox), and
   skim DESIGN.md's Status + Open questions.
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Website changes commit to mywebsite; design/ledger/tooling for
   the prototype live here until it graduates to its own repo
   (DESIGN.md open question 3).
4. Session end (or on `dcp`): update STATE.md and DESIGN.md's Status.

## House rules that bite here

- **Estimate cost before any AWS action and state it first** — this strand
  is all S3/Deep Archive ops. Uploads are cheap; restores and egress are
  the expensive paths. Deep Archive min storage duration is 180 days.
- Smoke test (`scans/`, 26 MB) end-to-end before the 66 GB.
- UTC timestamps in the ledger (house convention).
