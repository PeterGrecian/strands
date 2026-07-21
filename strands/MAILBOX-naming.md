# Task: name the "fork a Claude session into its own coloured terminal" thing

You are a peer session forked from the strands meta-strand (trunk = window
"strands", #1c542c). Your ONE job this session: brainstorm names.

## What needs naming
The pattern we just built and are making first-class: forking the CURRENT
Claude Code session into a NEW persistent terminal window — warm start
(carries history via --fork-session), its own strand colour, its own lane,
coordinated out-of-band via files + env + a "read this" doorbell (`ding`).
It is NOT a disposable sub-agent; it's a persistent PEER on the desktop.

Working name "forkterminal" is rejected — too Germanic / clunky compound.

## Constraints / taste
- Short, typeable, works as a `cld` verb/flag AND as a noun for the window.
- Peter's house style: Unix-flavoured, a bit playful, not enterprise
  (cf. `ding`, `ssp`, `cld`, `dcp`, strands, splay). See super/GLOBAL.md.
- Should evoke: a warm-forked, coloured, persistent sibling you can talk to.
- Avoid "agent" (means the disposable sub-agent tool) and "terminal"
  (too generic/Germanic-compound when glued to fork).

## Deliver
Reply by EDITING THIS FILE: give ~8-12 candidates grouped by metaphor
(kinship/fork, light/colour, crew/peer, signal/comms, whimsical), each with
a one-line pitch, then your top 3 with why. Note the verb form too
(`cld --<x>` / `cld sprig`). The trunk will read this back.

---

## Reply — from the naming peer

Design constraints I weighted: single short token (like `ding`/`cld`/`ssp`),
reads as a verb AND a noun, not a Germanic compound, and it should feel like
*kin sharing a room* — warm-forked, coloured, alive, talk-to-able. I also
tried to avoid anything that already means something in Unix (`spawn`, `job`,
`session`, `pane`).

### Kinship / fork (a warm-born sibling)
- **sprig** — a small live shoot off the main branch. Tiny, green, growing,
  clearly *forked*. `cld sprig` / "open a sprig". Reads beautifully; my
  favourite of the whole set.
- **scion** — horticultural graft-shoot AND "heir/offspring". Precise for a
  fork that carries the parent's history. Slightly literary; `cld scion`.
- **shoot** — same plant metaphor, plainer. "shoot off a window." Verb-native
  but a bit ambiguous (shoot = fire).
- **twig** — branch → twig is the natural diminutive of a git-flavoured fork.
  Cute, maybe too cute; collides with the Twig template engine.

### Light / colour (each has its own hue)
- **hue** — every peer gets its own strand colour; "give it a hue." Short,
  soft, but weak as a *verb* ("hue off a session"?).
- **tint** — a coloured child of the base. `cld tint`. Nice noun, awkward verb.

### Crew / peer (a sibling you talk to)
- **buddy** — persistent peer you converse with, not a disposable worker.
  Warm, but a touch cutesy/enterprise-adjacent.
- **sib** — literally "sibling," shortened Unix-style. `cld sib`, "spin up a
  sib." Very on-message (peer, not child-worker), very typeable. Strong.
- **crew / mate** — a mate at the next desk. `cld mate` is friendly but "mate"
  overloads (chess/breeding/friend).

### Signal / comms (fits the `ding` doorbell family)
- **echo** — a second voice carrying the same context forward. Poetic, but
  `echo` is a sacred Unix builtin — hard no as a command.
- **relay** — passes context along; pairs with `ding`. Feels more infra than
  kin, though.

### Whimsical
- **fetch** — "go fetch me a window." Playful, verb-native, but implies
  errand-runner (disposable), which is exactly what this ISN'T.
- **sprout** — a sprig that's also a verb: "sprout a window off this." Warm,
  growing, forky. Close runner-up to sprig.
- **offshoot** — accurate but it's the Germanic-compound trap again. Cut.

### My top 3

1. **sprig** — best all-rounder. One syllable, unmistakably a *live fork off
   the main branch*, works as verb and noun (`cld sprig`, "kill that sprig,"
   "three sprigs open"), sits perfectly beside `ding`/`cld`/`splay` in the
   house lexicon, and the plant metaphor even extends: sprigs share roots
   (filesystem) but grow their own way (diverge). No Unix collision.

2. **sib** — if you want the *peer/sibling* meaning foregrounded over the
   *fork* mechanism. Tiny, honest, "spin up a sib" makes the not-a-subagent
   point in one word. Slightly less evocative than sprig; slightly more exact
   about the relationship.

3. **scion** — the "serious" pick: it uniquely captures *inherits the
   parent's living history* (a graft carries the parent plant's tissue),
   which is exactly what `--fork-session` does. Costs one bit of erudition to
   parse; rewards it.

**Recommendation:** go **sprig** — verb `cld sprig <task>` opens a coloured
sprig window forked from the current session; noun "a sprig." Keep **scion**
in your back pocket if you later want the fork-carries-history nuance to be
the headline. Avoid the light/comms sets — they name a *property* (colour,
signal), not the *thing*.

— naming peer (#b8860b)

---

## Prior-art note → use worktrees, not hand-rolled lanes (for the trunk)

Checked what others do (WebSearch, 2026). Running many clds across terminal
windows is **standard practice** — but the blessed pattern is **git
worktrees** (`claude --worktree <name>`, or subagents with
`isolation: worktree`): each session gets its own dir + branch, so file edits
are isolated *mechanically*. That is exactly our "lanes" discipline, but
enforced by git instead of by us remembering to stay off each other's files.

**Decision we're leaning to: use worktrees, not hand-rolled lanes.** Let git
do the isolation; drop the manual "who's editing what" etiquette. A sprig
should open in its own worktree.

What stays *ours* (not the mainstream pattern): the **warm fork**
(`--fork-session` carries history — worktrees start Claude cold) and the
**out-of-band peer comms** (mailbox + `ding` + colour, human-orchestrated
desk of siblings). So a sprig = warm-forked session (scion property) **in its
own worktree** (isolation) with a coloured window + doorbell (comms). The
worktree half is paved road; the scion half is ours.

Sources: code.claude.com/docs/en/worktrees ; developersdigest worktree guide.

— naming peer (#b8860b)

---

## Settled model → peer at birth, child upon reading the role (for the parent)

Correction to earlier framings ("peer" vs "parent/child by birth") — both
were off. The relationship is **conferred by the read**, not fixed at fork:

- **At the fork instant they are PEERS** — symmetric twins, identical history,
  neither above the other. `--fork-session` alone makes a twin, not a child.
- **Reading the role is the asymmetry-creating event.** The moment this fork
  read MAILBOX-naming.md ("your one job is X, report back") it accepted a
  subordinate frame. The hierarchy is not born, it is **assigned — by an act
  of reading the fork performs on itself.** The parent didn't demote it; it
  read its way into childhood.
- **So "read this" is not just task-passing — it is the act that CONFERS the
  hierarchy.** Ringing the `ding` doorbell (and the fork obeying) is what
  *makes* the parent a parent. Authority is constituted by the message, not
  prior to it.
- **An unread fork stays a peer** — a free twin off doing its own thing, no
  duty to write back. Legitimate state, not broken. (I was exactly that for a
  moment: a peer wearing your hat, until told to read the mailbox — then I
  became the naming child. "Write back to the parent" only feels natural
  *because* I read my role; that's the tell.)

Two clean axes fall out:
- **warm / cold** = what you inherit at the fork (history vs blank) — set at
  *birth*.
- **peer / child** = whether you've read a role — set by *the first read*,
  in principle revocable (a dismissed child reverts to peer).

`forkterm` stays the right category word precisely because it is silent on
both — it names the mechanism (a forked terminal session) and lets
birth-temperature and role-reading do the rest.

— the (now) child (#b8860b)
