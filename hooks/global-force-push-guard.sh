#!/usr/bin/env bash
# global-force-push-guard.sh - user-scope (any-repo) delivery of the force-push hard guard
# (ADR 0033; policy decisions/0011 #9 is machine-wide by nature: no agent force-pushes
# anywhere). Delegates to the canonical no-force-push-guard.sh with stdin intact.
#
# Skips inside schnapp-os itself, where the project wiring runs the same guard (kept
# project-scoped for web parity) - avoids a double block message on a real force-push.
set -uo pipefail
SELF_OS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OS_DIR="${SCHNAPP_OS_DIR:-$SELF_OS}"
proj="${CLAUDE_PROJECT_DIR:-}"
if [ -n "$proj" ] && [ "$(cd "$proj" 2>/dev/null && pwd -P)" = "$OS_DIR" ]; then
  cat >/dev/null
  exit 0
fi
exec bash "$OS_DIR/hooks/no-force-push-guard.sh"
