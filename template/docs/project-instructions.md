# Project instructions — {{PRODUCT_NAME}}

<!-- This file is the SOURCE. Paste its contents into the Claude Code project
     at claude.ai/code: Project settings > Memory > Project instructions.
     The UI copy is a copy; edit it here, commit, then paste again. Keep it
     under 16,000 characters (the field's limit). Rules about this repository
     itself belong in CLAUDE.md, not here — every thread reads that file from
     its own clone. -->

## Where the work comes from
- The build order is `docs/ROADMAP.md`; open questions and handoffs are in
  `docs/NOTES.md`. Read both before starting a thread's task.
- Anything I paste into the conversation (a bug, a stack trace, a request)
  is the task. If it is already covered by a ROADMAP item, say so instead of
  starting a second thread for it.

## Branches and pull requests
- Start every thread from `main` and work on its own branch.
- Open one pull request per thread, with a title that says what changed and
  a body that states which done-when clause it satisfies.
- `main` is protected: the CI run of `.claude/hooks/verify.sh` must be green
  before anything can merge. Never change CI configuration to get a green.
- Never merge. I merge.

## How a thread checks its own work
- Run `bash .claude/hooks/verify.sh` before opening the pull request and put
  its result in the body.
- Every new test is run red before the change that turns it green; the
  pull request body says which test and how it was made to fail.
- If the done-when clause covers something the battery cannot see — UI
  behaviour, data state, an external service — CLAUDE.md names what to run
  for it; do that and put the verdict in the pull request body. Never
  report a check you did not run.

## Review
- When a thread opens a pull request, start a separate review thread for it:
  its task is to review the diff against `CLAUDE.md` and leave findings as
  pull request comments. The review thread does not change code.
- The review thread checks each new test against the done-when clause it
  claims to cover, and asks for the red run if the body does not show one.
- The authoring thread picks the findings up from the pull request and fixes
  them.

## Ask me first
- Anything outward-facing: deploys, DNS, third-party dashboards, production
  data.
- Any schema or API change that is not reversible in one commit.
- Adding a dependency that is not clearly better than the standard library.

## What to remember where
- Project memory is for this project. When what you save there is about
  this repository — a pitfall, a template improvement, something the
  battery missed — write it in `docs/NOTES.md` as well, under the section
  `CLAUDE.md` names. Only the repo reaches the other products.

## Pace
- Propose threads before starting them; run at most two at a time until I
  say otherwise.
- One feature per thread. A thread that discovers a second problem writes it
  into `docs/NOTES.md` and reports it instead of fixing it.
