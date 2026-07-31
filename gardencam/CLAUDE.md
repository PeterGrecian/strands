# Strand: gardencam

## Mission

Own the **gardencam / skycam** lifecycle — the garden/sky camera pipeline whose
**final product is the encoded video (hourly mp4 → S3 → YouTube)**, NOT the raw
frames. Spans `Berrylands/gardencam` (the processor + tooling), puppy (capture +
encode host), S3 (`gardencam-berrylands-eu-west-1`), and YouTube.

Core principle (Peter, 2026-07-31): **skycam raw jpgs are DISPOSABLE** — once the
deliverable (mp4/YouTube) exists, the raw is scratch. This is the opposite of the
**astro-storage** strand's keep-forever squashed-pyramid model, which is why this
is its own strand despite both being "camera storage."

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
