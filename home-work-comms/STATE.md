# home-work-comms — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **The home-owned instance of the home↔work comms keeper** (this strand).
  Scaffolded 2026-07-21; keeper pattern defined in `aifabric/method/keepers.md`.
  Durable method-only answer ("how does home communicate with work?") still to
  be written on a live session — bootstrap refs are in CLAUDE.md.
- **Sibling instance being stood up (2026-07-21): `work-home-comms`** on the
  work laptop — the work-owned mirror. Same pattern, work-governed location and
  remote, holds the work view. The two are separate strands that never share
  files; they agree only through the shared aifabric docs.
- **The comms mechanism is live and observed working.** As of 2026-07-21 there
  are three open PRs on `aifabric` from `PeterGrecian-NiCE` (the work identity),
  all `→ main` via PR, none direct-pushed — the air-gap review gate operating as
  designed. Only one (#5) is this keeper's subject; the others (#6 sessions
  graduation, #4 `idea` default_strand) are other strands' content.

## Incoming carries reviewed (the keeper's log)

- **aifabric PR #5 — `method/keepers.md` comms clause. Verdict: CLEAN, endorsed
  (2026-07-21).** The work-side keeper (`work-home-comms`, as `PeterGrecian-NiCE`)
  carried back a refinement of *this strand's own subject* and handed it to the
  shared method for every zone to hold (the clause credits a `home-work-comms`
  keeper instance as author). It pins three things this keeper wants pinned:
  (1) **method-only in every copy** — content is referenced as "held there,"
  never written into the method; (2) **verified carry, not trusted** — the
  cross-gap carry is reviewed line-by-line ("is every line method, or has content
  crossed"), protected direction never carries content; (3) **enforcement over
  aspiration** — a content-token check (hostnames, IPs, ticket IDs, internal
  names, secrets) at write/carry time, not a scrub afterwards. Reviewed the diff:
  method-only, no work content crosses onto personal infra — it strengthens the
  exact boundary this keeper protects, so the `keepers.md` portion is endorsed.
  (The bundled `docs/decisions/method-graduation.md` super↔aifabric
  source-of-truth decision is the orthogonal super/aitooling axis, not this
  keeper's call; the PR correctly separates the two.) Merge left to Peter /
  aitooling.
- **All three PRs RESOLVED (2026-07-21, with Peter's go).** Checked each against
  *current* `main` (which had moved: the OSD password fix + `strand-ps` already
  landed directly on main after the PRs opened), and found #5 and #6 both STALE:
  - **#4 (idea default_strand): MERGED** — genuinely new `bin/idea` work, not on
    main. Squash-merged clean.
  - **#6 (sessions graduation): CLOSED as superseded** — its password fix was
    already on main (`93cc9ac`); merging the stale branch would have regressed
    the docstring. Its one live delta (IPs→localhost) is now the pending
    endpoints-as-config work, done fresh on main. Commented + closed.
  - **#5 (method-graduation): MERGED docs-only** — its branch was cut before #4
    and re-added a stale `bin/idea` (reverting #4's feature) + a stale
    `bin/sessions` (old IPs + `Admin123` docstring). Rather than "redact", I
    **stripped both code files** (restored to main), rebased onto current main,
    force-pushed → the PR became the 3 method docs only (method-graduation,
    strands-storage, **the keepers.md comms clause**), then merged. Verified on
    true main: keepers clause present, #4's default_strand intact (not clobbered).
  - **Still open (handed to aifabric-sessions):** endpoints-as-config
    (`~/.config/osd/config`, Peter's chosen seam) — the real remediation for the
    home-LAN IPs that already sit on `aifabric/main` (landed via the earlier
    sessions merge, before this keeper existed). That work retires the IP
    exposure; the merge-order concern is now moot.
- **aifabric PRs #4/#5/#6 — full content-token quarantine scan (2026-07-21).**
  Applied the `keepers.md` "verified carry" gate (IPs, hostnames, ticket IDs,
  internal/work names, secrets) to the ADDED lines of all three PRs, not just
  the comms-method one — the air-gap hygiene check is the keeper's job on *every*
  incoming carry, even when the feature triage is another strand's.
  - **#4 (idea default_strand): CLEAN.** Only hit was the word "token" in a code
    comment.
  - **#6 (sessions graduation): CLEAN, and it IS the hygiene fix** — removes the
    hardcoded home-LAN IPs and the baked-in OSD password. Residual: the
    `Admin123!@Secure` password still lives in `main` history via the original
    'Create sss' commit (private repo, home-LAN pw — flagged for a scrub
    decision, not this keeper's call).
  - **#5 (method-graduation): method-CLEAN but carries a HAZARD.** #5 *adds*
    `bin/sessions` with home-LAN IPs `192.168.0.11` / `192.168.0.10` hardcoded;
    #6 *removes* exactly those. **Merge order is the gate: #6 must land before
    (or squash with) #5, else home IPs sit on aifabric/main where the work
    collaborator can read them.** The two PRs conflict on `bin/sessions` —
    resolve so #6's localhost-default wins. (The `PeterGrecian-NiCE/super` /
    "phone work app" line in the doc is the method *naming* the boundary, not
    leaked content — allowed.)
  - Verdict + full scan kept in scratchpad `pr-quarantine/QUARANTINE-VERDICT.md`
    (this session); ruling handed to aifabric-sessions via `idea`.
- **`Admin123!@Secure` reused-secret check (2026-07-21). NOT low-stakes — it is
  the LIVE OpenSearch admin password** for the real fleet cluster (backs the
  session archive). Hardcoded in ~25 tracked files across the private `osd`
  repo (`bin/*`, `cluster/docker-compose.*`, `*-sync.py`, README) and in the
  live `~/osd/.env` (the `.env` itself is gitignored). So "just a paste in
  aifabric history" understated it. **Boundary status, though, is contained:**
  `osd` is **private**; the string appears in **no current tracked file in
  `aifabric`** (only in the `bin/sss` removal diff, which pickaxe flags, and in
  one commit *message* — my own quarantine commit fc0e9c4). It does **not**
  reach the work collaborator via file content. Real exposure is (a) the
  password living in git history of a private repo, and (b) it being weak /
  shared across every OSD node. Rotation is an `osd`/aifabric-sessions
  operational call, not an air-gap breach — flagged, not this keeper's to fix.
  - **Rotation authorised (2026-07-21), execution routed to aifabric-sessions.**
    Peter said rotate + pull into `secrets` + add to Google Password Manager.
    Keeper did the sweep and wrote an executable plan (scratchpad
    `pr-quarantine/osd-rotate-plan.md`) but did NOT touch the live cluster —
    it's aifabric-sessions' green 3-node service. Plan: config-ify before
    rotate (central `$OSD_PASS` seam from `secrets get /osd/admin-password`, no
    hardcoded fallback across ~12 consumers), rotate via `securityadmin.sh`
    (mechanism in `osd/cluster/README.md:51`), then Google PM copy for the
    phone-facing Dashboards login per feedback_phone_credentials (create on
    pip, hand to Peter). Handed to aifabric-sessions via `idea`.

## Pending / loose ends

- Write this strand's durable STATE answer (method-only) from the archive
  sessions named in CLAUDE.md.
- Promote the air-gap collaboration model from a README section to its own
  `aifabric/docs/decisions/` doc — it's the shared protocol both instances
  serve, and three docs already reference it. Natural first job for this keeper.
- Once `work-home-comms` exists, confirm the two instances' names/boundaries
  line up (directional naming, no shared files).

## Decisions

- **Two instances, one per zone, directional names** (`home-work-comms` /
  `work-home-comms` = `<owner-zone>-<other-zone>-comms`). Never copy one strand
  across the gap; instantiate fresh from the shared pattern doc. (2026-07-21)
- **Keeper of METHOD, never work CONTENT.** Work content stays work-side/
  scratchpad; this strand references it as "held elsewhere," never reproduces
  it. (2026-07-21)
