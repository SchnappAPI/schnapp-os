#!/usr/bin/env bash
# test-check-secret-bytes.sh - proves check-secret-bytes.sh catches every malformed-secret
# class WITHOUT ever printing the value, incl. dedicated value-leak guards (cases 8 and 10).
#
# RED (the gap this closes): a secret stored with stray whitespace, wrapping quotes, or
# truncation 401s in production, indistinguishable from a bad token, and has cost multi-day
# misdiagnoses ([[malformed-stored-secret-401]], ADR 0019). This gate byte-checks the value at
# rotate/store time; this test proves each defect category fires AND that the gate never leaks
# the value itself while doing so.
#
# Cases 10-16 are regression tests from the 2026-07-01 adversarial security review: a Critical
# value-leak (C1, inherited SHELLOPTS=xtrace traced the value to stderr) and fail-open bypasses
# (I1 non-numeric --min-len, I2 NBSP/U+2028/U+2029 whitespace, I3 single-sided quotes, M1
# prefix-only value, M2 --ref path coverage). Every check must fail CLOSED.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gate="$here/../check-secret-bytes.sh"
pass=0; fail=0

check() { # $1=got $2=want $3=label
  if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "ok   $3"
  else echo "FAIL $3 (got [$1] want [$2])" >&2; fail=$((fail+1)); fi
}

contains() { # $1=haystack $2=needle -> 0 if present
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

# 1. clean value, 40+ chars -> exit 0, no MALFORMED
# (fixture value is deliberately NOT a real-looking token format - see the "not a leaked value"
# note below - so it never trips the on-write scan-secrets.sh leak guard on this test file itself.)
clean="TESTVALUE_abcDEFghiJKLmnoPQRstuVWXyz0123456789zzzzzzz"
out="$(printf '%s' "$clean" | bash "$gate" 2>&1)"; rc=$?
check "$rc" 0 "clean value exits 0"
if contains "$out" "MALFORMED"; then echo "FAIL clean value flagged MALFORMED: $out" >&2; fail=$((fail+1))
else pass=$((pass+1)); echo "ok   clean value has no MALFORMED in output"; fi

# 2. leading space -> exit 1, whitespace category
out="$(printf ' %s' "$clean" | bash "$gate" 2>&1)"; rc=$?
check "$rc" 1 "leading space exits 1"
if contains "$out" "whitespace"; then pass=$((pass+1)); echo "ok   leading space names whitespace category"
else echo "FAIL leading space did not name whitespace category: $out" >&2; fail=$((fail+1)); fi

# 3. trailing newline (value + "\n") reaches the script via printf '%s\n' piped in -> exit 1,
#    whitespace/newline category. A pipe does NOT strip trailing newlines (only command
#    substitution does), so this is how the newline actually arrives at the gate's stdin.
out="$(printf '%s\n' "$clean" | bash "$gate" 2>&1)"; rc=$?
check "$rc" 1 "trailing newline exits 1"
if contains "$out" "whitespace"; then pass=$((pass+1)); echo "ok   trailing newline names whitespace category"
else echo "FAIL trailing newline did not name whitespace category: $out" >&2; fail=$((fail+1)); fi

# 4. wrapped in double quotes -> exit 1, quote category
out="$(printf '"%s"' "$clean" | bash "$gate" 2>&1)"; rc=$?
check "$rc" 1 "double-quote-wrapped exits 1"
if contains "$out" "quote"; then pass=$((pass+1)); echo "ok   double-quote-wrapped names quote category"
else echo "FAIL double-quote-wrapped did not name quote category: $out" >&2; fail=$((fail+1)); fi

# 5. wrapped in single quotes -> exit 1, quote category
out="$(printf "'%s'" "$clean" | bash "$gate" 2>&1)"; rc=$?
check "$rc" 1 "single-quote-wrapped exits 1"
if contains "$out" "quote"; then pass=$((pass+1)); echo "ok   single-quote-wrapped names quote category"
else echo "FAIL single-quote-wrapped did not name quote category: $out" >&2; fail=$((fail+1)); fi

# 6. --min-len 40 with a 10-char value -> exit 1, too-short category
out="$(printf '%s' "0123456789" | bash "$gate" --min-len 40 2>&1)"; rc=$?
check "$rc" 1 "too-short exits 1"
if contains "$out" "too short"; then pass=$((pass+1)); echo "ok   too-short names too-short category"
else echo "FAIL too-short did not name too-short category: $out" >&2; fail=$((fail+1)); fi

# 7. --expect-prefix sk-ant- with a value of a DIFFERENT prefix family -> exit 1, prefix category
# (fixture is deliberately not a real token format, same reason as case 1's "clean" value.)
out="$(printf '%s' "OTHERVENDOR_11ABCDEFGabcdefghijklmnop0123456789" | bash "$gate" --expect-prefix sk-ant- 2>&1)"; rc=$?
check "$rc" 1 "prefix mismatch exits 1"
if contains "$out" "prefix"; then pass=$((pass+1)); echo "ok   prefix mismatch names prefix category"
else echo "FAIL prefix mismatch did not name prefix category: $out" >&2; fail=$((fail+1)); fi

# 8. VALUE-LEAK GUARD: run the leading-space case (a unique sentinel value) and capture ALL
#    output (stdout+stderr combined); the sentinel substring must NEVER appear in it.
sentinel="SEKRET_SENTINEL_9Z8Y7X6W5V4U3T2S1R0Q"
out="$(printf ' %s' "$sentinel" | bash "$gate" 2>&1)"
if contains "$out" "$sentinel"; then
  echo "FAIL VALUE-LEAK GUARD: sentinel value appeared in gate output: $out" >&2
  fail=$((fail+1))
else
  pass=$((pass+1)); echo "ok   VALUE-LEAK GUARD: sentinel value never appears in gate output"
fi

# 9. empty stdin -> exit 1, empty category
out="$(printf '' | bash "$gate" 2>&1)"; rc=$?
check "$rc" 1 "empty stdin exits 1"
if contains "$out" "empty"; then pass=$((pass+1)); echo "ok   empty stdin names empty category"
else echo "FAIL empty stdin did not name empty category: $out" >&2; fail=$((fail+1)); fi

# 10. C1 VALUE-LEAK GUARD (inherited xtrace): a caller that exports SHELLOPTS=xtrace (or runs
#     under `set -x`) must NOT cause the gate or its command-substitution subshells to trace the
#     plaintext value to stderr. Run the gate as a genuinely separate process with SHELLOPTS=xtrace
#     already in its environment (`env VAR=val cmd`, not a shell prefix-assignment: SHELLOPTS is a
#     bash-readonly special variable and a prefix-assignment trips "readonly variable" under
#     set -u), pipe a unique sentinel, capture stdout+stderr combined; the sentinel must never
#     appear anywhere in the output.
xtrace_sentinel="XTRACE_LEAK_SENTINEL_Q1W2E3R4T5Y6U7I8O9P0"
out="$(env SHELLOPTS=xtrace bash "$gate" <<<"$xtrace_sentinel" 2>&1)"
if contains "$out" "$xtrace_sentinel"; then
  echo "FAIL C1 VALUE-LEAK GUARD: sentinel leaked under inherited SHELLOPTS=xtrace: $out" >&2
  fail=$((fail+1))
else
  pass=$((pass+1)); echo "ok   C1 VALUE-LEAK GUARD: sentinel never leaks under inherited SHELLOPTS=xtrace"
fi

# 11. I1: non-numeric --min-len must fail CLOSED (exit 2, cannot-check), not fall through as
#     clean. Use a short value so a numeric-comparison bug would otherwise report "ok".
out="$(printf '%s' "short" | bash "$gate" --min-len abc 2>&1)"; rc=$?
check "$rc" 2 "non-numeric --min-len exits 2"
if contains "$out" "ok"; then
  echo "FAIL non-numeric --min-len printed ok: $out" >&2; fail=$((fail+1))
else
  pass=$((pass+1)); echo "ok   non-numeric --min-len does not print ok"
fi

# 12. I2: leading NBSP (U+00A0, 0xC2 0xA0) is a real clipboard/paste artifact that C-locale
#     [[:space:]] does not match. Must fail as a whitespace category, and the value must never
#     be echoed.
nbsp_clean="NBSPVALUE_abcDEFghiJKLmnoPQRstuVWXyz012345"
out="$(printf '\xc2\xa0%s' "$nbsp_clean" | bash "$gate" 2>&1)"; rc=$?
check "$rc" 1 "leading NBSP exits 1"
if contains "$out" "whitespace"; then pass=$((pass+1)); echo "ok   leading NBSP names whitespace category"
else echo "FAIL leading NBSP did not name whitespace category: $out" >&2; fail=$((fail+1)); fi
if contains "$out" "$nbsp_clean"; then
  echo "FAIL leading NBSP echoed the value: $out" >&2; fail=$((fail+1))
else
  pass=$((pass+1)); echo "ok   leading NBSP does not echo the value"
fi

# 13. I3: a single leading quote (mismatched / one-sided) must fail as a quote category. The
#     current both-sides-must-match logic lets this through.
out="$(printf '"%s' "$clean" | bash "$gate" 2>&1)"; rc=$?
check "$rc" 1 "single leading quote exits 1"
if contains "$out" "quote"; then pass=$((pass+1)); echo "ok   single leading quote names quote category"
else echo "FAIL single leading quote did not name quote category: $out" >&2; fail=$((fail+1)); fi

# 14. I3 regression guard: both-sides-quoted must still fail (do not regress case 4/5 while
#     fixing the one-sided check).
out="$(printf '"%s"' "$clean" | bash "$gate" 2>&1)"; rc=$?
check "$rc" 1 "both-sides-quoted still exits 1"
if contains "$out" "quote"; then pass=$((pass+1)); echo "ok   both-sides-quoted still names quote category"
else echo "FAIL both-sides-quoted did not name quote category: $out" >&2; fail=$((fail+1)); fi

# 15. M1: --expect-prefix given WITHOUT --min-len, value EQUAL to the prefix (zero real content
#     beyond the prefix) must fail as too-short via the auto-floor, not pass as "ok".
out="$(printf '%s' "sk-ant-" | bash "$gate" --expect-prefix sk-ant- 2>&1)"; rc=$?
check "$rc" 1 "prefix-only value exits 1 (auto-floor)"
if contains "$out" "too short"; then pass=$((pass+1)); echo "ok   prefix-only value names too-short category"
else echo "FAIL prefix-only value did not name too-short category: $out" >&2; fail=$((fail+1)); fi
if contains "$out" "sk-ant-"; then
  echo "FAIL prefix-only value echoed the value: $out" >&2; fail=$((fail+1))
else
  pass=$((pass+1)); echo "ok   prefix-only value does not echo the value"
fi

# 16. M2: --ref path with a fake `op` shim on PATH returning a sentinel value that FAILS a check
#     (leading space). Assert the sentinel never appears in output, the category/exit are right,
#     and the shim is removed afterward (never touches the real vault).
ref_sentinel="REF_SHIM_SENTINEL_A1B2C3D4E5F6G7H8I9J0"
shim_dir="$(mktemp -d)"
cat >"$shim_dir/op" <<SHIM
#!/usr/bin/env bash
printf ' %s' '$ref_sentinel'
SHIM
chmod +x "$shim_dir/op"
out="$(PATH="$shim_dir:$PATH" bash "$gate" --ref op://fake/vault/item 2>&1)"; rc=$?
rm -rf "$shim_dir"
check "$rc" 1 "--ref shim (leading-space value) exits 1"
if contains "$out" "whitespace"; then pass=$((pass+1)); echo "ok   --ref shim names whitespace category"
else echo "FAIL --ref shim did not name whitespace category: $out" >&2; fail=$((fail+1)); fi
if contains "$out" "$ref_sentinel"; then
  echo "FAIL --ref shim sentinel leaked in output: $out" >&2; fail=$((fail+1))
else
  pass=$((pass+1)); echo "ok   --ref shim sentinel never appears in output"
fi

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
