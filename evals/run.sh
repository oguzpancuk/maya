#!/usr/bin/env bash
# maya eval runner — measures whether a harness component is still
# load-bearing, by running the same task with the component ON (control) and
# OFF (ablated) and grading both with the same deterministic grader.
#
#   bash evals/run.sh evidence-gate --trials 5
#   bash evals/run.sh evidence-gate-hard --trials 10 --jobs 4
#   bash evals/run.sh evidence-gate --trials 1 --arms ablated
#
# Trials are independent — separate sandboxes, no shared state — so they run
# concurrently (--jobs, default 4). Each trial writes its own row file and the
# rows are appended to evals/results/<task>.jsonl once, so concurrent writes
# cannot interleave. Results are stamped with the maya commit they ran at.
# Every trial is a real agent session: it costs tokens. Start small.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/.." && pwd)"

# ---- internal single-trial mode (re-entered by xargs) ----------------------
if [ "${1:-}" = "--__trial" ]; then
  task="$2"; arm="$3"; trial="$4"; rowdir="$5"; run_id="$6"; max_turns="$7"; model="${8:-}"
  taskdir="$here/tasks/$task"
  sandbox="$(mktemp -d "${TMPDIR:-/tmp}/maya-eval-${task}-${arm}-XXXXXX")"
  cp -R "$taskdir/fixture/." "$sandbox/"

  # The gates under test are copied from template/contracts at run time, never
  # vendored into the fixture: an ablation instrument that tested a stale copy
  # of a hook would report on a component that is no longer the one shipping.
  mkdir -p "$sandbox/contracts"
  cp "$repo"/template/contracts/{evidence-gate.sh,bash-guard.sh,track-read.sh} "$sandbox/contracts/"
  chmod +x "$sandbox"/contracts/*.sh

  # Arms are a 2x2 of instruction against enforcement. The stripped contract
  # keeps the job (work the list, flip passes, never edit entries) and drops
  # only the discipline (evidence required, the suite is not a spec, leaving a
  # feature open is acceptable) — an agent that was never told the rule cannot
  # be scored against it.
  # Three contract levels, so the floor is a real floor. `none` is the repo
  # with no harness at all: a project description and the commands, nothing
  # from maya. `bare`/`hooks` keep the job and the do-not-delete-entries rule
  # but drop the discipline. `prose`/`full` get the whole contract.
  case "$arm" in
    none)
      mv "$sandbox/CLAUDE.minimal.md" "$sandbox/CLAUDE.md" ;;
    bare|hooks)
      mv "$sandbox/CLAUDE.stripped.md" "$sandbox/CLAUDE.md" ;;
  esac
  rm -f "$sandbox/CLAUDE.stripped.md" "$sandbox/CLAUDE.minimal.md"

  ( cd "$sandbox" && git init -q && git add -A && git commit -qm "fixture" ) >/dev/null 2>&1 || true

  # A task may need more than a copied directory — a remote to push to, a
  # seeded history. setup.sh runs once per sandbox, after the fixture commit.
  [ -x "$taskdir/setup.sh" ] && "$taskdir/setup.sh" "$sandbox" >/dev/null 2>&1


  if [ "$arm" = "control" ] || [ "$arm" = "hooks" ] || [ "$arm" = "full" ]; then
    mkdir -p "$sandbox/.claude"
    # A task that gates something other than the contract hooks ships its own
    # wiring; without one, the contract hooks are the default.
    if [ -f "$taskdir/hooks-settings.json" ]; then
      # A task-provided wiring must still go through the counter, or the rig
      # loses the one signal that separates a real null from a vacuous one.
      sed 's#/contracts/evidence-gate.sh#/contracts/gate-wrapper.sh#g' \
        "$taskdir/hooks-settings.json" > "$sandbox/.claude/settings.json"
      cat > "$sandbox/contracts/gate-wrapper.sh" <<'WRAP'
#!/usr/bin/env bash
proj="${CLAUDE_PROJECT_DIR:-.}"
payload="$(cat)"
printf '%s' "$payload" | "$proj/contracts/evidence-gate.sh"
rc=$?
printf '%s\n' "$rc" >> "$proj/.claude/.gate-invocations.log"
exit "$rc"
WRAP
      chmod +x "$sandbox/contracts/gate-wrapper.sh"
    else
    # Wrap the gate so every invocation is counted. A component that never
    # fires cannot be measured: reporting "no effect" for a gate the run never
    # put in a position to act is a vacuous null, and without this counter the
    # rig cannot tell that case from a real one. The wrapper only records; the
    # shipped hook is called unmodified.
    cat > "$sandbox/contracts/gate-wrapper.sh" <<'WRAP'
#!/usr/bin/env bash
proj="${CLAUDE_PROJECT_DIR:-.}"
payload="$(cat)"
printf '%s' "$payload" | "$proj/contracts/evidence-gate.sh"
rc=$?
printf '%s\n' "$rc" >> "$proj/.claude/.gate-invocations.log"
exit "$rc"
WRAP
    chmod +x "$sandbox/contracts/gate-wrapper.sh"
    cat > "$sandbox/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Read", "hooks": [
        { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/contracts/track-read.sh" } ] }
    ],
    "PreToolUse": [
      { "matcher": "Edit|Write", "hooks": [
        { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/contracts/gate-wrapper.sh" } ] },
      { "matcher": "Bash", "hooks": [
        { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/contracts/bash-guard.sh" } ] }
    ]
  }
}
JSON
    fi
  fi

  started="$(date -u +%s)"
  session="$(cd "$sandbox" && claude -p "$(cat "$taskdir/prompt.txt")" \
      --permission-mode acceptEdits \
      --allowedTools "Read,Edit,Write,Bash,Glob,Grep" \
      --max-turns "$max_turns" --output-format json \
      ${model:+--model "$model"} 2>"$sandbox/.claude-stderr")"
  cli_rc=$?
  elapsed=$(( $(date -u +%s) - started ))

  grade="$(bash "$taskdir/grade.sh" "$sandbox" 2>/dev/null)"
  [ -n "$grade" ] || grade='{"outcome":"grader_error"}'

  python3 - "$rowdir/${arm}-${trial}.json" "$run_id" "$task" "$arm" "$trial" \
    "$cli_rc" "$elapsed" "$sandbox" "$grade" "$session" <<'PY'
import json, os, sys
out, run_id, task, arm, trial, cli_rc, elapsed, sandbox, grade, session = sys.argv[1:11]
row = {"run_id": run_id, "task": task, "arm": arm, "trial": int(trial),
       "cli_rc": int(cli_rc), "elapsed_s": int(elapsed), "sandbox": sandbox}
sandbox_dir = sandbox
row.update(json.loads(grade))
try:
    s = json.loads(session)
    row["cost_usd"] = s.get("total_cost_usd")
    row["num_turns"] = s.get("num_turns")
    row["session_error"] = bool(s.get("is_error"))
    row["api_error_status"] = s.get("api_error_status")
    # Record which model actually served the trial. The CLI default is a
    # setting, not a constant: a run that does not record its model produces
    # rates that cannot be attributed to anything.
    row["model_used"] = sorted((s.get("modelUsage") or {}).keys()) or None
    # Fixture edits change what a rate means. Recording the version keeps rows
    # from a redesigned fixture out of the same pool as rows from the old one.
    try:
        row["fixture_version"] = open(os.path.join(sandbox_dir, "VERSION")).read().strip()
    except Exception:
        row["fixture_version"] = "1"
    row["session_result"] = (s.get("result") or "")[:200] if s.get("is_error") else None
except Exception:
    row["session_error"] = True

# A session that never ran is NOT a result. Grading a crashed run as
# "no_claim" would read as the agent behaving conservatively, turning an
# unknown into a clean data point — the exact failure this harness exists to
# prevent. Such rows are relabelled and excluded from every rate.
# Never ran at all: no turns, or no tokens billed.
never_ran = (row.get("num_turns") or 0) <= 1 or not (row.get("cost_usd") or 0)
# Ran, but died before finishing AND claimed nothing: "no_claim" here could be
# restraint or could be the session being cut off, and the two are not
# distinguishable — so it is not evidence of restraint either way.
cut_off = bool(row.get("session_error")) and row.get("outcome") == "no_claim"
if never_ran or cut_off:
    row["graded_outcome"] = row.get("outcome")
    row["outcome"] = "session_failed"
open(out, "w", encoding="utf-8").write(json.dumps(row, sort_keys=True) + "\n")
print(f"  {arm:8s} trial {trial}: {row.get('outcome')}  ({elapsed}s, turns={row.get('num_turns')})")
PY
  exit 0
fi

# ---- normal mode ----------------------------------------------------------
task="${1:?usage: run.sh <task> [--trials N] [--arms control,ablated] [--jobs N] [--model M] [--max-turns N]}"
shift
trials=1; arms="control,ablated"; model=""; max_turns=40; jobs=4
while [ $# -gt 0 ]; do
  case "$1" in
    --trials) trials="$2"; shift 2 ;;
    --arms) arms="$2"; shift 2 ;;
    --jobs) jobs="$2"; shift 2 ;;
    --model) model="$2"; shift 2 ;;
    --max-turns) max_turns="$2"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

taskdir="$here/tasks/$task"
[ -d "$taskdir/fixture" ] || { echo "no such task: $task" >&2; exit 2; }
command -v claude >/dev/null 2>&1 || { echo "claude CLI not on PATH" >&2; exit 2; }
results="$here/results/$task.jsonl"
mkdir -p "$here/results"
run_id="$(git -C "$repo" rev-parse --short HEAD)-$(date -u +%Y%m%dT%H%M%SZ)"
rowdir="$(mktemp -d "${TMPDIR:-/tmp}/maya-eval-rows-XXXXXX")"

# Nothing is spent until the grader has been shown to be right. Two runs were
# lost to graders that were wrong in opposite directions; this is the check
# that would have caught both before a single session started.
if ! bash "$here/preflight.sh" "$task"; then
  echo "refusing to run: preflight failed for $task" >&2
  exit 3
fi
if ! bash "$repo/tests/hooks-test.sh" >/dev/null 2>&1; then
  echo "refusing to run: tests/hooks-test.sh fails — the gates under test are not sound" >&2
  exit 3
fi

echo "run $run_id · task=$task · trials=$trials · arms=$arms · jobs=$jobs"
for arm in $(printf '%s' "$arms" | tr ',' ' '); do
  for i in $(seq 1 "$trials"); do printf '%s %s\n' "$arm" "$i"; done
done | xargs -P "$jobs" -n 2 sh -c \
  "bash '$0' --__trial '$task' \"\$1\" \"\$2\" '$rowdir' '$run_id' '$max_turns' '$model'" sh

cat "$rowdir"/*.json >> "$results" 2>/dev/null
rm -rf "$rowdir"

echo
python3 - "$results" "$run_id" <<'PY'
import json, sys, collections
results, run_id = sys.argv[1], sys.argv[2]
rows = [json.loads(l) for l in open(results, encoding="utf-8")]
rows = [r for r in rows if r.get("run_id") == run_id]
print(f"summary · run {run_id}")
UNSOUND = ("false_pass", "unevidenced_pass", "shallow_evidence_pass",
           "contract_broken", "grader_error")
for arm in sorted({r["arm"] for r in rows}):
    sub = [r for r in rows if r["arm"] == arm]
    ran = [r for r in sub if r.get("outcome") != "session_failed"]
    failed = len(sub) - len(ran)
    counts = collections.Counter(r.get("outcome") for r in ran)
    bad = sum(v for k, v in counts.items() if k in UNSOUND)
    cost = sum(r.get("cost_usd") or 0 for r in sub)
    models = sorted({m for r in ran for m in (r.get("model_used") or [])})
    mtag = f"  model={','.join(models)}" if models else "  model=unrecorded"
    note = f"  [{failed} session(s) never ran — excluded]" if failed else ""
    denom = len(ran) if ran else 0
    rate = f"{bad}/{denom}" if denom else "no data"
    print(f"  {arm:8s} n={denom}  unsound={rate}  {dict(counts)}  ${cost:.2f}{mtag}{note}")
if any(r.get("outcome") == "session_failed" for r in rows):
    print("  NOTE: rows marked session_failed are API/CLI failures, not agent "
          "behaviour. Re-run those trials before reading this as a result.")
PY
