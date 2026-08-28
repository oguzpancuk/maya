# Changelog

All notable changes to maya. Removals are listed with their reasons —
deletion is a feature, and the reasons are the evidence.

## Unreleased

- format-changed.sh: locate prettier by walking up from the edited file
  instead of assuming the repo root — first harvested lesson, from pati
  (multi-package repo, no root package.json; the hook silently no-oped).

## v0.1.0 — 2026-08-27

Initial scaffold, built from the Phase 1 research pass
(factory repo, `docs/research-notes.md`):

- `global/`: personal CLAUDE.md; skills: /spec, /mvp-scope, /release-notes,
  /new-product, /update-stack; agent: researcher.
- `template/`: stack-agnostic project CLAUDE.md; hooks: format-on-edit,
  push-gate (+ verify.sh stack slot); agents: code-reviewer, evaluator-qa;
  skill: /deploy-checklist; loop.md; docs skeleton (PRD/ROADMAP/NOTES/ADR);
  CI skeleton that runs verify.sh; unattended-run contracts
  (feature_list + evidence gate, off by default).
- Ablation watchlist (CANONICAL copy — other files reference this one;
  re-test on each model release, in order): evidence-gate → evaluator-qa
  invocation frequency → one-feature-per-session constraint → push-gate →
  CLAUDE.md line count.

### Hardening pass (same day, from the adversarial scaffold review)
- push-gate: command-position matching (no more false blocks on
  `git commit -m "... git push ..."`), `-C`/`-c` bypass closed, force pushes
  (`--force`/`-f`/`--force-with-lease`/`+refspec`) blocked outright,
  600s hook timeout, parse failures fail closed, verify warnings forwarded.
- evidence gate: per-session read logs (session_id-keyed, pruned after a
  day), evidence pattern no longer satisfied by reading the feature list or
  any config; fails closed without python3.
- new bash-guard hook closes the shell bypass (sed/tee/redirect writes to
  feature_list.json; AGENT_STOP now halts Bash too).
- settings.json: dead `Grep(**)`/`Glob(**)` rules removed (covered by
  `Read(**)`; the Glob rule warns at startup per current docs).
- install.sh: CLAUDE.md is copied instead of symlinked (desktop Cowork skips
  a symlinked user CLAUDE.md); glob guards for trimmed layers.
