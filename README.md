# Strands — recurring cross-repo workstreams

A *strand* is the unit between "repo" and "session": a long-running theme
(e.g. astro deliverables) that spans several repos and gets revisited every
week or so. **Sessions are disposable; the strand's state is curated here,
in git.** This is the "memory bank" pattern: the agent reads the state files
at session start and updates them at session end, instead of relying on
resumed conversations (whose compaction is lossy and uneditable).

## Launching

```bash
cld -s <strand-name>       # e.g. cld -s astro-deliverables
cld -s                     # bare: list the strands
```

`cld -s` (`--strand`) `cd`s into the named directory here and passes each
line of the strand's `dirs` file to claude as `--add-dir`. (Note: `-h` is
skip-housekeeping, `--help` is help.) Because Claude Code keys session
history and auto-memory to the launch directory, each strand gets:

- **its own CLAUDE.md** auto-loaded (plus `super/CLAUDE.md` from the parent)
- **its own session list** — `claude --resume` from the strand dir shows
  only that strand's sessions
- **its own memory** — `memory/` in the strand dir, symlinked from
  `~/.claude/projects/-home-peter-super-strands-<name>/memory` so it's in git

## Anatomy of a strand

| File | Role |
|---|---|
| `CLAUDE.md` | Mission: what the strand is, which repos it spans, session ritual |
| `STATE.md` | Curated state: what exists, pending, decisions. **Not a log** — edit it down |
| `IDEAS.md` | Inbox: append ideas between sessions from anywhere; triaged next session |
| `dirs` | Extra working directories, one per line (`~` ok), passed as `--add-dir` |
| `colour` | Terminal background colour (rrggbb hex). Auto-assigned on first launch from the golden-angle hue wheel; edit by hand to override |
| `memory/` | Strand-scoped auto-memory (symlinked from `~/.claude/projects/`) |

## Two kinds: keepers and builders

Every strand is one of two kinds, and knowing which shapes how a session behaves:

- **Keeper** — a *bounded concern*: it owns and serves one subject, staying in
  steady state (maintain it, answer about it precisely). It doesn't grow; it
  keeps. Think of a strand whose job is to be the reliable source of truth on
  one thing.
- **Builder** — an *active development* workstream with a trajectory: it's
  growing or changing something, driving work forward toward a goal. Most strands
  are builders; this is the default.

The kind is declared by the **first word of the strand's `blurb`** summary line:
if it starts with **"Keeps"**, the strand is a keeper; otherwise a builder. So a
keeper's one-line summary reads its own declaration — e.g. *"Keeps the aicli
launcher hardened…"*. aicli exports this as `CLD_STRAND_KIND` and its SessionStart
hook injects it, so a session opens **knowing which kind it is** and can lean
accordingly: a keeper resists scope-creep and keeps its served surface sharp; a
builder drives the work and curates STATE.md for the next visit. (No blurb file
⇒ builder, so today's blurb-less strands are all builders until declared.)

## The loop

1. Between sessions: jot ideas into `IDEAS.md` (it's in git — any machine).
2. Session start: Claude reads STATE.md + IDEAS.md, triages the inbox.
   **Promote by default** — moving an idea to STATE.md pending is the cheap,
   reversible default; *dropping* is the deliberate act (a good idea dropped is
   lost silently; a mediocre one promoted just sits visibly in pending). The
   inbox already filtered once — don't double-tax ideas.
3. Work. **Prune the pending list** while you're here — this is where the lossy
   judgement now lives (you have the most context at review); else STATE.md rots
   into a second inbox.
4. Session end (`dcp`): STATE.md updated (and pruned), IDEAS.md emptied of triaged
   items, committed and pushed with the rest of super.

## Resume vs fresh

Resume (`claude --resume` from the strand dir) to finish a *task* — days.
Start fresh for a new *visit* to the strand — weeks. STATE.md carries
everything a fresh session needs.

## Creating a new strand

```bash
strands new <name>         # scaffold non-interactively, then: cld -s <name>
cld -s <name>              # or scaffold+launch in one (prompts: Start new strand? [y/N])
```

`strands` (in `super/bin`) is the strand system as a typed tool: bare
`strands` lists them (with LIVE marks for strands that have a running
session), `strands desk` is the look-around view (STATE.md recency +
latest heading), `strands new <name>` scaffolds without the interactive
prompt — safe from scripts and agents. `strands --hints` for the AI-facing
description.

Answering `y` scaffolds the strand from `.template/` ({{name}} placeholders
substituted), creates the `~/.claude/projects` memory symlink, and launches
into it. Set the mission in CLAUDE.md and the working dirs in `dirs` — by
hand or as the first thing in that session. Note the memory symlink is
machine-local: on another machine, recreate it (see `.template/` recipe in
`bin/cld`).
