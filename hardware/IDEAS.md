# hardware — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->

## rackinabox is the structural fix — PRIORITISED (2026-08-10)

Peter: "rackinabox opens up many opportunities and I want to prioritise it."

This strand should treat rackinabox as the **physical answer to several
hardware items currently tracked as separate**, not as a side project:

- **Interfaces** — dressed/strain-relieved cabling instead of tether cables
  hanging off laptop sockets. Directly targets the muppet failure mode
  ([[eos-wedges-were-a-worn-usb-socket]]); wear stops being the failure mode.
- **Power** — one ATX PSU with real rails replaces the shared USB feed that
  caused the 2026-07-15 disk drop. The soldered 12V is instalment one; the
  freed ATX PSU is ALREADY earmarked for rackinabox in the 6 TB runbook.
- **Thermal** — designed downdraught 140 mm fan + dual-chamber PSU quarantine,
  vs the fan bodged onto photodisk when it hit 46 degC.
- **Silence/siting** — makes always-on infrastructure tolerable in the house.

Its stated capacity ("3 laptops + 3 HDDs + a couple of Pis + an ATX PSU") maps
onto muppet/pip/puppy + bigstore/bigdisk + the freed PSU almost exactly.

**⚠ COUPLING — rackinabox is CONSOLIDATION, NOT REDUNDANCY.** Putting the disks
and all three laptops in one box, one room, one PSU makes the **correlated**
failure risk WORSE (see [[redundancy-not-capacity]]). The offsite subset must
happen ALONGSIDE the build, not instead of it. Design it in, don't discover it.

**Sequencing notes:**
- Do the **IcyBox shuck** before/during the build — bigstore's bridge has to
  change anyway and the rack is when disks get handled. Don't build it in blind.
- **pog is OUT on physical grounds** — an SFF desktop doesn't fit an enclosure
  specced around laptops. Settles the liability question without needing an
  opinion about Ivy Bridge.
- Powered hub for the tether still applies and should be sited in the rack.
