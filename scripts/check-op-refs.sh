#!/usr/bin/env bash
# check-op-refs.sh - flag op:// references that point at an item NOT documented in the map.
#
# Single source of truth for "what items exist" is credentials-map.md. Every
# op://web-variables/<ITEM>/<field> in a tracked file should name an <ITEM> that appears there;
# one that doesn't is a stale/typo'd reference (renamed item, wrong title) that will resolve to
# nothing at runtime. Offline + deterministic (no vault access) - safe for CI.
#
# WARN-only by default (exit 0) so a lagging map never blocks a push; pass --strict to fail.
# Usage: check-op-refs.sh [--strict]
set -uo pipefail
export LC_ALL=C

REPO="${CLAUDE_KIT_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$REPO" || { echo "FATAL: repo not found: $REPO" >&2; exit 2; }
strict=0; [ "${1:-}" = "--strict" ] && strict=1
map="credentials-map.md"
[ -f "$map" ] || { echo "ok: no $map (nothing to check)"; exit 0; }

echo "== op:// reference check =="
miss=0
# extract op://web-variables/<ITEM>/ from every tracked file; ITEM = up to the next slash.
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  item="${ref#op://web-variables/}"; item="${item%%/*}"
  [ -n "$item" ] || continue
  # skip placeholders (<ITEM>) and pattern artifacts (regex/glob/shell-var text like [^...],
  # $VAR, {x}) - never real 1Password item titles, e.g. this script's own extraction regex.
  case "$item" in *'<'*|*'>'*|*'['*|*']'*|*'{'*|*'}'*|*'$'*|*'*'*|*'?'*|*'|'*|*'\'*) continue ;; esac
  if ! grep -qF "$item" "$map"; then
    echo "STALE op:// ref: item '$item' is not in $map (renamed/typo?)" >&2
    miss=1
  fi
done < <(git ls-files | xargs grep -hoE 'op://web-variables/[^/"'"'"' ]+/' 2>/dev/null \
          | grep -vF "$map" | LC_ALL=C sort -u)

if [ "$miss" -eq 0 ]; then echo "ok: every op:// item is documented in $map"; exit 0; fi
if [ "$strict" -eq 1 ]; then echo "== op:// refs: FAIL =="; exit 1; fi
echo "== op:// refs: WARN (not failing; run --strict to enforce) =="
exit 0
