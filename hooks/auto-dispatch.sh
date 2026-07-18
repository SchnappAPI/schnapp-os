#!/usr/bin/env bash
# auto-dispatch.sh - PostToolUse dispatcher for autonomous hooks (ADR 0037 tier 3).
# Registered ONCE in .claude/settings.json; every executable hooks/auto/*.sh runs with the same
# hook stdin JSON. Adding an auto-hook is therefore a file drop, no settings change - which keeps
# the autonomous lane's write scope at "add a script", never "edit wiring".
# Exit: 2 if any child exits 2 (an enforce-mode hook blocked); else 0. A child that errors
# (non-0, non-2) is reported but never blocks - only an explicit enforce verdict may block.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTO_DIR="${AUTO_HOOK_DIR:-"$HERE/auto"}"
[ -d "$AUTO_DIR" ] || exit 0

stdin_file="$(mktemp)"
trap 'rm -f "$stdin_file"' EXIT
cat > "$stdin_file" 2>/dev/null || true

rc=0
for h in "$AUTO_DIR"/*.sh; do
  [ -f "$h" ] || continue
  out="$(bash "$h" < "$stdin_file" 2>&1)"; hrc=$?
  if [ "$hrc" -eq 2 ]; then
    printf '%s\n' "$out" >&2
    rc=2
  elif [ "$hrc" -ne 0 ]; then
    echo "[auto-dispatch] $(basename "$h") errored (rc=$hrc, ignored): $out"
  fi
done
exit "$rc"
