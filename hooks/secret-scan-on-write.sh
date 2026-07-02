#!/usr/bin/env bash
# secret-scan-on-write.sh - PostToolUse shift-left leak guard.
#
# Runs the canonical literal-secret scanner (scan-secrets.sh) on each file the agent Writes/Edits,
# the moment it is written - not at push/PR time. Rationale: secrets-as-references is a cardinal rule
# and a real value already leaked once (vault memory/credential-leak-2026-06-17.md). The CI gate
# (.github/workflows/freshness.yml) is the backstop; this catches a leaked value in-session, while
# the agent can still fix it, instead of letting it sit in the working tree until a push.
#
# Single source of patterns: delegates to scan-secrets.sh - no rules duplicated here (anti-stale).
# Fires only on BLOCK findings (exact token formats); WARN heuristics are NOT enforced here so the
# always-on hook stays false-positive-free. PostToolUse exit 2 surfaces the finding to Claude (the
# write already happened) so it remediates immediately. Mirrors the no-force-push-guard.sh pattern.
set -uo pipefail
INPUT="$(cat)"

# jq-first with python3 fallback (the dual path length-advisory.sh already uses) so the
# guard survives a surface with only one JSON parser; a python3-only read meant this hook
# silently no-opped wherever python3 was absent. Keep this block byte-identical across
# secret-scan-on-write.sh / shellcheck-on-write.sh / em-dash-on-write.sh
# (test-write-hook-json-extract.sh diffs the three).
if command -v jq >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT" | jq -r 'select(.tool_name == "Write" or .tool_name == "Edit" or .tool_name == "MultiEdit") | .tool_input.file_path // empty' 2>/dev/null)"
else
  FILE="$(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if d.get("tool_name") not in ("Write", "Edit", "MultiEdit"):
    sys.exit(0)
print(d.get("tool_input", {}).get("file_path", "") or "")
' 2>/dev/null)"
fi

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

SCAN="$(cd "$(dirname "$0")/../scripts" && pwd)/scan-secrets.sh"
[ -x "$SCAN" ] || exit 0

findings="$(bash "$SCAN" "$FILE" 2>/dev/null)"
status=$?
if [ "$status" -ne 0 ]; then
  {
    echo "LEAK GUARD (secrets-as-references): scan-secrets flagged a literal secret VALUE in $FILE:"
    printf '%s\n' "$findings"
    echo "Replace the value with an op:// reference NOW (rules/global/secrets-as-references.md); the file"
    echo "is already written. If the value was ever committed it must be ROTATED, not just deleted"
    echo "(rotate-secret skill). CI (freshness.yml) will block the push until it is gone."
  } >&2
  exit 2
fi
exit 0
