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
  utility meters. **Two claims in the first draft were wrong and are corrected
  below — don't cite this entry without them:**
  - "No Thread border router" — **wrong.** The three **Google Nest Hubs are
    Thread border routers**; only the Home Minis / Google Home are not. Thread
    is available; what's missing is `thread_credentials_set` on the
    matter-server, which is why Matter-over-**Wi-Fi** is still the easy path.
  - "`docs/home-assistant.md`'s four Sonoff plugs is stale" — **wrong, and the
    correction was the error.** The Wi-Fi plugs are **real** (air shower fans +
    2 × lab lighting); they are deliberately outside HA per
    `docs/ecosystem-map.md`, so nothing derived from the HA registry can see
    them. Lesson: **HA's registry is not the estate** — an inventory built from
    it silently under-reports whatever bypasses HA by design.
  - `light.lights_east` wrapped **`switch.tumble_dryer`**, not the Matter plug
    and not a Sonoff. See the laundry entry below — it was a live fault, now
    fixed.
  `docs/hardware-inventory.md` carries a scope caveat and the Wi-Fi plugs; the
  "four Sonoff plugs" table in `docs/home-assistant.md` is still uncorrected.

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

- **Laundry plugs are MEASURE-ONLY — three unwanted power-control paths closed
  (2026-08-10).** The S60ZBTPG plugs exist to detect the end-of-cycle power
  drop; they must never switch the appliance. Peter's symptom was the opposite
  of what was first diagnosed: it wasn't "the plug fails to come back", it was
  **unwanted switching happening at all** (so far only between washes; mid-wash
  would kill a load). Three live paths, now all shut:
  1. `light.lights_east` — a `switch_as_x` helper wrapping
     `switch.tumble_dryer` and exposing it in the **light** domain, so Google
     "turn off the east light" cut the dryer's mains. **Helper deleted.**
     This also explains the "unreliable Zigbee plug" — the plug was innocent.
  2. **Status dashboard tiles** bound to the *switch* entities are tappable,
     so a mis-tap cut mains — the only path that could reach the **washing
     machine**. Now read-only power tiles (`tap_action: none`), fixed in
     **ansible** (`8594d5f`, the dashboard is templated).
  3. Dryer `start_up_behaviour` was **Off** (washing machine was On), so any
     stray off *persisted* across a mains blip. Set to **On** — a safety net,
     not the fix.
  Design change: both `*_finished` automations now have `conditions: []` (was
  gated on the switch being on), so the power drop alone fires the
  announcement and **the plug never needs switching to arm a wash**.
  `automations.yaml` is **UI-managed, not in git** — changed in place on
  homepi, backed up to `automations.yaml.bak-20260810-085506`.

- **Voice control: decided NOT to bridge HA↔Google (2026-08-09).** Verified no
  `google_assistant` and no `cloud` integration exists, and
  `homeassistant.exposed_entities` is `{"assistants": {}}` — **zero HA
  entities reach any assistant.** That is the design, not a fault. Google Home
  owns voice (the three Wi-Fi plugs publish via Smart Life/eWeLink, bypassing
  HA); HA owns logic, history and alerting. Nabu Casa (~£6.50/mo) and the
  manual GCP/OAuth route both cost more than the usage justifies. Written up in
  `docs/integration-policy.md`, which also answers the old `TODO.md` question
  and "why are the fans reliable when everything else barfs" (chain length).

- **Third S60ZBTPG paired as `Canon EOS Power` (2026-08-12) — intended as the
  Zigbee EOS power path, NOT yet wired to anything.** Joined ZHA at 09:32:51Z
  (5 → 6 devices) by permit-join; no setup code involved. The QR on the plug
  body decodes to `25502200004022` — a **plain serial, not a Matter payload**;
  a body QR is not by itself evidence of Matter. Verified reporting mains while
  powered (235.92 V). `start_up_behaviour` set to **On** so the EOS returns
  after a power cut (factory default is Off — the same trap fixed on the dryer
  2026-08-10). Device **and all 8 entity IDs** renamed to `canon_eos_power_*`:
  they land as `sonoff_s60zbtpg_*_2` on join, and a `_2` collision suffix is a
  bad stable identifier — rename entity IDs, not just the device, since the
  device rename only changes *friendly* names. The dryer's 7 entities keep the
  generic `sonoff_s60zbtpg_*` names (untouched, verified live after the rename).
  Currently reads `off` / 0.0 V because it is unplugged from the test socket —
  that is a de-energised plug holding last-known state, not a fault; the
  timestamps (09:33:28Z, minutes before any rename) rule out a self-switch.

- **Lab lighting buttons → use Matter, not Zigbee (decided 2026-08-09, not yet
  bought).** Peter wants a physical button for the lab late at night *and*
  keeps voice. Zigbee would pull lab lighting into HA and **lose** its Google
  voice; a Matter plug joins Google Home **and** HA simultaneously
  (multi-admin), giving both with no bridge. Buy **Matter-over-Wi-Fi**, not
  Thread: `thread_credentials_set` is `False`, whereas Wi-Fi Matter works today
  (node 7 proves it). Three Nest Hubs are Thread border routers if that changes.
  NB the Home Minis / Google Home are **not** border routers — only the Hubs.

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

- **`eos-power` has no ZHA backend — `Canon EOS Power` is unreachable by it.**
  `eos-power` drives the **matter-server WS API** and matches `MATTER_VENDOR =
  "Realwe"`; the new plug is **ZHA**, a different backend entirely (HA REST/WS,
  `switch.canon_eos_power`). Making it usable is a second code path in
  `astro/bin/eos-power`, not an id change — work for [[astro-canon]], whose
  repo owns that tool. **Keep the Realwe Matter plug as the live EOS path until
  the ZHA route is proven end-to-end**; a fresh pairing is not evidence.
  The prize: the plug's **wattage sensor verifies a power cut directly** (watch
  draw fall to ~0 and return), replacing `cycle`'s USB-renumeration proxy and
  retiring the exit-code-3 "plug lied" guesswork — that check exists only
  because the Sandstrom ACKed without switching. Measuring the rail beats
  inferring it downstream.

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
