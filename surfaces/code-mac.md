# Surface: Claude Code on the MacBook Pro (primary)

Most capable. No work restrictions. Run the full automation here.

- **Credentials:** `OP_SERVICE_ACCOUNT_TOKEN` in `~/.zshenv` + `~/.zshrc`, injected to
  launchd by `com.schnapp.environment`. `op read`/`op run` resolve `op://` URIs. `gh` via
  `op plugin run -- gh`. If `op`/`gh` 403, rotate the SA (decisions/0001).
- **Git:** SSH (`git@github.com`), works independently of the SA.
- **Tools/connectors:** local MCP (Mac ops `op_*`, `shell_exec`, SQL), GitHub MCP (OAuth),
  context7, cloudflare. Hosts SQL Server (Docker/Colima), Next.js site, Flask runner,
  self-hosted Actions runner.
- **Hooks:** run here. This is where "must happen every time" actually happens.
- **Routines:** session-start sync (`git pull --ff-only`) + unmerged-work check; commit and
  push every change; write memory/handoff at session end.
