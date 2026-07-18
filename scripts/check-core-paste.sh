#!/usr/bin/env bash
# check-core-paste.sh - claude.ai Preferences CORE currency check (campaign Phase 5 monitor).
#
# Drift caught: surfaces/always-loaded-instructions.md changes but the pasted CORE box in
# claude.ai Preferences (which has NO auto-sync) is never re-pasted, so claude.ai/iPhone run on
# stale rules. Alert path: WARN line -> run-ci-routines.sh Step Summary (soft leg: the re-paste
# is a manual owner step, so it must not hold the nightly red; the WARN repeats every night
# until the watermark moves). Own failure mode: it cannot false-green silently - a missing or
# dateless watermark file, or a git failure, is itself a WARN + exit 1, never a quiet OK.
# Verify: bash scripts/check-core-paste.sh (expect "CORE paste current", exit 0).
#
# A standalone script (not inline in run-ci-routines.sh) so it runs identically on the Mac,
# in CI, and under test, like every other check-*.sh leg.
#
# Usage: check-core-paste.sh [repo] - repo root (default: this script's parent).
# Exit 0 = paste current; exit 1 = WARN (source newer than watermark, or check blind).
set -uo pipefail
export LC_ALL=C

REPO="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SOURCE="surfaces/always-loaded-instructions.md"
WATERMARK="$REPO/surfaces/core-paste-watermark"

if [ ! -r "$WATERMARK" ]; then
  echo "WARN: watermark file missing: $WATERMARK (CORE currency check is blind)"
  exit 1
fi
paste_date="$(grep -Ev '^[[:space:]]*(#|$)' "$WATERMARK" | head -1 | tr -d '[:space:]')"
if ! printf '%s' "$paste_date" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
  echo "WARN: no ISO date line in $WATERMARK (CORE currency check is blind)"
  exit 1
fi

source_date="$(git -C "$REPO" log -1 --format='%cs' -- "$SOURCE" 2>/dev/null)"
if [ -z "$source_date" ]; then
  echo "WARN: cannot read the last commit date for $SOURCE (shallow checkout or not a git repo?)"
  exit 1
fi

# ISO dates compare correctly as strings; strictly newer source = stale paste.
if [ "$source_date" \> "$paste_date" ]; then
  echo "WARN: CORE paste stale - $SOURCE last changed $source_date but the watermark says the"
  echo "Preferences box was last pasted $paste_date. Re-paste the CORE block into claude.ai"
  echo "Settings > Profile > Preferences, then update surfaces/core-paste-watermark."
  exit 1
fi
echo "CORE paste current (source last changed $source_date, pasted $paste_date)"
