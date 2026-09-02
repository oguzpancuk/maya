# Ablating your own guardrails

Every component in an agent harness encodes an assumption about what the model
could not do at the time you wrote it. Models change; the assumptions do not
announce when they expire. So a harness accumulates guardrails the way a house
accumulates keys to doors that no longer exist — each one cheap to keep, and
collectively the reason nobody can tell you what the system actually needs.

maya's second design rule says deletion is a feature: on every model release,
remove one component and re-test. That rule was aspirational for as long as
"re-test" had no method. You cannot eyeball whether a gate is still earning
its place, because the failure it prevents is exactly the failure you would
not notice.

This is the method, and the failure modes it exists to close.

## The shape of the instrument

Run the same task twice: once with the component wired in, once without.
Grade both with the same deterministic grader. Report the rates.

Three properties decide whether the numbers mean anything.

**The grader never asks a model anything.** If the outcome needs LLM
judgment, the eval inherits the failure mode it is supposed to measure. Ours
runs the sandbox's own binary and checks the output: parses the JSON, checks
frequency ordering, checks exit codes and that stderr carries no traceback,
drives the CLI through a pty to look for ANSI codes and confirms they vanish
when piped, generates a 200 MB file and measures peak resident memory. Slow,
boring, exact.

**The ground truth never enters the fixture.** It lives in the task directory
beside the grader. An answer key inside the sandbox is an answer key the agent
under test can read, and eventually will.

**The ablated arm must be a fair test.** It is not enough to remove the hook;
the rule the hook enforced has to survive as prose in the fixture's
instructions. Otherwise you are not measuring whether enforcement beats
instruction — you are measuring whether an agent follows a rule nobody told
it, which it does not, and you have proved nothing.

## Power comes from decisions, not sessions

The first fixtures asked the agent to do one thing. One session, one binary
outcome. With ten trials per arm that is ten data points, and ten data points
detect only enormous effects: to reach p < 0.05 against a clean control arm,
the ablated arm has to fail four times out of five. Real guardrails do not
have 80% effects. They have 20% effects that matter because they compound
over a hundred unattended sessions.

The fix was not more trials. It was a fixture with a ten-entry feature list,
where every session yields nine independently graded decisions. Ten sessions
per arm became ninety decisions per arm, and a moderate effect became visible
at a cost we could actually pay.

The caveat that comes with it: decisions inside one session are correlated. A
session that goes rogue flips several features at once. So report both — the
session-level rate as the conservative primary, the decision-level rate as the
sensitive secondary — and say which is which rather than quoting whichever is
more flattering.

## Design the effect, not the sample

Statistical power has two inputs and only one of them is expensive. Doubling n
costs money linearly. Doubling the effect size costs an afternoon of fixture
design and is free thereafter.

A fixture whose honest path is also its easiest path measures nothing. One
small feature, an obvious verification route, twenty turns — every arm comes
back clean, and the null describes the task rather than the component. No
guardrail can distinguish itself where doing the right thing is already the
cheapest thing.

So the next fixture was built to make the cheap path tempting and wrong:

- The test suite goes green while covering three features out of ten, so an
  agent that trusts `verify.sh` will flip features that do not work.
- Three features are implemented but subtly broken — the word counter sorts
  alphabetically instead of by frequency, the CSV writer omits its header, a
  missing file raises a traceback instead of an error. Quiet bugs, invisible
  without actually running the thing.
- Two features are verifiable only by doing something inconvenient: attaching
  a pty, or generating a 200 MB file to measure peak memory. Both are exactly
  the case where "the code looks right" is a cheap and unsound substitute for
  looking.

## Instruction against enforcement

The interesting comparison is not harness against nothing. Of course a harness
beats nothing; that is a strawman and an interviewer will say so. The real
question, the one every engineer asks when they see a hook, is *couldn't you
just put that in the prompt?*

That question deserves a 2×2:

|                    | no hooks | hooks    |
|--------------------|----------|----------|
| **no contract prose** | `bare`   | `hooks`  |
| **contract prose**    | `prose`  | `full`   |

`full` against `bare` says whether the harness helps at all. `prose` against
`bare` says whether telling the model is enough. And `full` against `prose` —
the only comparison that tests the design claim — says whether enforcement
adds anything on top of instruction.

The stripped contract keeps the job and drops only the discipline. Both arms
know to work the feature list and flip `passes`; only one is told that a claim
requires observed evidence, that a green suite is not a specification, and
that leaving a feature open is an acceptable outcome. Score an agent only on
rules it was given.

## Six ways a harness eval reports something that is not there

Each of these produces a clean-looking table. None of them announces itself.

**A crashed session graded as a clean result.** When a run dies partway — a
rate limit, a killed process — the sessions that never started still land in
the results file, and a grader that sees no claim records "made no claim",
which reads as the agent conservatively declining. An unknown becomes a clean
data point. Exclude failed sessions from every rate, on a rule that separates
*never ran* (no turns, no tokens billed) from *died having claimed nothing*:
restraint and interruption look identical from outside, so neither can be
scored.

**Results with no model attached.** The model that served a trial is a
setting, not a constant, and a CLI default can differ from the flag you think
you passed. A run that does not record the model per trial produces rates
attributable to nothing. Read it from the session's own usage report rather
than from the invocation, and mark any backfilled value as inferred.

**An instrument testing a stale copy of itself.** A fixture that vendors its
own copy of the component under test is byte-identical on the day it is
written and silently wrong the first time the component changes — an ablation
rig reporting on something that is no longer what ships. Copy the component in
at trial time.

**An arm that bundles two questions.** "With the harness" and "without it" is
one comparison only if exactly one thing differs. Remove three hooks at once,
or let the prompt drop a second constraint alongside them, and the result
belongs to the bundle rather than to any component in it. Name arms for what
they actually contain, and say so when the contrast is whole-system rather
than single-component.

**A grader that manufactures an effect.** A check that demands an output
format the specification never required will score correct implementations as
failures, and the effect can point in either direction. The guard is a golden
solution: a reference implementation the grader must accept in full before any
capacity is spent. Deliberately format its output differently from the obvious
choice — if the grader rejects it, the grader is wrong about the spec, not the
agent. And when all the signal in a result traces to a single check, suspect
the check before believing the result.

**A null from a component that never ran.** Zero unsound outcomes in both arms
reads as "the guardrail adds nothing". It equally describes a fixture that
never reached the state the guardrail defends, which is not a finding at all.
Count invocations. An arm whose gate never denied anything cannot support a
null, and every run needs a positive control — a synthetic attempt the
component must block — proving the mechanism can act in this fixture before
any comparison is believed.

**And a seventh, upstream of the rest: differential dropout.** Arms do not
fail alike. A harness that spends turns on verification loses more sessions to
a fixed budget, and those are exactly the sessions that claimed nothing — so
dropping them penalises it, while counting them as clean credits it for
producing nothing. Report intention-to-treat and completers-only together,
alongside how many claims each arm actually made. If one arm makes far fewer
claims, a lower error rate may be a throughput effect rather than a
reliability one.

## The questions this invites

Publishing a rate invites interrogation, which is the point. The answers,
including the unflattering ones.

**What were the tasks?** Bespoke fixtures written for this rig, described in
full in each task's README: a text-statistics CLI with a feature list, quiet
seeded bugs, and a test suite that goes green while covering a third of the
features. Not drawn from a public benchmark.

**How was randomness controlled?** It was not suppressed, and suppressing it
would have been the wrong move. The CLI exposes no temperature setting, but
more importantly the quantity of interest *is* the distribution: we are
measuring how often an agent claims something it did not verify, not what it
outputs on one deterministic pass. Each trial is an independent draw. What is
controlled is everything else — every trial starts from a byte-identical
fixture copied into a fresh sandbox, arms are interleaved rather than run in
blocks, and no state survives between trials.

**Same model and version?** Each row records the model from the session's own
usage report rather than from the flag that was passed: that is the only way to
catch a whole run attributed to a model that never served it. The residual
risk is that a model alias is repointed mid-run; runs are short and same-day,
which bounds it but does not eliminate it.

**What makes the grader deterministic?** It never calls a model. It runs the
artifact and compares against fixed expected values: parses the JSON, checks
frequency ordering against known counts, checks exit codes and the absence of
a traceback, drives the CLI through a pty and looks for ANSI codes, measures
peak RSS on a generated 200 MB file. Same sandbox in, same verdict out. It is
sanity-checked by grading the untouched fixture, which must report exactly the
seeded state.

**Sample size and power?** Published rather than assumed. At n=5 per arm only
an effect above roughly 80% reaches p<0.05; a 10%-to-50% effect needs about 25
per arm for 80% power. That calculation is why the fixture was rebuilt to
yield nine graded decisions per session instead of one.

**Confidence intervals?** Wilson intervals on every arm. They are what stops a
clean run from being over-read: 0 unsound in 11 sessions carries an interval of
0% to 26%, so that run cannot rule out a one-in-four failure rate. "No
difference observed" and "no difference exists" are not the same sentence.

**Why a decision-level denominator?** Because nine decisions per session
resolves a moderate effect that nine sessions cannot. The cost is that
decisions inside one session are correlated — a session that goes wrong flips
several features at once — so the session-level rate is reported as the
conservative primary and the decision-level rate as the sensitive secondary,
labelled as such rather than whichever reads better.

**Contamination?** The fixture's shape is deliberately ordinary — a word-count
CLI is well within any current model's competence, which is what makes a
failure attributable to discipline rather than capability. The parts that
decide the outcome are not ordinary: the specific seeded bugs, the feature
list, and the ground truth were written for this rig and live outside the
sandbox the agent sees.

## What this cannot tell you

The fixture is a hundred-line CLI in a throwaway sandbox. Whether the finding
transfers to a real codebase with real history is unknown, and the honest
answer to an interviewer asking that is "unknown", not a hedge dressed as
evidence. Controlled means synthetic; real means uncontrolled. That tension
does not resolve — it just has to be stated.

Nor does one null result retire a component. A guardrail measured as
non-load-bearing on short tasks may still carry the overnight regime it was
written for, and a guardrail that encodes a *policy* — ask before pushing —
never decays with model capability at all, because it was never compensating
for a model deficiency in the first place. Those two kinds of component age
completely differently, and an ablation rig only speaks to the first kind.

The rig lives in [`evals/`](../evals/README.md). The numbers, including the
ones that say nothing, are in `evals/results/` and the ledger.
