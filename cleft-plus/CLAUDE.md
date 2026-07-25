# Strand: cleft-plus

Grow `cleft` from a point-in-time usage-rate **calculator** into a small usage
**observability surface** for Claude Code consumption. `cleft` (`aifabric/bin/cleft`,
228 lines of stdlib Python) today hits `https://api.anthropic.com/api/oauth/usage`
once, reads the `five_hour` / `seven_day` `utilization` + `resets_at`, and prints
current rate, required rate, and projected %-at-reset. It has no memory and no
per-model breakdown.

This strand adds three threads on top, all reading the *same* usage endpoint:

1. **Usage-vs-time logger + plot.** A gentle scraper appends timestamped samples
   to a data file; a plotter draws %-used vs time with reset markers. cleft only
   sees "now" — a graph needs stored history first.
2. **XFCE panel widget.** A `xfce4-genmon`-style panel item showing live 5h/7d %,
   reading from the **cached** sample file (never polling the API per refresh).
   Ties into the panel/`xdotool` tooling established in the dotfiles work.
3. **Per-model buckets.** The usage API already returns `seven_day_opus`,
   `seven_day_sonnet`, and codenamed buckets (`omelette`, `tangelo`, …) — cleft
   ignores them. Surface the per-model split (the "fable usage separate" note).

## Hard constraint: poll gently, cache once

The usage endpoint rate-limits — "it fails if polled too often" (the originating
idea). So the architecture is **one gentle scraper writes a cache; everything
else reads the cache.** The plot and the panel widget must never call the API
directly on refresh/click. Sampling cadence is a scraper concern (~15–30 min),
decoupled from display refresh.

## Where things live

- `cleft` itself: `aifabric/bin/cleft` (already graduated into aifabric). Code
  changes to cleft commit **there**, not in this strand dir.
- The scraper/plotter/widget are new tools — decide their home as they take
  shape (likely aifabric, since cleft is there; the widget may want a dotfiles
  `.desktop`/genmon config too).
- This strand dir holds only curation (STATE/IDEAS), per the strand model.

## Relationship to aifabric

cleft is an aifabric tool; this is a focused workstream *around* it, split out of
the aifabric IDEAS inbox because "usage observability" is more than a single
pending item. Portfolio-relevant: it's another clean, standalone, stdlib-only
tool in the fabric.

## Session ritual

1. Import spooled ideas with `idea --import`, then read `STATE.md` and `IDEAS.md`.
2. Triage new ideas with Peter: promote to STATE.md pending, or drop.
3. Work. cleft code commits to aifabric; curation lives here.
4. Session end (or `dcp`): update STATE.md — what changed, what's pending.
