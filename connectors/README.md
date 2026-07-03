# connectors/ - remote MCP servers

The off-Mac access layer: each subdirectory is one MCP server, self-contained with its own
README (what + why) and DEPLOY.md (how to run it). Inventory with endpoints:
[CATALOG.md](../CATALOG.md) "MCP connectors".

- [op-mcp/](op-mcp/) - 1Password secret resolver (references in, values at runtime; Render-hosted).
- [memory-mcp/](memory-mcp/) - cross-surface memory lane reader/writer over the vault repo (Render-hosted).
- [mac-mcp/](mac-mcp/) - the owner Mac: shell, services, SQL, workflows, op (Mac-hosted, tunneled).
- [github-mcp/](github-mcp/) - GitHub org operations (Mac-hosted, tunneled).
- [obsidian-mcp/](obsidian-mcp/) - Obsidian vault notes (Mac-hosted, tunneled).

`node_modules/` under op-mcp and memory-mcp are local installs, not tracked. Which surface uses
which connector: [surfaces/](../surfaces/). Secrets are `op://` references only
([credentials-map.md](../credentials-map.md)).
