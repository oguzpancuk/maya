#!/usr/bin/env bash
# THE verification battery — the single source of truth for "green".
# CI runs this same file. /new-product replaces the placeholder below with
# the product's real commands (typecheck, lint, tests, build).
set -euo pipefail
cd "$(dirname "$0")/../.."

# An unconfigured battery FAILS. This file is the required status check that
# gates every merge, so a placeholder that exits 0 would be a green light on
# nothing. /new-product must replace this block.
echo "FAIL: verify.sh is not configured yet — this battery verifies NOTHING." >&2
echo "Fill it with the real stack commands (see CLAUDE.md commands table)." >&2
# [STACK: replace everything below with the real battery. Three rules:
# (1) attempt EVERY step even after a failure, then report them together —
# a run that stops at the first error hides the rest; (2) a package with
# missing node_modules is a FAIL ("run npm ci"), never a silent skip — what
# cannot be verified is not verified; (3) a step this OS cannot run at all
# (xcodebuild on Linux) is reported as "NOT RUN here — <ci job> is the run",
# a third state beside ok/FAIL: it does not fail the battery, it is never
# silent, and the CI job named is a required check; (4) every tracked *.sh
# keeps its exec bit — an agent's write-then-rename drops it, no content
# diff shows it, and the script just stops running. Pattern:
#
#   fail=0; results=()
#   bad="$(git -c core.quotePath=false ls-files -- '*.sh' | while IFS= read -r f; do [ -x "$f" ] || printf ' %s' "$f"; done)"
#   [ -z "$bad" ] && results+=("ok   exec bits") || { results+=("FAIL exec bits:$bad (chmod +x, git update-index --chmod=+x)"); fail=1; }
#   step() { name="$1" dir="$2"; shift 2
#     [ -d "$dir/node_modules" ] || { results+=("FAIL $name — deps missing"); fail=1; return; }
#     (cd "$dir" && "$@") && results+=("ok   $name") || { results+=("FAIL $name"); fail=1; }
#   }
#   step "typecheck" app npx tsc --noEmit
#   step "tests"     app npm test
#   printf '%s\n' "${results[@]}"; exit $fail
# ]
exit 1
