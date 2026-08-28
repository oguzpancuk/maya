---
name: update-stack
description: Monthly maintenance of the agentic environment — check plugin/marketplace updates, fetch Anthropic news + engineering index + Claude Code changelog, remind about harness ablation when a new model shipped, and flag maya-template impact. Reports only; never auto-installs.
disable-model-invocation: true
---

# /update-stack — keep maya current

State file: `~/.claude/update-stack-state.json`
(`{"last_run": "...", "last_seen_model": "...", "last_seen_changelog": "..."}`).
Read it first; if missing, treat this as the first run and say so.

## 1. Plugins
- Try `claude plugin marketplace update` non-interactively; if unavailable in
  this context, tell me to run `/plugin marketplace update` and continue.
- List installed plugins and versions if the CLI allows; note any I haven't
  used recently (the /plugin "Not used recently" view) as pruning candidates —
  unused plugins still cost context every turn.

## 2. Ecosystem changes since last run
Fetch and diff against the state file (report each source's fetch status
honestly; a blocked fetch is "blocked", not silence):
- https://www.anthropic.com/news — product/model announcements
- https://www.anthropic.com/engineering — new engineering articles
- https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
  — Claude Code features
- https://code.claude.com/docs/llms.txt — new/moved doc pages

## 3. Model check → ablation reminder
If a new Claude model shipped since `last_seen_model`: remind me that every
harness component encodes an assumption about what the previous model could
not do. Walk the ablation watchlist from maya's CHANGELOG.md (the canonical copy
lives there — read it from ~/dev/maya/CHANGELOG.md, or ask me for the maya
checkout if it's elsewhere) and propose ONE component to trial-remove first,
with how we'd measure the result.

## 4. Harvest downstream improvements (products -> maya)
The flow must run both ways. The product list comes from maya's
`PRODUCTS.md` (the registry /new-product maintains) plus a safety-net scan
for `.maya-version` files under ~/dev/. For each product: if its checkout is
reachable, diff its `.claude/`, `contracts/` and CLAUDE.md against the maya
template AT the commit in its `.maya-version`, and read its docs/NOTES.md
"upstream candidates" section. Diff source per registered product: ALWAYS a fresh fetch from GitHub —
never a local checkout, which may be stale or on a dirty branch. Using MY
existing credentials (`gh` CLI or plain git over SSH — whatever this machine
already uses to push): `git clone --depth 1 <repo-url>` into a temp dir,
diff there, delete the temp dir after. Depth 1 suffices — the diff BASE is
the maya template at the product's `.maya-version` commit, which lives in
the local maya repo. Never prompt for or store tokens.
Consequences to surface in the report:
- The harvest sees only PUSHED state. Remind me to push any product with
  local-only work before trusting its row.
- A `.maya-version`-carrying repo found under ~/dev but missing from
  PRODUCTS.md is reported as "unregistered — add it", and still harvested
  from its remote, not from the local copy.
- Clone failed (no credentials, offline, repo gone)? Report the row as
  "skipped — <reason>"; never let an unreachable product silently disappear
  from the report (unknown is not zero). Anything the product improved
locally — a hardened hook, a better rule, a new skill — is an upstream
candidate: list it in the report with the diff hunk, so approved ones get
applied to maya (and CHANGELOG) and every future product inherits the fix.

## 4b. Downstream ports (maya -> products)
Template changes flow DOWN with a three-way check per product file:
template@(the product's .maya-version) vs template@HEAD vs the product's
current file.
- Unmodified in the product (matches its birth template): copy the new
  version, with my approval.
- Deliberately diverged (a filled [STACK] slot, a product adaptation):
  NEVER clobber — judge whether the template change still applies; port it
  as a patch, or record "superseded locally" with one line of why.
- Fill-class files (CLAUDE.md, verify.sh, loop.md, docs skeleton, init.sh)
  diverge by design: port ideas, never bytes.
After porting, bump the product's .maya-version to the maya commit ported
to — it is the harvest's diff BASE; a stale base re-flags already-ported
files and mistakes ports for product-born improvements.

## 5. Weight check (is maya getting fat?)
Weigh the ALWAYS-LOADED layer — the only part whose growth costs every turn:
global CLAUDE.md line count, number of global skills and total description
length, installed plugin count (with the context costs /plugin shows), and
the template CLAUDE.md line count. Compare against the state file's last
weigh-in. Growth without a matching CHANGELOG justification gets flagged
with a trim proposal; a CLAUDE.md over 200 lines is a finding, not a style
note. Repo size is NOT weight — skill bodies and docs are free until used.
Also scan for DEAD rules: for each product harvested, any CLAUDE.md/rules
line referencing a file, command, endpoint or service that no longer exists
in that repo is stale experience — flag it for removal. Domain rules don't
expire with model releases (that's the ablation watchlist's job); they
expire when the product changes, and this scan is what notices.

## 6. Report (never act)
A table: change | affects (global / template / a product) | recommendation
(adopt / ignore / trial) | effort. Explicitly flag anything that means the
maya template should change so future products inherit the fix — and list
which existing products' `.maya-version` is behind.
Then STOP. Installation, deletion, and template edits happen only after I
approve, in the maya repo first.

## 7. Close
Update the state file with today's date, current newest model, the
changelog version you saw, and this run's weight figures.
