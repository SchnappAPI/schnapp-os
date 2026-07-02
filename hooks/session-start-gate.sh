#!/usr/bin/env bash
# session-start-gate.sh - schnapp-os SessionStart freshness gate.
#
# Fires at session start (matcher: startup). Reconciles local state against ground truth
# BEFORE any work, because GitHub origin is the source of truth (you may have edited it from
# the web / another surface) and the 1Password store is the source of truth for credentials.
#
# Jobs (all deterministic; the agent's reasoning stays the agent's job):
#   1. SYNC: fast-forward local to origin (explicit refspec - the bare `git pull --ff-only`
#      form once failed with "Cannot fast-forward to multiple branches" and silently left the
#      repo stale). Never clobbers local work; surfaces divergence loudly.
#   2. GIT STATE: surface dirty / unpushed / behind so it is addressed before new work.
#   3. MEMORY: supersede-orphan scan (a fact that supersedes another whose file still exists).
#   4. SATELLITES: unpushed state in related repos (decisions/0008).
#   5. CREDS: light reconcile that the 1Password store resolves (deep check = remote op-mcp health).
#
# Stdout is injected into the session context by Claude Code. Budget ~1s. Never blocks; always
# exits 0 (a SessionStart failure must not stop the session).
set -uo pipefail

REPO="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$REPO" 2>/dev/null || { echo "[schnapp-os gate] cannot cd to $REPO"; exit 0; }

echo "===== schnapp-os SESSION-START GATE ====="

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[sync] not a git work tree; skipping gate"
  echo "========================================"
  exit 0
fi

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'HEAD')"

# 1. Sync: explicit fast-forward to origin/<branch>. Ground truth (origin) wins; never clobbers.
if sync_out="$(git pull --ff-only origin "$branch" 2>&1)"; then
  echo "[sync] origin/$branch: $(echo "$sync_out" | tail -1)"
else
  echo "[sync] could NOT fast-forward origin/$branch - diverged, dirty, or offline. Reconcile before work:"
  echo "$sync_out" | sed 's/^/        /'
fi

# 2. Git state to address first.
echo "[git] branch: $branch"
dirty="$(git status --porcelain 2>/dev/null)"
if [ -n "$dirty" ]; then
  echo "[git] UNCOMMITTED changes - commit state-changing work before new work:"
  echo "$dirty" | sed 's/^/        /'
else
  echo "[git] working tree clean"
fi
upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
if [ -n "$upstream" ]; then
  ahead="$(git rev-list --count '@{u}'..HEAD 2>/dev/null || echo 0)"
  behind="$(git rev-list --count HEAD..'@{u}' 2>/dev/null || echo 0)"
  [ "$ahead" != "0" ]  && echo "[git] UNPUSHED: $ahead commit(s) ahead of $upstream - push now (keep-tracker-current)."
  [ "$behind" != "0" ] && echo "[git] BEHIND: $behind commit(s) behind $upstream - pull/rebase before work."
  [ "$ahead" = "0" ] && [ "$behind" = "0" ] && echo "[git] in sync with $upstream"
else
  echo "[git] no upstream tracking branch set"
fi

# 3. Memory freshness scan (deterministic signals; reasoning stays the agent's per docs/memory-lane.md).
#    The global memory lane lives in the vault (SchnappAPI/schnapp-vault), not schnapp-os; scan it there.
#    Detection logic + its unit test live in scripts/check-supersede-orphans.sh so the
#    column-0-vs-indented-frontmatter bug (which made this a silent no-op) cannot regress unnoticed.
MEM="$HOME/code/schnapp-vault/memory"
if [ -d "$MEM" ]; then
  orphans="$(bash "$REPO/scripts/check-supersede-orphans.sh" "$MEM" 2>/dev/null)"
  if [ -n "$orphans" ]; then
    echo "[memory] SUPERSEDE-ORPHANS - replace/remove the old fact (supersede-not-append):"
    printf '%s\n' "$orphans" | sed 's/^/        - /'
  else
    echo "[memory] no supersede-orphans"
  fi
  stale="$(bash "$REPO/scripts/check-stale-facts.sh" "$MEM" 2>/dev/null \
            | grep -v '^memory freshness OK')"
  if [ -n "$stale" ]; then
    echo "[memory] STALE FACTS - review/refresh (read-only flag; supersede-not-append):"
    printf '%s\n' "$stale" | sed 's/^/        - /'
  else
    echo "[memory] no stale facts (<7d)"
  fi
  [ -f "$MEM/MEMORY.md" ] && echo "[memory] orient: read $MEM/MEMORY.md (thin index) first, then load facts on demand - it is the read-first map of durable knowledge."
else
  echo "[memory] no vault memory/ dir at $MEM (global lane is SchnappAPI/schnapp-vault)"
fi

# 4. Satellite repos (owner Mac): surface unpushed state so cross-repo work is not lost
#    (decisions/0008). Existence-guarded, so this no-ops on machines that lack these checkouts.
for sat in "$HOME/code/schnapp-bet" "$HOME/code/schnapp-vault"; do
  [ -d "$sat/.git" ] || continue
  name="$(basename "$sat")"
  sa="$(git -C "$sat" rev-list --count '@{u}'..HEAD 2>/dev/null || echo 0)"
  if [ "$sa" != "0" ]; then echo "[satellite:$name] UNPUSHED: $sa commit(s) not on origin - push (decisions/0008)."; else echo "[satellite:$name] pushed"; fi
done

# 5. Credential reconcile (light; the authoritative deep check is the remote op-mcp op_health tool).
#    Only calls the network when the SA token is already in env, so it never cries wolf.
if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ] && command -v op >/dev/null 2>&1; then
  if op whoami >/dev/null 2>&1; then
    echo "[creds] 1Password SA resolves (op whoami ok)"
  else
    echo "[creds] SA token set but 'op whoami' FAILED - may be rotated/invalid; fix before secret-dependent work."
  fi
elif command -v op >/dev/null 2>&1; then
  echo "[creds] op CLI present; SA token not in hook env (per-command 'op run' resolves it). Deep check = remote op-mcp health."
else
  echo "[creds] no local op - this surface resolves secrets via the remote op-mcp tool."
fi

echo "[next] Address sync/unpushed/dirty + stale memory + creds above BEFORE new work."
echo "========================================"
exit 0
