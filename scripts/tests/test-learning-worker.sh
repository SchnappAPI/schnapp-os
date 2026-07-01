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

# --- recurrence wiring in --dry-run (NO network, NO git, NO gh, NO working-tree change) -------------
# A recurring class (archive has 1 port-class capture; queue has a matching port-class capture) must
# surface a drafted-gate line, and the run must not dirty memory/ or rules/. LEARNING_GATE_DRAFTED
# points at a temp marker so the test never writes under the repo.
Q2="$tmp/q2.tsv"; A2="$tmp/q2.archive.tsv"; M2="$tmp/q2.gate-drafted.tsv"
printf '2026-06-01T00:00:00Z\tcorrection\tthe SQL Server port is 1433 not 1533\n' >  "$A2"
printf '2026-06-02T00:00:00Z\tcorrection\tthe SQL Server port is 5432 not 5433\n' >  "$Q2"
git_before="$(git -C "$REPO_ROOT" status --porcelain -- memory/ rules/ 2>/dev/null)"
out="$(LEARNING_QUEUE="$Q2" LEARNING_ARCHIVE="$A2" LEARNING_GATE_DRAFTED="$M2" bash "$SCRIPT" --dry-run 2>&1)"
check "$?" 0 "recurrence dry-run exits 0"
if [ "$(printf '%s\n' "$out" | grep -c 'would draft gate issue:')" -ge 1 ]; then
  pass=$((pass+1)); echo "ok   recurring class surfaces a drafted-gate issue line"
else
  echo "FAIL recurring class did not surface 'would draft gate issue:'" >&2; fail=$((fail+1))
fi
git_after="$(git -C "$REPO_ROOT" status --porcelain -- memory/ rules/ 2>/dev/null)"
check "$git_after" "$git_before" "recurrence dry-run wrote nothing under memory/ or rules/"
# The recurrence step must not create the marker under the repo (dry-run never writes it; it lives in tmp).
check "$(git -C "$REPO_ROOT" status --porcelain -- scheduled-tasks/ 2>/dev/null)" "" "recurrence dry-run left scheduled-tasks/ clean"

# A single unique capture (empty archive) draws NO gate draft.
Q3="$tmp/q3.tsv"; A3="$tmp/q3.archive.tsv"; M3="$tmp/q3.gate-drafted.tsv"
printf '2026-06-03T00:00:00Z\tcorrection\tthe SQL Server port is 1433 not 1533\n' > "$Q3"
out="$(LEARNING_QUEUE="$Q3" LEARNING_ARCHIVE="$A3" LEARNING_GATE_DRAFTED="$M3" bash "$SCRIPT" --dry-run 2>&1)"
check "$?" 0 "single-capture dry-run exits 0"
check "$(printf '%s' "$out" | grep -c 'would draft gate issue:')" 0 "single unique capture draws no gate draft"
check "$(printf '%s' "$out" | grep -c 'would distill+route')" 1 "single unique capture is routed to distill"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
