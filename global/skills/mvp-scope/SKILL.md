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
     naming its verification (test, screenshot, manual check).
   - `## v1` — what ships after the skeleton works end-to-end.
   - `## Deferred` — with the reason each item can wait.
5. Summarize the cut to me in chat and list what I lose by accepting it.

## Rules
- The skeleton must be completable in days, not weeks. If it isn't, cut again.
- Done-when clauses must be verifiable by the project's verify battery or a
  browser check — "feels good" is not a clause.
- Never delete PRD content — the roadmap references it, it doesn't replace it.
