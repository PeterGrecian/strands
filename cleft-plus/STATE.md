# cleft-plus — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What this is (framing, 2026-07-31)

cleft = **"claude left"** + the arithmetic to frame that against the reset
clock. Not a usage *monitor* (badge/alert genre — many of those exist); a
**fuel gauge with an ETA**: how much quota is left, and does that leave you
short or with slack before reset. cleft's distinctive framing vs the field:
the **exhaustion timestamp + gap-before-reset** ("runs out Fri 14:00, 8h
before reset") and the **required-rate-to-land-at-100%** (budget framing, not
just warning framing). Keep and lead with those.

Native `/usage` (much improved as of 2026-07) owns "where did it go" — the
per-skill/subagent/MCP breakdown. Peter doesn't use skills much, so that
decomposition isn't needed here. **cleft owns "will I make it to reset, at the
rate I'm going *now*."** No pressure to chase per-model/per-skill parity.

Key insight: **long sessions are expensive, long *duration* is not** — cost is
consumption *intensity*, not wall-clock. So the signal is recent burn rate, not
session age. And **recent rate is the one that matters because the human forgets
what they did 3 days ago** — the tool must supply the memory the person lacks.

## Pace marker on the bars (2026-08-02)

Peter's idea (dropped in cleft-plus + ubersitrep inboxes): *"the 5-day window
and week have bars, but they are of different scales which we don't see."*
Diagnosis: both bars use the same `bar()` and both plot **used %** of their
*own* quota — so a full 5h bar and a full 7d bar are the **same screen length**
but wildly different absolute token volumes, with nothing signalling it. Worse,
the bar drew *used* but ignored *elapsed-through-window*, so 50% at hour 1 of 5
looked identical to 50% at hour 4 of 5.

Fix (done, `super/bin/cleft`): `bar()` takes an optional `pace` (0–1, elapsed
fraction) and overlays a **`┃` marker** at that column. Read is now **fill vs
marker** — left of it = under pace, right = burning fast — which is *identical
across both windows* regardless of their different absolute quotas. Wired into
all three call sites (live 5h `elapsed/5`, live 7d + manual via `show()`
`elapsed/7`), plus a one-line legend. Verified in manual mode: 48% used at 24%
through the week puts fill well right of `┃`, matching the "runs out early"
verdict. This is the visual companion to cleft's required-rate arithmetic —
the fuel-gauge framing, seen at a glance.

## What exists

- `cleft` (`super/bin/cleft`) — point-in-time usage-rate calculator. Fetches
  `api.anthropic.com/api/oauth/usage` (OAuth token from `~/.claude/.credentials.json`,
  beta header `oauth-2025-04-20`), parses `five_hour` / `seven_day` buckets,
  prints current rate, required rate, projected %-at-reset. No history, no
  per-model split.
- **Prediction is single-sample, stateless:** `current_rate = pct / elapsed`,
  averaged from window-start. That's its weakness — for the 7d bucket it's
  dominated by 3 days ago and can't see you've gone quiet since. Community
  tools (Maciek's Claude-Code-Usage-Monitor) already do burn-rate projection;
  their edge is *history* → recent-slope rate. Closing that gap is the point of
  the logger below, not the plot.
- **API shape (observed 2026-07-25):** each of `five_hour` / `seven_day` has
  `utilization` (%), `resets_at` (ISO ts), plus `limit_dollars`/`used_dollars`
  (currently None). Also present: `seven_day_opus`, `seven_day_sonnet`,
  `seven_day_cowork`, and codenamed buckets (`omelette`, `tangelo`,
  `iguana_necktie`, …) — mostly None now but that's where the per-model /
  fable split lives. Plus `extra_usage` (monthly credit limit) and a `limits`
  array with `severity` (normal/critical). Sample seen: 5h=94% critical,
  7d=73% normal.

## Pending / loose ends

**Reshaped 2026-07-31** after surveying the field (built-in `/usage`, Maciek's
Claude-Code-Usage-Monitor, ClaudeKarma, claude-monitor.com, macOS menu-bar
tracker). Conclusion: the monitor/plot genre is commodity; cleft's niche is the
reset-relative *fuel-gauge* framing + a **recent** burn rate. Three original
threads collapse to:

1. **Recent-rate logger** (*promoted — the substance*). Gentle scraper → cache
   of `(ts, five_hour%, seven_day%, resets_at)`; cleft reads recent samples and
   reports a **recent-slope burn rate** alongside the window-average one. This
   is what turns cleft's naive single-sample projection into "what am I doing
   *now*" — the one real gap vs existing tools, and the memory the human lacks.
   - **Decided: fixed ~60min lookback** for the recent slope (same for 5h and
     7d buckets). Simplest; directly answers "right now."
   - *Load-bearing constraint (unchanged):* endpoint rate-limits — scrape
     gently (~15–30 min), never per display refresh. So the 60min lookback is
     ~2–4 samples; fine for a slope.
2. **XFCE genmon widget** (*kept — cheap, genuinely unfilled niche*). Shows
   "claude left + on-track?" from the **cache** (never the API). The live number
   is recent burn / on-track, **not** session age (duration ≠ cost).
3. **Per-model / fable split** (*demoted to a cleft print tweak, maybe not even
   that*). ClaudeKarma already does the fable split; native `/usage` does the
   decomposition. Peter doesn't use skills. At most a one-line cleft print.

Suggested order: #1 scraper+cache → #1 recent-slope in cleft → #2 widget (reads
the cache). #3 only if it earns its place.

## Field survey (2026-07-31)

- **Built-in `/usage`** — now shows 5h+weekly bars + per-skill/subagent/MCP
  breakdown. Owns "where did it go." Much improved since last looked at.
- **Claude-Code-Usage-Monitor** (Maciek) — mature real-time monitor with
  burn-rate predictions/warnings; edge is stored history → recent rate.
- **ClaudeKarma** (Chrome ext) — one-click 5h/7d, *explicitly breaks out Fable
  5* (covers the "fable separate" note).
- **claude-monitor.com** — toolbar badge, 80/95% desktop alerts.
- **Claude-Usage-Tracker** — native macOS *menu bar* app (the widget genre, but
  macOS not XFCE).
- Prediction *math* (linear burn → projected exhaustion) is common to all.
  cleft's differentiators: single-sample/stdlib/stateless, the exhaustion
  *timestamp*, and required-rate-to-100%.

### Reference links (survey sources, 2026-07-31)

- Claude-Code-Usage-Monitor (Maciek) — https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor
- ClaudeKarma (Chrome ext, Fable split) — https://chromewebstore.google.com/detail/claude-limit-usage-tracke/hoffoefgnaakaafdfjpnjdkclhjkebjn
- Claude Usage Monitor (toolbar badge, 80/95% alerts) — https://claude-monitor.com/
- Claude-Usage-Tracker (native macOS menu bar) — https://github.com/hamed-elfayome/Claude-Usage-Tracker
- SessionWatcher guide (`/usage`, `/status`, 5h window) — https://sessionwatcher.com/guides/how-to-check-claude-code-usage
- Amnic — Claude usage tracking overview — https://amnic.com/blogs/claude-usage-tracking
- Faros.ai — monitoring Claude Code token usage — https://www.faros.ai/blog/claude-code-token-usage

## Decisions

- **Split out of aifabric into its own strand** (2026-07-25) — "usage
  observability" outgrew a single aifabric pending item.
- **Cache-once architecture:** one gentle scraper writes a cache; plot + widget
  read the cache, never the API directly. Sampling cadence decoupled from
  display refresh.
- **Recent-rate over window-average** (2026-07-31): the load-bearing metric is a
  ~60min recent-slope burn rate, because cost is intensity not duration, and
  because the human forgets what they did days ago. Window-average kept as a
  secondary readout.
- **Scope narrowed to fuel-gauge + recent-rate** (2026-07-31): monitor/plot
  genre is commodity; don't chase per-model/per-skill parity (native `/usage`
  owns that, and skills aren't used here). Logger promoted, widget kept,
  per-model demoted.
- cleft code changes commit to **super** (`super/bin/cleft` — note: moved from
  aifabric); this dir is curation only.
