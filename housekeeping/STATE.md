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

## What exists

- Strand mission written (git housekeeping / data-loss framing).

## Done this session

- **`alerting` tidied.** `remove-hourly-digest` was 1-ahead/0-behind main (clean
  fast-forward): removes the hourly incident digest + disables the feeds
  schedule. Fast-forwarded into `main`, pushed, branch deleted local + remote.
  Repo now clean on `main`.

## Pending / loose ends

Snapshot of the fleet's data-loss surface at session end (not yet cleared):

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
