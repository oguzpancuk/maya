#!/usr/bin/env bash
# Smoke tests for push-gate.sh. CLAUDE_PROJECT_DIR points at an empty dir so a
# clean push exits 0 via the "verify.sh missing" branch instead of running the
# battery. Usage: bash push-gate-test.sh <path-to-push-gate.sh>
gate="$1"
T="$(mktemp -d)"
fail=0
run() {
  want="$1"; shift
  printf '%s' "$1" | python3 -c 'import json,sys;print(json.dumps({"tool_input":{"command":sys.stdin.read()}}))' \
    | CLAUDE_PROJECT_DIR="$T" bash "$gate" 2>/dev/null
  rc=$?
  if [ "$rc" = "$want" ]; then echo "PASS ($rc) $1"; else echo "FAIL want=$want got=$rc: $1"; fail=1; fi
}
run 0 'git status'
run 0 'echo "git push -f is bad"'
run 0 'git commit -m "deny git push -f rule" && git push'
run 0 'git commit -q -m "line one
The git push -f deny is belt-and-braces.
Co-Authored-By: x" && git push 2>&1 | tail -15'
run 0 'git push origin main; git commit -m "-f"'
run 0 'git push --follow-tags'
run 0 'git push -u origin main'
run 2 'git push -f origin main'
run 2 'git push origin main -f'
run 2 'git push --force origin main'
run 2 'git push --force-with-lease=main origin main'
run 2 'git push origin +main'
run 2 'git -C /x push --force'
run 2 'git -c k=v push -fu origin main'
run 2 'git status && git push -f'
run 2 'echo $(git push -f)'
run 2 'echo `git push --force`'
run 2 'git push origin main -m "unbalanced'
rm -rf "$T"
exit $fail
