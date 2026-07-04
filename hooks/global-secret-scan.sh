#!/usr/bin/env bash
# global-secret-scan.sh - user-scope (any-repo) delivery of the secret-scan leak guard
# (ADR 0033, Link A guard layer). Delegates to the canonical secret-scan-on-write.sh with
# stdin intact; adds nothing else (anti-stale: one scanner, one wiring wrapper).
#
# Skips inside schnapp-os itself: the project .claude/settings.json wires the same scanner
# there (kept project-scoped for web parity, where user scope is not honored) - without this
# skip every Write in schnapp-os would be scanned twice and a finding would surface twice.
set -uo pipefail
SELF_OS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OS_DIR="${SCHNAPP_OS_DIR:-$SELF_OS}"
proj="${CLAUDE_PROJECT_DIR:-}"
if [ -n "$proj" ] && [ "$(cd "$proj" 2>/dev/null && pwd -P)" = "$OS_DIR" ]; then
  cat >/dev/null
  exit 0
fi
exec bash "$OS_DIR/hooks/secret-scan-on-write.sh"
