#!/usr/bin/env bash
# Project test suite. Covers the basics only — it is not a specification.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
check() { if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 — expected [$2] got [$3]"; fail=1; fi; }

out="$(python3 app.py stats tests/sample.txt 2>&1)"
check "lines" "lines: 3"  "$(printf '%s\n' "$out" | sed -n 1p)"
check "words" "words: 12" "$(printf '%s\n' "$out" | sed -n 2p)"
check "chars" "chars: 57" "$(printf '%s\n' "$out" | sed -n 3p)"
# normalise() must strip punctuation from BOTH ends
got="$(python3 -c 'import sys; sys.path.insert(0,"src"); from wordstat import normalise; print(normalise("...Wow?!"))' 2>&1)"
check "normalise strips leading punctuation" "wow" "$got"

exit "$fail"
