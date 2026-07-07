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
#   - Concurrency (two SessionEnd hooks, or SessionEnd + launchd): a same-machine mutex
#     serializes us so two runs NEVER issue concurrent git ops - the loser finds the lock held
#     and skips (exit 0); the holder's `git add -A` sweeps every dirty path, so nothing is lost.
#     This is deterministic across every interleaving (no reliance on parsing git's contention
#     stderr). A FOREIGN writer that does not share our mutex (memory-mcp, Obsidian git, a manual
#     git) can still collide on git's own index.lock/HEAD.lock; those messages are classified
#     benign (concurrent_or_swept), leaving exit 2 for a genuine pre-commit gate rejection alone.
# Exit codes: 0 ok/no-op, 1 precondition (dir/branch), 2 commit blocked, 3 push/pull failed.
set -uo pipefail
export LC_ALL=C

VAULT_DIR="${VAULT_DIR:-$HOME/code/schnapp-vault}"
QUIET="${AUTOCOMMIT_QUIET_SECONDS:-120}"
# A crashed holder must not wedge the every-5-min launchd job forever: reclaim a lock older
# than this (a live run finishes well under it - add+commit+push is seconds, not minutes).
LOCK_STALE_SECONDS="${AUTOCOMMIT_LOCK_STALE_SECONDS:-300}"

log() { echo "[vault-autocommit] $*"; }

# Epoch mtime of $1 (GNU stat first, BSD fallback), or empty on failure. See the debounce
# loop below for why GNU is tried first even on macOS.
mtime_of() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }

# A failing git op during a concurrent sweep is benign, not a gate rejection: another writer
# holds a lock (index.lock during staging, HEAD.lock / "cannot lock ref" during the ref update),
# or already swept our paths ("nothing to commit"). Our mutex means this only fires for a FOREIGN
# writer; a real pre-commit rejection matches none of these and leaves the tree dirty -> exit 2.
concurrent_or_swept() { # $1 = git stderr; rc 0 if benign concurrency/sweep, 1 if a real failure
  case "$1" in
    *index.lock*|*HEAD.lock*|*"cannot lock ref"*|*"nothing to commit"*) return 0 ;;
  esac
  return 1
}

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
  # GNU first: on Linux `stat -f %m` is a VALID filesystem query (prints a mount point, not
  # an epoch) so BSD-first "succeeds" with garbage and the arithmetic below fatals the shell
  # (word-expansion error exits non-interactive bash). On macOS `stat -c` errors, BSD -f runs.
  m="$(mtime_of "$p")" || continue
  case "$m" in ''|*[!0-9]*) continue ;; esac
  if [ $(( now - m )) -lt "$QUIET" ]; then
    log "recent edit (<${QUIET}s) on '$p' - waiting for quiet"; exit 0
  fi
done
IFS="$old_ifs"

# Same-machine mutex (atomic mkdir - portable, no flock on bash 3.2). Two vault-autocommit runs
# (two SessionEnd hooks, or SessionEnd + launchd) must never issue concurrent git ops, or the
# loser's commit can collide on HEAD.lock during the ref update and be misread as a gate failure.
# The loser skips deterministically; the holder's `git add -A` sweeps its dirty paths too. A
# crashed holder is reclaimed once the lock ages past LOCK_STALE_SECONDS so launchd never wedges.
LOCK="$VAULT_DIR/.git/vault-autocommit.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  lock_m="$(mtime_of "$LOCK")"
  case "$lock_m" in
    ''|*[!0-9]*) log "another vault-autocommit run holds the lock - skipping (it sweeps this tree)"; exit 0 ;;
  esac
  if [ $(( now - lock_m )) -ge "$LOCK_STALE_SECONDS" ]; then
    log "stale lock (>${LOCK_STALE_SECONDS}s, holder crashed) - reclaiming"
    rmdir "$LOCK" 2>/dev/null || true
    mkdir "$LOCK" 2>/dev/null || { log "another run reclaimed first - skipping"; exit 0; }
  else
    log "another vault-autocommit run holds the lock - skipping (it sweeps this tree)"; exit 0
  fi
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

# Inside the mutex no self-concurrency is possible; concurrent_or_swept only fires for a FOREIGN
# writer (memory-mcp, Obsidian git, a manual git) racing our add/commit. A real pre-commit
# rejection matches none of its patterns, leaves the tree dirty, and exits 2.
add_out="$(git add -A 2>&1)" || {
  if concurrent_or_swept "$add_out"; then
    log "concurrent git writer - skipping; the other run sweeps"; exit 0
  fi
  log "git add failed: $(printf '%s' "$add_out" | tail -1)"; exit 2
}
if ! commit_out="$(git -c user.name="vault-autocommit" -c user.email="vault-autocommit@schnapp.bet" \
     commit -m "vault: auto-commit working-tree sweep (${dirty_count} path(s))" 2>&1)"; then
  if concurrent_or_swept "$commit_out"; then
    log "concurrent git writer or already swept - skipping"; exit 0
  fi
  log "commit rejected (pre-commit gate) - tree left dirty for review:"
  printf '%s\n' "$commit_out" | tail -5
  exit 2
fi
printf '%s\n' "$commit_out" | tail -1

# Rebase re-commits local work, so the pull needs the same host-independent ident as the
# commit (CI runners have none - the 2026-07-01 commit-identity-skew lesson).
if ! git -c user.name="vault-autocommit" -c user.email="vault-autocommit@schnapp.bet" \
     pull --rebase --autostash -q; then
  log "pull --rebase failed - resolve manually"; exit 3
fi
if ! git push -q; then
  log "push failed"; exit 3
fi
log "pushed: $(git log --oneline -1)"
exit 0
