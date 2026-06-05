#!/usr/bin/env bash
# check-freshness.sh — documentation freshness gate (PLAN.md Part 9.3). Runs in CI
# (.github/workflows/freshness.yml) and locally (pre-push). Two checks:
#
#   (1) Generated docs — regenerate and FAIL if the committed copy is stale (a source under
#       plugins/core/ changed but the generator was not re-run). Today: plugins/core/CATALOG.md.
#
#   (2) last-verified docs — a doc opts in with frontmatter:
#           last-verified: 2026-06-05
#           sources:
#             - relative/path/to/source
#       FAIL if any listed source has a git commit dated NEWER than last-verified (the doc's
#       claim about that source may be stale and needs re-checking). No-op until a doc adopts it.
#
# Exits non-zero on any staleness, naming exactly what to fix. Location-independent.
set -uo pipefail
export LC_ALL=C

REPO="${CLAUDE_KIT_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
cd "$REPO" || { echo "FATAL: repo not found: $REPO" >&2; exit 2; }
fail=0

# --- portable frontmatter helpers (BSD + GNU awk) ---
fm() { # file key -> single-line value
  awk -v k="$2" 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit}
    f&&index($0,k":")==1{v=substr($0,length(k)+2);sub(/^[ \t]+/,"",v);print v;exit}' "$1"
}
fm_list() { # file key -> one list item per line
  awk -v k="$2" 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit}
    f&&index($0,k":")==1{p=1;next}
    f&&p{ if($0~/^[ \t]*-[ \t]*/){g=$0;sub(/^[ \t]*-[ \t]*/,"",g);gsub(/"/,"",g);print g}
          else if($0~/^[^ \t]/){exit} }' "$1"
}

echo "== freshness check =="

# (1) generated docs ----------------------------------------------------------
tmp="$(mktemp)"
if bash plugins/core/scripts/gen-catalog.sh "$tmp" >/dev/null 2>&1; then
  if diff -q "$tmp" plugins/core/CATALOG.md >/dev/null 2>&1; then
    echo "ok: plugins/core/CATALOG.md is current"
  else
    echo "STALE generated doc: plugins/core/CATALOG.md" >&2
    echo "  fix: bash plugins/core/scripts/gen-catalog.sh  (then commit plugins/core/CATALOG.md)" >&2
    echo "  --- committed (<) vs regenerated (>): ---" >&2
    diff plugins/core/CATALOG.md "$tmp" | sed 's/^/    /' >&2 || true
    fail=1
  fi
else
  echo "ERROR: gen-catalog.sh failed to run" >&2
  fail=1
fi
rm -f "$tmp"

# (2) last-verified docs ------------------------------------------------------
found_lv=0
while IFS= read -r doc; do
  [ -n "$doc" ] || continue
  lv="$(fm "$doc" last-verified)"
  [ -n "$lv" ] || continue
  found_lv=1
  while IFS= read -r src; do
    [ -n "$src" ] || continue
    if [ ! -e "$src" ]; then
      echo "STALE: $doc lists a missing source: $src" >&2
      fail=1; continue
    fi
    sdate="$(git log -1 --format=%cs -- "$src" 2>/dev/null || true)"
    if [ -n "$sdate" ] && [[ "$sdate" > "$lv" ]]; then
      echo "STALE: $doc is last-verified $lv but source $src changed $sdate — re-verify and bump last-verified" >&2
      fail=1
    fi
  done < <(fm_list "$doc" sources)
done < <(grep -rl '^last-verified:' --include='*.md' . 2>/dev/null | LC_ALL=C sort)
[ "$found_lv" = "0" ] && echo "ok: no last-verified docs yet (convention enforced once adopted)"

if [ "$fail" -ne 0 ]; then echo "== freshness: FAIL =="; exit 1; fi
echo "== freshness: OK =="
