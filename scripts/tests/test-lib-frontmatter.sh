#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/lib-frontmatter.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

printf -- '---\nname: a\nsource: a session\nupdated: 2026-06-27\n---\nbody: x\n' > "$tmp/top.md"
printf -- '---\nname: b\nmetadata:\n  source: a decision\n  updated: 2026-06-20\n---\nbody\n' > "$tmp/nested.md"
printf -- 'no frontmatter here\n' > "$tmp/none.md"

check "$(fm_value "$tmp/top.md" updated)" "2026-06-27" "top-level updated"
check "$(fm_value "$tmp/top.md" source)"  "a session"  "multi-word source survives"
check "$(fm_value "$tmp/nested.md" updated)" "2026-06-20" "nested updated"
check "$(fm_value "$tmp/top.md" missing)" "" "absent key empty"
check "$(fm_value "$tmp/none.md" updated)" "" "no-frontmatter empty"
if fm_has "$tmp/top.md" source; then check 0 0 "fm_has present"; else check 1 0 "fm_has present"; fi
if fm_has "$tmp/top.md" nope;   then check 1 0 "fm_has absent";  else check 0 0 "fm_has absent"; fi
check "$(fm_block "$tmp/none.md")" "" "fm_block on no-frontmatter is empty"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
