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

# Headless auth: `claude setup-token` writes to the login Keychain, which a launchd job cannot
# read (it 401s). Inject the credential from 1Password at runtime instead — the LaunchAgent
# inherits OP_SERVICE_ACCOUNT_TOKEN, so `op read` resolves here. LEARNING_CLAUDE_TOKEN_REF is an
# op:// REFERENCE (safe to commit/set; the value is never stored on disk). The referenced item may
# hold EITHER an Anthropic API key (sk-ant-api…) or a Claude OAuth token (sk-ant-oat…); we export it
# under the matching env var so the ref can point at whichever credential actually authenticates.
# No-op if a credential is already in the env (e.g. an interactive test) or no ref is configured.
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && [ -n "${LEARNING_CLAUDE_TOKEN_REF:-}" ]; then
  # Observability: a headless job must NOT swallow its auth failure silently (that turns a
  # credential problem into a mystery). Log the resolution outcome — length + which env var —
  # but NEVER the value. The launchd op identity (the inherited service account) differs from an
  # interactive shell's personal login, so this is the only place we see what it gets.
  echo "learning-worker: auth — op:$(command -v op || echo MISSING) OP_SA:${OP_SERVICE_ACCOUNT_TOKEN:+set}${OP_SERVICE_ACCOUNT_TOKEN:-UNSET} ref:${LEARNING_CLAUDE_TOKEN_REF}"
  if command -v op >/dev/null 2>&1; then
    if _tok="$(op read "$LEARNING_CLAUDE_TOKEN_REF" 2>&1)"; then
      case "$_tok" in
        sk-ant-api*) export ANTHROPIC_API_KEY="$_tok";       _kind=ANTHROPIC_API_KEY ;;
        *)           export CLAUDE_CODE_OAUTH_TOKEN="$_tok"; _kind=CLAUDE_CODE_OAUTH_TOKEN ;;
      esac
      echo "learning-worker: auth — resolved credential via op (${#_tok} chars) -> $_kind."
      unset _kind
    else
      echo "learning-worker: auth — ERROR: op read failed: $_tok" >&2
    fi
    unset _tok
  else
    echo "learning-worker: auth — ERROR: op not on PATH; cannot resolve headless token." >&2
  fi
fi

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
