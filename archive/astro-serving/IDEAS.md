# astro-serving — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->

Heterogeneous clients (phone / laptop / varying bandwidth) — mostly falls out of
server-side render, but sharpens the push-vs-request open question

Context: cld-strand-astro-serving.md (Drive, 2026-08-15), the design sketch this
strand comes from.

Because the server renders and clients only receive 8-bit display-ready images,
bandwidth adaptation is a server-side PARAMETER change, not a client capability
problem. Every client speaks the same API and just asks for different numbers.
The knobs already exist in the API sketch: scale=1|2|4, stretch/black, codec.

First-order answer: serve to the VIEWPORT, not to the client "type". Client
sends display size + DPR; server picks the scale that covers it. Not adaptive
logic — just not sending pixels nobody can see. Removes most of the phone-vs-
laptop gap before anything clever happens.

Steady-state viewing of one frame is easy on any pipe. The hard case is the
thing this strand exists FOR: scrubbing hundreds of frames and having it feel
local. That is sustained bitrate, and it is where a phone on flaky WiFi diverges
from a laptop on ethernet. Two structural moves:

1. Decouple scrub resolution from settled resolution. While the playhead moves,
   serve small/cheap frames; when it stops ~150ms, serve full quality for that
   one position. How every NLE solves this. A slow client then degrades in scrub
   FIDELITY (softer while moving), not in smoothness — the right thing to
   sacrifice. Note /seq/{id}/strip?scale=8 is already a bulk low-res fetch, i.e.
   already most of what a scrub needs; scrub may be the strip endpoint reused.

2. Let the server DROP frames rather than let requests queue. This bears
   directly on the doc's stated open question. Under request/response a slow
   client's requests queue and it falls behind the playhead — unbounded latency,
   the worst failure mode. Under push the server knows the client's real drain
   rate and can skip to stay current, like a video stream. So heterogeneous
   clients are an ARGUMENT FOR PUSH, or at minimum for request/response plus an
   explicit "cancel outstanding, I've moved on" primitive so a phone never
   renders frames the user has already scrubbed past. The open question is not
   neutral on bandwidth.

Before building any adaptive-bitrate machinery, MEASURE: once a serving box
exists, fetch a strip at each scale from (a) phone on WiFi, (b) phone on 4G,
(c) laptop on ethernet, and record achieved frames/sec. Likely outcome is that
at scale=4 or 8 the phone is comfortably fine and the whole adaptive layer is
unnecessary complexity. Don't build it on estimates.

Constraint carried over from the hardware strand: pip is a WiFi INTERFACE, not
a compute node (4.9 vs 34 MB/s measured). Same lesson applies — the serving box
wants to be on the WIRED side of the house, near the bytes. No amount of client
adaptation fixes a server behind a slow radio link.

Related hardware-strand ideas spooled 2026-08-15: nit RAM ceiling, tin build,
NAS parity as prerequisite.

