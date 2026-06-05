# Credentials map — `op://` references, never values

How every surface finds secrets. **References only** — no secret value ever lands in a
tracked file ([secrets-as-references](plugins/core/rules/global/secrets-as-references.md)).
Resolution: `op read` / `op run` on the Mac; the [op-mcp connector](connectors/op-mcp/)
off-Mac (claude.ai / iPhone); a GitHub Actions secret in CI.

## Resolution by surface
| Surface | How secrets resolve |
|---|---|
| Code (Mac) | `op` CLI + Mac `op_*` MCP, Service Account token in the shell env |
| Code (work machines) | `op` CLI with the SA token in that machine's env |
| claude.ai / iPhone | op-mcp connector LIVE — portal `https://mcp.schnapp.bet/mcp` (decisions/0004). `op_read` returns values; prefer the Mac `op_run`/`op_inject` to *use* a secret |
| GitHub Actions | repo secret `OP_SERVICE_ACCOUNT_TOKEN` (set on the tracked repos; 2 unscoped repos pending — see Status) |

## Reference syntax
`op://<vault>/<item>/<field>` (sections: `op://<vault>/<item>/<section>/<field>`).
Discover with the connector: `op_list_vaults` -> `op_list_items` -> `op_read`.

> Field labels are NOT reliably the category default in this vault. Verified examples:
> `op://web-variables/GITHUB_PAT/credential` does NOT resolve (field is labeled
> differently). Confirm the exact field label in 1Password (or via `op_read`) before
> wiring a reference — do not assume `password`/`credential`.

## Vault: `web-variables` (id `o3rjqrgvascutyedbmuzfl4yzu`)
System-relevant items (titles from `op_list_items`; categories in brackets). Build
`op://web-variables/<item>/<field>` once you confirm the field label.

| Item | Category | Used for |
|---|---|---|
| `Service Account Auth Token: schnapp-automation` | ApiCredentials | The 1Password SA token (bootstrap secret; see below) |
| `GITHUB_PAT` | ApiCredentials | GitHub fine-grained PAT (gh / GitHub MCP) |
| `GitHub Actions Runner` | Password | Self-hosted runner registration |
| `Cloudflare Tunnel` | Password | Cloudflare tunnel for the Mac infra |
| `Database` | Password | SQL Server (Docker/Colima on the Mac) |
| `Web App` | Password | Production Next.js site |
| `MCP Tokens` | Password | MCP connector tokens |
| `Anthropic` / `Claude Code` | Password | Anthropic API / Claude Code |
| `Webshare Proxy` | Password | Proxy credentials |
| `QUICKBASE_EXCEL_SYNC` | ApiCredentials | Quickbase ETL |
| `GitHub SSH Key` | SshKey | git over SSH |

(Personal items in the vault are omitted; this map is the system surface.)

## Bootstrap + connector secrets (not `op://`-resolvable — they ARE the keys)
- `OP_SERVICE_ACCOUNT_TOKEN` — the SA token itself; set directly in each surface's env
  from the `Service Account Auth Token: schnapp-automation` item. It is what resolves all
  other `op://` references, so it cannot itself be an `op://` lookup at bootstrap.
- `CONNECTOR_AUTH_TOKEN` — op-mcp bearer gate; generate (`openssl rand -hex 32`) and store
  in 1Password, then set as a host secret. See connectors/op-mcp/.env.template.

## Status
- 1Password SA rotated 2026-06-03; `op`/`gh` work (memory/credentials-state.md).
- **op-mcp connector LIVE (2026-06-05):** Render `https://op-mcp.onrender.com` + Cloudflare portal
  `https://mcp.schnapp.bet/mcp`, registered in claude.ai. `op_health`/`op_read` verified from
  claude.ai (decisions/0004, connectors/op-mcp/DEPLOY.md).
- PAT widened to all repos; Actions secret set on the authorized repos incl. `af-invoice-parser` +
  `af-query-api`. `DB_Storage` + `appfolio-marketing-project` still lack it (never scoped — awaiting
  owner decision; classifier-flagged master-token spread).
