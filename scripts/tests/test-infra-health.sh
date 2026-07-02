#!/usr/bin/env bash
# test-infra-health.sh - smoke test for check-infra-health.sh.
# The probe is Mac-only (launchctl/docker/stat -f/nc), so on non-Darwin (e.g. Linux CI) this skips.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../check-infra-health.sh"

[ -x "$SCRIPT" ] || { echo "FAIL: $SCRIPT not executable"; exit 1; }

if [ "$(uname -s)" != "Darwin" ]; then
  echo "skip: check-infra-health is Mac-only (launchctl/docker/stat -f); uname=$(uname -s)"
  exit 0
fi

# A guaranteed-missing LaunchAgent and an empty backup dir must both report RED and exit non-zero.
# Alerting is fully isolated so a forced RED never touches prod state or files a real issue (#41
# footgun): OPS_ALERT_DISABLE=1 short-circuits the alert; the state-dir/repo/env overrides are
# belt-and-suspenders in case the guard ever regresses.
tmp="$(mktemp -d)"
out="$(OPS_ALERT_DISABLE=1 OPS_STATE_DIR="$tmp/state" OPS_GH_REPO='schnapp-os-tests/none' \
  OPS_ENV=/dev/null NTFY_URL='' INFRA_EXPECTED_AGENTS='definitely.not.loaded.zzz' \
  BACKUP_DIR="$tmp" "$SCRIPT" 2>&1)"; rc=$?
rm -rf "$tmp" 2>/dev/null || true

printf '%s\n' "$out" | grep -q '🔴 definitely.not.loaded.zzz' || { echo "FAIL: missing agent not reported RED"; printf '%s\n' "$out"; exit 1; }
printf '%s\n' "$out" | grep -q 'no schnapp-bet-.*\.bacpac found'  || { echo "FAIL: empty backup dir not reported RED"; exit 1; }
[ "$rc" -ne 0 ]                                                    || { echo "FAIL: expected non-zero exit on RED"; exit 1; }
printf '%s\n' "$out" | grep -q '## LaunchAgents loaded'           || { echo "FAIL: missing section header"; exit 1; }

echo "test-infra-health: PASS"
