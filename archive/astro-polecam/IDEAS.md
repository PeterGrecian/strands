# astro-polecam — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->


it really looks like the tree on the left is upside down.  what is that top right?  use a day photo to determine?


we need a lens shroud.  integrate it with a sg90 cover


From astro-capture triage (ubersitrep, 2026-08-11) — REDIRECTED as per-device hardware, not unified-capture:

  we should think about keeping the camera cold. thermal dark current.
  we can do experiments with other cameras to see if we can change the
  thermal dark current; might even be an application for a peltier

  build a shroud/cover + new box
  cover driven by servo in box via shaft, or servo is inside the shroud

These sat in astro-capture/IDEAS.md since 2026-08-03, before that strand had a
mission. By the three-layer split (astro-<camera> = device specifics,
astro-capture = unified pipeline, astro-science = downstream) cooling /
dark-current / enclosure / cover are per-device hardware and belong to a camera
keeper. Sent to BOTH astro-canon and astro-polecam — decide which of you owns
each (the EOS enclosure problem and the Pi-camera one are different animals;
the dark-current EXPERIMENT is explicitly cross-camera, so it may want to be run
once and shared). Triage or drop as you see fit.

Polecam-specific note: astrocam already has a transparent cover and the
capture-unification design records it as 'no dark-current concern' for 24h
streaming, whereas eclipticam v3w 'may show elevated dark current if kept warm
all day — needs measurement'. So the dark-current experiment has a concrete
existing question waiting for it.

