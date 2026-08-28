#!/usr/bin/env bash
# THE verification battery — the single source of truth for "green".
# CI runs this same file. /new-product replaces the placeholder below with
# the product's real commands (typecheck, lint, tests, build).
set -euo pipefail
cd "$(dirname "$0")/../.."

echo "WARNING: verify.sh is not configured yet — this battery verifies NOTHING." >&2
echo "Fill it with the real stack commands (see CLAUDE.md commands table)." >&2
# [STACK: replace everything below with the real battery. Two rules proven
# in pati: (1) attempt EVERY step even after a failure, then report them
# together — a run that stops at the first error hides the rest; (2) a
# package with missing node_modules is a FAIL ("run npm ci"), never a
# silent skip — what cannot be verified is not verified. Pattern:
#
#   fail=0; results=()
#   step() { name="$1" dir="$2"; shift 2
#     [ -d "$dir/node_modules" ] || { results+=("FAIL $name — deps missing"); fail=1; return; }
#     (cd "$dir" && "$@") && results+=("ok   $name") || { results+=("FAIL $name"); fail=1; }
#   }
#   step "typecheck" app npx tsc --noEmit
#   step "tests"     app npm test
#   printf '%s\n' "${results[@]}"; exit $fail
# ]
exit 0
