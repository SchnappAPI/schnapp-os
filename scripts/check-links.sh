#!/usr/bin/env bash
# check-links.sh - fail on a broken relative markdown link in a LIVE doc.
#
# RED (the recurring class this closes): the two big 2026 migrations (vault split ADR 0023, plugin
# flatten ADR 0024) shifted file locations and silently broke `../`-relative links; Phase-2 T3b
# repaired 50, and the 2026-07-02 eval still found 3 more. "Silent drift" is the framework's named
# enemy and the freshness gate could not see this class (it only checks generated-doc + last-verified
# staleness). Per ADR 0026 (deterministic + recurred -> gate), this class earned a gate.
#
# Scope: every tracked *.md EXCEPT append-only history / point-in-time snapshots (where a broken
# point-in-time link is acceptable) and vendored trees. Only checks LOCAL relative links; skips
# http(s)/mailto, #anchors, absolute (/), home (~/), and cross-repo (op://, ://) targets. Strips a
# trailing #anchor or :line-number before resolving. Read-only; exit 1 on any broken link.
set -uo pipefail
export LC_ALL=C
REPO="${CLAUDE_KIT_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$REPO" || { echo "FATAL: cannot cd $REPO" >&2; exit 2; }

# Files whose own links are NOT checked (append-only history + dated point-in-time snapshots +
# generated + vendored). A broken link inside frozen history is a point-in-time artifact, not drift.
excluded() {
  case "$1" in
    decisions/*|handoffs/[0-9]*|docs/archive/*|node_modules/*|*/node_modules/*) return 0 ;;
    PROGRESS.md|PLAN.md|AUDIT.md) return 0 ;;
    docs/repo-review-*|docs/intent-capture-*|docs/credentials-archaeology-*|docs/schnapp-os-research-*) return 0 ;;
    docs/superpowers/*) return 0 ;;   # dated plan/spec trackers reference since-moved files by design
  esac
  return 1
}

broken=0; checked=0
while IFS= read -r file; do
  excluded "$file" && continue
  dir="$(dirname "$file")"
  # extract each link target from ](...) inline links/images
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    case "$target" in
      http://*|https://*|mailto:*|"#"*|/*|"~"*|*"://"*) continue ;;  # external / anchor / absolute / cross-repo
      *NNN*) continue ;;   # NNN is the repo's placeholder token (handoff skeletons/examples), never a real path
    esac
    t="${target%%#*}"          # strip #anchor
    t="${t%% *}"               # strip any trailing " title"
    case "$t" in *:[0-9]*) t="${t%%:*}" ;; esac   # strip :line-number suffix
    [ -z "$t" ] && continue    # was a pure #anchor
    checked=$((checked+1))
    local_target="$dir/$t"
    if [ ! -e "$local_target" ]; then
      echo "BROKEN: $file -> $target (resolves to $local_target)" >&2
      broken=$((broken+1))
    fi
  done < <(grep -oE '\]\([^)]+\)' "$file" | sed -E 's/^\]\(//; s/\)$//')
done < <(git ls-files '*.md')

if [ "$broken" -gt 0 ]; then
  echo "== check-links: $broken broken link(s) across live docs ($checked local links checked) ==" >&2
  exit 1
fi
echo "check-links OK: $checked local links resolve across live docs"
