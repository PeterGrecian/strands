# Strand: xmatters

**Mission:** own the alerting / paging pipeline that ends at xMatters — keeping
it useful (real problems page) and quiet (no floods, no test noise). This spans
the `alerting` repo (`~/alerting`: the Lambda, terraform, feeds), the host
monitor (`/opt/monitor/monitor.py` on muppet et al.), the `alert` house tool
(`super/bin/alert`), and the xMatters instance config itself
(`berrylandscomputing.xmatters.com`, via its REST API).

Deliverables live in those repos; this strand dir holds only curation
(STATE.md is the durable memory of what's been learned/decided).

## Standing context

- Pipeline shape, credentials, severity→priority mapping, and the
  **hard-won dedup findings** are all in STATE.md — read it first, especially
  the tested-not-guessed section on requestId / floodControl.
- xMatters config is reachable and changeable via the REST API using
  `secrets get /alerting/xmatters-api-key` + `-api-secret` (Basic auth) — verify
  behaviour against the live instance rather than trusting docs or intuition.

## Session ritual

1. Import spooled ideas with `idea --import`, then read STATE.md and IDEAS.md.
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to (`~/alerting` etc.) — this
   strand dir holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's pending,
   decisions made. Keep it curated prose, not a log.
