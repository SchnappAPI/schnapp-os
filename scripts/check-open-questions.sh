#!/usr/bin/env bash
# check-open-questions.sh - read-only surfacing of the live handoff's open owner items.
#
# Handoffs are append-only; by convention the NEWEST numbered handoff is the resume point and
# carries forward every still-open question (older ones are frozen history). Open items rot
# silently: nothing re-reads a "## Open ..." section once the session that wrote it ends. This
# prints the newest handoff's open items so the nightly routine + owner keep seeing them until a
# newer handoff resolves or re-carries them. READ-ONLY: never edits, ALWAYS exits 0
# (informational, like check-stale-facts.sh - surfacing is the point).
#
# Usage: check-open-questions.sh [handoffs-dir]   (default: handoffs)
set -uo pipefail
DIR="${1:-handoffs}"
if [ ! -d "$DIR" ]; then
  echo "SKIP: handoffs dir '$DIR' not found on this surface."
  exit 0
fi

# Newest numbered handoff = resume point (same ordering rule as gen-handoff-index.sh:
# zero-padded numeric prefixes sort lexicographically).
newest="$(find "$DIR" -maxdepth 1 -name '[0-9]*.md' | sort | tail -1)"
if [ -z "$newest" ]; then
  echo "no numbered handoffs found in $DIR."
  exit 0
fi

# Every "## Open ..." section's list items (bulleted or numbered), up to the next heading.
items="$(awk '
  /^## Open/               { insec=1; next }
  /^## /                   { insec=0 }
  insec && /^([0-9]+\.|-) / { print }
' "$newest")"

name="$(basename "$newest")"
if [ -n "$items" ]; then
  n="$(printf '%s\n' "$items" | grep -c .)"
  echo "OPEN ITEMS ($n) in $name - stay listed until a newer handoff resolves or re-carries them:"
  printf '%s\n' "$items" | sed 's/^/  /'
else
  echo "no open items in $name."
fi
exit 0
