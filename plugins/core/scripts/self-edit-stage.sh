#!/usr/bin/env bash
# self-edit-stage.sh — Stage a judgment-bearing self-edit onto a review branch.
#
# Usage: self-edit-stage.sh <slug> <rationale>
#
# Stages the current working-tree changes (an already-made proposed edit) onto a
# review branch self-edit/<date>-<slug>, commits them with the rationale, then
# restores the original branch with a clean working tree.  The PR step degrades
# gracefully when there is no remote or no `gh` CLI.
#
# Env overrides (for testability):
#   SELF_EDIT_DATE    default: date -u +%F
#   SELF_EDIT_BASE    default: main
#   SELF_EDIT_REMOTE  default: origin
#
# Exit codes:
#   0  success (branch created, change committed, original branch restored)
#   2  usage error (missing slug) or nothing to stage
set -uo pipefail

SLUG="${1:-}"
RATIONALE="${2:-}"
DATE="${SELF_EDIT_DATE:-$(date -u +%F)}"
REMOTE="${SELF_EDIT_REMOTE:-origin}"

# ── guards ────────────────────────────────────────────────────────────────────
if [ -z "$SLUG" ]; then
  echo "self-edit-stage: error: slug is required" >&2
  echo "Usage: self-edit-stage.sh <slug> <rationale>" >&2
  exit 2
fi

# Slug must be a safe single ref component: letters, digits, dot, underscore, hyphen.
# This rejects whitespace (incl. whitespace-only), slashes, and shell/ref metacharacters
# BEFORE any branch is created — without it, a `git checkout -b` failure under
# `set +e` would fall through and commit the self-edit onto the CURRENT branch (main),
# defeating the gate.
case "$SLUG" in
  *[!a-zA-Z0-9._-]*)
    echo "self-edit-stage: error: slug '$SLUG' has invalid characters (allowed: a-z A-Z 0-9 . _ -)" >&2
    exit 2
    ;;
esac

if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  echo "self-edit-stage: error: working tree is clean — nothing to stage" >&2
  exit 2
fi

# ── record original branch ────────────────────────────────────────────────────
orig="$(git rev-parse --abbrev-ref HEAD)"
branch="self-edit/${DATE}-${SLUG}"

# ensure original branch is restored even if something errors mid-flight
restore_orig() {
  git checkout -q "$orig" 2>/dev/null || \
    echo "self-edit-stage: WARNING: could not restore original branch '$orig'" >&2
}
trap restore_orig EXIT

# ── create branch, carry working-tree changes, commit ─────────────────────────
# Defense-in-depth: if branch creation fails for any reason, abort BEFORE add/commit
# so the staged change can never land on the current branch (the slug guard above is
# the primary protection; this is the backstop).
git checkout -q -b "$branch" || {
  echo "self-edit-stage: error: could not create branch '$branch'" >&2
  exit 2
}
git add -A
git commit -q -m "self-edit: $SLUG" -m "$RATIONALE"

# ── PR step (graceful degradation) ────────────────────────────────────────────
# Check whether the remote actually exists (git remote get-url exits non-zero if not)
if git remote get-url "$REMOTE" >/dev/null 2>&1; then
  if command -v gh >/dev/null 2>&1; then
    # push + open PR via gh CLI
    git push -q -u "$REMOTE" "$branch" 2>/dev/null && \
      gh pr create \
        --title "self-edit: $SLUG" \
        --body "$RATIONALE" \
        --base "${SELF_EDIT_BASE:-main}" 2>/dev/null || \
      echo "self-edit-stage: push/PR step failed; commit is on branch $branch" >&2
  else
    # push + print compare URL for manual PR creation
    if git push -q -u "$REMOTE" "$branch" 2>/dev/null; then
      remote_url="$(git remote get-url "$REMOTE" | sed 's/\.git$//')"
      echo "Branch pushed. Open PR: ${remote_url}/compare/${branch}?expand=1"
      echo "(No gh CLI in this environment — open the PR via the GitHub MCP or browser.)"
    else
      echo "self-edit-stage: push failed; commit is still on branch $branch (safe)" >&2
    fi
  fi
else
  echo "local-only (no remote '$REMOTE'); PR step skipped — commit is on branch $branch"
fi

# ── restore original branch ───────────────────────────────────────────────────
# trap will fire on EXIT; call explicitly so any error is visible before exit
trap - EXIT
restore_orig

exit 0
