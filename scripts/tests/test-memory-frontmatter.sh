#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-memory-frontmatter.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got $1 want $2)"; fail=$((fail+1)); fi; }

# good (top-level)
printf -- '---\nname: a\nsource: a session\nupdated: 2026-06-27\n---\nbody\n' > "$tmp/good.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 0 "clean dir exits 0"
rm "$tmp/good.md"

# good (nested metadata)
printf -- '---\nname: b\nmetadata:\n  source: a decision\n  updated: 2026-06-27\n---\nbody\n' > "$tmp/nested.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 0 "nested metadata accepted"
rm "$tmp/nested.md"

# missing source
printf -- '---\nname: c\nupdated: 2026-06-27\n---\nbody\n' > "$tmp/nosrc.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 1 "missing source fails"
rm "$tmp/nosrc.md"

# bad date
printf -- '---\nname: d\nsource: x\nupdated: June 2026\n---\nbody\n' > "$tmp/baddate.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 1 "non-ISO updated fails"
rm "$tmp/baddate.md"

# MEMORY.md/README.md ignored
printf -- 'no frontmatter\n' > "$tmp/MEMORY.md"
printf -- 'no frontmatter\n' > "$tmp/README.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 0 "index/readme skipped"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
