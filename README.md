# maya

A reusable agentic development environment for building SaaS products with
Claude Code. Like a sourdough starter (*maya*), every new product rises from a
piece of it — and the starter itself keeps improving.

One repo, three jobs:

| Directory | What it is | Where it lands |
|---|---|---|
| `global/` | The personal layer: my conventions, cross-product skills and agents | `~/.claude/` via `./install.sh` (symlinks) |
| `template/` | The per-product starter: CLAUDE.md, hooks, agents, docs skeleton, CI, unattended-run contracts | cloned into each new product by `/new-product` |
| `docs/agentic-setup.md` | The living manual: what is installed, why, how to update, known pitfalls | read it |

## What problem this solves

A coding agent is a fast generator with no memory of what it broke last time.
Prompts are advice it may or may not take; the things that must always happen
have to be enforced outside the model. maya is the enforcement layer:

- **Deterministic gates, not prose.** A pre-push gate blocks unapproved
  pushes, an evidence gate rejects claims nothing verified, a verification
  battery runs before work is called done. These are hooks — the model cannot
  talk its way past them.
- **A verification ladder.** Rules-based checks first (typecheck, lint, tests,
  schema), visual confirmation second, LLM judgment last and never alone.
- **Ablation as routine.** Every harness component encodes an assumption about
  what the model cannot do yet. On each model release one component is removed
  and re-tested; what is no longer load-bearing gets deleted, with the reason
  recorded in CHANGELOG.md.
- **Propagation, not copy-paste.** Products are instantiated from `template/`
  and record their origin commit in `.maya-version`. Ledger entries marked
  `(→ products)` are port debt: a product is current when it contains every
  such entry above its watermark.

It is in daily use: see PRODUCTS.md for the products built on it, and
[docs/ablating-your-own-guardrails.md](docs/ablating-your-own-guardrails.md)
for how components here get measured — and deleted.

## Quickstart (on the dev machine)

```bash
git clone git@github.com:oguzpancuk/maya.git ~/dev/maya
cd ~/dev/maya && ./install.sh   # copies CLAUDE.md + links skills/agents into ~/.claude/
# then, inside any Claude Code session, install the approved plugins:
#   /plugin install code-review@claude-plugins-official
#   /plugin install commit-commands@claude-plugins-official
#   /plugin install security-guidance@claude-plugins-official
#   /plugin install typescript-lsp@claude-plugins-official
```

Start a new product: run `/new-product` in Claude Code.
Monthly maintenance: run `/update-stack`.

## Design rules (non-negotiable)

1. **Simple > complex.** Composable pieces over frameworks. Nothing gets added
   without justifying its context-window cost.
2. **Deletion is a feature.** Every harness component encodes an assumption
   about what the model can't do on its own. On every model release,
   `/update-stack` reminds us to re-test one component at a time and delete
   what is no longer load-bearing. Removals go to CHANGELOG.md with reasons.
3. **CLAUDE.md is advisory; hooks are enforcement.** Anything that must always
   happen is a hook, not prose.
4. **Honest signals.** A claim no one verified does not get written down.
   Unknown is not zero; a fetch that failed is reported as failed.
5. **The template is stack-agnostic.** Stack specifics live only in marked
   `[STACK]` slots and `verify.sh`. No product's stack is assumed permanent.

## Versioning

maya is rolling: no releases, no version numbers — `main` is live. Products
record the maya commit they were instantiated from in `.maya-version`.
Template changes land here first; `/update-stack` flags when a product should
pull them. See CHANGELOG.md.
