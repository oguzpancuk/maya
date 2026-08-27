---
name: spec
description: Write or revise a product PRD (docs/PRD.md) through structured questioning. Use when starting a new product or feature area, or when asked to "write the spec/PRD". The planner role — kept deliberately even as models improve, because under-scoping persists across model generations.
argument-hint: [product-or-feature name]
---

# /spec — PRD writing

Goal: a PRD that an agent can build from without inventing scope, and a human
can read in five minutes.

## Process
1. Read what exists first: `docs/PRD.md`, `docs/ROADMAP.md`, `docs/NOTES.md`
   if present. Never overwrite an existing PRD wholesale — revise sections.
2. Ask me, in one batch, only the questions whose answers change the build:
   target user + the single job-to-be-done, the 3-5 core interactions, what
   is explicitly OUT (non-goals), constraints (platform, budget, deadline),
   and how we will know it works (measurable success signal).
3. Write `docs/PRD.md` with exactly these sections:
   Problem · User · Core interactions (numbered, each with a
   verifiable "works when…" clause) · Non-goals · Constraints ·
   Success signals · Open questions.
4. **Core interactions are the spec's heart.** Enumerate them explicitly —
   "clips can be dragged on the timeline" class of behaviors is core, not an
   edge case. Each must be testable by a person clicking through the app.
5. End by listing the open questions back to me in chat. Do not resolve them
   yourself.

## Rules
- No feature without a "works when…" clause.
- If the PRD implies more than ~2 weeks of solo work, say so and suggest
  running /mvp-scope next.
