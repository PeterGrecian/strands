---
name: astrocam-plate-scale-unsolved
description: astrocam's imx708 plate scale is genuinely unsolved, and Polaris cannot solve it — use a far star for the pole
metadata:
  type: project
---

As of 2026-08-21 astrocam's imx708 plate scale is **not established**. Best
measurement is **0.0186 ± 0.0010 °/px full-res** (joint fit, 111 Polaris
positions, 14 nights), which is consistent with *both* the estate's legacy
0.02081 and the imx708 spec 0.01690. Any single night appearing to confirm one
to a few percent is over-reading its own noise.

**Why:** Polaris's arc is only ~16 px radius at half-res and sags ~6 px from a
straight chord. Curvature carries the radius, so ~1.5 px of detection scatter
becomes ~25% on the radius. This is geometry, not technique — and it is *not*
saturation (per-frame peaks ~440 of 1023 ADU).

**How to actually solve it:** fix the pole with a star FAR from it (Kochab, arc
radius ~470 px) — the centre of rotation does not require knowing which star it
is, so no identification is needed for that half — then measure Polaris's radius
from that solid centre.

**Why to apply it:** anything that projects to the sky (HTM anchoring, the
accumulator's map) inherits this scale, and resampling error bakes in
permanently. Do not let 0.0208 pass as verified because it appeared once.

Related: [[pip-astro-environment]]
