#!/usr/bin/env bash
set -uo pipefail
HOOK="$(cd "$(dirname "$0")/../../hooks" && pwd)/capture-nudge.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/scheduled-tasks"
Q="$tmp/scheduled-tasks/.learning-queue.tsv"
# capture-nudge resolves its queue from LEARNING_QUEUE (absolute default is the live schnapp-os
# queue); redirect it here so the test never touches the real queue.

# a correction enqueues exactly one record, tagged 'correction'
printf "you're wrong, the port is 1433" | LEARNING_QUEUE="$Q" bash "$HOOK" >/dev/null 2>&1
check "$?" 0 "hook exits 0 on correction"
check "$([ -f "$Q" ] && wc -l < "$Q" | tr -d ' ' || echo 0)" 1 "one queue record after a correction"
check "$(cut -f2 "$Q" | head -1)" "correction" "record tagged correction"
check "$(grep -c 'port is 1433' "$Q")" 1 "prompt text captured"

# a non-correction enqueues nothing
printf "please add a column to the report" | LEARNING_QUEUE="$Q" bash "$HOOK" >/dev/null 2>&1
check "$?" 0 "hook exits 0 on non-correction"
check "$(wc -l < "$Q" | tr -d ' ')" 1 "non-correction did not enqueue"

# newlines in the prompt are flattened to keep one record per line
printf "that's wrong\nline two" | LEARNING_QUEUE="$Q" bash "$HOOK" >/dev/null 2>&1
check "$(wc -l < "$Q" | tr -d ' ')" 2 "multiline correction is still one record"

# JSON envelope (real UserPromptSubmit shape): enqueues the prompt TEXT, not the envelope
printf '{"session_id":"abc123","cwd":"/tmp","prompt":"incorrect, the port is 1433"}' \
  | LEARNING_QUEUE="$Q" bash "$HOOK" >/dev/null 2>&1
check "$(wc -l < "$Q" | tr -d ' ')" 3 "JSON-envelope correction enqueues"
check "$(tail -1 "$Q" | grep -c 'session_id')" 0 "envelope stripped - prompt text only"
check "$(tail -1 "$Q" | grep -c 'port is 1433')" 1 "prompt text preserved from envelope"

# machine-generated prompts never enqueue, even when their body quotes correction phrases
printf '{"prompt":"<task-notification>\\nagent report: patterns like you are wrong, incorrect\\n</task-notification>"}' \
  | LEARNING_QUEUE="$Q" bash "$HOOK" >/dev/null 2>&1
check "$(wc -l < "$Q" | tr -d ' ')" 3 "task-notification did not enqueue"
printf '{"prompt":"<task-notification>..."}' | LEARNING_QUEUE="$Q" bash "$HOOK" 2>/dev/null | grep -qc capture
check "$?" 1 "task-notification did not emit the nudge"

# queue-echo meta-loop: a prompt containing the queue's own TSV shape never re-enqueues
printf '{"prompt":"Queued corrections:\\n2026-07-03T05:45:54Z\\tcorrection\\tyou are wrong about x"}' \
  | LEARNING_QUEUE="$Q" bash "$HOOK" >/dev/null 2>&1
check "$(wc -l < "$Q" | tr -d ' ')" 3 "queue echo did not re-enqueue"

# oversized prompt (pasted report/log) never enqueues
big="$(printf 'incorrect port %.0s' $(seq 1 200))"
printf '{"prompt":"%s"}' "$big" | LEARNING_QUEUE="$Q" bash "$HOOK" >/dev/null 2>&1
check "$(wc -l < "$Q" | tr -d ' ')" 3 "oversized paste did not enqueue"

# enqueued line is capped so the queue stays lean
awk -F'\t' '{ if (length($3) > 1000) exit 1 }' "$Q"
check "$?" 0 "queued text capped at 1000 chars"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
