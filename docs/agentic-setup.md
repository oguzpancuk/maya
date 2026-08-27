# Agentic setup — the living manual

What is installed, why, how each piece is updated, and the pitfalls that cost
real time. The research behind every choice: `docs/research-notes.md` in the
factory repo (Phase 1, 2026-08-27).

## 1. The two layers

| Layer | Lives in | Reaches Claude via | Carries |
|---|---|---|---|
| GLOBAL (me) | `maya/global/`, versioned here | `./install.sh` symlinks → `~/.claude/` | personal CLAUDE.md, /spec, /mvp-scope, /release-notes, /new-product, /update-stack, researcher agent, user-scope plugins |
| PROJECT (per product) | `maya/template/`, instantiated by `/new-product` | committed `.claude/` in each product repo | project CLAUDE.md, hooks (format, push-gate, verify.sh), code-reviewer + evaluator-qa agents, /deploy-checklist, loop.md, contracts/, CI |

Two researched facts dictate this split:
- **Cloud/remote sessions ignore `~/.claude/`** — anything a remote or
  scheduled session needs must be committed in the product repo. That is why
  the template ships its own agents/hooks even where global twins exist.
- **A personal skill silently shadows a same-named project skill** — global
  skill names (spec, mvp-scope, release-notes, new-product, update-stack) are
  reserved; template skills use different names (deploy-checklist).

## 2. Installed pieces and why

### Plugins (user scope, official marketplace — install once per machine)

| Plugin | Why | Cost note |
|---|---|---|
| `code-review` | multi-agent diff/PR review with confidence filtering; the reviewer I don't have | low — skills defer until invoked |
| `commit-commands` | commit/push/PR hygiene as commands | low |
| `security-guidance` | hook-driven security review (25+ vuln classes) on edits/commits; solo dev's security net | **medium — per-edit hooks; prune via /plugin if unused** |
| `typescript-lsp` | type errors visible to Claude immediately after each edit (TS projects only) | low; needs `npm i -g typescript-language-server typescript` |

Check the real "Context cost" number in `/plugin` before confirming each —
the estimate is shown pre-install. Deliberately NOT installed: overlapping
review plugins (pr-review-toolkit, feature-dev), Playwright plugin (a project
screenshot script is cheaper), stack plugins (no first-party Fly.io plugin;
per-product stacks vary), context-efficiency MCP tools (no measured problem).

### Hooks (template)
- `format-changed.sh` (PostToolUse Edit|Write): formats via the project's own
  prettier if present; always exits 0 — convenience, never a blocker.
- `push-gate.sh` (PreToolUse Bash): `git push` requires `verify.sh` green;
  exit 2 blocks with the failure output. CLAUDE.md is advisory — this is the
  enforcement layer.
- `verify.sh`: THE battery, one source of truth; CI runs the same file.
  `/new-product` must replace its placeholder — an unconfigured verify.sh
  warns loudly on every run.

### Agents
- `researcher` (global): web/repo research with per-source fetch honesty.
- `code-reviewer` (template): read-only severity-ordered review, APPROVE/NEEDS_WORK.
- `evaluator-qa` (template): the skeptical fresh-context judge — builders
  reliably praise their own work; this one collects its own evidence and
  defaults to NEEDS_WORK. Invoke at capability edges, not on every change.

### Harness (template `contracts/` + loop primitives)
- Interactive default: plain sessions + /goal for bounded runs
  (`… — or stop after N turns` always).
- Maintenance: `/loop` with the product's `.claude/loop.md` (one action per
  tick, "quiet tick" allowed, never invents work).
- Unattended runs: `contracts/README.md` pattern — default-FAIL
  feature_list.json, one feature per session, evidence gate + AGENT_STOP kill
  switch, evaluator-qa on the final state. All OFF by default.
- Custom Agent SDK harness: not built. Revisit only when /goal measurably
  falls short; cap any experiment with `maxBudgetUsd`.
- Managed Agents: deferred until a product ships an in-app agent. Skills
  written here port as-is (same SKILL.md format, same `.claude/skills/` path).

## 3. Update routine

Monthly, or when a model releases: run `/update-stack` (global skill). It
checks the marketplace, diffs anthropic.com/news + /engineering + the Claude
Code changelog + docs index against its state file, and reports — it never
installs. Adopt changes in this order: edit maya first → bump CHANGELOG →
products pull template updates when `/update-stack` flags their
`.maya-version` behind.

**Ablation ritual (deletion is a feature).** On every model release, per the
harness-repricing research: pick ONE component from the watchlist
(CHANGELOG.md keeps it current), remove it on a real task, compare. Keep the
removal if quality holds; record either way in CHANGELOG with the evidence.
Current watchlist order: evidence-gate → evaluator-qa frequency →
one-feature-per-session → push-gate → CLAUDE.md line count.

Updating individual pieces:
- Global skills/agents/CLAUDE.md: edit in maya, `git pull` on other machines
  (symlinks pick changes up instantly; Claude Code hot-reloads skills).
- Plugins: auto-update by default; `/plugin` → Installed to review/prune.
- Template: edit in maya; existing products adopt by diffing their `.claude/`
  against `template/` (their `.maya-version` names the base commit).

## 4. Instantiating a new product

Run `/new-product <name>`. It: copies `template/` (dotfiles included),
replaces `{{PRODUCT_NAME}}`/`{{DATE}}`, asks the stack questions in one
batch, fills the CLAUDE.md commands table + `verify.sh` + CI setup, records
`.maya-version`, makes the first commit. Any slot it cannot fill truthfully
stays a visible `[STACK: TODO]`. Then: `/spec` → `/mvp-scope` → first
skeleton step. pati integration follows this same diff-based path when maya
is done (owner decision, deferred).

## 5. Known version pitfalls (verified 2026-08)

- Agent SDK renames: npm `@anthropic-ai/claude-code` →
  `@anthropic-ai/claude-agent-sdk`; pip `claude-code-sdk` → `claude-agent-sdk`;
  Python `ClaudeCodeOptions` → `ClaudeAgentOptions`.
- Since SDK v0.1.0 the Claude Code system prompt is NOT the default — pass
  `systemPrompt: {type:'preset', preset:'claude_code'}` or old tutorials
  silently produce a weaker agent.
- `settingSources`: omitted = CLI parity (loads `~/.claude` + project
  `.claude/`); `[]` = isolated (use inside shipped products). Python SDK
  ≤ 0.1.59 treated `[]` as omitted — upgrade before relying on isolation.
- Docs moved: `docs.claude.com/en/docs/claude-code/*` →
  `code.claude.com/docs/en/*` (index: `code.claude.com/docs/llms.txt`).
- Slash commands merged into skills; `.claude/commands/` still works but
  skills are the recommended form.
- MCP spec 2026-07-28: stateless core; client features Roots/Sampling/Logging
  deprecated (removable from 2027-07-28) — any custom MCP server must not
  depend on them; use current Tier-1 SDKs, pin versions.
- Managed Agents is beta and not ZDR-eligible; bills via API key, separate
  from the Max subscription. The "$200/mo Agent SDK credit" was NOT
  corroborated by any first-party doc — verify in the Console before
  budgeting around it.
