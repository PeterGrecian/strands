# super-to-aifabric — state

*Curated summary of where this strand is. Updated at the end of each session.*

## Mission

Carve Peter's AI working method out of `super` and into its own repos, and make
`aifabric` the work-facing canonical home. Two motives: (1) `super/strands` grew
too big to live inside super; (2) **aifabric is the only part of Peter's GitHub
that work shares** — so it must be a self-contained, air-gapped surface.

## Done (2026-07-22)

- **strands extracted → `PeterGrecian/strands`** (private). Content moved to
  `~/strands`; `~/super/strands` is a **symlink** to it, so `cld -s`, `strands`,
  and every `$SUPER/strands` path resolve unchanged. super untracks + gitignores
  it. Fresh repo (history stays in super's log). Verified: tooling + LIVE
  detection work; the 8 live strand sessions survived the move.
- **`.template` converged → aifabric canonical.** The strand template was
  byte-identical in both repos; `~/strands/.template` now symlinks to
  `~/aifabric/method/template`. `strands new` scaffolds through it (verified).
- **ansible provisioning** (via forkterm into the `ansible` strand, its commit
  `280ee14`): `git-repos` role clones aifabric + strands on laptop-class hosts
  only — **pip / muppet / puppy / vole**. Rolled out + verified on all four;
  super/strands symlink resolves everywhere. vole needed the shared fleet SSH
  key (installed).
- **PATH flip**: `~/aifabric/bin` ahead of `super/bin` for **all** shells that
  source `.bashrc`. First landed interactive-only (commit `8886c9b`), then moved
  **above `.bashrc`'s non-interactive early-return** (commit `bc51cea`) so
  ssh-command / cron / script shells also get aifabric-first — needed as
  super/bin entries get deleted. Order: aifabric/bin first (fabric canonical),
  super/bin after (fallback drawer), both dedup-guarded. Guarded on aifabric/bin
  existing. Ships to the 4 hosts via the dotfiles ansible role. (Only truly
  uncovered case: bare `ssh host cmd` with no BASH_ENV — never had these dirs
  anyway, so no regression.)
- **`bin-shadows`** guard added to super/bin (commit `367a38e`): flags DIVERGENT
  name collisions between the two bins (silent-shadow bug); exit 1 on divergence.
  Run it after moving any tool into aifabric/bin, and from housekeeping.

## Governing constraint (air-gap)

Convergence-by-symlink is **one-way**: pieces settle INTO aifabric as
self-contained; **aifabric must never symlink to / import from / reference
super, strands, or the fleet** (would dangle for the NiCE collaborator who only
has aifabric, or leak a private path). strands→aifabric links (`bin/ding`,
`.template`) are the safe direction. Every tool that graduates into
`aifabric/bin` must be self-contained (no `source super/lib/...`).

## Decision (2026-07-23): invert the fallback — end-state target set

Peter's call: the **target end-state is super/bin OFF the default PATH** —
aifabric/bin becomes the sole primary, not just the first entry. Today super/bin
is still a PATH fallback (73 tools, only 3 graduated), so the flip is the *last*
step, not the first: it can only happen once everything still needed has either
graduated or been deliberately retired. **This session is plan-only — no tool
moves.** The ordered plan below is the durable artifact.

## The secrets knot (the thing that gates the whole endgame)

`secrets` is (a) the most-depended-on super/bin tool, (b) referenced by
**absolute path** `~/super/bin/secrets` in live code (`cfai` 4×, `r2-put` 2×,
`sessions` 2×), and (c) **cannot graduate to aifabric** — it talks to AWS SSM +
the private GCS bucket `petergrecian-secrets`, exactly the personal-infra the
air-gap rule forbids in aifabric. It's also mandated by GLOBAL.md ("never call
SSM/GCS directly"). So `secrets` is the **permanent resident of super/bin**.
Consequence: inverting the fallback does NOT mean super/bin empties — it means
super/bin shrinks to a small non-graduatable core (secrets + its private-infra
kin) that must stay reachable by some means other than the default PATH fallback
(explicit opt-in entry, or absolute-path callers only). Loosening step, deferred:
make `cfai`/`r2-put`/`sessions` call `secrets` via PATH (bare name) not absolute
path — touches Cloudflare/R2 auth, test carefully.

## super/bin classification (2026-07-23, 73 entries)

- **Not self-contained (source super/lib)** — air-gap blockers, cannot graduate
  as-is: `datedir`, `ssp`. (`ssp` is human-only + fleet-specific anyway → stays.)
- **secrets cluster** (stay in super, private-infra): `secrets`,
  `secrets_wrapper.py`, and its callers `cfai`, `r2-put`, `sessions`, `ai-gists`,
  `yt-upload`, `hub-leases`.
- **Live cross-refs that gate deletion** (fix before removing the super copy):
  - `claude-oauth-sync` — ansible systemd unit hardcodes
    `ExecStart=/home/peter/super/bin/claude-oauth-sync` (template
    `claude-oauth-sync.service.j2`).
  - `cld-statusline` — `dotfiles/.claude/settings-shared.json` hardcodes it.
  - `splay` — `dotfiles/.local/share/applications/splay.desktop` `Exec=` hardcodes
    it; `splay-launcher` falls back to the absolute path (tries `which` first).
- **Cruft to just delete/trash** (not tools): 6× `wifi-speedtest-*.csv`,
  `__pycache__`, stray `ssp_test`/`ssp.md`.
- **Everything else** — fleet/personal-infra tools that mostly never graduate
  (astro, wifi, stereo, vm, ssh helpers). super/bin stays their home.

## Ordered plan to reach the inverted end-state

1. **Wire `bin-shadows` into housekeeping** (all-repos-status / `cld -k`) — close
   the guard so divergence is caught automatically. (Smallest, do first.)
2. **Trash the cruft** — the `wifi-speedtest-*.csv` data files + `__pycache__`
   out of super/bin (via `trash`, not rm).
3. **Graduate the zero-live-ref, self-contained tools** into aifabric/bin
   (the strand/method tools: `forkterm`, `strand-mailbox`, `strand-ps`, `strands`
   itself — verify each is self-contained first; run `bin-shadows` after each;
   delete the super copy once no absolute ref remains).
4. **Fix the 3 hardcoded live refs** so those tools can graduate cleanly:
   `claude-oauth-sync.service.j2`, `settings-shared.json` (cld-statusline),
   `splay.desktop` + `splay-launcher` — repoint to PATH/aifabric or accept they
   stay in super.
5. **Loosen the secrets knot** — `cfai`/`r2-put`/`sessions` call `secrets` via
   PATH not absolute. Then decide secrets' permanent home (stays in super/bin as
   the non-graduatable core).
6. **Invert the fallback (LAST)** — drop `super/bin` off the default PATH in
   `.bashrc`; provide an explicit opt-in for the residual super-only core, OR
   confirm every survivor is reached by absolute path / systemd and needs no PATH
   entry. Roll out via the dotfiles ansible role to the 4 hosts. Verify nothing
   breaks in interactive + non-interactive + cron shells.

- **manywrapper convergence** (still deferred): make super's tools source
  `~/aifabric/manywrapper/manywrapper.py` as canonical. Deeper — touches
  secrets/resolve-host; test carefully. Related to step 5.
- **scrub-to-public prep** — ongoing air-gap audit of aifabric (fleet
  hostnames, personal-infra references) before it goes public.
- Consider whether every host that has `super` should also get `strands` (the
  `super/strands` symlink dangles on hosts without it). Currently only the 4
  laptop-class hosts get strands; other super hosts have a dangling symlink.
  Harmless today (they don't run strand tooling) but worth a decision.

## Deletion blast-radius (before removing anything from super/bin)

PATH resolution is handled; the remaining risk when deleting a super/bin tool is
**hardcoded `~/super/bin/<tool>` absolute references** (sweep re-runnable:
`grep -rn "super/bin/" ~/super ~/ansible ~/dotfiles ~/strands`). Current
absolute references, by tool (2026-07-22):
- `secrets` (7×) — the big one; update all before secrets/manywrapper graduates.
- `cfai` (4×), `splay` (2×), `sessions` (2×), `r2-put` (2×).
- 1× each: `cld-statusline`, `yt-upload`, `strand-ps`, `splay-launcher`,
  `ship-astro-data`, `gh-exposure-audit`, `claude-oauth-sync` (an ansible
  systemd unit — `ExecStart=/home/peter/super/bin/claude-oauth-sync`), `bin-shadows`.

Most are super-internal and won't graduate. Rule: before deleting a tool from
super/bin, fix its absolute references (or leave a symlink). Many of these will
never move — the list is the check, not a migration plan.

## Decisions

- strands: fresh repo (not full-history split); private.
- Repo layout: **extract + symlink**, not submodule — zero tool changes.
- aifabric hosts: **laptop-class only** (pip/muppet/puppy/vole), not fleet-wide.
- PATH: keep `super/bin` as a permanent fallback (second), don't drop it.

## See also

Memory: [[project_aifabric]] (air-gap boundary, PATH transition), [[project_strands]].
