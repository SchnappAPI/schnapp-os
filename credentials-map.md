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
| `MEMORY_MCP_BEARER` | `/credential` | mcp | Static bearer gating the **memory-mcp** connector `/mcp` (cross-surface memory over the git-tracked lane) | Render `memory-mcp` env (`MEMORY_MCP_BEARER`); Cloudflare portal `mcp.schnapp.bet` (memory-mcp server, Custom header, User-auth OFF). **DEPLOYED + LIVE 2026-06-23** — origin `memory-mcp-rtad.onrender.com`; claude.ai/iPhone via the shared portal (OAuth) |
| `SCHNAPP_OS_PAT` | `/credential` | github | Least-privilege GitHub token for memory-mcp: contents R/W on `SchnappAPI/schnapp-os` only (fine-grained PAT; owner created 2026-06-23). **Field is `/credential`, NOT `/token` — verified 2026-06-26 (value is set); the earlier `/token` note was wrong** | Render `memory-mcp` env var **`GITHUB_TOKEN`** (the var name the code reads; the credential's identity is `SCHNAPP_OS_PAT`) |
| ~~`MCP Tokens`~~ `DELETED 2026-06-26` | — | mcp | Legacy combined bearers; drained + deleted in the flatten. Live bearers are the two dedicated items below | — (→ `MAC_MCP_AUTH_TOKEN` / `GITHUB_MCP_AUTH_TOKEN`) |
| `MAC_MCP_AUTH_TOKEN` | `/credential` | mcp | Static bearer gating the **mac-mcp** server `/mcp` (:8765) | **Mac**: mac-mcp server env (`op-wrap.sh` resolves `~/mac-mcp/.env.template`, cwd `~/mac-mcp`); restart `com.schnapp.macmcp`. **Owner (CLIENT)**: claude.ai connector `mac-mcp.schnapp.bet` → Authorization Bearer (or the Cloudflare One MCP portal entry fronting it). NOTE: `~/obsidian-mcp/.env.template` also injects this var, but the OAuth obsidian server (:8767) **ignores it** (vestigial — server reads no `*_AUTH_TOKEN`); not a functional consumer |
| `GITHUB_MCP_AUTH_TOKEN` | `/credential` | mcp | Static bearer gating the **github-mcp** server `/mcp` (:8766) | **Mac**: github-mcp server env (`op-wrap.sh` resolves `~/github-mcp/.env.template`, cwd `~/github-mcp`); restart `com.schnapp.githubmcp`. **Owner (CLIENT)**: the Copilot / github-mcp client bearer |
| `ANTHROPIC_API_KEY` | `/credential` | llm, obsidian | Anthropic API key (Obsidian brain-agent); split from the dissolved `Anthropic` item 2026-06-26 | `com.schnapp.brain-watcher` → `brain_agent.py` (as `ANTHROPIC_API_KEY`); ref in OneDrive `Obsidian/.github/.env.template` + schnapp-bet/web-bad `refresh-data.yml` |
| `CLAUDE_CODE_OAUTH_TOKEN` | `/credential` | llm | Claude Code OAuth token (canonical; dedup of old `Claude Code/oauth_token` + `Anthropic/CLAUDE_CODE_OAUTH_TOKEN`); 2026-06-26 | Claude Code auth; schnapp-bet `claude.yml` |
| `Database` `(kept bundle)` | `/server` `/database` `/username` `/password` `/trust_cert` | db | SQL Server (Docker/Colima) connection — co-required set. `mssql_sa_password` split out 2026-06-26 | ETL, grading, Flask, Next.js web, mac-mcp `sql_query` (~18 schnapp-bet workflows read `/server`,`/database`,`/username`,`/password`) |
| `MSSQL_SA_PASSWORD` | `/credential` | db | SQL Server SA login (distinct from app user); split from `Database` 2026-06-26 | schnapp-bet/web-bad `.env.template` |
| `ADMIN_PASSCODE` · `ADMIN_REFRESH_CODE` · `AUTH_TOKEN_SECRET` · `ODDS_API_KEY` · `RUNNER_API_KEY` · `SQL_CONNECTION_STRING` | each `/credential` | web | Next.js app secrets; split from the dissolved `Web App` item 2026-06-26 (flatten-only — values still the un-rotated leaked ones) | Next.js web app; web↔Flask runner; schnapp-bet `.env.template` + workflows (`ODDS_API_KEY` in 8 workflows) |
| `WEB_APP_CONFIG` | `/hostname` `/node_env` `/port_prod` `/port_dev` `/runner_url` `/runner_url_dev` | config | Non-secret Web App config (ports/urls/host); split from `Web App` 2026-06-26 (Secure Note) | Next.js web app; schnapp-bet `.env.template` (`runner_url`,`runner_url_dev`) |
| `Webshare Proxy` | `/host` `/port` `/username` `/password` `/proxy_url` | proxy | NBA scraping proxy | NBA ETL (`NBA_PROXY_URL`) |
| `Cloudflare Tunnel` | `/tunnel_id` `/account_tag` `/tunnel_secret` `/argo_token` `/config_path` `/credentials_path` | cloudflare | cloudflared tunnel for Mac infra | `cloudflared` on the Mac |
| `GitHub Actions Runner` | `/agent_name` `/agent_id` `/pool_id` `/pool_name` `/client_id` `/runner_location` `/github_url` `/label` | github | Self-hosted runner registration | mac runner registration |
| `Dropbox` | `/DROPBOX_APP_KEY` `/DROPBOX_APP_SECRET` `/DROPBOX_REFRESH_TOKEN` | config | Dropbox app OAuth creds | Dropbox integration |
| `QUICKBASE_EXCEL_SYNC` | `/credential` | etl | Quickbase ETL API | Quickbase ETL |
| `GitHub SSH Key` | keys | github | git over SSH | git |
| `CLOUDFLARE_API_TOKEN` | `/credential` `/account_id` `/access_key_id` `/secret_access_key` `/s3_endpoint` | cloudflare | Broad-scope Cloudflare **account** API token (created 2026-06-27) + its auto-derived R2 S3 credentials (same token; S3 keys appear because R2 perms were included). Distinct item from `Cloudflare Tunnel` (which is cloudflared runtime plumbing). | Cloudflare MCP connector; R2 S3 API |

Personal (non-system, untouched): `Elgato`, `Obsidian`, `Schnapp's MacBook Pro`.

## Bootstrap + connector secrets (NOT `op://`-resolvable — they ARE the keys)
- `OP_SERVICE_ACCOUNT_TOKEN` — the SA token; set directly in each surface's env (see table row).
- `OP_MCP_BEARER` — op-mcp bearer; generate (`openssl rand -hex 32`),
  store in 1Password, set as Render env + Cloudflare portal header.

## Status — see the canonical source (do not hardcode mutable status here)
Live credential / rotation status goes stale if pinned in this doc, so it is NOT kept here.
Canonical, supersede-on-change: [`memory/credentials-state.md`](memory/credentials-state.md)
(SA + MCP-bearer rotation state, what is verified, what is owner-pending). The append-only
**Changelog** below is the where-to-change record for every rename/rotation.

## Changelog (append-only; the where-to-change log for every rename/rotation)
| date | change | locations updated | done |
|---|---|---|---|
| 2026-06-17 | Map upgraded to canonical inventory; SA item title corrected `Service Account Auth Token: schnapp-automation` → `OP_SERVICE_ACCOUNT_TOKEN` | this doc | ✓ |
| 2026-06-17 | `CONNECTOR_AUTH_TOKEN` → `OP_MCP_BEARER` | repo (src+dist, render.yaml, Dockerfile, fly.toml, .env.template, DEPLOY.md, README, map); 1P item title; Render env key + redeploy. **Verified: `op_health` green on the new name.** | ✓ |
| 2026-06-22 | Phase 3B prereq (rename residual): repointed deployed `server.py` symlinks from the dead `~/code/claude-kit/connectors/*` → `~/code/schnapp-os/connectors/*` for mac-mcp / github-mcp / obsidian-mcp (a restart would have crash-looped all three on ENOENT) | `~/{mac-mcp,github-mcp,obsidian-mcp}/server.py` (Mac) | ✓ |
| 2026-06-22 | **Rotated `MAC_MCP_AUTH_TOKEN`** (leaked → fresh `openssl rand -hex 32`, non-echoing) | 1P item `MAC_MCP_AUTH_TOKEN/credential` (concealed); restarted `com.schnapp.macmcp` (+`com.schnapp.obsidian-mcp`, vestigial injector). **Verified Mac**: `:8765` new bearer → HTTP 200, bogus → 401. **OWNER PENDING (client)**: claude.ai connector `mac-mcp.schnapp.bet` Authorization Bearer = `op://web-variables/MAC_MCP_AUTH_TOKEN/credential` | ~ |
| 2026-06-22 | **Rotated `GITHUB_MCP_AUTH_TOKEN`** (leaked → fresh `openssl rand -hex 32`, non-echoing) | 1P item `GITHUB_MCP_AUTH_TOKEN/credential` (concealed); restarted `com.schnapp.githubmcp`. **Verified Mac**: `:8766` new bearer → HTTP 200, bogus → 401. **OWNER PENDING (client)**: set the github-mcp client bearer (Copilot config) = `op://web-variables/GITHUB_MCP_AUTH_TOKEN/credential` | ~ |
| 2026-06-23 | **Rotated `OP_MCP_BEARER`** (leaked → fresh `openssl rand -hex 32`, non-echoing) | 1P item `OP_MCP_BEARER/credential` (concealed). Owner propagated: (1) Render `op-mcp` env + redeploy ✓; (2) Cloudflare portal `mcp.schnapp.bet` `op-mcp` Custom header `Authorization: Bearer …` ✓; (3) Code/Cowork direct-bearer client = **N/A** — this/claude.ai/iPhone reach op-mcp via the portal over **OAuth** (no static client bearer; only applies to an off-Mac client hitting `op-mcp.onrender.com` directly, none configured). **Verified**: `op_health` authenticated; origin `/health` 200, `/mcp` new bearer 200, bogus 401 | ✓ |
| 2026-06-23 | Phase 3B security fix (found mid-rotation): `~/Library/LaunchAgents/com.schnapp.macmcp.plist` had been clobbered to a bare JSON `ProgramArguments` array (no `Label`/`WorkingDirectory`) → a reboot would start macmcp with cwd `/` and empty `MCP_TOKEN` = **bearer auth disabled / exposed**, or fail to load. Rewrote it as a proper secrets-free op-wrap `<dict>` matching the live loaded job (lint OK, cwd `~/mac-mcp`, 0 secret patterns). Not reloaded (running job healthy + verified); activates next reboot/reload | `~/Library/LaunchAgents/com.schnapp.macmcp.plist` (Mac); clobbered copy saved `.jsonarray-bak-20260623` | ✓ |
| 2026-06-23 | ⚠️ Found plaintext-secrets file `~/Library/LaunchAgents/com.schnapp.macmcp.plist.bak.20260524-105649` (the pre-op-wrap design): hardcoded `MAC_MCP_AUTH_TOKEN` (`…6267`, now **dead** post-rotation), `GH_PAT`, `RUNNER_API_KEY` | OWNER: `rm` the `.bak` (plain terminal; destructive-guard blocks me); `GITHUB_PAT` + `RUNNER_API_KEY` join the owner-console rotation set (`RUNNER_API_KEY` = Web App `/runner_api_key`). `RUNNER_API_KEY` value transited this session transcript (redaction gap) → rotate | ~ |
| 2026-06-23 | `.bak` removal **VERIFIED done** (file no longer on disk). | n/a (owner removed) | ✓ |
| 2026-06-23 | **`service_status` redaction fix** — the Mac MCP `service_status` tool returned raw `launchctl print` output incl. the process's `inherited environment`, leaking the live `OP_SERVICE_ACCOUNT_TOKEN` into this session transcript. Added `_redact_secrets()` (scrubs secret-named env keys + `ops_/sk-ant-/ghp_/github_pat_/eyJ` token formats). | `connectors/mac-mcp/server.py` (repo + deployed `~/mac-mcp` symlink); **restart `com.schnapp.macmcp` to apply**. SA re-rotation = owner decision (token hit the transcript) | ✓ (applied) |
| 2026-06-23 | **Created `MEMORY_MCP_BEARER`** (`openssl rand -hex 32`, non-echoing) for the new memory-mcp connector | 1P item `MEMORY_MCP_BEARER/credential` (web-variables). **DEPLOYED + VERIFIED cross-surface 2026-06-23:** memory-mcp on Render (`memory-mcp-rtad.onrender.com`; env `GITHUB_TOKEN` = fine-grained PAT `SCHNAPP_OS_PAT` + `MEMORY_MCP_BEARER`); added to the `mcp.schnapp.bet` portal (User-auth OFF); claude.ai "1Password" connector reconnected → 11 tools; `memory_health` from web = authenticated, 10 files. FOLLOW-UP: confirm the `SCHNAPP_OS_PAT` value is stored in 1P (`op://web-variables/SCHNAPP_OS_PAT/token`) so the ref + `/rotate-secret` resolve. | ✓ |
| 2026-06-26 | **FLATTEN Phase A (additive, owner-directed, supersedes the 0011 deferral):** created 10 split items in `web-variables`, values copied from the bundles (no rotation — flatten-only): `ADMIN_PASSCODE`, `ADMIN_REFRESH_CODE`, `AUTH_TOKEN_SECRET`, `ODDS_API_KEY`, `RUNNER_API_KEY`, `SQL_CONNECTION_STRING` (← `Web App`); `WEB_APP_CONFIG` (non-secret `Web App` config, Secure Note); `MSSQL_SA_PASSWORD` (← `Database`); `ANTHROPIC_API_KEY` (← `Anthropic/api_key`); `CLAUDE_CODE_OAUTH_TOKEN` (← `Claude Code/oauth_token`, dedup). All resolve (verified char-counts). Old bundles UNTOUCHED → nothing broken. Repointed schnapp-os `.env.template` + `connectors/obsidian-mcp/README.md` to the new items. | 1P (10 new items); `schnapp-os/.env.template`; `obsidian-mcp/README.md` | ~ |
| 2026-06-26 | **FLATTEN Phase B+C DONE.** Repointed every live consumer (verified, value-free) then deleted the drained bundles. Repointed: schnapp-bet `.env.template`+`claude.yml`+`nba-backfill.yml`+7 more workflows+`docs/CONNECTIONS.md` (23 refs, committed `c626196`, pushed); `web-bad` (stale local clone of schnapp-bet remote — repointed, NOT committed; its workflows don't run); `obsidian-vault/.github/.env.template` (committed+pushed); **brain-watcher's live `OneDrive/Obsidian/.github/.env.template`** (edited on disk — separate file from the repo, would have broken brain-agent if missed); schnapp-os manifest+README (committed+pushed). `Database/{server,database,username,password,trust_cert}` untouched → ~18 ETL workflows unchanged. Deleted (each after a 0-ref grep guard across all repos+OneDrive): `Web App`, `Anthropic`, `Claude Code`, `MCP Tokens`, `GitHub`; removed `Database/mssql_sa_password` field. **Verified:** vault = 27 items, all new refs + `Database` core resolve, 5 bundles return not-found. Writes ran via MacOS-MCP `Shell` + `zsh -lic` (login-profile SA token). | 1P vault; schnapp-bet, obsidian-vault, schnapp-os (pushed); OneDrive brain-watcher env | ✓ |
| 2026-06-27 | **ROTATION — owner ACCEPTED residual risk, CLOSED as won't-do.** Flatten copied (did not rotate) values; all split secrets still hold the leaked 2026-05 values (`Web App`→6, `Database`+`MSSQL_SA_PASSWORD`, `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, plus `GITHUB_PAT`, Webshare, Cloudflare). Owner reviewed exposure 2026-06-27: `obsidian-vault` is PRIVATE (not public) though plaintext secrets remain in 30+ pushed export files; judged audience acceptable, declined rotation + scrub. Reopen only on new exposure (repo public / third-party access). Still worth a glance: `ADMIN_REFRESH_CODE` copied as 2 chars. See [[credential-leak-2026-06-17]]. | decision recorded | ✓ |
