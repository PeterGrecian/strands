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
- **PATH flip**: `~/aifabric/bin` now ahead of `super/bin` in interactive shells
  (dotfiles commit `8886c9b`), guarded on the dir existing. Graduated tools
  (ding/forkchat/idea) resolve from aifabric first; super/bin is the fallback
  drawer. Non-interactive shells still reach them via super/bin's symlinks (same
  inode). Ships to the 4 hosts via the dotfiles ansible role.
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

## Pending / next

- **Wire `bin-shadows` into housekeeping** (`cld -k` / all-repos-status path) so
  a divergent duplicate is caught automatically, not just by hand.
- **Graduate more tools into aifabric/bin** as they settle (candidates from
  memory: `manywrapper` lib as canonical, `forkterm`, `strand-mailbox`). Each
  must be self-contained per the air-gap rule; run `bin-shadows` after each.
  **Keep a `super/bin` symlink** to each graduated tool, else non-interactive
  shells (which don't get aifabric-first PATH — `.bashrc` returns early) won't
  find it. Interactive = aifabric direct; non-interactive = super/bin symlink →
  same file. bin-shadows enforces the two never diverge.
- **manywrapper convergence** (deferred this session): make super's tools source
  `~/aifabric/manywrapper/manywrapper.py` as canonical. Deeper — touches
  secrets/resolve-host; test carefully.
- **scrub-to-public prep** — ongoing air-gap audit of aifabric (fleet
  hostnames, personal-infra references) before it goes public.
- Consider whether every host that has `super` should also get `strands` (the
  `super/strands` symlink dangles on hosts without it). Currently only the 4
  laptop-class hosts get strands; other super hosts have a dangling symlink.
  Harmless today (they don't run strand tooling) but worth a decision.

## Decisions

- strands: fresh repo (not full-history split); private.
- Repo layout: **extract + symlink**, not submodule — zero tool changes.
- aifabric hosts: **laptop-class only** (pip/muppet/puppy/vole), not fleet-wide.
- PATH: keep `super/bin` as a permanent fallback (second), don't drop it.

## See also

Memory: [[project_aifabric]] (air-gap boundary, PATH transition), [[project_strands]].
