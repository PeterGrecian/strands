# usb-hid-keyboard — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **Nothing built yet** — strand created 2026-07-19, spun out of a real need
  during the [[hardware]] `vole` job (Acer C720 with a half-dead screen that
  couldn't be driven by screen-reading or inbound ssh). The idea: a Pi in USB
  gadget mode types keystrokes into an otherwise-undrivable target.

## Pending / next steps

- **Pick the board.** A **Pi Zero / Zero 2 W** is the natural pick (micro-USB
  OTG, tiny, cheap). Check the fleet/spares for a free Zero. Fallback: Pi 4/5
  via the USB-C power port (dwc2 OTG). Confirm what's actually spare.
- **First build milestone:** boot the Pi with `dtoverlay=dwc2`, expose a HID
  keyboard via configfs/libcomposite, get a `/dev/hidg0`, and successfully type
  a test string into pip (as the target) — proving the descriptor + report
  format before trusting it on a real flash job.
- **`type-string` helper:** map ASCII → HID usage codes (incl. shift modifier,
  key-up frames, configurable inter-key delay). This is the crux; get the
  keymap right once.
- **Codify:** once it works, an ansible `usb-hid-gadget` role on the chosen Pi
  so a reflash restores it; consider a `super/bin` house tool wrapper.

## Decisions

- **pip cannot be the emulator.** Laptop/PC USB-A ports are hosts, not gadgets —
  no UDC. Emulation needs OTG/gadget-capable hardware (Pi Zero/4/5, or a
  microcontroller). (2026-07-19)
- **Prefer a Pi over a bare microcontroller** (Digispark/RP2040): the Pi gives a
  full Linux brain — ssh in, compose/replay keystroke scripts, retry blind — not
  just a fixed canned payload. The value is a *driveable* keyboard appliance.

## Notes

- Cross-links: [[hardware]] (the strand whose broken-screen `vole` job motivated
  this). If this rig had existed, the C720 flash would have been a non-event.
