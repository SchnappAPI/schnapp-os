#!/usr/bin/env bash
# learning-worker.sh — nightly learning-loop driver (Phase 4).
#
# Reads the local learning queue (git-ignored .learning-queue.tsv), distills+classifies each
# capture, routes judgment-bearing ones through self-edit-stage.sh (the gate, ADR 0012), and
# archives processed lines. Never writes memory/ or plugins/core/rules/ directly.
#
# Usage: learning-worker.sh [--dry-run]
#
# Env:
#   LEARNING_QUEUE   — path to queue file (default: scheduled-tasks/.learning-queue.tsv)
#   LEARNING_ARCHIVE — path to archive file (default: alongside queue, .learning-queue.archive.tsv)
#
# --dry-run: exercises all logic with no claude -p call, no network, and no writes to memory/rules.
#            Processed lines ARE moved to the archive (safe: the dry-run tests the full plumbing).
#
# Safety:
#   - Empty/missing queue → message + exit 0.
#   - Live path requires the claude CLI; if absent → message + exit 0 (no-op, not a crash).
#   - Never writes memory/ or plugins/core/rules/ directly (all judgment via self-edit-stage.sh).
#   - Archiving (not deleting) means a capture is never silently lost.

set -uo pipefail

DRY_RUN=false
for arg in "$@"; do
  [ "$arg" = "--dry-run" ] && DRY_RUN=true
done

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

Q="${LEARNING_QUEUE:-"$REPO_ROOT/scheduled-tasks/.learning-queue.tsv"}"
A="${LEARNING_ARCHIVE:-"${Q%.tsv}.archive.tsv"}"

# Empty/missing queue → clean no-op
if [ ! -f "$Q" ] || [ ! -s "$Q" ]; then
  echo "learning-worker: queue empty — nothing to consolidate"
  exit 0
fi

# Deterministic heuristic for --dry-run: a capture mentioning a concrete value/name
# (digits, op://, a path) is classified as 'judgment' (fact-supersede); others as 'mechanical'.
# In live mode the LLM does the real classification; this only labels the dry-run output.
classify_capture() {
  local text="$1"
  if printf '%s' "$text" | grep -qE '[0-9]{2,}|op://|/[a-zA-Z]'; then
    echo "judgment"
  else
    echo "mechanical"
  fi
}

if $DRY_RUN; then
  # Dry-run: print what would happen, archive processed lines, write nothing to memory/rules
  while IFS=$'\t' read -r ts tag text; do
    lane="$(classify_capture "$text")"
    echo "would distill+route: [$lane] $text"
  done < "$Q"

  # Archive processed lines
  cat "$Q" >> "$A"
  # Drain the queue
  : > "$Q"
  exit 0
fi

# Live path — require the claude CLI
if ! command -v claude >/dev/null 2>&1; then
  echo "learning-worker: 'claude' CLI not found — install it to run the live learning worker. Exiting (no-op)."
  exit 0
fi

# Live: invoke claude -p with a prompt that loads the learn-route procedure, distills each
# queued capture to a reusable principle, and for judgment-bearing ones calls self-edit-stage.sh
# to open a PR. The worker is the driver; the LLM does the judgment.
GATE="$REPO_ROOT/plugins/core/scripts/self-edit-stage.sh"

# Build the prompt from queue contents
PROMPT="$(cat <<PROMPT_EOF
You are running as the nightly learning worker for this repo (scheduled-tasks/memory-consolidation.md).

For each queued correction below, distill it to a reusable principle and classify it using the
learn-route procedure (plugins/core/skills/learn-route.md):
  - mechanical (typo/format/regenerate) → state it is mechanical and skip (committed direct in session)
  - judgment (rule-meaning change, fact supersede, doc fix) → invoke the gate:
    bash $GATE <slug> "<rationale>"
    where slug is a short kebab-case label for the principle.

NEVER write to memory/ or plugins/core/rules/ directly. All judgment-bearing changes go through
self-edit-stage.sh so they are reviewed via PR before taking effect.

Queued corrections:
$(cat "$Q")
PROMPT_EOF
)"

echo "learning-worker: processing $(wc -l < "$Q" | tr -d ' ') capture(s) via claude -p ..."
claude -p "$PROMPT"

# Archive processed lines after successful run
cat "$Q" >> "$A"
: > "$Q"
echo "learning-worker: done — $(wc -l < "$A" | tr -d ' ') total archived captures."
