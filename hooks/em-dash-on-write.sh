#!/usr/bin/env bash
# em-dash-on-write.sh - PostToolUse writing-style guard (no em dashes in live files).
#
# Runs the canonical writing-style checker (scripts/check-writing-style.sh) on each file the
# agent Writes/Edits, the moment it is written. Rationale: writing-style.md bans em dashes,
# the class recurred (ADR 0026 stripped its own, then a 780-dash repo-wide sweep 2026-07-01),
# and per the decisions/0026 enforcement ladder a deterministic recurring check escalates to a
# gate. CI (ci-lint.yml) is the backstop; this catches the dash in-session while the agent can
# still fix it. Frozen-history exemptions live in the checker, not here (single source).
# Mirrors the secret-scan-on-write.sh pattern; PostToolUse exit 2 surfaces to Claude.
set -uo pipefail
INPUT="$(cat)"

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

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

CHECK="$(cd "$(dirname "$0")/../scripts" && pwd)/check-writing-style.sh"
[ -f "$CHECK" ] || exit 0

findings="$(bash "$CHECK" "$FILE" 2>&1)"
status=$?
if [ "$status" -eq 1 ]; then
  {
    echo "WRITING-STYLE (rules/global/writing-style.md): em dash (U+2014) written to $FILE:"
    printf '%s\n' "$findings"
    echo "Replace with a colon, a spaced hyphen, or split the sentence NOW; the file is already"
    echo "written. CI (ci-lint.yml writing-style gate) will block the push until it is gone."
  } >&2
  exit 2
fi
exit 0
