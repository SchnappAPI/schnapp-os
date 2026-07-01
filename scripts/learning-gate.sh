#!/usr/bin/env bash
# learning-gate.sh — deterministic eval/promote gate for a proposed self-edit (agentic-OS Phase 4b).
#
# The learning loop OPENS a self-edit PR; this gate decides whether it is safe to AUTO-LAND or must
# wait for a human. Deliberately CONSERVATIVE — APPROVES only the clearly-clean, HOLDS on any doubt.
# "A learning loop without the eval gate learns confident junk" (decision doc §7.8); the failure mode
# here is "holds too much" (safe), never "merges junk".
#
# APPROVED only when ALL hold:
#   1. SCOPE      — every changed file is a `.md` UNDER rules/ or memory/, and NOT a
#                   symlink (a symlink could alias an out-of-scope path such as a CI workflow).
#   2. SIZE       — total added lines <= LEARNING_GATE_MAX_ADDED (default 40); no binary change
#                   (binary can't be size-checked); big rewrites need eyes.
#   3. PROVENANCE — every CHANGED existing .md bumps its frontmatter `updated:` VALUE (compared via
#                   the shared parser, so a body line starting "updated:" can't spoof it, and nested
#                   `metadata:` frontmatter is handled).
#   4. NO DUP     — no added content line is already present in the file's base version.
# Cross-PR dedupe (another OPEN self-edit PR proposing the same file) is the workflow's job.
#
# Usage: learning-gate.sh [base]      (default: origin/main)
# Read-only. Exit 0 = APPROVE, 1 = HOLD (reasons on stdout). Portable (bash 3.2 indexed arrays).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib-frontmatter.sh"
BASE="${1:-origin/main}"
MAX_ADDED="${LEARNING_GATE_MAX_ADDED:-40}"
DUP_MIN="${LEARNING_GATE_DUP_MIN:-40}"

reasons=()
files="$(git diff --name-only "$BASE"...HEAD 2>/dev/null || true)"
if [ -z "$files" ]; then echo "HOLD: no changes vs $BASE (nothing to evaluate)."; exit 1; fi

# 1. SCOPE — .md under rules/memory only; reject symlinks (git mode 120000), robust without checkout.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  mode="$(git ls-tree HEAD -- "$f" 2>/dev/null | awk '{print $1}')"
  if [ "$mode" = "120000" ]; then reasons+=("symlink not allowed: $f"); continue; fi
  case "$f" in
    rules/*.md|memory/*.md) : ;;
    *) reasons+=("out-of-scope or non-.md file: $f (only .md under rules/ or memory/ may auto-land)") ;;
  esac
done <<< "$files"

# 2. SIZE — binary (numstat '-') can't be sized → HOLD; else cap added lines.
if git diff --numstat "$BASE"...HEAD 2>/dev/null | grep -qE '^-[[:space:]]'; then
  reasons+=("binary file change — cannot size-check; review by hand")
fi
added="$(git diff --numstat "$BASE"...HEAD 2>/dev/null | awk '$1 ~ /^[0-9]+$/ {a+=$1} END{print a+0}')"
if [ "${added:-0}" -gt "$MAX_ADDED" ]; then
  reasons+=("change too large (${added} added lines > ${MAX_ADDED}) — review by hand")
fi

# 3. PROVENANCE — each CHANGED existing .md bumps its frontmatter updated: value (parser-based).
tmpA="$(mktemp)"; tmpB="$(mktemp)"; trap 'rm -f "$tmpA" "$tmpB"' EXIT
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in rules/*.md|memory/*.md) : ;; *) continue ;; esac
  git show "$BASE:$f" > "$tmpA" 2>/dev/null || : > "$tmpA"
  [ -s "$tmpA" ] || continue   # new file — no prior updated: to bump
  git show "HEAD:$f" > "$tmpB" 2>/dev/null || : > "$tmpB"
  if [ "$(fm_value "$tmpA" updated)" = "$(fm_value "$tmpB" updated)" ]; then
    reasons+=("$f changed without bumping frontmatter 'updated:' (supersede hygiene)")
  fi
done <<< "$files"

# 4. NO IN-FILE DUP — added content not already present in the base file.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in rules/*.md|memory/*.md) : ;; *) continue ;; esac
  base_lc="$(git show "$BASE:$f" 2>/dev/null | tr 'A-Z' 'a-z' || true)"
  [ -n "$base_lc" ] || continue
  while IFS= read -r line; do
    add="${line:1}"  # strip leading '+'
    norm="$(printf '%s' "$add" | sed -E 's/^[-*[:space:]]+//; s/[[:space:]]+$//' | tr 'A-Z' 'a-z')"
    [ "${#norm}" -ge "$DUP_MIN" ] || continue
    case "$norm" in updated:*|scope:*|name:*|source:*|supersedes:*|metadata:*) continue ;; esac
    if printf '%s' "$base_lc" | grep -qF "$norm"; then
      reasons+=("duplicate content in $f: \"$(printf '%s' "$add" | sed -E 's/^[-*[:space:]]+//' | cut -c1-48)…\" already present")
    fi
  done < <(git diff "$BASE"...HEAD -- "$f" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+')
done <<< "$files"

if [ "${#reasons[@]}" -eq 0 ]; then
  echo "APPROVE: in-scope .md, small (${added} added lines), provenance bumped, non-duplicate."
  exit 0
fi
echo "HOLD — self-edit needs human review:"
for r in "${reasons[@]}"; do echo "  - $r"; done
exit 1
