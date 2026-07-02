#!/usr/bin/env bash
# check-stale-facts.sh - read-only memory freshness flag (agentic-OS loops Phase 2).
# Flags facts whose `updated:` crosses 7/30/90-day age thresholds vs today. READ-ONLY:
# prints flags, never edits, ALWAYS exits 0 (staleness is informational, not a hard gate:
# surfacing is the point; the agent decides what to refresh, supersede-not-append per docs/memory-lane.md).
#
# Usage: check-stale-facts.sh [dir] [today]
#   dir - memory dir (default: memory). Skips MEMORY.md/README.md.
#   today - ISO date to measure against (default: date -u +%F). Injectable for tests.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib-frontmatter.sh"
DIR="${1:-memory}"
TODAY="${2:-$(date -u +%F)}"

# A surface without the lane checked out (CI runners; the lane moved to the vault, ADR 0023)
# must say SKIP, not "OK": an unconditional green for a directory that was never read is the
# silent-drift class this script exists to catch. Still read-only, still exit 0.
if [ ! -d "$DIR" ]; then
  echo "SKIP: memory dir '$DIR' not found on this surface; nothing swept (global lane lives in SchnappAPI/schnapp-vault, ADR 0023)."
  exit 0
fi

# iso_to_days <YYYY-MM-DD> - days since the civil epoch (Hinnant days_from_civil).
# Pure integer arithmetic → portable across BSD/GNU, deterministic, unit-testable.
iso_to_days() {
  local y m d rest era yoe doy doe
  y=${1%%-*}; rest=${1#*-}; m=${rest%%-*}; d=${rest#*-}
  y=$((10#$y)); m=$((10#$m)); d=$((10#$d))
  (( m <= 2 )) && y=$(( y - 1 ))
  if (( y >= 0 )); then era=$(( y / 400 )); else era=$(( (y-399)/400 )); fi
  yoe=$(( y - era*400 ))
  if (( m > 2 )); then doy=$(( (153*(m-3)+2)/5 + d-1 )); else doy=$(( (153*(m+9)+2)/5 + d-1 )); fi
  doe=$(( yoe*365 + yoe/4 - yoe/100 + doy ))
  echo $(( era*146097 + doe - 719468 ))
}

t_today=$(iso_to_days "$TODAY")
flagged=0
for f in "$DIR"/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in MEMORY.md|README.md) continue;; esac
  upd="$(fm_value "$f" updated)"
  printf '%s' "$upd" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || continue  # malformed/missing dates are the frontmatter gate's job
  age=$(( t_today - $(iso_to_days "$upd") ))
  if   (( age >= 90 )); then tier="STALE 90d+"
  elif (( age >= 30 )); then tier="aging 30d+"
  elif (( age >=  7 )); then tier="review 7d+"
  else continue; fi
  echo "$base: $tier (${age}d, updated $upd)"
  flagged=$((flagged+1))
done
[ "$flagged" = 0 ] && echo "memory freshness OK (no facts older than 7d)"
exit 0
