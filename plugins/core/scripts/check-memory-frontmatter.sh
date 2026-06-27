#!/usr/bin/env bash
# Fail if any memory fact file lacks provenance (name + source + ISO updated).
# Required by memory/README.md. Accepts keys top-level OR under a `metadata:` block.
set -uo pipefail
DIR="${1:-memory}"
fail=0; n=0
for f in "$DIR"/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in MEMORY.md|README.md) continue;; esac
  n=$((n+1))
  fm="$(awk 'NR==1 && $0!="---"{exit} NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$f")"
  if [ -z "$fm" ]; then echo "$base: no frontmatter block"; fail=1; continue; fi
  printf '%s\n' "$fm" | grep -qE '^[[:space:]]*name:'   || { echo "$base: missing 'name:'";   fail=1; }
  printf '%s\n' "$fm" | grep -qE '^[[:space:]]*source:' || { echo "$base: missing 'source:'"; fail=1; }
  upd="$(printf '%s\n' "$fm" | grep -E '^[[:space:]]*updated:' | head -1 | sed -E 's/.*updated:[[:space:]]*//; s/["'\'' ]//g')"
  if [ -z "$upd" ]; then echo "$base: missing 'updated:'"; fail=1
  elif ! printf '%s' "$upd" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then echo "$base: 'updated:' not ISO (got '$upd')"; fail=1; fi
done
[ "$fail" = 0 ] && echo "memory frontmatter OK ($n facts)"
exit "$fail"
