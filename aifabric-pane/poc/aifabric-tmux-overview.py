#!/usr/bin/env python3
"""aifabric-pane OVERVIEW — `top`, but for strands.

A full-screen curses roster that refreshes in place like top: two header lines
(totals + cleft usage) and a table with one row per strand — its live/idle
state, session PID/TTY/uptime, and unread-mail count. LIVE strands and strands
with mail sort to the top. Press q or Ctrl-C to quit.

Why curses (replaces aifabric-tmux-overview.sh):
  The old shell loop did `clear` + full reprint AND re-ran `cleft` every 5 s.
  cleft() with no args hits the Anthropic OAuth usage endpoint with no caching,
  so a 5 s cadence = ~720 calls/hour and exhausted the frequency allowance
  (observed: `API error 429: Too Many Requests`). Curses lets us redraw by
  addressing the cursor (no flicker) and run independent cadences so the
  expensive fetch is rare:
        clock   every  1 s   (cheap, local)
        roster  every  5 s   (strand-ps + mail peek, all local)
        cleft   every CLEFT_EVERY s (default 300 s) — the API call
  with exponential back-off on 429 and the last good reading kept + shown as
  "(stale Nm)" rather than re-fetched or blanked.
"""
import curses
import subprocess
import time
import os
import re
import shutil
from datetime import datetime

STRANDS_ROOT = os.environ.get("STRANDS_DIR", "/home/peter/strands")
SM = shutil.which("strand-mailbox") or "/home/peter/aifabric/bin/strand-mailbox"
CLEFT = shutil.which("cleft")
STRAND_PS = shutil.which("strand-ps")

CLOCK_EVERY = 1
ROSTER_EVERY = int(os.environ.get("PANE_ROSTER_EVERY", "5"))
CLEFT_EVERY = int(os.environ.get("PANE_CLEFT_EVERY", "300"))
CLEFT_BACKOFF_MAX = 3600  # cap back-off at 1 h after repeated 429s

# strands to CHECK for mail (POC set; real version would scan all spools)
MAIL_WATCH = {"ansible", "housekeeping", "astro-storage", "astro-science",
              "aifabric", "ubersitrep", "rackinabox", "aifabric-pane"}


def _run(cmd, timeout):
    try:
        return subprocess.run(cmd, capture_output=True, text=True,
                              timeout=timeout).stdout
    except Exception:
        return ""


def all_strands():
    """Every strand dir (has a CLAUDE.md), sorted."""
    out = []
    skip = {".template", "archive"}
    try:
        for d in sorted(os.listdir(STRANDS_ROOT)):
            if d in skip or d.startswith("."):
                continue
            if os.path.isfile(os.path.join(STRANDS_ROOT, d, "CLAUDE.md")):
                out.append(d)
    except OSError:
        pass
    return out


def live_sessions():
    """strand -> (pid, tty, uptime) for the most-recent live session per strand."""
    sessions = {}
    if not STRAND_PS:
        return sessions
    out = _run([STRAND_PS], 5)
    for i, line in enumerate(out.splitlines()):
        if i == 0:
            continue
        p = line.split()
        if len(p) >= 5:
            pid, tty, uptime, strand = p[0], p[1], p[2], p[3]
            sessions.setdefault(strand, (pid, tty, uptime))
    return sessions


def mail_counts():
    counts = {}
    for s in MAIL_WATCH:
        out = _run([SM, "peek", s], 4)
        m = re.search(r":\s*(\d+)\s+pending", out)
        if m:
            counts[s] = int(m.group(1))
    return counts


def read_score(strand):
    """Peter's effectiveness score for a strand (1-5), or None. Cheap local file."""
    try:
        with open(os.path.join(STRANDS_ROOT, strand, "SCORE")) as f:
            return f.read().strip()
    except OSError:
        return None


def build_roster():
    strands = all_strands()
    sessions = live_sessions()
    mail = mail_counts()
    rows = []
    for s in strands:
        pid, tty, up = sessions.get(s, ("", "", ""))
        rows.append({
            "strand": s,
            "live": s in sessions,
            "pid": pid, "tty": tty, "up": up,
            "mail": mail.get(s, 0),
            "score": read_score(s),
        })
    # sort: live first, then strands with mail, then by mail count desc, then name
    rows.sort(key=lambda r: (not r["live"], r["mail"] == 0, -r["mail"], r["strand"]))
    return rows, len(sessions), sum(mail.values())


def fetch_cleft():
    if not CLEFT:
        return ("cleft: (not found)", False)
    out = _run([CLEFT], 15)
    if not out.strip():
        return ("cleft: (unavailable)", False)
    if "429" in out or "Too Many Requests" in out:
        return ("cleft: rate-limited (429)", False)
    used = _first(r"Used:\s*(\d+%)", out)
    rate = _first(r"Current rate:\s*([0-9.]+ %/hr)", out)
    warn = _first(r"(Quota runs out in [^\n—]*)", out)
    line = f"cleft 5h: {used or '?'} used · {rate or '?'}"
    return ((line, warn), True)


def _first(pat, text):
    m = re.search(pat, text)
    return m.group(1).strip() if m else None


def _addstr(win, y, x, s, attr=0):
    h, w = win.getmaxyx()
    if y >= h or x >= w or x < 0:
        return
    win.addstr(y, x, s[: max(0, w - x - 1)], attr)


def draw(win, state):
    win.erase()
    h, w = win.getmaxyx()
    bold = curses.A_BOLD
    cyan = curses.color_pair(1)
    yellow = curses.color_pair(2)
    red = curses.color_pair(3)
    green = curses.color_pair(4)
    dim = curses.A_DIM

    rows = state["rows"]
    nlive = state["nlive"]
    nmail = state["nmail"]
    total = len(rows)
    now = datetime.now()

    # header line 1: title + totals + clock (top-style summary)
    _addstr(win, 0, 1, "strands", bold)
    hdr = (f"{nlive} live · {total} total · "
           f"{nmail} unread mail")
    _addstr(win, 0, 10, hdr)
    _addstr(win, 0, max(0, w - 10), now.strftime("%H:%M:%S"), dim)

    # header line 2: cleft
    ctext, cwarn, cstale = state["cleft"]
    _addstr(win, 1, 1, ctext, cyan)
    x = 1 + len(ctext)
    if cstale:
        _addstr(win, 1, x + 1, f"(stale {cstale})", dim)
        x += 1 + len(f"(stale {cstale})")
    if cwarn:
        _addstr(win, 1, x + 2, f"⚠ {cwarn}", red | bold)

    # column header
    hy = 2
    _addstr(win, hy, 1,
            f"{'STRAND':<20} {'STATE':<6} {'PID':>7} {'TTY':<6} "
            f"{'UPTIME':>7} {'MAIL':>4} {'SCORE':>5}", bold | curses.A_UNDERLINE)

    # Body height is tiny in the OVERVIEW zone (~6 rows in a 9-row pane), so this
    # can't be a full 39-strand top. The sort already floats LIVE + mail rows to
    # the front; show as many of THOSE (the actionable ones) as fit, then collapse
    # the quiet idle tail into a "+N idle" footer. In a tall pane it just shows
    # everything — same code, no special-casing.
    avail = h - (hy + 1)          # rows available for body + footer
    actionable = [r for r in rows if r["live"] or r["mail"]]
    quiet = [r for r in rows if not (r["live"] or r["mail"])]

    if len(actionable) <= avail:
        shown = actionable
        footer_n = len(quiet)
        footer_lbl = "idle"
    else:
        # even the actionable rows overflow — show what fits, count the rest
        shown = actionable[: max(0, avail - 1)]
        footer_n = (len(actionable) - len(shown)) + len(quiet)
        footer_lbl = "more"

    for i, r in enumerate(shown):
        y = hy + 1 + i
        state_txt = "LIVE" if r["live"] else "idle"
        state_attr = green | bold if r["live"] else dim
        name_attr = bold if r["live"] else 0
        mail_txt = str(r["mail"]) if r["mail"] else "·"
        mail_attr = yellow | bold if r["mail"] else dim

        score_txt = f"{r['score']}/5" if r["score"] else "·"
        _addstr(win, y, 1, f"{r['strand']:<20}", name_attr)
        _addstr(win, y, 22, f"{state_txt:<6}", state_attr)
        _addstr(win, y, 29, f"{r['pid']:>7}", dim)
        _addstr(win, y, 37, f"{r['tty']:<6}", dim)
        _addstr(win, y, 44, f"{r['up']:>7}")
        _addstr(win, y, 52, f"{mail_txt:>4}", mail_attr)
        _addstr(win, y, 57, f"{score_txt:>5}", green | bold if r["score"] else dim)

    if footer_n > 0:
        y = hy + 1 + len(shown)
        _addstr(win, y, 1, f"… +{footer_n} {footer_lbl}", dim)

    win.noutrefresh()
    curses.doupdate()


def main(win):
    curses.curs_set(0)
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_CYAN, -1)
    curses.init_pair(2, curses.COLOR_YELLOW, -1)
    curses.init_pair(3, curses.COLOR_RED, -1)
    curses.init_pair(4, curses.COLOR_GREEN, -1)
    win.nodelay(True)

    rows, nlive, nmail = build_roster()
    state = {"rows": rows, "nlive": nlive, "nmail": nmail,
             "cleft": ("cleft: fetching…", None, None)}

    last_cleft_ok = None
    last_cleft_at = 0.0
    now = time.monotonic()
    next_clock = now
    next_roster = now
    next_cleft = now
    cleft_backoff = CLEFT_EVERY

    while True:
        ch = win.getch()
        if ch in (ord("q"), ord("Q")):
            break
        t = time.monotonic()

        if t >= next_roster:
            state["rows"], state["nlive"], state["nmail"] = build_roster()
            next_roster = t + ROSTER_EVERY

        if t >= next_cleft:
            result, ok = fetch_cleft()
            if ok:
                text, warn = result
                last_cleft_ok = (text, warn)
                last_cleft_at = t
                cleft_backoff = CLEFT_EVERY
                next_cleft = t + CLEFT_EVERY
                state["cleft"] = (text, warn, None)
            else:
                cleft_backoff = min(cleft_backoff * 2, CLEFT_BACKOFF_MAX)
                next_cleft = t + cleft_backoff
                if last_cleft_ok:
                    age = int((t - last_cleft_at) // 60)
                    text, warn = last_cleft_ok
                    state["cleft"] = (text, warn, f"{age}m")
                else:
                    err = result if isinstance(result, str) else "cleft: ?"
                    state["cleft"] = (err, None, None)

        if t >= next_clock:
            next_clock = t + CLOCK_EVERY

        draw(win, state)
        time.sleep(0.2)


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        pass
