# maya

A reusable starter for building SaaS products with Claude Code. Like a
sourdough starter (*maya*), every new product rises from a piece of it — and
the starter itself keeps improving.

One repo, three jobs:

| Directory | What it is | Where it lands |
|---|---|---|
| `template/` | The per-product starter: CLAUDE.md, the verification battery, CI, docs skeleton, project instructions | copied into each new product by `/new-product` |
| `global/` | The personal layer: conventions and the four skills | `~/.claude/` via `./install.sh` |
| `PRODUCTS.md` + `/update-stack` | The registry and the monthly harvest that carries improvements between products | run `/update-stack` |

## What problem this solves

Claude Code projects coordinate the work: you describe what needs doing and
threads run in parallel, each on its own branch, each opening a pull request.
What they do not do is create the repository, decide what "done" means, or
carry a lesson learned in one product over to the next. That is maya's job:

- **One battery, one definition of green.** `verify.sh` is the single
  verification script. CI runs the same file, and that CI run is the required
  check on every pull request — so nothing merges unverified. An unconfigured
  battery fails on purpose; a green check on nothing is worse than no check.
- **Every product starts equipped.** `/new-product` copies the template, fills
  the stack slots, sets up the repository and its merge gate, and records the
  maya commit it came from in `.maya-version`.
- **Improvements propagate.** Products are registered in `PRODUCTS.md`;
  `/update-stack` harvests what one product learned and reports which products
  are behind the template. Without it, each product relearns the same lesson.
- **Deletion is a feature.** Nothing stays because it once seemed necessary.
  When a model release makes a rule unnecessary, the rule goes, with the
  reason recorded in CHANGELOG.md.

In daily use: see PRODUCTS.md for the products built on it.

## Quickstart (on the dev machine)

```bash
git clone git@github.com:oguzpancuk/maya.git ~/dev/maya
cd ~/dev/maya && ./install.sh   # copies CLAUDE.md + links the skills into ~/.claude/
```

Installed skills: `/new-product`, `/spec`, `/mvp-scope`, `/update-stack`.

## Starting a product

1. `/new-product` — repository, CLAUDE.md, verify.sh, CI, docs skeleton.
2. Push to GitHub, install the Claude GitHub App, protect `main`: pull request
   required, `ci` required. (`/new-product` walks these.)
3. `/spec` → `docs/PRD.md`, then `/mvp-scope` → `docs/ROADMAP.md`. Commit.
4. Create the project at claude.ai/code, add the repository, and paste
   `docs/project-instructions.md` into Project settings > Memory.

Then the day-to-day is: send work to the project, read the pull requests,
merge. Deploys stay local and manual. Monthly: `/update-stack`.

## Design rules (non-negotiable)

1. **Simple > complex.** Composable pieces over frameworks. Nothing gets added
   without justifying its context-window cost.
2. **Deletion is a feature.** Every rule encodes an assumption about what the
   model cannot do on its own. Assumptions expire; removals go to CHANGELOG.md
   with their reasons.
3. **Enforcement lives outside the model.** Anything that must always happen
   is branch protection and a required check, not a sentence in a prompt.
4. **Honest signals.** A claim no one verified does not get written down.
   Unknown is not zero; a fetch that failed is reported as failed.
5. **The template is stack-agnostic.** Stack specifics live only in marked
   `[STACK]` slots and `verify.sh`.

## Versioning

maya is rolling: no releases, no version numbers — `main` is live. Products
record the maya commit they were instantiated from in `.maya-version`.
Template changes land here first; `/update-stack` flags when a product should
pull them. See CHANGELOG.md.
