# aicli — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->

Open question: should aicli make continue/resume FIRST-CLASS? Today `cld <strand> --resume`/`--continue` already work — extra args fall through to the backend (PASS array), and a strand launch cd's into the strand dir so --resume is correctly scoped to that strand's own history. So the capability EXISTS; it's just not surfaced (no dedicated flag, no niceties). A first-class option could add: (1) convenience flag e.g. `aicli -C <strand>`; (2) the real value — resume the SPECIFIC session tied to this window (aicli records .tty/.wid, could map to the exact session id rather than bare --continue's 'most recent in dir'); (3) raise-or-resume semantics slotted into the existing decision tree (live→raise, dead-with-history→offer resume, none→fresh). TENSION to resolve first: making resume ergonomic pushes AGAINST the strand philosophy (sessions disposable, STATE.md durable) — it may nudge people to lean on transcript-continuity instead of dcp'ing to STATE.md. That friction may be deliberate, not an oversight. Real decision = 'do we want to make the exception ergonomic, or keep the friction that nudges toward dcp+fresh?' — a philosophy call, not a coding one. Related: the dcp/continue/compact orthogonality (essay seed spooled to aifabric-essay).


Decision: deprecate `cld` in favour of `aicli`. Peter's muscle memory is now `aicli` because `cld` does not work at work (the cld wrapper/alias isn't available there; aicli is the portable name). aicli is already the canonical superset launcher (aifabric/bin/aicli); cld is the legacy alias. Action to consider: remove/retire the cld alias, or at minimum stop documenting it as co-equal — steer everything to `aicli`. Check: any docs/hints/help text still presenting `cld` as the primary name; the `if [[ "$PROG" == "cld" ]]` claude-forcing branch (keep the behaviour, but under aicli invocation, not a cld-named binary). See memory [[aicli-supersedes-cld]].

