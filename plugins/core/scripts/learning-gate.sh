#!/usr/bin/env bash
# learning-gate.sh — deterministic eval/promote gate for a proposed self-edit (agentic-OS Phase 4b).
#
# The learning loop OPENS a self-edit PR; this gate decides whether it is safe to AUTO-LAND or must
# wait for a human. It is deliberately CONSERVATIVE — it APPROVES only changes that are clearly clean,
# and HOLDS on anything uncertain. "A learning loop without the eval gate learns confident junk"
# (decision doc §7.8); the failure mode here is "holds too much" (safe), never "merges junk".
#
# A self-edit is APPROVED only when ALL hold:
#   1. SCOPE     — touches only plugins/core/rules/ and memory/ (no code, CI, secrets, connectors).
#   2. SIZE      — total added lines <= LEARNING_GATE_MAX_ADDED (default 40); big rewrites need eyes.
#   3. PROVENANCE— every changed .md bumps its `updated:` (supersede-not-append hygiene).
#   4. NO DUP    — no added content line is already present in the file's base version (re-adding a
#                  rule that already exists — the #19/#21 duplicate mode).
# Cross-PR dedupe (is another OPEN self-edit PR proposing the same file?) is the workflow's job
# (self-edit-gate.yml), since it needs the GitHub API.
#
# Usage: learning-gate.sh [base]      (default: origin/main)
# Read-only. Exit 0 = APPROVE, 1 = HOLD (reasons on stdout). Portable (bash 3.2 indexed arrays).
set -uo pipefail
BASE="${1:-origin/main}"
MAX_ADDED="${LEARNING_GATE_MAX_ADDED:-40}"

reasons=()

files="$(git diff --name-only "$BASE"...HEAD 2>/dev/null || true)"
if [ -z "$files" ]; then
  echo "HOLD: no changes vs $BASE (nothing to evaluate)."
  exit 1
fi

# 1. SCOPE
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    plugins/core/rules/*|memory/*) : ;;
    *) reasons+=("out-of-scope file: $f (only plugins/core/rules/ and memory/ may auto-land)") ;;
  esac
done <<< "$files"

# 2. SIZE
added="$(git diff --numstat "$BASE"...HEAD 2>/dev/null | awk '{a+=$1} END{print a+0}')"
if [ "${added:-0}" -gt "$MAX_ADDED" ]; then
  reasons+=("change too large (${added} added lines > ${MAX_ADDED}) — review by hand")
fi

# 3. PROVENANCE (each changed .md bumps updated:)
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in *.md) : ;; *) continue ;; esac
  if ! git diff "$BASE"...HEAD -- "$f" 2>/dev/null | grep -qE '^\+[[:space:]]*updated:'; then
    reasons+=("$f changed without bumping 'updated:' (stale provenance)")
  fi
done <<< "$files"

# 4. NO DUP (added content not already in the base file)
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in *.md) : ;; *) continue ;; esac
  base_lc="$(git show "$BASE:$f" 2>/dev/null | tr 'A-Z' 'a-z' || true)"
  [ -n "$base_lc" ] || continue
  while IFS= read -r line; do
    add="${line:1}"  # strip leading '+'
    norm="$(printf '%s' "$add" | sed -E 's/^[[:space:]*-]+//; s/[[:space:]]+$//' | tr 'A-Z' 'a-z')"
    [ "${#norm}" -ge 25 ] || continue                         # skip short/structural lines
    case "$norm" in updated:*|scope:*|name:*|source:*|supersedes:*|metadata:*) continue ;; esac
    if printf '%s' "$base_lc" | grep -qF "$norm"; then
      reasons+=("duplicate content in $f: \"$(printf '%s' "$add" | sed -E 's/^[[:space:]*-]+//' | cut -c1-48)…\" already present")
    fi
  done < <(git diff "$BASE"...HEAD -- "$f" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+')
done <<< "$files"

if [ "${#reasons[@]}" -eq 0 ]; then
  echo "APPROVE: in-scope, small (${added} added lines), provenance bumped, non-duplicate."
  exit 0
fi
echo "HOLD — self-edit needs human review:"
for r in "${reasons[@]}"; do echo "  - $r"; done
exit 1
