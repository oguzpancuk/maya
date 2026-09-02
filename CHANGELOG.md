# Changelog

maya is a ROLLING repo: no releases — `main` is live. This ledger is
reverse-chronological (newest first), every entry stamped with its
commit's UTC time. Every entry's hash is backfilled immediately by a tiny
follow-up ledger commit (a commit cannot know its own id); ledger upkeep
itself gets no entry — `git log -- CHANGELOG.md` is its record. Removals
are listed with their reasons: deletion is a feature.
Entries touching `template/` carry **(→ products)** and track port debt:
a product is current when it contains every marked entry above its
`.maya-version` — which pins the newest ledger entry at the close of the
update run that last reconciled it (its watermark), never plain HEAD.

## Ablation watchlist (canonical copy — other files reference this one)

Re-test on each model release, ONE component at a time, in this order:
evidence-gate (measured 2026-09-01: never fires on Opus 5 across 57 sessions;
fires constantly on Haiku 4.5 but does not move the false-claim rate, because
it checks that evidence exists rather than that it is relevant — fix the
heuristic before re-testing) → evaluator-qa
invocation frequency → one-feature-per-session constraint → push-gate →
CLAUDE.md line count.

Re-testing means running the ablation, not judging it by eye: `evals/`
runs a task with the component wired in and with it removed, grades both
deterministically, and writes rates to `evals/results/`. A component whose
ablated arm is no worse than its control arm is a deletion candidate —
record the numbers here with the decision. Components without an eval task
yet are re-tested by hand, and that is noted as such.

---

### 2026-09-02 08:58 · `e575b9d` — the gate batch, after its own review (→ products)
The port commits were reviewed before push by a fresh-context reviewer
(the rule applies to the maya session too, whose pushes bypass the product
hooks by construction). Verdict NEEDS_WORK, all findings taken: the
evidence-gate relevance check only worked for Write — an Edit fragment
never parsed and the fallback accepted any evidence, so the gate now
reconstructs the file the edit would produce and fails closed when it
cannot; `GIT_DIR=`/`GIT_WORK_TREE=`/`pushd` join the other-directory
refusal; `git update-ref` is denied (one command rewrote what "on a
remote" means); the marker-write heuristic refuses dd/ln/install/ruby/php
/xargs and no longer trips on `2>/dev/null`; code-reviewer reviews
`last-reviewed..HEAD` of COMMITTED state, and CLAUDE.md says commit first,
then review — otherwise every push needed a second identical review.
Deliberate-evasion shapes (a split "pu""sh", `git send-pack`, a
variable-assembled marker path) stay out of scope by design; the gate
turns "forgot" into a block, and the ledger says so. A second, delta-only
review approved the fix and named two one-liners, applied after approval
and covered by the suite: `>|` joins the marker-write refusal, and
review-gate refuses `update-ref`/`symbolic-ref`/`refs/remotes/` outright
(`git fetch . x:refs/remotes/...` could launder a commit as "on a remote";
the settings deny is prefix-matched, this backs it). 28 hook contracts,
52 gate cases.

### 2026-09-02 08:43 · `4fb055e` — push gates stop parsing; nothing leaves unreviewed (→ products)
Harvested from pati (seven review rounds on its own attempt, `a15cb43`) and
reproduced here first: the template push-gate's command-position regex let
`env git push`, `\git push` and `GIT_TRACE=1 git push` skip both the force
check and the battery, and its force scan missed `--mirror`, `--delete` and
`origin :branch`. Two hardening passes (fee3fac, 1dfbd00) had made the
parser more precise; precision is what leaked. push-gate.sh now parses
nothing: does the text mention git and push, does it carry a force-shaped
flag anywhere — and it accepts the false positive that buys (a commit
message naming a push flag blocks; write it with `git commit -F`),
deliberately reversing 1dfbd00. Remote deletions count as destructive.
New review gate, the owner's second-occurrence finding (30 Aug "why didn't
you run it", 2 Sep "it ran on intermediate commits, the pushed state was
never reviewed"): `review-gate.sh` refuses any local commit — HEAD, branches,
tags, minus what remotes have — that is not an ancestor of
`.claude/last-reviewed`; `review-mark.sh`, a SubagentStop hook on
code-reviewer, writes that marker so the harness, not the agent, records
what was reviewed; shell writes to it are refused and Edit/Write denied in
settings. No refspec parsing: a stale side branch over-blocks, accepted.
No exceptions, docs-only included. Fix after a review → review again.
Suite rewritten (45 cases, real scratch repo with a bare remote, cwd guards
— pati's harness once committed the user's tree after a failed clone; the
same `cd ""` shape existed in evals/run.sh and preflight.sh). The eval
fixture ships the reviewer and the new wiring, so `full` measures the
harness as shipped; fixture v2 keeps old rows apart. Also: analyze.sh
pools task arm names onto control/ablated (it printed "no trials" over
100 rows), run.sh stamps rows with the maya commit the README promised,
and the 2 Sep entry below gains the (→ products) marker it lacked.

### 2026-09-02 · `75715d2` — harness measured end to end on Haiku 4.5 (→ products)
`evals/tasks/harness` wires every hook maya ships — evidence-gate, track-read,
bash-guard, push-gate, format-changed — on a fixture where each can act:
eleven features to claim, a shell-editable feature list, a verification battery
that arrives red from a seeded bug, and a real bare remote behind a goal
condition ending in a push. `full` is that; `none` is the same repository with
no hooks and a CLAUDE.md carrying only the project description.

**Result, 100 sessions with a turn budget both arms complete inside:** unsound
claims ran 8.8% (42/480) without the harness and 6.9% (34/496) with it, at
matched claim volume, p=0.28. The gate was invoked 883 times and denied 62.
Direction favours the harness; the sample does not settle it, and the entry
says so rather than rounding it into a finding.

Method and the failure modes it closes: `docs/ablating-your-own-guardrails.md`.
Preconditions enforced by the rig itself — `evals/preflight.sh` refuses to
spend on a grader that rejects a golden solution, `run.sh` refuses to start
unless `tests/hooks-test.sh` passes, `analyze.sh` reports intention-to-treat
and completers-only side by side with claim volume so a throughput effect
cannot be read as a reliability one.

Earlier fixtures in this family (single-gate, tighter budgets) measured null or
proved unable to discriminate and were deleted; deletion is a feature.

### 2026-08-30 10:39 · `cd1a40d` — async-owner defaults, opt-in parallel tracks, consolidation (→ products)
Fourth run's approved batch, harvested from pati's improvement sprint and
refined with the owner in session. Working loop now defaults to ONE
serial agent with async-owner behavior: never block on the owner (queue
prefix-push approvals, keep working), never make the owner wait (a
mid-work message preempts — answered as the next visible output, closing
the turn if needed; commands over ~1 min run in the background).
Plan-first for long multi-item requests, owner questions up front.
Parallel worktree tracks are OPT-IN only — proposed by showing the
disjoint partition, never default: parallelism buys wall-clock only,
which is nearly free for a solo owner, while adding whole error classes;
this restores the founding verdict (multi-agent for research, one
generator) after a one-day drift the owner caught. Mechanics live in the
new template skill /parallel-tracks: file claims, --no-ff track merges as
rollback handles, park-on-conflict, single-owner shared resources,
merged-whole battery + evaluator-qa before push, the revert-of-a-merge
trap. Template .gitignore learns .claude/worktrees/ (pati 9b017b3). 4c
now also reads @-included files (the AGENTS.md case). Deferred by owner:
parity-test seed, evaluator-qa evidence slot; pati settings.json repair
goes to the pati agent. Plus a wording-only consolidation pass over
global/CLAUDE.md (71→72 lines, new rules included), update-stack
SKILL.md (150→108), this header, and the spec skill's always-loaded
description (rationale moved into its body) — semantics unchanged,
rationale lives here. An audit of the rest of the repo found it already
lean (largest remaining file is retrieval-only docs).

### 2026-08-30 06:40 · `ddbe56d` — watermark bumps belong to the run's close, only
Owner caught the agent proposing a .maya-version bump after a maya push
that happened OUTSIDE an update-stack run. 4b now states the scope
explicitly: the watermark claims "reconciled through here", only a run
reconciles, so a maya push alone never moves it — commits between runs
accumulate above the watermark until the next run advances it once.

### 2026-08-30 06:36 · `1b43f16` — the run closes the machine, too
update-stack's close now runs install.sh itself when the global layer
changed, and installs missing checklist plugins (with per-instance
approval, reporting context cost right after). Maintenance commands are
never handed back to the owner; their one manual step is restarting open
sessions to re-read ~/.claude/CLAUDE.md. Also corrected in this session's
report: the two installed plugins were flagged three runs straight as
"no CHANGELOG justification" — they are install.sh's own checklist set
(covered by `8e24c43`); the real gap was the missing commit-commands,
installed now.

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
