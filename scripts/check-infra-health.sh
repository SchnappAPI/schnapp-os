#!/usr/bin/env bash
# check-infra-health.sh - deterministic, read-only liveness probe for the Mac platform.
#
# Catches the SILENT-STOP class: a scheduled job that quietly stopped being armed, a dead service,
# an aging backup. Pure bash - no LLM, no MCP, no auth dependency - so the probe cannot itself
# silently fail on the very things it watches. This is a deliberate divergence from the original
# infra-health.md `claude -p` design: a liveness probe must NOT depend on the connector/credential
# it is meant to check (the 2026-06-29 lesson - a backup, a worker, and a credential all silently
# stopped). Mac-only (launchctl/docker/ports). READ-ONLY: never restarts or remediates; a RED signal
# is reported + (best-effort) notified, for an approved session to act on.
#
# Run on demand (the `status` skill) or via the com.schnapp.infra-health LaunchAgent (daily).
# Overrides (tests / tuning): INFRA_EXPECTED_AGENTS (space-sep labels), BACKUP_DIR, MAX_BACKUP_AGE_DAYS.
set -uo pipefail
export LC_ALL=C

MAX_BACKUP_AGE_DAYS="${MAX_BACKUP_AGE_DAYS:-8}"   # weekly backup + 1 day grace
BACKUP_DIR="${BACKUP_DIR:-$HOME/azure-sql-backups}"

if [ -n "${INFRA_EXPECTED_AGENTS:-}" ]; then
  read -r -a EXPECTED_AGENTS <<< "$INFRA_EXPECTED_AGENTS"
else
  # LaunchAgents that must stay loaded (label present in `launchctl list`). Maintain this list as the
  # platform changes - a label missing here is exactly how the bacpac backup silently lapsed.
  EXPECTED_AGENTS=(
    com.schnapp.macmcp
    com.schnapp.obsidian-mcp
    com.schnapp.memory-consolidation
    com.schnapp.vault-autocommit
    com.schnapp.syncrepos
    bet.schnapp.bacpac-backup
    bet.schnapp.flask
    bet.schnapp.web-prod
    homebrew.mxcl.cloudflared
    actions.runner.SchnappAPI-schnapp-bet.mac-runner-1
  )
fi

# "port:label" for the local MCP servers that should be LISTENing.
PORT_CHECKS=( "8765:mac-mcp" "8767:obsidian-mcp" )

rc=0
RED_SUMMARY=""
red()  { rc=1; RED_SUMMARY+="• $1"$'\n'; printf -- '- 🔴 %s\n' "$1"; }
grn()  { printf -- '- 🟢 %s\n' "$1"; }
warn() { printf -- '- 🟡 %s\n' "$1"; }

printf '# infra-health - %s\n\n' "$(date -u '+%Y-%m-%d %H:%M:%SZ')"

printf '## LaunchAgents loaded\n'
loaded="$(launchctl list 2>/dev/null | awk 'NR>1{print $3}')"
if [ "${#EXPECTED_AGENTS[@]}" -gt 0 ]; then
  for label in "${EXPECTED_AGENTS[@]}"; do
    if printf '%s\n' "$loaded" | grep -Fxq "$label"; then
      grn "$label"
    else
      red "$label NOT loaded (a scheduled/service job is not armed)"
    fi
  done
else
  red "EXPECTED_AGENTS is empty (malformed INFRA_EXPECTED_AGENTS override) - no agents checked"
fi
printf '\n'

printf '## SQL backup freshness (%s/schnapp-bet-*.bacpac)\n' "$BACKUP_DIR"
shopt -s nullglob
backups=( "$BACKUP_DIR"/schnapp-bet-*.bacpac )
shopt -u nullglob
if [ "${#backups[@]}" -eq 0 ]; then
  red "no schnapp-bet-*.bacpac found in $BACKUP_DIR"
else
  newest=""; newest_m=0
  for f in "${backups[@]}"; do
    m="$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || echo 0)"
    [ "$m" -gt "$newest_m" ] && { newest_m="$m"; newest="$f"; }
  done
  age_days=$(( ( $(date +%s) - newest_m ) / 86400 ))
  if [ "$age_days" -gt "$MAX_BACKUP_AGE_DAYS" ]; then
    red "newest backup ${age_days}d old (> ${MAX_BACKUP_AGE_DAYS}d): $(basename "$newest")"
  else
    grn "newest backup ${age_days}d old: $(basename "$newest")"
  fi
fi
printf '\n'

printf '## SQL Server container\n'
if ! command -v docker >/dev/null 2>&1; then
  warn "docker CLI not found - cannot check the mssql container"
elif [ -n "$(docker ps --filter name=mssql --filter status=running --format '{{.Names}}' 2>/dev/null)" ]; then
  grn "mssql container running"
else
  red "mssql container NOT running (SQL Server down)"
fi
printf '\n'

printf '## Local MCP ports listening\n'
for entry in "${PORT_CHECKS[@]}"; do
  port="${entry%%:*}"; name="${entry#*:}"
  if nc -z -G 2 localhost "$port" >/dev/null 2>&1; then
    grn "$name :$port"
  else
    red "$name :$port NOT listening"
  fi
done
printf '\n'

# Self-check the PRIMARY alert channel so a broken issue/email path becomes a detected RED (alerted via
# the non-gh channels: ntfy/notification), instead of silently failing. Sources ops.env for an
# explicit GH_TOKEN if present, matching what ops-alert uses.
printf '## GitHub alert channel (gh auth)\n'
gh_ok=1
# shellcheck disable=SC1090,SC1091
( [ -r "$HOME/.config/schnapp-os/ops.env" ] && . "$HOME/.config/schnapp-os/ops.env"; command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 ) || gh_ok=0
if [ "$gh_ok" -eq 1 ]; then
  grn "gh authenticated - issue/email alerts can fire"
else
  red "gh NOT authenticated - GitHub issue/email alerts will NOT fire (fix gh auth or set GH_TOKEN in ops.env)"
fi
printf '\n'

DIR="$(cd "$(dirname "$0")" && pwd)"
# Alerting is best-effort and side-effecting (opens/closes a real owner-assigned GitHub issue +
# pings ntfy + writes the state file). OPS_ALERT_DISABLE=1 suppresses it so a forced-RED test or a
# dry-run cannot touch prod state or file a false incident (the #41 footgun). ops-alert also honors
# OPS_STATE_DIR / OPS_GH_REPO for further isolation.
alert() { [ "${OPS_ALERT_DISABLE:-0}" = 1 ] && return 0; "$DIR/ops-alert.sh" "$@" >/dev/null 2>&1 || true; }
if [ "$rc" -eq 0 ]; then
  printf '**infra-health: OK** - all checks green.\n'
  # Resolve any open incident (best-effort): closes the GitHub issue + clears state on recovery.
  alert green infra-health "schnapp infra-health" ""
else
  printf '**infra-health: RED** - a watched signal failed (read-only; nothing was restarted).\n'
  # Native alert (best-effort): opens/updates an owner-assigned GitHub issue (email) for the incident,
  # plus a one-shot ntfy/macOS notification on the green->red transition. See ops-alert.sh.
  alert red infra-health "schnapp infra-health RED" \
    "$(printf 'Host %s:\n%s' "$(hostname -s)" "$RED_SUMMARY")"
fi
exit "$rc"
