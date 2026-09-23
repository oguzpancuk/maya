---
name: integrate-product
description: Bring an EXISTING product repository onto the maya harness — reads what the repo already has, merges the template in without replacing a working setup, makes verify.sh the single battery, adds CI and the docs skeleton, lands it as one revertible pull request, then walks the merge gate and registers the product. Use for any product that predates maya ("eski ürünü mayaya entegre et", "retrofit", "adopt into maya"); a product started from scratch takes /new-product instead.
disable-model-invocation: true
argument-hint: [product-path] [product-name, default: the directory name]
---

# /integrate-product — bring an existing product onto maya

The brownfield twin of `/new-product`. That skill fills an empty
directory; this one meets a repository that already has habits: its own
commands, maybe its own CI, an AGENTS.md, a live deployment, users. Two
principles decide every step. **Minimal merge**: never replace a setup
that works. **No second tool for the same job**: when the template and
the product both do something, one goes, and the survivor is the one the
harness expects (`verify.sh`, `ci.yml`).

Stopping condition: the integration pull request is open with CI's
result explained, the merge gate is on or its blocker is named, the
product is registered, and the report is written. Product bugs the
integration surfaces are not fixed here — they become the first ROADMAP
items, and the product's project threads do them.

## Preconditions (check, don't assume)
1. maya: `~/dev/maya`, else ask. `git fetch`, compare HEAD to
   `origin/main`, report the commit. The version to write is the hash of
   the newest CHANGELOG entry — the same base `/update-stack` uses as the
   watermark; an entry-less commit is not addressable in the ledger.
2. The product path exists. Not a git repository → `git init` and commit
   the tree AS FOUND (`chore: import <name> as found`) before anything
   else, so the integration is a separate, revertible diff. Dirty tree →
   stop and ask: my commit must not swallow uncommitted work of yours.
   Read `git remote -v`, the default branch, `gh repo view` if a remote
   exists.

## A. Read before writing (change nothing yet)
3. Inventory, in one pass — every later judgment depends on it:
   - Instruction files: `CLAUDE.md`, `AGENTS.md`, `.cursorrules`,
     `.github/copilot-instructions.md`, an older `.claude/` (commands,
     hooks, agents, settings). Note who owns each: a block a tool
     regenerates (Next.js rewrites its block in AGENTS.md on every
     `next dev`) cannot be merged away.
   - The battery as documented: README, package scripts, Makefile — what
     does the product itself call "tests pass"? Existing workflows and
     what they run. Anything that deploys on push.
   - Stack facts for the `[STACK]` slots: language, framework, package
     layout, database, test runner, deploy target, surfaces (web / native
     iOS / backend). Read them from lockfiles and configs; ask me, in one
     batch, only what the repo does not say.
   - Docs: README, any spec, roadmap, notes or decision records under
     other names.
   - Hygiene, reported not fixed: a tracked `.env`, key-shaped strings,
     a committed `node_modules`, no `.gitignore`, default branch not
     `main`. Rewriting history destroys history: report, never do.
4. Run the product's OWN documented checks once, as they are, and record
   the result. This is the baseline: the battery I write may not be
   greener than the product actually is.
5. Present the inventory and the plan — which files get added, merged,
   rewired, removed, left as found — and get my word BEFORE writing. An
   old product's setup carries decisions I remember and the repo doesn't.

## B. The merge (one branch: `maya-integrate-<version>`)
6. `CLAUDE.md`. Absent → the template's, slots filled from the
   inventory. Present → keep the product's rules, restructured into the
   template's sections; a product rule that duplicates a template rule
   goes, one that contradicts is a decision — ask. `AGENTS.md` present →
   Claude Code reads it only when `CLAUDE.md` is absent, so adding ours
   would silently shadow it: when a tool owns that file, `@AGENTS.md` at
   the top of `CLAUDE.md` (dealcloser's pattern; the ratchet scan reads
   @-includes); otherwise merge its rules in and delete it. Same test for
   `.cursorrules` and the like: merge or delete, no parallel rulebooks.
   Ratchet: a product line that LOOSENS the global authority tiers
   ("push freely", "deploy from CI") does not survive the merge unless
   `docs/NOTES.md` records an owner decision for it. Products only
   tighten.
7. Battery. `.claude/hooks/verify.sh` becomes THE implementation of what
   the product documented: its real commands in the template's pattern
   (attempt every step, deps-missing is FAIL, "NOT RUN here" for another
   OS or a container, exec bits). A rival entry point (`npm run check`,
   `make test`, a script) is rewired to call `verify.sh` or removed, and
   the README names `verify.sh`. A step that failed in the baseline
   stays in and stays red — an integration that drops a failing test has
   made the product look better than it is. In an older `.claude/`,
   hooks and settings the template replaced go; a product-specific skill
   or agent stays if nothing in the template does its job.
8. CI. `ci.yml` with setup steps matching what `verify.sh` needs, a job
   per OS the battery needs. An existing workflow that runs the same
   checks is replaced — one green, one definition. One that does
   something else (deploy, release) stays as found; deploy is step 10.
9. Docs skeleton, without clobbering. Add `docs/NOTES.md` (Upstream
   candidates and Battery gaps sections; notes that exist under another
   name are moved in, not duplicated), `docs/adr/0001`, and
   `docs/project-instructions.md` adapted to the product. `docs/PRD.md`
   and `docs/ROADMAP.md`: a spec or plan the product already has is
   pointed to, and `/spec` (revise mode) and `/mvp-scope` come later;
   otherwise the template stubs. The ROADMAP gets ONE real first item —
   whatever the baseline found: "battery green on `main`", "first test",
   "typecheck clean" — with its done-when clause. The README stays.
10. Deploy. The template's `/deploy-checklist`, product steps filled from
    what the repo documents, TODO where it doesn't; deploy credentials
    never in the repo, a cloud environment or an Actions secret. A live
    deploy-on-push from `main` (Vercel, a host's Git integration, a
    deploy workflow) contradicts "production follows my deploy" — report
    it; turning it off is outward-facing and can disrupt live users, so
    it is step 15, asked. A native iOS surface follows `/new-product` B2
    (Xcode Cloud on the release tag), asked the same way.
11. `.gitignore` merged — template lines added, nothing removed.
    `.maya-version` written. Every `{{PRODUCT_NAME}}` and `{{DATE}}`
    replaced; grep the tree for `{{` to prove it, and list the remaining
    `[STACK: TODO` markers — visible, never guessed.
12. ONE commit: `chore: integrate maya <version>`, body listing added /
    merged / rewired / removed and the baseline result. Run `verify.sh`
    on the committed HEAD; its result goes in the pull request body as it
    is, red included. Push the branch, open the pull request, never merge
    it. No remote yet → step 13 comes first, then the branch.

## C. The gate (outward-facing: propose each step, get my word, act)
13. No remote: create the GitHub repository (private unless I say) and
    push `main` as found. Default branch not `main`: rename, with the
    reason stated.
14. Install the Claude GitHub App on it — without it, project threads
    cannot clone or open pull requests.
15. Read CI on the integration pull request. Green, or red for exactly
    the reason the baseline predicted: the product's red, named in the
    body, is left standing. Red for any other reason is the workflow's
    and is fixed in the same pull request. Then, if I said so in step 10,
    turn the host's deploy-on-push off.
16. Protect `main` AFTER the pull request is merged and CI is green on
    `main`: direct pushes off, pull request required, every verify job
    required, up to date before merging — the list in `/new-product`
    step 9 is canonical. The order matters: a required check that cannot
    pass would gate everything, the fix included. If `main` is red for a
    product reason, the gate waits, that is the report's first finding,
    and the product's first thread makes it green.

## D. Registration (a maya write — this skill runs in the maya session)
17. Append the row to maya's `PRODUCTS.md`: name, repo URL, the local
    path as it is (moving a checkout is yours), and
    `<version> (retrofit — repo predates maya)`. Commit in the maya repo;
    pushing maya's `main` is asked like any other push to it.

## E. Report
- What existed and what happened to it — kept / merged / rewired /
  removed / left as found. This table is the opt-out map: one revert of
  the integration commit undoes B.
- Baseline versus the battery now; every remaining TODO slot; hygiene
  findings; the gate, condition by condition.
- Next steps in order: merge the pull request; step 16 if it waited;
  `/spec` and `/mvp-scope` where the product had no spec or plan; the
  claude.ai/code project exactly as `/new-product` step 11 lists it —
  instructions pasted, the environment setup script mirroring `ci.yml`
  (guarded `cd`, no Docker), the tiny first thread; and the product-side
  fixes the integration surfaced, as ROADMAP items for that project.

## Rules
- Read first, write second; ask before the write and before every
  outward-facing step. The repository remembers less than you do.
- The battery reports the product as it is: never drop a failing step,
  never mark one "NOT RUN" because it fails, never fix the product inside
  the integration commit.
- Never rewrite history, force-push, merge, or move the checkout.
- Template content is English; the product's own language stays as it is.
- Do not install plugins or MCP servers here.
