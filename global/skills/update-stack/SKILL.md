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
The flow must run both ways. For each product repo I name (or that is
checked out under ~/dev/): diff its `.claude/`, `contracts/` and CLAUDE.md
against the maya template AT the commit in its `.maya-version`, and read its
docs/NOTES.md "upstream candidates" section. Anything the product improved
locally — a hardened hook, a better rule, a new skill — is an upstream
candidate: list it in the report with the diff hunk, so approved ones get
applied to maya (and CHANGELOG) and every future product inherits the fix.

## 5. Report (never act)
A table: change | affects (global / template / a product) | recommendation
(adopt / ignore / trial) | effort. Explicitly flag anything that means the
maya template should change so future products inherit the fix — and list
which existing products' `.maya-version` is behind.
Then STOP. Installation, deletion, and template edits happen only after I
approve, in the maya repo first.

## 6. Close
Update the state file with today's date, current newest model, and the
changelog version you saw.
