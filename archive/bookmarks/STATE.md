# bookmarks — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

**Source**: Chrome only (`~/.config/google-chrome/Default/Bookmarks`). No Firefox
profile on pip. Chrome sync is ON for peter.grecian@gmail.com — so edits go via
**export → clean → import** (never touch the JSON while syncing), which sync then
propagates to all devices as a normal in-browser change.

**Archive + git** at `~/archives/bookmarks-20260719/` (local git repo, `History`
gitignored). Commits: initial snapshot → analysis → classifier+clean output.
Key files there:
- `Bookmarks` — pristine backup of the live store (885 KB, mtime 2026-07-19 16:11)
- `bookmarks.tsv` — every bookmark w/ added-date, last-visit, history visit-count
- `link-check.tsv` — liveness scan of 565 unique URLs (curl, follow-redirects)
- `classify.py` — the taxonomy engine (overrides + path-defaults + dead-rule)
- `decisions.tsv` — per-URL verdict (keep-folder or CULL:reason)
- `bookmarks-clean.html` — **the import file** (235 keeps, Netscape format)
- `culled.html` — the 340 culled, grouped by reason (recovery file)
- `review.html` — visual keep/cull review → artifact 6251ae2f-43fc-4194-8deb-088369f2543b

**Numbers**: 1078 bookmarks in Chrome → 575 unique URLs (503 were duplicates,
mostly a wholesale "Imported" mirror of the bar) → **235 keep / 340 cull**.

## Taxonomy (agreed 2026-07-19)

Flat, shallow, purpose-named. Bookmarks bar holds the daily-driver folders;
reference material lives under a single `ref/` tree in Other bookmarks.

**Bookmarks bar** (hot leftmost; emoji prefixes on every folder — Chrome has no
per-folder icons, emoji-in-name is the only lever and renders as text):
- `🔥 hot` — live dashboards & logins used now. **Sub-grouped by topic**, Claude first:
  `⭐ Claude` · `☁️ Cloud consoles` · `🌐 petergrecian.co.uk` · `📊 Sessions logs`
  · `🖥️ Fleet & home` · `📺 YouTube Studio` · `💬 Slack` · `👅 under my tongue` · `📎 Misc`
  (Chrome shows folders above loose links, so every hot item lives in a sub-folder — nothing dangles.)
- `🤖 ai` — AI chat tools (Claude, Grok, DeepSeek, Perplexity, Copilot…)
- `🏃 run` — 26.2 club, Strava, England Athletics, races
- `🎧 snd` — radio / BBC Sounds / music listening
- `💊 med` — NHS & medical portals
- `🏠 home` — household: banking, shopping, utilities, calendar, WhatsApp
- `👤 me` — Peter's own sites, CV, LinkedIn, courses
- `🎭 N` — culture / days out (current: LSO, City of London, weddings)

Sub-folder grouping + emoji live in `classify.py` (`HOT_GROUPS`, `HOT_ORDER`,
`BAR_EMOJI`, `HOT_SUB_EMOJI`) — re-run to regenerate the import file.

**Other bookmarks → `ref/`** (long-tail reference, rarely-clicked but worth keeping):
- `ref/dev`, `ref/electronics`, `ref/music-making`, `ref/science`,
  `ref/philosophy`, `ref/news`, `ref/walks`,
  `ref/esperanto` (+ `Groups`, `Resources` subfolders — the one deep folder kept intact)

### Cull rules applied
- **Dedupe**: prefer the non-Imported occurrence; drop the "Imported"/"Imported
  From Firefox" mirrors wholesale (20 kept as unique, rest were dups).
- **Dead links**: culled on 404/410/000/5xx from the liveness scan — EXCEPT
  LAN/localhost hosts (unreachable from sandbox ≠ gone) and file:// (checked on disk).
- **Repaired, not culled**: 6 dead URLs had an obvious live replacement
  (Langley Medical, muzaiko, meteoradar, heatsinkcalculator, github projects, CV → petergrecian.co.uk/cv).
- **Era cull**: pre-2018 loose "Other bookmarks" and old mobile-sync junk.
- **NSFW**: culled (Peter's instruction) — recoverable from `culled.html`/git only.
- **file:// missing**, **chrome://**/about: pages, saved Google searches, trivially
  retypeable (Wiktionary) — culled.

## Pending / loose ends

- **NEXT ACTION: import.** Everything is built and committed; the only thing left
  is for Peter to run the export→delete→import in Chrome (walkthrough below).
  Within-subfolder ordering is date-added, not importance — offer to hand-order
  (e.g. claude.ai/usage to top of ⭐ Claude) if he wants it after seeing it live.
- Waiting on Peter to review the artifact, then:
  1. Chrome → Bookmarks Manager → ⋮ → Export (extra safety copy).
  2. Delete all existing bookmarks in-browser (sync-safe).
  3. Import `bookmarks-clean.html`. Verify folders, then re-check on a second synced device.
  4. `me`/`N`/`hot` may want hand-tuning after Peter sees them in situ.
- Consider whether `hot` and `home` overlap too much (both have logins).
- **Open question from Peter (promoted 2026-07-23): is the sort using git?**
  He asked and didn't get an answer. Also wants to *see* the new
  `bookmarks-clean.html` before it's imported — i.e. review the generated
  file (or the artifact) first. Answer the git question and make sure the
  preview-before-import step is honoured.

## Decisions

- Chrome-only; export/import workflow (sync stays on).
- Scope = reorganise + dedupe + cull dead + cull era-obsolete + cull NSFW.
- Taxonomy proposed from the data (not dictated); Peter approved "build it".
- Archive under git for full recoverability of anything culled.
