# Research Notes — Agentic Development Environment (Phase 1)

Date: 2026-08-27 · Author: research pass for the "optimal agentic dev environment" mission
Status: Phase 1 deliverable. Phase 2 (architecture proposal) builds on the conclusions here.

## 0. How these notes were produced (read this first)

Ten parallel research agents fetched the assigned sources. This environment's egress
proxy **blocks `anthropic.com` and `claude.com`** (but not `code.claude.com`,
`platform.claude.com`, `github.com`, `registry.modelcontextprotocol.io`), so several
articles were read from verbatim GitHub mirrors and cross-checked against web-search
extracts and official docs. Per-source fetch status:

| # | Source | Status | Read from |
|---|--------|--------|-----------|
| 1 | Building Effective Agents (Dec 2024, lightly revised since) | mirror, full text | 2 GitHub mirrors, verbatim-consistent |
| 2 | Effective Context Engineering (Sep 29, 2025) | mirror, full text | GitHub mirror, matches canonical excerpts word-for-word |
| 3 | Managed Agents (eng. post Apr 2026 + platform docs) | docs full / post second-hand | platform.claude.com + code.claude.com read live; eng. post only via search summaries |
| 4 | Effective Harnesses for Long-Running Agents (Nov 26, 2025) | mirror, full text | GitHub mirror + official companion repo `anthropics/cwc-long-running-agents` |
| 5 | Harness Design for Long-Running App Dev (Mar 24, 2026) | mirror + research note | GitHub mirrors; substance confirmed |
| 6 | "3 Patterns" + "Getting started with loops" | partially, via docs | live `code.claude.com` docs on /goal & /loop + search extracts of the blog posts |
| 7 | awesome-harness-engineering | direct (condensed fetches) | github.com/ai-boost/awesome-harness-engineering (~3.8k stars) |
| 8 | Building Agents with the Claude Agent SDK (Sep 2025) | mirror, full text | web-clipper capture + live migration guide/overview docs |
| 9 | Claude Code docs (memory/skills/subagents/hooks/plugins/MCP) | **direct, full** | code.claude.com/docs/en/* (docs moved there; all 7 pages read live) |
| 10 | MCP spec | **direct (repo)** | official spec repo @ commit d8fdc88 + blog.modelcontextprotocol.io |
| 11 | claude.com/plugins directory | backing catalog, live | `anthropics/claude-plugins-official` marketplace.json (289 plugins, counted 2026-08-27) |

Honest-signal rule applied throughout. Second-hand or partial material, marked as
such where used: the Managed Agents *engineering post's* internals (search summaries
only); the two claude.com blog posts' own text in §1.6 (reconstructed from multiple
mutually-corroborating search extracts — the `/goal` and `/loop` *mechanics* there come
from fully-read official docs pages); and the awesome-harness README (read directly but
via condensing fetches). Everything else was read in full from primary or
verbatim-mirror sources.

### Corrections to the mission brief (verified discrepancies)

1. **Managed Agents is not the successor to "Building Effective Agents".** Nothing
   first-party supports that framing. The Agent SDK docs call Managed Agents
   "a separate product from the Agent SDK. Anthropic runs the agent and the sandbox" —
   it is a *deployment target* (hosted harness + sandbox as a REST API, beta since
   Apr 2026), not replacement design guidance. The design-guidance lineage continues
   through the harness/loops articles instead.
2. **"Agent Harness Design: 3 Patterns" and "Getting started with loops" live on
   `claude.com/blog`**, not the anthropic.com/engineering index
   (`/blog/harnessing-claudes-intelligence`, `/blog/getting-started-with-loops`).
3. **MCP spec revision 2026-07-28 is real and is the latest stable** — verified in the
   official spec repo's versioned tree. It is the largest revision since launch
   (stateless core). Details in §1.10.
4. **The "$200/mo Agent SDK credit" could not be corroborated** in any doc read (the
   SDK blog and docs say nothing about Max-plan credits). Verify in the Console before
   budgeting harness runs around it. Cost math below marks where it assumed this.
5. **Slash commands no longer exist as a separate concept** — the docs state custom
   commands are merged into skills (`.claude/commands/` still works; skills are
   recommended). Phase 4's "/update-stack skill or slash command" is therefore one
   artifact, not a choice.
6. Docs URLs in the brief have moved: `docs.claude.com/en/docs/claude-code/*` →
   `code.claude.com/docs/en/*`; machine-readable index at `code.claude.com/docs/llms.txt`.

---

## 1. Source digests

### 1.1 Building Effective Agents (Dec 2024; revised)

The design constitution. Key content:

- **Taxonomy**: *workflows* = LLMs+tools orchestrated through predefined code paths;
  *agents* = LLMs dynamically direct their own process and tool use. Agents are the
  escalation, not the default: "for many applications, optimizing single LLM calls with
  retrieval and in-context examples is usually enough."
- **Prime directive**: "The most successful implementations weren't using complex
  frameworks… they were building with simple, composable patterns." Add complexity only
  when it demonstrably improves measured outcomes.
- **Framework advice**: start with the API/SDK directly; frameworks obscure prompts and
  hinder debugging; reduce abstraction on the way to production. (Current revision names
  Claude Agent SDK, AWS Strands, Rivet, Vellum.)
- **Building block**: the *augmented LLM* (retrieval + tools + memory).
- **Five workflow patterns** with when-to-use tests:
  1. *Prompt chaining* — fixed decomposition, programmatic gates between steps.
  2. *Routing* — classify then dispatch (cheap model for easy inputs, strong for hard).
  3. *Parallelization* — sectioning (independent subtasks) and voting (same task, many
     perspectives, e.g. multi-prompt security review).
  4. *Orchestrator-workers* — orchestrator decomposes per input, delegates, synthesizes
     (the shape of this repo's lead+teammates factory).
  5. *Evaluator-optimizer* — generator + evaluator loop when clear criteria exist.
- **Agents**: "typically just LLMs using tools based on environmental feedback in a
  loop"; need ground truth from the environment each step, checkpoints, and explicit
  stopping conditions (e.g. max iterations).
- **Appendix 2 (ACI)**: tool design deserves prompt-engineering attention — model-friendly
  formats (markdown over escaped JSON), docstring-quality tool descriptions, poka-yoke
  arguments (absolute paths eliminated a whole SWE-bench error class). "We spent more
  time optimizing our tools than the overall prompt."

### 1.2 Effective Context Engineering for AI Agents (Sep 29, 2025)

- Context is a **finite resource**: "context rot" — recall degrades as tokens grow, in
  every model. Goal: "the smallest possible set of high-signal tokens that maximize the
  likelihood of some desired outcome."
- **System prompts at the "right altitude"**: between brittle hardcoded if-else logic and
  vague guidance; minimal ≠ short — minimal = fully outlines expected behavior. Start
  minimal on the best model; grow only from observed failure modes.
- **Tools**: self-contained, token-efficient, unambiguous params; the #1 failure mode is
  bloated, overlapping tool sets.
- **Just-in-time retrieval beats pre-loading**: keep lightweight identifiers (paths,
  queries), load via tools at runtime; folder structure and naming are free steering.
  Claude Code's hybrid: CLAUDE.md pre-loaded, everything else glob/grep on demand.
- **Long-horizon techniques**: (1) compaction — summarize + reinitiate window (tune for
  recall first); lightest form is tool-result clearing; (2) structured note-taking —
  NOTES.md / to-do lists persisted outside the window (this is exactly this repo's
  repo-as-source-of-truth rule); (3) sub-agents — deep work in clean windows, return
  1,000–2,000-token summaries.
- Selection heuristic: compaction for long back-and-forth; note-taking for milestone
  work; multi-agent for parallel research.
- API mechanics (companion cookbook): `compact_20260112` (server-side, default trigger
  150K), `clear_tool_uses_20250919` (mechanical, cheap), `memory_20250818` (file store).

### 1.3 Managed Agents (beta Apr 2026)

What it actually is: a **hosted agent harness + managed sandbox as a REST API**
(`/v1/agents`, `/v1/environments`, `/v1/sessions`, SSE events; beta header
`managed-agents-2026-04-01`; `ant` CLI). Anthropic runs the loop, compaction, caching,
sandbox provisioning, event-log persistence/resume, retries, OAuth vaults. You define
Agent (versioned config), Environment, Sessions, and custom client-side tools.

- **Positioning (first-party, verbatim)**: "Hosted REST API, a separate product from the
  Agent SDK. Anthropic runs the agent and the sandbox" — for long-running/async agents
  without building your own infra. Not a successor to the SDK or to design guidance.
- **Pricing (official)**: standard token rates + **$0.08/session-hour**, metered per ms,
  accruing only while `running` (idle is free). Session budgets (`budget_reached` stop
  reason) give hard per-run spend caps. Not ZDR/HIPAA-eligible (server-side state).
- **The portability headline for us**: Managed Agents consumes the **identical
  `SKILL.md` format** and auto-discovers `.claude/skills/<name>/SKILL.md` from a mounted
  GitHub repo — the exact Claude Code project layout. Skills written once for dev-time
  Claude Code are directly loadable by a hosted production agent later. Zero rework.
- Extras: scheduled deployments (cron agents), multiagent orchestration, outcomes with
  grading rubrics, memory stores, self-hosted sandboxes ("your hands, Anthropic's brain").
- Engineering post (second-hand): stateless harness replays a durable append-only session
  log; every tool is `execute(name, input) → string`; sandboxes are "cattle, not pets".
- **Billing**: API-key (Console), separate from Max subscription; third-party products
  may not piggyback claude.ai login/limits.

### 1.4 Effective Harnesses for Long-Running Agents (Nov 26, 2025)

The blueprint for unattended work. Problem: sessions have no memory of prior sessions;
compaction alone is insufficient. Solution — a two-agent harness proven on a 200+-feature
claude.ai clone:

- **Initializer agent** (runs once): expands spec into `feature_list.json`
  (`{category, description, steps[], passes:false}`), writes `init.sh` (boot dev server +
  basic e2e), `claude-progress.txt`, initial git commit.
- **Coding agent** (woken repeatedly): read git log + progress + feature list → pick ONE
  unfinished feature → implement → **verify end-to-end in the browser** (Puppeteer MCP,
  "as a human user would") → commit → update progress. One-feature-per-session is the
  critical constraint (prevents one-shotting and false "done" declarations).
- JSON over Markdown for the feature list ("less likely to inappropriately change or
  overwrite JSON files"); agents may only flip `passes`; "It is unacceptable to remove
  or edit tests."
- Four failure modes → mechanisms: early victory declaration → feature list; broken repo
  state → git + progress notes; premature `passes:true` → mandatory browser verification;
  setup waste → init.sh.
- **Official companion repo `anthropics/cwc-long-running-agents`** (Apache-2.0, "example
  ingredients, not a turnkey harness") ships this as plain Claude Code config:
  default-FAIL contract + PreToolUse evidence gate ("the agent can't claim success it
  hasn't observed" — a hook denies writes to results unless evidence was Read first),
  fresh-context evaluator subagent (no Write/Edit; returns PASS/NEEDS_WORK), PROGRESS.md
  handoff + commit-on-stop, kill-switch (AGENT_STOP file), STEER.md. Execution: built-in
  `/goal` first, bash `while` loop over `claude -p` second.

### 1.5 Harness Design for Long-Running App Dev (Mar 24, 2026) — planner/generator/evaluator

- Three-agent harness on the Agent SDK: **Planner** (1–4-sentence prompt → ambitious
  spec), **Generator** (builds in git-committed sprints), **Evaluator** (skeptical,
  GAN-inspired; drives the *running* app via Playwright MCP, grades against a
  few-shot-calibrated rubric — design quality / originality / craft / functionality —
  files structured bug reports with file paths + repro steps that seed the next round).
  Generator and Evaluator negotiate "sprint contracts" (deliverables + testable pass/fail
  criteria) before coding.
- Why the split: **self-grading bias** — "agents reliably praise their own work";
  separating builder from judge is "a strong lever". Also documented: "context anxiety"
  (premature wrap-up near perceived limits; full resets + structured handoffs beat
  in-place compaction on Sonnet/Opus 4.5 — mirror sources conflict on which model).
- **Measured costs**: retro game maker solo run 20 min/$9 (broken) vs full Opus 4.5
  harness 6 h/$200 (feature-complete); browser DAW on slimmed Opus 4.6 harness
  3 h 50 min/**$124.70** (planner alone: $0.46; QA rounds $3–4 each).
- **The repricing thesis (central to our maintenance routine)**: "every component in a
  harness encodes an assumption about what the model can't do on its own, and those
  assumptions are worth stress testing." When Opus 4.6 shipped, Anthropic **deleted
  sprint decomposition and context resets**, moved the evaluator to a single end-pass —
  but **kept the planner** (under-scoping persisted). "The evaluator is not a fixed
  yes-or-no decision. It is worth the cost when the task sits beyond what the current
  model does reliably solo." Deletion is a feature; re-test scaffolding every release.

### 1.6 "3 Patterns" + "Getting started with loops" (claude.com/blog, ~Apr & Jun/Jul 2026)

- **Three harness patterns** (Lance Martin): (1) *use what Claude already knows* — build
  on bash, filesystems, standard CLIs, not bespoke abstractions; (2) *ask "what can I
  stop doing?"* — prune scaffolding as models improve; (3) *carefully set boundaries* —
  the harness enforces UX/cost/safety limits the model shouldn't self-police.
- **Loop taxonomy**: turn-based → skill-based (verification encoded as a skill, e.g.
  /code-review) → goal-based (`/goal`: you define done; a second small model judges every
  turn) → scheduled/proactive (`/loop`, cloud routines; runs until turned off).
- **`/goal` mechanics** (docs read in full): wraps a session-scoped prompt-based Stop
  hook judged by Haiku (met / not-yet / impossible); 4,000-char conditions; bound with
  "or stop after 20 turns"; anti-spin guard; works headless (`claude -p "/goal …"`).
  Good conditions name one measurable end state + the check ("npm test exits 0", "git
  status clean") + constraints ("no other test file modified").
- **`/loop` mechanics**: `/loop 5m <prompt>` fixed interval; self-paced variant; bare
  `/loop` runs a maintenance prompt overridable via `.claude/loop.md` (project) then
  `~/.claude/loop.md` (user) — note the project-overrides-global precedence, same shape
  as our two-layer plan. Cron under the hood; 7-day expiry; 50-task cap.
- **SDK loop budgets**: `maxTurns`, `maxBudgetUsd` (subagent spend counts), effort
  levels, result subtypes `error_max_turns`/`error_max_budget_usd` — the hard stop
  conditions for any unattended run.
- Boris Cherny datapoint (per `cocodedk/loop-engineering`'s fact-check of Cherny's own
  posts; not independently verified here): 259 PRs/~40k lines in 30 days, all via
  Claude Code — his rule: every caught mistake gets written into CLAUDE.md or a skill,
  "then Claude can just run forever."

### 1.7 awesome-harness-engineering (read directly)

Real, active (~3.8k stars). Mostly enterprise/research weight we should skip; the
high-signal section for us is **Templates**. Five picks worth studying as prior art for
our two-layer design (study file layouts, don't adopt frameworks):

1. `obra/superpowers` — mature cross-harness global skills layer with auto-triggered
   mandatory skills.
2. `codejunkie99/agentic-stack` — portable `.agent/` folder + adapters rendering to
   CLAUDE.md etc.; a concrete global/project split implementation.
3. `addyosmani/agent-skills` — 24 lifecycle skills (/spec → /ship) as slash commands.
4. `mininfold-ai/Trellis` — progressive specs instead of one bloated CLAUDE.md.
5. `wshobson/agents` — one source-of-truth plugins/ dir generating per-harness
   artifacts; the maintenance pattern for sharing config across many repos.

Context-efficiency MCP tools (context7, headroom, token-savior) → trial only when token
cost becomes a *measured* problem.

### 1.8 Building Agents with the Claude Agent SDK (Sep 2025)

- Rename rationale: Claude Code's harness is general-purpose ("it has begun to power
  almost all of our major agent loops"). Principle: **"give your agents a computer."**
- Canonical loop: **gather context → take action → verify work → repeat.**
- Gather: filesystem as context store; agentic search first, embeddings only if speed
  demands; folder structure is context engineering; subagents for parallel+isolated
  context; auto-compaction.
- Act: custom tools as primary actions; bash as fallback; code generation as the power
  move ("precise, composable, and infinitely reusable"); MCP for integrations.
- **Verify (the reliability lever), descending robustness**: (1) rules-based — lint,
  typecheck (TypeScript > JS because it adds a feedback layer), schema validation;
  (2) visual — screenshot via Playwright MCP; (3) LLM-as-judge — "generally not a very
  robust method", last resort.
- **Version pitfalls (from the live migration guide)**: npm `@anthropic-ai/claude-code` →
  `@anthropic-ai/claude-agent-sdk`; pip `claude-code-sdk` → `claude-agent-sdk`; Python
  `ClaudeCodeOptions` → `ClaudeAgentOptions`; since v0.1.0 the Claude Code system prompt
  is **no longer the default** (pass `systemPrompt: {type:'preset', preset:'claude_code'}`);
  `settingSources` omitted = CLI parity (loads `~/.claude` + project `.claude/` +
  CLAUDE.md), `[]` = isolated (use inside shipped products).
- Licensing: third-party products can't offer claude.ai login/limits — API key required.

### 1.9 Claude Code docs (all read live at code.claude.com)

The mechanism inventory — every global-layer piece has a documented home:

- **Memory**: CLAUDE.md load order managed-policy → user `~/.claude/CLAUDE.md` → project
  `./CLAUDE.md` → `CLAUDE.local.md`, concatenated; subdirectory CLAUDE.md loads lazily.
  Target **<200 lines/file**. `@path` imports (4 hops). **`.claude/rules/*.md`**: modular
  rules; `paths:` glob frontmatter loads them only when matching files are touched;
  `~/.claude/rules/` = user-global; **symlinks explicitly supported** for sharing one
  rule set across projects. Auto memory (on by default) at
  `~/.claude/projects/<project>/memory/`.
- **Skills**: `SKILL.md` progressive disclosure — only descriptions always in context
  (budgeted ~1% of window), body loads on invocation, supporting files on demand; keep
  SKILL.md <500 lines. Frontmatter: `description`, `disable-model-invocation` (for
  side-effect commands), `allowed-tools`, `context: fork` + `agent:`, `paths`, hooks.
  Dynamic injection: `` !`cmd` `` runs shell pre-read. Personal `~/.claude/skills/` vs
  project `.claude/skills/`. **Slash commands are merged into skills.** Precedence trap:
  personal skill silently shadows a same-named project skill.
- **Subagents**: `.claude/agents/*.md` (project) or `~/.claude/agents/` (user);
  frontmatter `name`, `description`, `tools`, `model`, `memory` (persistent per-agent),
  `skills` (preloaded); fresh context window each run; returns only a summary.
- **Hooks**: settings.json (user/project/local, merged) or skill/agent frontmatter;
  ~25 events (PreToolUse, PostToolUse, Stop, SessionStart, SubagentStop, PreCompact…);
  exit 2 = blocking; JSON `permissionDecision allow|deny`. **The docs are blunt:
  CLAUDE.md is advisory; hooks and permission settings are enforcement.**
- **Plugins**: bundle skills/agents/hooks/.mcp.json/LSP behind `.claude-plugin/plugin.json`;
  test with `--plugin-dir`; distribute via marketplaces — **a marketplace can be just a
  GitHub repo** (`/plugin marketplace add owner/repo`); `extraKnownMarketplaces` +
  `enabledPlugins` in a repo's `.claude/settings.json` wire it per project.
- **MCP**: scopes local / project (`.mcp.json`, committed) / user; tool-search deferral
  on by default (MCP tools cost ~nothing until used); `MAX_MCP_OUTPUT_TOKENS` default 25k.
- **Cloud caveat that shapes our design**: cloud/web sessions **ignore `~/.claude/`** —
  anything needed in remote or scheduled runs must be committed to the repo's `.claude/`
  or declared as a repo-level plugin.

### 1.10 MCP spec (2026-07-28 — verified latest)

- Largest revision since launch: **stateless core** — initialize handshake and session
  header removed; every request self-contained (`_meta` carries version/capabilities);
  state = explicit server-minted handles. Mandatory `server/discover` RPC. MRTR replaces
  server-initiated requests (mid-tool-call user input without statefulness).
- Client features Roots/Sampling/Logging deprecated (12-month lifecycle, SEP-2596);
  elicitation remains. Transports: stdio (unchanged shape) + Streamable HTTP hardened.
  Caching first-class (`ttlMs`, `cacheScope`, deterministic tools/list → prompt-cache
  hits). OAuth hardening; DCR deprecated for CIMD.
- Official registry: still **preview** — treat as marketing, not infrastructure.
- Practical rule: use official Tier-1 SDKs (TS/Python updated day one), pin versions,
  never hand-roll the protocol; product-facing MCP servers can now be plain stateless
  serverless endpoints — the zero-ops profile a solo dev needs.

### 1.11 Plugin directory (counted from the live catalog, 2026-08-27)

- 289 plugins; categories: development 119, productivity 51, database 38, monitoring 20,
  security 18, testing **2** (playwright, growthbook — unit-test QA workflow is a gap we
  fill ourselves). ~39 first-party Anthropic plugins; partner plugins pinned to commit SHAs.
- **Context cost is a first-class UX concern** (per the `discover-plugins` docs page,
  read live — the directory page itself was blocked): the directory shows a per-plugin
  "Context cost" estimate (tokens added *every turn*) pre-install, and a "Not used
  recently" view exists to prune. Plugins run arbitrary code — vet by pinned source repo.
- Strongest first-party candidates for a solo SaaS dev (justification in Phase 2):
  `code-review`, `pr-review-toolkit`, `commit-commands`, `security-guidance` (hook-driven),
  `typescript-lsp` (diagnostics after every edit; needs `typescript-language-server`
  binary), `feature-dev`, meta-helpers (`hookify`, `skill-creator`, `claude-md-management`,
  `agent-sdk-dev`). Stack plugins per product: supabase/vercel/stripe/sentry/github/
  playwright (Microsoft).
- **The marketplace mechanism is the sanctioned substrate for our own reusable layer**:
  a private GitHub repo with `.claude-plugin/marketplace.json` = personal marketplace,
  referenced from every product repo.

---

## 2. The evolution, 2024 → 2026

```
Dec 2024  Building Effective Agents      WHAT to build: workflows vs agents,
                                         5 composable patterns, simplicity, ACI
Sep 2025  Agent SDK release/blog         WITH WHAT: the Claude Code harness as a
                                         library — "give your agents a computer"
Sep 2025  Context Engineering            WHAT GOES IN: attention budget, right
                                         altitude, JIT retrieval, notes, sub-agents
Oct 2025  Agent Skills                   HOW CAPABILITY IS PACKAGED: SKILL.md,
                                         progressive disclosure
Nov 2025  Effective Harnesses            HOW TO RUN LONG: initializer/coding agent,
                                         feature_list.json, evidence gates
Jan–Mar 2026  Evals + Harness Design     HOW TO JUDGE: demystifying evals;
                                         planner/generator/evaluator; the repricing
                                         thesis (delete scaffolding every release)
Apr 2026  3 Patterns / Managed Agents    WHERE IT RUNS: thin harness principles;
                                         hosted runtime (brain/hands decoupled)
Jun 2026  Loops                          HOW IT KEEPS RUNNING: turn → skill → goal
                                         → scheduled loops, stop conditions
Jul 2026  MCP 2026-07-28                 HOW TOOLS FEDERATE: stateless, cacheable
```

The through-line: **the guidance never got more complex — the infrastructure did.**
Design advice stayed "simple, composable, verify with ground truth, delete what the
model no longer needs"; what changed is that the loop, the sandbox, the packaging
(skills/plugins) and the protocol (MCP) became commodity layers you configure rather
than build. Managed Agents is the current endpoint of that *infrastructure* line, not a
new design philosophy — and it consumes the same SKILL.md files Claude Code does, which
is why investing in the skills/config layer is the safest long-term bet.

## 3. Build options for MY use case

| Option | What it is | Fits my case | Cost profile | Verdict |
|---|---|---|---|---|
| (a) Claude Code interactive + plugins/skills/hooks | Daily driver; two-layer config (`~/.claude` + repo `.claude/`) | Dev-time work on pati + every future product; covered by Max 20x | Subscription; context cost per plugin is the currency to watch | **Primary — adopt now** |
| (a+) Built-in loop primitives (`/goal`, `/loop`, evaluator subagent) | The harness patterns, already shipped inside (a) | Unattended feature runs, PR babysitting, nightly QA — without writing a custom loop | Same subscription; `or stop after N turns` bounds runs | **Adopt now, before any custom harness** |
| (b) Custom harness via Agent SDK | The same loop as a Python/TS library (`query()`, hooks, `maxBudgetUsd`) | Overnight autonomous builds (planner/generator/evaluator); measured: $9–$200/run depending on depth | API-key metered; **verify the $200/mo credit claim first** | **Secondary — one experiment per product, only where (a+) measurably falls short** |
| (c) Managed Agents | Hosted harness+sandbox REST API (beta) | NOT for dev workflow. For agents shipped *inside* a SaaS later (pati triage bot, scheduled jobs) | Tokens + $0.08/session-hour; hard per-session budgets; API-key | **Defer — product runtime, revisit when a product needs an in-app agent** |

**Recommendation: (a) + (a+) as the standard environment, (b) as a bounded experiment
lane, (c) deferred to product runtime.** This matches the Agent SDK overview docs' own comparison table (read live; quoted in §1.3)
and the "start with the simplest thing that works" rule. The critical insight from the
research: the built-in primitives (/goal, /loop, subagents, hooks, skills) already
implement every pattern in sources 1–6 — a custom SDK harness is justified only when a
measured gap appears (e.g. a full-app overnight build with browser-verified QA), and
`anthropics/cwc-long-running-agents` provides the copyable ingredients when it does.

## 4. Patterns that apply to my situation

**Directly adopted (global layer):**
- *Gather → act → verify* as the loop policy; **verification ladder**: rules-based first
  (typecheck, lint, tests, zod), visual second (Playwright screenshots), LLM-judge last.
- *Evaluator separation*: never let the builder grade its own work — a fresh-context
  reviewer/QA subagent (this repo's reviewer role is exactly this; keep it).
- *Evidence-gated done*: default-FAIL feature contracts (JSON, agent may only flip
  `passes`), PreToolUse evidence gates for unattended runs.
- *Repo as memory*: status/backlog/ADR files + progress notes = structured note-taking;
  survives compaction and session resets; costs only discipline.
- *One-feature-per-session* for unattended work; explicit stopping conditions on every
  task (already an immutable rule in this repo's CLAUDE.md).
- *Context economy*: <200-line CLAUDE.md at the right altitude; skills for on-demand
  depth; `paths:`-scoped rules; JIT retrieval over pre-loading; folder-naming as free
  steering across all products.
- *ACI investment*: docstring-quality tool/skill descriptions, poka-yoke args.
- *Boris Cherny's rule*: every corrected mistake gets written into CLAUDE.md or a skill —
  fixes must compound across products.

**Planner/generator/evaluator as my standard product workflow — verdict: adopt the
roles, not the ceremony.** The three roles map onto: planner = spec/MVP-scoping skill
(kept even on Opus 4.6 — under-scoping persists across model generations); generator =
normal Claude Code sessions under one-feature-per-session + gates; evaluator = skeptical
fresh-context QA subagent with Playwright and a pass/fail rubric, invoked *when the task
sits beyond what the current model does reliably solo*. The full three-agent SDK harness
is the experiment lane (option b), not the daily workflow. **Ablation ritual**: on every
model release, re-test one harness component at a time and delete what the model no
longer needs — Anthropic deleted sprint decomposition when Opus 4.6 shipped. Deletion
is a feature; the maintenance routine (Phase 4) must schedule it.

**Explicitly not adopted:** agent frameworks (LangGraph et al.), embedding search for
code (agentic search suffices at our scale), memory-graph/enterprise-governance patterns,
context-efficiency MCP tools (until token cost is a *measured* problem), LLM-as-judge as
a primary gate.

## 5. The two layers

| Piece | GLOBAL (reusable, every product) | PROJECT (per product) |
|---|---|---|
| Constitution | `~/.claude/CLAUDE.md` — my conventions, loop policy, verification ladder (<200 lines) | `./CLAUDE.md` — stack, commands, standards, workflow rules (<200 lines) |
| Modular rules | `~/.claude/rules/*.md` (+ symlink pattern for sharing) | `.claude/rules/*.md` with `paths:` scoping |
| Skills | `~/.claude/skills/` — spec-writing, MVP-scoping, release-notes, deploy-checklist, update-stack | `.claude/skills/` — product-specific workflows |
| Subagents | `~/.claude/agents/` — code-reviewer, researcher, docs-writer, evaluator/QA | `.claude/agents/` — stack-specialized roles if needed |
| Hooks | `~/.claude/settings.json` — universal guards | `.claude/settings.json` — lint/typecheck/test wiring for this stack |
| Plugins | user-scope installs (first-party workflow plugins) | project-scope stack plugins (`.claude/settings.json` `enabledPlugins`) |
| MCP | user scope only for universal servers | `.mcp.json` committed (stack servers) |
| Harness | loop policy, /goal condition templates, `~/.claude/loop.md` | `.claude/loop.md`, feature-contract templates, init.sh pattern |
| Packaging | **private marketplace repo** (`.claude-plugin/marketplace.json`) + starter template repo | instantiated from the template |

Three researched constraints that shape Phase 2:
1. **Cloud sessions ignore `~/.claude/`** → the template must commit everything a remote
   or scheduled session needs into the repo's `.claude/`; the global layer is for local
   interactive work, and its durable form is a *repo* (template + marketplace), not a
   home directory.
2. **CLAUDE.md is advisory; hooks are enforcement** → anything that must always happen
   (lint on edit, test before commit, board-format guards) is a hook, not prose.
3. **Skills are the portable unit** across Claude Code → Agent SDK → Managed Agents →
   invest there first; a personal skill silently shadows a same-named project skill, so
   namespace global skills distinctly.

## 6. Open questions for Phase 2

1. Template/global-layer repo name (owner picked English; shortlist: keel / anvil / forge).
2. pati's concrete stack (hosting, DB, payments?) → decides project-scope plugin + MCP picks.
3. Verify the $200/mo Agent SDK credit in the Console (nothing first-party documents it).
4. Where pati development happens (this factory repo's multi-agent flow vs a fresh repo
   from the template) — decides how much of the factory's constitution migrates into the
   template.
5. Local machine access: the global layer (`~/.claude/*`) can only be *documented and
   scripted* from here (install script in the template repo), not written directly —
   this session is a cloud container, not the owner's machine.
