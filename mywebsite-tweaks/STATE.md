# mywebsite-tweaks — state

*Curated summary of where this strand is. Updated at the end of each session.*

## What exists

- **Role: mywebsite-keeper** — this strand owns deep knowledge of
  `www.petergrecian.co.uk` (`~/mywebsite`) and improves it on request, including
  work handed over from other forkterms. Mission in this dir's CLAUDE.md; memory
  in `project_mywebsite_keeper.md`.
- Cloudflare DNS/WAF/cache config lives as Terraform in `mywebsite/cloudflare/`
  (`dns.tf`, `cache.tf`, `waf.tf`, `zone.tf`, `pages.tf`). Backend: S3
  `tfstate-petergrecian/cloudflare-tfstate`. Token: `/cloudflare/terraform-token`
  (Bearer), passed as `TF_VAR_cloudflare_api_token`.
- **README rewritten (2026-07-17).** The old `mywebsite/README.md` was a stale
  copy from the `cv` repo (described `cv.py`/`./update`/`cvdev`/w3, gardencam
  only). Now accurately documents mywebsite: architecture, `routes/` dispatch,
  real route set (cameras/astro/glacier/lambda-stats/etc.), `./deploy` flow,
  `/contents` sync, Cloudflare, cv-vs-mywebsite. Addresses the TODO.md item
  "Better repo name and docs".

## Pending / loose ends

- **Apex domain (`petergrecian.co.uk`) — half-fixed (2026-07-14).** It previously
  had NO DNS record and didn't resolve at all; `www` worked. Added a proxied apex
  CNAME (flattened) → API Gateway — **applied**, apex now resolves. Added an
  apex→www 301 redirect ruleset in `dns.tf` (`cloudflare_ruleset.apex_redirect`)
  — **NOT applied**: the terraform token has zero ruleset permission (fails even
  to read the ruleset phases). The origin 403s on a `petergrecian.co.uk` Host
  header, so until the redirect exists the apex resolves but 403s.
  - **To finish:** grant the terraform token **Zone → Dynamic Redirect → Edit**
    and **Zone → Cache Rules → Edit** at dash.cloudflare.com/profile/api-tokens,
    re-save via `secrets set /cloudflare/terraform-token`, then
    `terraform apply` in `mywebsite/cloudflare/`. Import the two new rulesets if
    they were created out-of-band.
- **Pre-existing drift:** `cloudflare_ruleset.cache_rules` (cache.tf) was never
  applied — same missing ruleset permission. Same token fix resolves it; apply
  will create it (starts edge-caching /cv, /gitinfo, /robots.txt, /contents).
- **`/cloudflare/global-api-key` is invalid** — auth error 9103 (`cfk_`-prefixed,
  52 chars; a real global key is 37-char hex). Stale/mislabeled; rotate or
  remove from the secrets store.

## Decisions

- Apex → www via **301 redirect**, not direct serve: origin only accepts the
  `www.` Host (apex 403s), and a single canonical hostname is better for SEO.
  Redirect implemented as a `http_request_dynamic_redirect` ruleset.
