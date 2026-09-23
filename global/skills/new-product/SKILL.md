---
name: new-product
description: Instantiate the maya template as a new product repository — copies template/, fills the stack slots interactively, sets up the GitHub repo with its merge gate, records the maya version. Use only when deliberately starting a new product.
disable-model-invocation: true
argument-hint: [product-name] [target-directory, default ~/dev/<product-name>]
---

# /new-product — instantiate maya

## Preconditions (check, don't assume)
1. Locate the maya repo: try `~/dev/maya`, else ask me. Run
   `git -C <maya> pull` first so the template is current; report the commit.
2. Target directory must not exist or must be empty. Never overwrite.

## A. The repository
1. Copy `template/` (including dotfiles: `.claude/`, `.github/`,
   `.gitignore`) into the target directory.
2. Replace every `{{PRODUCT_NAME}}` placeholder with the product name
   (carriers: `CLAUDE.md`, `docs/PRD.md`, `docs/ROADMAP.md`,
   `docs/project-instructions.md`) and every `{{DATE}}` with today's date
   (carrier: `docs/adr/0001-*.md`). Then grep the tree for `{{` to prove no
   placeholder survived.
3. Fill the `[STACK]` slots interactively — ask me in ONE batch:
   language/runtime, framework(s), package layout (single app / monorepo),
   database, deploy target, test runner. Then:
   - complete the Commands table, Standards and Looking-at-it slots in
     `CLAUDE.md`,
   - write the real battery into `.claude/hooks/verify.sh` (typecheck, lint,
     tests, build — whatever the stack offers; remove the FAIL placeholder).
     A surface that builds only on another OS (native iOS: macOS) gets its
     own steps, reported "NOT RUN here" where they cannot run,
   - adjust `.github/workflows/ci.yml` setup steps to match, with a job per
     OS the battery needs.
   Leave anything still unknown as an explicit `[STACK: TODO — <question>]`
   marker; never fill a slot with a guess.
4. Record provenance: write the maya repo's current commit hash to
   `.maya-version` in the new repo.
5. `git init`, initial commit: `chore: instantiate from maya <short-hash>`.

## B. The merge gate (ask me before each outward-facing step)
6. Create the GitHub repository and push `main`.
7. Install the Claude GitHub App on it. Without this, project threads cannot
   clone the repo or open pull requests.
8. Confirm CI ran and is green on `main`. A red or skipped first run means
   the battery or the workflow is wrong — fix it now, not later.
9. Protect `main`: direct pushes off, pull request required, the `verify`
   status check required (the job in `ci.yml`; GitHub lists checks by job
   name) and every other verify job the stack added (a `verify-ios` on
   macOS for a native surface) and "require branches to be up to date
   before merging" on —
   so two green branches cannot merge into a red `main`. This is the only
   thing that stops unverified work from landing, so it is part of
   instantiation, not a later improvement.

## B2. Release path for a native iOS surface (only when there is one)
9b. Set up the Xcode Cloud workflow in App Store Connect: trigger on the
    release tag (`v*`), actions archive + distribute to the TestFlight
    internal group; put dependency setup in `ci_scripts/ci_post_clone.sh`
    if the stack needs it. Like branch protection, this is a setting, not
    a file: record in `docs/NOTES.md` what the workflow does. Nothing
    else builds: a pull request is looked at on the web in the thread and
    locally by me. Included compute is 25 hours a month; `/update-stack`
    reads the month's usage.

9c. Deploy path: deploys run from my LOCAL Claude Code session, through
    /deploy-checklist, on my machine. Log the deploy CLIs in there
    (`fly auth login`, `wrangler login`, …) and put NO deploy credential in
    a cloud environment or an Actions secret — a thread cannot deploy what
    it cannot authenticate to. Fill the checklist's product steps with the
    real commands, health check and rollback. Turn off the host's own
    deploy-on-push from `main` if it has one: production follows my
    deploy, not the branch.

## C. Registration
10. Register the product in maya's `PRODUCTS.md` (name, repo URL, local
    path, the same maya commit as `.maya-version`), commit that in the maya
    repo. An unregistered product is invisible to /update-stack's harvest —
    registration is part of instantiation, not optional.

## D. Report
11. Report: created path, repo URL, filled slots, remaining TODO slots, and
    the next steps, in order:
    - `/spec` → `docs/PRD.md`, then `/mvp-scope` → `docs/ROADMAP.md`, commit
      and push both;
    - create the project at claude.ai/code, add this repository, paste
      `docs/project-instructions.md` into Project settings > Memory >
      Project instructions (/mvp-scope has filled its About block from the
      ROADMAP — that block is all the coordinator knows about the product),
      set the goal in Project settings > General to the walking skeleton's
      end state, and lower the thread effort from the default;
    - Project settings > Environment: pick or create the cloud environment
      threads run in. Its setup script installs the stack exactly as
      `ci.yml`'s setup steps do — `verify.sh` fails when deps are missing,
      so without this every thread is red. Add the env vars the battery
      needs. Chromium and Playwright are already in Anthropic-hosted
      environments, so web QA needs nothing extra; a native mobile screen
      cannot be driven there at all. One environment serves every product
      on the same stack. Four facts, each learned the hard way: the setup
      script starts in the clone's PARENT directory (`/home/user`), so
      `cd <repo>` first — guarded, `[ -d <repo> ] || exit 0`, because the
      project's own chat (the coordinator) runs the same script with NO
      clone and an unguarded `cd` silences it; there is no Docker daemon, so a battery step that
      needs containers (a local database stack) cannot run in a thread —
      give `verify.sh` its "NOT RUN here — CI's `verify` is the run" branch
      for it, never a silent skip; and a fix to the script is tested with a
      NEW thread, because a resumed one keeps the container built before
      the fix;
    - before real work, send one tiny task — "run the battery, install
      nothing yourself, report missing deps instead" — and open the thread:
      `verify.sh` must have gone green inside it WITHOUT the thread
      installing anything; a thread that quietly runs `npm ci` hides a setup
      script that never ran. A red first thread is the environment,
      not the product.

## Rules
- Every slot is either correctly filled or a visible TODO. An unconfigured
  `verify.sh` fails by design: it would otherwise be a green required check
  on nothing, which is worse than no gate at all.
- Do not install plugins or MCP servers here.
- Steps 6-9 are outward-facing: propose, get my word, then act.
