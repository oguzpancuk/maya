# Preview recipes

Every pull request gets a preview URL (`template/CLAUDE.md`, Preview), and
the preview is a required check. This file is how to get there. It is
reference material: nothing loads it until `/new-product` step 3 or a
preview problem sends someone here.

## 1. The rule: choose a host whose Git integration does it

Owner decision, 2026-09-21: a NEW product is hosted where the provider's
own Git integration gives each pull request a URL and a status check —
Vercel, Netlify, Cloudflare Pages / Workers Builds and their like; where a
database is needed, one that can branch or be cheaply duplicated. Setup is
then a few clicks in the provider's dashboard: connect the repository,
turn previews for pull requests on, turn automatic PRODUCTION deploys from
`main` OFF (deploys are the owner's, run locally — `/deploy-checklist`),
and add the provider's check to the required checks.

Why it is the rule and not a preference: recipes 2 and 3 below took most
of a day between them, each surfaced pitfalls specific to its provider,
and each leaves a production-capable token in GitHub Actions that has to
be fenced in. A Git integration has none of that.

A preview workflow of our own is the EXCEPTION. It needs its reason
written into the product's `docs/NOTES.md`, and it follows section 4.
Recorded exceptions: pati (Fly.io has no such integration, and moving a
live PostGIS app for preview convenience is out of proportion) and juno
(Cloudflare has Workers Builds, but the rule arrived after recipe 3 was
built, hardened and proven there).

Not verified here, so check before relying on it: whether Workers Builds
can be kept from deploying the production branch — its default production
command is `npx wrangler deploy`; the docs say the command can be changed,
not that it can be a non-deploying one.

## 2. Recipe — full-stack app on Fly.io (pati)

A review app per pull request from the production Dockerfile, with a
database of its own in a separate cluster. Verified 2026-09-21.

One-time, owner-side:

```bash
fly postgres create --name <product>-review-db --region <region> --vm-size shared-cpu-1x --initial-cluster-size 1 --volume-size 1
fly machine update <machine-id> --vm-memory 1024 -a <product>-review-db --yes   # 256 MB OOM-kills CREATE EXTENSION postgis
fly tokens create org personal | gh secret set FLY_REVIEW_TOKEN -R <owner>/<repo>
openssl rand -hex 32 | gh secret set REVIEW_JWT_SECRET -R <owner>/<repo>
```

`.github/workflows/preview.yml` (pati, as of `e70ac5a` — the product's
live copy wins over this one):

```yaml
# Per-pull-request preview: the whole app — backend, web and admin in one
# image, the same Dockerfile production uses — at
#   https://pati-pr-<number>.fly.dev
# with a database of its own in the `pati-review-db` cluster. Redeployed on
# every push to the pull request, destroyed when it closes. Configuration:
# fly.review.toml. The URL is deterministic, so a pull request body can carry
# it before this job has finished; the job going green is what makes it true.
#
# Why pull_request_target. The Fly token below is org-scoped — the only kind
# that can create and destroy apps — so it can also deploy `pati-app`. With
# plain `pull_request` this file is read from the pull request itself, and
# any branch could rewrite these steps into a production deploy that runs
# the moment the pull request opens. `pull_request_target` reads the file
# from `main`, always. The pull request's code is still what gets built, but
# it is built on Fly's remote builder and run inside the review app — it
# never executes on this runner, next to the token.
name: preview
on:
  pull_request_target:
    types: [opened, reopened, synchronize, closed]

permissions:
  contents: read

jobs:
  preview:
    runs-on: ubuntu-latest
    concurrency:
      group: preview-pr-${{ github.event.number }}
    steps:
      # The pull request's tree, as the build context — by sha, and without
      # leaving a credential in the checkout.
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}
          persist-credentials: false
      - uses: superfly/fly-pr-review-apps@f5d85309215d5700e7a42faf9aa5e9a718aaef7c # 1.5.0
        with:
          name: pati-pr-${{ github.event.number }}
          region: fra
          org: personal
          config: fly.review.toml
          postgres: pati-review-db
          memory: 512
          secrets: JWT_SECRET=${{ secrets.REVIEW_JWT_SECRET }}
        env:
          # An org-scoped token: the action creates and destroys apps, which a
          # deploy token for one app cannot do. Kept apart from the production
          # deploy credential on purpose.
          FLY_API_TOKEN: ${{ secrets.FLY_REVIEW_TOKEN }}
      # The action destroys the app on close but leaves what `postgres attach`
      # made: a database (17 MB even when empty — PostGIS) and a superuser
      # role, one pair per pull request, on a 1 GB volume. Seen on pati-pr-4.
      # `fly postgres connect` wants a terminal; psql inside the machine does
      # not. The name is built from the pull request NUMBER only.
      # Third-party actions are pinned to a commit: both end up running with an
      # org-scoped Fly token, and a tag or branch can be moved under us.
      - uses: superfly/flyctl-actions/setup-flyctl@ed8efb33836e8b2096c7fd3ba1c8afe303ebbff1 # 1.6
        if: github.event.action == 'closed'
      - name: Drop the review app's database and role
        if: github.event.action == 'closed'
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_REVIEW_TOKEN }}
          DB: pati_pr_${{ github.event.number }}
        run: |
          flyctl ssh console -a pati-review-db -C "sh -c 'psql \"postgres://postgres:\$OPERATOR_PASSWORD@localhost:5432/postgres\" -v ON_ERROR_STOP=1 -c \"DROP DATABASE IF EXISTS $DB WITH (FORCE)\" -c \"DROP ROLE IF EXISTS $DB\"'"
      # A deploy that did not take must not look green. The request also wakes
      # the machine, which auto-stops when idle.
      - name: Health check
        if: github.event.action != 'closed'
        run: curl -fsS --retry 10 --retry-delay 6 --retry-all-errors "https://pati-pr-${{ github.event.number }}.fly.dev/health"
```

`fly.review.toml` — production's `fly.toml` minus what a disposable app
must not have:

```toml
# Review-app configuration, used only by .github/workflows/preview.yml.
# Production is fly.toml. This file differs from it on purpose:
#   - no [mounts]: a review app has no volume; uploads go to /tmp and die
#     with the machine, which is what a disposable preview should do
#   - no CORS_ORIGINS: the app serves its own origin, and unset means "allow"
#   - no ADMIN_HOST: the admin panel is chosen by hostname and a review app
#     has one hostname, so the panel is not reachable on a preview
#   - no DEMO_GUIDE_REFRESH: nothing to keep alive
# The app name and region come from the workflow; DATABASE_URL from
# `fly postgres attach` (a database of its own in pati-review-db);
# JWT_SECRET from the workflow's secrets.

# Same region as pati-review-db. Without this line the first review app
# landed in iad while its database sat in fra — every query crossed the
# Atlantic. The workflow passes the region too; this is what makes it stick.
primary_region = "fra"

[build]
  dockerfile = "Dockerfile"

[deploy]
  release_command = "node scripts/migrate.js"

[env]
  PORT = "3000"
  UPLOADS_DIR = "/tmp/uploads"
  WEB_DIST_DIR = "/app/web-dist"
  ADMIN_DIST_DIR = "/app/admin-dist"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 0

  [[http_service.checks]]
    interval = "30s"
    timeout = "5s"
    grace_period = "10s"
    method = "GET"
    path = "/health"

[[vm]]
  size = "shared-cpu-1x"
  memory = "512mb"
```

What bit, in the order it bit: the database machine's default 256 MB;
no `primary_region`, so the first app landed in `iad` while its database
sat in `fra`; the review-apps action destroys the app on close but leaves
the attached database (17 MB even when empty, with PostGIS) and a
superuser role — hence the drop step, run with `psql` inside the cluster's
machine because `fly postgres connect` wants a terminal; and the token is
org-scoped, so it can deploy production — hence section 4.
Still open there: a preview starts with an EMPTY database.

## 3. Recipe — static / SPA export on Cloudflare Workers (juno)

A Worker VERSION per pull request under the alias `pr-<number>`; never a
deployment, so nothing to tear down. Verified 2026-09-21.

One-time, owner-side: `CLOUDFLARE_API_TOKEN` ("Edit Cloudflare Workers"
template, restricted to the account) and `CLOUDFLARE_ACCOUNT_ID` as
secrets; whatever the build inlines as repository VARIABLES when it is
public by design (juno: the Supabase URL and anon key — checked for role
`anon` before being stored). `"preview_urls": true` in `wrangler.jsonc`,
then ONE `npx wrangler triggers deploy` from `main`: it is a non-versioned
setting and Cloudflare only applies it on a deployment — until then the
upload succeeds and prints no URL.

`.github/workflows/preview.yml` (juno, as of `7299022` — the product's
live copy wins):

```yaml
# Per-pull-request preview of the web target: the Expo web export, uploaded
# as a Worker VERSION with the alias pr-<number>. `versions upload` never
# touches production traffic; the alias gives the version its own URL.
#
# Why pull_request_target and two jobs. A Cloudflare token that can upload a
# version can also deploy production — there is no narrower permission. With
# plain `pull_request` the workflow is read from the pull request itself, so
# any branch could rewrite these steps and deploy. `pull_request_target`
# reads this file from `main`, always. The price: a pull request's own code
# must never run next to the token. So:
#   build  — runs the pull request's code (npm ci, expo export). No secrets.
#   upload — holds the token. Runs NOTHING from the pull request: it checks
#            out `main` for wrangler.jsonc, takes the built files as an
#            artifact, and uses a pinned wrangler from the registry.
# The preview talks to the PRODUCTION Supabase project (owner decision,
# 2026-09-21): real data behind RLS, and a pull request's migrations are NOT
# applied to it. The URL and anon key are public by design — they ship in
# every bundle — so they are repository variables, not secrets.
name: preview
on:
  pull_request_target:
    types: [opened, reopened, synchronize]

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      EXPO_PUBLIC_SUPABASE_URL: ${{ vars.PREVIEW_SUPABASE_URL }}
      EXPO_PUBLIC_SUPABASE_ANON_KEY: ${{ vars.PREVIEW_SUPABASE_ANON_KEY }}
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}
          persist-credentials: false
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      # The same gates `npm run deploy` runs, minus the deploy: refuse a local
      # or wrong-role Supabase target, export, then check the bundle itself.
      - working-directory: apps/mobile
        run: npx tsx scripts/check-deploy-env.ts && npx expo export -p web --clear && npx tsx scripts/check-deploy-bundle.ts
      - uses: actions/upload-artifact@v4
        with:
          name: web-dist
          path: apps/mobile/dist
          if-no-files-found: error
          retention-days: 3

  upload:
    needs: build
    runs-on: ubuntu-latest
    concurrency:
      group: preview-pr-${{ github.event.number }}
    steps:
      # `main`, not the pull request: nothing from the branch runs in this job.
      - uses: actions/checkout@v4
        with:
          persist-credentials: false
      - uses: actions/download-artifact@v4
        with:
          name: web-dist
          path: apps/mobile/dist
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - name: Upload the version under the alias pr-<number>
        working-directory: apps/mobile
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          ALIAS: pr-${{ github.event.number }}
        run: |
          npx --yes wrangler@4.133.0 versions upload --preview-alias "$ALIAS" --message "pull request #${{ github.event.number }}" | tee upload.log
          url="$(grep -Eo 'https://[a-z0-9.-]+\.workers\.dev' upload.log | grep -- "$ALIAS-" | head -1)"
          [ -n "$url" ] || { echo "no preview alias URL in wrangler's output — is a workers.dev subdomain enabled, and preview_urls true in wrangler.jsonc?" >&2; exit 1; }
          echo "PREVIEW_URL=$url" >> "$GITHUB_ENV"
          echo "Preview: $url" >> "$GITHUB_STEP_SUMMARY"
      # An upload that does not serve must not look green.
      - name: The preview answers
        run: curl -fsS --retry 8 --retry-delay 5 --retry-all-errors -o /dev/null "$PREVIEW_URL/" && curl -fsS -o /dev/null "$PREVIEW_URL/legal"
```

The URL is `https://pr-<number>-<worker>.<account-subdomain>.workers.dev`.
What a preview like this cannot show: anything that needs the pull
request's backend changes — juno's talks to the production Supabase
project by owner decision, so migrations and Edge Function changes are not
applied.

## 4. Rules for any preview workflow of our own

1. `pull_request_target`, not `pull_request`: the workflow is then read
   from `main` and a branch cannot rewrite the steps that hold the token.
   The token almost always can deploy production — Fly has no narrower
   token that creates apps, Cloudflare none for "upload only".
2. A job that runs the pull request's code (`npm ci`, a build) holds NO
   secrets. Build in one job, pass the output as an artifact, upload in
   another that checks out `main` and runs a pinned tool.
3. Such a workflow cannot run from the pull request that adds it. Open a
   small follow-up pull request and call the preview done only when that
   one is green and the URL answers from OUTSIDE the job.
4. Third-party actions are pinned to a commit sha.
5. The workflow ends with a request to the preview itself, and on `closed`
   removes everything it created.
6. Make EVERY job of it a required check: a job skipped because the one it
   `needs` failed counts as passing.
