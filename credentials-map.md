# Credentials map — canonical inventory (`op://` references, never values)

The single source of truth for what every credential is, where it resolves, and everywhere
its value is set. **References only** — no secret value ever lands here
([secrets-as-references](plugins/core/rules/global/secrets-as-references.md)). Verified against
`op item list` on 2026-06-17.

- **History:** [docs/credentials-archaeology-2026-06-17.md](docs/credentials-archaeology-2026-06-17.md)
- **Target design + conventions:** [docs/superpowers/specs/2026-06-17-credential-system-design.md](docs/superpowers/specs/2026-06-17-credential-system-design.md)
- **Connector runbook:** [connectors/op-mcp/DEPLOY.md](connectors/op-mcp/DEPLOY.md) · decisions `0001`, `0002`, `0004`

## Resolution by surface
| Surface | How secrets resolve |
|---|---|
| Code (Mac) | `op` CLI + Mac `op_*` MCP; SA token in the shell env (`~/.zshrc`/`~/.zshenv`) |
| Code (work machines) | `op` CLI with the SA token in that machine's env |
| claude.ai / iPhone | op-mcp connector via Cloudflare portal `https://mcp.schnapp.bet/mcp` |
| Code / Cowork (off-Mac) | op-mcp connector `https://op-mcp.onrender.com/mcp` + bearer |
| GitHub Actions | repo secret `OP_SERVICE_ACCOUNT_TOKEN` → `1password/load-secrets-action@v2` → `op://` per workflow |

## Reference syntax
`op://web-variables/<item>/<field>` (sections: `op://web-variables/<item>/<section>/<field>`).
Discover via `op_list_vaults` → `op_list_items` → `op_read`.

> **Field labels are NOT the category default in this vault.** The reference must match the
> real field label. Verified: `GITHUB_PAT` resolves at `/token` (not `/credential`). Confirm
> the exact label (this table, or `op_read`) before wiring a new reference.

## Vault: `web-variables` (id `o3rjqrgvascutyedbmuzfl4yzu`)
System items (verified 2026-06-17). `→` notes the planned target from the design spec.

| Item | `op_ref` (key fields) | Tag | Purpose | Consumed by (everywhere the value is set) |
|---|---|---|---|---|
| `OP_SERVICE_ACCOUNT_TOKEN` | `/credential` | bootstrap | The 1Password SA token; resolves all other refs. **Not itself op://-resolvable.** | `~/.zshrc`, `~/.zshenv`; `com.schnapp.environment` (launchctl setenv); `op-wrap.sh`; GH Actions repo secrets (per repo); **Render `op-mcp` env** |
| `GITHUB_PAT` | `/token` | github | GitHub PAT (all-repos/all-perms; shared — see spec Accepted risks) | `gh` CLI (op plugin); Next.js web routes (Actions dispatch); mac-mcp; github-mcp |
| `OP_MCP_BEARER` | `/credential` | mcp | Static bearer gating the op-mcp connector `/mcp` (portal → Render origin) | Render `op-mcp` env; Cloudflare portal `mcp.schnapp.bet` Custom header `Authorization: Bearer …`. **Clients reach the portal over OAuth** (Mac desktop / claude.ai / iPhone hold no static bearer — `config.json` `oauth:tokenCache`); a direct `op-mcp.onrender.com` off-Mac client would also use this bearer (none configured) |
| `MCP Tokens` `(split DONE)` | legacy `/schnapp_mac` `/schnapp_github` | mcp | Original combined item; **split into the two dedicated items below** (still holds the pre-split fields; superseded as the live source) | superseded → see `MAC_MCP_AUTH_TOKEN` / `GITHUB_MCP_AUTH_TOKEN` rows |
| `MAC_MCP_AUTH_TOKEN` | `/credential` | mcp | Static bearer gating the **mac-mcp** server `/mcp` (:8765) | **Mac**: mac-mcp server env (`op-wrap.sh` resolves `~/mac-mcp/.env.template`, cwd `~/mac-mcp`); restart `com.schnapp.macmcp`. **Owner (CLIENT)**: claude.ai connector `mac-mcp.schnapp.bet` → Authorization Bearer (or the Cloudflare One MCP portal entry fronting it). NOTE: `~/obsidian-mcp/.env.template` also injects this var, but the OAuth obsidian server (:8767) **ignores it** (vestigial — server reads no `*_AUTH_TOKEN`); not a functional consumer |
| `GITHUB_MCP_AUTH_TOKEN` | `/credential` | mcp | Static bearer gating the **github-mcp** server `/mcp` (:8766) | **Mac**: github-mcp server env (`op-wrap.sh` resolves `~/github-mcp/.env.template`, cwd `~/github-mcp`); restart `com.schnapp.githubmcp`. **Owner (CLIENT)**: the Copilot / github-mcp client bearer |
| `Anthropic` `→ dissolve` | `/api_key` (live), `/CLAUDE_CODE_OAUTH_TOKEN`, `/password` (empty), `/schnapps-mbp-brain-agent` (stale dup) | llm | `api_key` = Obsidian brain-agent Anthropic key | `api_key`: `com.schnapp.brain-watcher` → `brain_agent.py` (as `ANTHROPIC_API_KEY`) |
| `Claude Code` | `/oauth_token` | llm | Claude Code OAuth token (dup of `Anthropic/CLAUDE_CODE_OAUTH_TOKEN`) | Claude Code auth |
| `Database` | `/server` `/database` `/username` `/password` `/trust_cert` `/mssql_sa_password` `→ split MSSQL_SA_PASSWORD` | db | SQL Server (Docker/Colima) connection | ETL, grading, Flask, Next.js web, mac-mcp `sql_query` |
| `Web App` `→ split` | secrets: `/admin_passcode` `/admin_refresh_code` `/auth_token_secret` `/odds_api_key` `/runner_api_key` `/sql_connection_string`; config: `/hostname` `/node_env` `/port_prod` `/port_dev` `/runner_url` `/runner_url_dev` `→ WEB_APP_CONFIG` | config | Production Next.js app secrets + non-secret config | Next.js web app; web↔Flask runner dispatch |
| `Webshare Proxy` | `/host` `/port` `/username` `/password` `/proxy_url` | proxy | NBA scraping proxy | NBA ETL (`NBA_PROXY_URL`) |
| `Cloudflare Tunnel` | `/tunnel_id` `/account_tag` `/tunnel_secret` `/argo_token` `/config_path` `/credentials_path` | cloudflare | cloudflared tunnel for Mac infra | `cloudflared` on the Mac |
| `GitHub Actions Runner` | `/agent_name` `/agent_id` `/pool_id` `/pool_name` `/client_id` `/runner_location` `/github_url` `/label` | github | Self-hosted runner registration | mac runner registration |
| `Dropbox` | `/DROPBOX_APP_KEY` `/DROPBOX_APP_SECRET` `/DROPBOX_REFRESH_TOKEN` | config | Dropbox app OAuth creds | Dropbox integration |
| `QUICKBASE_EXCEL_SYNC` | `/credential` | etl | Quickbase ETL API | Quickbase ETL |
| `GitHub SSH Key` | keys | github | git over SSH | git |
| _(to create)_ `CLOUDFLARE_API_TOKEN` | `/credential` | cloudflare | Scoped Cloudflare User API Token for the Cloudflare MCP connector | Cloudflare MCP connector |

Personal (non-system, untouched): `Elgato`, `Obsidian`, `Schnapp's MacBook Pro`.

## Bootstrap + connector secrets (NOT `op://`-resolvable — they ARE the keys)
- `OP_SERVICE_ACCOUNT_TOKEN` — the SA token; set directly in each surface's env (see table row).
- `OP_MCP_BEARER` — op-mcp bearer; generate (`openssl rand -hex 32`),
  store in 1Password, set as Render env + Cloudflare portal header.

## Status (2026-06-17)
- **Off-Mac op-mcp connector: UP (verified 2026-06-17).** After the Render
  `OP_SERVICE_ACCOUNT_TOKEN` was updated to the current SA + redeployed, `op_health` →
  `authenticated` (integration `claude-kit-op-mcp`, 1 vault).
- **Mac path: restored.** Shell SA valid (`op whoami` → SERVICE_ACCOUNT); `com.schnapp.macmcp`
  restarted to clear its stale in-process token (decisions/0010).
- **GitHub Actions:** PAT widened to all repos; `OP_SERVICE_ACCOUNT_TOKEN` secret set on authorized
  repos (incl. `af-invoice-parser`, `af-query-api`). `DB_Storage`, `appfolio-marketing-project`
  still unset — awaiting owner decision.

## Changelog (append-only; the where-to-change log for every rename/rotation)
| date | change | locations updated | done |
|---|---|---|---|
| 2026-06-17 | Map upgraded to canonical inventory; SA item title corrected `Service Account Auth Token: schnapp-automation` → `OP_SERVICE_ACCOUNT_TOKEN` | this doc | ✓ |
| 2026-06-17 | `CONNECTOR_AUTH_TOKEN` → `OP_MCP_BEARER` | repo (src+dist, render.yaml, Dockerfile, fly.toml, .env.template, DEPLOY.md, README, map); 1P item title; Render env key + redeploy. **Verified: `op_health` green on the new name.** | ✓ |
| 2026-06-22 | Phase 3B prereq (rename residual): repointed deployed `server.py` symlinks from the dead `~/code/claude-kit/connectors/*` → `~/code/schnapp-os/connectors/*` for mac-mcp / github-mcp / obsidian-mcp (a restart would have crash-looped all three on ENOENT) | `~/{mac-mcp,github-mcp,obsidian-mcp}/server.py` (Mac) | ✓ |
| 2026-06-22 | **Rotated `MAC_MCP_AUTH_TOKEN`** (leaked → fresh `openssl rand -hex 32`, non-echoing) | 1P item `MAC_MCP_AUTH_TOKEN/credential` (concealed); restarted `com.schnapp.macmcp` (+`com.schnapp.obsidian-mcp`, vestigial injector). **Verified Mac**: `:8765` new bearer → HTTP 200, bogus → 401. **OWNER PENDING (client)**: claude.ai connector `mac-mcp.schnapp.bet` Authorization Bearer = `op://web-variables/MAC_MCP_AUTH_TOKEN/credential` | ~ |
| 2026-06-22 | **Rotated `GITHUB_MCP_AUTH_TOKEN`** (leaked → fresh `openssl rand -hex 32`, non-echoing) | 1P item `GITHUB_MCP_AUTH_TOKEN/credential` (concealed); restarted `com.schnapp.githubmcp`. **Verified Mac**: `:8766` new bearer → HTTP 200, bogus → 401. **OWNER PENDING (client)**: set the github-mcp client bearer (Copilot config) = `op://web-variables/GITHUB_MCP_AUTH_TOKEN/credential` | ~ |
| 2026-06-23 | **Rotated `OP_MCP_BEARER`** (leaked → fresh `openssl rand -hex 32`, non-echoing) | 1P item `OP_MCP_BEARER/credential` (concealed). Owner propagated: (1) Render `op-mcp` env + redeploy ✓; (2) Cloudflare portal `mcp.schnapp.bet` `op-mcp` Custom header `Authorization: Bearer …` ✓; (3) Code/Cowork direct-bearer client = **N/A** — this/claude.ai/iPhone reach op-mcp via the portal over **OAuth** (no static client bearer; only applies to an off-Mac client hitting `op-mcp.onrender.com` directly, none configured). **Verified**: `op_health` authenticated; origin `/health` 200, `/mcp` new bearer 200, bogus 401 | ✓ |
