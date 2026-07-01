#!/usr/bin/env bash
# test-scan-secrets.sh - proves scan-secrets.sh catches every leaked value class.
#
# RED (the gap this closes): the reused opensource-sanitizer pattern lib has NO rule for the
# 1Password SA token (ops_…) or the Anthropic/Claude keys (sk-ant-…) - the exact master-token
# classes that leaked 2026-06-17. A naive reuse would pass them through. This test asserts the
# scanner BLOCKs them (GREEN), plus the rest of the registry, and that op:// pointers are skipped.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scan="$here/../scan-secrets.sh"
fixture="$here/secret-fixtures.txt"
fail=0

out="$("$scan" "$fixture" 2>/dev/null || true)"

expect_block=(onepassword-sa-token anthropic-key github-pat-fine github-token aws-access-key \
  google-oauth slack-webhook sendgrid-key jwt db-url-creds private-key)
expect_warn=(hex-bearer-64 assignment-secret private-ip)

for label in "${expect_block[@]}"; do
  if echo "$out" | grep -q "  BLOCK  $label  "; then echo "ok   BLOCK $label"
  else echo "MISS BLOCK $label" >&2; fail=1; fi
done
for label in "${expect_warn[@]}"; do
  if echo "$out" | grep -q "  WARN  $label  "; then echo "ok   WARN  $label"
  else echo "MISS WARN  $label" >&2; fail=1; fi
done

# negative: the op:// pointer line must not appear as a finding
if echo "$out" | grep -q 'op://'; then echo "FAIL op:// pointer flagged as a secret" >&2; fail=1
else echo "ok   negative op:// pointer not flagged"; fi

# masking: a full fixture value must never appear in output
if echo "$out" | grep -q 'AKIAIOSFODNN7EXAMPLE'; then echo "FAIL unmasked value in output" >&2; fail=1
else echo "ok   values masked (no full token in output)"; fi

# exit code: scanning a file with BLOCK hits must be non-zero
if "$scan" "$fixture" >/dev/null 2>&1; then echo "FAIL scanner exited 0 despite BLOCK hits" >&2; fail=1
else echo "ok   non-zero exit on BLOCK hits"; fi

if [ "$fail" -ne 0 ]; then echo "== test-scan-secrets: FAIL ==" >&2; exit 1; fi
echo "== test-scan-secrets: PASS =="
