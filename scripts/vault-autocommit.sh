#!/usr/bin/env bash
# vault-autocommit.sh: commit + push the schnapp-vault working tree so git truth never lags
# Obsidian / obsidian-mcp edits (Phase-1 follow-up of the 2026-06-30 streamline plan; memory-mcp
# already auto-commits its own writes, manual/Obsidian edits had no equivalent).
#
# Runs from launchd (scheduled-tasks/com.schnapp.vault-autocommit.plist, every 5 min) or by hand.
# Safety model:
#   - main-only, never force, pull --rebase --autostash before push (repo global constraints).
#   - Debounce: if any dirty path was modified within AUTOCOMMIT_QUIET_SECONDS (default 120),
#     skip this run - an edit is likely still in progress; the next interval sweeps it.
#   - The vault's own pre-commit hook (core.hooksPath scripts/git-hooks) stays the schema gate:
#     if it rejects, the tree is left dirty and this exits 2 so launchd's last-exit surfaces it.
#   - No secrets: git pushes with the Mac's existing credential helper.
# Exit codes: 0 ok/no-op, 1 precondition (dir/branch), 2 commit blocked, 3 push/pull failed.
set -uo pipefail
export LC_ALL=C

VAULT_DIR="${VAULT_DIR:-$HOME/code/schnapp-vault}"
QUIET="${AUTOCOMMIT_QUIET_SECONDS:-120}"

log() { echo "[vault-autocommit] $*"; }

[ -d "$VAULT_DIR/.git" ] || { log "not a git repo: $VAULT_DIR"; exit 1; }
cd "$VAULT_DIR" || exit 1

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ "$branch" != "main" ]; then
  log "on '$branch', not main - refusing to auto-commit"; exit 1
fi

# macOS ships bash 3.2 (no mapfile); newline-split a plain variable instead. Paths with
# spaces survive via IFS=newline; quoted porcelain paths get unwrapped by the sed.
dirty_paths="$(git status --porcelain | sed 's/^...//; s/^"//; s/"$//')"
if [ -z "$dirty_paths" ]; then
  exit 0
fi
dirty_count="$(printf '%s\n' "$dirty_paths" | wc -l | tr -d ' ')"

# Debounce: newest mtime among dirty paths must be older than the quiet window.
now="$(date +%s)"
old_ifs="$IFS"; IFS=$'\n'
for p in $dirty_paths; do
  # Renames show as "old -> new"; the live path is the right-hand side.
  p="${p##* -> }"
  [ -e "$p" ] || continue
  m="$(stat -f %m "$p" 2>/dev/null || stat -c %Y "$p" 2>/dev/null)" || continue
  if [ $(( now - m )) -lt "$QUIET" ]; then
    log "recent edit (<${QUIET}s) on '$p' - waiting for quiet"; exit 0
  fi
done
IFS="$old_ifs"

git add -A
if ! git -c user.name="vault-autocommit" -c user.email="vault-autocommit@schnapp.bet" \
     commit -m "vault: auto-commit working-tree sweep (${dirty_count} path(s))"; then
  log "commit rejected (pre-commit gate?) - tree left dirty for review"; exit 2
fi

if ! git pull --rebase --autostash -q; then
  log "pull --rebase failed - resolve manually"; exit 3
fi
if ! git push -q; then
  log "push failed"; exit 3
fi
log "pushed: $(git log --oneline -1)"
exit 0
