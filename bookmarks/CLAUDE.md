# Strand: bookmarks

**Reorganises Peter's browser bookmarks — a short-lived tidy-up strand.**

Reorganise Peter's browser bookmarks — likely a short-lived strand (a few
sessions), retired when the reorganisation is done and stable.

## Hard rules

- **Back up before touching anything**: copy the live bookmark store(s) to
  `~/archives/bookmarks-YYYYMMDD/` before the first edit, every session that
  edits. Never `rm` — `trash` if something must go.
- **The browser must be CLOSED when editing store files directly.** Chrome
  rewrites its `Bookmarks` JSON on exit (open-browser edits are silently
  lost); Firefox holds `places.sqlite` locked/WAL. Prefer export → edit →
  import where the browser supports it.
- Taxonomy decisions (folder scheme, what got merged/culled) go in STATE.md —
  they're the durable product; the moves themselves are mechanical.

## Session ritual

1. Read STATE.md + IDEAS.md; triage.
2. Work in batches; verify in the browser after each import before continuing.
3. Session end / dcp: update STATE.md (taxonomy, progress, remaining).
