#!/usr/bin/env bash
# global-vault-push.sh - the portable shell's ANY-REPO SessionEnd hook (ADR 0033, Link B).
#
# Wired at USER scope (~/.claude/settings.json via shell/install.sh). Closes the memory
# round-trip on Code surfaces: a session in any repo writes memory into the vault
# (autoMemoryDirectory / direct edits per docs/memory-lane.md); this pushes it so GitHub
# mirrors local before the machine goes quiet.
#
# Thin wrapper, no second implementation (anti-stale): the commit+push engine is
# scripts/vault-autocommit.sh (main-only, never force, pull --rebase --autostash, the vault's
# pre-commit schema gate stays the gatekeeper). Debounce is disabled here - at SessionEnd the
# writes are finished by definition. On the Mac the launchd 5-minute autocommit already sweeps
# the vault; this hook makes the push immediate at session end and portable to machines
# without the launchd job. VAULT ONLY: the schnapp-os backup stays project-scoped
# (decisions/0005 wrong-scope warning; decisions/0033).
#
# SessionEnd is advisory and cannot block: always exits 0.
set -uo pipefail

# Self-locate the live clone (this script lives in it), env-overridable; vault as in
# global-session-gate.sh (env, Mac-standard path, sibling checkout).
SELF_OS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OS_DIR="${SCHNAPP_OS_DIR:-$SELF_OS}"
VAULT="${VAULT_DIR:-$HOME/code/schnapp-vault}"
[ -d "$VAULT" ] || VAULT="$(dirname "$OS_DIR")/schnapp-vault"

ENGINE="$OS_DIR/scripts/vault-autocommit.sh"
[ -d "$VAULT/.git" ] || { echo "[shell] vault push skipped: no vault clone at $VAULT"; exit 0; }
[ -f "$ENGINE" ] || { echo "[shell] vault push skipped: no engine at $ENGINE"; exit 0; }

if out="$(VAULT_DIR="$VAULT" AUTOCOMMIT_QUIET_SECONDS=0 bash "$ENGINE" 2>&1)"; then
  if [ -n "$out" ]; then
    echo "[shell] vault: $(printf '%s' "$out" | tail -1)"
  else
    echo "[shell] vault: clean, nothing to push"
  fi
else
  echo "[shell] vault push FAILED (tree left for review): $(printf '%s' "$out" | tail -1)"
fi
exit 0
