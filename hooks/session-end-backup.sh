#!/usr/bin/env bash
# session-end-backup.sh — schnapp-os end-of-session write, deterministic half.
#
# Fires on SessionEnd. Two jobs:
#   1. BACKUP: run backup-archive.sh — mirror memory/handoffs/decisions/PLAN/PROGRESS +
#      session transcripts into the OneDrive claude-archive vault.
#      Best-effort, never fatal.
#   2. REMINDER: surface unpushed / uncommitted state as a closing nudge so the end-of-session
#      memory + handoff WRITE and commit+push (agent judgment, per docs/memory-lane.md
#      "End-of-session write" + keep-tracker-current) is not skipped.
#
# The hook automates only the deterministic backup; it cannot author memory/handoff prose —
# that stays the agent's procedure. SessionEnd hooks cannot block, so this is advisory.
# Never exits non-zero.
set -uo pipefail

REPO="${CLAUDE_PROJECT_DIR:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "===== schnapp-os SESSION-END ====="

# 1. Backup (non-fatal). backup-archive.sh always mirrors the schnapp-os knowledge base
#    (its own CLAUDE_KIT_REPO default / env override), regardless of the session's project.
BACKUP="$SCRIPT_DIR/../scripts/backup-archive.sh"
if [ -f "$BACKUP" ]; then
  if out="$(bash "$BACKUP" 2>&1)"; then
    echo "[backup] $out"
  else
    echo "[backup] skipped/failed (non-fatal): $out"
  fi
else
  echo "[backup] script not found at $BACKUP"
fi

# 2. Unpushed/dirty reminder for the project the session worked in.
cd "$REPO" 2>/dev/null || { echo "=================================="; exit 0; }
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  dirty="$(git status --porcelain 2>/dev/null)"
  ahead="$(git rev-list --count '@{u}'..HEAD 2>/dev/null || echo 0)"
  [ -n "$dirty" ]    && echo "[reminder] uncommitted changes remain — commit state-changing work + update PROGRESS/handoff."
  [ "$ahead" != "0" ] && echo "[reminder] $ahead unpushed commit(s) — push now (keep-tracker-current)."
  [ -z "$dirty" ] && [ "$ahead" = "0" ] && echo "[ok] tree clean + pushed."
fi
echo "=================================="
exit 0
