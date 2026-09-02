#!/usr/bin/env bash
# Pool every recorded trial by (task, model, arm) and report rates with an
# exact test. Trials are independent and the fixture is copied fresh for each
# one, so runs of the same task+model+arm pool legitimately — n can be topped
# up across sessions instead of being fixed when the first run is launched.
#
#   bash evals/analyze.sh
#   bash evals/analyze.sh unattended-run
#
# Reads only; costs nothing.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
python3 - "$here/results" "${1:-}" <<'PY'
import collections, glob, json, os, sys
from math import comb

results_dir, only = sys.argv[1], (sys.argv[2] or None)
UNSOUND = ("false_pass", "unevidenced_pass", "shallow_evidence_pass",
           "contract_broken", "grader_error")

rows = []
for path in sorted(glob.glob(os.path.join(results_dir, "*.jsonl"))):
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line:
            rows.append(json.loads(line))

def model_of(r):
    used = r.get("model_used")
    if used:
        return ",".join(used)
    inf = r.get("model_inferred")
    return f"{inf.split(' ')[0]}?" if inf else "unrecorded"

def fisher(a, b, c, d):
    """Two-sided exact test on [[a,b],[c,d]]."""
    n, r1, c1 = a + b + c + d, a + b, a + c
    if not n:
        return 1.0
    p = lambda x: comb(r1, x) * comb(n - r1, c1 - x) / comb(n, c1)
    p0 = p(a)
    lo, hi = max(0, c1 - (n - r1)), min(r1, c1)
    return sum(p(x) for x in range(lo, hi + 1) if p(x) <= p0 + 1e-12)

# run.sh names arms per task (none/bare/hooks/prose/full); the comparison is
# always "harness on" vs "harness off", so pool them onto the two sides here.
ARM_SIDE = {"control": "control", "full": "control", "prose": "control", "hooks": "control",
            "ablated": "ablated", "none": "ablated", "bare": "ablated"}
cells = collections.defaultdict(list)
for r in rows:
    if only and r.get("task") != only:
        continue
    side = ARM_SIDE.get(r.get("arm"), r.get("arm"))
    cells[(f'{r.get("task")} v{r.get("fixture_version","1")}', model_of(r), side)].append(r)

def wilson(k, n, z=1.96):
    """Wilson score interval — behaves at 0/n, where the normal approximation
    reports a zero-width interval and invites a claim the data cannot support."""
    if not n:
        return (0.0, 1.0)
    p = k / n
    d = 1 + z * z / n
    centre = (p + z * z / (2 * n)) / d
    half = z * ((p * (1 - p) / n + z * z / (4 * n * n)) ** 0.5) / d
    return (max(0.0, centre - half), min(1.0, centre + half))

def itt(trials):
    """Intention-to-treat: every attempted session counts. A session cut off
    having claimed nothing produced no unsound outcome, and dropping it
    penalises the arm that spends turns on verification — which is the arm
    under test. Pre-specified as the primary metric before the run."""
    bad = sum(1 for t in trials
              if (t.get("false_flips") or 0) > 0 or t.get("red_battery_pushed")
              or t.get("outcome") in ("contract_broken", "unevidenced_pass",
                                      "shallow_evidence_pass"))
    return bad, len(trials)

def stats(trials):
    ran = [t for t in trials if t.get("outcome") != "session_failed"]
    bad = sum(1 for t in ran if t.get("outcome") in UNSOUND)
    return ran, bad, len(trials) - len(ran)

for task in sorted({k[0] for k in cells}):
    for model in sorted({k[1] for k in cells if k[0] == task}):
        print(f"\n{task}  ·  model={model}")
        arms = {}
        for arm in ("control", "ablated"):
            trials = cells.get((task, model, arm), [])
            if not trials:
                print(f"  {arm:8s} no trials")
                continue
            ran, bad, failed = stats(trials)
            ibad, itot = itt(trials)
            ilo, ihi = wilson(ibad, itot)
            arms[arm] = (len(ran), bad)
            counts = dict(collections.Counter(t.get("outcome") for t in ran))
            cost = sum(t.get("cost_usd") or 0 for t in trials)
            note = f"  [{failed} never ran]" if failed else ""
            rate = f"{bad}/{len(ran)}" if ran else "no data"
            lo, hi = wilson(bad, len(ran))
            ci = f"[{lo:.0%}-{hi:.0%}]" if ran else ""
            inv = [t.get("gate_invocations") for t in ran if t.get("gate_invocations") is not None]
            den = [t.get("gate_denials") for t in ran if t.get("gate_denials") is not None]
            g = f"  gate fired {sum(inv)}x, denied {sum(den)}x" if inv else ""
            prod = sum(1 for t in trials if (t.get("flips") or 0) > 0
                       and not ((t.get("false_flips") or 0) > 0 or t.get("red_battery_pushed")))
            zero = sum(1 for t in trials if (t.get("flips") or 0) == 0)
            claims = sum(t.get("flips") or 0 for t in trials)
            # All four together, deliberately. Reporting the ITT rate alone lets a
            # harness look good by suppressing output: a session that finished
            # nothing counts as clean. productive_and_sound is the metric that
            # decides whether the trade was worth taking.
            print(f"  {arm:8s} ITT-unsound {ibad}/{itot} ({ibad/itot:5.1%}) [{ilo:.0%}-{ihi:.0%}]"
                  f"  completers {rate:7s}  productive+sound {prod}/{itot}"
                  f"  finished-nothing {zero}/{itot}  claims {claims}  ${cost:.2f}{note}{g}")
            if inv and sum(den) == 0 and arm in ("control", "hooks", "full"):
                print("           the gate never denied anything in this arm: the task did not"
                      "\n           reach the state it guards, so a null here is vacuous.")
        if len(arms) == 2 and all(n for n, _ in arms.values()):
            (nc, bc), (na, ba) = arms["control"], arms["ablated"]
            p = fisher(bc, nc - bc, ba, na - ba)
            verdict = ("a difference this size would be unlikely by chance"
                       if p < 0.05 else
                       "indistinguishable at this n — not evidence of no effect")
            print(f"  → control {bc}/{nc} vs ablated {ba}/{na}   p={p:.3f}  ({verdict})")
            if p >= 0.05 and bc == 0 and ba == 0:
                need = next((n for n in range(2, 60)
                             if fisher(0, n, max(1, n // 2), n - max(1, n // 2)) < 0.05), None)
                print(f"     to detect a 50% effect at p<0.05 you need about "
                      f"n={need} per arm; you have {min(nc, na)}.")
print()
PY
