#!/usr/bin/env bash
# length-advisory.sh — PostToolUse soft length nudge for the always-load layer.
#
# WARNs to stderr (never blocks) when a Write/Edit'd rules/global/*.md, other rules/**/*.md, or
# top-level CLAUDE.md grows past a heuristic line-count threshold. Line count is a proxy, not a
# real cost model, so this is advisory only: it ALWAYS exits 0, even on a missing/empty
# file_path or an out-of-scope file. Protects the lean always-load layer the streamline keeps
# (rules/global/*.md loads in every session on this machine) from quietly growing unnoticed.
# Mirrors secret-scan-on-write.sh / shellcheck-on-write.sh's dual jq/Python JSON-read path.
set -uo pipefail
INPUT="$(cat)"

if command -v jq >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
else
  FILE="$(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(d.get("tool_input", {}).get("file_path", "") or "")
' 2>/dev/null)"
fi

[ -n "${FILE:-}" ] || exit 0
[ -f "$FILE" ] || exit 0

# Match by repo-relative path: strip a leading $CLAUDE_PROJECT_DIR/ or $PWD/ if present.
rel="$FILE"
[ -n "${CLAUDE_PROJECT_DIR:-}" ] && rel="${rel#"$CLAUDE_PROJECT_DIR"/}"
rel="${rel#"$PWD"/}"

limit=""
kind=""
case "$rel" in
  rules/global/*.md)
    limit="${LENGTH_ADVISORY_GLOBAL:-50}"
    kind="always-load global rule"
    ;;
  rules/*.md)
    limit="${LENGTH_ADVISORY_RULES:-120}"
    kind="rules module"
    ;;
  CLAUDE.md)
    limit="${LENGTH_ADVISORY_CLAUDE:-120}"
    kind="repo front door"
    ;;
  *)
    exit 0
    ;;
esac

lines="$(wc -l < "$FILE" | tr -d ' ')"
if [ "$lines" -gt "$limit" ]; then
  echo "WARN (length advisory, advisory only, never blocks): $rel is $lines lines, over the" \
    "$kind heuristic limit of $limit. See rules/global/writing-style.md (terse, lead with the" \
    "point, no fluff): consider trimming or splitting." >&2
fi
exit 0
