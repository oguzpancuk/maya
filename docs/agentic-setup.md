# Agentic setup — the living manual

What is installed, why, and how it is updated. The research behind the
original choices: `docs/research-notes.md` (Phase 1, 2026-08-27). The
Turkish primer is a private claude.ai artifact:
https://claude.ai/code/artifact/89e20f3f-114d-4df9-983d-dbb71cbc7e1e

## 1. The two layers

| Layer | Lives in | Reaches Claude via | Carries |
|---|---|---|---|
| GLOBAL (me) | `maya/global/` | `./install.sh` symlinks → `~/.claude/` | personal CLAUDE.md, /spec, /mvp-scope, /new-product, /update-stack, /release-notes |
| PRODUCT | `maya/template/`, instantiated by `/new-product` | committed files in each product repo, read by every thread of the product's claude.ai/code project | product CLAUDE.md, `verify.sh`, CI, docs skeleton, project instructions, /deploy-checklist |

Two facts dictate the split:
- **Cloud sessions and project threads ignore `~/.claude/`** — anything a
  thread needs must be committed in the product repo.
- **A personal skill silently shadows a same-named project skill** — global
  skill names (spec, mvp-scope, new-product, update-stack, release-notes)
  are reserved.

## 2. What each piece is

- **`template/CLAUDE.md`** — the rules every session and thread reads when it
  starts. `[STACK]` slots are filled per product.
- **`template/.claude/hooks/verify.sh`** — THE battery, one source of truth
  for "green". CI runs the same file; that CI run is the required check that
  gates every merge. Unconfigured, it exits 1 by design.
- **`template/.github/workflows/ci.yml`** — runs `verify.sh`, nothing else.
  Its `[STACK]` setup steps are the same commands the product's cloud
  environment setup script runs, so a thread and CI verify on the same
  footing. A surface that builds only on another OS (a native iOS app) gets
  its own job on that OS, also required: a Linux thread cannot run it and
  says so in the pull request body — "not run here" — never "passing".
  The same holds for a step that needs containers: a hosted thread has no
  Docker daemon, CI does, and CI's run is the required check. The
  environment's setup script starts in the clone's parent directory
  (`cd <repo>` first), and a change to it is tested with a new thread — a
  resumed thread keeps its old container.
- **`template/docs/project-instructions.md`** — the source text for the
  Claude Code project's instructions field. The pasted copy in the web UI is
  a copy; this file is the original, and `/update-stack` reports when a port
  changes it.
- **`template/.claude/agents/evaluator-qa.md`** — the one agent: a
  fresh-context judge that collects its own evidence. It runs before a
  pull request only when the item's done-when clause names a screenshot or
  manual check as its verification — the ROADMAP decides, not the thread —
  and at a release over every item done since the last one. Code review is not an agent
  here: the project's review thread runs the built-in `/code-review
  --comment`, and being a separate session it starts with nothing of the
  author's to inherit.
- **`template/.claude/skills/deploy-checklist/`** — the owner's pre-deploy
  walk: generic gates (clean tree, CI green on this commit, no secrets
  in the range, reversible migrations, release notes exist, `evaluator-qa`
  over every item done since the last deploy), then the product's own
  steps in a `[STACK]` slot. Threads never deploy: the owner runs this in
  a LOCAL Claude Code session, and the deploy commands run on that
  machine, with credentials that exist nowhere else. The release tag is
  pushed after the deploy; an iOS surface is archived from it by Xcode
  Cloud.
- **`template/docs/`** — PRD, ROADMAP, NOTES, ADR skeleton. The repo is the
  memory.

A native iOS surface is archived by Xcode Cloud on the release tag and
distributed through TestFlight; nothing else builds. Xcode stays on the
Mac as the faster path for a cabled phone.

There is no preview URL (owner decision, 2026-09-23; it replaced a day of
preview workflows built on 2026-09-21 — the ledger has both). A thread
runs the web surface in its container, drives it with `evaluator-qa` and
puts screenshots in the pull request; a native mobile screen cannot be
driven there, so its clause is a `manual check`. When the owner wants to
try a change himself he brings it up from a local session — web and iOS
simulator — before merging. Projects develop; looking is local.

Enforcement is not in this repo. It lives on GitHub: `main` protected, pull
request required, the `verify` check required, branches must be up to
date before they merge. A hook can be argued with; a required check
cannot. Deploys sit outside GitHub altogether: they run from the owner's
local session with credentials no thread and no workflow holds — a thread
cannot deploy what it cannot authenticate to.

## 3. Update routine

Monthly, or when a model releases: run `/update-stack`. It checks the
marketplace, diffs Anthropic news + engineering + the Claude Code changelog
+ the docs index against its state file, harvests product improvements,
reports ports, and never installs. Adopt changes in this order: edit maya
first → CHANGELOG entry → products pull when `/update-stack` flags their
`.maya-version` behind.

On a model release it also proposes ONE template rule to drop. Rules encode
assumptions about what the model could not do on its own; assumptions
expire. Record every removal in CHANGELOG.md with its reason.

Updating individual pieces:
- Global skills: edit in maya, `git pull` elsewhere — symlinks pick changes
  up instantly. Global CLAUDE.md is COPIED, so re-run `./install.sh` after
  editing it.
- Template: edit in maya; products adopt via `/update-stack` (their
  `.maya-version` names the base commit).

## 4. Integrating an EXISTING product (brownfield)

Principles: **minimal merge** — never replace a working setup; **no second
tool for the same job**.

1. Read the product's CLAUDE.md and conventions FIRST. If the repo has an
   `AGENTS.md` and no CLAUDE.md, merge its rules into the CLAUDE.md you add:
   Claude Code reads AGENTS.md only when CLAUDE.md is absent, so adding
   ours would silently shadow it.
2. Make `verify.sh` the SINGLE implementation of whatever battery the
   product already documents — if a rival command exists, rewire it to call
   the script.
3. Add the CI workflow that runs `verify.sh`, and confirm it is green before
   making it required. Give the product's cloud environment a setup script
   with the same install steps.
4. Protect `main`: pull request required, the `verify` check required, up
   to date before merging.
5. Add `docs/project-instructions.md`, adapted to the product.
6. Add the "Upstream candidates" section to the product's NOTES.md.
7. Write maya's current commit to `.maya-version`. Registering in maya's
   `PRODUCTS.md` is a MAYA write — do it in a maya session, or let the next
   `/update-stack` catch it as "unregistered".
8. Land it as ONE revertible commit so opting out later is a single revert.

## 5. Known version pitfalls (verified 2026-08)

- Docs moved: `docs.claude.com/en/docs/claude-code/*` →
  `code.claude.com/docs/en/*` (index: `code.claude.com/docs/llms.txt`).
- Slash commands merged into skills; `.claude/commands/` still works but
  skills are the recommended form.
- Claude Code projects are in beta on Pro/Max and roll out gradually. This
  harness assumes every product session is a thread of a claude.ai/code
  project; it is not designed for any other mode.

Pitfalls about the Agent SDK, Managed Agents and the MCP spec were dropped
with the harness that needed them; `git log` has them.
