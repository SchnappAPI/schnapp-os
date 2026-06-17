# Handoff 028 — credentials archaeology + canonical map + op-mcp outage fix + OP_MCP_BEARER rename

Date: 2026-06-17. Surface: Claude Code (Mac, local). Status: COMPLETE on `main`, pushed
(commits below). Supersedes handoff 027's "op-mcp DOWN" status — the outage is RESOLVED.

## What happened (this session)
1. **Transcript archaeology** — analyzed how the 1Password setup was built across `schnapp-bet`,
   `schnapp-kit`, `claude-kit` session transcripts. Output: `docs/credentials-archaeology-2026-06-17.md`
   (history, verified item/field map, reasoning, inconsistencies). No secret values.
2. **Credential system design** (brainstorming → spec): `docs/superpowers/specs/2026-06-17-credential-system-design.md`.
   Convention: UPPER_SNAKE name = the consuming env var, identical in system+config+1P title; one
   secret per item; co-required fields bundle; tags group; metadata split (operational story in the
   1P item note, references-only index in the map); rename/rotation protocol (per-item `consumed_by`
   = where-to-change checklist + append-only changelog).
3. **Canonical map** — rebuilt `credentials-map.md` as the references-only inventory (full item
   table, `op_ref`, tags, `consumed_by`, changelog, status). Verified against live `op item list`
   2026-06-17. Fixed stale SA item title (`OP_SERVICE_ACCOUNT_TOKEN`, not the old long title).
4. **op-mcp outage RESOLVED** — root cause was stale tokens after the 2026-06-15 SA rotation. Owner
   updated Render `op-mcp` env `OP_SERVICE_ACCOUNT_TOKEN` + redeployed; Mac `com.schnapp.macmcp`
   restarted. `op_health` → authenticated. `memory/credentials-state.md` + `MEMORY.md` flipped to
   RESOLVED (kept the ROTATION GOTCHA rule).
5. **First real migration executed** — `CONNECTOR_AUTH_TOKEN → OP_MCP_BEARER` end-to-end via the
   rename protocol: repo (connector `src`+`dist`, `render.yaml`, `Dockerfile`, `fly.toml`,
   `.env.template` + its stale `op://` comment refs, `DEPLOY.md`, `README`, map, spec) + Render
   (env key + redeploy) + 1Password item title + Cloudflare (value unchanged). `op_health` verified
   green on the new name. Changelog ✓.
6. **Workflow fix** — owner switched `~/.claude/settings.json` to `permissions.defaultMode: "default"`
   + read-only/retrieval `allow` rules + `ask` = [`git push`, `launchctl kill`]. Silent auto-mode
   denials → inline approve prompts.

## Commits (all on origin/main)
- `b5be88e` archaeology + spec + canonical map
- `77495ae` outage resolved (Render token + Mac restart)
- `3441bc6` OP_MCP_BEARER rename (code+config+docs)
- `9e1fb44` changelog ✓ (rename complete + verified)
- (this handoff commits on top)

## Current verified state (2026-06-17)
- Off-Mac op-mcp: `op_health` authenticated (integration `claude-kit-op-mcp`, 1 vault). Endpoint
  `op-mcp.onrender.com`; portal `mcp.schnapp.bet/mcp`.
- Mac: shell `op whoami` valid (SERVICE_ACCOUNT, sees `web-variables`); `com.schnapp.macmcp` restarted.
- 1Password bearer item = `OP_MCP_BEARER`. Vault = `web-variables` (id `o3rjqrgvascutyedbmuzfl4yzu`).
- git `main` in sync.

## What remains — credential reorg is DESIGN-ONLY beyond the one rename (owner-scheduled)
Per the spec target inventory, not yet executed (1P vault writes are gated by the classifier as
design-deferred — owner does them or explicitly authorizes):
- **Splits:** `MCP Tokens` → `MAC_MCP_AUTH_TOKEN` + `GITHUB_MCP_AUTH_TOKEN`; `Web App` → six secret
  items + `WEB_APP_CONFIG` (non-secrets stay, owner's call); `Anthropic` → `OBSIDIAN_BRAIN_AGENT`
  (the live `api_key`, consumed by `com.schnapp.brain-watcher` → `brain_agent.py` as
  `ANTHROPIC_API_KEY`) + dedup `CLAUDE_CODE_OAUTH_TOKEN`; `Database` → split `MSSQL_SA_PASSWORD`.
- **Consolidate:** retire the old `GitHub` bundle (`pat_*`) → the one shared `GITHUB_PAT`.
- **Hygiene:** tags on every item; operational notes in each item; delete the stale
  `Anthropic/schnapps-mbp-brain-agent` field (dup of `api_key`).
- **Create:** `CLOUDFLARE_API_TOKEN` (scoped Cloudflare User API Token for the Cloudflare MCP
  connector — owner to send the connector's token-request screenshot for exact scopes).
- **Open verifications:** is `SQL_CONNECTION_STRING` just `DATABASE` re-encoded (drop if so)?
  `Anthropic/password` is empty — confirm nothing reads it before removing.
- **Accepted risk (recorded):** the shared all-repos/all-permissions `GITHUB_PAT` (owner decision).

## Method for each remaining item
Follow the rename/rotation protocol in the spec: for ONE item — update consumers → 1Password →
map + changelog, in lockstep, verify resolution after each. Never piecemeal. 1P writes need owner
approval (or owner does them in the app).

## Canonical docs
- Map (single source of truth): `credentials-map.md`
- Design + convention + target inventory + protocol: `docs/superpowers/specs/2026-06-17-credential-system-design.md`
- History: `docs/credentials-archaeology-2026-06-17.md`
- Operational state + rotation gotcha: `memory/credentials-state.md`
- Connector runbook: `connectors/op-mcp/DEPLOY.md`; decisions `0001/0002/0004`.

## Connectors to keep ON for this work (next session, lean startup)
- `op-mcp` (off-Mac 1Password) — used for verification.
- Schnapp Mac MCP (`op_run`/`op_inject`/`op_whoami`/`shell_exec`/`sql_query`).
- Everything else (GitHub MCP — git/gh via Bash covers it; Cloudflare MCP unless configuring the
  API token; Obsidian; Microsoft/Outlook/SharePoint; context7; Chrome; computer-use;
  Desktop_Commander; Apple Notes; visualize; plugin_data/design; scheduled-tasks; mcp-registry)
  can be toggled OFF — not needed for the credential reorg.
