#!/usr/bin/env bash
# test-scan-stale-notes.sh - proves scan-stale-notes.sh catches the stale-incident-note
# classes (the 2026-07-15 cleanup's phrase registry) and skips routine-rotation language.
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scan="$here/../scan-stale-notes.sh"
fail=0

# The shipped fixture lives under scripts/tests/, which the scanner's own allowlist skips -
# copy it to a neutral path so the positive assertions actually scan it.
workdir="$(mktemp -d)"; trap 'rm -rf "$workdir"' EXIT
fixture="$workdir/live-doc.md"
cp "$here/stale-note-fixtures.md" "$fixture"

out="$("$scan" "$fixture" 2>/dev/null || true)"

expect=("was exposed" "needs rotation" "must be rotated" "\[MISSING - NEEDS ROTATION\]" \
  "credential was leaked" "as compromised")
for phrase in "${expect[@]}"; do
  if echo "$out" | grep -qi "$phrase"; then echo "ok   STALE $phrase"
  else echo "MISS STALE $phrase" >&2; fail=1; fi
done

# negative: routine-maintenance rotation language must not be flagged
if echo "$out" | grep -qi "yearly schedule\|rotation runbook"; then
  echo "FAIL routine rotation language flagged" >&2; fail=1
else echo "ok   negative routine language not flagged"; fi

# exit code: findings must be non-zero
if "$scan" "$fixture" >/dev/null 2>&1; then echo "FAIL scanner exited 0 despite findings" >&2; fail=1
else echo "ok   non-zero exit on findings"; fi

# allowlist: the same fixture under a handoffs/ path must be skipped
tmp="$(mktemp -d)"; mkdir -p "$tmp/handoffs"; cp "$fixture" "$tmp/handoffs/note.md"
if "$scan" "$tmp/handoffs/note.md" >/dev/null 2>&1; then echo "ok   handoffs/ path excluded"
else echo "FAIL handoffs/ path was scanned" >&2; fail=1; fi
rm -rf "$tmp"

if [ "$fail" -ne 0 ]; then echo "== test-scan-stale-notes: FAIL ==" >&2; exit 1; fi
echo "== test-scan-stale-notes: PASS =="
