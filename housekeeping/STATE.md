# housekeeping — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What this strand is

Git housekeeping across the ~36-repo fleet, done on demand when Peter feels it
needs it. The framing that emerged this session: **housekeeping is mostly about
avoiding data loss** — surfacing and clearing the risks that
`all-repos-status` alone doesn't make obvious.

The data-loss surface, in rough order of volatility (most volatile first):

1. **Local uncommitted work** — not in git at all; a stray `checkout`/`stash
   drop` loses it. Highest risk.
2. **Stashes** — recoverable but invisible; easy to forget. `git stash list`
   per repo.
3. **Orphaned remote branches** — pushed (so safe) but with no open PR, holding
   commits not in `main`. Found via `all-repos-status` "UNMERGED", then compared
   to main with `rev-list --count main..origin/<br>` (ahead) and the reverse
   (behind).

House tools: `all-repos-status` / `reposcheck` (parallel uncommitted/unpushed),
`sync-repos.sh`. Neither catches stashes or ahead/behind on orphaned branches —
those are checked by hand (see loops above).

### Two distinct axes — don't conflate them

1. **pip's own repos** (the workstation) — the loops above, plus `sync-repos.sh`
   (which *only* operates on pip's siblings, running locally).
2. **The Pi fleet's clones** — a separate concern. Each host carries its own
   clones that drift **behind** `main`. Fixing these is **ansible's job, not
   `sync-repos.sh`**: the `git-repos` role (`ansible/roles/git-repos`,
   `safe_pull.yml`) stashes any dirty tree first (`ansible-auto <iso8601>`, `-u`
   so untracked kept), fixes origin URL, then pulls to the pinned branch. So the
   right move for stale fleet clones is to **ask the `ansible` strand to run the
   role** — this keeper does the sweep and hands off. A fleet clone being
   *behind* is harmless staleness; only *ahead* (unique unpushed work on a host)
   is a real data-loss risk.

**Fleet sweep tool:** `check-repos.sh` (kept in this strand's scratchpad /
paste-able) — finds git repos under `~` on a host (depth 3) and prints
`branch / OK|AHEAD|BEHIND|DIVERGED|NO-UPSTREAM / ahead / behind / dirty`. Run it
over `ssp` hosts via `ssh peter@<host> 'bash -s' < check-repos.sh`, skipping
offline hosts. Reachability first: try `.local`, fall back to `resolve-host`.

## What exists

- Strand mission written (git housekeeping / data-loss framing).

## Done this session (2026-08-03)

- **Fleet repo-divergence sweep.** Ran `check-repos.sh` across the 7 reachable
  `ssp` hosts (homepi, cloudcam, muppet, eclipticam, astrocam, vole, puppy).
  deskpi, xoverpi, starcam offline (down via both `.local` and `resolve-host`
  IP). Result: **no true ahead+behind divergence anywhere.** Almost everything
  is just **behind** (stale clones: `super` behind up to 159, `strands` ~169,
  `mywebsite` ~193, `Berrylands` ~241 on homepi). One at-risk item: eclipticam
  `astro` on deprecated branch `moon-net-marking`, 41 ahead / 2 dirty (only host
  with unique unpushed work). Peter: fine to drop it.
- **Handed the sync to the `ansible` strand** (correct owner — it owns the
  inventory + `git-repos` role). It ran the role and reported "7/7 hosts synced
  clean, failed=0".
- **Verified the run — it was only partial.** Re-swept + direct
  HEAD-vs-`origin/main` check on the inventory-managed repos:
  - eclipticam `astro` off `moon-net-marking`, back on `main` ✅ (the one
    at-risk item — resolved).
  - **But several managed repos are still BEHIND after the run:** homepi
    `Berrylands`/`busclock`/`super` (super stuck at Jul-16), cloudcam `super`,
    muppet `Berrylands`, puppy `astro`. Fetch *did* run (FETCH_HEAD ~15:33) but
    the working tree didn't advance — smells like `safe_pull` stashed a dirty
    tree / hit a non-fast-forward and `ansible.builtin.git` reported `ok`
    without advancing (so the strand's `failed=0` was falsely reassuring).
    Flagged back to the `ansible` strand to investigate the module behaviour.
  - **Lesson recorded:** trust-but-verify a delegated fleet sync with a direct
    HEAD==origin/main check, not the runner's own success count. And beware
    running `check-repos.sh` *concurrently* with the sync — its fetch races the
    role's pull and yields mid-sync "behind" numbers (bit me here).

### Earlier session

- **`alerting` tidied.** `remove-hourly-digest` was 1-ahead/0-behind main (clean
  fast-forward): removes the hourly incident digest + disables the feeds
  schedule. Fast-forwarded into `main`, pushed, branch deleted local + remote.
  Repo now clean on `main`.

## Pending / loose ends

- **Fleet sync — CLOSED from this keeper's side (2026-08-03).** Sweep done,
  handed to the ansible strand, which ran the role + hand-fixes; this keeper
  verified against `origin/main` throughout. Remaining loose ends are the
  ansible strand's / Peter's, not this strand's: (a) ff homepi `busclock`, (b)
  the homepi `group_vars` inventory fix (needs Peter — real blast radius). No
  data-loss risk outstanding (the one at-risk item, eclipticam moon-net, is
  resolved). After the strand's root-cause + hand-fixes and this keeper's
  re-verify, everything else reconciled:
  - homepi `super`+`Berrylands`: hand-ff'd by ansible strand, **SYNCED** ✅.
  - puppy `astro`, muppet `Berrylands`: **false alarms of mine** — not in those
    hosts' `git_repos`, so present-but-unmanaged and correctly untouched. (Same
    scope trap: `check-repos.sh` reports every clone; only inventory-listed ones
    are ansible's to move.)
  - eclipticam `moon-net-marking` dead branch left on-host for manual delete:
    `git -C ~/astro branch -D moon-net-marking`.

- **NEW durable finding — homepi ansible inventory bug (for Peter).** The
  ansible strand found `inventory/group_vars/homepi.yml` is **silently ignored**:
  there is no `[homepi]` inventory *group* (homepi is a host in `[stationary]`),
  so that ~100-line file — `git_repos`, `ansible_user: pi`, `pi_packages`,
  `users`, `dotfiles` — never applies. That's why homepi's super/Berrylands/
  busclock never synced (only `git_repos_global` reached it). Fix = move it to
  `host_vars/homepi.yml` (merging the existing one), but it changes
  `ansible_user` and enables roles — **too much blast radius for an autonomous
  merge; needs Peter's review.** Owned by the ansible strand; noted here as the
  root cause of the homepi sync misses.

Snapshot of pip's own data-loss surface at session end (not yet cleared):

- **`splay/splay-grid-mode`** — 1 ahead / 7 behind. One commit to rescue
  (`4c9ab6e` grid contact-sheet mode). Needs a rebase onto current main (not a
  fast-forward); at most one conflict round. The obvious next easy win.
- **`aifabric` — 3 orphaned branches**, all heavily diverged and overlapping
  (all touch the `aicli` graduation), so real reconciliation not a quick merge:
  - `feat/spool-tool` — 1 ahead / 12 behind. Adds `bin/spool` (generic
    clobber-safe one-file-per-item spool primitive; maildir reduced to essence)
    and refits `bin/idea` onto it. Decision doc `docs/decisions/spool.md` names
    two intended call sites: **ideas (done on this branch)** and **mail/`ding`
    (specified, NOT yet built)** — deliver = `spool put` into `MAILBOX.d/`,
    armed receiver = `spool drain`, keep the waiter lifecycle + legacy
    `MAILBOX.md` compat. "Anything else?" — doc deliberately leaves it as "the
    caller is the address"; only hint at a third use is an ad-hoc review-notes
    inbox (`git diff --stat | spool put review-notes`). Open question before any
    merge: does this branch's `bin/idea` refit still match main's current
    `bin/idea`, or has it drifted in the 12 commits behind.
  - `graduate/sessions-recolour` — 11 ahead / 13 behind.
  - `pr/aifabric-dogfood-main-20260724` — 10 ahead / 12 behind.
- **`astro` stash** — `stash@{0}` "WIP: eclipticam v3w_uploader -> canonical
  layout (migration paused 2026-06-20)". 6+ weeks old. Decide: resume, or drop.
- **Local uncommitted work** (from the session-start `all-repos-status`) in
  aifabric (`bin/aicli`), dotfiles (`.config/.config/ssp` — note the doubled
  path, worth a look), mywebsite (`DEPLOY_COUNT`, `lambda/cv.html`), splay,
  strands, super. Re-run `all-repos-status` before acting — it drifts.

## Decisions

- **`alerting`**: fast-forward-only merge (`--ff-only`) for a 0-behind branch —
  no merge commit, cleanest history. Delete the branch both places after.
- **General**: these branches are solo (yours, no open PRs, no collaborators),
  so **rebase is safe** and gives cleaner linear history than merge. Only avoid
  rebase on branches others have pulled. `--ff-only` when 0-behind; rebase when
  behind>0 and few commits; merge/cherry-pick when heavily diverged.
