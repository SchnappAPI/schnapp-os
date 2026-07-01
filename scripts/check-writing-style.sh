#!/usr/bin/env bash
# check-writing-style.sh - writing-style gate: no em dash (U+2014) in live files
# (rules/global/writing-style.md). Enforcement per decisions/0026 (deterministic check that
# recurred twice -> CI gate + write-time hook): the 2026-07-01 repo-wide sweep is the baseline;
# this keeps the class closed.
#
# FROZEN history is exempt (append-only by design, anti-stale.md): decisions/, handoffs/,
# docs/archive/, PROGRESS.md, plus the dated point-in-time snapshot reports and the closed
# initiative docs the streamline plan's T3 leave-list froze. The vault MEMORY.md index-line
# format ('- [Title](slug.md) <em dash> hook') is vault-owned data, not prose: lines quoting it
# are skipped wherever they appear (connectors/memory-mcp/src/tools.ts).
#
# Usage:
#   check-writing-style.sh              # gate every git-tracked live file (CI mode)
#   check-writing-style.sh FILE...      # gate specific files (hook mode); frozen paths pass
# Exit 0 clean; exit 1 on any em dash in a live file (each hit named file:line).
set -uo pipefail
export LC_ALL=C

REPO="${CLAUDE_KIT_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$REPO" || { echo "FATAL: repo not found: $REPO" >&2; exit 2; }

EM="$(printf '\xe2\x80\x94')"   # U+2014 as literal UTF-8 bytes (portable, no $'\u..' dependency)

is_frozen() { # repo-relative path -> 0 if exempt
  case "$1" in
    decisions/*|handoffs/*|docs/archive/*|PROGRESS.md|AUDIT.md) return 0 ;;
    docs/repo-review-*|docs/intent-capture-*|docs/credentials-archaeology-*) return 0 ;;
    docs/schnapp-os-research-and-decisions-*) return 0 ;;
    docs/superpowers/plans/2026-06-27-*|docs/superpowers/specs/2026-06-17-*) return 0 ;;
    *) return 1 ;;
  esac
}

check_file() { # repo-relative path -> prints hits, returns 1 if any
  # skip binaries: grep -I treats them as clean
  grep -In "$EM" -- "$1" 2>/dev/null | grep -v "\.md) ${EM}" | sed "s|^|$1:|"
}

fail=0
if [ "$#" -gt 0 ]; then
  for f in "$@"; do
    rel="${f#"$REPO"/}"
    [ -f "$rel" ] || continue
    # An absolute path that survived the prefix-strip lives in ANOTHER checkout (e.g. a
    # worktree-session hook checking the main checkout). Map it to ITS repo-relative path so
    # the frozen-history patterns still match; untracked/unmappable stays as-is (checked live).
    case "$rel" in
      /*) frozen_key="$(git -C "$(dirname "$rel")" ls-files --full-name -- "$rel" 2>/dev/null | head -1)" ;;
      *)  frozen_key="$rel" ;;
    esac
    is_frozen "${frozen_key:-$rel}" && continue
    hits="$(check_file "$rel")"
    [ -n "$hits" ] && { printf '%s\n' "$hits" >&2; fail=1; }
  done
else
  while IFS= read -r rel; do
    is_frozen "$rel" && continue
    hits="$(check_file "$rel")"
    [ -n "$hits" ] && { printf '%s\n' "$hits" >&2; fail=1; }
  done < <(git ls-files)
fi

if [ "$fail" -ne 0 ]; then
  echo "writing-style: em dash (U+2014) in live files (above). Use a colon, a spaced hyphen," >&2
  echo "or split the sentence (rules/global/writing-style.md). Frozen history is exempt." >&2
  exit 1
fi
echo "writing-style OK (no em dashes in live files)"
