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

## The whole thing, plainly (2026-07-23)

The mechanism is already built and it's just this: **`aifabric/bin` is ahead of
`super/bin` on PATH.** That's the entire migration machinery. There's no "flip"
or "endgame" to engineer — as the aifabric method tools land in `aifabric/bin`,
the ordering quietly stops mattering. (An earlier version of this file grew an
over-engineered 5-step "invert the fallback" plan + secrets "knot" + blast-radius
tables. Deleted — it dressed up a job that's just "move a few files.")

**The only actual task: put the aifabric method tools in `aifabric/bin`.**
Candidates that are genuinely aifabric's (strands/forkterm/method): `forkterm`,
`strand-mailbox`, `strand-ps`, `strands`. For each: check it's self-contained
(no `source super/lib`), copy into `aifabric/bin`, delete the super copy, done.
Everything else in super/bin is super's and **stays** — secrets, wifi-speedtest,
astro, fleet, ssh helpers. Not the concern.

**One real hazard to watch (not urgent):** `aifabric/bin` is PATH position 1,
*ahead of `/usr/bin`*. A future graduated tool named like a system binary
(`test`, `time`, `ip`, `[`, …) would silently shadow it for every shell. Safe
today (only `ding`/`forkchat`/`idea`). Worth adding a check to `bin-shadows` for
aifabric-vs-system collisions, or just: don't name a tool after a coreutil.

**Only two things need care when deleting a super copy:** (a) it's self-contained;
(b) nothing calls it by the absolute path `~/super/bin/<tool>`. Known live
absolute refs that would need fixing if their tool ever graduated:
`claude-oauth-sync` (ansible systemd unit), `cld-statusline` (settings-shared.json),
`splay` (splay.desktop). None of those three are aifabric tools, so likely moot.

## Decisions

- strands: fresh repo (not full-history split); private.
- Repo layout: **extract + symlink**, not submodule — zero tool changes.
- aifabric hosts: **laptop-class only** (pip/muppet/puppy/vole), not fleet-wide.
- PATH: `aifabric/bin` before `super/bin` IS the mechanism; no flip event needed.
  super/bin's order stops mattering once the method tools have left it.

## See also

Memory: [[project_aifabric]] (air-gap boundary, PATH transition), [[project_strands]].
