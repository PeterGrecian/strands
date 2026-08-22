# super — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **Help flag audit**: All 56 scripts in `~/super/bin/` (and `~/splay/`) now robustly support `-h` / `--help` (exiting `0`), with safe early-exits to prevent hanging on network/SSH commands, and deferred imports in Python scripts to ensure `--help` works even if third-party modules are missing.
- **Unified `cleft`**: The AI usage calculator `cleft` now supports both Anthropic API (`-c`) and AGY/Gemini API (`-a`). Running it with no flags automatically checks `aicli -d` to show usage for the current default backend.
- **`ssp` improvements**: Added `eclipticam` (alias `e`, IP `192.168.0.66`) to ansible `host_vars` so `ssp --refresh` includes it. Also updated `ssp` to use `StrictHostKeyChecking=no` and `UserKnownHostsFile=/dev/null` by default to prevent getting trapped by changing fleet host keys.

## Pending / loose ends

- **Topology for a phone-reachable strand team** (promoted 2026-07-23; partly
  done). Host **puppy** — it co-locates the mesh tree + resident strandterms +
  the web surface (inotify waiters need the mailbox fs local), with
  `tailscale serve` fronting HTTPS, which also makes the OSD dashboard :5601
  phone-reachable for free. **Puppy is now on the tailnet** (joined ~2026-07-22),
  so the prerequisite is met — remaining work is the serve config plus something
  to serve. **What gets served changed 2026-08-22:** the plan named `strandchat`,
  but that strand is archived (chat was the wrong shape) and the surface is now
  [[aifabric-pane]]'s browser compositor. The *topology* here is unaffected and
  still the right answer; only the payload moved. Super owns the host + serve
  config, `aifabric-pane` owns what runs on it. Notes: homepi is
  windows-only (ample but agents can't live there); vole stays lean
  (tiebreaker duty); muppet joins the tailnet only if the team outgrows puppy.
  **Caution:** resident strandterms drink the 5h quota window — arm-and-idle
  discipline required.

## Decisions
