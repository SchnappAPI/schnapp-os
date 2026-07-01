#!/usr/bin/env bash
# learning-gate.sh - deterministic eval/promote gate for a proposed self-edit (agentic-OS Phase 4b;
# pre-commit flow per ADR 0016; scoped per ADR 0028).
#
# The nightly worker leaves a proposed self-edit as a commit on the current branch; this gate decides
# whether it is safe to AUTO-LAND (push to main) or must wait for a human (review issue). Deliberately
# CONSERVATIVE - APPROVES only the clearly-clean, HOLDS on any doubt. "A learning loop without the
# eval gate learns confident junk" (decision doc 7.8); the failure mode here is "holds too much"
# (safe), never "merges junk".
#
# SCOPE is an argument (ADR 0028): the global memory lane lives in the VAULT repo, so in schnapp-os
# only rule .md may auto-land (default scope rules/*.md). The worker runs this same gate inside its
# vault clone with scope memory/*.md for the fact leg. A repo-local memory/ write in schnapp-os is
# out-of-scope and HOLDS.
#
# APPROVED only when ALL hold:
#   1. SCOPE - every changed file is a `.md` matching the scope glob list, and NOT a
#                   symlink (a symlink could alias an out-of-scope path such as a CI workflow).
#   2. SIZE - total added lines <= LEARNING_GATE_MAX_ADDED (default 40); no binary change
#                   (binary can't be size-checked); big rewrites need eyes.
#   3. PROVENANCE - every CHANGED existing in-scope .md whose base has a frontmatter `updated:` must
#                   bump its VALUE (compared via the shared parser, so a body line starting
#                   "updated:" can't spoof it, and nested `metadata:` frontmatter is handled);
#                   REMOVING the key HOLDS. A file whose base has no `updated:` at all (an index
#                   like the vault's MEMORY.md) is exempt.
#   4. NO DUP - no added content line is already present in the file's base version.
# Cross-run dedupe (an OPEN review issue proposing the same file) is the workflow's job.
#
# Usage: learning-gate.sh [base] [scope]
#   base  - diff base (default: origin/main)
#   scope - |-separated glob list a changed path must match (default: 'rules/*.md')
# Read-only. Exit 0 = APPROVE, 1 = HOLD (reasons on stdout). Portable (bash 3.2 indexed arrays).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091  # resolved at runtime relative to this script
. "$HERE/lib-frontmatter.sh"
BASE="${1:-origin/main}"
# No-colon default on purpose: an UNSET scope gets the default, but an explicitly EMPTY scope
# stays empty and matches nothing (fail closed) - a caller that computed '' must never be
# silently gated against the rules default.
SCOPE="${2-rules/*.md}"
MAX_ADDED="${LEARNING_GATE_MAX_ADDED:-40}"
DUP_MIN="${LEARNING_GATE_DUP_MIN:-40}"

# in_scope <path>: does the path match any |-separated glob in SCOPE? (bash 3.2 safe)
# Fail closed: an empty scope matches NOTHING (never everything, never a crash).
# NOTE: case-glob `*` crosses `/` (so 'rules/*.md' admits rules/global/x.md by design); a caller
# whose contract is depth-limited must enforce depth itself (the worker's fact leg does).
in_scope() {
  local p
  [ -n "$SCOPE" ] || return 1
  IFS='|' read -r -a _scope_pats <<< "$SCOPE"
  for p in "${_scope_pats[@]}"; do
    [ -n "$p" ] || continue
    # shellcheck disable=SC2254  # unquoted on purpose: $p is a glob pattern
    case "$1" in $p) return 0 ;; esac
  done
  return 1
}

reasons=()
files="$(git diff --name-only "$BASE"...HEAD 2>/dev/null || true)"
if [ -z "$files" ]; then echo "HOLD: no changes vs $BASE (nothing to evaluate)."; exit 1; fi

# 1. SCOPE - .md matching the scope list only; reject symlinks (git mode 120000), robust without checkout.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  mode="$(git ls-tree HEAD -- "$f" 2>/dev/null | awk '{print $1}')"
  if [ "$mode" = "120000" ]; then reasons+=("symlink not allowed: $f"); continue; fi
  in_scope "$f" || reasons+=("out-of-scope or non-.md file: $f (only .md matching '$SCOPE' may auto-land)")
done <<< "$files"

# 2. SIZE - binary (numstat '-') can't be sized → HOLD; else cap added lines.
if git diff --numstat "$BASE"...HEAD 2>/dev/null | grep -qE '^-[[:space:]]'; then
  reasons+=("binary file change - cannot size-check; review by hand")
fi
added="$(git diff --numstat "$BASE"...HEAD 2>/dev/null | awk '$1 ~ /^[0-9]+$/ {a+=$1} END{print a+0}')"
if [ "${added:-0}" -gt "$MAX_ADDED" ]; then
  reasons+=("change too large (${added} added lines > ${MAX_ADDED}) - review by hand")
fi

# 3. PROVENANCE - each CHANGED existing in-scope .md bumps its frontmatter updated: value
#    (parser-based). Base has no updated: at all (an index like MEMORY.md) -> exempt; removing
#    the key -> HOLD.
tmpA="$(mktemp)"; tmpB="$(mktemp)"; trap 'rm -f "$tmpA" "$tmpB"' EXIT
while IFS= read -r f; do
  [ -n "$f" ] || continue
  in_scope "$f" || continue
  git show "$BASE:$f" > "$tmpA" 2>/dev/null || : > "$tmpA"
  [ -s "$tmpA" ] || continue   # new file - no prior updated: to bump
  git show "HEAD:$f" > "$tmpB" 2>/dev/null || : > "$tmpB"
  upA="$(fm_value "$tmpA" updated)"
  [ -n "$upA" ] || continue    # base carries no updated: (index file) - provenance not applicable
  upB="$(fm_value "$tmpB" updated)"
  if [ -z "$upB" ]; then
    reasons+=("$f removed frontmatter 'updated:' (supersede hygiene)")
  elif [ "$upA" = "$upB" ]; then
    reasons+=("$f changed without bumping frontmatter 'updated:' (supersede hygiene)")
  fi
done <<< "$files"

# 4. NO IN-FILE DUP - added content not already present in the base file.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  in_scope "$f" || continue
  base_lc="$(git show "$BASE:$f" 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  [ -n "$base_lc" ] || continue
  while IFS= read -r line; do
    add="${line:1}"  # strip leading '+'
    norm="$(printf '%s' "$add" | sed -E 's/^[-*[:space:]]+//; s/[[:space:]]+$//' | tr '[:upper:]' '[:lower:]')"
    [ "${#norm}" -ge "$DUP_MIN" ] || continue
    case "$norm" in updated:*|scope:*|name:*|source:*|supersedes:*|metadata:*) continue ;; esac
    if printf '%s' "$base_lc" | grep -qF "$norm"; then
      reasons+=("duplicate content in $f: \"$(printf '%s' "$add" | sed -E 's/^[-*[:space:]]+//' | cut -c1-48)…\" already present")
    fi
  done < <(git diff "$BASE"...HEAD -- "$f" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+')
done <<< "$files"

if [ "${#reasons[@]}" -eq 0 ]; then
  echo "APPROVE: in-scope ('$SCOPE') .md, small (${added} added lines), provenance bumped, non-duplicate."
  exit 0
fi
echo "HOLD - self-edit needs human review:"
for r in "${reasons[@]}"; do echo "  - $r"; done
exit 1
