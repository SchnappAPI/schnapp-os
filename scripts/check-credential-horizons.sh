#!/usr/bin/env bash
# check-credential-horizons.sh - dated credential-expiry alarm (campaign Phase 5 monitor).
#
# Drift caught: a credential with a known expiry (e.g. the ~2027-05 learning-worker OAuth
# re-mint) crossing into its warn window with no alert beyond a prose note in
# credentials-map.md. Alert path: WARN lines here -> run-ci-routines.sh Step Summary; a WARN
# also exits 1, which reds the nightly scheduled-routines workflow (GitHub emails the owner) -
# the bundle's only push channel. Own failure mode: it cannot die silently while the nightly
# runs - a missing/unreadable data file or a malformed dated row is itself a WARN + exit 1,
# never a quiet OK; rows with expiry UNKNOWN are INFO (documented absence, not silence).
# Verify: bash scripts/check-credential-horizons.sh (expect "credential horizons OK", exit 0).
#
# Usage: check-credential-horizons.sh [tsv] [today]
#   tsv   - data file (default: scripts/credential-horizons.tsv beside this script)
#   today - ISO date to measure against (default: date -u +%F). Injectable for tests.
# Exit 0 = no credential inside its warn window; exit 1 = WARN (within horizon, or bad data).
set -uo pipefail
export LC_ALL=C

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TSV="${1:-$HERE/credential-horizons.tsv}"
TODAY="${2:-$(date -u +%F)}"

if [ ! -r "$TSV" ]; then
  echo "WARN: horizons data file missing or unreadable: $TSV (the expiry alarm is blind)"
  exit 1
fi

# iso_to_days <YYYY-MM-DD> - days since the civil epoch (Hinnant days_from_civil).
# Pure integer arithmetic: portable across BSD/GNU, deterministic, unit-testable.
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

t_today="$(iso_to_days "$TODAY")"
warned=0
rows=0

while IFS=$'\t' read -r name expiry warn_days note; do
  case "$name" in ''|'#'*) continue ;; esac
  rows=$((rows+1))
  if [ "$expiry" = "UNKNOWN" ]; then
    echo "INFO: $name has no documented expiry (${note:-no note}); add a dated row when one is learned"
    continue
  fi
  if ! printf '%s' "$expiry" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
     || ! printf '%s' "$warn_days" | grep -qE '^[0-9]+$'; then
    echo "WARN: malformed row for '$name' (expiry='$expiry' warn_days='$warn_days') - fix $TSV"
    warned=1
    continue
  fi
  t_expiry="$(iso_to_days "$expiry")"
  days_left=$(( t_expiry - t_today ))
  if [ "$days_left" -le "$warn_days" ]; then
    echo "WARN: $name expires $expiry (${days_left} days; warn window ${warn_days}d). ${note:-}"
    warned=1
  else
    echo "OK: $name expires $expiry (${days_left} days out)"
  fi
done < "$TSV"

if [ "$rows" -eq 0 ]; then
  echo "WARN: no data rows in $TSV (the expiry alarm is blind)"
  exit 1
fi
if [ "$warned" -ne 0 ]; then exit 1; fi
echo "credential horizons OK (no credential inside its warn window as of $TODAY)"
