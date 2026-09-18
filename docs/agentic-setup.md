# Agentic setup — the living manual

What is installed, why, and how it is updated. The research behind the
original choices: `docs/research-notes.md` (Phase 1, 2026-08-27). The
Turkish primer is a private claude.ai artifact:
https://claude.ai/code/artifact/89e20f3f-114d-4df9-983d-dbb71cbc7e1e

## 1. The two layers

| Layer | Lives in | Reaches Claude via | Carries |
|---|---|---|---|
| GLOBAL (me) | `maya/global/` | `./install.sh` symlinks → `~/.claude/` | personal CLAUDE.md, /spec, /mvp-scope, /new-product, /update-stack |
| PRODUCT | `maya/template/`, instantiated by `/new-product` | committed files in each product repo | product CLAUDE.md, `verify.sh`, CI, docs skeleton, project instructions |

Two facts dictate the split:
- **Cloud sessions and project threads ignore `~/.claude/`** — anything a
  thread needs must be committed in the product repo.
- **A personal skill silently shadows a same-named project skill** — global
  skill names (spec, mvp-scope, new-product, update-stack) are reserved.

## 2. What each piece is

- **`template/CLAUDE.md`** — the rules every session and thread reads when it
  starts. `[STACK]` slots are filled per product.
- **`template/.claude/hooks/verify.sh`** — THE battery, one source of truth
  for "green". CI runs the same file; that CI run is the required check that
  gates every merge. Unconfigured, it exits 1 by design.
- **`template/.github/workflows/ci.yml`** — runs `verify.sh`, nothing else.
- **`template/docs/project-instructions.md`** — the source text for the
  Claude Code project's instructions field. The pasted copy in the web UI is
  a copy; this file is the original, and `/update-stack` reports when a port
  changes it.
- **`template/.claude/agents/`** — two fresh-context agents, both defined
  as custom subagents so they start without the author's conversation.
  `code-reviewer` reads a branch's diff cold before a pull request opens
  (outside a project; inside one, the review thread does this).
  `evaluator-qa` collects its own evidence and runs only where the battery
  cannot see the done-when clause (UI behaviour, data state, an external
  service), not on every change.
- **`template/docs/`** — PRD, ROADMAP, NOTES, ADR skeleton. The repo is the
  memory.

Enforcement is not in this repo. It lives on GitHub: `main` protected, pull
request required, `ci` required. A hook can be argued with; a required check
cannot.

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

1. Read the product's CLAUDE.md and conventions FIRST.
2. Make `verify.sh` the SINGLE implementation of whatever battery the
   product already documents — if a rival command exists, rewire it to call
   the script.
3. Add the CI workflow that runs `verify.sh`, and confirm it is green before
   making it required.
4. Protect `main`: pull request required, `ci` required.
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
- Claude Code projects are in beta on Pro/Max and roll out gradually. If a
  product cannot use one yet, cloud sessions and ordinary pull requests
  cover the same ground more manually.

Pitfalls about the Agent SDK, Managed Agents and the MCP spec were dropped
with the harness that needed them; `git log` has them.
