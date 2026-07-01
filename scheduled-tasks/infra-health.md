# Routine: infra / pipeline health probe

- **Class:** safe (probe) - read-only health checks; no remediation without approval.
- **Implementation:** [`scripts/check-infra-health.sh`](../scripts/check-infra-health.sh):
  **pure bash**, deterministic, read-only. No LLM, no MCP, no auth dependency.
- **Scheduler:** the [`com.schnapp.infra-health`](com.schnapp.infra-health.plist) Mac LaunchAgent (every 30 min + once at load). Also runnable on demand and surfaced by the `status` skill.
- **What it checks** (green/red; exits non-zero on any RED):
  - expected LaunchAgents are loaded (the three connectors, the tunnel, the worker, the backup, the CI
    runner, flask + web-prod) - a missing label is exactly how the bacpac backup silently lapsed;
  - the newest `schnapp-bet-*.bacpac` is younger than `MAX_BACKUP_AGE_DAYS` (default 8);
  - the `mssql` Docker container is running;
  - the three local MCP ports (8765 mac, 8766 github, 8767 obsidian) are LISTENing.
- **On a RED signal:** prints the failing detail, posts a macOS notification, **pages off-Mac via
  [`notify-ops.sh`](../scripts/notify-ops.sh) (ntfy) when `NTFY_URL` is set**, exits non-zero, and
  logs the report to `~/Library/Logs/schnapp-os/infra-health.log`. It NEVER restarts or remediates - a fix is an
  approved-session action (and never foreground-restart `com.schnapp.macmcp`; use the detached daemon, per
  handoff 020/021).
- **Why pure bash, not `claude -p` (deliberate divergence from the original spec):** a liveness probe must
  not depend on the connector or credential it is meant to watch. The 2026-06-29 session had a backup, a
  worker, and a credential all silently stop; an LLM/MCP-based probe could itself be the dead thing.
  Deterministic bash cannot silently fail on auth/LLM. (ADR 0019 records the credential half of that lesson.)

## Install (run on the Mac, owner-confirmed)

```bash
REPO="$HOME/code/schnapp-os"
mkdir -p ~/Library/Logs/schnapp-os
PL=~/Library/LaunchAgents/com.schnapp.infra-health.plist
sed -e "s|__REPO__|$REPO|g" -e "s|__HOME__|$HOME|g" \
  "$REPO/scheduled-tasks/com.schnapp.infra-health.plist" > "$PL"
launchctl unload "$PL" 2>/dev/null; launchctl load "$PL"   # RunAtLoad runs it once now
launchctl list | grep infra-health                         # confirm loaded
tail -n 20 ~/Library/Logs/schnapp-os/infra-health.log      # read the first report
```

## Extending it

Add checks to `check-infra-health.sh`, keeping each deterministic + read-only. Candidates: the Render cloud
connectors (probe via `op_health` from an off-Mac surface - Render free-tier cold-starts make an on-Mac HTTP
check noisy), the Obsidian brain-agent index drain age, and the production site `site_health`. Maintain
`EXPECTED_AGENTS` as the platform's LaunchAgents change (or override it per-run via `INFRA_EXPECTED_AGENTS`).
