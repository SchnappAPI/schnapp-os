#!/usr/bin/env bash
# session-start-gate.sh — claude-kit SessionStart freshness + git gate (PLAN.md 5.3 / 7.2).
#
# Fires at session start (matcher: startup). Two deterministic jobs:
#   1. SYNC: git pull --ff-only — absorbs the Part 0.3 sync (non-fatal, fast-forward only,
#      never clobbers local work; surfaces divergence).
#   2. GATE: surface unmerged / unpushed / dirty git state + a memory freshness scan so the
#      agent addresses stale state and unpushed work BEFORE new work. This is the deterministic
#      half of the freshness-gate procedure in memory/README.md; the memory *reasoning*
#      (compare updated:, decide what is current) stays the agent's job — this hook only
#      surfaces the signals.
#
# Stdout is injected into the session context by Claude Code. The hook never blocks and
# always exits 0 (a SessionStart failure must not stop the session).
set -uo pipefail

REPO="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$REPO" 2>/dev/null || { echo "[claude-kit gate] cannot cd to $REPO"; exit 0; }

echo "===== claude-kit SESSION-START GATE ====="

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[sync] not a git work tree; skipping gate"
  echo "========================================"
  exit 0
fi

# 1. Sync (Part 0.3): fast-forward only; non-fatal.
if pull_out="$(git pull --ff-only 2>&1)"; then
  echo "[sync] $pull_out"
else
  echo "[sync] pull not fast-forward or offline — resolve before work (PLAN 0.3 / 8.2): $pull_out"
fi

# 2. Git gate: surface state to address first.
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
echo "[git] branch: $branch"

dirty="$(git status --porcelain 2>/dev/null)"
if [ -n "$dirty" ]; then
  echo "[git] UNCOMMITTED changes — commit state-changing work before new work:"
  echo "$dirty" | sed 's/^/        /'
else
  echo "[git] working tree clean"
fi

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
if [ -n "$upstream" ]; then
  ahead="$(git rev-list --count '@{u}'..HEAD 2>/dev/null || echo 0)"
  behind="$(git rev-list --count HEAD..'@{u}' 2>/dev/null || echo 0)"
  [ "$ahead" != "0" ]  && echo "[git] UNPUSHED: $ahead commit(s) ahead of $upstream — push now (keep-tracker-current)."
  [ "$behind" != "0" ] && echo "[git] BEHIND: $behind commit(s) behind $upstream — pull/rebase before work."
  [ "$ahead" = "0" ] && [ "$behind" = "0" ] && echo "[git] in sync with $upstream"
else
  echo "[git] no upstream tracking branch set"
fi

# 3. Memory freshness scan (deterministic signals; reasoning stays the agent's per memory/README.md).
MEM="$REPO/memory"
if [ -d "$MEM" ]; then
  orphans=""
  for f in "$MEM"/*.md; do
    [ -e "$f" ] || continue
    case "$(basename "$f")" in MEMORY.md|README.md) continue;; esac
    sup="$(sed -n 's/^supersedes:[[:space:]]*//p' "$f" | head -1)"
    sup="${sup//\"/}"; sup="${sup//\'/}"; sup="${sup// /}"
    [ -z "$sup" ] && continue
    [ -f "$MEM/$sup.md" ] && orphans="${orphans}        - $(basename "$f") supersedes '$sup' but $sup.md still exists"$'\n'
  done
  if [ -n "$orphans" ]; then
    echo "[memory] SUPERSEDE-ORPHANS — the old fact should be replaced/removed (supersede-not-append):"
    printf "%s" "$orphans"
  else
    echo "[memory] no supersede-orphans"
  fi
else
  echo "[memory] no memory/ dir"
fi

echo "[next] Address unpushed/unmerged + stale memory above BEFORE new work (PLAN 5.3 / 8.2)."
echo "========================================"
exit 0
