#!/usr/bin/env bash
# shell/mac-setup.sh - the portable shell's MAC leg (ADR 0033). One command to take a NEW Mac
# from bare to a fully wired Claude Code system: install the op CLI, clone the two live repos,
# and run shell/install.sh (which writes the user-scope rules/hooks/skills/memory wiring).
#
# The Mac analog of shell/web-setup.sh (that leg targets the Linux web container; this one uses
# the macOS op-CLI install and macOS paths). install.sh does the actual wiring and is idempotent,
# so this whole script is safe to re-run: it clone-or-pulls and re-installs in place.
#
# OWNER PREREQUISITES (interactive, cannot be scripted headlessly - do these once first):
#   - GitHub auth for this Mac: an SSH key added to the account, or `gh auth login`. Needed to
#     clone the (private) repos and to push vault writes from the SessionEnd hook.
#   - Optional: `op signin` (or 1Password app + Touch ID) if you want in-terminal op:// resolution
#     outside the MCP connectors. The op-mcp connector resolves secrets regardless.
#
# Run (the repos are private, so fetch schnapp-os first with your GitHub auth, then run this):
#   git clone git@github.com:SchnappAPI/schnapp-os.git ~/code/schnapp-os
#   bash ~/code/schnapp-os/shell/mac-setup.sh
# Re-running later just pulls + re-wires (idempotent); the vault clone is handled by this script.
#
# Best-effort: warns and continues rather than half-failing; exits 0.
set -uo pipefail

[ "$(uname -s)" = "Darwin" ] || { echo "[mac-setup] not macOS - use shell/install.sh directly (or web-setup.sh in a web env)"; exit 0; }

# 0. Hard prerequisites present on macOS by default (git ships with the Xcode Command Line Tools).
if ! command -v git >/dev/null 2>&1; then
  echo "[mac-setup] git not found. Install the Command Line Tools first: xcode-select --install"; exit 0
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "[mac-setup] WARN: python3 not found - install.sh needs it to merge settings.json (brew install python3 or Xcode CLT)"
fi

# 1. op CLI (macOS): in-terminal op:// resolution. Non-fatal - the op-mcp connector still resolves
#    secrets remotely without it.
if command -v op >/dev/null 2>&1; then
  echo "[mac-setup] op present: $(op --version)"
elif command -v brew >/dev/null 2>&1; then
  brew install --cask 1password-cli 2>&1 | tail -1 || echo "[mac-setup] WARN: op CLI install failed (op-mcp connector unaffected)"
else
  echo "[mac-setup] WARN: Homebrew not found - skipping op CLI (install from https://brew.sh, then: brew install --cask 1password-cli)"
fi

# 2. The two live clones + the shell wiring.
BASE="${SHELL_CLONE_BASE:-$HOME/code}"
mkdir -p "$BASE"

clone_or_pull() { # $1=repo $2=dest
  if [ -d "$2/.git" ]; then
    git -C "$2" pull --ff-only 2>&1 | tail -1
  elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh repo clone "SchnappAPI/$1" "$2" 2>&1 | tail -1
  else
    git clone "git@github.com:SchnappAPI/$1.git" "$2" 2>&1 | tail -1
  fi
}

echo "[mac-setup] cloning the two live repos under $BASE"
clone_or_pull schnapp-os "$BASE/schnapp-os" || echo "[mac-setup] WARN: schnapp-os clone failed (is this Mac's GitHub auth set up? SSH key or gh auth login)"
clone_or_pull schnapp-vault "$BASE/schnapp-vault" || echo "[mac-setup] WARN: vault clone failed (GitHub auth covers SchnappAPI/schnapp-vault?)"

if [ -f "$BASE/schnapp-os/shell/install.sh" ]; then
  VAULT_DIR="$BASE/schnapp-vault" bash "$BASE/schnapp-os/shell/install.sh" || echo "[mac-setup] WARN: installer failed"
else
  echo "[mac-setup] WARN: installer missing at $BASE/schnapp-os/shell/install.sh; wiring not written"
fi

echo "[mac-setup] done. Open a new Claude Code session in any repo to verify: look for a [shell] status line at session start."
exit 0
