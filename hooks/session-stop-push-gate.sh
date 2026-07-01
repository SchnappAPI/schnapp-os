#!/usr/bin/env bash
# session-stop-push-gate.sh — schnapp-os Stop gate: never leave unpushed commits
# (PLAN.md 7.2 + keep-tracker-current "push immediately").
#
# Fires when the agent tries to stop. If commits exist that are not on the upstream branch,
# it BLOCKS the stop (decision: block) and instructs a push, so committed state never lingers
# unpushed past a turn.
#
# Boundaries (deliberate):
#   - Hard-blocks ONLY on unpushed commits. Uncommitted edits are noted, not blocked — blocking
#     those would trap normal mid-work editing; the inline keep-tracker-current rule commits +
#     pushes state-changing work as it happens.
#   - Anti-loop: if it already blocked once this cycle (stop_hook_active) and commits are STILL
#     unpushed (push failing / offline), it warns and ALLOWS the stop instead of looping forever.
#   - No upstream branch → nothing to enforce → allow.
#
# Outputs a block-decision JSON on stdout when blocking; exits 0 (allow) otherwise.
set -uo pipefail

input="$(cat 2>/dev/null || true)"

stop_active="false"
if command -v jq >/dev/null 2>&1; then
  stop_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
elif printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  stop_active="true"
fi

REPO="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$REPO" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
[ -z "$upstream" ] && exit 0

ahead="$(git rev-list --count '@{u}'..HEAD 2>/dev/null || echo 0)"
[ "$ahead" = "0" ] && exit 0   # nothing unpushed → allow stop

if [ "$stop_active" = "true" ]; then
  # Already prompted once and still unpushed (push failing / offline) → don't trap; warn + allow.
  echo "[stop-gate] WARNING: $ahead commit(s) still unpushed (push appears to be failing — offline?). Allowing stop; push when back online." >&2
  exit 0
fi

uncommitted="$(git status --porcelain 2>/dev/null | grep -c . || true)"
note=""
[ "${uncommitted:-0}" != "0" ] && note=" ($uncommitted uncommitted file(s) also present — commit state-changing work first.)"

printf '{"decision":"block","reason":"%s unpushed commit(s) on %s. Run: git push (keep-tracker-current: never leave unpushed work).%s Then stop."}\n' \
  "$ahead" "$upstream" "$note"
exit 0
