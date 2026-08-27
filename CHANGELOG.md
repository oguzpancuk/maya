# Changelog

All notable changes to maya. Removals are listed with their reasons —
deletion is a feature, and the reasons are the evidence.

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
- Ablation watchlist (re-test on each model release, in order):
  evidence-gate → evaluator-qa invocation frequency → one-feature-per-session
  constraint → push-gate → CLAUDE.md line count.
