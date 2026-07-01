#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/learning-worker.sh"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
Q="$tmp/q.tsv"; A="$tmp/q.archive.tsv"

# empty queue → clean no-op
out="$(LEARNING_QUEUE="$Q" LEARNING_ARCHIVE="$A" bash "$SCRIPT" --dry-run 2>&1)"; check "$?" 0 "empty queue exits 0"
check "$(printf '%s' "$out" | grep -c 'nothing to consolidate')" 1 "empty queue message"

# two captures → dry-run reports two, writes nothing to memory/rules, archives both
printf '2026-06-27T00:00:00Z\tcorrection\tthe port is 1433 not 1533\n' >  "$Q"
printf '2026-06-27T00:01:00Z\tcorrection\talways quote op refs with spaces\n' >> "$Q"
# real safety assertion: the dry-run must not dirty memory/ or rules/
git_before="$(git -C "$REPO_ROOT" status --porcelain -- memory/ rules/ 2>/dev/null)"
out="$(LEARNING_QUEUE="$Q" LEARNING_ARCHIVE="$A" bash "$SCRIPT" --dry-run 2>&1)"; check "$?" 0 "dry-run exits 0"
check "$(printf '%s' "$out" | grep -c 'would distill+route')" 2 "dry-run reports both captures"
check "$([ -f "$A" ] && wc -l < "$A" | tr -d ' ' || echo 0)" 2 "both processed lines archived"
check "$([ -s "$Q" ] && echo nonempty || echo empty)" "empty" "queue drained after processing"
git_after="$(git -C "$REPO_ROOT" status --porcelain -- memory/ rules/ 2>/dev/null)"
check "$git_after" "$git_before" "dry-run wrote nothing under memory/ or rules/"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
