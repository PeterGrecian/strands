# Strand: gardencam

## Mission

Own the **gardencam** camera lifecycle — a *generic* garden-camera pipeline.
Spans `Berrylands/gardencam` (the processor + tooling), puppy (capture + encode
host), S3 (`gardencam-berrylands-eu-west-1`), and YouTube.

### Two cameras, OPPOSITE storage models (Peter, 2026-07-31)

gardencam is generic; its two current uses have deliberately different storage:

- **skycam ('sky')** — cloud timelapse → **YouTube is the deliverable**. Raw jpgs
  are **DISPOSABLE** (scratch once encoded — see the incoming-cleanup tool). And
  **S3 is NOT wanted**: the S3 copy of skycam videos grows **∝ t²** for data that
  lives on YouTube and will never be read from S3 → **drop the S3 upload leg for
  skycam** (keep YouTube). ~114 GB already accumulated there (2026-07-31).
- **springcam ('garden')** — timelapse of spring arriving in the garden; a
  **project in itself**, the first real use of generic gardencam. Bounded, valued
  output → **S3 is appropriate**; its full-res stills in S3 are actively used
  (`combined_timelapse_lambda` composites sky-over-garden). **Keep S3 for
  springcam.**

So "is S3 needed?" is **per-camera**: yes springcam, no skycam. The S3-upload
toggle should default ON (protect springcam/others) and be turned OFF only for
skycam's service.

This whole strand is the opposite of the **astro-storage** strand's keep-forever
squashed-pyramid model, which is why it's separate despite both being "cameras."

### What this strand owns
- **Incoming cleanup** — bound the unbounded raw-frame growth on puppy
  (`~/skycam-frames`); delete per-hour raw once its mp4 encode exists.
- **The encode/publish pipeline's storage** — where processed mp4s live, and the
  open question of whether **S3 is even needed** now the deliverable is YouTube
  (see IDEAS; https://www.petergrecian.co.uk/gardencam/s3-stats).
- gardencam capture/processor health as it touches storage.

### NOT this strand
- **astro streams** (astrocam, eclipticam, starcam) — those are **astro-storage**,
  keep-forever squashed + bigstore-primary. gardencam data must NOT go to bigstore
  as a keep-forever copy; it's disposable. (astrocam capture *runs* from the
  gardencam repo for historical reasons, but its DATA lifecycle is astro-storage's.)

## Session ritual

1. Import spooled ideas with `idea --import`, then read
   `STATE.md` (current state, decisions) and `IDEAS.md` (inbox).
2. Triage new ideas with Peter: promote to STATE.md pending list, or drop.
   Delete triaged entries from IDEAS.md.
3. Work. Commits go to the repo the change belongs to — this strand dir
   holds only curation files.
4. Session end (or on `dcp`): update STATE.md — what changed, what's
   pending, decisions made. Keep it curated prose, not a log.
