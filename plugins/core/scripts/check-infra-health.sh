#!/usr/bin/env bash
# check-infra-health.sh — deterministic, read-only liveness probe for the Mac platform.
#
# Catches the SILENT-STOP class: a scheduled job that quietly stopped being armed, a dead service,
# an aging backup. Pure bash — no LLM, no MCP, no auth dependency — so the probe cannot itself
# silently fail on the very things it watches. This is a deliberate divergence from the original
# infra-health.md `claude -p` design: a liveness probe must NOT depend on the connector/credential
# it is meant to check (the 2026-06-29 lesson — a backup, a worker, and a credential all silently
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
  # platform changes — a label missing here is exactly how the bacpac backup silently lapsed.
  EXPECTED_AGENTS=(
    com.schnapp.macmcp
    com.schnapp.githubmcp
    com.schnapp.obsidian-mcp
    com.schnapp.memory-consolidation
    com.schnapp.syncrepos
    bet.schnapp.bacpac-backup
    bet.schnapp.flask
    bet.schnapp.web-prod
    homebrew.mxcl.cloudflared
    actions.runner.SchnappAPI-schnapp-bet.mac-runner-1
  )
fi

# "port:label" for the local MCP servers that should be LISTENing.
PORT_CHECKS=( "8765:mac-mcp" "8766:github-mcp" "8767:obsidian-mcp" )

rc=0
red()  { rc=1; printf -- '- 🔴 %s\n' "$1"; }
grn()  { printf -- '- 🟢 %s\n' "$1"; }
warn() { printf -- '- 🟡 %s\n' "$1"; }

printf '# infra-health — %s\n\n' "$(date -u '+%Y-%m-%d %H:%M:%SZ')"

printf '## LaunchAgents loaded\n'
loaded="$(launchctl list 2>/dev/null | awk 'NR>1{print $3}')"
for label in "${EXPECTED_AGENTS[@]}"; do
  if printf '%s\n' "$loaded" | grep -Fxq "$label"; then
    grn "$label"
  else
    red "$label NOT loaded (a scheduled/service job is not armed)"
  fi
done
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
    m="$(stat -f %m "$f" 2>/dev/null || echo 0)"
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
  warn "docker CLI not found — cannot check the mssql container"
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

if [ "$rc" -eq 0 ]; then
  printf '**infra-health: OK** — all checks green.\n'
else
  printf '**infra-health: RED** — a watched signal failed (read-only; nothing was restarted).\n'
  if command -v osascript >/dev/null 2>&1; then
    osascript -e 'display notification "infra-health found a RED signal — see the log" with title "schnapp-os infra-health"' >/dev/null 2>&1 || true
  fi
fi
exit "$rc"
