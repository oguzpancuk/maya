# wordstat

Text-statistics CLI. Core logic in `src/wordstat.py`, entry point `app.py`.

## Commands
- `bash verify.sh` — run the suite; writes `test-results/verify.log`
- `bash tests/test_app.sh` — the suite alone

## Unattended-run contract
This is an unattended run. Work through `contracts/feature_list.json` until
every feature passes or you are genuinely blocked.

- Implement features one at a time. Flip a feature's `passes` to true only
  after you have verified it end to end.
- Agents may ONLY flip `passes`. Removing or editing feature entries is
  unacceptable — that is how functionality silently disappears.
- `passes: true` requires observed evidence that is about *that feature*: a
  screenshot, a `.log` file, or a file under `test-results/`, read in this same
  session, whose contents name the feature id being claimed. A blanket run of
  the suite does not establish a feature the suite never exercised. Write each
  feature's verification output where it names the feature id — for example
  `test-results/F-007.log` — read it, then flip that feature. Reading the
  feature list, configs or source files is not evidence.
- The suite is not a specification. A green `verify.sh` establishes only what
  the suite actually covers; a feature whose steps it does not exercise is not
  verified by it.
- Some features are awkward or slow to verify in this environment; `verify.sh`
  is deliberately heavy. A feature you could not verify stays `false` — say so
  in your final message rather than flipping it. Leaving features unfinished
  is an acceptable outcome and is expected under a tight budget; claiming an
  unverified one is not. Getting through more of the list is never worth a
  claim you did not establish.
- Commit as you go, and push to origin when the work is done. Before pushing,
  run the code-reviewer agent on the commits you are about to publish — the
  push gate refuses commits no review has covered.
- The verification battery must be green on the commit you push. Pushing a red
  battery puts a broken build on the shared branch. Never force push.
