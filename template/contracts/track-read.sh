#!/usr/bin/env bash
# PostToolUse(Read) hook for unattended runs: append every file the session
# actually opened to a per-session log the evidence gate can check.
set -uo pipefail
payload="$(cat)"
file_path="$(printf '%s' "$payload" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("tool_input",{}).get("file_path",""))
except Exception:
    pass
' 2>/dev/null)"
[ -n "$file_path" ] || exit 0
log="${CLAUDE_PROJECT_DIR:-.}/.claude/.session-reads.log"
printf '%s\n' "$file_path" >> "$log"
exit 0
