#!/usr/bin/env bash
# run-ci-routines.sh — the SAFE, Mac-independent scheduled routines, as one bundle.
#
# Single source of truth for the two auto-class routines (PLAN Part 11.1): the doc-freshness
# sweep and the sync/unmerged check. The cron workflow
# (.github/workflows/scheduled-routines.yml) calls this; nothing here is duplicated in YAML.
# Read-only except for the freshness generator's temp file. Exit non-zero ONLY when a hard gate
# (freshness) fails, so a real problem is a visible failure and informational drift is not.
#
# Output is markdown on stdout (the workflow appends it to the job Step Summary). Config:
# CLAUDE_KIT_REPO (default: derived from this script's location, so it runs anywhere).
set -uo pipefail
export LC_ALL=C

REPO="${CLAUDE_KIT_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$REPO" || { echo "FATAL: repo not found: $REPO" >&2; exit 1; }

rc=0

echo "# Scheduled routines — $(date -u '+%Y-%m-%d %H:%M:%SZ')"
echo

# --- Routine 1: doc-freshness sweep (hard gate) ---
echo "## Doc-freshness sweep"
echo
echo '```'
if bash plugins/core/scripts/check-freshness.sh 2>&1; then
  echo '```'
  echo
  echo "**Result: OK** — generated docs current."
else
  rc=1
  echo '```'
  echo
  echo "**Result: DRIFT (gate failed)** — a source under \`plugins/core/\` changed without"
  echo "regenerating \`CATALOG.md\`, or a \`last-verified:\` doc is stale. Fix: re-run"
  echo "\`plugins/core/scripts/gen-catalog.sh\`, commit, in an approved session."
fi
echo

# --- Routine 2: sync / unmerged + stray-branch reconcile (informational) ---
# Under ADR 0016/0017 `main` is the only long-lived branch on any surface, so EVERY other remote
# branch is session residue. Surface both kinds: unmerged (review before retiring) and merged
# (orphaned session litter, safe to delete). Read-only — never merges or deletes.
echo "## Sync / unmerged check"
echo
# Best-effort: ensure we can see all remote branches (CI may have fetched only one ref).
git fetch --quiet origin '+refs/heads/*:refs/remotes/origin/*' 2>/dev/null || true
base="origin/main"
if ! git rev-parse --verify --quiet "$base" >/dev/null; then base="main"; fi
strays="$(git for-each-ref --format='%(refname:short)' refs/remotes/origin \
  | grep -vE "^origin/(HEAD|main)$" || true)"
if [ -z "$strays" ]; then
  echo "No remote branches besides \`main\`. ✅"
else
  unmerged_rows=""; merged_rows=""
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    counts="$(git rev-list --left-right --count "$base...$b" 2>/dev/null)" || continue
    behind="$(printf '%s' "$counts" | awk '{print $1}')"
    ahead="$(printf '%s' "$counts" | awk '{print $2}')"
    when="$(git log -1 --format='%cr' "$b" 2>/dev/null)"
    if [ "${ahead:-0}" = "0" ]; then
      merged_rows="${merged_rows}| \`$b\` | $behind | $when |"$'\n'
    else
      unmerged_rows="${unmerged_rows}| \`$b\` | $ahead | $behind | $when |"$'\n'
    fi
  done <<< "$strays"
  if [ -n "$unmerged_rows" ]; then
    echo "### Unmerged work — review before retiring"
    echo "| Branch | Ahead of main | Behind main | Last commit |"
    echo "|---|---|---|---|"
    printf '%s' "$unmerged_rows"
    echo
  fi
  if [ -n "$merged_rows" ]; then
    echo "### Merged residue — orphaned session branches, safe to retire"
    echo "| Branch | Behind main | Last commit |"
    echo "|---|---|---|"
    printf '%s' "$merged_rows"
    echo
  fi
  echo "_Every branch above is session residue (ADR 0016/0017: \`main\` is the only live branch)."
  echo "Merged ones are safe to delete; unmerged ones need a review pass first. Retire via"
  echo "\`git push origin --delete <branch>\` on the Mac (the cloud env's git proxy 403s pushes), or"
  echo "\`/clean-gone\` in an approved session — this routine never merges or deletes._"
fi
echo

# --- Routine 3: memory freshness sweep (informational) ---
echo "## Memory freshness sweep"
echo
echo '```'
bash plugins/core/scripts/check-stale-facts.sh memory 2>&1 || true
echo '```'
echo
echo "_Read-only: flags facts crossing 7/30/90-day \`updated:\` thresholds. Refresh via supersede"
echo "in an approved session — this routine never edits._"
echo

# --- Routine 4: learning-loop eval (informational) ---
echo "## Learning-loop eval"
echo
echo '```'
bash plugins/core/scripts/learning-eval.sh 2>&1 || true
echo '```'
echo
echo "_Read-only: flags corrections that recurred after promotion (the rule may not have stuck) —"
echo "the signal for revisiting a promoted rule. This routine never edits._"
echo

exit "$rc"
