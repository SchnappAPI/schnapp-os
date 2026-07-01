#!/usr/bin/env bash
# test-learning-recurrence.sh — proves learning-recurrence.sh classifies captures deterministically
# and drafts a GATE proposal (stdout only) when a class recurs (>= 2), never on a single occurrence,
# and never as a working-tree/git side effect.
#
# RED (the gap this closes): the nightly learning worker used to answer EVERY correction with more
# prose. Spec sec 2/4.4: a class that recurs should escalate to ENFORCEMENT (a drafted gate for owner
# approval), not another doc line. This tool computes the deterministic class signature + archive count
# and emits the drafted-gate body; the WORKER (not this tool) files it as a GitHub issue. Nothing here
# may edit the tree, commit, or push — a drafted gate is only a proposal.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rec="$here/../learning-recurrence.sh"
pass=0; fail=0

check() { # $1=got $2=want $3=label
  if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "ok   $3"
  else echo "FAIL $3 (got [$1] want [$2])" >&2; fail=$((fail+1)); fi
}

contains() { # $1=haystack $2=needle -> 0 if present
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

sig() { bash "$rec" signature "$1"; }

# TSV row helper: timestamp<TAB>kind<TAB>text
row() { printf '%s\tcorrection\t%s\n' "$1" "$2"; }

# ---- signature ------------------------------------------------------------------------------

# 1. two same-class texts (digit variation only) -> IDENTICAL, non-empty signature
s1="$(sig 'the SQL Server port is 1433 not 1533')"
s2="$(sig 'the SQL Server port is 5432 not 5433')"
check "$s1" "$s2" "same-class texts share a signature"
if [ -n "$s1" ]; then pass=$((pass+1)); echo "ok   same-class signature is non-empty"
else echo "FAIL same-class signature was empty" >&2; fail=$((fail+1)); fi

# 2. two different-class texts -> DIFFERENT signatures
d1="$(sig 'always quote op refs that contain spaces')"
d2="$(sig 'the SQL Server port is 1433 not 1533')"
if [ "$d1" != "$d2" ]; then pass=$((pass+1)); echo "ok   different-class texts differ"
else echo "FAIL different-class texts collided: [$d1]" >&2; fail=$((fail+1)); fi

# 3. order-independence: a text and its word-shuffled variant -> same signature
o1="$(sig 'the SQL Server port is 1433 not 1533')"
o2="$(sig 'not 1533 port the is Server SQL 1433')"
check "$o1" "$o2" "signature is order-independent"

# 4. a trivial text -> EMPTY signature (too little signal to classify)
check "$(sig 'ok')" "" "trivial text yields empty signature"

# extra: determinism — same input twice -> identical output
r1="$(sig 'the SQL Server port is 1433 not 1533')"
r2="$(sig 'the SQL Server port is 1433 not 1533')"
check "$r1" "$r2" "signature is deterministic across runs"

# ---- draft ----------------------------------------------------------------------------------

# Shared port-class signature (used by several cases below).
PORTSIG="$(sig 'the SQL Server port is 1433 not 1533')"

# 5. seeded repeat: archive has 1 port capture, queue has 1 more port capture + 1 unrelated single.
#    -> exactly ONE <<<GATE-DRAFT>>> block; SIG == port signature; body carries BOTH port texts +
#    the owner-approval line; the unrelated single capture produces NO block.
q="$(mktemp)"; a="$(mktemp)"; m="$(mktemp)"
row '2026-06-01T00:00:00Z' 'the SQL Server port is 1433 not 1533' >  "$a"
row '2026-06-02T00:00:00Z' 'the SQL Server port is 5432 not 5433' >  "$q"
row '2026-06-02T00:01:00Z' 'always quote op refs that contain spaces' >> "$q"
: > "$m"
out="$(bash "$rec" draft "$q" "$a" "$m")"; rc=$?
check "$rc" 0 "draft (seeded repeat) exits 0"
check "$(printf '%s\n' "$out" | grep -c '^<<<GATE-DRAFT>>>$')" 1 "seeded repeat emits exactly one block"
check "$(printf '%s\n' "$out" | grep -c "^SIG: $PORTSIG$")" 1 "block SIG equals the port signature"
if contains "$out" 'the SQL Server port is 1433 not 1533'; then pass=$((pass+1)); echo "ok   body carries the archive occurrence text"
else echo "FAIL body missing the archive occurrence text" >&2; fail=$((fail+1)); fi
if contains "$out" 'the SQL Server port is 5432 not 5433'; then pass=$((pass+1)); echo "ok   body carries the queue occurrence text"
else echo "FAIL body missing the queue occurrence text" >&2; fail=$((fail+1)); fi
if contains "$out" 'owner approval required'; then pass=$((pass+1)); echo "ok   body carries the owner-approval line"
else echo "FAIL body missing the owner-approval line" >&2; fail=$((fail+1)); fi
if contains "$out" 'always quote op refs that contain spaces'; then
  echo "FAIL unrelated single capture leaked into a block" >&2; fail=$((fail+1))
else pass=$((pass+1)); echo "ok   unrelated single capture produced no block"; fi

# 6. single occurrence only (queue has 1 capture, archive empty, marker empty) -> NO block.
q="$(mktemp)"; a="$(mktemp)"; m="$(mktemp)"
row '2026-06-02T00:00:00Z' 'the SQL Server port is 1433 not 1533' > "$q"
out="$(bash "$rec" draft "$q" "$a" "$m")"; rc=$?
check "$rc" 0 "draft (single occurrence) exits 0"
check "$(printf '%s' "$out" | grep -c '^<<<GATE-DRAFT>>>$')" 0 "single occurrence emits no block"

# 7. idempotency: marker already lists the port signature; seeded-repeat input from case 5 -> NO block.
q="$(mktemp)"; a="$(mktemp)"; m="$(mktemp)"
row '2026-06-01T00:00:00Z' 'the SQL Server port is 1433 not 1533' >  "$a"
row '2026-06-02T00:00:00Z' 'the SQL Server port is 5432 not 5433' >  "$q"
printf '%s\n' "$PORTSIG" > "$m"
out="$(bash "$rec" draft "$q" "$a" "$m")"; rc=$?
check "$rc" 0 "draft (already-drafted) exits 0"
check "$(printf '%s' "$out" | grep -c '^<<<GATE-DRAFT>>>$')" 0 "already-drafted signature emits no block"

# 8. two same-class captures BOTH in the queue (archive empty) -> ONE block (in-run recurrence).
q="$(mktemp)"; a="$(mktemp)"; m="$(mktemp)"
row '2026-06-02T00:00:00Z' 'the SQL Server port is 1433 not 1533' >  "$q"
row '2026-06-02T00:01:00Z' 'the SQL Server port is 5432 not 5433' >> "$q"
: > "$m"
out="$(bash "$rec" draft "$q" "$a" "$m")"; rc=$?
check "$rc" 0 "draft (in-run repeat) exits 0"
check "$(printf '%s\n' "$out" | grep -c '^<<<GATE-DRAFT>>>$')" 1 "two queue-only same-class captures emit one block"

# 9. determinism / no side-effects: draft only READS; it must not create or modify the queue,
#    archive, or marker files (the WORKER writes the marker, not this tool).
q="$(mktemp)"; a="$(mktemp)"; m="$(mktemp)"
row '2026-06-01T00:00:00Z' 'the SQL Server port is 1433 not 1533' >  "$a"
row '2026-06-02T00:00:00Z' 'the SQL Server port is 5432 not 5433' >  "$q"
: > "$m"
q_before="$(cksum < "$q")"; a_before="$(cksum < "$a")"; m_before="$(cksum < "$m")"
_="$(bash "$rec" draft "$q" "$a" "$m")"
check "$(cksum < "$q")" "$q_before" "draft did not modify the queue file"
check "$(cksum < "$a")" "$a_before" "draft did not modify the archive file"
check "$(cksum < "$m")" "$m_before" "draft did not modify the marker file"

# extra: a usage error (unknown subcommand / wrong arg count) exits non-zero.
bash "$rec" bogus >/dev/null 2>&1; check "$?" 2 "unknown subcommand exits 2"
bash "$rec" signature >/dev/null 2>&1; check "$?" 2 "signature with no arg exits 2"
bash "$rec" draft "$q" >/dev/null 2>&1; check "$?" 2 "draft with too few args exits 2"

# extra: missing queue AND archive files -> no rows -> no block, exit 0 (either may be absent).
mm="$(mktemp)"; : > "$mm"
out="$(bash "$rec" draft "$here/does-not-exist-q.tsv" "$here/does-not-exist-a.tsv" "$mm")"; rc=$?
check "$rc" 0 "draft with both files missing exits 0"
check "$(printf '%s' "$out" | grep -c '^<<<GATE-DRAFT>>>$')" 0 "draft with both files missing emits no block"

# extra: the cosmetic run-date must NOT enter the signature (a date-only capture is trivial signal).
check "$(sig "$(date -u +%F)")" "" "a bare run-date yields an empty signature"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
