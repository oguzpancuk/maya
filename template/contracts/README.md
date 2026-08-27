# Unattended-run contracts

The pattern for overnight / goal-loop work, adapted from Anthropic's
long-running-agents harness (`anthropics/cwc-long-running-agents`). Everything
here is OFF by default — wire it up only for an actual unattended run, and
re-test whether each piece is still needed on every model release
(ablation watchlist in maya's CHANGELOG.md).

## The pattern

1. **Initializer session** (once): expand the ROADMAP into
   `contracts/feature_list.json` — every feature `"passes": false` (schema:
   `feature_list.schema.json`), each with human-verifiable steps. Write
   `contracts/init.sh` (from `init.sh.example`) so every later session can
   boot the app in one command. Commit.
2. **Work sessions** (repeated): each session reads git log + NOTES.md +
   the feature list, picks ONE unfinished feature, implements it, verifies
   it end-to-end (through the UI for UI features — a passing unit test is
   not end-to-end), flips only that feature's `passes`, commits, appends a
   dated NOTES.md entry.
3. **Run it** with the built-in goal loop, always bounded:

   ```
   /goal every feature in contracts/feature_list.json has passes true,
   verify.sh exits 0, and git status is clean — or stop after 25 turns
   ```

4. **Kill switch**: create a file named `AGENT_STOP` in the repo root; the
   evidence gate refuses all writes while it exists. Delete it to resume.

## Rules baked into the contract

- Agents may ONLY flip the `passes` field. It is unacceptable to remove or
  edit feature entries — that is how functionality silently disappears.
- `passes: true` requires observed evidence (test output, screenshot,
  driving the app). The evidence gate below enforces the observation.
- One feature per session. Progress notes + commits are the handoff; the
  next session starts from the repo, not from memory.

## Evidence gate (optional enforcement)

Two hooks, wired ONLY for unattended runs (add to `.claude/settings.json`):

```json
"PostToolUse": [
  { "matcher": "Read", "hooks": [ { "type": "command",
    "command": "\"$CLAUDE_PROJECT_DIR\"/contracts/track-read.sh" } ] }
],
"PreToolUse": [
  { "matcher": "Edit|Write", "hooks": [ { "type": "command",
    "command": "\"$CLAUDE_PROJECT_DIR\"/contracts/evidence-gate.sh" } ] }
]
```

`track-read.sh` records what the session actually opened; `evidence-gate.sh`
denies writes to `feature_list.json` unless evidence (test output, a
screenshot, a log) was Read since the session started — the agent cannot
claim success it hasn't observed. Asking nicely in the prompt does not
reliably stop premature `passes: true`; the gate does.

Also run the **evaluator-qa** agent on the final state: the builder never
grades its own overnight work.
