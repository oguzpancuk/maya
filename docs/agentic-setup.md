# Agentic setup — the living manual

What is installed, why, how each piece is updated, and the pitfalls that cost
real time. The research behind every choice: `docs/research-notes.md` (Phase 1,
2026-08-27; moved here from the factory repo's side branch so maya's
foundation lives with maya). The Turkish primer/handbook is a private
claude.ai artifact: https://claude.ai/code/artifact/89e20f3f-114d-4df9-983d-dbb71cbc7e1e

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
- `push-gate.sh` (PreToolUse Bash, 600s timeout): a real `git push`
  invocation (command-position match, `-C`/`-c` covered) requires `verify.sh`
  green; force pushes are blocked outright — run those by hand if truly
  meant. Exit 2 blocks with the failure output; unparseable payloads fail
  closed. CLAUDE.md is advisory — this is the enforcement layer. The
  settings.json deny rules for force-push/rm are prefix-matched best-effort
  only (documented Claude Code behavior); the hook is the real guard.
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
  feature_list.json, one feature per session, per-session evidence gate +
  bash-guard (closes the shell bypass) + AGENT_STOP kill switch, evaluator-qa
  on the final state. All OFF by default.
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
The canonical watchlist lives in CHANGELOG.md (currently: evidence-gate →
evaluator-qa invocation frequency → one-feature-per-session constraint →
push-gate → CLAUDE.md line count).

Updating individual pieces:
- Global skills/agents: edit in maya, `git pull` on other machines —
  symlinks pick changes up instantly (Claude Code hot-reloads skills).
  Global CLAUDE.md: edit in maya, then re-run `./install.sh` — it is COPIED,
  not symlinked, because desktop Cowork sessions skip a symlinked
  `~/.claude/CLAUDE.md`.
- Plugins: auto-update by default; `/plugin` → Installed to review/prune.
- Template: edit in maya; existing products adopt by diffing their `.claude/`
  against `template/` (their `.maya-version` names the base commit).

## 4a. Integrating an EXISTING product (brownfield)

The path pati took (reference: pati commit `e8c6869`). Principles first:
**minimal merge** — never replace a working `.claude/`; **no second tool for
the same job** — check the product's existing skills/agents/commands and
merge on overlap; **every gate tested before the commit lands**.

1. Read the product's CLAUDE.md and conventions FIRST — its rules govern
   how you commit, branch, and name things there.
2. Add the sync-class files from `template/`: hooks (format, push-gate) and
   `contracts/`. Make `verify.sh` the SINGLE implementation of whatever
   verification battery the product already documents — if a /verify-style
   command exists, rewire it to call the script rather than adding a rival.
3. Add `evaluator-qa`, adapted: state explicitly how it differs from the
   product's existing reviewer/QA agents, and what it must hand off instead
   of guessing (e.g. device-only checks).
4. Wire the hooks into `.claude/settings.json` PRESERVING the product's
   existing permissions; add the 600s timeout on the push-gate.
5. Fill the [STACK] slots from the product's real commands; record any
   deliberate divergence from the template with one line of why.
6. Add the "Upstream candidates" section to the product's NOTES.md.
7. Write maya's current commit to `.maya-version` (part of the product's
   integration commit). Registering the product in maya's `PRODUCTS.md` is
   a MAYA write — the integrating product session does not push it (product
   sessions never write to maya): either do it yourself in a maya-context
   session, or simply let the next /update-stack run catch it — an
   unregistered `.maya-version` repo is flagged "unregistered — add it" by
   the harvest's safety net.
8. Test the gates with real cases before committing: a force push must
   block, a red battery must block a push, a non-push command must pass,
   the battery must FAIL honestly where deps are missing.
9. Land it as ONE revertible commit ("Integrate the maya layer: …") so
   opting out later is a single `git revert`.

Expect early friction: template assumptions meet an unknown layout (pati's
prettier lived in a subpackage and the format hook silently no-oped).
That is normal brownfield tax — each such lesson is harvested upstream so
the next integration pays less.

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
