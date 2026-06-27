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

# Archive processed captures, THEN drain — but NEVER drain if the archive write failed
# (e.g. LEARNING_ARCHIVE points at a missing/unwritable dir), or captures would be lost.
archive_and_drain() {
  if ! cat "$Q" >> "$A" 2>/dev/null; then
    echo "learning-worker: ERROR — could not write archive '$A'; queue NOT drained (no captures lost)." >&2
    exit 1
  fi
  : > "$Q"
}

if $DRY_RUN; then
  # Dry-run: print what would happen, archive processed lines, write nothing to memory/rules
  while IFS=$'\t' read -r ts tag text; do
    lane="$(classify_capture "$text")"
    echo "would distill+route: [$lane] $text"
  done < "$Q"

  archive_and_drain
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
learn-route procedure (plugins/core/skills/learn-route/SKILL.md):
  - mechanical (typo/format/regenerate) → state it is mechanical and skip (committed direct in session)
  - judgment (rule-meaning change, fact supersede, doc fix) → WRITE the proposed edit to the working
    tree first, then invoke the gate to stage it on a review branch + PR:
    bash $GATE <slug> "<rationale>"
    where slug is a short kebab-case label for the principle.

NEVER commit to memory/ or plugins/core/rules/ directly (no direct-to-main for judgment changes).
Writing the proposed edit to the working tree and then running self-edit-stage.sh IS the path —
it commits the edit onto a review branch and opens a PR, leaving main untouched until review.

Queued corrections:
$(cat "$Q")
PROMPT_EOF
)"

# Run from the repo root so the headless session loads CLAUDE.md / .claude/settings.json and can
# resolve relative paths (the learn-route skill, the gate). The LaunchAgent's cwd is / otherwise.
cd "$REPO_ROOT" || { echo "learning-worker: ERROR — cannot cd to repo root '$REPO_ROOT'." >&2; exit 1; }

echo "learning-worker: processing $(wc -l < "$Q" | tr -d ' ') capture(s) via claude -p ..."
# Pass the prompt on STDIN, not as a positional arg: --allowedTools accepts a list and otherwise
# swallows the trailing prompt argument, leaving claude with no input ("Input must be provided
# ... when using --print"). Tools are bounded as defense-in-depth behind the gate.
if ! printf '%s' "$PROMPT" | claude -p --allowedTools "Read,Edit,Write,Bash"; then
  echo "learning-worker: ERROR — claude run failed; queue NOT drained (captures preserved for next run)." >&2
  exit 1
fi

# Archive + drain ONLY after a successful run (a failed run above already exited without draining).
archive_and_drain
echo "learning-worker: done — $(wc -l < "$A" | tr -d ' ') total archived captures."
