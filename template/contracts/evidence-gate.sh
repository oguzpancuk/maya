#!/usr/bin/env bash
# PreToolUse(Edit|Write) hook for unattended runs.
# 1) AGENT_STOP kill switch: refuse ALL writes while the file exists.
# 2) Evidence gate: refuse writes to feature_list.json unless the session
#    has Read evidence (test output, screenshot, log) since it started.
set -uo pipefail
proj="${CLAUDE_PROJECT_DIR:-.}"

if [ -f "$proj/AGENT_STOP" ]; then
  echo "evidence-gate: AGENT_STOP present — all writes halted by operator." >&2
  exit 2
fi

payload="$(cat)"
file_path="$(printf '%s' "$payload" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("tool_input",{}).get("file_path",""))
except Exception:
    pass
' 2>/dev/null)"

case "$file_path" in
  */feature_list.json) ;;
  *) exit 0 ;;
esac

log="$proj/.claude/.session-reads.log"
if [ -f "$log" ] && grep -Eq '\.(png|jpg|jpeg|txt|log|json|xml)$|test|spec|screenshot' "$log"; then
  exit 0
fi

echo "evidence-gate: write to feature_list.json DENIED — no evidence was Read" >&2
echo "this session. Run the verification (tests / screenshot), Read the output" >&2
echo "file, then flip passes. The contract requires observed evidence." >&2
exit 2
