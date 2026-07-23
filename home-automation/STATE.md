# home-automation — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- (new strand — nothing recorded yet)

## Pending / loose ends

- **Remote power-cycle for the astro-canon EOS dummy battery** (promoted
  2026-07-23). Give the tethered EOS 2000D a remotely switchable feed to its
  DR-E10 dummy battery, so a firmware-wedged camera (-110 I/O in progress,
  silently-rejected config writes) can be power-cycled without a human at
  muppet's desk. The dummy battery holds the USB device alive across the
  physical power switch, so dropping the feed for ~10 s is the *only* reset
  that forces a fresh 480M USB renegotiation. Two candidate builds:
  (a) Pico/ESP32 + MOSFET/relay in the ~9-12V DR-E10 line, exposing a trivial
  HTTP/serial "off N seconds then on" endpoint the astro-canon eos-* tools hit;
  (b) reuse the existing Zigbee/WiFi smart mains plug on the DR-E10 mains
  adapter (coarser, whole-adapter, no new hardware). Want: a documented
  off/on/cycle primitive the eos-* tools can call so a wedged camera
  self-recovers instead of paging Peter. See astro-canon STATE "Reset ladder"
  (Class B) for the failure it fixes.

- **New `electronics` repo + strand** — DONE 2026-07-23. Created `~/electronics`
  (`PeterGrecian/electronics`, private) + the [[electronics]] strand, sitting
  *between* home-automation and hardware: circuits Peter builds to interface
  things (schematics + design discussion). The astro PWM-for-speakers /
  pwmaudio driver work is slated to migrate there. See the electronics strand
  STATE for the plan; [[astro-speaker-dither]] cross-links it.

## Decisions
