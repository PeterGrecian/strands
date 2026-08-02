# Strand: aifabric

**The tools, libraries and templates that make stranding run — practical
stranding, presented as one portfolio cloth.**

`aifabric` (display name **"AI Fabric"**) is the *practice* half of the strand
system (the *theory* half is the [[strands]] strand). It owns the working parts:
the manywrapper library and its instances (`aicli`, `resolve-host`), the
`.template` scaffolds, forkterms, `idea`/`ding`/`spool`, the patterns/decisions
docs. These are **threads of one cloth**, woven so they reinforce each other —
that density is the thesis, and why it's also Peter's **principal portfolio**:
not a drawer of scripts but a coherent way of working with AI, read as a fabric,
not a pile.

It has outgrown `super` and earned its own home. Chosen model (revised
2026-07-31, superseding both "extract & migrate" and the timid "convergence by
symlink" step before it): **separation, PATH picks the winner.** `aifabric` and
`super` are *separate*, with no symlink either way. The aifabric/bin tools live
in `~/aifabric/bin`, which sits **ahead of** `super/bin` on `$PATH`, so typing
`cld`/`idea`/`ding`/… resolves to the aifabric copy directly — no link needed.
`super` does **not** reference aifabric: symlinking back into it wrongly implied
the aifabric tools were general-purpose `super/bin` fare, when they are
*specialised to the aifabric thrust*. The old `super/bin/*` links were historical
cruft and are gone (git carries the move history); PATH ordering does the work.
Published under `PeterGrecian` as the repo `aifabric`.

This is not a publish task — it's a **product extraction** to portfolio standard:
sever every dependency back into `super`/fleet, make each tool run **standalone**,
scrub to a bar higher than "not sensitive" (fleet-specifics are both a small leak
*and* portfolio noise), and present it as evidence of how Peter thinks and builds.

Precedent: `glacier-app`'s CLAUDE.md ("lives here until it graduates to its own
repo") — same trajectory. Pleasingly recursive: using the strand method to build
the portfolio *of* the method.

## Hard constraints (portfolio bar)

- **Standalone, uniquely.** No assuming `super/bin` on PATH; no `secrets get`
  against Peter's AWS/GCS; no `resolve-host` at his fleet. Each tool is either
  self-contained, or its external dep is abstracted behind a clean, documented
  seam (config/env) so a reader sees the *pattern* without needing his infra.
- **Code is the evidence.** Docs-only would be insufficient — it must contain
  runnable tools that *embody* the ideas (manywrapper as real multi-backend code,
  forkterms as a working mailbox), not essays about them.
- **`super` must keep working after the amputation.** `cld` and friends still run
  throughout — now via PATH ordering (aifabric/bin first), not via `super`
  linking back. Not "done" until the daily workflow is verified intact.
- **Publish under `PeterGrecian`** (personal, his name, "collaborations" bio) —
  the identity he *wants* associated. Not `-NiCE`, not a bridge account.
- **History decision per tool:** filter-repo/subtree-split to carry the evolution
  (probably yes — it's the story of the thinking), vs clean-start copy.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Graduated tools (`aicli`/`cld`, `idea`, `ding`, `forkchat`, `sessions`,
   `strands`, …) now live in `~/aifabric/bin` and are edited there — commit those
   changes to the `aifabric` repo, not `super`. Curation lives here in the strand.
4. Session end (or `dcp`): update STATE.md — what moved, what's pending, what
   coupling was severed, whether `super`'s workflow still runs.

## The air-gap / sovereignty context (why this repo is clean by design)

This strand is the *personal* portfolio. Keep it strictly to Peter's own general
method — never work (NiCE) content. The parallel work-side migration (offloading
`PeterGrecian-NiCE` code into a NiCE-governed home, the plane-based sovereignty
principle) is a *separate* effort captured in a hand-carried plan doc, NOT here.
