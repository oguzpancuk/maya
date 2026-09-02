#!/usr/bin/env bash
# Deterministic contract tests for the harness hooks. No model, no network,
# runs in seconds. Every hook gets at least three cases: it blocks what it
# exists to block, it allows the legitimate case so it is not a brick, and it
# fails closed on malformed input — these run unattended, where a hook that
# crashes open is worse than no hook at all.
#
# These are also the positive controls for the behavioural evals: no result
# about a gate is believable until its unit test passes. A gate that never
# fires produces the same clean table as a gate that does nothing, and the
# only thing that separates them is proof the mechanism can act.
#
#   bash tests/hooks-test.sh
set -uo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
contracts="$repo/template/contracts"
hooks="$repo/template/.claude/hooks"
fail=0
pass=0

check() { # check <want-rc> <got-rc> <description>
  if [ "$1" = "$2" ]; then
    echo "PASS  $3"
    pass=$((pass + 1))
  else
    echo "FAIL  $3 — want rc=$1 got rc=$2"
    fail=1
  fi
}

payload_write() { # <session> <file_path>
  python3 -c 'import json,sys; print(json.dumps({"session_id":sys.argv[1],"tool_input":{"file_path":sys.argv[2]}}))' "$1" "$2"
}
payload_bash() { # <command>
  python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1"
}

fresh() { # a sandbox that looks like a product repo mid-run
  local d; d="$(mktemp -d)"
  mkdir -p "$d/contracts" "$d/.claude" "$d/test-results"
  printf '[{"id":"F-001","passes":false},{"id":"F-002","passes":false}]' > "$d/contracts/feature_list.json"
  echo 'print("hi")' > "$d/app.py"
  echo 'PASS  something' > "$d/test-results/verify.log"
  echo 'F-001 verified: exit code 2 as specified' > "$d/test-results/f001.log"
  printf '%s' "$d"
}

payload_write_content() { # <session> <file_path> <new content>
  python3 -c 'import json,sys; print(json.dumps({"session_id":sys.argv[1],"tool_input":{"file_path":sys.argv[2],"content":sys.argv[3]}}))' "$1" "$2" "$3"
}

echo "── evidence-gate ──────────────────────────────────────────────"
T="$(fresh)"
payload_write s1 "$T/contracts/feature_list.json" | CLAUDE_PROJECT_DIR="$T" bash "$contracts/evidence-gate.sh" >/dev/null 2>&1
check 2 $? "blocks a feature-list write with no evidence read this session"

printf '%s/test-results/f001.log\n' "$T" > "$T/.claude/.session-reads.s2.log"
payload_write_content s2 "$T/contracts/feature_list.json" \
  '[{"id":"F-001","passes":true},{"id":"F-002","passes":false}]' \
  | CLAUDE_PROJECT_DIR="$T" bash "$contracts/evidence-gate.sh" >/dev/null 2>&1
check 0 $? "allows the flip when the evidence read names the feature being claimed"

printf '%s/test-results/verify.log\n' "$T" > "$T/.claude/.session-reads.s2b.log"
payload_write_content s2b "$T/contracts/feature_list.json" \
  '[{"id":"F-001","passes":true},{"id":"F-002","passes":false}]' \
  | CLAUDE_PROJECT_DIR="$T" bash "$contracts/evidence-gate.sh" >/dev/null 2>&1
check 2 $? "blocks the flip when the evidence read never names that feature"

printf '%s/test-results/f001.log\n' "$T" > "$T/.claude/.session-reads.s2c.log"
payload_write_content s2c "$T/contracts/feature_list.json" \
  '[{"id":"F-001","passes":true},{"id":"F-002","passes":true}]' \
  | CLAUDE_PROJECT_DIR="$T" bash "$contracts/evidence-gate.sh" >/dev/null 2>&1
check 2 $? "one relevant log does not carry a second feature flipped alongside it"

printf '%s/app.py\n%s/contracts/feature_list.json\n' "$T" "$T" > "$T/.claude/.session-reads.s3.log"
payload_write s3 "$T/contracts/feature_list.json" | CLAUDE_PROJECT_DIR="$T" bash "$contracts/evidence-gate.sh" >/dev/null 2>&1
check 2 $? "source files and the feature list itself do not count as evidence"

printf '%s/test-results/verify.log\n' "$T" > "$T/.claude/.session-reads.other.log"
payload_write s4 "$T/contracts/feature_list.json" | CLAUDE_PROJECT_DIR="$T" bash "$contracts/evidence-gate.sh" >/dev/null 2>&1
check 2 $? "evidence read in a different session does not carry over"

payload_write s2 "$T/app.py" | CLAUDE_PROJECT_DIR="$T" bash "$contracts/evidence-gate.sh" >/dev/null 2>&1
check 0 $? "writes to files other than the feature list are untouched"

echo 'not json' | CLAUDE_PROJECT_DIR="$T" bash "$contracts/evidence-gate.sh" >/dev/null 2>&1
check 2 $? "fails closed on a malformed payload"

touch "$T/AGENT_STOP"
payload_write s2 "$T/app.py" | CLAUDE_PROJECT_DIR="$T" bash "$contracts/evidence-gate.sh" >/dev/null 2>&1
check 2 $? "AGENT_STOP halts all writes, not just the feature list"
rm -f "$T/AGENT_STOP"; rm -rf "$T"

echo
echo "── bash-guard ─────────────────────────────────────────────────"
T="$(fresh)"
for cmd in \
  'sed -i "" "s/false/true/" contracts/feature_list.json' \
  'echo "[]" > contracts/feature_list.json' \
  'cat x >> contracts/feature_list.json' \
  'python3 -c "..." contracts/feature_list.json'
do
  payload_bash "$cmd" | CLAUDE_PROJECT_DIR="$T" bash "$contracts/bash-guard.sh" >/dev/null 2>&1
  check 2 $? "blocks shell write to the feature list: ${cmd:0:44}"
done

for cmd in \
  'cat contracts/feature_list.json' \
  'grep passes contracts/feature_list.json' \
  'bash verify.sh'
do
  payload_bash "$cmd" | CLAUDE_PROJECT_DIR="$T" bash "$contracts/bash-guard.sh" >/dev/null 2>&1
  check 0 $? "allows a read-only command: ${cmd:0:44}"
done

echo 'not json' | CLAUDE_PROJECT_DIR="$T" bash "$contracts/bash-guard.sh" >/dev/null 2>&1
check 2 $? "fails closed on a malformed payload"

touch "$T/AGENT_STOP"
payload_bash 'echo hello' | CLAUDE_PROJECT_DIR="$T" bash "$contracts/bash-guard.sh" >/dev/null 2>&1
check 2 $? "AGENT_STOP halts every command"
rm -rf "$T"

echo
echo "── track-read ─────────────────────────────────────────────────"
T="$(fresh)"
payload_write sess1 "$T/test-results/verify.log" | CLAUDE_PROJECT_DIR="$T" bash "$contracts/track-read.sh" >/dev/null 2>&1
check 0 $? "exits 0 so a read is never blocked by logging"
if grep -q 'verify.log' "$T/.claude/.session-reads.sess1.log" 2>/dev/null; then
  check 0 0 "records the read under this session's id"
else
  check 0 1 "records the read under this session's id"
fi
payload_write sess2 "$T/app.py" | CLAUDE_PROJECT_DIR="$T" bash "$contracts/track-read.sh" >/dev/null 2>&1
if [ -f "$T/.claude/.session-reads.sess1.log" ] && [ -f "$T/.claude/.session-reads.sess2.log" ]; then
  check 0 0 "keeps sessions in separate logs"
else
  check 0 1 "keeps sessions in separate logs"
fi
echo 'not json' | CLAUDE_PROJECT_DIR="$T" bash "$contracts/track-read.sh" >/dev/null 2>&1
check 0 $? "a malformed payload never blocks a read (this hook must fail open)"
rm -rf "$T"

echo
echo "── push-gate ──────────────────────────────────────────────────"
if [ -f "$repo/tests/push-gate-test.sh" ]; then
  out="$(bash "$repo/tests/push-gate-test.sh" "$hooks/push-gate.sh" 2>&1)"
  printf '%s\n' "$out" | sed 's/^/  /'
  if printf '%s' "$out" | grep -q '^FAIL'; then fail=1; else pass=$((pass + 1)); fi
else
  echo "  SKIP  tests/push-gate-test.sh missing"
fi

echo
echo "── format-changed ─────────────────────────────────────────────"
T="$(fresh)"
payload_write s1 "$T/app.py" | CLAUDE_PROJECT_DIR="$T" bash "$hooks/format-changed.sh" >/dev/null 2>&1
check 0 $? "never blocks an edit: formatting is cosmetic and must fail open"
echo 'not json' | CLAUDE_PROJECT_DIR="$T" bash "$hooks/format-changed.sh" >/dev/null 2>&1
check 0 $? "fails open on a malformed payload"
rm -rf "$T"

echo
if [ "$fail" = 0 ]; then
  echo "all hook contracts hold ($pass checks)"
else
  echo "HOOK CONTRACT FAILURES — see above"
fi
exit "$fail"
