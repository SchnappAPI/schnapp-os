#!/usr/bin/env bash
# auto-hook-lib.sh - shared verdict helper for autonomous hooks (ADR 0037 tier 3).
# An auto-hook sources this and calls `auto_hook_verdict <name> <mode> <reason>` when its check
# FAILS. observe mode: append a would-block line to the ledger and exit 0 (never blocks).
# enforce mode: exit 2 with the reason (a real blocking hook). Any other mode: treated as
# observe (fail-open on mode typos - a malformed auto-hook must never brick sessions).
# Ledger: ~/Library/Logs/schnapp-os/auto-hooks.log (one line per would-block; the escalator
# and the FP process read it).

AUTO_HOOK_LEDGER="${AUTO_HOOK_LEDGER:-"$HOME/Library/Logs/schnapp-os/auto-hooks.log"}"

auto_hook_verdict() { # <name> <mode> <reason>
  local name="$1" mode="$2" reason="$3"
  if [ "$mode" = "enforce" ]; then
    echo "[auto-hook:$name] BLOCKED: $reason" >&2
    exit 2
  fi
  mkdir -p "$(dirname "$AUTO_HOOK_LEDGER")" 2>/dev/null
  printf '%s\t%s\twould-block\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$name" "$reason" \
    >> "$AUTO_HOOK_LEDGER" 2>/dev/null
  exit 0
}
