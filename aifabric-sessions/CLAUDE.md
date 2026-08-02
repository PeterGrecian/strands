# Strand: aifabric-sessions

**Builds the session archive + RAG — every Claude Code transcript ingested into
local OpenSearch and made searchable, for Peter and for agents.**

Every Claude Code session transcript,
ingested into local OpenSearch (the `~/osd` stack) and made searchable —
first for Peter (dashboards, full-text queries), then as a retrieval surface
agents can consult ("what did we conclude about X in March?"). The strand is
the **sessions-keeper** in the making: it owns session-history intelligence
as a service.

## Why this exists (born 2026-07-18)

Claude Code's default `cleanupPeriodDays` (30) silently deleted months of
transcripts. What survives: `~/archives/claude-sessions-snapshot-20260718.tar.gz`
(pip, 2026-06-19 →) and `~/archives/claude-sessions-muppet-20260718.tar.gz`
(muppet, 2026-03-03 – 04-21, recovered before its reaper ran; extracted copy at
`~/archives/muppet-sessions/`). Plus live `~/.claude/projects/*/**/*.jsonl`.
The model is **ship-and-free** (house convention): ingest into the index
(ship), then let the 30-day cleanup reap the files (free) — the index is the
permanent record. The `cleanupPeriodDays` decision itself stays with Peter.

## Hard constraints

- **Local-only index.** Transcripts embed tool output (file contents,
  occasionally secrets-adjacent). The OpenSearch instance must never be
  internet-exposed; no cloud copies of transcript content.
- Ingest code lives in the **`~/osd` repo** (its `bin/`), committed there.
- House rules: UTC in stored timestamps, `trash` not `rm`, no `/tmp` for
  anything durable.
- Don't touch `~/.claude/settings.json` (retention decision pending) and never
  delete live transcripts — the reaper or Peter does that, not this strand.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox); triage.
2. Work: osd-repo commits for code, strand files for curation.
3. Session end (or on `dcp`): update STATE.md — what changed, what's pending,
   decisions made. Keep it curated prose, not a log.

Mailbox: `./MAILBOX.md` (arm with `~/super/strands/strands/ding --arm` to be
reachable by other live strands; see `strands/strands/forkterms.md`).
