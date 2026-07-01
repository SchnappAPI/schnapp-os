#!/usr/bin/env bash
set -uo pipefail
HOOK="$(cd "$(dirname "$0")/../../hooks" && pwd)/capture-nudge.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/scheduled-tasks"
Q="$tmp/scheduled-tasks/.learning-queue.tsv"

# a correction enqueues exactly one record, tagged 'correction'
printf "you're wrong, the port is 1433" | CLAUDE_PROJECT_DIR="$tmp" bash "$HOOK" >/dev/null 2>&1
check "$?" 0 "hook exits 0 on correction"
check "$([ -f "$Q" ] && wc -l < "$Q" | tr -d ' ' || echo 0)" 1 "one queue record after a correction"
check "$(cut -f2 "$Q" | head -1)" "correction" "record tagged correction"
check "$(grep -c 'port is 1433' "$Q")" 1 "prompt text captured"

# a non-correction enqueues nothing
printf "please add a column to the report" | CLAUDE_PROJECT_DIR="$tmp" bash "$HOOK" >/dev/null 2>&1
check "$?" 0 "hook exits 0 on non-correction"
check "$(wc -l < "$Q" | tr -d ' ')" 1 "non-correction did not enqueue"

# newlines in the prompt are flattened to keep one record per line
printf "that's wrong\nline two" | CLAUDE_PROJECT_DIR="$tmp" bash "$HOOK" >/dev/null 2>&1
check "$(wc -l < "$Q" | tr -d ' ')" 2 "multiline correction is still one record"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
