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

## Product steps
[STACK: the real deploy commands + post-deploy verification — health check
URL, smoke-test flow, rollback command. Until filled, this skill stops here
and reports that the product has no deploy path defined.]
