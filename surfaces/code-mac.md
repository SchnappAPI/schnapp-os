# Surface: Claude Code on the MacBook Pro (primary)

Most capable. No work restrictions. Run the full automation here.

- **Credentials:** `OP_SERVICE_ACCOUNT_TOKEN` in `~/.zshenv` + `~/.zshrc`, injected to
  launchd by `com.schnapp.environment`. `op read`/`op run` resolve `op://` URIs. `gh` via
  `op plugin run -- gh`. If `op`/`gh` 403, rotate the SA (decisions/0001).
- **Git:** SSH (`git@github.com`), works independently of the SA.
- **Tools/connectors:** local MCP (Mac ops `op_*`, `shell_exec`, SQL), GitHub MCP (OAuth),
  context7, cloudflare. Hosts SQL Server (Docker/Colima), Next.js site, Flask runner,
  self-hosted Actions runner.
- **Hooks:** run here, after the workspace-trust dialog is accepted (the same gate enables the
  memory lane). This is where "must happen every time" happens — the Part-7 hooks in
  [`hooks/`](../hooks/hooks.json) (SessionStart freshness/git gate, Stop
  push-gate, SessionEnd backup). Procedures: [docs/memory-lane.md](../docs/memory-lane.md). Delivery
  (plugin-wide vs project): [decisions/0005](../decisions/0005-hook-delivery-split.md).
