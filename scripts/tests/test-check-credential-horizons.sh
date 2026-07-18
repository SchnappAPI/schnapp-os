#!/usr/bin/env bash
# test-check-credential-horizons.sh - proves check-credential-horizons.sh WARNs inside the warn
# window, stays OK outside it, reports UNKNOWN expiry as INFO not WARN, and cannot go blind
# silently (missing/empty/malformed data is a WARN + exit 1).
set -uo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="$here/../check-credential-horizons.sh"
fail=0

workdir="$(mktemp -d)"; trap 'rm -rf "$workdir"' EXIT
tsv="$workdir/horizons.tsv"
today="2026-07-18"

printf '%s\n' \
  '# fixture' \
  $'FAR_FUTURE_TOKEN\t2030-01-01\t30\tfar out, must be OK' \
  $'EXPIRING_TOKEN\t2026-08-01\t30\tinside the 30d window, must WARN' \
  $'MYSTERY_PAT\tUNKNOWN\t0\tno documented expiry, must be INFO' \
  > "$tsv"

out="$("$check" "$tsv" "$today" 2>&1)"; code=$?

if [ "$code" -eq 1 ]; then echo "ok   exit 1 when a row is within horizon"
else echo "FAIL exit code $code, expected 1" >&2; fail=1; fi
if echo "$out" | grep -q "OK: FAR_FUTURE_TOKEN"; then echo "ok   far-future row OK"
else echo "FAIL far-future row not OK" >&2; fail=1; fi
if echo "$out" | grep -q "WARN: EXPIRING_TOKEN"; then echo "ok   within-horizon row WARNs"
else echo "FAIL within-horizon row did not WARN" >&2; fail=1; fi
if echo "$out" | grep -q "INFO: MYSTERY_PAT"; then echo "ok   UNKNOWN expiry reported as INFO"
else echo "FAIL UNKNOWN expiry not INFO" >&2; fail=1; fi
if echo "$out" | grep -q "WARN: MYSTERY_PAT"; then
  echo "FAIL UNKNOWN expiry wrongly WARNed" >&2; fail=1
else echo "ok   UNKNOWN expiry did not WARN"; fi

# all-clear fixture: far-future + UNKNOWN only -> exit 0
printf '%s\n' \
  $'FAR_FUTURE_TOKEN\t2030-01-01\t30\tfar out' \
  $'MYSTERY_PAT\tUNKNOWN\t0\tno expiry' \
  > "$tsv"
if "$check" "$tsv" "$today" >/dev/null 2>&1; then echo "ok   exit 0 when nothing within horizon"
else echo "FAIL exit non-zero on an all-clear file" >&2; fail=1; fi

# boundary: today exactly warn_days before expiry -> WARN (today >= expiry - warn_days)
printf '%s\n' $'EDGE_TOKEN\t2026-08-17\t30\texactly 30d out' > "$tsv"
edge_out="$("$check" "$tsv" "$today" 2>&1 || true)"
if echo "$edge_out" | grep -q "WARN: EDGE_TOKEN"; then echo "ok   boundary day WARNs"
else echo "FAIL boundary day did not WARN" >&2; fail=1; fi

# blindness guards: missing file, empty file, malformed row all WARN + exit 1
if "$check" "$workdir/nope.tsv" "$today" >/dev/null 2>&1; then
  echo "FAIL missing data file exited 0" >&2; fail=1
else echo "ok   missing data file is a WARN"; fi
: > "$tsv"
if "$check" "$tsv" "$today" >/dev/null 2>&1; then
  echo "FAIL empty data file exited 0" >&2; fail=1
else echo "ok   empty data file is a WARN"; fi
printf '%s\n' $'BAD_ROW\tnot-a-date\tthirty\tmalformed' > "$tsv"
if "$check" "$tsv" "$today" >/dev/null 2>&1; then
  echo "FAIL malformed row exited 0" >&2; fail=1
else echo "ok   malformed row is a WARN"; fi

# the LIVE data file parses clean today (exit 0 or 1 both legal states, but never a malformed row)
live_out="$(bash "$check" 2>&1 || true)"
if echo "$live_out" | grep -q "malformed row"; then
  echo "FAIL live credential-horizons.tsv has a malformed row" >&2; fail=1
else echo "ok   live data file parses clean"; fi

if [ "$fail" -ne 0 ]; then echo "== test-check-credential-horizons: FAIL ==" >&2; exit 1; fi
echo "== test-check-credential-horizons: PASS =="
