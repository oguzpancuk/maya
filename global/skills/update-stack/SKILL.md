---
name: update-stack
description: Monthly maintenance of the agentic environment — check plugin/marketplace updates, fetch Anthropic news + engineering index + Claude Code changelog, remind about harness ablation when a new model shipped, and flag maya-template impact. Reports only; never auto-installs.
disable-model-invocation: true
---

# /update-stack — keep maya current

State file: `~/.claude/update-stack-state.json`. Read it first; if
missing, treat this as the first run and say so.

## 1. Plugins
`claude plugin marketplace update` (if unavailable, say so and continue),
then list installed plugins. Note unused ones as pruning candidates —
unused plugins still cost context every turn.

## 2. Ecosystem changes since last run
Fetch and diff against the state file. Report each source honestly — a
blocked fetch is "blocked", never silence:
- https://www.anthropic.com/news
- https://www.anthropic.com/engineering
- https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
- https://code.claude.com/docs/llms.txt

## 3. Model check → ablation reminder
If a new Claude model shipped since `last_seen_model`: every harness
component encodes an assumption about what the previous model could not
do. Walk the ablation watchlist (canonical copy: maya CHANGELOG.md) and
propose ONE component to trial-remove first, with how to measure the
result.

## 4. Harvest (products -> maya)
Products = maya's PRODUCTS.md registry + a safety-net scan for
`.maya-version` files under ~/dev. Per product, diff its `.claude/`,
`contracts/` and CLAUDE.md against the maya template at its
`.maya-version`, and read its docs/NOTES.md "upstream candidates".
- Diff source is ALWAYS a fresh `git clone --depth 1` from GitHub into a
  temp dir (existing credentials; never prompt for or store tokens;
  delete the dir after) — never a local checkout. The diff BASE comes
  from the local maya repo.
- The harvest sees only PUSHED state: remind me to push products with
  local-only work before trusting their rows.
- A `.maya-version` repo under ~/dev missing from PRODUCTS.md:
  "unregistered — add it", still harvested from its remote.
- Clone failed: "skipped — <reason>". Unknown is not zero.
- Anything a product improved in template-origin files is an upstream
  candidate: list it with its diff hunk so approved ones land in maya
  (and its CHANGELOG) and every product inherits the fix.

## 4b. Ports (maya -> products)
Template changes flow down via a three-way check per file:
template@(product's .maya-version) vs template@HEAD vs the product file.
- Unmodified in the product: copy the new version, with my approval.
- Deliberately diverged: NEVER clobber — port the change as a patch, or
  record "superseded locally" with one line of why.
- Hybrid files (generic half + [STACK] slots, e.g. deploy-checklist):
  sync generic sections PER HUNK — outside the slots, template@HEAD wins
  unless the product hunk has a NOTES-documented rationale.
- Fill-class files (CLAUDE.md, verify.sh, loop.md, docs skeleton,
  init.sh) diverge by design: port ideas, never bytes.
Apply ports only to a PULLED, CLEAN checkout: `git pull` first, postpone
if `git status --porcelain` is not empty.

**Watermark**: at the run's close — after the approved maya updates are
committed and PUSHED — bump EVERY harvested product's `.maya-version`
(port or no port) to the hash of the newest CHANGELOG entry: "reconciled
through here". Never plain HEAD (entry-less commits aren't addressable
in the ledger); the (→ products) marker only tracks port debt. A stale
base re-flags ported files as product-born. The bump happens ONLY at a
run's close: a maya push outside a run never moves a watermark.

## 4c. Ratchet scan (global -> products)
4b sees only template files, so global rules need their own enforcer.
Every run: check each product's CLAUDE.md — including @-included files —
for lines that LOOSEN the global authority tiers or any other policy
rule. Loosening backed by a NOTES-recorded owner decision = confirmed
divergence; without one = finding. Products may only tighten.

## 5. Weight check
Weigh the ALWAYS-LOADED layer only: global CLAUDE.md lines, global
skills count + description length, installed plugin count (+ context
costs), template CLAUDE.md lines. Compare with the state file. Growth
without a CHANGELOG justification gets a trim proposal; a CLAUDE.md over
200 lines is a finding. Repo size is NOT weight — skill bodies and docs
are free until used.
Also scan for DEAD rules: any product CLAUDE.md line referencing a file,
command, endpoint or service that no longer exists in that repo. Domain
rules expire when the product changes; this scan is what notices.

## 6. Report (never act)
Open with the maya commit (and clone time) analyzed; if origin/main
moved during the run, say so and offer a rerun. Mirror rule for other
sessions: hold maya pushes while a run is active.
Table: change | affects (global / template / a product) | recommendation
(adopt / ignore / trial) | effort. Flag template-impacting items and
products whose watermark is behind. Then STOP: installs, deletions and
template edits happen only after my approval, in the maya repo first.

## 7. Close
Update the state file (date, newest model, changelog version, weights).
Then finish the machine — maintenance commands are never handed back to
the owner:
- Global layer changed (skill, agent, global/CLAUDE.md)? Run
  `bash <maya>/install.sh` yourself.
- A checklist plugin missing? `claude plugin install` WITH approval, per
  instance; report its context cost from `claude plugin details` after.
The owner's one manual step: restarting open sessions so an updated
~/.claude/CLAUDE.md is re-read.
