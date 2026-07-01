#!/usr/bin/env bash
# test-length-advisory.sh - proves length-advisory.sh WARNs on an over-long always-load/rules
# file, stays silent on a normal or out-of-scope file, and NEVER blocks (always exit 0).
#
# RED (the gap this closes): the streamline keeps rules/global/*.md lean by convention only.
# Nothing nudges when a file quietly grows past the point where "always loaded" stops being cheap.
# This is a soft heuristic (line count is a proxy, not a real cost model), so the hook must only
# WARN to stderr and exit 0 in every case, including a missing/empty file_path on stdin.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$here/../../hooks/length-advisory.sh"
fail=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/rules/global" "$tmp/rules/modules/lang" "$tmp/docs"

# fixture 1: over-long rules/global/*.md (> 50 lines): must WARN
for i in $(seq 1 60); do echo "line $i"; done > "$tmp/rules/global/toolong.md"

# fixture 2: normal rules/global/*.md (< 50 lines): must NOT warn
for i in $(seq 1 10); do echo "line $i"; done > "$tmp/rules/global/normal.md"

# fixture 3: over-long rules/modules/.../*.md (> 120 lines): must WARN
for i in $(seq 1 130); do echo "line $i"; done > "$tmp/rules/modules/lang/toolong.md"

# fixture 4: out-of-scope long file (e.g. docs/x.md, foo.py): must NOT warn regardless of length
for i in $(seq 1 200); do echo "line $i"; done > "$tmp/docs/x.md"
for i in $(seq 1 200); do echo "line $i"; done > "$tmp/foo.py"

run_hook() { # $1 = repo-relative path (relative to $tmp, mimicking $PWD-prefixed tool_input)
  ( cd "$tmp" && printf '{"tool_input":{"file_path":"%s/%s"}}' "$tmp" "$1" | bash "$hook" )
}

# --- case 1: over-long rules/global fixture -> WARN, exit 0 ---
out1="$(run_hook rules/global/toolong.md 2>&1 1>/dev/null)"; rc1=$?
if echo "$out1" | grep -q WARN; then echo "ok   WARN      over-long rules/global (case 1)"
else echo "MISS WARN      over-long rules/global (case 1): $out1" >&2; fail=1; fi
if [ "$rc1" = "0" ]; then echo "ok   exit0     over-long rules/global (case 1)"
else echo "FAIL exit0 $rc1 over-long rules/global (case 1)" >&2; fail=1; fi

# --- case 2: normal rules/global fixture -> no WARN, exit 0 ---
out2="$(run_hook rules/global/normal.md 2>&1 1>/dev/null)"; rc2=$?
if echo "$out2" | grep -q WARN; then echo "FAIL silent    normal rules/global (case 2): $out2" >&2; fail=1
else echo "ok   silent    normal rules/global (case 2)"; fi
if [ "$rc2" = "0" ]; then echo "ok   exit0     normal rules/global (case 2)"
else echo "FAIL exit0 $rc2 normal rules/global (case 2)" >&2; fail=1; fi

# --- case 3: over-long rules/modules/.../x.md fixture (> 120 lines) -> WARN, exit 0 ---
out3="$(run_hook rules/modules/lang/toolong.md 2>&1 1>/dev/null)"; rc3=$?
if echo "$out3" | grep -q WARN; then echo "ok   WARN      over-long rules/modules (case 3)"
else echo "MISS WARN      over-long rules/modules (case 3): $out3" >&2; fail=1; fi
if [ "$rc3" = "0" ]; then echo "ok   exit0     over-long rules/modules (case 3)"
else echo "FAIL exit0 $rc3 over-long rules/modules (case 3)" >&2; fail=1; fi

# --- case 4: out-of-scope long files (docs/x.md, foo.py) -> no WARN, exit 0 ---
out4a="$(run_hook docs/x.md 2>&1 1>/dev/null)"; rc4a=$?
out4b="$(run_hook foo.py 2>&1 1>/dev/null)"; rc4b=$?
if echo "$out4a" | grep -q WARN; then echo "FAIL silent    out-of-scope docs/x.md (case 4): $out4a" >&2; fail=1
else echo "ok   silent    out-of-scope docs/x.md (case 4)"; fi
if echo "$out4b" | grep -q WARN; then echo "FAIL silent    out-of-scope foo.py (case 4): $out4b" >&2; fail=1
else echo "ok   silent    out-of-scope foo.py (case 4)"; fi
if [ "$rc4a" = "0" ] && [ "$rc4b" = "0" ]; then echo "ok   exit0     out-of-scope files (case 4)"
else echo "FAIL exit0 $rc4a/$rc4b out-of-scope files (case 4)" >&2; fail=1; fi

# --- case 5: missing/empty file_path on stdin -> exit 0, no crash ---
out5a="$(printf '{"tool_input":{}}' | bash "$hook" 2>&1 1>/dev/null)"; rc5a=$?
out5b="$(printf '' | bash "$hook" 2>&1 1>/dev/null)"; rc5b=$?
if [ "$rc5a" = "0" ] && [ "$rc5b" = "0" ]; then echo "ok   exit0     missing/empty file_path (case 5)"
else echo "FAIL exit0 $rc5a/$rc5b missing/empty file_path (case 5)" >&2; fail=1; fi
if echo "$out5a$out5b" | grep -q WARN; then echo "FAIL silent    missing/empty file_path warned (case 5)" >&2; fail=1
else echo "ok   silent    missing/empty file_path (case 5)"; fi

if [ "$fail" -ne 0 ]; then
  echo "pass=$((5 - fail)) fail=$fail"
  echo "== test-length-advisory: FAIL ==" >&2
  exit 1
fi
echo "pass=5 fail=0"
echo "== test-length-advisory: PASS =="
