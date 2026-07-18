#!/usr/bin/env bash
# auto-hook-escalate.sh - staged-rollout escalator for autonomous hooks (ADR 0037 tier 3).
# For each hooks/auto/*.sh still in observe mode: if its first-commit date is >= AGE_DAYS ago
# AND no OPEN GitHub issue labeled auto-hook-fp names it, flip AUTO_HOOK_MODE=observe ->
# enforce and commit+push straight to main (deterministic 1-line change; ADR 0016 no-branch).
# Fail-closed: if `gh` is unavailable the FP brake cannot be read, so NOTHING escalates.
#
# Usage: auto-hook-escalate.sh [--dry-run]
# Env: AUTO_HOOK_AGE_DAYS (default 7)
set -uo pipefail
DRY_RUN=false
for arg in "$@"; do [ "$arg" = "--dry-run" ] && DRY_RUN=true; done
REPO_ROOT="${SESSION_MINE_REPO_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}"
AGE_DAYS="${AUTO_HOOK_AGE_DAYS:-7}"
AUTO_DIR="$REPO_ROOT/hooks/auto"

[ -d "$AUTO_DIR" ] || { echo "auto-hook-escalate: no auto dir - nothing to do."; exit 0; }

if ! $DRY_RUN && ! command -v gh >/dev/null 2>&1; then
  echo "auto-hook-escalate: gh unavailable - FP brake unreadable, holding all escalations."
  exit 0
fi

cutoff="$(date -u -v-"${AGE_DAYS}"d +%Y-%m-%d 2>/dev/null \
  || date -u -d "${AGE_DAYS} days ago" +%Y-%m-%d)"
open_fp=""
$DRY_RUN || open_fp="$(gh issue list --label auto-hook-fp --state open --json title \
  --jq '.[].title' 2>/dev/null || echo GH-FAILED)"
if [ "$open_fp" = "GH-FAILED" ]; then
  echo "auto-hook-escalate: gh query failed - holding all escalations."
  exit 0
fi

flipped=""
for h in "$AUTO_DIR"/*.sh; do
  [ -f "$h" ] || continue
  name="$(basename "$h" .sh)"
  grep -q '^AUTO_HOOK_MODE=observe' "$h" || continue
  # No --follow: with similar file contents git's rename detection can trace a NEW hook back
  # to an older sibling's add-commit and escalate it early. Without it a renamed hook restarts
  # its observe window - the conservative direction.
  first="$(git -C "$REPO_ROOT" log --diff-filter=A --format=%as -1 -- "${h#"$REPO_ROOT"/}" \
    | head -1)"
  if [ -z "$first" ] || [[ "$first" > "$cutoff" ]]; then
    echo "auto-hook-escalate: $name too young (added ${first:-uncommitted}, cutoff $cutoff) - observing."
    continue
  fi
  if printf '%s\n' "$open_fp" | grep -qF "$name"; then
    echo "auto-hook-escalate: $name has an open auto-hook-fp issue - holding."
    continue
  fi
  if $DRY_RUN; then echo "would escalate: $name"; continue; fi
  sed -i '' 's/^AUTO_HOOK_MODE=observe/AUTO_HOOK_MODE=enforce/' "$h" 2>/dev/null \
    || sed -i 's/^AUTO_HOOK_MODE=observe/AUTO_HOOK_MODE=enforce/' "$h"
  flipped="$flipped $name"
done

[ -n "$flipped" ] || { echo "auto-hook-escalate: nothing to escalate."; exit 0; }
git -C "$REPO_ROOT" add hooks/auto/
git -C "$REPO_ROOT" commit -qm "feat(hooks): auto-escalate$flipped observe -> enforce (ADR 0037)" \
  -m "Clean >= ${AGE_DAYS}-day observe window, no open auto-hook-fp issue - staged rollout complete."
git -C "$REPO_ROOT" push -q origin HEAD:main \
  && echo "auto-hook-escalate: escalated$flipped (pushed to main)." \
  || echo "auto-hook-escalate: commit made but push FAILED - resolve manually." >&2
