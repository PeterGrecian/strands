# aifabric ideas/ spool

**One file per idea.** This is the clobber-safe inbox for aifabric ideas from any
active strand or forkterm — the per-strand `ideas/` spool (see the `idea` tool /
`ideas-keeper` design in `super/strands/strands/IDEAS.md`).

## How to drop an idea (until the `idea` tool exists)

Write a **new file** — never edit someone else's, never append to a shared file.
Concurrency-safety is by construction: unique filenames can't collide.

Filename: `YYYYMMDDThhmm-<strand>-<pid>.md` (timestamp + your strand + pid), e.g.
`20260717T0912-astro-canon-4412.md`. Use UTC for the timestamp (repo convention).

Suggested body:

```markdown
---
strand: <your-strand>
date: 2026-07-17
host: <host>
---

<the idea, in your own words>
```

Triaged at aifabric session start: promote-by-default into `STATE.md` pending,
then the file is swept to `~/.trash` (never `rm`). `README.md` is not an idea and
is never swept.
