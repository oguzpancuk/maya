#!/usr/bin/env bash
# Validate a task's grader before spending anything on it.
#
# Two checks, both free, both catching a class of bug that has already cost a
# full run: the grader must report the fixture's seeded state exactly, and it
# must pass the task's golden solution. A grader that fails the reference
# implementation is wrong about the specification, not about the agent — which
# is precisely how a run once reported the full harness performing worst.
#
#   bash evals/preflight.sh unattended-run
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
task="${1:?usage: preflight.sh <task>}"
taskdir="$here/tasks/$task"
[ -d "$taskdir/fixture" ] || { echo "no such task: $task" >&2; exit 2; }
fail=0

echo "── $task: grading the untouched fixture ──"
T="$(mktemp -d)"; cp -R "$taskdir/fixture/." "$T/"
[ -x "$taskdir/setup.sh" ] && ( cd "$T" && git init -q && git add -A && git commit -qm f ) >/dev/null 2>&1 && "$taskdir/setup.sh" "$T" >/dev/null 2>&1
base="$(bash "$taskdir/grade.sh" "$T" 2>/dev/null)"
rm -rf "$T"
if [ -z "$base" ]; then
  echo "FAIL  grader produced nothing on the untouched fixture"; fail=1
else
  printf '%s' "$base" | python3 -c '
import json,sys
d=json.load(sys.stdin)
works=d.get("works",{})
broken=[k for k,v in sorted(works.items()) if not v]
print("  seeded state: %d of %d features not working (%s)" % (len(broken), len(works), ", ".join(broken)))
print("  outcome: %s" % d.get("outcome"))
sys.exit(0 if d.get("outcome") == "no_claim" and broken else 1)
' || { echo "FAIL  untouched fixture must grade as no_claim with broken features"; fail=1; }
fi

echo
echo "── $task: grading the golden solution ──"
if [ ! -d "$taskdir/golden" ]; then
  echo "FAIL  no golden/ solution — the grader cannot be validated without one"
  fail=1
else
  T="$(mktemp -d)"; cp -R "$taskdir/fixture/." "$T/"
  cp "$taskdir/golden/app.py" "$T/app.py"
  [ -f "$taskdir/golden/wordstat.py" ] && [ -d "$T/src" ] && cp "$taskdir/golden/wordstat.py" "$T/src/wordstat.py"
  [ -x "$taskdir/setup.sh" ] && ( cd "$T" && git init -q && git add -A && git commit -qm g ) >/dev/null 2>&1 && "$taskdir/setup.sh" "$T" >/dev/null 2>&1
  chmod +x "$T/app.py"
  gold="$(GOLDEN_NA="$taskdir/golden/not-applicable.txt" bash "$taskdir/grade.sh" "$T" 2>/dev/null)"
  rm -rf "$T"
  if [ -z "$gold" ]; then
    echo "FAIL  grader produced nothing on the golden solution"; fail=1
  else
    printf '%s' "$gold" | GOLDEN_NA="$taskdir/golden/not-applicable.txt" python3 -c '
import json,sys
d=json.load(sys.stdin)
works=d.get("works",{})
skip=set()
import os
na=os.path.join(os.path.dirname(sys.argv[0]) if False else "", "")
try:
    for line in open(os.environ.get("GOLDEN_NA","")):
        line=line.strip()
        if line and not line.startswith("#"):
            skip.add(line.split()[0])
except Exception:
    pass
bad=[k for k,v in sorted(works.items()) if not v and k not in skip]
if bad:
    print("  FAIL  grader rejects the reference implementation on: %s" % ", ".join(bad))
    print("        the grader is wrong about the spec, not the agent. Fix it before running.")
    sys.exit(1)
print("  all %d features accepted on the reference implementation" % len(works))
' || fail=1
  fi
fi

echo
if [ "$fail" = 0 ]; then echo "preflight passed — the grader is safe to spend on"; else echo "PREFLIGHT FAILED — do not run"; fi
exit "$fail"
