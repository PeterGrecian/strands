# Strand: astro-polecam

**Keeps the pole-pointing camera capturing — the v3-standard (imx708) on
astrocam: setup, focus, calibration and processing topology.**

The camera **keeper** for the pole-pointing instrument: a Pi Camera v3 standard
(imx708) that replaced the v2 imx219, mounted looking at the celestial pole
(Polaris dead-centre — the radial-breathing ⊥ tangential-drift geometry the
science relies on *is* this camera's identity). This strand owns its day-to-day
operation: focus (settled ~1.4), pedestal (105), rotation, the night gate/daemon,
and the still-open processing-topology question. The *science* it feeds (the
sidereal accumulator, sub-pixel theory) lives in [[astro-science]]; storage in
[[astro-storage]]. Spans `~/astro` (capture/config) and the astrocam host.

**Note — renamed from `astro-v3s` 2026-08-02** (the strand was named for the
project phase; it's really this camera's keeper). The **device** is still named
`astrocam` everywhere (hostname, S3 bucket, camera.json, systemd units,
cdf/resolve-host/ssp) — the `astrocam → polecam` device rename is a separate,
heavier task (grep the estate for "astrocam" first; it touches live capture).
See STATE for that pending item.

## Session ritual

1. Import spooled ideas with `idea --import`, then read
   `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
