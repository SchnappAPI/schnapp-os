#!/usr/bin/env bash
# test-global-secret-scan.sh - the user-scope wrapper's two legs (ADR 0033; red-team 056):
# PreToolUse Bash scans the command TEXT (a literal token in a heredoc/echo is blocked BEFORE
# execution - Write/Edit hooks never see Bash-written files), PostToolUse Write/Edit delegates
# to the canonical scanner with the schnapp-os self-skip. Token material is pulled from
# secret-fixtures.txt at runtime - never inline in this file.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$here/../../hooks/global-secret-scan.sh"
OS_REAL="$(cd "$here/../.." && pwd)"
pass=0; fail=0
check() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

token="$(grep -oE 'gh[pousr]_[A-Za-z0-9]{36,}' "$here/secret-fixtures.txt" | head -1)"
[ -n "$token" ] || { echo "FAIL: no github-token fixture in secret-fixtures.txt"; exit 1; }

mkjson() { # $1=tool_name $2=command
  python3 -c 'import json,sys; print(json.dumps({"tool_name": sys.argv[1], "tool_input": {"command": sys.argv[2]}}))' "$1" "$2"
}

# 1. Bash command carrying a literal token: blocked (exit 2) with the leak message
out="$(mkjson Bash "echo $token > /tmp/x" | SCHNAPP_OS_DIR="$OS_REAL" bash "$HOOK" 2>&1)"; rc=$?
check "$rc" 2 "Bash leg blocks a literal token in command text"
if printf '%s' "$out" | grep -q "LEAK GUARD"; then pass=$((pass+1)); else echo "FAIL: no LEAK GUARD message"; fail=$((fail+1)); fi

# 1b. Every BLOCK class in the canonical registry trips the Bash leg (couples the wrapper's
#     fast-path pre-filter to the registry: a class the pre-filter misses fails here)
while IFS= read -r ere; do
  sample="$(grep -oE -e "$ere" "$here/secret-fixtures.txt" | head -1)"
  [ -n "$sample" ] || { echo "FAIL: no fixture sample for BLOCK class /$ere/"; fail=$((fail+1)); continue; }
  mkjson Bash "echo $sample" | SCHNAPP_OS_DIR="$OS_REAL" bash "$HOOK" >/dev/null 2>&1
  check "$?" 2 "Bash leg blocks class ${ere:0:24}"
done < <(bash "$OS_REAL/scripts/scan-secrets.sh" --block-re)

# 2. Benign Bash command: allowed
mkjson Bash "git status && ls -la" | SCHNAPP_OS_DIR="$OS_REAL" bash "$HOOK" >/dev/null 2>&1
check "$?" 0 "benign Bash command passes"

# 3. The Bash leg never self-skips - no project wiring covers Bash-written files anywhere,
#    schnapp-os included
mkjson Bash "echo $token" | CLAUDE_PROJECT_DIR="$OS_REAL" SCHNAPP_OS_DIR="$OS_REAL" bash "$HOOK" >/dev/null 2>&1
check "$?" 2 "Bash leg fires even inside schnapp-os"

# 4. Write leg self-skips inside schnapp-os (project wiring runs the same scanner there)
printf '{"tool_name":"Write","tool_input":{"file_path":"/tmp/nonexistent-fixture"}}' \
  | CLAUDE_PROJECT_DIR="$OS_REAL" SCHNAPP_OS_DIR="$OS_REAL" bash "$HOOK" >/dev/null 2>&1
check "$?" 0 "Write leg self-skips in schnapp-os"

# 5. Write leg outside schnapp-os delegates: clean file passes, fixture file blocks
tmpf="$(mktemp)"
echo "clean content" > "$tmpf"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$tmpf" \
  | CLAUDE_PROJECT_DIR=/tmp SCHNAPP_OS_DIR="$OS_REAL" bash "$HOOK" >/dev/null 2>&1
check "$?" 0 "Write leg delegation: clean file passes"
cp "$here/secret-fixtures.txt" "$tmpf"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$tmpf" \
  | CLAUDE_PROJECT_DIR=/tmp SCHNAPP_OS_DIR="$OS_REAL" bash "$HOOK" >/dev/null 2>&1
check "$?" 2 "Write leg delegation: fixture secrets block"
rm -f "$tmpf"

echo "test-global-secret-scan: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
