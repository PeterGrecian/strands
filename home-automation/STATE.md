# home-automation — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **Matter commissioning works headlessly via the matter-server WS API**
  (no phone app, no HA browser UI). HA + `python-matter-server` both run as
  docker containers on **homepi**; the matter-server exposes a WebSocket API on
  `ws://homepi.local:5580/ws` (`get_nodes`, `set_wifi_credentials`,
  `commission_with_code`, `device_command`). Commission a Wi-Fi Matter device
  with: (1) `set_wifi_credentials {ssid, credentials}`, (2)
  `commission_with_code {code: "MT:…", network_only: False}` while the device is
  BLE-advertising (hold button → blink) within Bluetooth range of homepi.

- **BLE on homepi — required setup (was NOT in place; now fixed).** For
  `commission_with_code` to do BLE at all, the matter-server container needs:
  `--security-opt apparmor=unconfined`, `-v /run/dbus:/run/dbus:ro`,
  `--network=host`, **and the `--bluetooth-adapter 0` command argument** (this
  last was the missing piece — without it the API returns "Bluetooth
  commissioning is not available"). Also `hci0` must be UP (`sudo hciconfig
  hci0 up`). The container was recreated by hand with these on 2026-07-26; data
  bind `/opt/matter-server/data:/data` preserved the fabric.
  **NOT captured in IaC** — this container is a hand-run `docker run` (no
  ansible/compose); the BLE change lives only in the running container. See
  pending item below.

- **Current plug: Realwe Innovation Smart Plug, node 7** (SW 1.2.6, On/Off on
  endpoint 1), commissioned 2026-08-09, on Wi-Fi, off/on/cycle verified
  end-to-end through `eos-power`. Wi-Fi creds live in secrets
  (`/wifi/lab-ssid`, `/wifi/lab-psk`) and are reused by `set_wifi_credentials`.

- **Retired: Currys Sandstrom Wi-Fi Smart Plug, node 4** (commissioned
  2026-07-26). Proved **unreliable** and was physically discarded 2026-08-09.
  Its fabric entry is deliberately **left in place** as a ghost
  (`available: False`) — harmless, removable later.

- **Hardware inventory** — `home-automation/docs/hardware-inventory.md`
  (2026-08-09). Every physical device in the estate, built from the live HA
  device registry (34 devices), the matter-server API and `lsusb`, not from
  memory. Surfaced kit this STATE never recorded: the **Sonoff ZBDongle-E
  Zigbee coordinator** on `ttyUSB0` (4 ZHA devices — 2 appliance plugs, 2
  temp/humidity sensors), 13 Cast endpoints, the eero, and the Octopus-linked
  utility meters. Also notes **no Thread border router** exists, so Matter kit
  must be Wi-Fi. Flags that `docs/home-assistant.md`'s "four Sonoff plugs" is
  **stale** — only the two Zigbee plugs exist; `light.lights_east` is a
  `switch_as_x` helper over the *Matter* plug, not a Sonoff. That older doc is
  left uncorrected on purpose; fixing it properly is a separate call.

- **`eos-power cycle` now VERIFIES the rail dropped** (Peter, 2026-08-09,
  commit `a778bfd` in `astro`). Smart plugs here have proved unreliable enough
  that an ACK is not evidence: the plug can confirm the command without
  switching mains, which is indistinguishable from a camera wedge. `cycle`
  watches the EOS's USB device number — a genuine power cut forces
  re-enumeration with a new Dev. Exit codes: `0` verified, `2` plug
  unreachable, `3` **plug lied** (ACKed, Dev unchanged — suspect the plug), `4`
  camera never came back. This is the direct answer to the "was it the plug or
  the camera?" ambiguity that the unreliable Sandstrom created.

- **Plug lookup is by vendor, not node id** (`eos-power`, 2026-08-09).
  Replacing a plug renumbers it, so `MATTER_VENDOR = "Realwe"` matches
  `0/40/1` and `MATTER_NODE = 7` is only a fallback. Match on **vendor**, not
  product: the node-4 ghost is also called "…Smart Plug", so a product-name
  match hits both. Reachable candidates are preferred over ghosts.

- **Commissioning gotchas (both cost time on 2026-08-09):**
  - A **wrong/stale setup code fails in ~4ms** with a bare "Commission with
    code failed for node N" and *no* BLE activity in the log — that is code
    rejection (checksum), not a radio problem. A genuine BLE attempt takes
    tens of seconds. Each try burns a node id (5, 6 wasted this way).
  - `_matterc._udp` staying **empty is not diagnostic** for a factory-fresh
    plug: with no Wi-Fi yet it advertises over **BLE only**, which is what
    matter-server uses anyway.
  - `homepi.local` mDNS resolution intermittently fails from pip
    (`gaierror -2`); use the IP (`192.168.0.53`) for commissioning runs.

## Pending / loose ends

- **Remote power-cycle for the astro-canon EOS dummy battery** — **DONE
  (build) 2026-07-26 via option (b); plug swapped 2026-08-09.** The Matter plug
  (now **node 7**, Realwe) switches mains to the DR-E10 adapter;
  `astro/bin/eos-power` `_relay_set()` drives it over the matter-server WS API.
  off/on/cycle re-verified against the new plug 2026-08-09.
  Coordinated with [[astro-canon]] (its STATE `eos-power` entry updated; MAILBOX
  notified). **Remaining: confirm the reset actually clears a real Class-B wedge
  on the next wedge** — whole-adapter mains switching may not drop the 12V rail
  as cleanly/quickly as the 12V-only pull STATE validated (PSU bulk caps); may
  need `--secs` > 10. Tracked in astro-canon STATE (CAVEAT).

- **Capture homepi's matter-server container in IaC** — **owned by
  [[astro-canon]]** (2026-07-26). The matter-server is a hand-run `docker run`
  (April, no ansible/compose); the BLE fix lives only in the running container.
  Astro-canon owns this because its reset path (eos-power → the plug →
  matter-server) is the load-bearing dependency that a homepi reprovision would
  break — see astro-canon STATE. home-automation keeps this pointer only.

- **New `electronics` repo + strand** — DONE 2026-07-23. Created `~/electronics`
  (`PeterGrecian/electronics`, private) + the [[electronics]] strand, sitting
  *between* home-automation and hardware: circuits Peter builds to interface
  things (schematics + design discussion). The astro PWM-for-speakers /
  pwmaudio driver work is slated to migrate there. See the electronics strand
  STATE for the plan; [[astro-speaker-dither]] cross-links it.

## Decisions
