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

# --- Routine 2: sync / unmerged check (informational) ---
echo "## Sync / unmerged check"
echo
# Best-effort: ensure we can see all remote branches (CI may have fetched only one ref).
git fetch --quiet origin '+refs/heads/*:refs/remotes/origin/*' 2>/dev/null || true
base="origin/main"
if ! git rev-parse --verify --quiet "$base" >/dev/null; then base="main"; fi
unmerged="$(git for-each-ref --format='%(refname:short)' refs/remotes/origin \
  | grep -vE "^origin/(HEAD|main)$" || true)"
if [ -z "$unmerged" ]; then
  echo "No remote branches besides \`main\`."
else
  found=0
  echo "| Branch | Ahead of main | Behind main | Last commit |"
  echo "|---|---|---|---|"
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    counts="$(git rev-list --left-right --count "$base...$b" 2>/dev/null)" || continue
    behind="$(printf '%s' "$counts" | awk '{print $1}')"
    ahead="$(printf '%s' "$counts" | awk '{print $2}')"
    [ "${ahead:-0}" = "0" ] && continue   # fully merged → not outstanding
    when="$(git log -1 --format='%cr' "$b" 2>/dev/null)"
    echo "| \`$b\` | $ahead | $behind | $when |"
    found=1
  done <<< "$unmerged"
  if [ "$found" = "0" ]; then
    echo "All remote branches are merged into \`main\`."
  else
    echo
    echo "_Unmerged work above. Merge via \`merge-with-discretion\` or retire via \`/clean-gone\`"
    echo "in an approved session — this routine never merges or deletes._"
  fi
fi
echo

exit "$rc"
