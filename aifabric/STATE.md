# aifabric — STATE

*Curated state of the aifabric extraction. Prose, not a log. Updated at session end / on dcp.*

## What this is

Extract Peter's AI working method from `~/super` into a standalone repo
**`aifabric`** (display name "AI Fabric") — his principal portfolio. Not a drawer
of tools: a *fabric* — the manywrapper library and its instances, strands,
forkterms, and the patterns/decisions docs are threads of one cloth. Model:
**extract & migrate** (the pieces move out, `aifabric` is their live home).
Publish under `PeterGrecian` as `aifabric`.

## ding doorbell: waiter lifecycle fixed (2026-07-21)

The `ding --arm` doorbell had a **stale-waiter bug**: a waiter whose session
ended abnormally (SIGKILL / terminal closed / crash — the harness never killed
its background task) was reparented to init and lived forever (`timeout 0` =
wait forever), then **stole the next mail** written to its mailbox
(consume-on-read truncates before the live waiter sees it) — so the doorbell
silently failed to ring. This was the reported symptom.

Fixed in two layers (see memory `project_ding_waiter_lifecycle`):
- **Owner-death self-clean** — waiter records its owning `claude` session and
  exits 3 within one ~30s poll of the owner dying. Handles abnormal exits.
- **`ding --reap`** — sweeps waiters whose owner PID is dead (never a live
  one); `cld` runs it before + after every session, closing the ~30s window
  for clean exits and clearing a SIGKILLed prior session's orphans.

Also **converged the diverged copies**: canonical is now `~/aifabric/bin/ding`
only; `super/bin/ding` and `super/strands/strands/ding` are both symlinks to
it (the on-PATH copy had been the *older, buggier* one). Tested end-to-end
(self-clean fires, reap kills orphans + spares live waiters, delivery still
rings). Committed aifabric `471796c`, super `53ce18b`; both pushed. `super`
workflow verified intact (`cld` syntax-checked, reap is fail-safe `|| true`).

**Spun off → `aifabric-spool` strand (2026-07-21).** The waiter fix exposed a
deeper issue: the mailbox itself is a *single-slot file* with the same
concurrent-write hazard the `idea` tool already solved by spooling —
`cat > MAILBOX.md` overwrites an unread message, and the receiver's `: >`
consume-truncate races a concurrent send. Rather than hand-code a spool a
second time inside `ding`, Peter's call is to **extract a generic `spool` tool**
(`aifabric/bin/spool`: `put`/`drain`, one-file-per-item, clobber-safe) and refit
both `idea` (write) and `ding` (write+drain) onto it. Scaffolded as its own
strand with a full FORKTERM-BRIEFING; `ding` left at the clean committed state
`471796c` for the refit. STATE.md dcp-collision is noted but explicitly out of
scope (one-curator convention for now).

## Naming (2026-07-17)

Renamed **aitooling → aifabric**. "Fabric" is denser and truer than "tooling":
it's an interwoven method, not a collection of scripts. Repo/CLI/paths are
lowercase `aifabric` (Unix-conventional, greppable); human-facing display name is
**"AI Fabric"**. Strand renamed to match (one name top-to-bottom kills drift).
Individual tools keep their own names (`aicli`, `resolve-host`) as threads.

## Decisions made (2026-07-16)

- **Extract & migrate**, not a curated derivative and not a fresh rebuild —
  chosen for integrity (portfolio == real working set) and to kill the drift /
  two-homes problem for good. One copy, his.
- **Portfolio bar**, not just "not sensitive": fleet-specifics (IPs, hostnames,
  secret paths) are portfolio noise as well as leaks — scrub harder than for a
  merely-private repo.
- **Must be standalone**: sever deps back into `super`/fleet; abstract external
  deps behind documented seams so the *pattern* shows without needing his infra.
- **Code is the evidence** — runnable tools embodying the ideas, not docs alone.
- Publish under **`PeterGrecian`** (name + "collaborations" bio), the identity he
  wants attributed. Not `-NiCE`, not a bridge.

## Candidate contents (from the super allowlist analysis)

Proven-clean method docs (publish-ready today):
- `patterns/{bash-style,python-style,debugging,terraform}.md`
- `docs/decisions/{manywrapper,time-hierarchy,aisetup}.md`  *(aisetup: verify it
  doesn't quote GLOBAL.md/paths before including)*
- `strands/README.md`, `strands/strands/{forkterms,MAILBOX-naming,MAILBOX-worktransfer}.md`

Tool code (the harder, higher-value extraction — needs per-tool decoupling + scrub):
- Exemplars of the patterns: the manywrapper tools (`resolve-host`, `secrets`
  shape), `cld` (session launcher / strand mechanism), forkterm mailbox tooling.
- Each: identify coupling to `super/bin`, fleet, AWS/GCS; abstract or excise.

## Pending / next

1. **Cut-line inventory**: for each candidate tool, list its dependencies back
   into `super`/fleet/cloud → classify portable-method vs fleet-glue-that-stays.
2. **Decouple design**: the clean seam for each external dep (config/env), so
   tools run standalone.
3. **History decision** per tool: subtree-split (carry evolution) vs clean copy.
4. **Scrub-to-public**: the repo is on GitHub but *private* (see "Published"
   below); the portfolio-bar scrub of the grabbed docs/tools (fleet hostnames,
   personal-infra noise) is now the gate to flipping it public.
5. **Migrate tool-by-tool**, verifying `super`'s `cld` workflow stays intact after
   each move (don't big-bang it).
6. **Portfolio polish**: README that frames the ideas; each tool's `--hints`/help
   readable as a demonstration.
7. **`manywrapper` library + `aicli` flagship** — the meta move (2026-07-17):
   lift the manywrapper *pattern* (multi-backend, random-first/ordered/write-all,
   `--hints`, availability-first) out of convention and into a small **collection
   of helper functions** (NOT a framework — no Backend/Registry/Result classes;
   Peter: "it should be simple"). Instances stay plain scripts that call the
   helpers. Python (matches super tooling; portfolio-legible).
   - **Helpers**: `random_first`, `ordered`, `write_all`, `first_available`,
     plus `--hints`/`--list`/`--backend` CLI harness and warn-on-fallback (the
     identical boilerplate every current instance re-implements by hand).
   - **`CmdBackend` insight**: a backend is often just `{name, check, run}` —
     three strings. So command-shaped tools (aicli, resolve-host) declare
     backends as **TOML config** (`aicli.toml`) against a generic runner; richer
     backends (secrets' SSM/GCS API calls) stay as Python functions. Config is
     the easy path, code is the escape hatch. Library-is-the-evidence; config is
     one *kind* of backend — satisfies "code is the evidence" without ceremony.
   - **`aicli`** is the flagship instance: wraps `claude`/`copilot` (extensible),
     availability-first, `--backend` override, `--hints`. **Auth is NOT the
     wrapper's concern** — dispatches to CLIs that carry their own creds (like
     `aws`/`gh`/`git`); an un-authed backend is simply "unavailable" and `--hints`
     points at *its* auth docs. Build clean; do NOT copy the NiCE work version.
     Never touches `secrets` — decoupled from the secrets question below.
   - **Meta-story**: aicli + resolve-host + a secrets-shape exemplar = three
     instances of one library. Pattern doc, library, and instances are the same
     idea at three altitudes — the fabric woven visibly.
   - **Terminology**: standardise on "manywrapper" (docs/decisions/manywrapper.md
     is titled "Polywrapper" — stale; fix on extraction).
8. **`secrets` disposition** (fleet-coupled, not portable): keep in `super` as
   fleet glue, OR ship the *pattern* as an exemplar with generic-default pluggable
   backends (env/`pass`/local file; AWS/GCS optional). Separately, "make `secrets`
   more standard" — `pass` / `age`+SOPS / documented env — is a `super`-side infra
   task, decoupled from `aicli`.

9. **Air-gap consumption model** (promoted from IDEAS 2026-07-17): the master
   `aifabric` repo lives on the *personal* side and is the source of truth. The
   work (NiCE) side *pulls it as a collaborator* — it might need to open a PR to
   write back across the air gap, never a direct push. This is the sanctioned
   one-way-ish flow: personal fabric → work consumes it; work improvements return
   by PR for Peter to accept. Keeps the sovereignty boundary clean. (Design later;
   not blocking the extraction. The parallel work-side migration stays in the
   hand-carried plan doc, NOT here.)

10. **Define the keeper system** (idea dropped 2026-07-17 by splay-ai-discovery;
    triaged & promoted 2026-07-17, spool file swept). Directly unblocks the
    "define the keeper system" prerequisite the `ideas`-tool handoff is waiting on
    (see `## ideas tool` section) and the keeper-per-repo principle. Proposed
    taxonomy: **strand** = curation; **keeper** = a role/stance (owns a subject,
    serves intelligence, improves it); **forkterm** = a resident keeper. A keeper
    serves at two altitudes matching lazy-context: a cheap self-discoverable
    **`hints`** surface (its published API, templated on `secrets hints`) + an
    expensive keeper session/forkterm. `mywebsite-keeper` is the live precedent;
    `splay hints` would be the second `hints` instance (two = a pattern). The
    keeper doc is a strong "first filled-in concept" for the portfolio.

## Ideas triaged in (2026-07-23)

Promoted from the ideas inbox. Grouped; forkterm/strand-ps cluster reconciled.

**forkterm / liveness cluster** (the strand-ps "bug" was self-retracted — no
strand-ps ever existed; `strands` already has `/proc`-based `live_cwds()` done
right; the near-miss was operator error. Two real remainders survive):
- **forkterm dup-session guard** — the shared entry point now EXISTS:
  **`super/bin/strand-ps`** (built 2026-07-21, on PATH, `/proc`-based, `-s
  <name>` filters, `--hints`) is the "real strand-ps" PR #5 gestured at.
  Remaining work: `forkterm into <strand>` should consult `strand-ps -s
  <strand>` (dup = >1 row) and warn "a live session already has cwd in this
  strand — raise it? (y/N)" before launching a duplicate. (Absorbed here from
  the retired `aifabric-strand-ps` strand, archived 2026-07-25.)
- **forkterm window raise + stable handle** — today windows can't be identified
  or raised: every window launches with the same static `--title="forkterm:
  $STRAND"`, and on xfce4-terminal `--title` only sets the *initial* title
  (claude clobbers it). Fix: give each window an immutable X11 identity at launch
  — `--role="forkterm:$STRAND:<shortid>"` (or a distinct WM_CLASS), targetable by
  `wmctrl -x` / `xdotool search --role`. Add `forkterm ls` (enumerate live
  windows by role → strand + pid + age, cross-ref `/proc/<pid>/cwd`) and
  `forkterm raise [strand|id]` (`wmctrl -ia`). xfce/X11-first, degrade gracefully.
  Pairs naturally with the dup-guard (one small live-forkterm registry feeds both).

**ding waiter cleanup on cld exit** — on `cld` session exit, tear down any
`ding --arm` waiters that session spawned, via a trap/cleanup in `cld` (the
natural owner — waiters are per-session background tasks), rather than trusting
each session to disarm by hand. Bonus: a `ding --list` / stale-waiter reaper
(find `ding --arm` procs whose parent shell is gone) self-heals the crash case
where the exit trap never fires. (Partly addressed by the 2026-07-21 `--reap`
work above — check overlap before building.)

**check-PATH-first reflex** — make "is there already a tool for this on PATH?"
the *first* move before writing any helper/glue/file-drop, not a rule that fires
after building has started. Already in memory (`feedback_check_house_tools`) but
too late-firing. Document it where sessions actually look: a one-line convention
at the top of `ideas/README` and in the strand ritual — "before hand-rolling,
`compgen -c | grep` / `ls ~/super/bin` / `<verb> --help`". Prompted by two
house-tool near-misses in one session (nearly re-derived mailbox delivery, then
hand-wrote an ideas/ file when `idea` already existed).

**auto-stranding** — every repo should have a strand; every subproject in
Berrylands too; they should all live in `~/strands`. Worth an auto-scaffold pass.

**auto-trust cld starting dirs** — "can we auto-trust cld starting dirs? yes I
trust them." Skip the per-dir trust prompt for the strand/`--add-dir` set that
`cld` itself hands to claude.

**always monitor the mailbox** — a session should always be watching its mailbox
(relates to the ding/strandchat waiter work).

**remote-to-Slack an existing session** — `cld --remote` starts a *new*
backgrounded Remote Control session and posts the connect URL to Slack. Can we
instead attach remote-control to an *already-running* session? (Peter, asked
2026-07-23.)

**mywebsite favicon inconsistency** (reroute → mywebsite) — favicons are
inconsistent: sometimes the tick shows (could be cleaned up), sometimes not.
Possibly only the desktop/home-screen icons on a phone. Not aifabric's domain;
recorded here for routing to the mywebsite work.

## bin migration — cld/sessions divergence to reconcile (2026-07-25)

Five strand/session tools graduated from `super/bin` to `aifabric/bin` on
2026-07-25 (`strands`, `strand-ps`, `strand-mailbox`, `forkterm`,
`cld-statusline` — canonical here, no super symlink; PATH puts aifabric/bin
first). **RESOLVED (2026-07-25, aifabric-bin-migration sub-strand) — `bin-shadows`
now 0 divergent:**

- **`cld`** — `aicli` made a true SUPERSET of super's old `cld` (folded in
  `-k` housekeeping, `--remote`+Slack, `--tmux`+orphan detection, `ding --reap`
  before/after, health warnings, `--hints`), then `super/bin/cld` → symlink →
  `aifabric/bin/cld`. Claude backend now runs as a child (not exec) so
  after-reap/after-push run; copilot still execs. Fleet helpers resolved on
  $PATH via `fleet_helper()`; the `$BIN/../strands` coupling is gone (STRANDS_DIR
  resolves from `~/.config/idea/config`). aifabric `6cff4e1`, super `bde32a7`.
- **`sessions`** — aifabric kept canonical; super's LAN node defaults +
  `secrets get /osd/admin-password` fallback folded in *lazily* (no import-time
  fetch, no baked credential). `super/bin/sessions` → symlink. Verified live.
  aifabric `015fa93`, super `e9119d9`.
- **Bonus:** `aicli-completion.bash` (existed but unsourced) wired into dotfiles
  `.bashrc` + updated with the new flags. dotfiles `3c5def1`.

Verified: `bin-shadows` = 5 same-inode, 9 aifabric-only, **0 divergent**;
stubbed-`claude` smoke tests of every folded flow; `sessions` stats/search/show
live. See the aifabric-bin-migration strand STATE for full detail.

Deliberate behaviour change: unknown strand now DIES with a `--create` hint,
not super's interactive scaffold prompt (non-interactive-safe; the prompt was a
documented automation footgun).

## Published (2026-07-17) — early push for collaboration

`PeterGrecian/aifabric` created on GitHub, **private**, and `PeterGrecian-NiCE`
invited as collaborator (write; invitation pending acceptance). This overrides
the earlier "hold push until flagship + README" — Peter is short of Claude
quota and wants the work side able to progress the extraction. Consistent with
the air-gap model (#9): work side pulls + contributes **by PR only, never
direct push to main**. That rule is convention, not enforcement — branch
protection isn't available on a free-plan private repo; revisit when public.
**Private until the portfolio-bar scrub** (pending #4); README documents the
collaboration rule and migration table.

**Grabbed from super** (copies, NOT graduations — live home stays super until
each piece is decoupled): patterns ×4 and decisions ×3 → `docs/`;
`strands/README.md` + `forkterms.md` + both MAILBOX exemplars + strand
`.template/` → `method/`; `ding` → `bin/`; raw `cld` + `resolve-host` →
`incoming/` (fleet-coupled, awaiting seams). `secrets` deliberately NOT
grabbed (highest leak density; disposition still open, #8).

## Verified (2026-07-17) — inter-strand comms works

The armed-waiter doorbell is **proven end-to-end**: (a) primitive — background
`inotifywait` waiter + foreign writer woke the agent between turns, no human
input; (b) tooling — `ding` grew an `--arm` receiving leg (default
`$PWD/MAILBOX.md` address, consume-on-read, immediate delivery closes the
write-before-arm race, timeout exit 2, re-arm per wake), all paths tested;
(c) composite — a live strands-peer session was launched autonomously,
answered an aifabric question mailbox-to-mailbox, and re-armed resident.
forkterms.md carries the verification stamp. Remaining is convention:
arm-on-idle/re-arm ritual, and live-strand discovery.

## Session close (2026-07-20)

Tailnet stood up on **puppy** (MagicDNS `tailc34ab9.ts.net`, HTTPS certs
enabled; homepi + pixel-6a already members) — resolves the phone-reachability
question raised for forkchat/strandchat. OSD dashboard fronted at
`https://puppy.tailc34ab9.ts.net/` via `tailscale serve` (targets the LAN
bind; localhost gave 502 — noted for the keeper). pip stays off the tailnet;
LOCALCLAUDE.md updated. Credential-handling policy settled: phone-facing
creds/URLs go via Google Password Manager/Bookmarks sync (create on pip, Peter
saves), not Slack — new memory `feedback_phone_credentials`.

Vocabulary settled: **strandterm/strandchat** = the resident thing (live
session, terminal or browser, however born) vs **forkterm/forkchat** = the
spawning mechanism. Completes the substrate-agnostic active-strand grid.
Routed to strands inbox; memory shows a `project_strandchat` already exists
(keeper's own naming landed independently — reconcile at next strands triage)
and a stray `strands/aifrbric-strandchat/` dir appeared (typo'd name?) —
check at next session, don't assume its purpose.

Topology recommendation given (not yet built): a resident strandterm *team*
belongs on puppy/muppet (RAM + colocation with the mesh for inotify), not
homepi (windows only, can't host agents) or vole (tiebreaker stays lean).
Caution logged: resident strandterms are expensive against the 5h quota
window — cleft showed this starkly today; arm-and-idle discipline needed.

## Constitution revised (2026-07-19): convergence by symlink

Peter ratified the model the NiCE side's README reframe (PR #2) was reaching
for: **super = daily kitchen, aifabric = where pieces settle as clean
canonical copies; on settling, super symlinks to aifabric's copy.** One copy,
two framings — "what he shows is what he runs" holds *via the link*. CLAUDE.md
updated. First convergence act done: `super/bin/idea → ~/aifabric/bin/idea`
(work-built tool, config/env seam, works in place). PRs fielded: #1 #2 merged
by Peter, #3 (forkchat, browser onto the forkterm mesh) reviewed + merged
2026-07-19 — clean, well-hardened; its mesh format (~/.forkterms tree +
`forkterm send`) nominated as the convergence spec for home's
ding/strand-mailbox/forkterm consolidation (asked NiCE side for
docs/decisions/forkterm-mesh.md in the PR thread). Backlog noted (Peter):
"loads of bins aifabric does not have." Also 2026-07-19: homepi transcript
trove secured (67 files incl. gardencam-era → ~/archives/), routed to the
sessions keeper; forkchat-at-home (tailscale, AI filter) is a future adoption
item — fleet isn't on tailscale yet.

## Session 2 (2026-07-18) — archaeology, the sessions spin-off, hints salience

- **Session archaeology**: Claude Code's default 30-day reaper had been silently
  deleting transcripts all along — months lost. Recovered muppet's un-reaped
  trove (2026-03-03–04-21, incl. cloud-init-init + gardencam eras; stereo
  photography predates even that, gone). Archives at `~/archives/`.
- **Portfolio evidence found**: strands born 2026-07-10; within 8 days, 25
  strands and near-total adoption in the session record. March's "Explore the
  repository…" prompts → July's strand launches = the method's evolution in
  primary sources. Use this arc in the aifabric README/story.
- **`aifabric-sessions` strand born** (via `forkterm into`; first *commissioned
  keeper*): owns the session archive + RAG (OpenSearch on puppy → 3-node
  cluster puppy/muppet/homepi in progress). Keeper model ratified with Peter:
  three altitudes — **tool < hints < digest** — and raw retrieval never passes
  through a keeper's context in either direction. `sessions` CLI + `--hints`
  commissioned to the keeper (it owns the schema); embeddings+kNN approved
  (hybrid, local-only). This is live input to pending #10 (keeper-system doc).
- **Hints salience law** proven and acted on: agents only reach for tools that
  describe themselves (secrets salient, forkterm invisible). GLOBAL.md gained
  the look-first rule + a 22-tool table (interim until hints everywhere);
  `cld --hints` + `forkterm --hints` added; audit + rollout list in
  strands/strands/IDEAS.md. Also new memory: feedback_check_house_tools.
- **Comms toolset note**: three overlapping comms tools exist (ding,
  strand-mailbox, forkterm) — consolidation is aifabric extraction work; the
  merged tool is the portfolio's inter-agent comms exhibit.

## Built so far (2026-07-17)

- **`~/aifabric` scaffolded** (`git init`, not yet on GitHub — hold push until it
  has a working flagship + README).
- **`manywrapper/manywrapper.py` sketched** and smoke-tested (imports + runs on
  py3.13). It's a *collection of functions*, not a framework, per Peter:
  - `Backend` = a dataclass record `{name, run, check, hint}` — data, not a base
    class to subclass.
  - `cmd_backend()` + `load_manifest()` = the CmdBackend insight: command-shaped
    backends declared as TOML (`[[backend]] name/run/check/hint`); dispatch via
    `os.execvp` (passthrough, never returns).
  - Selection helpers: `random_first`, `ordered` (both select on `run()`
    succeeding, warn-on-fallback), `write_all` (run every *available*, failure =
    raises), `first_available(prefer=)` (aicli: selects on `check()`, `--backend`
    override is an explicit error if unavailable, not silent fallback).
  - CLI harness: `print_list` (backend + availability), `print_hints`.
  - **Two selection axes confirmed distinct** (surfaced by the smoke test):
    read-tools select on the *operation* succeeding (`random_first`/`ordered`);
    dispatch-tools select on *availability* (`first_available`). This IS the
    value-vs-dispatch "model both" choice, working concretely.
  - **TODO in sketch**: a `main(backends, strategy)` convenience wiring
    --list/--hints/--backend/--help so an instance is ~10 lines — deliberately
    left until `aicli` drives its exact shape (don't abstract ahead of the use).

- **IDEAS.md is now the explicit collection point** for aifabric ideas from other
  active strands: append-only under the marker line, `— <strand>, <date>`
  provenance tags, clobber-safe convention documented in the file.

## `idea` tool → aifabric/bin — BUILT (2026-07-19)

**Live.** `aifabric/bin/idea` exists (symlinked `super/bin/idea` → canonical, on
PATH); singular name (`idea "<thought>"`, writes ONE spool file). Writes a
clobber-safe `YYYYmmddThhmmssZ-XXXXXX` file into a strand's `ideas/` spool; strand
resolved from `$STRANDS_DIR` / `~/.config/idea/config` / `$PWD` / tty `.tty` match;
`-s <strand>` to target, stdin accepted, `--hints` for AI-facing context. Built to
the manywrapper standard (self-describing). The aifabric `IDEAS.md` header now
points writers at it (2026-07-21). Earlier "BLOCKED on super-keeper" note is
superseded — it got built directly.

- The **`ideas/` spool** is the durable inbox — one file per idea, unique
  filename = clash-proof by construction. The tool is the writer; the strand
  drains the spool into `IDEAS.md` at triage and sweeps files to `~/.trash`.
- `idea` (the tool) and the spool *pattern* are portable → aifabric portfolio.
  The keepers that use them are your-setup glue → stay in super/repos.
- Follow-up: `ideas/README.md`'s hand-format filename example is older than the
  tool's actual `…Z-XXXXXX` scheme — reconcile when next in there.

## Next build steps

1. `aicli` + `aicli.toml` (claude/copilot) as the first real consumer of
   `first_available` — validates the harness shape, tells us what `main()` should
   be. Then decouple `resolve-host`/`secrets` as uses 2/3.
2. ~~`ideas` tool~~ — **done** (`bin/idea`, 2026-07-19; see section above).

## Blockers / watch

- `super` must not break mid-extraction — `cld`, `dcp`, `secrets`, `resolve-host`
  are load-bearing daily. Verify after each move.
- Keep strictly personal — no NiCE/work content ever enters this repo.
