# splay-ai-discovery — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

Strand created 2026-07-14 from notes taken while using splay as the frame
viewer during an astro-canon EOS-2000D focus session.

### How an agent should use splay (the core discovery)

- **splay is *the* viewer here.** Don't render images inline or copy JPEGs to
  `~/tmp/` for `xdg-open` — point splay at them. splay lives at `~/splay`
  (145 KB single script `splay/splay`), on `$PATH` as `super/bin/splay`.
- **`splay <dir>` hands off to the already-running instance** ("handed off N
  path(s) to running splay") and switches its view. One persistent viewer;
  scripts point it at things. `--new-instance` forces a separate process.
- **auto-reload** (`R` / `--auto-reload`, was already on) rescans source dirs
  every second and jumps to the newest arrival → capture into a watched dir
  and frames appear live in Peter's viewer.
- **`splay --send key:NAME`** injects hotkeys over IPC (`--send key:r`
  reloads). The lever for an agent to drive the viewer programmatically.
- State files `~/.splay-loaded.json` / `~/.splay-state.json` expose what's
  loaded and the view settings — script-inspectable.

### `--help` assessment (Peter asked "is it good enough?")

Good enough for essentials (paths, handoff, `--send`, `--auto-reload`), but
had to read source for: (1) the **full hotkey table** — `--help` names keys
but never lists them with meanings; (2) **valid `--send key:` names** (arrows,
select, wipe: `LEFT RIGHT s d w`…) — only two examples given; (3) **state-file
locations**. Small, high-value doc additions would make it self-sufficient.

## Pending / loose ends

- **Default sort mode → `added`** (Peter's request). New frames should always
  be at the *start* of the sequence, **even when file timestamps are wrong**
  (the EOS clock drifted; NFS mtimes were in the future — mtime sort is
  unreliable, which is the whole point of `added`). Shipped default is
  currently `"name"` (`splay/splay` line ~808).
- **Root-caused bug: `added` degenerates to `name` on initial dir load.**
  `added` orders by `added_order[p]`, a monotonic `_added_seq` set in the
  order paths are *first seen*. On the constructor's initial load (lines
  ~816–818) paths are iterated in the order passed — i.e. **name order** for a
  directory — so every pre-existing file is bulk-assigned seq in name order.
  True newest-first only works for files that arrive *later* via the reload
  path (lines ~1697–1699). Hence for `/mnt/muppet/bigdisk/canon/tmp/` (all
  frames pre-existed the load) `added` looked just like `name`.
  - Fix options: (a) change default to `added`; (b) seed initial `added_order`
    meaningfully instead of name order — but mtime is the only on-disk arrival
    signal and Peter says it's unreliable, so this is the real design tension;
    (c) persist `added_order` per-path across sessions so a re-opened dir keeps
    true first-seen order. At minimum document that `added` = arrival *while
    splay is running*.
- **Doc improvements to `--help`**: hotkey table (or `--list-keys`), valid
  `--send key:` names, state-file locations.

- **`splay hints` — AI-oriented, on demand** (promoted from IDEAS 2026-07-17).
  The `secrets hints` equivalent for splay: the non-obvious things an agent
  would otherwise get wrong, surfaced only when needed (lazy-context). `-h`
  already covers *how to launch/drive*; `hints` covers **role + capabilities**.
  Peter: two things must be well known —
  1. **splay is for images** — it's *the* viewer; don't render inline / copy to
     `~/tmp`. (The whether/why the origin agent missed.)
  2. **Unusual 2-way communication** — the guess-it-wrong part: `splay <dir>`
     hands off to the *running* instance (`--new-instance` forces separate);
     `--send key:NAME` injects hotkeys over IPC; `~/.splay-loaded.json` /
     `~/.splay-state.json` expose live state; `p` emits parseable `PROBE` +
     `~/.splay-probes.log`.
  - Keep `hints` static/always-safe (role + capabilities); the *live* "instance
    running, showing what dir" is dynamic → maybe a separate `--status`.
  - **This is a keeper deliverable.** The keeper *pattern* was written up for
    the `aifabric` strand (`aifabric/ideas/20260717T0617-splay-ai-discovery-…`):
    `splay hints` = the cheap self-discoverable path of an eventual
    **splay-keeper** (sibling strand, Peter's call), i.e. the keeper's published
    API. `mywebsite-keeper` is the precedent; `splay hints` = 2nd `hints`
    instance. Build the `hints` code here in `~/splay` when picked up.

## Decisions

- Code changes commit to `~/splay`; this strand dir holds only curation.
