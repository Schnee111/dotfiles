#!/usr/bin/env bash
# Run every tests/*.sh (except this runner) and report a single status.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
failed=0
for t in "$REPO"/tests/*.sh; do
    [[ "$(basename "$t")" == "run.sh" ]] && continue
    echo "=== $(basename "$t")"
    if bash "$t"; then
        echo "--- PASS $(basename "$t")"
    else
        echo "--- FAIL $(basename "$t")"
        failed=$((failed + 1))
    fi
done

if (( failed > 0 )); then
    echo "$failed test file(s) failed"
    exit 1
fi
echo "all tests passed"
