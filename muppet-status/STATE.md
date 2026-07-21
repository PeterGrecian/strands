# muppet-status — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **2026-07-12 puppy dongle swap** (session started as "muppet" by mistake — target was puppy). Old SZNX 100M dongle (CDC dmesg spam) replaced; puppy back at static 192.168.0.11, cloudcam NFS writes recovered, empty thumb drive removed.
- NM profile "Wired connection 1" is now **interface-agnostic** (interface-name binding cleared) — future dongle swaps come up at .11 with no reconfig.
- Detail lives in memory: `project_puppy_network.md`, `project_muppet_hardware.md`.

## Pending / loose ends

- The replacement "gigabit" UGREEN is actually RTL8152 10/100 (USB2). **Seller messaged for return** — awaiting response. Evidence: lsusb `0bda:8152` + ethtool PHY modes.
- When a real gigabit dongle arrives: plug into puppy's USB3-A port, re-check link, then `iperf3` puppy→muppet to test switch port and path together. Peter recalls the switch port is gigabit (the 10/100 link-partner reading from a 100M PHY is not evidence against it).

## Decisions

- Strand mission still unwritten in CLAUDE.md.
