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

---

### 2026-09-21 15:06 · `596facf` — deploys come back to the owner's machine; phone builds only on request (→ products)
Two owner decisions, the same day as the entries they change, made after
the per-pull-request previews were working and the division of labour was
clear: project threads produce pull requests and their previews; the
owner's LOCAL Claude Code session does the releasing.
(1) Deploy commands run on the owner's machine, through `/deploy-checklist`
in a local session. This REVERSES `af030ac` of this morning ("deploys run
in CI on the release tag; the laptop leaves the loop"): `deploy.yml` is
removed from the template, and with it the `production` environment, the
Actions secrets and `/new-product` 9c as it stood. Reason as the owner
gave it: deploy work is run from the local agent, not through projects.
What this buys is a stronger version of "a thread never deploys" than CI
offered — a thread cannot deploy what it cannot authenticate to, and the
credentials now exist in no cloud environment and no repository. What it
gives back is what `af030ac` had bought: a release again needs the laptop,
the CLIs logged in on it, and a rollback is the product's own command
rather than a re-run. In no product had `deploy.yml` ever been configured;
it failed on purpose in all three, so nothing that worked is lost.
The release tag stays: it is pushed AFTER a verified deploy, marks what is
live, and is still what Xcode Cloud archives for an iOS surface
(`96a0dfe` stands). Gate 2 of the checklist (`439898f`: trust CI's green,
not a local battery) stands too — it is about verification, not about
where the deploy runs.
(2) A pull-request build to TestFlight happens only ON REQUEST. This
narrows `c8264ec` ("on, not optional; when the pull request opens plus on
demand"): every product keeps web and iOS in sync, so the web preview is
the normal check and a phone build is the exception the owner asks for. A
thread never triggers one. `/update-stack` 4e now treats any build that
was not asked for as a finding.
Touched: `template/CLAUDE.md` (Preview slot, Deploy), `/deploy-checklist`
(Release steps, product slot), `template/docs/project-instructions.md`,
`/new-product` 9b and 9c, `/update-stack` 4e, the constitution's authority
tier and working loop ("running a deploy"), the manual.

### 2026-09-21 14:51 · `f30853a` — previews: a required check, built by a workflow that a branch cannot rewrite
pati and juno got their per-pull-request previews the same afternoon — Fly
review apps with a database each, and a Cloudflare Worker version per pull
request — and both were verified on real pull requests, from outside the
job. Owner decision: the preview is a REQUIRED check on both, EVERY job of
it (juno's has two; a job skipped by a failed `needs` counts as passing,
so requiring only `upload` would have let a broken build merge). Accepted
cost: a provider outage blocks merges.
What generalises, now in `/new-product` step 3 and step 9 and in the
manual: a preview workflow's token can almost always deploy production, so
it runs as `pull_request_target` from `main` and the job that runs the
pull request's code holds no secrets — the first pati version used plain
`pull_request` with an org-scoped Fly token, which made "a thread never
deploys" a sentence instead of a fact for about an hour; such a workflow
cannot be tested by the pull request that adds it, so a follow-up pull
request is part of the job; third-party actions are pinned to a sha; the
workflow ends by asking the preview itself, and on `closed` removes what
it created, database and role included (the review-apps action leaves
them: 17 MB and a superuser per pull request).
Product-side findings that stay in the products' NOTES: a Fly Postgres
machine needs 1024 MB for `CREATE EXTENSION postgis`; `fly.toml` without
`primary_region` lands in `iad`; wrangler's `preview_urls` is a
non-versioned setting and needs one `wrangler triggers deploy`.
iOS previews were skipped by owner decision: every product keeps web and
iOS in sync, and the web target is the preview.

### 2026-09-21 13:02 · `87a3b12` — three facts about the cloud environment, from the first threads
pati's and juno's first threads, the same afternoon their projects were
created, failed in ways nothing here warned of. `/new-product` step 11 and
the manual now say: the setup script starts in the clone's PARENT directory
(`/home/user`) — both products' scripts died on `cd backend` / a missing
lockfile until they began with `cd <repo>`; a hosted thread has no Docker
daemon — juno's RLS suite needs a local Supabase stack and cannot run
there, so its battery gets the "NOT RUN here" branch `74b083e` introduced
for another OS, with CI's `verify` (which has Docker) as the required run;
and a fixed script is tested with a NEW thread — both resumed threads kept
the container built before the fix and reported "deps missing" against a
script that was already right. The first-thread check is sharpened to
match: the thread is told to install nothing, because one that helpfully
runs `npm ci` hides a setup script that never ran. Cost recorded, not
solved: work under juno's `supabase/` gets its feedback from CI (~5 min a
round), and red-before-green for an RLS test is shown by CI's check
history, not inside the thread; a self-hosted environment with Docker is
the real fix if that loop starts to hurt.

### 2026-09-21 11:00 · `d58cc34` — sixth update run: the battery checks exec bits; registry follows a rename (→ products)
First `/update-stack` run after the Projects rewrite. It began on a local
checkout 54 commits behind `origin/main` — the skill text it was handed was
the old one — so it read `origin/main` without pulling, reported against
`2a89f0d`, and only then fast-forwarded and re-ran `install.sh`.
Adopted from juno's NOTES: `verify.sh`'s pattern gains rule (4), every
tracked `*.sh` keeps its exec bit. An agent's write-then-rename drops the
mode, no content diff shows it, and three commits in five went to putting
one back there; the cause is generic to any repository an agent edits.
Not adopted, with reasons: juno's refusal-test rule — a test that passes
for the wrong reason cannot be seen red first, so `59e9cf3` already
refuses the class; its docs-figures gate (124 lines, found three stale
figures after six review rounds) stays in juno until a second product
carries measured figures in docs; `pod install` locale, the React clock
pattern and `init.sh`'s `CI=1` are juno-local now that iOS archives on
Xcode Cloud and `contracts/` is gone.
Registry: `stardate` was renamed `juno` on GitHub and gained a remote; the
row said neither. `/update-stack` step 7 loses its "checklist plugin"
bullet — `install.sh` has carried no plugin list since `2a53368`.
Findings reported, not fixed here (4d): no product has a protected `main`
or uses pull requests yet, and all three still carry the pre-rewrite
harness; their first ports open as pull requests from this run.

### 2026-09-21 10:20 · `af030ac` — deploys run in CI on the release tag; the laptop leaves the loop (→ products)
The last thing a release needed from the owner's machine was the deploy
command and its credentials. Now `template/.github/workflows/deploy.yml`
runs on a `v*` tag (and by hand with any tag, which is the rollback),
deploys the web and backend surfaces, and is gated by GitHub's
`production` environment with the owner as required reviewer — so a tag
deploys only after a click, wherever the tag came from. Credentials are
Actions secrets, in no cloud environment and on no laptop. Unconfigured,
the job fails on purpose, like `verify.sh`. Xcode Cloud archives iOS on
the same tag: one tag, every surface.

`/deploy-checklist` gains steps 7–8 — push the tag, watch the workflow,
the health check and the TestFlight build — and its product steps say
"nothing here runs on a laptop". `/new-product` 9c sets up the secrets,
the environment and turns off the preview provider's automatic production
deploy from `main`. The authority tier and the project instructions name
"pushing a release tag" as a per-instance ask, so a release thread may
run the checklist but never pushes the tag on its own.

What this settles: the morning's "should a thread deploy" question
without giving a thread anything — the tag is the only hand-made action,
and GitHub asks the owner before it does anything with it. Day to day, a
product now needs the owner's phone: the project, GitHub, TestFlight, a
browser. A laptop remains for `/new-product`, `/spec`, `/mvp-scope` and
`/update-stack`, all movable later.

### 2026-09-21 10:05 · `c8264ec` — iOS pull requests build to TestFlight on open, not on push (→ products)
Owner decision: the pull-request workflow on Xcode Cloud is on, not
optional. Trigger is the pull request opening plus on-demand rebuilds;
never every push, because the review thread pushes until APPROVE and each
push would be a build. The pull request body carries the TestFlight build
number next to the "awaiting the owner's check" items, and the thread
does not trigger rebuilds — the owner asks. `/update-stack` gains 4e:
read the month's Xcode Cloud hours against the 25 included and the number
of builds pull requests caused, and propose on-demand-only if it climbs.
Xcode stays on the Mac for now as the fast path to a cabled phone;
dropping it is decided on those readings, not today.

### 2026-09-21 09:55 · `96a0dfe` — the iOS archive moves to Xcode Cloud (→ products)
The last thing a release needed from the owner's Mac was Xcode, to
archive and upload. Owner decision: the archive is Xcode Cloud's, on the
release tag. `/deploy-checklist`'s product steps say so for an iOS
surface — push the tag, confirm the TestFlight build, open it on a
device; nothing in the checklist needs Xcode. `/new-product` gains step
9b: set up the workflow in App Store Connect (a setting, not a file, like
branch protection) and record it in NOTES.md; optionally build
pull-request branches to TestFlight too, which makes an iOS pull request
tryable on a phone with no Mac at all. The `verify-ios` GitHub Actions job
stays the required check: whether Xcode Cloud reports a status to GitHub
was not verified, and the merge gate is not tied to anything unverified.

### 2026-09-21 09:40 · `74b083e` — a battery step this OS cannot run: "not run here", and a CI job per OS (→ products)
The products have a native iOS surface built with Xcode. A cloud thread is
a Linux VM: it cannot build or test that surface, and the template had one
`ubuntu-latest` job and no word for a step a machine cannot run. Now
`verify.sh` has a third state beside ok and FAIL — "NOT RUN here — <job>
is the run" — which never fails the battery and is never silent; `ci.yml`
shows a job per OS the battery needs, each a required check;
`template/CLAUDE.md` says how a thread reports such a step in the pull
request body, never as passing; `/new-product` requires every verify job
and `/update-stack` checks for all of them. The screen half of this (a
native screen is the owner's manual check) landed two entries ago; this
is the build half.

### 2026-09-21 09:20 · `439898f` — deploy-checklist trusts CI's green, not a local battery (→ products)
Gate 2 ran `verify.sh` locally, which needs the product's deps installed
on the owner's machine — the one thing the new order otherwise never asks
of the laptop. The same fact already exists on GitHub: every commit on
`main` passed the `verify` required check to get there. Gate 2 now reads
that check on the exact commit, and says not to run the battery locally
instead: a local tree can carry deps or state CI does not, and CI's run is
the one the merge gate trusted. A release now needs a checkout and the
deploy commands, nothing else.

### 2026-09-21 09:01 · `b483626` — where a pull request is tried, and what a cloud thread cannot see (→ products)
Nothing in the template said where the owner tries a pull request, and
the QA rules assumed every screen could be driven from a thread. Neither
held for a mobile product: a cloud VM has Chromium and Playwright but no
iOS or Android simulator, so a native screen cannot be driven there, and
the owner had no channel to try a build without a local simulator.

Added: a `Preview` slot in `template/CLAUDE.md` — a preview URL per pull
request for web, an EAS Update channel or TestFlight for mobile — which
`/new-product` asks for with the other stack questions and every pull
request body carries for its own build. `/mvp-scope` now says what the
verification names mean: `screenshot` is a screen a thread can drive (web
or a web target), a native screen is `manual check`, and that check is the
owner's on a device before the merge. Project instructions list such
clauses as awaiting the owner's check, and the thread does not report the
item done. `evaluator-qa` names the native screen as its standing
"unverified, never PASS" case. The environment step notes that web QA
needs nothing installed.

Owner decision the same morning: the preview URL is the rule, not one
option among channels. Every pull request gets one and its body carries
it; a pull request without it is not ready. A mobile product meets the
rule with a web target; a build channel stands in only where no URL is
physically possible. Where the preview provider posts a status check,
`/new-product` requires it alongside `verify`.

Net: code, tests, review and most of QA run in the cloud; the owner tries
every pull request on its preview URL; a native screen's last look is the
owner's. A laptop is required for none of it.

### 2026-09-18 20:05 · `1b7999f` — fit audit against Projects: one gap, three leftovers (→ products)
Missing: every thread runs in a cloud environment whose setup script
installs the stack before Claude starts, and nothing in maya set one up.
`verify.sh` fails on missing deps by design, so a product with `ci.yml`
configured and no environment script would have had every thread red.
`/new-product` now configures the environment with the same install
steps as `ci.yml` and has the owner watch one tiny thread go green before
real work.

Removed: `template/.claude/settings.json` — its allow list means nothing
under auto mode, its denies are branch protection's, auto mode's and
`.gitignore`'s jobs, and it applied only in a single-repository project;
three `.gitignore` entries for deleted components; and two lines in
`global/CLAUDE.md` about unattended local runs, which no longer exist —
a local session does not build features.

Left as is, named so it is not mistaken for an oversight: the battery
still lives at `.claude/hooks/verify.sh` with no hooks beside it. Moving
it would touch CI, CLAUDE.md and three products for a directory name.

### 2026-09-18 19:42 · `4d88502` — QA keyed on the clause, review until APPROVE, rule files trimmed (→ products)
Three changes to the two files every thread loads.

The QA trigger was the author's call: "if the battery cannot cover the
clause, run `evaluator-qa`" left the thread that wrote the code to decide
whether its own claim needed checking. The ROADMAP already names each
clause's verification — `test`, `screenshot` or `manual check`, written
by the owner through `/mvp-scope` at scoping time. The trigger now keys
on that name: screenshot or manual check runs the agent before the pull
request, test does not. The decision moves from the thread at pull
request time to the owner at scoping time, and it is readable in the
ROADMAP.

Review ran once. The review thread commented on the first push and
nothing looked at the fixes; the second eye saw only v1. The review
thread now keeps watching the pull request and reviews each push's delta
the same way until its summary says APPROVE, so what the owner reads
before merging is a verdict on the current head.

`template/CLAUDE.md` and `docs/project-instructions.md` are loaded into
every thread on every turn, and about a third of their sentences were
reasons rather than rules — the reasons belong here. Rewritten to rules
only: 489→422 and 579→369 words, no rule dropped. The eight-line paste
note at the top of the instructions became three.

### 2026-09-18 19:32 · `6ee3735` — the release-time QA pass gets wired (→ products)
`evaluator-qa`'s description has said "and before a release" since it
came back, and nothing called it at a release: `/deploy-checklist` had
five gates and none was it. So the claim that a test-green-but-broken
feature would be caught at release time was not true of the files. Gate
6 now runs the agent over every ROADMAP item marked done since the last
deploy, against the running app; one NEEDS_WORK stops the deploy. In a
pull request the agent runs only where the battery cannot see the clause;
at a release it runs over all of them — the one pass that does.

### 2026-09-18 19:24 · `7aaa38f` — the review thread runs /code-review; code-reviewer goes for good (→ products)
`code-reviewer` came back two entries ago for one property: `/code-review`
runs as a forked subagent and inherits the author's conversation, so a
review started from the author's session is not independent. That holds
in the author's session. It does not hold in the review thread, which is
a separate session with no conversation to inherit — and since the
one-mode decision every review runs there. With independence given by the
wrapper, the choice was method against method, and the built-in wins on
what a repo file cannot supply: Anthropic maintains it, `--comment` posts
findings as inline pull request comments, and effort levels and `ultra`
exist. What the agent file had over it — an explicit verdict, the
done-when and red-run check, never editing — is three lines of the review
thread's task in the project instructions, where they now live.

Removed: `template/.claude/agents/code-reviewer.md`. The restoration was
right under two modes and wrong under one; the ledger keeps both.
`evaluator-qa` stays: nothing built in collects evidence.

Unverified until the first real thread: whether `--comment` can post from
a cloud thread. The instructions say what to do if it cannot.

### 2026-09-18 19:16 · `c95c637` — deploy-checklist and release-notes come back (→ products)
Both went out in the first cut under "owner simplification", not under
any measurement or anything Projects covers — and Projects covers neither:
threads open pull requests and stop; nothing in a project deploys, and
nothing writes a user-facing account of a range. Owner decision to keep
them. They come back unchanged: `/deploy-checklist` is the owner's
pre-deploy walk in the product repo (generic gates, then the `[STACK]`
product steps), run in a local session because the deploy target is
reachable only from there; `/release-notes` is a global skill the
checklist's fifth gate calls for. `template/CLAUDE.md`'s Deploy slot
names the checklist again. Of the first cut's "owner simplification"
bucket, `researcher` and `evals/` remain removed.

### 2026-09-18 19:10 · `8538217` — one mode: every product session is a project thread (→ products)
Owner decision: this harness is used only through claude.ai/code
projects. There is no local, plain-cloud or teleported mode for product
work, so nothing in the template may branch on which mode a session is
in. Removed: the review rule in `template/CLAUDE.md`, which had grown a
five-line conditional ("if project instructions delivered with this
session… otherwise a local session, a plain cloud session, a teleported
one…") and the "not bound by this file" note in
`docs/project-instructions.md` — both existed only to keep a mode that
does not exist from misreading. Review is now defined in exactly one
place: the project instructions start a review thread per pull request,
the thread runs `code-reviewer`, the agent file is the method. The
agent's description no longer hints at any other trigger. Docs say the
same: this harness is not designed for any other mode.

What still runs locally, by design: maya's own work, and `/spec` and
`/mvp-scope`, which are interactive with the owner. They touch a product
repo only to write `docs/`, land it through a pull request like anything
else, and get no review thread — CI green and the owner's merge.

### 2026-09-18 18:52 · `8a74ce6` — one reviewer, two wrappers; "project" disambiguated (→ products)
The review thread and the `code-reviewer` agent had the same independence
property and different methods: the agent file spells one out (severity
order, a failure scenario per finding, an explicit verdict), the project
instructions gave the thread three bullets and left the rest to default
behaviour. Now the thread's whole task is to run the agent on the pull
request's branch and post its report as comments. The method is written
once, in the agent file; the thread adds only a separate session and a
place the findings persist. Outside a project the agent's verdict goes
into the pull request body, so the pull request is the review's record
in both modes.

Also fixed: the rule in `template/CLAUDE.md` said "in a project", and in
Claude Code that word usually means the repository. A local session could
read it as "here" and wait for a review thread that never comes. The rule
now keys on what a session can observe — whether project instructions in
its context assign a review thread — and the other two uses of the word
name the claude.ai/code feature explicitly.

### 2026-09-18 18:40 · `8b97260` — code-reviewer comes back, for the fresh context (→ products)
The first entry today removed `code-reviewer` as a duplicate of the
built-in `/code-review`. That was true of what it does and false of how
it does it: `/code-review` runs as a forked subagent that inherits the
author's whole conversation, so the reviewer starts with the author's
assumptions; a custom subagent under `.claude/agents/` starts with none.
The agent's own first sentence names the property — findings the author
cannot see because they wrote the code — and the deletion traded it away
without noticing. Inside a project the separate review thread has the
property anyway; outside one, nothing did.

Restored as a definition only: no gate, no marker, no hook. It reviews
the branch's diff against its merge base with `main`, committed state
only, and also checks each new test against its done-when clause and for
the red run the pull request should show. `template/CLAUDE.md` carries
the one rule in one place: no pull request reaches the owner unreviewed
by something that did not write it — the review thread in a project, the
agent outside one. Project instructions keep only the coordinator's
mechanics for the thread, so the rule is not written twice.

### 2026-09-18 18:26 · `25a8b6b` — the harvest gets its input back in a project (→ products)
`/update-stack` harvests `docs/NOTES.md`; in a project, threads were never
told to write there. The rule that sends template-origin improvements to
"Upstream candidates" lived only in `global/CLAUDE.md`, which threads do
not read, and what a thread learns goes to project memory, which maya
does not read. Propagation — the one job nothing else here does — had no
input while work ran through Projects. Three lines close it: the rule
moves into `template/CLAUDE.md` where every thread sees it; project
instructions say memory stays in the project and NOTES.md is what
travels; and `/update-stack` now reads "Battery gaps" as well, proposing
the template rule or `verify.sh` pattern for each class of miss so the
next product's battery is born without that hole. The entry below had
promised that harvest without wiring it; this one wires it.

### 2026-09-18 18:15 · `59e9cf3` — the battery gets a discipline, not a measurement (→ products)
With `evals/` gone, nothing measures whether a green battery means a
working feature — the one gap the old instrument did show. Four rules
stand in for the measurement, chosen because they cost nothing and do not
depend on Projects:
- `/mvp-scope`: a done-when clause also says what failure looks like. A
  clause that cannot fail cannot be tested, and a vague clause is where a
  green-but-broken test starts.
- `template/CLAUDE.md`: a new test is seen red before the change that
  turns it green, and the pull request says so.
- `project-instructions.md`: the pull request body names the red run; the
  review thread checks each new test against its clause and asks for the
  run when it is missing — so the claim has a second reader.
- `docs/NOTES.md` gains a "Battery gaps" section: every miss the battery
  let through, with the test that closed it. `/update-stack` harvests the
  classes of miss across products.

Considered and deferred, deliberately: a release-time sabotage pass by
`evaluator-qa` (break each done item, confirm the battery goes red) that
would give a number back. It is one paragraph in a file that already
exists and can be added when a product shows it is needed. Until then
the honest answer to "how good is the battery" is: production tells us.

### 2026-09-18 17:54 · `cfcfb11` — evaluator-qa comes back, narrowed (→ products)
Reversing one removal from the entry below, on the same evidence that
motivated the rest of it. The measured gap was never enforcement: the
battery was green at tip in 100/100 runs while roughly 0.7 features per
run did not work. Everything that survived the cut reads code or runs the
battery; `evaluator-qa` was the only component that collected its own
evidence — ran the battery itself, drove the running app, queried the
store — so removing it deleted the only thing aimed at the one failure
mode the numbers actually showed. The replacement line ("verify it by hand
and say what you observed") puts the author thread in charge of grading
its own claim, which is the exact failure the agent's first paragraph
names.

It comes back narrowed rather than as it was. The old rule ran it before
every done report, before deploys and after unattended runs; the new one
runs it only where `verify.sh` cannot see the done-when clause — UI
behaviour, data state, an external service — and before a release. Where
the battery and CI already cover the clause, their result stands. The
agent file says so itself now, so the trigger travels with it.

The rule lives in `template/CLAUDE.md` (it is about this repository and
the agent committed in it); `project-instructions.md` points at it instead
of repeating it. Threads load `.claude/agents/` from every repository in a
project, so this works in a multi-repository project where hooks would
not.

### 2026-09-18 17:49 · `2a53368` — the harness comes out; the gate moves to GitHub (→ products)
Claude Code projects shipped on 2026-09-17: one conversation coordinates
parallel cloud threads, each on its own branch, each opening a pull
request and watching it. Coordination was the job several components here
were doing by hand, so the whole stack was repriced against it — and
against this repo's own measurements.

What the measurements said, before `evals/` was removed with everything
else (run `0bd0de2-20260902T031130Z`, 50 trials per arm, Haiku 4.5, in
`git log`): the full-harness arm and the no-harness arm were the same
within noise on false passes (27/50 vs 31/50), and `red_battery_pushed`
was **0/50 in both arms** — the push gate's failure case never once
occurred. The full arm cost +73% turns, +67% wall clock and +88% dollars
for that. The evidence gate had already been recorded as never firing on
Opus 5 across 57 sessions. The one finding that did hold: the battery was
green at tip in 100/100 runs while ~0.7 features per run were actually
broken. The gap was never enforcement — it was what the battery checks.

So enforcement leaves the model's machine and moves to the forge: `main`
protected, pull request required, the `ci` run of `verify.sh` required.
A hook can be argued past and, in a project with several repositories,
threads read no repository's `settings.json` at all — a required check
holds in both cases. `/new-product` now sets this up as part of
instantiation rather than leaving it to "later".

Removed, with reasons:
- `push-gate`, `review-gate`, `review-mark`, `evidence-gate`, `bash-guard`,
  `format-changed` and their `settings.json` wiring — measured above, or
  superseded by branch protection.
- `code-reviewer` — the built-in `/code-review` does the same work in its
  own context window. Review now runs as a separate thread that comments
  on the pull request; the pull request itself is a better record than the
  untracked `.claude/last-reviewed` marker ever was.
- `evaluator-qa`, `/deploy-checklist`, `/parallel-tracks`, `contracts/`,
  `loop.md`, `/release-notes`, the `researcher` agent — owner decision:
  keep the template, `/new-product`, `/update-stack` + the registry, and
  the two scope skills; drop the rest.
- `evals/`, `tests/`, `docs/test-plan.md`,
  `docs/ablating-your-own-guardrails.md` — the instrument and its manuals,
  removed with the components they measured. This is the honest cost of
  this entry: the numbers above cannot be reproduced from a checkout any
  more, only from history. `/update-stack`'s model-release step is now a
  judgement call ("propose one rule to drop"), not a measurement.

Added/changed:
- `verify.sh` unconfigured now exits 1. As the required check it would
  otherwise be a green light on nothing — worse than no check.
- `template/docs/project-instructions.md`: the source text pasted into a
  project's instructions field. Instructions live in a web UI, which maya
  cannot propagate; keeping the original as a repo file restores versioning
  and lets `/update-stack` port it.
- Authority tiers: the per-instance approval moves from **push** to
  **merge**. Threads push to their own branches constantly; the branch is
  cheap and the merge is the decision.
- `install.sh` prunes `~/.claude` symlinks left by components deleted here.

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
in `993bf69` and covered by the suite: `>|` joins the marker-write refusal, and
review-gate refuses `update-ref`/`symbolic-ref`/`refs/remotes/` outright
(`git fetch . x:refs/remotes/...` could launder a commit as "on a remote";
the settings deny is prefix-matched, this backs it). 28 hook contracts,
56 gate cases.

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
