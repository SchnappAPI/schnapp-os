#!/usr/bin/env bash
# test-no-force-push-guard.sh - pins the force-push HARD gate's exact envelope and proves the
# python3 and jq detection paths return the SAME verdict on every case (the equivalence matrix
# that gates the jq fallback).
#
# RED (the gap this closes): the guard is the repo's only hard-policy gate, yet it had zero
# regression coverage and was python3-only: on a python3-less surface it silently failed OPEN
# (allowed force-push). The matrix below runs every case through BOTH parser paths via PATH
# masking, so any future change to either regex has a harness that catches semantic drift.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$here/../../hooks/no-force-push-guard.sh"
pass=0; fail=0

payload(){ # $1 tool_name, $2 command -> hook-event JSON (jq-built so quoting is exact)
  jq -cn --arg t "$1" --arg c "$2" '{tool_name:$t, tool_input:{command:$c}}'
}

# mkmask <dir> <tool-to-omit>: a PATH farm with symlinks to every tool the hook may need
# EXCEPT the omitted one, to simulate that tool being genuinely absent (not merely broken).
mkmask(){
  local d="$1" omit="$2" t p
  mkdir -p "$d"
  for t in bash sh cat grep sed awk tr wc dirname basename env jq python3; do
    [ "$t" = "$omit" ] && continue
    p="$(command -v "$t" 2>/dev/null)" || continue
    ln -sf "$p" "$d/$t"
  done
}
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkmask "$tmp/no-py"  python3   # jq path
mkmask "$tmp/no-jq"  jq        # python3 path
mkmask "$tmp/none"   python3; rm -f "$tmp/none/jq"   # neither parser

run(){ # $1 PATH override (empty = inherit), $2 tool_name, $3 command -> echoes exit code
  local rc
  if [ -n "$1" ]; then payload "$2" "$3" | PATH="$1" bash "$hook" >/dev/null 2>&1; rc=$?
  else payload "$2" "$3" | bash "$hook" >/dev/null 2>&1; rc=$?; fi
  echo "$rc"
}

# case <name> <expected-rc> <tool_name> <command>
# Every case must yield expected-rc on the default path (python3), the no-py path (jq),
# and the no-jq path (python3 explicitly) - that IS the equivalence matrix.
case_check(){
  local name="$1" want="$2" tool="$3" cmd="$4" rc_def rc_jq rc_py
  rc_def="$(run ""            "$tool" "$cmd")"
  rc_jq="$(run "$tmp/no-py"   "$tool" "$cmd")"
  rc_py="$(run "$tmp/no-jq"   "$tool" "$cmd")"
  if [ "$rc_def" = "$want" ] && [ "$rc_jq" = "$want" ] && [ "$rc_py" = "$want" ]; then
    echo "ok   $name (py=$rc_py jq=$rc_jq def=$rc_def)"; pass=$((pass+1))
  else
    echo "FAIL $name: want $want, got py=$rc_py jq=$rc_jq def=$rc_def" >&2; fail=$((fail+1))
  fi
}

# blocked (exit 2)
case_check "block --force"            2 Bash 'git push --force origin main'
case_check "block -f"                 2 Bash 'git push -f'
case_check "block bundled -uf"        2 Bash 'git push -uf origin main'
case_check "block --force-with-lease" 2 Bash 'git push --force-with-lease origin main'
case_check "block +refspec"           2 Bash 'git push origin +main'
case_check "block force mid-chain"    2 Bash 'git add -A && git push --force origin main'
# allowed (exit 0)
case_check "allow plain push"         0 Bash 'git push -u origin main'
case_check "allow rm -f after push segment" 0 Bash 'git push origin main && rm -f scratch.txt'
case_check "allow non-push git -f"    0 Bash 'git clean -f'
case_check "allow no git at all"      0 Bash 'echo hello'
case_check "allow non-Bash tool"      0 Write 'git push --force origin main'

# malformed JSON -> allow (both parsers treat unparseable input as no-verdict)
rc_def="$(printf 'not json' | bash "$hook" >/dev/null 2>&1; echo $?)"
rc_jq="$(printf 'not json' | PATH="$tmp/no-py" bash "$hook" >/dev/null 2>&1; echo $?)"
if [ "$rc_def" = "0" ] && [ "$rc_jq" = "0" ]; then echo "ok   malformed JSON allows (both parsers)"; pass=$((pass+1))
else echo "FAIL malformed JSON: def=$rc_def jq=$rc_jq (want 0/0)" >&2; fail=$((fail+1)); fi

# neither parser present: DOCUMENTED fail-open, but loud (stderr warning), never silent.
# Full fail-closed here would block every Bash call on such a surface - an owner decision,
# recorded in the owner report, pinned here so a future change is deliberate.
err="$(payload Bash 'git push --force origin main' | PATH="$tmp/none" bash "$hook" 2>&1 >/dev/null)"; rc=$?
if [ "$rc" = "0" ] && printf '%s' "$err" | grep -q 'force-push detection is OFF'; then
  echo "ok   neither-parser case is fail-open but LOUD"; pass=$((pass+1))
else
  echo "FAIL neither-parser case: rc=$rc err=$err (want rc 0 + OFF warning)" >&2; fail=$((fail+1))
fi

echo "pass=$pass fail=$fail"
[ "$fail" = 0 ] || { echo "== test-no-force-push-guard: FAIL ==" >&2; exit 1; }
echo "== test-no-force-push-guard: PASS =="
