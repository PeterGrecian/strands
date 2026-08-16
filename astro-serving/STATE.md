# astro-serving — state

*Curated summary of where this strand is. Updated at the end of each session.*

**Status: design sketch, nothing built.** Originated 2026-08-15 from the Drive
document `cld-strand-astro-serving.md`; strand scaffolded 2026-08-16. The
design below is transcribed from that document — **this file is now the source
of truth**, the Drive copy is historical.

## What exists

Nothing is built. What exists is a design with two decided principles, one
open question, and one undecided topology.

### The core decision — server renders, client displays

The server renders; the client only ever receives display-ready 8-bit images.
Forced by a hard constraint (a tablet cannot decode 16-bit FITS or hold a
working set), but right regardless: frames stay where the storage and
processing are, and the display device holds only a decode buffer plus a few
seconds of lookahead — **4–8 GB, not 16**.

Consequence: reviewing long sequences stops being limited by the display
machine. Hundreds of frames stay resident server-side and scrub instantly.
Prefetch ahead of the playhead and it feels local.

### Two boxes: nit and tin

Splitting processing from serving is cleaner than one large build, and DDR4 is
cheap enough that two boxes may cost less than one 64 GB machine.

| | Role | Character |
|---|---|---|
| **nit** | processing | RAM-hungry, bursty, hot, noisy. Eventually wants 64 GB. Put it where noise doesn't matter. |
| **tin** | serving | Holds frame sets resident, serves browsers, always on. Modest CPU, wants to be quiet and low-power. |

The real gain: **the processing box can be rebooted, reconfigured or taken
apart mid-project without killing the ability to review sequences.**

*(The machines themselves belong to `hardware` — see Pending.)*

### API sketch

```
GET  /seq                     → list of sequences
GET  /seq/{id}                → manifest: frame count, timestamps,
                                calibration version, available scales
GET  /seq/{id}/frame/{n}      ?scale=1|2|4 &stretch=asinh&black=…
                              → WebP/AVIF, server-side stretch applied
GET  /seq/{id}/strip          ?from=&to=&scale=8  → contact sheet
WS   /splay                   → probe state, layout intent, playhead
```

## Pending / loose ends

1. **OPEN QUESTION — does scrubbing mean "request frame n", or "subscribe to a
   playhead and let the server push"?** Request/response is simpler and
   survives flaky WiFi; push is what makes splay's coordination across multiple
   display heads work properly. Probably both eventually — request/response as
   the primitive, push as a layer over it. **Decide before writing code**,
   because it shapes the WebSocket protocol. *(See Decisions: the client-
   heterogeneity analysis is not neutral on this.)*
2. **UNDECIDED — storage topology.** Does each box hold its own copy, or does
   tin mount from nit / from the NAS? **The NAS build likely answers this**,
   and may make tin much thinner than currently imagined. Blocks speccing tin.
3. **Measure before building any adaptive-bandwidth layer.** Once a serving box
   exists: fetch a strip at each scale from (a) phone on WiFi, (b) phone on 4G,
   (c) laptop on ethernet; record achieved frames/sec. Likely outcome is that
   at `scale=4` or `8` the phone case is comfortably fine and the whole
   adaptive layer is unnecessary complexity. Don't build it on estimates.
4. **Hardware prerequisites are owned by `hardware`**, spooled there 2026-08-15:
   nit's 64 GB ceiling (verify it's reachable on AM4/DDR4 — check DIMM count
   and max per slot), tin's build (spec *after* the NAS decision), and **NAS
   parity**, which the design assumes but the fleet does not yet have. Sequence
   there: NAS parity → tin → nit RAM.

## Decisions

- **Stretch is a request parameter, not baked in.** Client sends display
  parameters; server applies them to the 16-bit source and returns 8-bit. Keeps
  the linear data authoritative, and lets black point be scrubbed from a tablet
  without shipping raw frames anywhere.
- **The manifest is a view over the existing index**, generated from the
  per-frame Parquet and the versioned YAML calibration records. **Not a second
  source of truth.** Calibration version goes in the manifest so a client can
  tell when it is looking at stale renders.
- **Redundancy is scoped to captured frames only.** The one thing that
  genuinely cannot be lost is the **captured frames**; everything downstream is
  reproducible as long as the pipeline is in git. So the raw archive lives on
  the NAS with real parity, and nit and tin hold working sets they can rebuild
  — neither needs its own redundant copy.
  **⚠ The premise is not yet true:** today the raw archive is bigstore, a
  single SMART-blind copy behind a Seagate bridge that blocks ATA pass-through.
  The most irreplaceable link is currently the least protected. See
  [[redundancy-not-capacity]] and [[seagate-expansion-blocks-sat]].
- **For the service itself, "redundancy" means *boring to redeploy*, not
  clustered.** If tin can be brought up from a git clone plus a mount in ten
  minutes, that is sufficient at this scale.
- **Serve to the VIEWPORT, not to the client "type" (2026-08-16).** Because the
  server renders, bandwidth adaptation is a server-side *parameter* change, not
  a client-capability problem — every client speaks the same API and just asks
  for different numbers. Client sends display size + DPR; server picks the scale
  that covers it. That is not adaptive logic, it is declining to send pixels
  nobody can see, and it removes most of the phone-vs-laptop gap before
  anything clever happens.
  - **The hard case is scrubbing, not steady-state viewing.** Any pipe delivers
    one frame eventually; sustained scrub bitrate is where a phone on flaky
    WiFi diverges from a laptop on ethernet.
  - **Decouple scrub resolution from settled resolution.** While the playhead
    moves, serve small/cheap frames; when it stops ~150 ms, serve full quality
    for that one position (how every NLE solves this). A slow client then
    degrades in scrub *fidelity* — softer while moving — not in smoothness,
    which is the right thing to sacrifice. Note `/seq/{id}/strip?scale=8` is
    already a bulk low-res fetch: **scrub may just be the strip endpoint
    reused.**
  - **⚠ This is an argument for PUSH, so open question 1 is not neutral.**
    Under request/response a slow client's requests *queue* and it falls behind
    the playhead — unbounded latency, the worst failure mode. Under push the
    server knows the client's real drain rate and can skip frames to stay
    current, like a video stream. Minimum viable alternative: request/response
    plus an explicit "cancel outstanding, I've moved on" primitive, so a phone
    never renders frames the user has already scrubbed past.
  - **The serving box wants to be on the WIRED side of the house**, near the
    bytes. Carried from `hardware`: pip is a WiFi *interface*, not a compute
    node (4.9 vs 34 MB/s measured). No amount of client-side adaptation fixes a
    server that is itself behind a slow radio link. See
    [[compute-follows-the-data]].
- **This strand supersedes the image-sequence parts of `mywebsite`.**
