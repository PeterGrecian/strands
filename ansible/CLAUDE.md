# Strand: ansible

**Keeps fleet configuration applied and current — the strand that *changes
hosts* and fixes config drift across the estate.**

This strand
owns *changing hosts* — editing `~/ansible` roles/templates/inventory, rolling
those changes out with `ansible-playbook`, and verifying they landed. It is the
"catch up with fleet maintenance" workstream: the durable home for the backlog
of config drift, template fixes, and cross-host rollouts.

Spans **`~/ansible`** primarily; touches the repos whose deployed artefacts
ansible manages (e.g. `Berrylands/pi-fleet` unit/template, `super/services/`).

## Seam with pifleet

- **pifleet** owns *fleet membership + dashboard/liveness* — who's in the fleet
  and whether it's healthy on the pi-fleet board. All always-on hosts, Pi or
  not (vole, muppet, the GCP pair included).
- **ansible** (this strand) owns *making changes stick on those hosts*. When a
  pifleet concern needs a host-side change (e.g. "report every 5 min"), pifleet
  decides *what* the fleet should look like; ansible *implements and rolls it
  out*.

So: pifleet says "vole should be on the board reporting sanely"; ansible edits
the timer template, re-deploys, and confirms vole checks in.

## Live-capture caution

Several fleet hosts run foreground capture loops (cloudcam's 5 s skycam
capture, gardencam daemons). Rollouts must never displace that work — the
pi-fleet reporter is already `Nice=15` / idle-scheduled for this reason. Prefer
`--limit`, deploy in waves, and verify capture is undisturbed after each wave.

## Session ritual

1. Read `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to (`~/ansible`, or the
   repo owning the deployed artefact) — this strand dir holds only curation.
4. Session end (or on `dcp`): update STATE.md — what changed, what's pending,
   decisions made. Keep it curated prose, not a log.
