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

# Both pulls in parallel: network RTT dominates and the two repos are independent, so the
# gate costs max(pull) not sum(pull) (~2s vs ~4.5s measured sequential).
os_tmp="$(mktemp)"; vault_tmp="$(mktemp)"
pull_repo "$OS_DIR" "schnapp-os" > "$os_tmp" & os_pid=$!
pull_repo "$VAULT" "vault" > "$vault_tmp" & vault_pid=$!
wait "$os_pid" "$vault_pid"
os_status="$(cat "$os_tmp")"; vault_status="$(cat "$vault_tmp")"
rm -f "$os_tmp" "$vault_tmp"

# Wiring drift: every live component should be symlinked into ~/.claude. The installer is
# idempotent, so drift is auto-healed here (owner rule: automate, do not instruct); new links
# serve THIS session, new hooks load next session.
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
if [ "$missing" -eq 0 ]; then
  wiring="wiring intact"
elif inst_out="$(bash "$OS_DIR/shell/install.sh" 2>&1)"; then
  wiring="wiring drift ($missing unlinked) -> installer auto-ran: $(printf '%s' "$inst_out" | grep -o 'components: [0-9].*' | head -1)"
else
  wiring="WIRING DRIFT: $missing component(s) unlinked, installer auto-run FAILED - run $OS_DIR/shell/install.sh manually"
fi

echo "[shell] $os_status | $vault_status | $wiring"

# Surface a stuck memory lane. SessionEnd hook output is invisible (the session is already
# over), so a vault pre-commit rejection or failed push is only ever seen HERE, at the next
# session start, in whatever repo that happens to be. Local-only checks, no network.
if [ -d "$VAULT/.git" ]; then
  backlog=""
  dirty="$(git -C "$VAULT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  ahead="$(git -C "$VAULT" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)"
  [ "$dirty" -gt 0 ] && backlog="$dirty uncommitted path(s)"
  [ "$ahead" -gt 0 ] && backlog="${backlog:+$backlog, }$ahead unpushed commit(s)"
  [ -n "$backlog" ] && echo "[shell] vault BACKLOG: $backlog - the autocommit may be blocked (schema gate? push failure?); run bash $OS_DIR/scripts/vault-autocommit.sh to see why."
fi
[ -f "$VAULT/memory/MEMORY.md" ] && echo "[shell] memory: read $VAULT/memory/MEMORY.md (thin index) first, then load facts on demand; write-backs follow the vault agents.md schema (supersede, never append)."
exit 0
