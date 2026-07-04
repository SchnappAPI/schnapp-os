#!/usr/bin/env bash
# shell/web-setup.sh - the portable shell's WEB leg (ADR 0033). Canonical copy lives here;
# the owner pastes it into each Claude Code web environment's setup script.
#
# Runs at environment init (Anthropic container), NOT at session start, and its result is
# cached ~7 days - so this only bootstraps the clones and wiring; per-session freshness is the
# SessionStart global-session-gate.sh pull (fires if the container honors user-scope hooks).
# Whether web honors user-scope wiring at all is ADR 0033's open question: the first web
# session after this runs verifies it (the gate announces itself with a [shell] line; no line
# means user scope is ignored there and the documented boundary applies - account-scope MCP +
# the clones below are what a web session gets).
#
# Never bricks environment init: always exits 0.
set -uo pipefail

BASE="${SHELL_CLONE_BASE:-$HOME/code}"
mkdir -p "$BASE"

clone_or_pull() { # $1=repo $2=dest
  if [ -d "$2/.git" ]; then
    git -C "$2" pull --ff-only 2>&1 | tail -1
  elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh repo clone "SchnappAPI/$1" "$2" 2>&1 | tail -1
  else
    git clone "https://github.com/SchnappAPI/$1" "$2" 2>&1 | tail -1
  fi
}

echo "[web-setup] cloning the two live repos under $BASE"
clone_or_pull schnapp-os "$BASE/schnapp-os" || echo "[web-setup] WARN: schnapp-os clone failed (check the environment's GitHub access covers SchnappAPI/schnapp-os)"
clone_or_pull schnapp-vault "$BASE/schnapp-vault" || echo "[web-setup] WARN: vault clone failed (check access covers SchnappAPI/schnapp-vault)"

if [ -f "$BASE/schnapp-os/shell/install.sh" ]; then
  VAULT_DIR="$BASE/schnapp-vault" bash "$BASE/schnapp-os/shell/install.sh" || echo "[web-setup] WARN: installer failed"
else
  echo "[web-setup] WARN: installer missing; wiring not written"
fi
exit 0
