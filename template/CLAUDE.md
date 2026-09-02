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
- [STACK: framework/library conventions specific to this product]

## Verification
`bash .claude/hooks/verify.sh` is the single battery (CI runs the same file).
It must pass on a clean, committed HEAD before a push or a "done" report —
`git status --porcelain` empty before and after. A result from a dirty tree
is not a result.
Nothing leaves this machine unreviewed: the push gate refuses any local
commit newer than `.claude/last-reviewed`, which the harness writes when
code-reviewer finishes — fix after a review, then review again. Force
pushes and remote deletions are refused outright; the scan is coarse, so a
commit message that mentions a push flag is written with `git commit -F`.

## Workflow
- The repo is the memory. Read `docs/ROADMAP.md` + `docs/NOTES.md` when
  starting; update `docs/NOTES.md` (dated, append-only) when stopping.
  Decisions that constrain the future go to `docs/adr/`.
- Every task states its stopping condition up front; when met, stop & report.
- Unattended runs (goal loops, overnight): follow `contracts/README.md` —
  one feature per session, default-FAIL feature list, evidence before
  `passes: true`.
- Launch code-reviewer before reporting a feature done, and evaluator-qa
  before any deploy and after an unattended run — unprompted; the roster
  is a standing instruction, not an option.

## Deploy
[STACK: deploy target, commands, and the checklist trigger — see
/deploy-checklist. Until filled: this product has no deploy path.]
