#!/usr/bin/env bash
# ops-alert.sh — incident-managed, native alerting for schnapp-os Mac routines.
#
# Fires ONCE per incident and resolves on recovery, across channels (all best-effort — detection
# stays in the caller, which is dependency-free; this layer may use gh/network and must NEVER break
# the caller):
#   - GitHub issue, assigned to the owner -> NATIVE email. Open on red / close on green, deduped by
#     the "[<key>] " title prefix (open-issue-as-state), so a persistent red is one issue, not spam.
#   - ntfy push (via notify-ops.sh) + macOS notification, ONLY on the green->red transition, so a
#     frequent probe cadence does not re-alert every run for the same ongoing failure.
#
# State: ~/.config/schnapp-os/state/<key>.state  (overridable via OPS_STATE_DIR).
# Config: OPS_GH_REPO (default SchnappAPI/schnapp-os), OPS_GH_ASSIGNEE (default SchnappAPI).
# Needs gh authenticated for the issue path; without gh it degrades to the push channels only.
#
# Usage: ops-alert.sh <red|green> <key> <title> <summary-text>
set -uo pipefail

status="${1:-}"; key="${2:-}"; title="${3:-schnapp-os alert}"; summary="${4:-}"
[ -n "$status" ] && [ -n "$key" ] || exit 0

STATE_DIR="${OPS_STATE_DIR:-$HOME/.config/schnapp-os/state}"
mkdir -p "$STATE_DIR" 2>/dev/null || true
state_file="$STATE_DIR/${key}.state"
last="$(cat "$state_file" 2>/dev/null || echo green)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${OPS_GH_REPO:-SchnappAPI/schnapp-os}"
ASSIGNEE="${OPS_GH_ASSIGNEE:-SchnappAPI}"
ISSUE_TITLE="[${key}] ${title}"
now="$(date -u '+%Y-%m-%d %H:%M:%SZ')"

have_gh() { command -v gh >/dev/null 2>&1; }
find_open_issue() {
  gh issue list --repo "$REPO" --state open --json number,title \
    --jq '.[] | select(.title|startswith("['"$key"']")) | .number' 2>/dev/null | head -1
}

if [ "$status" = "red" ]; then
  # File ONE incident issue (assigned -> native email). A persistent RED keeps this single open issue
  # as the standing record; we deliberately do NOT comment each run, so a long outage is one email,
  # not one per probe cycle. It auto-closes on recovery.
  if have_gh && [ -z "$(find_open_issue)" ]; then
    printf '%s\n\nFailing checks at %s:\n\n%s\n\nThis issue auto-closes when the next run is all green.\n' \
      "$title" "$now" "$summary" \
      | gh issue create --repo "$REPO" --title "$ISSUE_TITLE" --body-file - --assignee "$ASSIGNEE" >/dev/null 2>&1 || true
  fi
  if [ "$last" != "red" ]; then
    "$SCRIPT_DIR/notify-ops.sh" "$title (see GitHub issue). $summary" "$ISSUE_TITLE" "high" "rotating_light" >/dev/null 2>&1 || true
    if command -v osascript >/dev/null 2>&1; then
      osascript -e 'display notification "RED signal — see the GitHub issue / log" with title "schnapp-os infra-health"' >/dev/null 2>&1 || true
    fi
  fi
  echo red > "$state_file" 2>/dev/null || true
else
  if [ "$last" = "red" ]; then
    if have_gh; then
      # Close every matching open issue (guards the rare case where two runs raced and both opened one).
      gh issue list --repo "$REPO" --state open --json number,title \
        --jq '.[] | select(.title|startswith("['"$key"']")) | .number' 2>/dev/null | while read -r n; do
        [ -n "$n" ] || continue
        printf 'Recovered at %s. Auto-closing.\n' "$now" | gh issue comment "$n" --repo "$REPO" --body-file - >/dev/null 2>&1 || true
        gh issue close "$n" --repo "$REPO" --reason completed >/dev/null 2>&1 || true
      done
    fi
    "$SCRIPT_DIR/notify-ops.sh" "Recovered: $title" "$ISSUE_TITLE" "default" "white_check_mark" >/dev/null 2>&1 || true
  fi
  echo green > "$state_file" 2>/dev/null || true
fi
exit 0
