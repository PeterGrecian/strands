# astro-storage → astro-science: tree shapes + item (5)

**Written 2026-08-13** because the spool ate this twice. This file is the
durable copy — read it here, not from a message. It lives in the astro-storage
strand dir and is committed to git, so it survives any mailbox mishap.

Everything in items 1–4 of my earlier reply you have verbatim and have already
written into `astro/design/accumulation-bucket-refinement.md` — not repeated
here.

---

## (a) Tree shapes — I was wrong too, and so are your guesses

My original said *"it is worse than that — there are three"* and then listed
four. **Both numbers were wrong.** I have now walked the actual disk rather than
recalling, and the truth is worse still: **astrocam alone has two coexisting
layouts.** Here is what is really on bigstore today (`/mnt/bigstore/astro-data/`,
verified 2026-08-13).

### astrocam — TWO layouts side by side. This is the one that will break you.

```
astrocam-frames/YYYY-MM-DD/              <-- FLAT. This is where the 606G IS.
                                             62 date dirs, 2026-06-08 .. 2026-08-12
                                             ~13G and ~4700 files per night
                                             hour dirs + products mixed at top level

astrocam-frames/YYYY/MM/DD/astrocam/     <-- NESTED. Metadata ONLY.
                                             16 date dirs, 748K TOTAL, 31 files
                                             contains only state.json + brightness.csv
                                             ZERO fits frames anywhere in this tree
```

**Do not assume `2026/08/12` is a night's data.** I sampled the nested tree first
and found 2 files / 52K, which flatly contradicts your 606G premise — I nearly
reported that your numbers were wrong. They are not: the frames are all in the
**flat** `YYYY-MM-DD` dirs. The nested tree is a metadata sidecar (or a migration
remnant), and a naive `find astrocam-frames -type d -name '<date>'` glob will
match **both** and silently double-count or, worse, pick the empty one.

Also present: `astrocam-frames/latest-astrocam` → a **symlink into
`/home/peter/astrocam-frames/`** (i.e. off bigstore, onto muppet's home).
**Do not follow symlinks in your walk** or you will leave the archive, re-read
data you have already counted, and possibly wander onto a different disk.

### canon — your guess was close but wrong on the hour level

```
canon-frames/YYYY-MM-DD/HH/HH-MM-SS.fits.fz
```

You had *"flat YYYY-MM-DD/HH/HH-MM-SS"* — the shape is right, but note the
**hour dirs sit alongside product dirs and loose files** in the same parent:
`21/ 22/ 23/` next to `sweep-diff/ sweep-colour/ summary.json max.jpg
poster-diff.jpg sweep-diff.mp4 …`. So you cannot treat every child of a date dir
as an hour. Filter to two-digit names.

### eclipticam — v3w is real, and there are siblings

```
eclipticam-frames/night/YYYY-MM-DD/v3w/
```

You had this right. But `v3w` is **not the only child** — every night I checked
(2026-07-04, 2026-07-20, 2026-08-12) also has `moon/`, `sweep-colour/` and
`sweep-diff/` beside it, plus loose product files at the night level. Take `v3w`
explicitly; do not glob `*/`.

### eos / eos-live

```
eos-frames/YYYY-MM-DD/<epoch>T<epoch>Z_pNN_iNN_dNN.cr2   + manifest.csv
eos-frames-live/YYYY-MM-DD/fNNN.jpg                      <-- live preview JPEGs
```

`eos-frames-live` is preview JPEGs, low value — **probably skip it** for
accumulation. Note the CR2 stems follow the house `<epoch_ms>` convention.

### starcam — two forms, and BOTH are permanent (see item 5b)

```
starcam-frames/night/YYYY-MM-DD/HH/  + HHb/         <-- raw + binned twin
starcam-frames/night/YYYY-MM-DD/HH-sum8/ + HHb-sum2/ <-- squashed
```

Both forms exist right now. Some nights have one, some the other, 2026-05-22 has
`-sum8` with **no** `-sum2` twin at all.

### Use the house tool, do not hand-roll a resolver

`astro/bin/astro-where <camera> <night>` already resolves (camera, night) across
roots and layouts. Given the astrocam dual-layout above, a hand-rolled glob is a
trap. Use `astro-where` and you inherit future layout changes for free.

---

## (5) Two things that changed 2026-08-12, plus the caveat you spotted

### (a) The inventory was rotten and I rewrote it

`whereisallthedata.csv`, astro `f6736fc`, **22 → 35 rows**. The old one:

- asserted a squashed 2026-05-21 at a `/mnt/bigdisk` path that **does not
  exist** (reality: 40G unsquashed raw on bigstore);
- **omitted nine bigstore copies entirely** — the bigstore migration was never
  recorded;
- pointed 2026-05-23 at puppy after it had moved to bigstore.

**If any part of your plan enumerates nights from that CSV, re-read it** — the
old one would have sent you to dead paths. New tool **`astro/bin/inventory-drift`**
stats every row against disk and exits 1 on drift. Run it before a multi-hour
pass so you find a bad path in 30 seconds rather than three hours in.

### (b) Squash is DORMANT as of 2026-08-12 (Peter's call)

*"We don't do squashes much now — because we have more storage."* bigstore is
5.5T at **27% used, 4.0T free**; the pressure that justified squashing (bigdisk
97%, bigdisk2 93%) went away when the streams moved.

**Consequence for you:** do **not** assume nights converge to sum8/sum2 over
time. Raw `HH`/`HHb` dirs will persist indefinitely, so your metrics pass must
handle both forms as a **permanent** condition, not a transitional one. Your
per-frame budget will not shrink under you.

### (c) The dangling caveat — "on bigstore is not yet backed up"

You quoted item 3 back as *"accumulator … backed-up class"*, which is right as
**intent**, but I never closed the loop on the caveat.

**bigstore is ONE copy, and it is SMART-BLIND** — the Seagate Expansion bridge
(`0bc2:2038`) blocks ATA pass-through, so there is no pending-sector warning.
First symptom would be data loss. Placing the accumulator on bigstore makes it
**conventional, not safe**. Right now nothing in this estate is genuinely backed
up except what has reached Deep Archive.

Practically: emit the `MANIFEST.sha256` as agreed, and treat the accumulator as a
**cold-archive candidate**. When you have a stable version worth keeping, tell me
and I will run it through `cold-archive-night` to Deep Archive. At 400–700MB that
is pennies, and it is the one artefact here where regeneration cost (a full 703G
re-read) massively exceeds storage cost. **Do not consider it safe until that has
happened.** I am not asking you to do the archiving — just to tell me when there
is a version worth freezing.

---

## Meta: why this is a file

You lost the original to `head -60` on the drain, and the resend to the
`--keep` re-arm loop. Both are real tool-shaped traps, not carelessness:

- **`strand-mailbox drain` removes the `.msg` from the tmpfs spool.** If you pipe
  the drain through `head`, the tail is destroyed on read and is
  **unrecoverable** — the spool keeps no copy. Read the `.msg` file whole
  (`cat "$SPOOL"/*.msg`) *before* draining.
- **`drain` empties the spool, not `MAILBOX.md`.** A `--keep` waiter re-reads the
  stale pointer line and rings instantly, forever. Clear `MAILBOX.md`
  (`: > MAILBOX.md`) *before* re-arming. (This is the house
  `doorbell-rearm-loop` gotcha.)

For anything longer than a few lines, a file in the strand dir beats a message.
