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

- **astro-canon WIRED THE PLUG IN AS THE LIVE EOS PATH — settled, no fault
  (2026-08-12, astro `c6cae82` + `4f18f3b`).** `eos-power` defaults
  `PLUG_BACKEND='zha'`, deployed to muppet; it reads **no watts** at all now.
  **No verdict was ever at risk**: the advisory wattage block was gated on
  `w_before > 0.5`, which a 200 mW camera never satisfies, so it was dead code,
  not a live false-pass — removed anyway lest it imply watts were usable.
  Dev-number **re-enumeration remains the verification of record** (it proves
  the *camera* lost power, not merely that a socket went dead). Realwe fallback
  confirmed live: matter-server node 7 `available=True`, cleanly distinct from
  the node-4 Currys ghost; `PLUG_BACKEND='matter'` is a one-line revert.
  **Proven on the real load 2026-08-12** (not a bench socket): the DR-E10
  dummy-battery adapter moved onto this plug, and a live `eos-power cycle`
  returned **rc=0 with a genuine re-enumeration, Dev 064 → 065** — mains cut,
  12 V rail dropped, camera returned; `gphoto2 --summary` then answered Canon
  EOS 2000D at 480M. **The switch half — the half we rely on — is verified
  end-to-end on hardware.**
  **Two corrections to my own alarm** (recorded because the reasoning error is
  the reusable part): (1) I called this an inversion of my "Realwe remains the
  live path" note — but the swap was **Peter's instruction**, not astro-canon
  freelancing; a mailbox note from this strand does not out-rank the user, and
  I had no standing to impose that constraint. (2) `eos-power` only ever needed
  the plug as a **switch** (verified good, `start_up_behaviour=On`); the
  metering was a hoped-for bonus, never load-bearing — so the retraction cost
  nothing. Lesson that survives: state the *disqualifying* condition up front,
  not the prize — my message pitched wattage verification and the ~200 mW fact
  arrived after they had shipped.

- **Entity-name collision — FIXED 2026-08-12 by renaming the dryer.** The
  footgun (flagged by [[astro-canon]]): `sensor.sonoff_s60zbtpg_*` was the
  **TUMBLE DRYER**, same model as the Canon plug, so **anything matching that
  model by *name* rather than entity id would have switched the dryer** — same
  shape as the `light.lights_east` fault and the node-4 Sandstrom ghost. All 7
  dryer entities renamed `sonoff_s60zbtpg_*` → `tumble_dryer_*`; **all three
  S60ZBTPGs now carry appliance names, no model-name ids remain.**
  **Renaming entity ids does NOT update references** — that is the trap, since
  HA leaves them pointing at the old id and they silently stop working. Four
  sites swept: `automations.yaml` on homepi (dryer-finished trigger + the
  **coordinator watchdog**, both live alerting paths; UI-managed and not in git,
  so backed up to `automations.yaml.bak-20260812-103914`), the rendered
  `dashboards/status.yaml`, the ansible template that generates it
  (`42b8ab3`, `tap_action: none` preserved — the 2026-08-10 read-only guard),
  and `home-automation/docs/home-assistant.md` (`04343be`). Automations
  reloaded and verified `on`; sensors reporting live under the new ids; zero
  orphaned ids. Note the washing machine already had a clean
  `sensor.washing_machine_power` — only the dryer had been left generic.

- **~~`eos-power` has no ZHA backend~~ — superseded above; it has one now.**
  `eos-power` drives the **matter-server WS API** and matches `MATTER_VENDOR =
  "Realwe"`; the new plug is **ZHA**, a different backend entirely (HA REST/WS,
  `switch.canon_eos_power`). Making it usable is a second code path in
  `astro/bin/eos-power`, not an id change — work for [[astro-canon]], whose
  repo owns that tool. **Keep the Realwe Matter plug as the live EOS path until
  the ZHA route is proven end-to-end**; a fresh pairing is not evidence.
  ~~The prize: the plug's wattage sensor verifies a power cut directly.~~
  **RETRACTED 2026-08-12 — the EOS draws ~200 mW, far BELOW this plug's
  measurement floor.** At 240 V that is ~0.0008 A against a **0.01 A
  quantisation step** (~1/12th of one step; power quantises at 1 W, 5× the
  load), so a forced read returns **0.0 W with the camera running normally**.
  Wattage verification is **not usable for the EOS** and `cycle` must NOT gate
  on measured watts — doing so false-passes a cycle that never happened, or
  false-fails a healthy camera: the Sandstrom "plug lied" failure class
  reintroduced from the other end. **Keep the USB-renumeration check as the
  verification of record** — it works and costs nothing.
  All the encouraging bench numbers came from a **20–40 W glue gun**, not a
  camera load; that is the trap — a test load 100× the real one validated a
  scheme the real load cannot support. **As a switch the plug is fine** (relay
  verified over 3+ clean cycles with two loads cycling on the meter); it is
  only the *measurement* that cannot see an EOS.
  **CLOSED BY DECISION 2026-08-12 — Peter declined the ballast.** The mooted
  fix was a ~10 W resistive ballast in parallel on the switched side, to make
  the meter report on the *rail* rather than the camera (~£2/month continuous
  + heat, against a free USB proxy that already works). Not being built, so
  **wattage is permanently unusable for the EOS** and `eos-power` reads none.
  Reopen only if a ballast is ever fitted.
  Confirmed from [[astro-canon]] with the camera **actually attached**: power
  reads **0.0 W with the EOS running normally**, and `summation_delivered` is
  still **0.0 kWh after a full power cycle** — so *energy accumulation is not a
  workaround either*; ~200 mW accrues too slowly to register. That closes the
  last "is it drawing?" proxy this plug could have offered.
  ~~Verification must FORCE a read via `homeassistant.update_entity`.~~
  **THAT WORKAROUND DOES NOT WORK** — measured by [[astro-canon]] 2026-08-12:
  `update_entity` returns **HTTP 200 without refreshing** (both `last_updated`
  and `last_reported` stayed frozen across two forced polls), and
  `sensor.canon_eos_power_voltage` sat at **238.02 V straight through a genuine
  off/on of its own relay** — the meter did not witness its own plug switching.
  **There is no on-demand freshness signal at idle: the metering cannot be
  polled.** Passive reporting is delta-driven and does work when a load moves
  (a spontaneous 22→21 W report was observed), but silence is then ambiguous
  between *rail down* and *nothing changed*, and nothing can disambiguate it.
  Two independent findings — this one, and the ~200 mW floor below — each kill
  wattage verification on their own.
  **Two wrong turns worth not repeating:** (1) a frozen `last_changed` was read
  as a broken/lying plug — it was a correctly-silent delta-driven sensor, and
  `off`-state samples were **stale values, not evidence of current flowing**;
  never verdict on a sample whose timestamp predates the command. (2) A ~2 W
  computer fan is **useless as a test load** — it sits under the reportable
  delta and at the 0.01 A quantisation floor, so everything reads as a fault.
  Test with a real load (a thermostatted glue gun at 20–40 W worked well; its
  cycling is visible in the trace). One genuine oddity, seen once and not
  reproduced: the switch entity read `off` while the relay was closed and only
  corrected after `update_entity` — so prefer measured watts over switch state
  regardless.

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
