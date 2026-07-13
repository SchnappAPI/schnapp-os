#!/usr/bin/env bash
# global-secret-scan.sh - user-scope (any-repo) delivery of the secret-scan leak guard
# (ADR 0033, Link A guard layer). One file, two wirings (shell/install.sh):
#
#   PostToolUse Write|Edit|MultiEdit -> delegate to the canonical secret-scan-on-write.sh
#     (file scan, stdin intact). Skips inside schnapp-os itself: the project settings wire
#     the same scanner there (kept project-scoped for web parity) - without the skip every
#     Write in schnapp-os would be scanned twice and a finding would surface twice.
#
#   PreToolUse Bash -> scan the COMMAND TEXT before it runs. Write/Edit hooks never see a
#     file written by Bash (heredoc, echo >, tee), but the literal value is right there in
#     the command string; blocking here (exit 2) stops it BEFORE it hits disk. BLOCK token
#     formats only (scan-secrets.sh), same false-positive bar as the file scan. NO self-skip:
#     no project wiring anywhere covers Bash-written files, schnapp-os included.
#
# Anti-stale: one pattern source (scripts/scan-secrets.sh), one wiring wrapper.
set -uo pipefail
SELF_OS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OS_DIR="${SCHNAPP_OS_DIR:-$SELF_OS}"
INPUT="$(cat)"

# jq-first with python3 fallback (the write-hook dual-path convention) so the guard survives
# a surface with only one JSON parser.
extract() { # $1 = jq filter, $2 = python expression on parsed dict d
  local v=""
  if command -v jq >/dev/null 2>&1; then
    v="$(printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null)"
  elif command -v python3 >/dev/null 2>&1; then
    v="$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print($2 or '')
" 2>/dev/null)"
  fi
  printf '%s' "$v"
}

tool="$(extract '.tool_name' 'd.get("tool_name")')"

if [ "$tool" = "Bash" ]; then
  cmd="$(extract '.tool_input.command' 'd.get("tool_input", {}).get("command")')"
  [ -n "$cmd" ] || exit 0
  SCAN="$OS_DIR/scripts/scan-secrets.sh"
  [ -f "$SCAN" ] || exit 0
  # Fast path: one grep with the BLOCK alternation emitted by the canonical registry itself
  # (scan-secrets.sh --block-re; no pattern copies here - anti-stale). Only a hit pays for
  # the full scanner run (~0.3s); the no-hit common path costs one grep.
  block_re="$(bash "$SCAN" --block-re 2>/dev/null | paste -sd'|' -)"
  printf '%s' "$cmd" | grep -qE -e "$block_re" 2>/dev/null
  [ $? -eq 1 ] && exit 0   # 1 = clean no-match; 0 = hit and >=2 = grep error/empty regex both fall through to the full scan (fail SAFE)
  tmp="$(mktemp)"
  printf '%s' "$cmd" > "$tmp"
  findings="$(bash "$SCAN" "$tmp" 2>/dev/null)"
  status=$?
  rm -f "$tmp"
  if [ "$status" -ne 0 ]; then
    {
      echo "LEAK GUARD (secrets-as-references): this Bash command contains a literal secret VALUE:"
      printf '%s\n' "$findings"
      echo "Blocked before execution. Pass the secret by REFERENCE instead: op read 'op://...',"
      echo "op run, or an env var expansion - never the literal (rules/global/secrets-as-references.md)."
      echo "If the value was ever committed or executed it must be ROTATED (rotate-secret skill)."
    } >&2
    exit 2
  fi
  exit 0
fi

# Write/Edit/MultiEdit leg: self-skip inside schnapp-os (project wiring covers it there).
# Identity is the git remote, NOT the path: on the web surface the working checkout and the
# shell clone are different paths for the same repo, and a path compare double-scanned there.
proj="${CLAUDE_PROJECT_DIR:-}"
proj_url="$(git -C "$proj" remote get-url origin 2>/dev/null || true)"
case "$proj_url" in
  *[/:][Ss]chnapp[Aa][Pp][Ii]/schnapp-os|*[/:][Ss]chnapp[Aa][Pp][Ii]/schnapp-os.git)
    exit 0
    ;;
esac
printf '%s' "$INPUT" | bash "$OS_DIR/hooks/secret-scan-on-write.sh"
exit $?
