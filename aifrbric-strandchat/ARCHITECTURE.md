# strandchat — deployment architecture

*Checked against disk 2026-07-20. Distinguishes what's built from what's sketched.*

## Rationale: why puppy

- **puppy is always-on** (up 3+ weeks), 8 cores / 7.6 GB — the strongest
  always-on node. **pip is a laptop that sleeps** — wrong host to serve from.
- **homepi** is a Pi4 (4 cores) — usable, but weaker; puppy wins on CPU/RAM.
- So the *server* belongs on puppy; the open question is where the *brain*
  (clds + the live spool) lives.

## What is built today (Architecture A — "pip brain, puppy window")

```
  pip (laptop, sleeps)                    puppy (always-on)              phone
  ───────────────────                     ─────────────────             ─────
  clds run here  ──► strand-mailbox spool
  ($XDG_RUNTIME_DIR/strand-mailboxes,     forkchat --serve --read-only
   tmpfs, per-user)                       --password  (tailnet-only)
        │                                        ▲                        │
        │ spool2mesh.py (project)                │ tailscale serve        │
        ▼                                        │ /chat -> :8787         │
  ~/strandchat-mesh  ──rsync──►  puppy:~/strandchat-mesh                  │
                                          https://puppy.tailc34ab9.ts.net/chat ◄─┘
                                          (Google Password Manager holds pw+URL)
```

- **One-way**: pip pushes a projected mesh; puppy only serves it. Puppy shows
  stale data whenever pip is asleep.
- Coexists with OpenSearch Dashboards, which already owns `/` on puppy's 443
  (strandchat is mounted on `/chat`; tailscale strips the prefix before
  proxying to :8787, so forkchat's relative `/api/*` routes work unchanged).
- Sync is pip's job (a timer or on-demand `strandchat-sync.sh`).

## What was sketched (Architecture B — "puppy is the coordinator")

The always-on-hub vision: **strands + spool + clds all live on puppy**, so
strandchat serves directly from local state — no cross-host projection/rsync,
never stale.

Requires (none true today):
- `~/super` **checked out on puppy** (currently absent). "strands synced with
  git to puppy" = keep puppy's checkout pulled.
- **clds run on puppy** (`claude` + `node` ARE installed there; just not wired
  — no super checkout, nothing running).
- A decision on pip's role: either pip also runs clds and shares state, or pip
  becomes a *client* of puppy's mesh.

**The NFS bridge between A and B:** puppy already is the NFS *server* for the
fleet (exports camera frames; pip mounts them). It could **also export
`~/super/strands`**; pip mounts it → both hosts share one strand tree + one
spool location, and strandchat serves local state with no rsync. NB the sketch
said "NFS-mounted *from* puppy" — that's the correct direction (puppy serves,
pip mounts); today no strands export exists.

## Idea: AWS Lambda as the coordinator (parked)

Conceivably the mesh coordination need not be a specific always-on box at all.
An **AWS Lambda + a small store (DynamoDB / S3)** could be the rendezvous: clds
on any host POST messages to an API-Gateway endpoint; strandchat (served from
anywhere, or even static + Lambda-backed) reads from the same store. Removes
the single-always-on-node dependency entirely (no puppy SPOF, no
pip-must-be-awake), at the cost of leaving loopback-only/local-only simplicity
and taking on cloud cost + auth surface. Fits the fleet's existing AWS posture
(Lambda + DynamoDB + API GW already in use). **Not built — noted as a design
option** should the always-on-node model prove limiting.

## Open decisions

1. **A or B?** Ship the lightweight A (done), or invest in B (puppy as hub)?
2. If B: super-checkout-on-puppy via git-pull, or NFS-share strands from puppy?
3. Sync cadence for A (timer vs on-demand) — deferred, pending 1.
4. Lambda coordinator — parked unless the node model limits us.
