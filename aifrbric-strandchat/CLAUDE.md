# Strand: aifrbric-strandchat

**strandchat** is the browser window onto the mesh — every strand (fork) with
its kinship colour and lineage, its message transcript, and a box to send a
message that shells out to the CLI and rings the peer's bell. The browser
becomes another driver of the mesh, alongside the terminal; the phone-onto-the-
mesh path (always-on home node behind Tailscale `--serve`).

**strandchat and forkchat are synonymous for now.** The shipped tool is
`aifabric/bin/forkchat` (PR #3, `c7f2046`) — the name "strandchat" reflects
where the vocabulary is heading. In the aifabric scheme both *strands* and
*forks* are real ideas, but **strands are the more central framing**: a strand
is the recurring workstream, a fork is the mechanism underneath. As the repo
converges on strand vocabulary, this tool becomes strandchat in name too.

- **Repo it spans:** `aifabric` (public-facing portfolio repo). The tool lives
  at `aifabric/bin/forkchat`. This strand dir under `super/strands/` holds only
  curation (mission/state/ideas); code commits go to aifabric.
- **Deliverable:** the `forkchat`→`strandchat` browser tool and its hardening.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
