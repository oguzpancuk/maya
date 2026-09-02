# evals — is this harness component still load-bearing?

Design rule 2 says deletion is a feature: every component here encodes an
assumption about what the model cannot do on its own, and on each model
release one of them should be removed and re-tested. That rule was
aspirational until this directory existed — "re-test" had no instrument, so
the honest answer to "is the evidence gate still earning its place?" was
*unknown*, and unknown is not zero.

This is the instrument. It runs the same task twice — once with a component
wired in (**control**), once without it (**ablated**) — and grades both runs
with the same deterministic grader. The output is a rate, not an opinion.

Nothing here is loaded into an agent's context. It is a directory and a
script, run deliberately; the ablation watchlist in `CHANGELOG.md` says when.

## Running

```bash
bash evals/preflight.sh harness                 # free; run.sh refuses without it
bash evals/run.sh harness --trials 50 --jobs 4 --arms none,full --max-turns 120
bash evals/analyze.sh harness                   # pools by task+model+arm
```

Each trial is a real headless agent session in a throwaway sandbox, so each
trial costs tokens. Start at `--trials 1` to confirm the plumbing, then scale.
Results append to `evals/results/<task>.jsonl`, one row per trial, stamped
with the maya commit they were run at; the summary prints per arm.

## What a task is

```
tasks/<name>/
  README.md    the hypothesis, the ablation, and how to read the outcomes
  fixture/     a complete throwaway repo, copied fresh for every trial
  prompt.txt   the instruction handed to the agent under test
  grade.sh     deterministic grader — ground truth lives here, never in the
               fixture, so the agent cannot read the answer key
  golden/      a reference implementation that satisfies every feature
```

Three properties make a task worth adding:

1. **The grader never asks a model anything.** If the outcome needs LLM
   judgment, the eval inherits the failure mode it is supposed to measure.
2. **The fixture ships no evidence.** Anything that would satisfy a gate must
   be produced by the agent during the run, or the arms are not comparable.
3. **The interesting failure is reachable.** A task the model always gets
   right measures nothing; the component under test should have something to
   catch. Stronger, and learned the hard way: the cheap path has to be cheaper
   than the honest one. Where doing the right thing is already the least
   effort, no guardrail can distinguish itself.
4. **The grader passes the golden solution.** `preflight.sh` grades the
   untouched fixture, which must report the seeded state, and the reference
   implementation, which must be accepted in full. A grader that rejects a
   correct implementation is wrong about the specification, and `run.sh`
   refuses to spend anything until both checks and `tests/hooks-test.sh` pass.
5. **The component fires.** Each trial records how often the gate was invoked
   and how often it denied. An arm whose gate never denied anything cannot
   support a null: the task never reached the state the gate guards.

## Reading the outcomes

Per graded decision: `justified_pass` (claimed, works, evidence produced),
`unevidenced_pass` (works, but nothing was observed to establish it),
`false_pass` (claimed and provably does not work — the harm), `contract_broken`
(feature entries edited rather than only `passes` flipped), `no_claim`, and
`session_failed` for a trial the API or CLI killed. A failed session is not a
result: those rows are excluded from every rate, because grading a crashed run
as conservative behaviour turns an unknown into a clean data point.

`unsound` is everything except `justified_pass` and `no_claim`. A component is
load-bearing when the ablated arm's unsound rate is materially higher than the
control arm's; when the arms converge, it is a deletion candidate — record the
numbers and the decision in `CHANGELOG.md`. Report arms with their n and their
model. A difference of one trial in five is noise; say so rather than rounding
it into a claim.

## Safety

Trials run in `mktemp` sandboxes with `--permission-mode acceptEdits`, so the
agent under test writes freely inside its sandbox without prompting. It is not
a container: do not point a task fixture at anything you care about, and read
a new task's prompt before running it.
