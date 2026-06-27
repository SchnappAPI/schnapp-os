#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-stale-facts.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }
mk(){ printf -- '---\nname: %s\nsource: t\nupdated: %s\n---\nbody\n' "$1" "$2" > "$tmp/$1.md"; }
T=2026-06-27

mk fresh 2026-06-25                                   # 2d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'fresh.md')" 0 "fresh (<7d) not flagged"; rm "$tmp/fresh.md"

mk wk 2026-06-18                                      # 9d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'wk.md: review 7d+')" 1 "7-day tier"; rm "$tmp/wk.md"

mk mo 2026-05-20                                      # 38d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'mo.md: aging 30d+')" 1 "30-day tier"; rm "$tmp/mo.md"

mk old 2026-01-01                                     # 177d  (the "done when" >90d condition)
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'old.md: STALE 90d+')" 1 "90-day tier"

mk b7 2026-06-20                                      # exactly 7d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'b7.md: review 7d+')" 1 "exactly 7d flagged"; rm "$tmp/b7.md"

mk b6 2026-06-21                                      # 6d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'b6.md')" 0 "6d not flagged"; rm "$tmp/b6.md"

printf -- '---\nupdated: 2000-01-01\n---\n' > "$tmp/MEMORY.md"   # ancient but excluded
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'MEMORY.md')" 0 "MEMORY.md skipped"

bash "$SCRIPT" "$tmp" "$T" >/dev/null 2>&1; check "$?" 0 "always exits 0 (read-only)"

# empty/clean dir reports the OK line
e="$(mktemp -d)"; trap 'rm -rf "$tmp" "$e"' EXIT
check "$(bash "$SCRIPT" "$e" "$T" | grep -c 'memory freshness OK')" 1 "clean dir prints OK line"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
