---
name: update-stack
description: Monthly maintenance of the agentic environment — check plugin/marketplace updates, fetch Anthropic news + engineering index + Claude Code changelog, remind about trimming rules a new model no longer needs, and flag maya-template impact. Reports only; never auto-installs.
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

## 3. Model check → trim reminder
If a new Claude model shipped since `last_seen_model`: every rule in the
template encodes an assumption about what the previous model could not do
on its own. Re-read `template/CLAUDE.md` and
`template/docs/project-instructions.md` and propose ONE rule to drop —
the one whose absence you would notice least. Deletion is a feature;
record the removal and its reason in CHANGELOG.md.

## 4. Harvest (products -> maya)
Products = maya's PRODUCTS.md registry + a safety-net scan for
`.maya-version` files under ~/dev. Per product, diff its `.claude/`,
`CLAUDE.md` and `docs/project-instructions.md` against the maya template
at its `.maya-version`, and read its docs/NOTES.md "upstream candidates".
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
- Read each product's NOTES.md "Battery gaps" too. A test is product-
  specific; the CLASS of miss is not ("mocked DB passed, real query
  failed"). For each class seen, propose the template rule or `verify.sh`
  pattern that would have caught it, so the next product's battery is
  born without that hole.

## 4b. Ports (maya -> products)
Template changes flow down via a three-way check per file:
template@(product's .maya-version) vs template@HEAD vs the product file.
- Unmodified in the product: copy the new version, with my approval.
- Deliberately diverged: NEVER clobber — port the change as a patch, or
  record "superseded locally" with one line of why.
- Deleted from the template since the product's base: propose deleting
  the product's copy (and any wiring that names it — settings, CLAUDE.md
  lines) if unmodified; if modified, show the diff and ask. Added to the
  template since the base: propose adding it, its [STACK] slots filled
  from what the product already has, TODO where it does not.
- Hybrid files (generic half + [STACK] slots, e.g. ci.yml): sync generic
  sections PER HUNK — outside the slots, template@HEAD wins unless the
  product hunk has a NOTES-documented rationale.
- Fill-class files (CLAUDE.md, verify.sh, docs skeleton,
  project-instructions) diverge by design: port ideas, never bytes.
- If a port changes a product's `docs/project-instructions.md`, say so in
  the report: the copy pasted into that product's project settings is a
  copy, and only I can re-paste it.
Apply ports only to a PULLED, CLEAN checkout: `git pull` first, postpone
if `git status --porcelain` is not empty. Land each product's port as ONE
commit on a branch and open its pull request; never merge it — the owner
does. A first port after a template rewrite lands before the merge gate
is turned on, since the gate's checks arrive with it.

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

## 4d. Merge gate check (GitHub -> products)
The merge gate is a GitHub setting, not a file, so ports cannot carry it.
Every run, for each registered product with a remote: confirm `main` has
all four — direct pushes off, pull request required, every verify job in
`ci.yml` required, branches up to date before merging (the list in /new-product step 9 is
canonical). Read it through the GitHub API where credentials allow;
where they do not, ask me to confirm each product and record the answer.
Any missing condition is a finding, not a note: without it the battery
gates nothing on that product.

## 4e. Xcode Cloud hours (products with an iOS surface)
Read the month's compute usage in App Store Connect against the 25
included hours. Pull-request builds are on request only, so the number
should track how often I asked for one; anything else building on its own
is a finding. Report it — never change the workflow.

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
- Global layer changed (a skill or global/CLAUDE.md)? Run
  `bash <maya>/install.sh` yourself.
The owner's one manual step: restarting open sessions so an updated
~/.claude/CLAUDE.md is re-read.
