#!/usr/bin/env bash
# shell/web-setup.sh - the portable shell's WEB leg (ADR 0033). Canonical copy lives here;
# the owner pastes this WHOLE file into each Claude Code web environment's setup script
# (it replaced the standalone op-CLI-only setup script - this is a superset).
#
# Runs at environment init (Anthropic container), NOT at session start, and its result is
# cached ~7 days - so this only bootstraps the op CLI, the clones, and the wiring; per-session
# freshness is the SessionStart global-session-gate.sh pull. Web honors user-scope wiring:
# VERIFIED YES 2026-07-18 ([shell] gate line observed live, closing ADR 0033's open question).
# If a future session shows no [shell] line, the platform changed: re-verify per
# skills/os-cross-surface-campaign Phase 2 (fallback boundary = account-scope MCP + these clones).
#
# Requirements (docs/environment-and-access.md §1): env vars OP_SERVICE_ACCOUNT_TOKEN,
# MAC_MCP_AUTH_TOKEN, OP_MCP_BEARER, MEMORY_MCP_BEARER; allowlist incl. my.1password.com,
# cache.agilebits.com, github.com, api.github.com + the schnapp/Render MCP hosts.
#
# Never bricks environment init: always exits 0.
set -uo pipefail

# 1. op CLI: in-container op:// resolution via OP_SERVICE_ACCOUNT_TOKEN. Non-fatal: without
#    it the op-mcp connector still resolves secrets remotely.
install_op() (
  if command -v op >/dev/null 2>&1; then echo "[web-setup] op present: $(op --version)"; return 0; fi
  VER=2.33.1
  URL="https://cache.agilebits.com/dist/1P/op2/pkg/v${VER}/op_linux_amd64_v${VER}.zip"
  cd /tmp || return 1
  if command -v curl >/dev/null 2>&1; then curl -sSfL "$URL" -o op.zip; else wget -q "$URL" -O op.zip; fi || return 1
  if command -v unzip >/dev/null 2>&1; then unzip -o op.zip op -d /usr/local/bin/; \
  else python3 -c "import zipfile;zipfile.ZipFile('op.zip').extract('op','/usr/local/bin')"; fi || return 1
  chmod 755 /usr/local/bin/op
  rm -f op.zip
  op --version
)
install_op || echo "[web-setup] WARN: op CLI install failed - in-container op:// resolution unavailable (op-mcp connector unaffected)"

# 2. The two live clones + the shell wiring.
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
