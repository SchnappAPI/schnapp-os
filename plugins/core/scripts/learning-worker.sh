#!/usr/bin/env bash
# learning-worker.sh — nightly learning-loop driver (Phase 4, pre-commit gate, ADR 0016).
#
# Reads the local learning queue (git-ignored .learning-queue.tsv), has a headless Agent SDK run
# distill+classify each capture and WRITE any proposed rule/fact edit to the working tree (no branch,
# no commit, no PR), then the WORKER gates the working-tree diff (learning-gate.sh): a clean proposal
# is committed straight to main; anything the gate holds is filed as a GitHub issue. No branches —
# everything that lands goes to main (owner pref 2026-06-27; ADR 0016 refines 0012/0013/0015).
#
# Usage: learning-worker.sh [--dry-run]
# Env:
#   LEARNING_QUEUE   — queue file (default: scheduled-tasks/.learning-queue.tsv)
#   LEARNING_ARCHIVE — archive file (default: alongside queue, .learning-queue.archive.tsv)
#   LEARNING_CLAUDE_TOKEN_REF — op:// ref to the Claude credential (headless auth; see docs/headless-claude-auth.md)
#
# --dry-run: exercises queue/classify/archive plumbing with NO distill call, NO git, NO network.
#
# Safety:
#   - Empty/missing queue → message + exit 0.  Live path needs the `claude` CLI; absent → no-op exit 0.
#   - Distillation runs via the Agent SDK (learning_distill.py): file-edit tools only
#     (Read/Edit/Write/Grep/Glob, NO Bash/git/network), bounded turns + timeout + retry-once. The
#     prompt scopes edits to rules/memory; the worker gates+commits the diff (not a hard sandbox).
#   - Default flow: the worker gates the resulting diff (learning-gate.sh) and pushes only APPROVED
#     changes to main; held proposals never touch main (→ issue).
#   - Archiving (not deleting) means a capture is never silently lost.
set -uo pipefail

DRY_RUN=false
for arg in "$@"; do [ "$arg" = "--dry-run" ] && DRY_RUN=true; done

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
Q="${LEARNING_QUEUE:-"$REPO_ROOT/scheduled-tasks/.learning-queue.tsv"}"
A="${LEARNING_ARCHIVE:-"${Q%.tsv}.archive.tsv"}"

# Best-effort native alerting (incident-managed via ops-alert.sh: opens/auto-closes a GitHub issue +
# ntfy). Detection stays in this caller; the alert layer must NEVER break the worker, hence `|| true`.
# No-op under --dry-run. Closes the silent-swallow gap: a failed claude run used to exit non-zero with
# no signal off the Mac.
alert() { $DRY_RUN && return 0; "$REPO_ROOT/plugins/core/scripts/ops-alert.sh" "$@" >/dev/null 2>&1 || true; }

if [ ! -f "$Q" ] || [ ! -s "$Q" ]; then
  echo "learning-worker: queue empty — nothing to consolidate"
  alert green learning-worker "Learning worker healthy" "queue empty — nothing to consolidate"
  exit 0
fi

# Deterministic label for --dry-run only (the live LLM does the real classification).
classify_capture() {
  if printf '%s' "$1" | grep -qE '[0-9]{2,}|op://|/[a-zA-Z]'; then echo "judgment"; else echo "mechanical"; fi
}

# Archive processed captures, THEN drain — never drain if the archive write failed (no captures lost).
archive_and_drain() {
  if ! cat "$Q" >> "$A" 2>/dev/null; then
    echo "learning-worker: ERROR — could not write archive '$A'; queue NOT drained (no captures lost)." >&2
    exit 1
  fi
  : > "$Q"
}

if $DRY_RUN; then
  while IFS=$'\t' read -r _ _ text; do
    echo "would distill+route: [$(classify_capture "$text")] $text"
  done < "$Q"
  archive_and_drain
  exit 0
fi

# Live path — require the claude CLI
if ! command -v claude >/dev/null 2>&1; then
  echo "learning-worker: 'claude' CLI not found — install it to run the live learning worker. Exiting (no-op)."
  exit 0
fi

# Run from repo root so the headless session loads CLAUDE.md / .claude/settings.json + relative paths.
cd "$REPO_ROOT" || { echo "learning-worker: ERROR — cannot cd to repo root '$REPO_ROOT'." >&2; exit 1; }

# Headless auth: launchd can't read the login Keychain, so inject the credential from 1Password at
# runtime (the LaunchAgent inherits OP_SERVICE_ACCOUNT_TOKEN). LEARNING_CLAUDE_TOKEN_REF is an op://
# REFERENCE; the item may hold an Anthropic API key (sk-ant-api…) or a Claude OAuth token (sk-ant-oat…)
# — export under the matching env var. No-op if a credential is already set or no ref is configured.
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && [ -n "${LEARNING_CLAUDE_TOKEN_REF:-}" ]; then
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
    echo "learning-worker: auth — ERROR: op not on PATH; cannot resolve headless credential." >&2
  fi
fi

# Pre-commit gate flow (ADR 0016, no branches): start from a clean main synced to origin so the only
# diff after the run is the worker's proposal.
git fetch -q origin main 2>/dev/null || true
if [ -n "$(git status --porcelain)" ]; then
  echo "learning-worker: working tree not clean — aborting (queue preserved)." >&2
  alert red learning-worker "Learning worker blocked" "working tree not clean — aborted; queue preserved"
  exit 1
fi
git checkout -q main 2>/dev/null || true
git reset -q --hard origin/main 2>/dev/null || true

echo "learning-worker: processing $(wc -l < "$Q" | tr -d ' ') capture(s) via Agent SDK (learning_distill.py) ..."
# Bounded, file-scoped Agent SDK distillation (no Bash/git/network). The worker gates+commits the diff.
export LEARNING_QUEUE="$Q"
DISTILL_PY="$REPO_ROOT/plugins/core/scripts/learning_distill.py"
DISTILL_PYTHON="${LEARNING_DISTILL_PYTHON:-$HOME/.venvs/learning-distill/bin/python}"
[ -x "$DISTILL_PYTHON" ] || DISTILL_PYTHON="$(command -v python3)"
if ! "$DISTILL_PYTHON" "$DISTILL_PY"; then
  git reset -q --hard origin/main 2>/dev/null || true
  echo "learning-worker: ERROR — Agent SDK distillation failed; queue NOT drained (captures preserved)." >&2
  alert red learning-worker "Learning worker failed" "Agent SDK distillation failed; queue preserved, will retry"
  exit 1
fi

if [ -z "$(git status --porcelain)" ]; then
  echo "learning-worker: no rule/fact change proposed (skipped / duplicate / mechanical)."
else
  git add -A
  git commit -q -m "self-edit: learning-loop promotion $(date -u +%F)"
  gate_out="$(mktemp)"
  if bash "$REPO_ROOT/plugins/core/scripts/learning-gate.sh" origin/main > "$gate_out" 2>&1; then
    if git push -q origin HEAD:main 2>/dev/null; then
      echo "learning-worker: PROMOTED a clean self-edit to main."
    else
      git reset -q --hard origin/main 2>/dev/null || true
      echo "learning-worker: push to main failed (remote moved?) — discarded; will recapture." >&2
    fi
  else
    patch="$(git show HEAD --patch --stat 2>/dev/null | head -c 8000)"
    reasons="$(cat "$gate_out")"
    git reset -q --hard origin/main 2>/dev/null || true
    # shellcheck disable=SC2016  # single-quoted printf format is intentional — printf expands %s/\n, not the shell
    issue_body="$(printf 'The nightly learning worker proposed a self-edit the eval gate HELD (no branch, nothing landed on main).\n\n## Gate reasons\n%s\n\n## Proposed change\n```diff\n%s\n```\n' "$reasons" "$patch")"
    if command -v gh >/dev/null 2>&1 && \
       gh issue create --title "learning-loop: self-edit held for review ($(date -u +%F))" \
         --body "$issue_body" \
         >/dev/null 2>&1; then
      echo "learning-worker: HELD self-edit — opened a review issue (nothing on main)."
    else
      echo "learning-worker: HELD self-edit (could not open issue) — $reasons" >&2
    fi
  fi
  rm -f "$gate_out"
fi

archive_and_drain
alert green learning-worker "Learning worker healthy" "run completed; $(wc -l < "$A" | tr -d ' ') total archived captures"
echo "learning-worker: done — $(wc -l < "$A" | tr -d ' ') total archived captures."
