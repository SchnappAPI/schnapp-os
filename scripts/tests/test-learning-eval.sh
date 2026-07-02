#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/learning-eval.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
A="$tmp/archive.tsv"

# ABSENT archive (the CI-runner reality: it is git-ignored) -> SKIP, not a false "no history"
out="$(bash "$SCRIPT" "$A" 2>&1)"; check "$?" 0 "missing archive exits 0"
check "$(printf '%s' "$out" | grep -c 'SKIP - archive not present')" 1 "missing archive says SKIP"
check "$(printf '%s' "$out" | grep -c 'no learning history')" 0 "missing archive does NOT claim no-history"

# exists-but-EMPTY archive -> the genuine "no learning history yet"
: > "$A"
out="$(bash "$SCRIPT" "$A" 2>&1)"; check "$?" 0 "empty archive exits 0"
check "$(printf '%s' "$out" | grep -c 'no learning history')" 1 "empty archive message"

# one unique capture
printf '2026-06-01T00:00:00Z\tcorrection\tthe sql port is 1433\n' > "$A"
out="$(bash "$SCRIPT" "$A" 2>&1)"
check "$(printf '%s' "$out" | grep -c 'processed: 1 | unique topics: 1 | recurred topics: 0')" 1 "single-capture summary"
check "$(printf '%s' "$out" | grep -ci 'RECURRED:')" 0 "no recurrence for a unique topic"

# same topic on a later date (and a 'test:' prefix to prove normalization) -> recurrence
printf '2026-06-10T00:00:00Z\tcorrection\ttest: The SQL port is 1433\n' >> "$A"
out="$(bash "$SCRIPT" "$A" 2>&1)"
check "$(printf '%s' "$out" | grep -c 'recurred topics: 1')" 1 "recurrence counted"
check "$(printf '%s' "$out" | grep -ci 'RECURRED:')" 1 "recurrence flagged"

# a distinct topic stays separate
printf '2026-06-12T00:00:00Z\tcorrection\talways quote op refs with spaces\n' >> "$A"
out="$(bash "$SCRIPT" "$A" 2>&1)"
check "$(printf '%s' "$out" | grep -c 'unique topics: 2')" 1 "distinct topic counted separately"
check "$(printf '%s' "$out" | grep -c 'recurred topics: 1')" 1 "still one recurrence"

# always exit 0 (read-only)
bash "$SCRIPT" "$A" >/dev/null 2>&1; check "$?" 0 "exits 0 (read-only)"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
