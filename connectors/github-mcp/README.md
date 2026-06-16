# github-mcp

Self-hosted MCP server exposing GitHub operations. Bearer-token auth
(`GITHUB_MCP_AUTH_TOKEN`); secrets resolved at launch via `op-wrap.sh` +
`~/github-mcp/.env.template` (op:// refs). Connected in claude.ai as "Schnapp GitHub".

- URL: https://github-mcp.schnapp.bet/mcp  (Mac :8766 via the schnapp-mac tunnel)
- Service: launchd `com.schnapp.githubmcp` (RunAtLoad, KeepAlive)
- **Single source of truth: this repo.** The Mac runs it via symlink
  `~/github-mcp/server.py -> connectors/github-mcp/server.py`. Edit here, then restart:
  `launchctl kickstart -k gui/$UID/com.schnapp.githubmcp`.
- Deps pinned (requirements.txt) + locked (requirements.lock.txt). Bump only after smoke-testing.
