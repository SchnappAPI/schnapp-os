#!/usr/bin/env bash
# run-ci-routines.sh - the SAFE, Mac-independent scheduled routines, as one bundle.
#
# Single source of truth for the safe, auto-class routines: seven read-only
# passes - the doc-freshness sweep (hard gate), the sync/unmerged check, a memory-freshness
# sweep (check-stale-facts.sh), the learning-loop eval (learning-eval.sh), the open
# owner-items surfacing (check-open-questions.sh), the credential-horizons check
# (check-credential-horizons.sh, hard on an actual within-horizon WARN), and the CORE-paste
# currency check (check-core-paste.sh, informational). The cron workflow
# (.github/workflows/scheduled-routines.yml) calls this; nothing here is duplicated in YAML.
# Read-only except for the freshness generator's temp file. Exit non-zero ONLY when a hard gate
# (freshness, or a credential inside its warn window) fails, so a real problem is a visible
# failure and informational drift is not.
#
# Output is markdown on stdout (the workflow appends it to the job Step Summary). Config:
# CLAUDE_KIT_REPO (default: derived from this script's location, so it runs anywhere).
set -uo pipefail
export LC_ALL=C

REPO="${CLAUDE_KIT_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$REPO" || { echo "FATAL: repo not found: $REPO" >&2; exit 1; }

rc=0

echo "# Scheduled routines - $(date -u '+%Y-%m-%d %H:%M:%SZ')"
echo

# --- Routine 1: doc-freshness sweep (hard gate) ---
echo "## Doc-freshness sweep"
echo
echo '```'
if bash scripts/check-freshness.sh 2>&1; then
  echo '```'
  echo
  echo "**Result: OK** - generated docs current."
else
  rc=1
  echo '```'
  echo
  echo "**Result: DRIFT (gate failed)** - a component/source file changed without"
  echo "regenerating \`CATALOG.md\`, or a \`last-verified:\` doc is stale. Fix: re-run"
  echo "\`scripts/gen-catalog.sh\`, commit, in an approved session."
fi
echo

# --- Routine 2: sync / unmerged + stray-branch reconcile (informational) ---
# Under ADR 0016/0017 `main` is the only long-lived branch on any surface, so EVERY other remote
# branch is session residue. Surface both kinds: unmerged (review before retiring) and merged
# (orphaned session litter, safe to delete). Read-only - never merges or deletes.
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
    echo "### Unmerged work - review before retiring"
    echo "| Branch | Ahead of main | Behind main | Last commit |"
    echo "|---|---|---|---|"
    printf '%s' "$unmerged_rows"
    echo
  fi
  if [ -n "$merged_rows" ]; then
    echo "### Merged residue - orphaned session branches, safe to retire"
    echo "| Branch | Behind main | Last commit |"
    echo "|---|---|---|"
    printf '%s' "$merged_rows"
    echo
  fi
  echo "_Every branch above is session residue (ADR 0016/0017: \`main\` is the only live branch)."
  echo "Merged ones are safe to delete; unmerged ones need a review pass first. Retire via"
  echo "\`git push origin --delete <branch>\` on the Mac (the cloud env's git proxy 403s pushes), or"
  echo "\`/clean-gone\` in an approved session - this routine never merges or deletes._"
fi
echo

# --- Routine 3: memory freshness sweep (informational) ---
echo "## Memory freshness sweep"
echo
# VAULT_MEMORY_DIR: the workflow points this at a vault checkout (vault/memory) when the
# VAULT_READ_TOKEN secret is configured. A missing dir means the vault leg never ran - a LOUD
# warning, never a silent skip (the sin is silence, not absence: the token being unset may be
# an owner choice, so this stays informational, not a hard failure). Step Summary is the right
# channel: this bundle is deliberately dependency-free and opens no issues (the probe workflows
# own the issue mechanism); its only channels are the Step Summary and the exit code.
vault_dir="${VAULT_MEMORY_DIR:-memory}"
if [ ! -d "$vault_dir" ]; then
  echo "### ⚠️ WARNING: vault memory lane NOT swept"
  echo
  echo "No vault checkout at \`$vault_dir\`, so the stale-facts sweep is BLIND to the memory"
  echo "lane. On CI this means the \`VAULT_READ_TOKEN\` Actions secret is unset, expired, or"
  echo "lost its vault repo grant (locally: point VAULT_MEMORY_DIR at the vault clone's"
  echo "memory dir). If intentional, no action; otherwise restore the secret with:"
  echo '```'
  echo "gh secret set VAULT_READ_TOKEN --repo SchnappAPI/schnapp-os  # value: op://web-variables/SCHNAPP_OS_PAT/credential"
  echo '```'
  echo
fi
echo '```'
bash scripts/check-stale-facts.sh "$vault_dir" 2>&1 || true
echo '```'
echo
echo "_Read-only: flags facts crossing 7/30/90-day \`updated:\` thresholds. Refresh via supersede"
echo "in an approved session - this routine never edits._"
echo

# --- Routine 4: learning-loop eval (informational) ---
echo "## Learning-loop eval"
echo
echo '```'
bash scripts/learning-eval.sh 2>&1 || true
echo '```'
echo
echo "_Read-only: flags corrections that recurred after promotion (the rule may not have stuck) - "
echo "the signal for revisiting a promoted rule. This routine never edits._"
echo

# --- Routine 5: open owner items in the live handoff (informational) ---
echo "## Open owner items (live handoff)"
echo
echo '```'
bash scripts/check-open-questions.sh handoffs 2>&1 || true
echo '```'
echo
echo "_Read-only: re-surfaces the resume-point handoff's \"## Open ...\" items nightly so they"
echo "cannot rot silently. Resolve or re-carry them in the next handoff - this routine never edits._"
echo

# --- Routine 6: credential horizons (hard on an actual within-horizon WARN) ---
# Hard like the freshness gate, not informational like routines 2-5: a green nightly's Step
# Summary is never read, and this bundle's only push channel is the red workflow (GitHub emails
# the owner). The script exits 1 ONLY on a real within-horizon row or a blind/malformed data
# file, so a red here is always actionable.
echo "## Credential horizons"
echo
echo '```'
if ! bash scripts/check-credential-horizons.sh 2>&1; then
  rc=1
  horizons_failed=1
fi
echo '```'
echo
if [ "${horizons_failed:-0}" -eq 1 ]; then
  echo "**Result: WARN (gate failed)** - a credential is inside its warn window (or the data"
  echo "file is broken). Rotate/re-mint per the row's note (\`rotate-secret\` skill), then move"
  echo "its expiry date in \`scripts/credential-horizons.tsv\`."
else
  echo "**Result: OK** - no credential inside its warn window."
fi
echo

# --- Routine 7: claude.ai CORE paste currency (informational) ---
echo "## CORE paste currency (claude.ai Preferences)"
echo
echo '```'
bash scripts/check-core-paste.sh 2>&1 || true
echo '```'
echo
echo "_Read-only: compares surfaces/core-paste-watermark to the last commit touching"
echo "surfaces/always-loaded-instructions.md. Soft by design: the re-paste is a manual owner"
echo "step, so it warns nightly until the watermark moves - it never reds the run._"
echo

exit "$rc"
