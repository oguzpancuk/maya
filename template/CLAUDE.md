# {{PRODUCT_NAME}}

<!-- Instantiated from maya (see .maya-version). Slots marked [STACK: ...]
     are filled by /new-product; a remaining [STACK: TODO] is a visible gap,
     never fill one with a guess. -->

[STACK: one-line product description — what it is, for whom]

Spec: `docs/PRD.md` · Build order: `docs/ROADMAP.md` · Working notes:
`docs/NOTES.md` · Decisions: `docs/adr/`

## Stack & commands
[STACK: fill the table — every command an agent may need, nothing more]

| Purpose | Command |
|---|---|
| install | [STACK: TODO] |
| test | [STACK: TODO] |
| typecheck | [STACK: TODO] |
| lint | [STACK: TODO] |
| dev | [STACK: TODO] |
| full battery | `bash .claude/hooks/verify.sh` |

## Standards
- Strict typing where the language offers it; schema validation at every
  external boundary. `any`/untyped escape hatches need a `// why:` comment.
- Every feature lands with its verification: a test, or for UI a screenshot
  check — named in the ROADMAP done-when clause it satisfies.
- A new test is seen failing before the change that makes it pass, and the
  pull request says so. A test that was never red proves nothing.
- [STACK: framework/library conventions specific to this product]

## Verification
`bash .claude/hooks/verify.sh` is the single battery. CI runs the same file,
and that CI run is the required status check on every pull request — nothing
reaches `main` without it green. Run it yourself before opening a pull
request or reporting "done": on a clean, committed HEAD, `git status
--porcelain` empty before and after. A result from a dirty tree is not a
result.
If the battery cannot cover a done-when clause (UI behaviour, data state,
an external service), run the `evaluator-qa` agent on it and put its
verdict in the pull request. It collects its own evidence instead of
taking yours; where `verify.sh` already covers the clause, it is not
needed. An unverifiable claim is not a passing claim.

## Workflow
- Work on a branch, never on `main`; land through a pull request.
- The repo is the memory. Read `docs/ROADMAP.md` + `docs/NOTES.md` when
  starting; update `docs/NOTES.md` (dated, append-only) when stopping.
  Decisions that constrain the future go to `docs/adr/`.
- Two things always go into `docs/NOTES.md`, whatever else you remember
  them in: an improvement to a template-origin file (`CLAUDE.md`,
  `verify.sh`, `ci.yml`, `docs/project-instructions.md`) under "Upstream
  candidates", and anything the battery passed that turned out broken
  under "Battery gaps". maya harvests this repo, not a project's memory.
- Every task states its stopping condition up front; when met, stop & report.
- Merging is the owner's call, always. Do not merge, force-push, or change
  CI configuration without being asked in this session.

## Deploy
[STACK: deploy target and commands. Until filled: this product has no deploy
path. Deploys are run by the owner from a local session, never from a cloud
thread.]
