#!/usr/bin/env bash
# test-session-mine-worker.sh - self-test for session-mine-worker.sh (ADR 0037 P2/P3).
# Covers: evidence verification (good / fabricated quote / single session), trigger-phrase
# collision, and the dry-run path (no git, no SDK, snapshot written).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKER="$REPO_ROOT/scripts/session-mine-worker.sh"   # sourcing the worker reassigns REPO_ROOT
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

# --- fixtures -------------------------------------------------------------------------------
mkdir -p "$TMP/transcripts"
printf '{"x":"the owner reconciled the vendor export against the API before loading"}\n' \
  > "$TMP/transcripts/sess-a.jsonl"
printf '{"x":"again reconciled the vendor export against the API before loading it"}\n' \
  > "$TMP/transcripts/sess-b.jsonl"

good_ev="$TMP/good.json"; cat > "$good_ev" <<EOF
{"skill":"vendor-reconcile","evidence":[
 {"transcript":"$TMP/transcripts/sess-a.jsonl","quote":"reconciled the vendor export against the API before loading"},
 {"transcript":"$TMP/transcripts/sess-b.jsonl","quote":"again reconciled the vendor export against the API before"}]}
EOF
bad_ev="$TMP/bad.json"; cat > "$bad_ev" <<EOF
{"skill":"vendor-reconcile","evidence":[
 {"transcript":"$TMP/transcripts/sess-a.jsonl","quote":"this fabricated quote appears in no transcript anywhere"},
 {"transcript":"$TMP/transcripts/sess-b.jsonl","quote":"again reconciled the vendor export against the API before"}]}
EOF
one_ev="$TMP/one.json"; cat > "$one_ev" <<EOF
{"skill":"vendor-reconcile","evidence":[
 {"transcript":"$TMP/transcripts/sess-a.jsonl","quote":"reconciled the vendor export against the API before loading"}]}
EOF

# fixture skill tree for collision checks
mkdir -p "$TMP/repo/skills/newbie" "$TMP/repo/skills/oldie"
printf -- '---\nname: oldie\ndescription: Use when "reconcile the vendor export" comes up.\n---\n' \
  > "$TMP/repo/skills/oldie/SKILL.md"
printf -- '---\nname: newbie\ndescription: Use when "reconcile the vendor export" is asked again.\n---\n' \
  > "$TMP/repo/skills/newbie/SKILL.md"

# --- source the worker's functions (main guarded by BASH_SOURCE) ----------------------------
export SESSION_MINE_REPO_ROOT="$TMP/repo"
# shellcheck disable=SC1090,SC1091  # sourced path is computed; functions come from the worker
. "$WORKER" --dry-run

verify_evidence "$good_ev" >/dev/null || fail "good evidence rejected"
verify_evidence "$bad_ev" >/dev/null 2>&1 && fail "fabricated quote accepted"
verify_evidence "$one_ev" >/dev/null 2>&1 && fail "single-session evidence accepted"

check_collision newbie >/dev/null 2>&1 && fail "colliding trigger phrase accepted"
printf -- '---\nname: newbie\ndescription: Use when "a totally distinct trigger" is asked.\n---\n' \
  > "$TMP/repo/skills/newbie/SKILL.md"
check_collision newbie >/dev/null || fail "non-colliding description rejected"

# --- dry-run end to end: real repo root, fixture transcripts, tmp history; must not touch git
unset SESSION_MINE_REPO_ROOT
out="$(MINING_TRANSCRIPT_ROOT="$TMP/transcripts" MINING_HISTORY_DIR="$TMP/hist" \
  bash "$WORKER" --dry-run)"
echo "$out" | grep -q "dry-run complete" || fail "dry-run did not complete: $out"
find "$TMP/hist" -name '*.tsv' | grep -q . || fail "dry-run wrote no snapshot"

echo "PASS test-session-mine-worker"
