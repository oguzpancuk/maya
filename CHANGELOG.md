# Changelog

maya is a ROLLING repo: there are no releases. Whatever is on `main` is
live, and every product pins the exact commit it derives from in its
`.maya-version`. This ledger is reverse-chronological (NEWEST FIRST — the
latest change is always at the top), every entry stamped with its commit's
time in UTC. Removals are listed with their reasons: deletion is a feature,
and the reasons are the evidence. One mechanical note: an entry that lands
in the very commit it describes cannot carry its own hash (a commit cannot
know its own id), so EVERY entry's hash is backfilled immediately — a tiny
follow-up ledger commit in the same session, no exceptions and no
two-class rule. Relatedly, a product's .maya-version is the newest
entry's hash at the end of the update run that last reconciled it — a
run watermark, never plain HEAD — so every base is identifiable here;
the (→ products) marker tracks port debt only. And the ledger's own upkeep
(backfills, reordering, wording) gets NO entry — otherwise every backfill
would need a backfill; `git log -- CHANGELOG.md` is its record.
Entries that touch `template/` — the only zone products inherit — carry the
marker **(→ products)**: a product is current when it contains every marked
entry above its `.maya-version`; unmarked entries never create port debt.

## Ablation watchlist (canonical copy — other files reference this one)

Re-test on each model release, ONE component at a time, in this order:
evidence-gate → evaluator-qa invocation frequency → one-feature-per-session
constraint → push-gate → CLAUDE.md line count.

---

### 2026-08-30 06:23 · `987bea1` — bases are run watermarks
Owner refinement of `8bc0cad`, minutes later: after an update run's
approved maya changes are pushed, EVERY harvested product's .maya-version
(port or no port) bumps to the newest CHANGELOG entry's hash — recording
"reconciled through here", which now covers global rules (4c) and not
just the template. The (→ products) marker is demoted to pure port-debt
tracking.

### 2026-08-30 06:18 · `8bc0cad` — ledger addressability: immediate hashes, marked bases
Owner decision after catching that both products' .maya-version pointed at
`a005446` — a registry docs commit with no ledger entry. Two rules replace
the old two-class backfill: (1) EVERY entry's hash is backfilled
immediately by a tiny follow-up ledger commit, marked or not; (2) 4b bumps
.maya-version to the newest (→ products) commit at port time, never plain
HEAD, so a base is always identifiable here. Both products' bases
repointed to `a72d36a` (same template bytes; only the address changes).

### 2026-08-30 06:03 · `c2919b9` — update-stack learns two blind spots
Second run of the day, both candidates from pati, both aimed at the skill
itself. (1) New step 4c, the ratchet scan: template diffs never see the
global layer, so every run now checks product CLAUDE.md files for lines
that loosen the authority tiers without a NOTES-recorded owner decision.
(2) Step 4b, hybrid files: generic sections sync per hunk (template@HEAD
wins outside [STACK] slots absent a NOTES rationale) instead of falling
into the per-file "diverged → judge" branch that lost the "yayınla"
trigger for a cycle.

### 2026-08-30 05:46 · `c091c7b` — global: authority tiers with a one-way ratchet
Proposed by the pati agent after the push-rule collision: the constitution
had no push policy, pati's "push freely" had filled that gap, and "project
file wins" resolved the surprise silently. The new section names the tiers
(free without asking / ask every time), folds in the push-is-never-implied
line from `007b0a4`, bars unattended runs from the ask tier (park and
report), and lets product files only tighten — loosening requires an owner
decision recorded with rationale in the product's NOTES.md.

### 2026-08-30 05:27 · `007b0a4` — global: push is never implied
Harvested from dealcloser (approved): the agent bundled a push into an
approved commit. Honest signals now states that approval to commit does
not include push; push happens only on an explicit push instruction.

### 2026-08-30 05:27 · `a72d36a` — template: reviewer/QA launches are standing instructions (→ products)
Harvested from pati (second /update-stack run, approved): the builder
session weighed the generic "don't spawn agents unprompted" default above
the project convention and skipped code-reviewer/evaluator-qa until asked.
The Workflow section now names the trigger points — code-reviewer before a
feature is reported done; evaluator-qa before a deploy and at the end of
an unattended run.

### 2026-08-28 09:03 · `8e24c43` — first /update-stack run's approved batch (→ products)
First real monthly cycle, run on the owner's machine. Adopted harvests:
Turkish skill triggers (H1), generalized prettier fallback for multi-package
repos (H2, supersedes the walk-up-only version), verify.sh skeleton rules
in the [STACK] example — attempt-all + deps-missing-is-FAIL (H3), loop.md
local-device handoff bound (H4). install.sh drops the code-review plugin
line (/code-review and /security-review are built into recent CLI).
Coordination lessons from a mid-run maya push (the cloud session's own
mistake): reports stamp the maya commit they analyzed; other sessions hold
maya pushes while a run is active. Related pati fix: `npm run seed` removed
from the allowlist — it contradicted CLAUDE.md's "ask first" for a command
that wipes every table (report's best catch).

### 2026-08-28 08:47–08:56 · `8c2e508` `68db6b5` — ledger format settled
Owner requests: every entry stamped with its commit's real time (UTC,
normalized — two machines commit in different timezones), newest first.
Pure ledger maintenance (backfills like this one) gets no entry of its own;
git log is its record.

### 2026-08-28 08:28–08:34 · `f581856` `e03d207` — housekeeping
install.sh's plugin reminder says why it repeats; hash backfill convention
stated and applied.

### 2026-08-28 08:24 · `d93bd76` — downstream port flow codified
Three-way check (birth template vs new template vs product file);
deliberate divergences never clobbered; fill-class files carry ideas, not
bytes; every port bumps the product's .maya-version so the harvest base
stays true. pati bumped to this base (`d08ee2a` in pati; registry
`3feb26c`).

### 2026-08-28 08:20 · `8f4ead0` — policy: product sessions never write to maya
Found by the owner watching the loop run: the old wording ("apply it to the
maya repo too") let a pati session push straight to maya, skipping the
approval moment. Path is now park → harvest → approve; explicit owner
instruction is the only immediate exception.

### 2026-08-28 08:15 · `e512795` — changelog went rolling (merged `f08d609`)
"Unreleased"/"v0.1.0" implied a release process maya doesn't have: main is
live, products pin commits.

### 2026-08-28 08:05 · `2352bd5` — init.sh.example detaches servers (→ products)
Harvested from pati: plain `nohup … &` stayed in the agent shell tool's
process group — the tool call hung, then killed the server with it. Servers
now start in their own session (setsid).

### 2026-08-28 07:45 · `1dfbd00` — push-gate force check made argument-aware (→ products)
Harvested from pati: the whole-line force regex tripped on a commit message
mentioning "git push -f" — and then blocked the fix attempt itself. Now
tokenizes with shlex, inspects only the push segment's own arguments;
unplaceable `$(...)` pushes fall back to the whole-line scan; unbalanced
quotes fail closed. 18-case suite at tests/push-gate-test.sh.

### 2026-08-28 07:40 · `4299a26` — first harvest from pati (→ products)
format-changed.sh finds the nearest prettier by walking up from the edited
file instead of assuming the repo root (pati: multi-package repo, no root
package.json — the hook silently no-oped).

### 2026-08-28 06:53 · `89c656d` — pati registered
First product on the maya layer (minimal merge: battery, gates,
evaluator-qa, contracts, .maya-version).

### 2026-08-27 11:21 · `3b674a3` — dead-rule scan
Domain-experience rules expire with the product, not the model; the weight
check flags rules whose referents no longer exist.

### 2026-08-27 11:17 · `195f2b2` — recurrence rule
Machine-caught findings (QA/CI/hooks) compound when the same class is
caught twice; one-off bugs stay one-off.

### 2026-08-27 10:53–10:57 · `82b469b` `19ac8fa` `ff03ef2` `eacc923` — harvest machinery
- `82b469b` PRODUCTS.md registry: unreachable products report as "skipped",
  never vanish silently.
- `19ac8fa` harvest can shallow-clone from GitHub with the machine's own
  credentials; `ff03ef2` GitHub state becomes the ONLY diff source (local
  clones can be stale or dirty).
- `eacc923` monthly weight check guards the always-loaded layer against
  bloat; repo size is not weight.

### 2026-08-27 10:50 · `90d61dc` — upstream flow opened (→ products)
Product-born fixes to template-origin files flow back: proposed, or parked
in the product's NOTES.md "upstream candidates" for harvest.
(Tightened on 08-28: product sessions never write to maya directly.)

### 2026-08-27 10:47 · `9a6f7a5` — test infra is the first skeleton step
The battery is born with the walking skeleton, never backfilled; a later
standalone "testing task" is named a planning failure.

### 2026-08-27 10:14 · `fee3fac` — hardening pass (→ products)
From the adversarial scaffold review; 19 attack cases verified.
- push-gate: command-position matching, `-C`/`-c` bypass closed, force
  pushes blocked outright, 600s timeout, fail-closed parsing.
- evidence gate: session-keyed read logs; reading the feature list or
  configs no longer counts as evidence; fails closed without python3.
- new bash-guard: closes the sed/tee/redirect bypass; AGENT_STOP halts Bash.
- settings.json: dead `Grep(**)`/`Glob(**)` rules removed.
- install.sh: CLAUDE.md copied instead of symlinked (desktop Cowork skips a
  symlinked user CLAUDE.md); empty-glob guards.

### 2026-08-27 09:59 · `3c3ad6f` — initial scaffold (→ products)
Built from the Phase 1 research pass (factory repo, docs/research-notes.md).
- `global/`: personal CLAUDE.md; skills /spec, /mvp-scope, /release-notes,
  /new-product, /update-stack; researcher agent; install.sh.
- `template/`: stack-agnostic CLAUDE.md with [STACK] slots; format/push-gate
  hooks + verify.sh single battery; code-reviewer + evaluator-qa agents;
  /deploy-checklist; loop.md; docs skeleton (PRD/ROADMAP/NOTES/ADR); CI
  running verify.sh; unattended-run contracts (off by default).
