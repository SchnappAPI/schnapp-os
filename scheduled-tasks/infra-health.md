# Routine: infra / pipeline health probe

- **Class:** safe (probe) — read-only health checks; no remediation without approval.
- **Scheduler:** Mac LaunchAgent → headless `claude -p` session (needs the Mac MCP connectors).
- **What it does:** probes the owner's platform via the Mac connector and reports status:
  the three custom MCP connectors (mac 8765, github 8766, obsidian 8767), the op-mcp host
  (`op_health` / portal), SQL Server in Docker/Colima, the Flask live-data runner, the production
  Next.js site, the self-hosted Actions runner, tunnel health, and the last backup archive age.
- **Acts on its own?** No. It only reads (`service_status`, `site_health`, `tunnel_status`,
  `backup_status`, `op_health`). A restart or any remediation is **asks-first**: if a service is
  down it queues the proposed fix (and never restarts `com.schnapp.macmcp` except via the detached
  double-fork daemon — that is the operating channel; see handoff 020/021).
- **Reports:** writes a health summary to the repo and notifies; on any red signal, queues the
  proposed remediation for an approved session.
- **Why it exists:** the platform runs unattended (scheduled ETL, live data, the site); a nightly
  probe catches a dead service or an aging backup before the owner hits it.

## Agent instructions (what the LaunchAgent's `claude -p` runs)
> Probe each service read-only via the Mac connector (service_status, site_health, tunnel_status,
> backup_status, op_health, docker_status, flask_status, the three MCP ports). Report a
> green/red table with the failing detail. Do NOT restart or remediate anything. For each red
> signal, write the proposed fix as a queued item for an approved session. Persist the report to
> the repo and notify. Never foreground-restart com.schnapp.macmcp.
