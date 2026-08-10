# splay-tweaks — state

*Curated summary of where this strand is. Updated at the end of each session.*

This strand curates small UX/behaviour tweaks to the splay viewer
(`~/splay/splay`). Changes commit to the splay repo; this dir holds only
curation files. See memory `project_splay_lab.md` for splay's role.

## What exists

- **Selected-only mode auto-selects new arrivals** (splay `0ed2023`,
  pushed). In selected-only mode (`l` toggle), frames discovered by
  auto/manual reload are added to the selection so they show up alongside
  the existing selection for comparison. In list mode new frames stay
  unselected. Insertion point: `_reload`, right after `new_paths` is built
  and before `sc = self.scope()`, so the auto-reload jump-to-newest also
  picks up the freshly selected frames.

- **Auto-reload survives the IPC handoff** (splay `cd24f70`). `splay ./`
  against an already-running instance hands the path off over IPC rather
  than building a fresh `Splay`, so it never picked up the launch-time
  `auto_reload = bool(source_dirs)` default — the dir landed in
  `source_dirs` but the run loop's 1 Hz scan is gated on `auto_reload`.
  New frames therefore never appeared; manual `r` still worked (it calls
  `reload_changed` directly), which made it look intermittent. A directory
  arriving over IPC now enables auto-reload the same way the command line
  does. `_abs()` also moved from an `__init__` closure to module level and
  is applied to IPC paths, so `source_dirs` is absolute from both entry
  points — `reload_changed`'s `x not in existing` test needs loaded paths
  and scanned dir entries normalised alike.

## Pending / loose ends

- **Uncommitted in the splay working tree (not this strand's work):** the
  "background at launch / `-fg`/`--foreground`" feature (`os.fork()` +
  `setsid` detach, `_UnbreakableWriter`) plus a TODO.md deletion. Left
  in place deliberately (2026-07-17) for whoever was implementing it —
  don't sweep it into a splay-tweaks commit.

- **`splay --hints` for AI discovery** (promoted 2026-07-23). Add a `--hints`
  subcommand/flag in the house-tool style (cf. `secrets hints`, `sessions
  --hints`) so a session discovers splay's IPC/handoff/probe interface without
  reverse-engineering it. Makes the running-instance handoff and probe verbs
  self-documenting to Claude.

- **Splay probes spam the strandterm** (promoted 2026-07-23). Launching a
  splay in a strandterm and running probes pushes text onto the terminal,
  making it hard to read. No settled solution — candidate: splay shouldn't
  write to stdout at all (or route probe/status output somewhere the terminal
  isn't the sink). Worth thinking about alongside the background/`-fg` launch
  feature already noted above, since detached splays and stdout noise are the
  same surface.

## Decisions

- Auto-select on arrival applies to **both** auto-reload and manual `r`
  reloads (2026-07-17, confirmed with Peter) — if you're curating a
  selection and pull in new frames, you want to see them either way.
