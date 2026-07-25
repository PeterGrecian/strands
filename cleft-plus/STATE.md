# cleft-plus — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- `cleft` (`aifabric/bin/cleft`) — point-in-time usage-rate calculator. Fetches
  `api.anthropic.com/api/oauth/usage` (OAuth token from `~/.claude/.credentials.json`,
  beta header `oauth-2025-04-20`), parses `five_hour` / `seven_day` buckets,
  prints current rate, required rate, projected %-at-reset. No history, no
  per-model split.
- **API shape (observed 2026-07-25):** each of `five_hour` / `seven_day` has
  `utilization` (%), `resets_at` (ISO ts), plus `limit_dollars`/`used_dollars`
  (currently None). Also present: `seven_day_opus`, `seven_day_sonnet`,
  `seven_day_cowork`, and codenamed buckets (`omelette`, `tangelo`,
  `iguana_necktie`, …) — mostly None now but that's where the per-model /
  fable split lives. Plus `extra_usage` (monthly credit limit) and a `limits`
  array with `severity` (normal/critical). Sample seen: 5h=94% critical,
  7d=73% normal.

## Pending / loose ends

Three sub-ideas promoted from the aifabric inbox (idea `20260723T113801Z`,
2026-07-23) + the two `super/IDEAS.md` cleft notes:

1. **Usage-vs-time logger + plot.** Gentle cron scraper appends
   `(ts, five_hour%, seven_day%, resets_at)` to a data file; plotter draws
   %-used vs time with reset markers. cleft is point-in-time, so this needs a
   store first. *Load-bearing constraint:* endpoint rate-limits — poll gently
   (~15–30 min), never per display refresh.
2. **XFCE panel widget** (`xfce4-genmon`-style) showing live 5h/7d %, reading
   the **cached** sample file (not the API). Ties into the panel/`xdotool`
   tooling from the 2026-07-25 dotfiles work.
3. **Surface per-model buckets** — extend cleft to show `seven_day_opus` /
   `seven_day_sonnet` / fable split the API already returns. Small,
   self-contained; good first slice (no new infra).

Suggested order: #3 (small, in cleft) → #1 scraper (unblocks everything) → #1
plot → #2 widget (reads #1's cache).

## Decisions

- **Split out of aifabric into its own strand** (2026-07-25) — "usage
  observability" outgrew a single aifabric pending item.
- **Cache-once architecture:** one gentle scraper writes a cache; plot + widget
  read the cache, never the API directly. Sampling cadence decoupled from
  display refresh.
- cleft code changes commit to **aifabric** (where cleft lives); this dir is
  curation only.
