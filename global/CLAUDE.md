# Personal constitution (maya global layer)

Applies in every project. Project CLAUDE.md adds to this; where they conflict,
the project file wins. Source of this file: the maya repo — edit it there
(`~/dev/maya/global/CLAUDE.md`), never in place.

## Who I am
Solo developer building multiple SaaS products. No teammate catches my
mistakes: verification discipline substitutes for a second pair of eyes.

## Language
Chat with me in Turkish when I write Turkish. Everything that lands in a
repository — code, comments, commits, docs — is English.

## Engineering conventions
- Conventional Commits (`feat:`, `fix:`, `test:`, `chore:`, `docs:`).
  Small, single-purpose commits.
- Strict typing wherever the language offers it; schema validation at every
  external boundary (API input, env, file formats).
- Prefer boring, well-trodden tools I already run (bash, git, standard CLIs)
  over bespoke abstractions. Add a dependency only when it demonstrably
  beats the stdlib.

## Verification ladder (in this order, always)
1. Rules-based: typecheck, lint, tests, schema checks — the primary gate.
2. Visual: screenshot/drive the running app when UI is involved.
3. LLM judgment: last resort, never the only gate.
A change is "done" when the project's verify battery passes on a clean,
committed HEAD — not when it looks done.

## Honest signals
Never state a result you did not observe. Tests you didn't run are "not run",
not "passing". A failed fetch is reported as failed. Unknown is not zero.
Never let a degraded read become a destructive write.

## Working loop
- Before starting: read the project's ROADMAP/NOTES; state a stopping
  condition for the task. When it's met, stop and report — no "one more try".
- Unattended work (goal loops, overnight runs): one feature per session,
  commit + progress note per session, bounded with "or stop after N turns".
- When I correct a mistake of yours, propose where the fix should live so it
  compounds: this file, the project CLAUDE.md, a skill, or a hook.
- Upstream rule: if a fix or improvement lands in a file that came from the
  maya template (.claude/ hooks, agents, skills, contracts/, CLAUDE.md
  sections), it belongs to every future product — apply it to the maya repo
  too, or when maya isn't checked out, record it in the product's
  docs/NOTES.md under "upstream candidates" so /update-stack harvests it.

## Cost discipline
Every addition to context (plugin, MCP server, CLAUDE.md line) must justify
its per-turn token cost. When in doubt, leave it out — retrieval is cheap.
