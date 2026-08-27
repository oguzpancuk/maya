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

Products record the maya commit they were instantiated from in `.maya-version`.
Template changes land here first; `/update-stack` flags when a product should
pull them. See CHANGELOG.md.
