#!/usr/bin/env bash
# test-transcript-mine.sh - fixture-driven self-test for scripts/transcript-mine.py (ADR 0037 P1).
# Two fixture sessions: skill fired twice across both, agent once, hook marker once.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/proj"

cat > "$TMP/proj/session-a.jsonl" <<'EOF'
{"timestamp":"2026-07-18T01:00:00.000Z","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"status"}}]}}
{"timestamp":"2026-07-18T01:01:00.000Z","message":{"content":[{"type":"tool_use","name":"Agent","input":{"subagent_type":"Explore","prompt":"x"}}]}}
{"timestamp":"2026-07-18T01:02:00.000Z","message":{"content":[{"type":"text","text":"SessionStart:startup hook success: gate ran"}]}}
not-json-line-must-be-skipped
EOF
cat > "$TMP/proj/session-b.jsonl" <<'EOF'
{"timestamp":"2026-07-18T02:00:00.000Z","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"status"}}]}}
EOF

OUT="$(python3 "$REPO_ROOT/scripts/transcript-mine.py" --root "$TMP/proj")"

fail() { echo "FAIL: $1"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q $'^skill\tstatus\t2\t2\t' || fail "expected skill status fires=2 sessions=2"
echo "$OUT" | grep -q $'^agent\tExplore\t1\t1\t' || fail "expected agent Explore fires=1"
echo "$OUT" | grep -q $'^hook\tSessionStart:startup\t1\t1\t' || fail "expected hook SessionStart:startup fires=1"
echo "$OUT" | grep -q '2026-07-18T02:00:00' || fail "expected last_ts from session-b"

echo "PASS test-transcript-mine"
