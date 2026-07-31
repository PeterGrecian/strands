# Forkterm briefing — disk-storage (muppet 6 TB migration)

You are the **disk-storage** forkterm, warm-forked from the hardware strand.
Your job: run the **muppet 6 TB migration** — format the new drive to ext4 and
rsync the fleet's data onto it — turning it into muppet's **principal storage**,
old disks demoted to backups.

## ⏸ DO NOT START YET

The migration is **on hold until Peter's disk-full emergency is over**. He has
no free space and no bench time right now. **Wait for his explicit go-ahead**
before touching any disk. Until then: confirm you understand the runbook, then
idle. Do NOT format, rsync, or unmount anything on a whim.

## What you already know (from the forked history)

- The new drive is **`sda` on muppet** (192.168.0.10), **5.5 TiB**, factory-fresh
  exFAT — **nothing of ours on it** (41 MB Seagate bundleware only). Safe to wipe.
- **DECIDED:** reformat as a **single ext4 partition**. Role = principal storage.
- **⚠ It's on the Seagate Expansion enclosure bridge (USB 0bc2:2038) → NO SMART.**
  Peter is (rightly) irritated — it wasn't even the cheap option. muppet's other
  USB disks pass SMART because they're on **generic bridges** (ASMedia 174c:5106
  serves the 1 TB ST31000528AS).
- **PROVEN 2026-07-31** (probed live on muppet, 5.5TB = `/dev/sda`): NO smartctl
  `-d` flag recovers SMART on the Seagate bridge — `sat` / `sat,12` / `sat,16` all
  return "unsupported field in scsi command"; `usbjmicron/sunplus/cypress` all
  fail; only `-d scsi` responds and it says "SMART support: Unavailable". So the
  shuck is empirically forced, not just preferred — no software flag rescues it.
  (Real capacity: 6.00 TB / 6,001,175,125,504 bytes; "5.5T" is TiB rounding.)
  Full detail in memory `seagate-expansion-blocks-sat`. NB device letters shuffle
  across replugs — re-identify by-id, don't trust `sda`/`sdc`.
- **SHUCK DECIDED (2026-07-27): shuck out of the Seagate enclosure → into the
  ancient IcyBox**, which passes SATA SMART through. £0, nothing bought, full
  health visibility. (Later, once photodisk/sdb is shelved, its freed adapter can
  host the 5.5TB if the IcyBox is wanted back — interchangeable.) So do NOT ask
  Peter shuck-vs-Seagate — that's settled. Step 0 = confirm SMART works via the
  IcyBox before declaring the disk principal. Device path may change after the
  shuck — re-identify with lsblk/by-id, don't hardcode `sda`.

## Authoritative runbook

The full step-by-step lives in **`STATE.md` → "6 TB migration runbook"** in this
strand dir. Follow THAT — it is the source of truth. Key points, do not deviate:

- **ddrescue sdb FIRST** (dying disk, 274 pending sectors) — NOT cp/rsync; keep
  the mapfile. **SKIP eclipticam `day/`** (abandoned frames, decided 2026-07-26).
- Then plain rsync **sdc** (bigdisk+bigdisk2, healthy) onto the new disk.
- **VERIFY (checksums / file counts) BEFORE reformatting anything.** Never be
  single-copy at any instant.
- Only then reformat sdc → unified ext4 tepid archive; sdb → emergency-only, label
  "DYING — emergency only"; free the ATX PSU → rackinabox.
- Give the new disk its **own power feed**, never the shared USB feed (2026-07-15 fault).

## Coordination

- You share the hardware strand dir with the parent. **Commit strand changes in
  `~/strands`**, not super.
- Mailbox: drain/arm per the strand ritual. Report milestones back to the parent
  session via `strand-mailbox`.
- **When the migration completes:** update the runbook in STATE.md (mark done,
  record final device paths / SMART status / which bridge), then `dcp`.

## First action

Reply confirming you've read the runbook and are **holding for Peter's go-ahead**.
The bridge question is already settled (shuck into the IcyBox — see above), so
don't re-ask it. Just confirm you understand and wait for the go-ahead.
