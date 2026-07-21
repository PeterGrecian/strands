# Strand: usb-hid-keyboard

## Mission

Build and maintain a **USB HID keyboard-emulation rig** — a small Linux board
(Pi Zero / Zero 2 W, or Pi 4 via its USB-C OTG port) configured as a **USB
gadget** that presents itself to a *target* machine as an ordinary USB keyboard
(and optionally mouse/mass-storage), so we can **type into a machine we cannot
otherwise drive**: dead/half-dead screens, no-network boxes, firmware/BIOS
menus, boot loaders, recovery consoles — anywhere a real keyboard is the only
input the target trusts.

**Origin (2026-07-19):** the [[hardware]] strand's `vole` job (Acer C720 →
Debian, the aifabric-sessions x86 tiebreaker) stalled hard because vole's HDMI
screen has a **dead half** and its ChromeOS dev shell wouldn't reliably start an
inbound sshd — so we could neither *see* MrChromebox's menu nor *drive* it
remotely. A device that just **types the keystrokes** sidesteps both: it needs
no cooperation from the target's OS and no working display on our side (we send
a fixed keystroke script). pip itself can't do this — a normal laptop USB-A
port is a *host*, not a *gadget*; you need OTG/gadget-capable hardware.

## Why a Pi (not pip)

USB HID emulation requires the controller to act as a USB **device/gadget**,
which needs a UDC (USB Device Controller). Regular PCs/laptops (incl. pip) only
have host ports. Gadget-capable options in the fleet:
- **Pi Zero / Zero 2 W** — micro-USB "USB" port is OTG; ideal, cheap, tiny.
- **Pi 4 / Pi 5** — the USB-C *power* port doubles as OTG (dwc2), usable.
- deskpi/older Pis via ethernet-only — no OTG on the type-A ports; not suitable.
Also off-the-shelf: a Digispark/RP2040/"Rubber Ducky" can do HID, but a Pi gives
us a full Linux brain (scripting, ssh-in to compose keystrokes, screen-blind
retries), which is the point.

## The build (sketch — flesh out as we go)

1. `dtoverlay=dwc2` in config.txt + `dwc2` module → gadget mode on boot.
2. `libcomposite` + a configfs script (or `modprobe g_hid` legacy) to expose an
   **HID keyboard descriptor** as `/dev/hidg0`.
3. A `type-string` helper: ASCII/keysym → HID usage-code reports written to
   `/dev/hidg0` (with modifier bytes, key-up frames, inter-key delay).
4. Cable: Pi's OTG port → target's USB-A. Target sees a plain keyboard.
5. Drive it: ssh into the Pi over its network, run `type-string "..."`, or feed
   a whole keystroke script (e.g. "wait, ctrl-alt-f2, type creds, run flasher").

## In scope
The rig itself: gadget config, HID descriptor, the `type-string`/scripting
layer, mouse/mass-storage add-ons, a house tool (`super/bin`?) once it works,
and codifying it (ansible role on the chosen Pi) so it survives a reflash.

## Out of scope
The *targets* we drive with it (vole belongs to [[hardware]]; a given flash job
belongs to its own strand). This strand owns the **input appliance**, not what
we type into.

## Repos it spans
`ansible` (a `usb-hid-gadget` role on the chosen Pi), `super` (this dir, any
house tool + memory). Physical wiring notes live here in STATE.md.

## Session ritual
1. Read STATE.md + IDEAS.md.
2. Triage ideas with Peter.
3. Work; commits go to the repo the change belongs to.
4. On `dcp`: update STATE.md — build progress, wiring, what works, blockers.
