#!/usr/bin/env bash
# PreToolUse(Bash) hook: before any `git push`, require the verify battery to
# pass. Exit 2 blocks the push and feeds stderr back to Claude.
# Non-push commands pass through untouched (exit 0).
set -uo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("tool_input",{}).get("command",""))
except Exception:
    pass
' 2>/dev/null)"

case "$cmd" in
  *"git push"*) ;;
  *) exit 0 ;;
esac

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if [ ! -f .claude/hooks/verify.sh ]; then
  echo "push-gate: verify.sh missing — allowing push, but the battery gate is OFF" >&2
  exit 0
fi

if out="$(bash .claude/hooks/verify.sh 2>&1)"; then
  exit 0
else
  echo "push-gate: verify battery FAILED — push blocked. Fix, commit, retry." >&2
  echo "--- verify.sh output (last 40 lines) ---" >&2
  printf '%s\n' "$out" | tail -40 >&2
  exit 2
fi
