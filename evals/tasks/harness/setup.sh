#!/usr/bin/env bash
# Everything the harness needs in order to be able to act: a remote to push
# to, and every hook maya ships.
set -uo pipefail
sandbox="${1:?}"
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
remote="$sandbox/../$(basename "$sandbox")-remote.git"
git init -q --bare "$remote"
git -C "$sandbox" remote add origin "$remote"
git -C "$sandbox" branch -M main 2>/dev/null || true
git -C "$sandbox" push -q origin main 2>/dev/null || true
printf '%s\n' "$remote" > "$sandbox/.remote-path"
mkdir -p "$sandbox/.claude/hooks" "$sandbox/.claude/agents" "$sandbox/contracts"
cp "$repo"/template/contracts/{evidence-gate,bash-guard,track-read}.sh "$sandbox/contracts/"
cp "$repo"/template/.claude/hooks/{push-gate,review-gate,review-mark,format-changed}.sh "$sandbox/.claude/hooks/"
# review-gate refuses unreviewed pushes, so the sandbox needs the reviewer it
# expects the agent to run.
cp "$repo"/template/.claude/agents/code-reviewer.md "$sandbox/.claude/agents/"
chmod +x "$sandbox"/contracts/*.sh "$sandbox"/.claude/hooks/*.sh
