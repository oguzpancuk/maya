# Project instructions — {{PRODUCT_NAME}}

<!-- SOURCE of the project's instructions field (Project settings > Memory).
     Edit here, commit, paste again. Rules about the repository itself live
     in CLAUDE.md, which every thread reads from its clone. -->

## Work
- The build order is `docs/ROADMAP.md`; open questions and handoffs are in
  `docs/NOTES.md`. Read both before starting.
- Whatever I paste here is the task. If a ROADMAP item already covers it,
  say so instead of starting a second thread.
- One feature per thread. A second problem found on the way goes into
  `docs/NOTES.md`, not into the fix.
- Propose threads before starting them; at most two at a time until I say
  otherwise.

## Pull requests
- Start from `main`, work on your own branch, open one pull request per
  thread. The body names the done-when clause it satisfies and carries the
  battery result, the red run of each new test, and the QA verdict when
  CLAUDE.md called for one.
- `main` is protected: CI green and up to date with `main`, or no merge.
  When `main` moves under your open pull request, merge it into your branch
  yourself. Never change CI to get green.
- Never merge. I merge.

## Review
- When a thread opens a pull request, start a review thread for it. Its
  task: `/code-review --comment` on the pull request — never `--fix`. If
  `--comment` cannot post from the thread, post each finding as a pull
  request comment yourself, file and line included.
- In a summary comment it also checks that every new test covers the clause
  it claims and that the body shows its red run, then ends with APPROVE or
  NEEDS_WORK and one sentence why.
- The review thread keeps watching the pull request. After each push it
  reviews the delta the same way, until its summary says APPROVE. The
  authoring thread fixes what the review posts.

## Ask me first
- Anything outward-facing: deploys, DNS, third-party dashboards, production
  data.
- A schema or API change that is not reversible in one commit.
- A dependency that is not clearly better than the standard library.

## Memory
- Project memory stays in this project. What is about the repository — a
  pitfall, a template improvement, a battery miss — also goes into
  `docs/NOTES.md`, under the section CLAUDE.md names. Only the repo reaches
  the other products.
