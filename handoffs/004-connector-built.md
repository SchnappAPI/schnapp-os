# Handoff 004 — Part 4.2 off-Mac 1Password connector BUILT + verified

Date: 2026-06-03.

## State
Part 4.2 connector is built and locally verified. The only remaining Part 4 work
is **owner-gated deploy + claude.ai registration** (needs a host account and the
claude.ai Settings UI). Work continued to Part 5 in the same session.

## What changed
- New `connectors/op-mcp/` — Node streamable-HTTP MCP server (TypeScript).
  - Stack: `@modelcontextprotocol/sdk` + `express` + `@1password/sdk` (Service Account).
  - Tools (all read-only): `op_read` (resolve `op://v/i/f`), `op_list_vaults`,
    `op_list_items`, `op_health`. `op_run`/`op_inject` omitted on purpose (no remote
    command execution).
  - Auth: bearer gate (`CONNECTOR_AUTH_TOKEN`); server refuses to start unless both
    `OP_SERVICE_ACCOUNT_TOKEN` and `CONNECTOR_AUTH_TOKEN` are set. `/health` is open.
  - Deploy: portable `Dockerfile`; `fly.toml` for the recommended Fly.io Node host.
  - Files: `src/{index,tools,onepassword,auth,constants}.ts`, `scripts/verify-sdk.ts`,
    `README.md`, `.env.template`, `.gitignore`, `.dockerignore`. node_modules/dist gitignored.
- `decisions/0004` updated: host fork CLOSED. `@1password/sdk-core@0.4.0` ships only the
  wasm-bindgen Node target (`fs.readFileSync` + sync `WebAssembly.Module`), so Workers
  (even nodejs_compat) is ruled out → Node host. Includes the claude.ai auth options.

## Verified (evidence)
- `npm run build` clean under strict TS; `dist/index.js` correct.
- `npm run verify` PASS: SDK runs in Node, SA authenticates, vault `web-variables` visible (16 items).
- Live HTTP (`:3939`): `/health` ok; `tools/list` returns 4 tools; `tools/call` for
  op_health (`{authenticated:true,vaultCount:1}`), op_list_vaults, op_list_items work;
  401 without bearer; clean input-validation + resolve errors; `op_read` resolve path
  exercised end-to-end (value masked).

## Owner-gated remainder of Part 4 (cannot be done autonomously)
1. Deploy: `cd connectors/op-mcp && fly launch --no-deploy --copy-config` then
   `fly secrets set OP_SERVICE_ACCOUNT_TOKEN=... CONNECTOR_AUTH_TOKEN=$(openssl rand -hex 32)`
   (save the bearer to 1Password), `fly deploy`; confirm `GET /health`. (Or Render/Railway/
   Cloudflare Container — all build from the Dockerfile.)
2. claude.ai auth front: Cloudflare Access / OAuth proxy (recommended) OR add an OAuth wrapper.
   Register `https://<app>/mcp` in claude.ai Settings > Connectors. Add to Code/Cowork mcp
   config with `Authorization: Bearer <token>`.
3. Verify PLAN check 7: resolve a secret from claude.ai with the **Mac OFF**.
4. Still pending from before: widen the GitHub fine-grained PAT to All repos, then set the
   `OP_SERVICE_ACCOUNT_TOKEN` Actions secret on `af-invoice-parser` and `af-query-api` (other 8 done).

## Next in order
Part 5 (two-lane memory): `autoMemoryDirectory` → repo path; one-fact-one-file +
supersede-not-append; SessionStart freshness gate; Stop/SessionEnd writes memory + handoff;
dual-altitude promotion (seed perf examples). Then 2.2, 6, 7, 8, 9, 10, 11.

## Resume prompt
"Resume claude-kit. Working dir ~/code/claude-kit. Read PLAN.md, PROGRESS.md, and the latest
handoffs. Connector (Part 4.2) is built + verified; deploy is owner-gated (handoff 004).
Continue from Part 5 in order. Act autonomously, handoff at each part boundary, commit and push."
