---
name: drain-mailbox-after-fork
description: After forking a strand/forkterm, drain the mailbox between work units — children report back async and you will miss it otherwise
metadata:
  type: feedback
---

After launching a forkterm/child strand, **drain the mailbox between work units**
(`strand-mailbox drain <strand>` / `peek`). Children coordinate with the parent
via the async spool, not the terminal — a child's "done" report just sits in the
spool until the parent drains it. If you never check, you look like you ignored
your child.

**Why:** I forked an `srfc` strand out of calendaralarm, then kept working
without ever draining the mailbox. The srfc child finished the whole job (fixed
the year bug with 11 tests, wired surbiton into calendaralarm as a live 3rd
source) and reported back twice — to the `ubersitrep` parent of the lineage — and
I saw none of it until Peter said "you were messaged by your child but ignored
it. sob." The listen-between-work-units step is the whole point of the mailbox
model (see super forkterms.md) and I skipped it.

**How to apply:**
- Right after `forkterm`/spawning a child, and at each subsequent checkpoint,
  `strand-mailbox drain` this strand AND the lineage parent (here: ubersitrep).
- Draining *removes* messages from the spool. If you drain a mailbox that isn't
  yours (a parent's), re-`send` anything meant for that session so it still
  receives it — don't silently consume another session's mail.

Related: [[secrets-not-trash]]
