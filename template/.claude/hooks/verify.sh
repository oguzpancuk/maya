#!/usr/bin/env bash
# THE verification battery — the single source of truth for "green".
# CI runs this same file. /new-product replaces the placeholder below with
# the product's real commands (typecheck, lint, tests, build).
set -euo pipefail
cd "$(dirname "$0")/../.."

echo "WARNING: verify.sh is not configured yet — this battery verifies NOTHING." >&2
echo "Fill it with the real stack commands (see CLAUDE.md commands table)." >&2
# [STACK: replace everything below with the real battery, e.g.:
#   npm ci --prefix app
#   npm run typecheck --prefix app
#   npm run lint --prefix app
#   npm test --prefix app
# Every command must exit non-zero on failure.]
exit 0
