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

- **First plug commissioned (2026-07-26):** Currys Sandstrom Wi-Fi Smart Plug
  (VendorID 5470 / ProductID 9217, SW V1.0.0.5), **node 4** on the fabric,
  on Wi-Fi, On/Off cluster verified end-to-end. Wi-Fi creds saved to secrets
  (`/wifi/lab-ssid`, `/wifi/lab-psk`) for reuse by future Matter devices.

## Pending / loose ends

- **Remote power-cycle for the astro-canon EOS dummy battery** — **DONE
  (build) 2026-07-26 via option (b).** The Matter plug (node 4) switches mains
  to the DR-E10 adapter; `astro/bin/eos-power` `_relay_set()` now drives it over
  the matter-server WS API. off/on/cycle/status all verified against the plug.
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
