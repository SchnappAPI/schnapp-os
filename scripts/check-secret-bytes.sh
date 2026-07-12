#!/usr/bin/env bash
# check-secret-bytes.sh - byte-check gate for a stored secret value (never prints the value).
#
# A recurring class (a secret stored with stray whitespace / wrapping quotes / truncation) 401s
# in production, indistinguishable from a bad token, and has cost multi-day misdiagnoses
# ([[malformed-stored-secret-401]], ADR 0019). This gate checks the RAW BYTES of a value at
# rotate/store time and reports only a DEFECT CATEGORY - never the value, never any of its bytes.
#
# SECURITY INVARIANT: this script must NEVER print, log, or echo the secret value or any bytes of
# it. Length is reportable (a count, not the value); the actual bytes, actual prefix, actual quoted
# contents are not. Exit codes distinguish "cannot check" (2) from "checked and malformed" (1).
#
# Usage:
#   check-secret-bytes.sh [--ref op://vault/item/field] [--min-len N] [--expect-prefix S]
#     no --ref   -> reads the value from stdin (tests, piping a freshly minted value)
#     --ref REF  -> `op read REF` resolves the value (live rotate/store path); op absent or the
#                   read failing is an ERROR (exit 2), distinct from a MALFORMED value (exit 1);
#                   the ref's value is never printed even when the read itself fails.
#     --min-len N       -> fail if the value is shorter than N bytes (catches truncation)
#     --expect-prefix S -> fail if the value does not start with S (catches the wrong-secret class)
#
# Exit codes: 0 = clean; 1 = MALFORMED (defect category on stdout); 2 = cannot check (op missing /
# read failed / bad args) - never a malformed-value verdict, since the value was never obtained.
unset SHELLOPTS BASH_XTRACEFD 2>/dev/null || true   # never trace secret bytes (fail closed on inherited xtrace)
set +x
set -uo pipefail

usage() {
  sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

ref=""
min_len=""
expect_prefix=""
while [ $# -gt 0 ]; do
  case "$1" in
    --ref) ref="$2"; shift 2 ;;
    --ref=*) ref="${1#--ref=}"; shift ;;
    --min-len) min_len="$2"; shift 2 ;;
    --min-len=*) min_len="${1#--min-len=}"; shift ;;
    --expect-prefix) expect_prefix="$2"; shift 2 ;;
    --expect-prefix=*) expect_prefix="${1#--expect-prefix=}"; shift ;;
    -h|--help) usage ;;
    *) echo "check-secret-bytes: unknown argument: $1" >&2; exit 2 ;;
  esac
done

# --min-len must be a non-negative integer; a non-numeric value would make the length
# comparison below error and fall through as if clean (fail OPEN) - reject it up front instead.
if [ -n "$min_len" ] && ! [[ "$min_len" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --min-len must be a non-negative integer" >&2
  exit 2
fi

# auto-floor: --expect-prefix with no (or zero) --min-len means a value equal to the prefix
# itself (zero real content beyond it) would otherwise pass as "ok". Raise the effective floor
# so that case fails as too-short instead.
if [ -n "$expect_prefix" ] && { [ -z "$min_len" ] || [ "$min_len" -eq 0 ]; }; then
  min_len=$((${#expect_prefix} + 1))
fi

fail() { # $1=message (category only - caller must never pass value bytes)
  echo "MALFORMED: $1"
  exit 1
}

# --- obtain the value, preserving trailing bytes -------------------------------------------
# Command substitution strips ALL trailing newlines, which would HIDE a trailing-whitespace
# defect (the exact class this gate exists to catch). The sentinel trick defeats that: append a
# known non-newline byte ('x') inside the substitution, then strip exactly that one trailing byte
# afterward - any trailing newline(s) that were part of the real value survive in between.
status_marker="___CHECK_SECRET_BYTES_STATUS:"
if [ -n "$ref" ]; then
  if ! command -v op >/dev/null 2>&1; then
    echo "ERROR: op CLI not found; cannot resolve --ref (value not checked)" >&2
    exit 2
  fi
  # A plain `val="$(op read ...; printf x)"` would capture printf's exit status (always 0), not
  # op read's - masking a failed read as an empty/malformed value instead of an ERROR. So op
  # read's own $? is appended as a status marker in the SAME substitution as the sentinel (both
  # must be in one substitution, since a second, separate substitution would strip the real
  # value's trailing newline before the sentinel ever sees it - destroying the exact defect this
  # gate exists to catch).
  # -n: op read otherwise appends its own trailing newline, which the sentinel logic
  # faithfully preserves - making EVERY ref-based check false-positive on the
  # trailing-whitespace class (verified against a known-good production value 2026-07-11).
  raw="$(op read -n "$ref" 2>/dev/null; printf '%s%d' "$status_marker" "$?"; printf x)"
  raw="${raw%x}"
  op_status="${raw##*"$status_marker"}"
  val="${raw%"$status_marker$op_status"}"
  if [ "$op_status" -ne 0 ]; then
    echo "ERROR: op read failed for the given ref; cannot resolve --ref (value not checked)" >&2
    exit 2
  fi
else
  val="$(cat; printf x)"
  val="${val%x}"
fi

# --- checks: exit 1 with a category on the FIRST failure; never print $val -----------------

# 1. empty
[ -z "$val" ] && fail "empty value"

# 2. surrounding or embedded whitespace/newline (leading/trailing space or tab, or any
#    embedded newline/CR anywhere in the value). [[:space:]] is C-locale, single-byte, and
#    misses real clipboard/paste artifacts: NBSP (U+00A0, 0xC2 0xA0), LINE SEPARATOR (U+2028,
#    0xE2 0x80 0xA8), PARAGRAPH SEPARATOR (U+2029, 0xE2 0x80 0xA9). A secret never legitimately
#    contains these bytes, so they are flagged anywhere in the value, not just leading/trailing.
if [[ "$val" =~ ^[[:space:]] ]] || [[ "$val" =~ [[:space:]]$ ]]; then
  fail "surrounding or embedded whitespace/newline"
fi
case "$val" in
  *$'\n'*|*$'\r'*|*$'\xc2\xa0'*|*$'\xe2\x80\xa8'*|*$'\xe2\x80\xa9'*) fail "surrounding or embedded whitespace/newline" ;;
esac

# 3. quote at either end: a real secret never starts or ends with a " or ' byte. Fail if
#    EITHER side is a quote, not only when both sides match the same quote character - a
#    single leading quote (or a mismatched pair) is just as much evidence of a stored quoted
#    literal, and the both-must-match form let it through.
first_char="${val:0:1}"
last_char="${val: -1}"
if [ "$first_char" = '"' ] || [ "$first_char" = "'" ] || [ "$last_char" = '"' ] || [ "$last_char" = "'" ]; then
  fail "value starts or ends with a quote (stored the quoted literal?)"
fi

# 4. --min-len: too short (truncation)
if [ -n "$min_len" ]; then
  if [ "${#val}" -lt "$min_len" ]; then
    fail "too short (${#val} bytes < $min_len; truncated?)"
  fi
fi

# 5. --expect-prefix: wrong-secret / prefix mismatch
if [ -n "$expect_prefix" ]; then
  case "$val" in
    "$expect_prefix"*) : ;;
    *) fail "does not start with the expected prefix" ;;
  esac
fi

echo "ok: value bytes clean"
exit 0
