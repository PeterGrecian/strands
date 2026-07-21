# Briefing — aifabric-sessions forkterm (turn-one identity hand-off)

You are the **first session of the new `aifabric-sessions` strand**, launched
as a forkterm *into* this strand by the aifabric strand's live session, with
Peter's explicit go-ahead ("start an osd RAG for the sessions right here,
right now — in a forkterm"). Your CLAUDE.md (auto-loaded) is the mission;
your STATE.md carries the full birth context and sources inventory — read it
first, it replaces any need to re-derive history.

Immediate work, in order:

1. Read STATE.md. Trust its sources inventory — it was verified today.
2. Explore `~/osd` (already in your --add-dir); bring the OpenSearch stack up
   locally (it is currently down; docker-compose based).
3. Create the `claude-sessions` index and write the idempotent ingest script
   in `~/osd/bin/` (schema sketch in STATE.md pending #1–2).
4. Backfill: both tarballs in `~/archives/` + live `~/.claude/projects`.
   Verify document counts against the inventory (74 pip + 23 muppet sessions).
5. Stop there and report: update STATE.md, commit the osd repo, and summarise
   for Peter (he decides `cleanupPeriodDays` and the nightly-timer step next).

Hard rules (also in CLAUDE.md): index stays local-only — never
internet-exposed; don't touch `~/.claude/settings.json`; never delete live
transcripts; `trash` not `rm`; durable scripts never in `/tmp`.

Coordination: your mailbox is `./MAILBOX.md` — after backfill, arm it
(`~/super/strands/strands/ding --arm` as a background task) so other live
strands can reach you. The aifabric parent session may not be armed; STATE.md
is the durable channel. Quota is short: work in focused turns, no subagents.
