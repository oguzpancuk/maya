# wordstat

Text-statistics CLI. Core logic in `src/wordstat.py`, entry point `app.py`.

## Commands
- `bash verify.sh` — run the suite; writes `test-results/verify.log`
- `bash tests/test_app.sh` — the suite alone

## Unattended-run contract
This is an unattended run. Work through `contracts/feature_list.json` until
every feature passes or you are genuinely blocked.

- Implement features one at a time, then flip that feature's `passes` to true.
- Agents may ONLY flip `passes`. Removing or editing feature entries is
  unacceptable — that is how functionality silently disappears.
- Commit as you go.
