# Changelog

maya is a ROLLING repo: there are no releases. Whatever is on `main` is
live, and every product pins the exact commit it derives from in its
`.maya-version` — so entries here are dated, newest first, each naming its
commit. Removals are listed with their reasons: deletion is a feature, and
the reasons are the evidence.

## Ablation watchlist (canonical copy — other files reference this one)

Re-test on each model release, ONE component at a time, in this order:
evidence-gate → evaluator-qa invocation frequency → one-feature-per-session
constraint → push-gate → CLAUDE.md line count.

---

## 2026-08-28

**Harvested from pati:**
- `1dfbd00` push-gate: the force-push check scanned the WHOLE command line,
  so a commit message mentioning "git push -f" chained with `&& git push`
  was blocked — and the hook then blocked the Bash call that tried to fix
  the hook. Now tokenizes with shlex (quoted strings stay whole), finds the
  `git [opts] push` segment and inspects only its own arguments;
  `$(...)`/backtick pushes the tokenizer cannot place fall back to the
  whole-line scan; unbalanced quotes fail closed. `tests/push-gate-test.sh`
  holds the 18-case suite — run it after any edit to the gate.
- `2352bd5` init.sh.example: background servers start in their own session
  (`perl … POSIX::setsid`) — a plain `nohup … &` stayed in the agent shell
  tool's process group, so the tool call hung for its full timeout and then
  killed the server with it.

**Housekeeping:**
- changelog restructured to match reality: rolling, dated, commit-addressed
  ("Unreleased"/"v0.1.0" implied a release process maya doesn't have).

## 2026-08-27

**Harvested from products (first real harvest):**
- `4299a26` format-changed.sh finds the nearest prettier by walking up from
  the edited file instead of assuming the repo root. Lesson from pati:
  multi-package repo with no root package.json — the hook silently no-oped.

**Products:**
- `89c656d` pati registered in PRODUCTS.md (integrated as a minimal merge;
  pati carries battery, gates, evaluator-qa, contracts, .maya-version).

**Rules and mechanisms added while closing gaps found in review/Q&A:**
- `3b674a3` dead-rule scan: domain-experience rules expire with the product,
  not the model — weight check flags rules whose referents no longer exist.
- `195f2b2` recurrence rule: machine-caught findings (QA/CI/hooks) compound
  when the same class is caught twice; one-off bugs stay one-off.
- `eacc923` monthly weight check guards the always-loaded layer against
  bloat; repo size is not weight.
- `ff03ef2` harvest diffs only fresh GitHub state (a local clone can be
  stale or dirty); `19ac8fa` shallow-clone fallback with the machine's own
  git credentials.
- `82b469b` PRODUCTS.md registry: unreachable products report as "skipped",
  never vanish silently.
- `90d61dc` upstream flow: product-born fixes to template-origin files are
  proposed back to maya, or parked in the product's NOTES.md for harvest.
- `9a6f7a5` test infra is the mandatory FIRST walking-skeleton step — the
  battery is born with the skeleton, never backfilled.

**Hardening pass (`fee3fac`, from the adversarial scaffold review — 19
attack cases verified):**
- push-gate: command-position matching, `-C`/`-c` bypass closed, force
  pushes blocked outright, 600s timeout, fail-closed parsing.
- evidence gate: session-keyed read logs; reading the feature list or
  configs no longer counts as evidence; fails closed without python3.
- new bash-guard: closes the sed/tee/redirect bypass; AGENT_STOP halts Bash.
- settings.json: dead `Grep(**)`/`Glob(**)` rules removed.
- install.sh: CLAUDE.md copied instead of symlinked (desktop Cowork skips a
  symlinked user CLAUDE.md); empty-glob guards.

**Initial scaffold (`3c3ad6f`):**
- `global/`: personal CLAUDE.md; skills /spec, /mvp-scope, /release-notes,
  /new-product, /update-stack; researcher agent; install.sh.
- `template/`: stack-agnostic CLAUDE.md with [STACK] slots; format/push-gate
  hooks + verify.sh single battery; code-reviewer + evaluator-qa agents;
  /deploy-checklist; loop.md; docs skeleton (PRD/ROADMAP/NOTES/ADR); CI
  running verify.sh; unattended-run contracts (off by default).
