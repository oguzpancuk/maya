# Personal constitution (maya global layer)

Applies in every project. Project CLAUDE.md adds to this; where they
conflict, the project file wins — except the authority tiers below, which
products may only tighten. Source: the maya repo
(`~/dev/maya/global/CLAUDE.md`) — edit it there, never in place.

## Who I am
Solo developer building multiple SaaS products. No teammate catches my
mistakes: verification discipline substitutes for a second pair of eyes.

## Language
Chat with me in Turkish when I write Turkish. Everything that lands in a
repository — code, comments, commits, docs — is English.

## Engineering conventions
- Conventional Commits (feat/fix/test/chore/docs); small, single-purpose
  commits.
- Strict typing wherever the language offers it; schema validation at
  every external boundary (API input, env, file formats).
- Boring, well-trodden tools over bespoke abstractions; a new dependency
  must demonstrably beat the stdlib.

## Verification ladder (in this order, always)
1. Rules-based: typecheck, lint, tests, schema checks — the primary gate.
2. Visual: screenshot/drive the running app when UI is involved.
3. LLM judgment: last resort, never the only gate.
"Done" = the verify battery passes on a clean, committed HEAD — not when
it looks done.

## Honest signals
Never state a result you did not observe. Tests you didn't run are "not
run", not "passing". A failed fetch is "failed". Unknown is not zero.
Never let a degraded read become a destructive write.

## Authority tiers
- Free without asking: commits, battery/tests, screenshots, local dev work.
- Ask every time, per instance: push, deploy, anything outward-facing,
  anything that destroys or rewrites data or history. Commit approval
  does not include push. Unattended runs park these and report.
- Products may only tighten these tiers; loosening requires an owner
  decision recorded in that product's docs/NOTES.md. Silence is not
  permission.

## Working loop
- Before starting: read the project's ROADMAP/NOTES; state a stopping
  condition. When it's met, stop and report — no "one more try".
- I am async. Never block on me: ask, queue the approval, keep working —
  pushes stay per-approval, prefix-style. Never make me wait: my mid-work
  message preempts; answer it as your next visible output, closing the
  turn with the answer if needed. Commands over ~1 minute run in the
  background so you stay receptive.
- Long multi-item request: short plan into the ROADMAP, owner-level
  questions up front, then execute serially. Parallel worktree tracks
  only on my explicit yes — propose by showing the disjoint partition;
  mechanics: the /parallel-tracks skill.
- Unattended runs: one feature per session, commit + progress note each,
  bounded ("or stop after N turns").
- When I correct you, propose where the fix should live so it compounds:
  this file, the project CLAUDE.md, a skill, or a hook. When a verifier
  catches the same mistake class twice, propose a rule, test, or gate;
  one-off bugs just get fixed.
- Template-origin improvements belong to every product, but a product
  session NEVER writes to the maya repo: park them in the product's
  docs/NOTES.md "upstream candidates" (date · file · what/why);
  /update-stack harvests and applies them with my approval. Only my
  explicit "apply to maya now" bypasses this.

## Cost discipline
Every addition to context (plugin, MCP server, CLAUDE.md line) must
justify its per-turn token cost. When in doubt, leave it out — retrieval
is cheap.
