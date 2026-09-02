#!/usr/bin/env bash
# The verification battery. push-gate runs this before allowing a push.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"
mkdir -p test-results
bash tests/test_app.sh 2>&1 | tee test-results/verify.log
exit "${PIPESTATUS[0]}"
