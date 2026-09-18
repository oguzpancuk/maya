---
name: mvp-scope
description: Cut a PRD down to a walking-skeleton MVP and write the build order into docs/ROADMAP.md. Use after /spec, when scope feels too big, or when asked "what's the MVP / what do we cut".
---

# /mvp-scope — scope cutting

Goal: the smallest end-to-end slice that a real user could use, plus an
honest deferred list — not a smaller wishlist.

## Process
1. Read `docs/PRD.md`. If it doesn't exist, stop and suggest /spec first.
2. Identify the walking skeleton: the single thinnest path through every
   layer (UI → logic → storage → back) that completes the core job once.
3. Classify every PRD interaction: `skeleton` / `v1` / `deferred`.
   Deferring is the default; promotion needs a one-line justification.
4. Write `docs/ROADMAP.md`:
   - `## Walking skeleton` — ordered steps, each with a done-when clause
     naming its verification: `test`, `screenshot` or `manual check`. The
     name is a trigger: a screenshot or manual check makes the thread run
     `evaluator-qa` before its pull request; a test does not.
   - `## v1` — what ships after the skeleton works end-to-end.
   - `## Deferred` — with the reason each item can wait.
5. Write the About block of `docs/project-instructions.md` from the same
   material: product line, areas, skeleton items in order with their
   done-when, v1 items, deferred items with reasons. Remind me to paste the
   file into the project's instructions — the coordinator reads that field,
   not the repo.
6. Summarize the cut to me in chat and list what I lose by accepting it.

## Rules
- The skeleton's FIRST step is always the same, whatever the product: the dev
  environment boots, the test runner runs ONE real passing test, and
  `bash .claude/hooks/verify.sh` exits 0. The battery is born with the
  skeleton — a later standalone "testing task" is a planning failure.
- The skeleton must be completable in days, not weeks. If it isn't, cut again.
- Done-when clauses must be verifiable by the project's verify battery or a
  browser check — "feels good" is not a clause. Verifiable is not enough:
  each clause also says what failure looks like ("wrong password → 401
  and no session cookie"), so the test written for it has a red state to
  show. A clause that cannot fail cannot be tested.
- Never delete PRD content — the roadmap references it, it doesn't replace it.
