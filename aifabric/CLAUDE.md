# Strand: aifabric

Extract Peter's AI working method out of `~/super` into its own standalone repo,
**`aifabric`** (display name **"AI Fabric"**) — his **principal portfolio**. Not
a drawer of tools: a *fabric*. The pieces — the manywrapper library and its
instances (`aicli`, `resolve-host`), strands, forkterms, the patterns/decisions
docs — are **threads of one cloth**, woven so they reinforce each other. That
density is the thesis: what Peter has is not a collection of scripts but a
coherent way of working with AI, and the portfolio should read as that fabric,
not as a pile.

It has outgrown `super` and earned its own home. Chosen model (revised
2026-07-19, superseding "extract & migrate"): **convergence by symlink** —
`super` is the daily kitchen (eating our own exquisite cuisine); `aifabric` is
where a piece *settles* as its clean canonical copy; when it settles, `super`
symlinks to it (first: `super/bin/idea → ~/aifabric/bin/idea`). One copy, two
framings: what he shows IS what he runs, via the link. Published under
`PeterGrecian` as the repo `aifabric`.

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
  throughout. Not "done" until the daily workflow is verified intact.
- **Publish under `PeterGrecian`** (personal, his name, "collaborations" bio) —
  the identity he *wants* associated. Not `-NiCE`, not a bridge account.
- **History decision per tool:** filter-repo/subtree-split to carry the evolution
  (probably yes — it's the story of the thinking), vs clean-start copy.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. During extraction, tooling changes still commit to `super` until a tool
   graduates cleanly into `aifabric`; curation lives here.
4. Session end (or `dcp`): update STATE.md — what moved, what's pending, what
   coupling was severed, whether `super`'s workflow still runs.

## The air-gap / sovereignty context (why this repo is clean by design)

This strand is the *personal* portfolio. Keep it strictly to Peter's own general
method — never work (NiCE) content. The parallel work-side migration (offloading
`PeterGrecian-NiCE` code into a NiCE-governed home, the plane-based sovereignty
principle) is a *separate* effort captured in a hand-carried plan doc, NOT here.
