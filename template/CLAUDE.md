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
- Every feature lands with the verification its ROADMAP done-when clause
  names: a test, a screenshot check, or a manual check.
- A new test is seen red before the change that makes it pass; the pull
  request says which test and how it was made to fail.
- [STACK: framework/library conventions specific to this product]

## Verification
- `bash .claude/hooks/verify.sh` is the single battery. CI runs the same
  file as the required check on every pull request.
- Run it before opening a pull request, on a clean committed HEAD
  (`git status --porcelain` empty before and after), and put the result in
  the pull request body.
- If the item's done-when clause names a screenshot or manual check, run the
  `evaluator-qa` agent on it and put its verdict in the pull request body.
  NEEDS_WORK means not done: fix, run it again, open the pull request only
  on PASS. A clause that names a test needs no QA pass.
- Never report a check you did not run.

## Workflow
- Work on a branch, never on `main`; land through a pull request.
- Read `docs/ROADMAP.md` and `docs/NOTES.md` when starting. When stopping,
  append a dated entry to `docs/NOTES.md`; decisions that constrain the
  future go to `docs/adr/`.
- Always into `docs/NOTES.md`, whatever else you remember them in: an
  improvement to `CLAUDE.md`, `verify.sh`, `ci.yml` or
  `docs/project-instructions.md` under "Upstream candidates"; anything the
  battery passed that turned out broken under "Battery gaps".
- State the stopping condition up front; when met, stop and report.
- Never merge, force-push, or change CI configuration. Merging is the
  owner's.

## Deploy
[STACK: deploy target and commands — the product steps of /deploy-checklist.
Until filled: this product has no deploy path. Deploys are the owner's,
never a thread's.]
