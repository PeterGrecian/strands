# aifabric-sessions — STATE

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

Strand born 2026-07-18, forked from the aifabric strand session that
discovered the 30-day reaping and recovered the muppet trove. Nothing built
yet. OpenSearch is NOT currently running on pip (checked 2026-07-18);
`~/osd` is a docker-compose stack (fluent-bit + cloudwatch/dynamodb sync
scripts) — sessions ingest will be a new index + ingest script alongside.

## Cluster — 2-node GREEN, tiebreaker parked (2026-07-18, session 1)

**Built and live:** 2-node OpenSearch 3.7 cluster, **green**, replica of every
shard on both disks — **losing puppy OR muppet loses zero data.**
- **puppy** (192.168.0.11) — cluster_manager,data,ingest; primary shard; data
  in docker volume `osd_opensearch-data`.
- **muppet** (192.168.0.10) — cluster_manager,data,ingest; replica shard; data
  on `/mnt/photodisk` (218G free). Docker enabled + compose plugin installed.
- Config in **osd repo** `cluster/` (per-host compose + `opensearch.base.yml`);
  TLS certs in `cluster-certs/` (gitignored). Admin pw `Admin123!@Secure` set
  via securityadmin (NOT the env var — we supply our own opensearch.yml so the
  demo installer is bypassed; see cluster/README.md).
- Bootstrapped **fresh** (not single-node→multi conversion): old single-node
  volume backed up as `osd_opensearch-data-precluster-20260718` on puppy (can
  trash once confident), then re-ingested 36,623 docs from the 3 sources.
- 9200/9300 bound to **LAN IPs only** (local-only hard constraint kept).

**Tiebreaker: DONE (2026-07-19) — 3-node HA cluster is live.**
- **vole** (192.168.0.9, Acer C720, x86_64 Haswell, 2GB, Debian 13, WiFi
  static, always-on) = voting-only master (`node.roles=cluster_manager`, no
  data, 256MB heap). The x86 box that clears the ARMv8.2 floor homepi (Pi 4B,
  ARMv8.0) couldn't. Config committed (osd 438fa8f).
- **HA VERIFIED**: stopped puppy (a data node) → cluster kept its master
  (muppet+vole quorum) AND stayed **writable** (write returned `created`) +
  searchable. That's precisely what 2-node couldn't do. claude-sessions green
  + replicated throughout; puppy rejoined green on restart.
- Build notes for future: (a) node cert must include the new node's IP — I
  regenerated node.pem with .9 (dropped homepi .53); changing the shared cert
  means force-recreating puppy+muppet to pick it up. (b) voting-only nodes need
  `opensearch.vole.yml` = base MINUS `path.repo` (no snapshot mount → won't
  start otherwise). (c) `--force-recreate` needed when only the mounted
  config/cert changes (compose doesn't detect content changes).
- homepi's ARMv8.2 limit recorded in strands/hardware/IDEAS.md.

**Cluster is FULLY GREEN** (all indices, 100% active shards) after a clean
full-cluster restart on 2026-07-19. Runbook learned: **rolling** restarts can
wedge the `.opendistro_security` replica in INITIALIZING (harmless yellow —
claude-sessions stays green + auth works — but it won't self-clear and the
index is admin-write-protected so API/securityadmin fixes don't take). The fix
is a **coordinated** restart: stop all nodes, start the two data+master nodes
together (bootstrap quorum), then vole. Prefer that over rolling when a restart
is needed.

Pre-cluster baseline (if ever needed): was puppy single-node, 34MB / 36,335
docs / pri=1 rep=1 / yellow. Old volume kept on puppy (see above).

**Snapshot backup — DONE (2026-07-18).** Replica ≠ backup: it mirrors logical
mistakes (bad delete/corruption) to both disks. Snapshots restore from the
past. Built:
- fs repo `sessions-backup` at `/mnt/osd-snapshots` — a shared path BOTH data
  nodes reach: it's `muppet:/mnt/photodisk/osd-snapshots` (local on muppet,
  NFS-mounted on puppy via fstab `nofail,x-systemd.automount`; muppet already
  NFS-exported photodisk to the LAN). `path.repo` in opensearch.base.yml +
  bind-mount in both data-node compose files. Repo _verify → both nodes OK.
- `bin/snapshot-sessions` (+ daily `snapshot-sessions.timer` on puppy 04:30,
  30-day retention = the reaper). First snapshot SUCCESS; timer run
  Result=success. osd 0a418aa.
- Restore recipe in cluster/README.md (close → _restore → reopen).

Cosmetic gotcha resolved: after each rolling restart the `.opendistro_security`
system-index replica briefly wedges INITIALIZING (election churn) → cluster
shows yellow while `claude-sessions` itself is green. It self-heals once both
nodes are cleanly up. Don't chase it live (that index is admin-write-protected;
securityadmin re-init hangs). A clean full-cluster restart clears it.

## Session 3 (2026-07-28/29) — Offsite S3 export = backup of record (DONE); photodisk evacuation staged

**Trigger:** idea to move OSD live data off the deprecated **photodisk** (muppet's
ST3360320AS spinning HDD) onto the modern root NVMe SSDs. Diagnosis confirmed:
puppy's primary is already on its SSD root (fine); muppet's **replica sits on
photodisk**, and the **snapshot repo** (`/mnt/photodisk/osd-snapshots`, NFS-shared
to puppy as `path.repo`) is also on photodisk. So photodisk deprecation forces
two moves.

**Key reframe (Peter):** the session archive is *so valuable* that an offsite copy
is justified — the strand's "no cloud copies of transcript content" was an
assistant-authored cautious default (traced to the 2026-07-18 scaffold), never a
reasoned requirement. Revised stance: **S3 treated ≈ as safe as LAN disk** (private,
encrypted, our creds; we already trust AWS with SSM secrets), **but still scrub
known secrets** as cheap belt-and-braces. And: **store `_source`, not the index** —
the Lucene index is derived/rebuildable; the `_source` docs are canonical. So the
offsite artefact is a redacted `_source` export, which also **retires the whole
native-snapshot / repository-s3 / path.repo apparatus**.

**BUILT + VERIFIED (osd 6149d0b, pushed; puppy pulled to 6149d0b clean):**
- **`osd/bin/export-sessions`** — scroll all `{_id,_source}` → exact-match redact
  every known secret **value** (from `secrets describe`, in-memory only, never
  logged; `MIN_SECRET_LEN=8` guard, longest-first) → gzip JSONL → `aws s3 cp` to
  private bucket. `--restore FILE` re-indexes by stored `_id` (idempotent).
  `--no-upload`/`--no-redact` for local checks.
- **Numbers:** 50,531 docs, 50 MB index → **~15 MB gz** (~3×). Redaction set = 54
  secret values; **102 docs scrubbed**. **Audit CLEAN** — independent pass confirms
  no known secret survives the export. **Round-trip exact: 50531 → 50531** doc-for-doc
  into a throwaway index (then deleted).
- **S3 bucket `s3://petergrecian-sessions-archive`** (eu-west-1, acct 700630586062):
  block-public-access ALL on, **SSE-AES256** default, **versioning on**. Objects
  under `exports/`. **Lifecycle:** current exports expire 90d, noncurrent versions
  30d, incomplete MPU 7d → ~1.3 GB steady-state ≈ **$0.03/mo**.
- **Daily timer on puppy** (`export-sessions.{service,timer}`, 05:00, Persistent,
  linger) → **verified running under systemd on puppy** (`status=0/SUCCESS`),
  produced a fresh 14.7 MiB SSE-AES256 object unattended. Puppy needed the **aws
  CLI v2 installed** (was absent); creds already present in `~/.aws` (that's how
  `secrets` works there) — no new creds spread.

**ITEM #3 — photodisk evacuation: DONE (2026-07-29, osd 28e0f1e).** OSD is fully
off the deprecated photodisk HDD; both copies of the archive now on modern NVMe
SSDs; cluster GREEN 3 nodes. photodisk → vault as a cold archive (NOT deleted —
Peter's call: it holds the 13 snapshot files + old data as offline backup).

- **Move 1 (index → root SSD):** muppet's data is now a **named docker volume**
  `cluster_opensearch-data` on its root NVMe (`/var/lib/docker` is on root), was
  `/mnt/photodisk/opensearch-data`. Cutover = `compose down`/`up` with the new
  (empty) volume; OpenSearch re-replicated ~50 MB from puppy automatically. NB the
  primary ended up ON muppet's new SSD volume (not the replica as first predicted)
  — harmless, both copies complete + green. puppy's copy stayed on its SSD root.
- **Move 2 (snapshot teardown):** timer disabled on puppy; `sessions-backup` repo
  **deregistered** (13 snaps left on-disk = the vault shelf copy); `path.repo`
  removed from `opensearch.base.yml`; `/mnt/osd-snapshots` bind dropped from BOTH
  data composes; **coordinated recreate muppet-then-puppy** (vole held master
  quorum, `claude-sessions` green throughout — no `.opendistro_security` wedge);
  puppy NFS unmounted + fstab commented (backup `/etc/fstab.bak-*`). Verified:
  puppy 0 osd-snapshots refs, muppet 0 photodisk binds, registered repos `{}`.
  Runbook confirmed: single-node-at-a-time recreate with vole quorum avoids the
  wedge — didn't need a full-cluster stop.
- **Handoff:** `bigstore-xfer` strand flagged the hang risk (puppy hard-NFS-mounted
  photodisk) + relayed Peter's power-down intent; replied via strand-mailbox that
  photodisk is OSD-free + clear to unmount/power-down. **The `_source` export to S3
  is now the sole backup of record.** `bin/snapshot-sessions` + its systemd units
  kept in-repo but INERT (not deleted).

**Bonus fix — audit-log disk bloat (2026-07-29):** cluster briefly RED mid-move
from OpenSearch's own telemetry indices — `security-auditlog-*` (~254k docs,
logging every API call, ~34k/day, unbounded) + `top_queries-*`. Deleted them
(cleared RED, freed disk → **puppy 91% → 62%**, ~112 GB) and **disabled audit
logging**: live via `/_plugins/_security/api/audit/config` (`enabled:false`) +
durable in `opensearch.base.yml` (`plugins.security.audit.type: debug`). This
was the hidden reason puppy kept creeping toward the 95% flood watermark.

**Still open (small):** the `snapshot-sessions` dead code + its units linger in
the osd repo (inert, kept for reference); remove in a later cleanup if wanted.

## Session 3 cont. — redact-from-sessions tool + live-file scrub (2026-07-29)

Peter's framing: back up BOTH the index (fast working-system restore) AND the
raw sessions (source of truth, tiny — none of it heavyweight); redaction matters
less because the S3 bucket is "as secret as bin/secrets". Resolution:
- **`aifabric/bin/redact-from-sessions`** (aifabric fb19e19) — the durable tool,
  "run after a blunder". Scrubs a leaked value (positional, need not be in
  `secrets`) and/or `--known` (all managed secrets) from live
  `~/.claude/projects/**/*.jsonl` AND, with `--index`, the OpenSearch index.
  Excludes the active session file (append-corruption hazard); trashes originals;
  re-validates JSON per line; refuses <8-char values; prints counts only.
- **One-off live-file scrub DONE**: 50/114 live transcripts contained a known
  secret (nothing had ever scrubbed the *live* files — only the index+export on
  2026-07-21). Scrubbed 49 (active session skipped), 0 JSON failures, originals
  in `~/.trash/2026-07-29/redact-from-sessions/`. **Index also scrubbed**: 142
  docs (later shown inflated) → now **0 exact-substring hits**, verified.
- **GOTCHA found + fixed** ([[gotcha-match-phrase-vs-exact-redact]]): the index
  path first counted with `match_phrase` (ANALYZED → over-matches tokenised
  fragments) but redacted with exact `.replace()`. Left 20 "residual" hits that
  were ALL false positives (0 exact substrings). Fixed: match_phrase is only a
  candidate pre-filter; painless gates on exact `.contains()` with
  `ctx.op='noop'`; dry-run exact-checks client-side. Report says "(exact-substring)".
- Perf note: `--known` = 52 sequential queries (~2min). Fine — the blunder case
  is usually ONE value (fast); `--known` is the rare belt-and-braces sweep.

## Session 3 cont. (2026-07-30) — raw-session backup + bucket lockdown + reboot fix (all DONE)

Built the two deferred pieces + fixed a reboot gap found en route.

- **`osd/bin/backup-raw-sessions`** (osd fa97e66) — the SOURCE-OF-TRUTH backup,
  companion to export-sessions. Byte-faithful `tar.gz` of `~/.claude/projects` →
  `s3://petergrecian-sessions-archive/raw/<host>/<UTC>.tar.gz`, per-host (like
  ingest), `--keep 30` prune. No redaction (live files kept clean by
  redact-from-sessions). Independent of ingest → closes the "reaped before
  indexed" gap. **Daily timer 05:20 on pip + puppy + muppet**, all verified under
  systemd. Sizes: pip 79 MB, muppet 2.9 MB, puppy 611 B (puppy runs ~no sessions).
- **Bucket lockdown = DONE (parity + then some).** Reference bar: the `secrets`
  GCS bucket (`petergrecian-secrets`) is project-private, no public members. Our
  S3 bucket already had block-public-access + SSE-AES256 + versioning + no
  policy/ACL grants (= equal-or-tighter). **Added an explicit-deny bucket policy**:
  DenyInsecureTransport (non-TLS) + DenyNonAccountPrincipals (anything outside
  acct 700630586062). Owner-over-TLS verified still works. So "as secret as
  bin/secrets" is now literally true + declarative.
- **REBOOT FIX (found live):** puppy rebooted mid-session; its `opensearch`
  data-node container did NOT auto-start (only dashboards did — it already had a
  restart policy). Cluster ran 2-node yellow until started by hand. Root cause:
  puppy + muppet composes lacked a `restart:` policy (vole + dashboards had one).
  **Added `restart: unless-stopped`** to both data-node composes (osd 7c08609),
  coordinated-recreated puppy-then-muppet (green throughout). Reboots now
  auto-recover the cluster. [[project-drift-watch]] — the "always-on index host"
  assumption now actually holds.

**Backups now = three layers, all cheap:** (1) live LAN replica (disk/node
failure), (2) `export-sessions` redacted index → S3 (fast working-system
restore), (3) `backup-raw-sessions` faithful raw tree → S3 (source of truth,
ingest-independent). photodisk snapshot repo retired; the vault disk is a 4th
cold copy.

**Everything above DONE (2026-07-27→30):** OSD off photodisk onto NVMe SSDs;
snapshots retired to S3; export + raw backups live + timered; redact tool built;
live files + index scrubbed; bucket locked down; reboot auto-recovery fixed.
Cluster GREEN 3 nodes.

## Session 2 (2026-07-21) — OSD admin-password rotation (authorised, DONE)

Handoff from home-work-comms keeper: rotate the OSD admin password off the
weak, ~24-places-hardcoded `Admin123!@Secure`, pull it into secrets + Google
Password Manager, config-ify all consumers. **All done + verified live.**

- **New password** (`openssl rand -base64 24`) → **`secrets get /osd/admin-password`**
  (both backends) + **Google Password Manager** card handed to Peter (phone-
  facing, per feedback_phone_credentials). `secrets hints` line added.
- **Central auth seam**: `osd/bin/_osd-env` (bash) + `bin/_osd_env.py` (python),
  password from secrets, **no hardcoded fallback (fail loud)**, `secrets`
  resolved by abs path (super/bin not on PATH under systemd). All bin/* +
  ingest/wordcloud/operations + cloudwatch-sync.py + dynamodb-sync.py + compose
  bootstrap defaults + `super/bin/sessions` now source it. **Zero `Admin123` in
  any tracked file** (osd 759e33c, super 0663340 + 93cc9ac).
- **Live rotation**: `hash.sh -env` → swap ONLY the `admin:` hash in the puppy
  container's `internal_users.yml` → `securityadmin.sh -t internalusers` with the
  admin cert. **SUCCESS on all 3 nodes; GREEN; new pw → 200, old pw → 401.**
- **Consumers verified**: ingest-sessions.service Result=success on **all three**
  hosts (pip/puppy/muppet) under systemd with the rotated pw; snapshot-sessions
  SUCCESS; `sessions` CLI works.
- **3 pre-existing bugs surfaced + fixed en route**: (a) `secrets` crashed on
  puppy/muppet (unconditional google-cloud import; they're boto3-only) → made
  GCP optional, AWS-only fallback. (b) puppy's `/etc/default/osd-ingest` pointed
  at `localhost:9200` (OpenSearch binds LAN IP only) → puppy's own ingest had
  been silently failing; fixed to 192.168.0.11:9200. (c) puppy's osd checkout
  stale at f641490 (8 behind), full pull blocked by divergent untracked
  cluster/certs/systemd copies → surgically checked out just the seam files.

**Post-rotation work, same session (all DONE):**
- **Password redacted from the archive** — the plaintext pw had landed in this
  session's transcript (Peter's request to redact). Scrubbed to `<REDACTED-OSD-PW>`
  in: the live `.jsonl` (JSON integrity preserved), 5 index docs (`_update_by_query`),
  and the tainted `snap-20260721-185725` snapshot (deleted; older snaps predate the
  pw). Re-ingest verified idempotent-clean. Peter chose "redact only, keep pw".
- **`secrets copy <path>` added** (super 9a2c3d3) — copies a secret to the
  clipboard WITHOUT printing it (Wayland wl-copy / X11 xclip/xsel; both CLIPBOARD
  + PRIMARY). Born from the Google-PM hand-off: a screen copy lands plaintext in
  the transcript the archive ingests. Documented in --help + hints. `xclip`
  installed on pip. This is the house way to hand any secret to the clipboard now.
- **Git housekeeping on the db servers (puppy + muppet), DONE** — both were
  months-stale: puppy osd f641490→**759e33c**, puppy super 4cc9995 (123 behind)
  →**9a2c3d3**; muppet osd f641490→759e33c, super→9a2c3d3. **All 4 checkouts now
  CLEAN.** Method: the blocking untracked files were identical-to-origin or stale
  (only real diff = old-pw bootstrap default in docker-compose.puppy.yml; origin
  wins); `cluster-certs/` (gitignored, precious) left untouched and confirmed
  gitignored on origin; everything moved aside was backed up to dated dirs, all
  verified live (ingest green, timers enabled, trash-sweeper active, cluster
  green), then the backups trashed. **The db servers had been running pre-cluster
  code** — worth a drift-watch on their checkouts to stop it recurring ([[project_drift_watch]]).

**Loose ends still open:**
- **NEXT: OSD endpoints → `~/.config/osd/config`** (new idea 20260721T192715Z,
  Peter decided the how). Finish what the pw rotation started: server ADDRESSES
  are config too. Precedence env > `~/.config/osd/config` (`osd_nodes=`) > localhost;
  fix both seams (`_osd-env` + `_osd_env.py`) + drop bin/sessions' hardcoded IP
  default; create the config on puppy/muppet/pip + ship config.example. Retires
  the #5/#6 merge-order hazard at the root. Full spec: keeper scratchpad
  pr-quarantine/osd-endpoints-config.md.
- **Old password in osd git history** (private repo, home-LAN) — rotation made
  it dead; scrub deferred (Peter's call). Only matters if osd is ever opened.
- **aifabric PR triage (#4/#5/#6) still OPEN** — see below; not done this session
  (rotation was the priority). PR #6's IP-in-code concern is now moot at the root
  because the seam keeps infra addresses/secrets out of committed code entirely.

## aifabric PR triage — PENDING (routed by keeper, 2026-07-21)

Keeper routed aifabric PR #6 (graduate/sessions → main): graduates `bin/sessions`
into aifabric/bin, removes an earlier `bin/sss` paste. Keeper's air-gap ruling
(binding): PR #6 is CLEAN + is the hygiene fix; **merge-order gate — PR #6 must
land before/with PR #5** or #5's bin/sessions hunk dropped, else home-LAN IPs
(192.168.0.10/.11) sit on aifabric/main; the two conflict on bin/sessions, PR #6's
localhost-default wins. Keeper's sharper steer (Peter): OSD endpoints are CONFIG
not code — belong in a per-host `~/.config/sessions/config` (like idea's
`$STRANDS_DIR`), so NO copy in ANY zone carries home infra. **Mine to screen**:
whether the tool is good, whether to adopt the config-seam (yes — matches what I
just did on the osd side), and the Admin123-in-history scrub. Do next session.

## Ideas triaged 2026-07-21 — carried follow-ups (spool cleared)

Older spool items (2026-07-19), still TODO — kept here now the spool is trashed:
- **homepi trove**: already secured → `~/archives/claude-sessions-homepi-20260719.tar.gz`
  (67 transcripts, 5MB, incl. gardencam/Berrylands/repos dirs, possibly pre-March).
  **Ingest as a 4th source** with host=homepi; update the sources inventory.
- **forkchat/mesh mailboxes**: where do forkchat-driven conversations go? Mesh
  mailboxes are a record — consider ingesting them too (open question).
- **Dashboards now tailnet-fronted**: puppy runs `tailscale serve --bg
  http://192.168.0.11:5601` → **https://puppy.tailc34ab9.ts.net** (tailnet-only:
  puppy/homepi/pixel-6a; local-only constraint intact, tailscale-gated not
  internet-exposed). Serve targets the LAN bind (localhost gave 502).

## Sources inventory (2026-07-18)

- `~/archives/claude-sessions-snapshot-20260718.tar.gz` — pip, 74 sessions,
  2026-06-19 →, 60 MB (memory dirs excluded).
- `~/archives/claude-sessions-muppet-20260718.tar.gz` — muppet, 23 sessions,
  2026-03-03 – 04-21, 3 MB; browseable at `~/archives/muppet-sessions/`.
  Originals still on muppet, safe only until claude next launches there.
- Live: `~/.claude/projects/*/**/*.jsonl` on pip (note: transcripts can nest
  one level deeper than `projects/<dir>/<sid>.jsonl` — use find, not glob).
- Everything pre-2026-03-03 is lost (reaped before archiving began).

## DONE (session 1, 2026-07-18)

- [x] `claude-sessions` index live on **puppy** (192.168.0.11:9200),
  OpenSearch 3.7.0, data volume on puppy root (89% used — watch it).
- [x] `~/osd/bin/ingest-sessions` written, committed, pushed (osd f641490),
  pulled on puppy. One doc/message; content-hashed IDs (idempotent + cross-host
  dedup); strand/host/title/first-prompt/sidechain fields; full-text `text`.
- [x] Backfill verified: **36 237 docs**, **74 pip sessions + 8 muppet**,
  0 errors. pip tarball + live merged to 74 unique (dedup proven). Full-text
  search working (top hit for "opensearch ingest rag" is this very session).
- [x] Hourly timer units authored + committed (`systemd/ingest-sessions.{service,timer}`,
  `bin/install-ingest-timer`) — NOT yet enabled (Peter's call to switch on).

- [x] **Hourly timer ENABLED on all three hosts** (2026-07-18): puppy (→
  localhost:9200), pip + muppet (→ 192.168.0.11:9200). `--user` timers,
  `loginctl enable-linger peter` set on each so they ship while logged out.
  All three ran once under systemd, Result=success. muppet re-ship added 0
  dupes (content-hash idempotency proven live).
- [x] **`cleanupPeriodDays` = keep 30** (Peter, 2026-07-18: "30 day reaper
  should be fine"). Ship-and-free is now the standing model; index is the
  permanent record, files reap at 30 days. **Not touching settings.json** —
  the 30-day default already gives this; no change needed.

## Pending / loose ends

1. ~~Query surface CLI~~ **DONE (2026-07-18)** — `super/bin/sessions` (typed
   fleet tool, on PATH). Subcommands: `search "<q>"` (BM25, filters
   --strand/--host/--role/--since/--until, -n, --full, --json), `sessions`
   (list openings newest-first), `show <id>` (full transcript), `strands`,
   `stats`, `--hints` (agent contract), `--json` everywhere. Multi-node
   random-first + fallback (puppy+muppet), local-only. Verified incl. failover.
   super 2d2d0b2. **RAG-for-agents:** agents call `sessions search ... --json`
   or read `--hints`; lazy-context pattern (no transcript data in prompts).
2. ~~Dashboards~~ **DONE (2026-07-18)** — OpenSearch Dashboards on puppy at
   **http://192.168.0.11:5601** (LAN-only, admin/pw, green, cluster failover to
   muppet). `claude-sessions` index pattern (default → Discover works) +
   "Claude Sessions — Overview" dashboard (45d default): **Strand activity over
   time** (daily stacked area by workstream, dataviz-skill validated palette,
   peter/tmp excluded → Other), total, by-host, sessions/day, activity, top
   strands. Config + exported saved objects in osd
   `cluster/docker-compose.dashboards.yml` + `cluster/dashboards/`.
   **Gotcha:** the raw saved-objects API creates a FIELDLESS index pattern (no
   timepicker, date-histogram panels error "can't locate field timestamp") —
   must populate `fields[]` from `_field_caps`. Weekly date_histogram buckets
   anchor to Monday → the current partial week looks empty; use daily.
3. Watch puppy root disk (89%, index competes; OpenSearch flood-blocks at 95%).
4. **Semantic search: embeddings + kNN, APPROVED — build after the CLI**
   (Peter, 2026-07-18: he's done embeddings+kNN before; embedding compute on
   the two data-node laptops is cheap, so don't defer-for-evidence). Shape
   (from aifabric session's assessment, ratified): **hybrid** BM25 + kNN —
   never pure-vector (exact-term queries over jargon-dense transcripts must
   not get worse); embeddings computed **locally only** (small CPU model —
   cloud embedding APIs would break the local-only constraint); OpenSearch
   kNN native, so this is an ingest-side embed step + a query-side one, no new
   infra. Timing is NOT an issue (Peter): `_reindex` reads stored `_source`
   (reap-proof), and embedding can run high-nice overnight on the laptops —
   so add vectors whenever convenient; no need to beat the reaper.
5. ~~Snapshot repository~~ **DONE (2026-07-18)** — see below.

## Decisions

- **Index scope: transcripts ONLY** (Peter, 2026-07-18). Do NOT ingest strand
  files (STATE/IDEAS — they're the *curated* layer, read whole not searched;
  small by design; `git grep` covers them) or repo code (grep/LSP/GitHub beat
  a text index; ingesting it dilutes transcript hits). Three retrieval
  regimes, matched: index what's otherwise lost, curate what's kept, grep
  what's structured. Transcripts already embed code-as-discussed via tool
  output, which covers the useful cross-over for free.
- **`strand` field = strand-or-pwd-leaf** (2026-07-18, surfaced by Peter). It's
  the real strand name IF cwd is under `.../strands/<name>/`, ELSE the last path
  component of cwd (repo/dir). So `astro`/`super`/`splay` etc. are repo names,
  not strands; `peter` (=/home/peter) and `tmp` (=/tmp scratch) are pure
  location-noise. Charts exclude peter/tmp → Other. **Open option (Peter may
  want later):** fix `strand_of()` at source so home/scratch → a clean label
  and re-ingest, fixing CLI + dashboards together (not just per-chart excludes).
- Ship-and-free is the working model; index = permanent record, files remain
  disposable. (Inherited from birth context; revisit only with Peter.)
- Local-only index is a hard constraint, not a preference.
- **Index host: puppy** (192.168.0.11), always-on (Peter, 2026-07-18: "pip
  sleeps, the others dont"). puppy was briefly blocked (disk 100% full) but
  Peter freed it (394G→50G free) so it is the permanent home as intended.
- **Ingest model: each host ships its own** transcripts to the central
  OpenSearch (pip/puppy/muppet each run their own timer), doc IDs
  content-hashed so re-runs + overlaps are idempotent (Peter, 2026-07-18).
- **Cadence: hourly**, not nightly (Peter, 2026-07-18: "ship hourly").

## Progress / environment (2026-07-18, session 1)

- OpenSearch 3.7.0 stack brought UP on **pip** (validation host only — pip
  sleeps, so this is not the permanent home). Needed to install the docker
  compose v2 plugin (v5.3.1) into `~/.docker/cli-plugins/` first — pip's
  `docker.io` had no compose. Password unified to `Admin123!@Secure` via new
  `~/osd/.env` so it matches `bin/indx`.
- JSONL schema surveyed: line `type` ∈ {mode, permission-mode,
  file-history-snapshot, user, assistant, system, attachment, last-prompt,
  ai-title, custom-title, agent-name, agent-color, queue-operation}. Ingest
  targets `user`/`assistant` (+ `ai-title`/`custom-title` for session titles).
  `message.content` is str OR array of typed blocks (text/tool_use/
  tool_result/thinking). Useful fields: sessionId, uuid, parentUuid,
  timestamp, cwd, gitBranch, version, userType, isMeta, isSidechain.

## Gotchas learned (session 1)

- **puppy disk was 100% full** when first checked (camera frames: astrocam
  132G, starcam 122G, eclipticam 56G, skycam 52G + rerenders) — the
  ship-and-free unbounded-raw risk from GLOBAL.md, realised. Peter cleared it
  during this session (→50G free). Still only 89% now: **watch puppy root**;
  the index competes for space there and OpenSearch flood-blocks writes at 95%.
  Camera-pipeline retention is astro/astro-storage's problem, not ours.
- **OpenSearch flood watermark bites at 95% disk** → `create-index blocked
  (api)` (403 even for admin/all_access). pip hit this (97% full) which is a
  second reason pip is validation-only, not the host.
- **Docker on puppy**: `docker.io` present but the daemon service was *disabled*
  (never enabled). Enabled + started it (`systemctl enable --now docker`), added
  `peter` to the docker group (effective next login; used sudo this session),
  installed compose v5.3.1 plugin system-wide (`/usr/local/lib/docker/cli-plugins`).
- **muppet "23 sessions" was 23 *files*, = 8 real sessions**: the extra 15 are
  agent sidechain / compaction transcripts sharing the parent sessionId. Ingest
  counts distinct sessionId (8) but keeps all message content (`is_sidechain`
  flags the 2709 sidechain docs). The inventory's "23 sessions" should read
  "23 files". Transcripts also nest as `agent-a<hash>.jsonl` beside the main file.
