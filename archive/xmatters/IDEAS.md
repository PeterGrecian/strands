# xmatters — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->

- **[RETURN TO THIS] Implement Lambda-side dedup** — the real open work from the
  2026-07-27 disk-full storm. Native xMatters requestId/floodControl were tested
  and *disproven* on our Events-API path (see STATE.md). Fix = suppress in
  `~/alerting/lambda/handler.py::_fire_alert` before calling `trigger_xmatters`:
  query DynamoDB for an open incident with the same normalized `source+title`
  in a window, skip xMatters if found. Parked until after muppet's disk swap;
  storm already silenced (monitor stopped). Decide window + "still-broken"
  re-page cadence when we pick it up.
