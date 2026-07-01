#!/usr/bin/env bash
# Hook shellcheck-on-write.sh - PostToolUse shell-lint gate.
# (Filename is not the leading comment word on purpose: a comment line beginning with the linter
#  keyword is read as an in-file directive and self-errors with SC1072/SC1073.)
#
# Lints each *.sh file the agent Writes/Edits, the moment it is written. The repo's bash surface
# (session hooks + the scripts/ guards) gates every session; a quoting or word-split
# bug there silently breaks a gate (e.g. the op-wrap quote bug crash-looped 6 services;
# vault memory/op-wrap-token-unquoted.md). Catch it at edit time, not at the next failed run.
#
# Scope: info and above (-S info) - real correctness bugs surface, including the unquoted-variable
# word-split class (SC2086) the op-wrap bug belonged to; only pure style nits are excluded so the
# always-on hook is not noisy. No-ops if the linter is absent or the file is not shell. PostToolUse
# exit 2 surfaces findings to Claude (the write already happened) so it fixes them now. Mirrors
# secret-scan-on-write.sh. To silence one check in a file, use the linter's own in-file disable
# directive (respected here) - do not weaken the hook.
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
case "$FILE" in *.sh) ;; *) exit 0 ;; esac
command -v shellcheck >/dev/null 2>&1 || exit 0

findings="$(shellcheck -S info "$FILE" 2>/dev/null)"
status=$?
if [ "$status" -ne 0 ]; then
  {
    echo "SHELLCHECK (info and above) flagged $FILE - fix before relying on it:"
    printf '%s\n' "$findings"
  } >&2
  exit 2
fi
exit 0
