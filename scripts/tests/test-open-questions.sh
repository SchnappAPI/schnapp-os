#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-open-questions.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
H="$tmp/handoffs"; mkdir -p "$H"

# missing dir -> SKIP, exit 0
out="$(bash "$SCRIPT" "$tmp/nope")"
check "$?" 0 "missing dir exits 0"
check "$(printf '%s' "$out" | grep -c SKIP)" 1 "missing dir says SKIP"

# no numbered handoffs (README/TEMPLATE-style files ignored)
touch "$H/README.md" "$H/TEMPLATE.md"
out="$(bash "$SCRIPT" "$H")"
check "$(printf '%s' "$out" | grep -c 'no numbered')" 1 "no numbered handoffs reported"

# open items in the NEWEST handoff are listed; older handoffs are frozen history
cat > "$H/001-old.md" <<'EOF'
# Handoff 1
## Open questions
- stale old item
EOF
cat > "$H/002-new.md" <<'EOF'
# Handoff 2
## Open questions / edge cases (owner-only)
1. **Do the thing** on machine X.
2. Decide Y.
## Copy-paste primer
- not an open item
EOF
out="$(bash "$SCRIPT" "$H")"
check "$(printf '%s\n' "$out" | grep -c 'OPEN ITEMS (2)')" 1 "two open items counted"
check "$(printf '%s\n' "$out" | grep -c 'stale old item')" 0 "older handoff ignored"
check "$(printf '%s\n' "$out" | grep -c 'not an open item')" 0 "section ends at the next heading"
check "$(printf '%s\n' "$out" | grep -c 'Decide Y')" 1 "numbered item listed"

# a newer handoff with no open section clears the report
cat > "$H/003-clean.md" <<'EOF'
# Handoff 3
## Status
done
EOF
out="$(bash "$SCRIPT" "$H")"
check "$(printf '%s\n' "$out" | grep -c 'no open items')" 1 "clean newest handoff reports none"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
