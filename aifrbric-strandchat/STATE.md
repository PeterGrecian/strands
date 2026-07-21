# aifrbric-strandchat — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **`aifabric/bin/forkchat`** — shipped via PR #3 (merge `c7f2046`, on aifabric
  `main`). 472-line stdlib-only Python HTTP server; "a browser window onto the
  forkterm mesh." Reads the mailbox tree (`$FORKTERM_ROOT`, default
  `~/.forkterms`) and serves it as a live chat; send box shells out to
  `forkterm send`. Reads live from disk each poll, keeps no state of its own.
- **Hardening** (`e7804fe`) already in: HTTP Basic-auth password
  (`$FORKCHAT_PASSWORD` / `--password-file`), Host-header allowlist against
  DNS-rebinding, fork-name validation, fail-closed when bound off loopback.
- Intended remote path: run on an always-on home node behind Tailscale
  `--serve` (Tailscale terminates HTTPS + gates to the tailnet); localhost bind
  stays. This is the phone-onto-the-mesh route.
- **Both presentations verified working** (2026-07-20). One responsive page,
  640px breakpoint: desktop two-pane (sidebar + chat), phone one-pane (list →
  tap → chat with `‹` back). Screenshotted headless at both widths.
- **`spool2mesh.py` (scratchpad)** — read-only adapter projecting the LIVE
  home substrate (`$XDG_RUNTIME_DIR/strand-mailboxes/<strand>/*.msg`) into a
  forkchat-shape tree, pulling real `colour`/`dirs` from `super/strands/<s>/`
  and `active` from `/proc`. Proved strandchat renders real fleet coordination
  (aifabric-sessions + victim spool messages), not just the demo.

## Repo convergence (super ↔ aifabric)

- Model (recorded `43d5439` "convergence-by-symlink constitution"): PRs land in
  **aifabric** (canonical settling ground, air-gapped NiCE collaboration);
  **super** = daily kitchen; on settling, super symlinks to aifabric so Peter
  runs his own cooking. One copy, two framings.
- **Catch-up symlinks landed 2026-07-20:** `super/bin/ding` and
  `super/bin/forkchat` now → `~/aifabric/bin/*` (joining the pre-existing
  `super/bin/idea` precedent). The catch-up half no longer lags for these.
- **Format gap exposed by spool2mesh** (the real convergence decision): the
  live strand-mailbox spool is flat + loses sender/lineage; forkchat's
  `~/.forkterms` format wants `### src → dst`, colour, and parent. Unifying the
  repos means picking a direction — mailbox adopts the forkterm-tree shape, or
  forkchat learns to read the spool. `forkterm` + `strand-mailbox` are still
  super-only (not yet PR'd into aifabric).

## Pending / loose ends

- **The name.** strandchat = forkchat for now (synonymous, no rename today).
  Eventual rename `bin/forkchat` → `bin/strandchat` (+ `FORKCHAT_PASSWORD` →
  `STRANDCHAT_PASSWORD`, prose "forkterm mesh" → "strand mesh") tracks the
  aifabric convergence onto strand vocabulary. Do it when the repo does; not yet.

## Decisions

- **strandchat and forkchat are synonymous** — same tool, two names.
- **Strands are the more central idea; forks are the mechanism underneath.**
  Both are real; the scheme leads with strands, so the tool trends to
  "strandchat" in name over time.
