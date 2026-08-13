# astro-science — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->


the 3 live cameras are difficult to compare currently.  The deliverables and science needs a revamp so the true detail of the findings can be presented.  I'd also like a downloadable impress your friends pack


Meteor/transient detection is a MISSING DELIVERABLE — the pipeline currently throws them away.

Peter spotted meteors by eye scrubbing the 2026-08-10 sweeps (canon frames 109 + 117 of 329). Confirmed by falling back to individual subs: TWO single-frame events —
  23:51:42 UTC 2026-08-10 (54px, ang 150.4)
  00:05:14 UTC 2026-08-11 (97px, ang 85.8)
Each present in EXACTLY ONE 30s sub, absent from neighbours => genuine transients, not satellites/aircraft (which step across consecutive subs). Perseid build-up (peak Aug 12-13); different angles => independent events. astrocam caught one the same night too, so BOTH cameras saw them.

THE GAP: the accumulator outlier-rejection design classes meteors WITH planes and cosmic rays as 'non-sidereal => reject' so they don't co-add. Correct for the accumulator — but it means a real detection is DISCARDED, never catalogued. And the catalogue's confidence model is built on PERSISTENCE, the one property a one-frame transient lacks by definition. So transients currently fall through every crack in the science layer.

PROPOSED: a transient deliverable that runs on the SAME non-sidereal test already specified for rejection — reuse the machinery, invert the disposal. Reject from the stack AND emit to a transients table (t_utc, camera, x/y, angle, length, peak, ablation profile). Single-sub presence is the discriminator and it is cheap: my crude detector found both events in one pass over 13 subs.

WHY IT MATTERS: 'what does a year-scale urban dataset yield' is this strand's whole question, and meteor RATE vs shower calendar is a real result an all-night all-sky archive can produce that a targeted telescope cannot. Two cameras seeing the same night also opens crude triangulation.

CAVEATS: sweep windows are 10-min stacks and SMEAR the brightness profile — I misread the 117 streak as a flat-profile satellite from the stack; the single sub proved it transient. So any classifier must run on SUBS, not sweep frames. Ablation profile (brighten-then-fade) needs raw CR2 not JPEG for the highlight range.

Staged frames: ~/tmp/meteor-0810/w109 + w117 (time-named full-res JPEGs for splay).


splay launch/IPC gotchas hit while viewing the 2026-08-10 meteor subs (2026-08-11):

1. IPC command syntax is 'key:NAME' with a COLON, not a space. 'splay --send "key space"' and 'splay --send "key RIGHT"' are both rejected as 'unknown command'; the correct form is 'splay --send key:RIGHT' / 'key:HOME'. Names are pygame K_ names without the prefix. Only 'open', 'clear' and 'key' exist — there is no 'pause' or 'goto' command, so positioning on a specific frame means HOME then N x key:RIGHT.

2. A splay started as a plain background job DIES when the launching shell exits — the socket vanishes and '--send' then reports 'no running instance'. Launch it with setsid + nohup + </dev/null + disown to survive. This matters for any agent/script that starts splay in one tool call and drives it in a later one.

3. --no-autoplay is what you want when opening a set to inspect a SPECIFIC frame; otherwise it starts playing immediately and you have to catch it.

Possible tool improvement: a 'goto <basename-or-index>' IPC command would remove the HOME+N-arrows dance, which is fragile (miscount and you are on the wrong frame with no feedback). Also worth having '--send help' list the valid commands instead of rejecting 'help' as unknown.


CONTRAIL is a missing class in find-transients (Peter, 2026-08-12: 'the meteor looks like a contrail' — he was right).

Candidate was EOS 2026-08-11 sweep frame 312/339. Verdict: CONTRAIL, not meteor. Evidence from neighbouring sweep frames (305, 311, 320, 330):
- ABSENT in 305 and 311, PRESENT in 320, still present but visibly BROADENED and diffused by 330.
- Crosses the whole frame, both ends off-screen.
- Diffuse soft edges, not a thin hard filament; same lit-cloud quality as the skyglow-lit cloud around it.
- These are the last frames of the night (sky mean 84->123 across them) so it is lit from below by DAWN TWILIGHT.

A meteor lasts <1s and is in exactly ONE sub. This persists over many minutes AND SPREADS.

THE GAP: design/transients.md and find-transients only know satellite vs meteor. A contrail scores ends_touching=2 and persists>>1, so it lands as 'satellite' — harmlessly (it is correctly rejected as non-meteor) but WRONGLY classified. Aircraft/contrails are also named in accumulator-outlier-rejection.md as things that must not co-add, so the estate already cares about them.

PROPOSED discriminator — WIDTH GROWTH OVER TIME. It cleanly separates the two persistent classes:
  satellite : thin, CONSTANT width, moves position frame to frame, ends off-screen
  contrail  : starts thin then BROADENS and softens, drifts slowly with wind, ends off-screen
Measure perpendicular FWHM per sub and fit d(width)/dt; a positive trend is a contrail. Also: satellites traverse the field in a single sub (they streak); a contrail is stationary-ish and persists across subs as a STATIC feature.

Also worth noting the contrail is a genuine CLOUD-VERDICT concern, not just a classifier one: it is a lit linear cloud, so it lifts the frame mean and could pull an otherwise-clear night toward 'cloudy' — related to the pedestal/scs double-duty trap.

NB the eyeball trap keeps repeating: this looked meteor-like in ONE sweep frame; only the NEIGHBOURING frames disproved it. Same lesson as 'sweep frames cannot classify' — but note here the neighbours in the SWEEP were sufficient, no need for subs, because persistence over minutes is exactly what a stack shows well.

