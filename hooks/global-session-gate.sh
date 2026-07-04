#!/usr/bin/env bash
# global-session-gate.sh - the portable shell's ANY-REPO SessionStart hook (ADR 0033, Link A).
#
# Wired at USER scope (~/.claude/settings.json via shell/install.sh), so it fires in every
# project on the machine. Jobs, in order:
#   1. Keep the two live clones FRESH: ff-only pull of schnapp-os + schnapp-vault. The whole
#      shell reads rules/hooks/skills/memory from these clones, so their freshness is what makes
#      Link A live on this machine (the schnapp-os project gate only ran inside schnapp-os).
#   2. WIRING drift check: every skill/agent/command in the live clone must have its
#      ~/.claude symlink; a missing one means shell/install.sh needs a re-run.
#   3. ORIENT: point the session at the vault memory index (foreign repos get no project gate).
#
# Inside schnapp-os itself the project session-start-gate.sh already pulls the repo and prints
# the full gate, so this hook stays quiet there and only ff-pulls the VAULT (which the project
# gate checks but never pulls).
#
# Stdout is injected into the session context. Never blocks: always exits 0; offline or a held
# git lock degrades to a one-line warning. GIT_TERMINAL_PROMPT=0 so a credential prompt can
# never hang a session start; the settings-level timeout is the hard stop.
set -uo pipefail
export GIT_TERMINAL_PROMPT=0

# Self-locate the live clone (this script lives in it), env-overridable. Vault: env, the
# Mac-standard path, then a sibling checkout (the cloud env clones both side by side).
SELF_OS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OS_DIR="${SCHNAPP_OS_DIR:-$SELF_OS}"
VAULT="${VAULT_DIR:-$HOME/code/schnapp-vault}"
[ -d "$VAULT" ] || VAULT="$(dirname "$OS_DIR")/schnapp-vault"

# ff-only pull; echoes a short status token. Never fails the hook.
pull_repo() { # $1=dir $2=label
  local dir="$1" label="$2" branch out
  [ -d "$dir/.git" ] || { echo "$label: no clone at $dir"; return; }
  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  if [ -z "$branch" ] || [ "$branch" = "HEAD" ]; then
    echo "$label: detached/unknown branch, not pulled"; return
  fi
  if out="$(git -C "$dir" pull --ff-only origin "$branch" 2>&1)"; then
    if printf '%s' "$out" | grep -q 'Already up to date'; then
      echo "$label: fresh"
    else
      echo "$label: UPDATED ($(git -C "$dir" log --oneline -1 2>/dev/null | cut -c1-60))"
    fi
  else
    echo "$label: pull FAILED (offline/diverged/locked) - $(printf '%s' "$out" | tail -1 | cut -c1-80)"
  fi
}

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
if [ "$(cd "$PROJECT" 2>/dev/null && pwd -P)" = "$(cd "$OS_DIR" 2>/dev/null && pwd -P)" ]; then
  # schnapp-os session: the project gate owns the OS pull + full report. Vault pull only,
  # and only speak when something happened.
  vault_status="$(pull_repo "$VAULT" "vault")"
  case "$vault_status" in
    "vault: fresh") : ;;
    *) echo "[shell] $vault_status" ;;
  esac
  exit 0
fi

os_status="$(pull_repo "$OS_DIR" "schnapp-os")"
vault_status="$(pull_repo "$VAULT" "vault")"

# Wiring drift: every live component should be symlinked into ~/.claude (shell/install.sh).
missing=0
for kind in skills agents commands; do
  src="$OS_DIR/.claude/$kind"
  [ -d "$src" ] || continue
  for item in "$src"/*; do
    name="$(basename "$item")"
    [ "$name" = ".DS_Store" ] && continue
    [ -e "$HOME/.claude/$kind/$name" ] || missing=$((missing+1))
  done
done
if [ "$missing" -eq 0 ]; then wiring="wiring intact"; else wiring="WIRING DRIFT: $missing component(s) unlinked - run $OS_DIR/shell/install.sh"; fi

echo "[shell] $os_status | $vault_status | $wiring"
[ -f "$VAULT/memory/MEMORY.md" ] && echo "[shell] memory: read $VAULT/memory/MEMORY.md (thin index) first, then load facts on demand; write-backs follow the vault agents.md schema (supersede, never append)."
exit 0
