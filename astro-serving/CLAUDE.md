# Strand: astro-serving

**The server renders; the client only ever receives display-ready 8-bit
images.**

## Mission

Serve astro frame sequences to browsers — phones, tablets, laptops — by
rendering server-side and shipping 8-bit display-ready images, never raw
16-bit data. Frames live where the storage and the processing are; the
display device holds a decode buffer and a few seconds of lookahead.

This falls out of a hard constraint — a tablet cannot decode 16-bit FITS or
hold a working set — but it is the right design regardless. Reviewing long
sequences stops being limited by the display machine: hundreds of frames stay
resident server-side and scrub instantly.

**Two load-bearing principles, from the founding sketch:**

- **Stretch is a request parameter, not baked in.** The client sends display
  parameters; the server applies them to the 16-bit source and returns 8-bit.
  The linear data stays authoritative, and black point can be scrubbed from a
  tablet without shipping raw frames anywhere.
- **The manifest is a view over the existing index**, generated from the
  per-frame Parquet and the versioned YAML calibration records — not a second
  source of truth. Calibration version travels in the manifest so a client can
  tell when it is looking at stale renders.

**In scope:** the serving API (sequence list, manifest, frame render, contact
strip), the `/splay` WebSocket (probe state, layout intent, playhead), the
scrub protocol, client heterogeneity and bandwidth, and the render path from
16-bit source to delivered image.

**Out of scope:** capture and calibration (the astro capture/processing
strands), the physical machines this runs on (`hardware` owns nit, tin, and
the NAS), and splay's own display behaviour (`splay-*` strands) beyond the
protocol boundary between them.

**Supersedes** the image-sequence parts of `mywebsite`.

**Related strands:** `splay-*` (layout intent, the display end),
`astro-capture` / `astro-science` (what produces the frames),
`astro-storage` (where they live), `hardware` (nit, tin, NAS parity).

## Origin

Design sketch `cld-strand-astro-serving.md`, written 2026-08-15 (Google Docs).
**That document's content now lives in `STATE.md` here** — this git-backed
strand is the source of truth; the Drive copy is a historical artefact.

## Session ritual

1. Import spooled ideas with `idea --import`, then read
   `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
