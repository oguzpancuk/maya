---
name: deploy-checklist
description: Pre-deploy verification checklist — run before any production deploy, when asked to "deploy", "ship", "release", "canlıya al", or "yayınla". Walks the generic gates, then the product's own deploy steps.
---

# /deploy-checklist

Walk every item IN ORDER; report each as pass / fail / not-applicable-because.
A fail stops the deploy — no "deploy anyway" without my explicit say-so.

## Generic gates (every product)
1. Working tree clean, on the release branch, synced with remote.
2. CI green on this exact commit: the `verify` check on the commit `main`
   points at — the required check that let it merge. Do not run the
   battery locally instead: a local tree can carry deps or state CI does
   not, and CI's run is the one the merge gate trusted.
3. No secrets in the diff since last deploy (`git diff <last-tag>..HEAD`
   scanned for keys/tokens/passwords).
4. Migrations/data changes: reversible, or the irreversibility is stated
   and acknowledged.
5. Release notes exist for the range (offer /release-notes if not).
6. `evaluator-qa` on every ROADMAP item marked done since the last deploy:
   it grades each done-when clause against the running app, not the
   tests. One NEEDS_WORK stops the deploy. This is the only pass that
   checks every clause, not just the ones the battery could not see.

## Release
This runs in a LOCAL session on the owner's machine — never in a project
thread. Every step that changes production waits for my explicit
go-ahead, each time.
7. Run the product's deploy steps (below) from this machine, in order,
   stopping at the first failure.
8. Verify — the health check answering, the smoke-test flow — and only
   then push the release tag (`vX.Y.Z` on the deployed commit). The tag
   marks what is live; for an iOS surface it is also what Xcode Cloud
   archives to TestFlight: confirm the build appears, then open it on a
   device. Rollback is the product's rollback command below.

## Product steps
[STACK: the deploy commands and where they deploy to, the health check
URL, the smoke-test flow, the rollback command. Credentials live on the
owner's machine (`fly auth`, `wrangler login`, …) — never in the repo, a
cloud environment or an Actions secret. Until filled, this skill stops
before step 7 and reports that the product has no deploy path defined.]
