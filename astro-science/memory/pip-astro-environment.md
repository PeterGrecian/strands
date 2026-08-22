---
name: pip-astro-environment
description: How to run astro code on pip — the venv, and the SMB share's 2 MB/s read speed that decides muppet vs pip
metadata:
  type: project
---

On **pip**, `~/astro/.venv` did not exist until 2026-08-21 (created from
`requirements.txt`); before that any astro tool needing scipy/astropy/matplotlib
could only run on muppet, which is why work kept migrating there. The venv is
also what lets `splay` open FITS on pip — without astropy it silently cannot.

`~/bigstore-astro` is a **symlink to an SMB mount** of the astro data
(`/mnt/shared/SMB/<hash>`), not a local disk. Measured read speed **~2 MB/s**.

**How that decides where work runs:** night products (`max.jpg`, `max/sum.fits.fz`,
a few MB each) are fine to read on pip. Per-frame passes are not — one astrocam
night is ~430 frames × 10 MB ≈ 2 GB ≈ 17 min of read. Measured: 14 nights × 10
frames took 3.5 minutes. So geometry/calibration work on night products runs on
pip; anything touching many raw frames belongs on muppet, or copy the one night
across first.

Related: [[astrocam-plate-scale-unsolved]]
