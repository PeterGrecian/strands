# aicli — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->

Decision: deprecate `cld` in favour of `aicli`. Peter's muscle memory is now `aicli` because `cld` does not work at work (the cld wrapper/alias isn't available there; aicli is the portable name). aicli is already the canonical superset launcher (aifabric/bin/aicli); cld is the legacy alias. Action to consider: remove/retire the cld alias, or at minimum stop documenting it as co-equal — steer everything to `aicli`. Check: any docs/hints/help text still presenting `cld` as the primary name; the `if [[ "$PROG" == "cld" ]]` claude-forcing branch (keep the behaviour, but under aicli invocation, not a cld-named binary). See memory [[aicli-supersedes-cld]].

