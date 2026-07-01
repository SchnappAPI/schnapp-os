# op-mcp — off-Mac 1Password connector

A small remote MCP server that resolves 1Password secrets through a **Service
Account**, so claude.ai, the iPhone app, Cowork, and Claude Code can read
`op://` references **without the Mac being on**. (decisions/0004.)

## Why a Node host (not a Worker)

`@1password/sdk` depends on `@1password/sdk-core`, whose only published build is
the wasm-bindgen **Node target**. It loads its WASM with
`fs.readFileSync(__dirname + '/core_bg.wasm')` and a synchronous
`new WebAssembly.Module(bytes)` at import time. Cloudflare Workers (even with
`nodejs_compat`) has no runtime filesystem and blocks synchronous WASM compiles
from runtime buffers, so a plain/`nodejs_compat` Worker cannot run the SDK
without hacking the loader. **Verdict: run on a Node host.** This resolves the
host fork left open in `decisions/0004`.

Portable: the `Dockerfile` runs on **Render** (the chosen host — see DEPLOY.md), or
Fly.io (`fly.toml` included), Railway, Cloudflare Containers, or Cloud Run.

## Tools (all read-only — no command execution, no writes)

| Tool | Purpose | Returns |
|---|---|---|
| `op_read` | Resolve one `op://vault/item/field` reference | `{ reference, value }` |
| `op_list_vaults` | Discover vaults the SA can see | `{ count, vaults[] }` |
| `op_list_items` | List active items in a vault | `{ count, items[] }` |
| `op_health` | Confirm the SA authenticates (no secrets) | `{ authenticated, integration, vaultCount }` |

The Mac connector's `op_run` (execute a command with injected secrets) and
`op_inject` (template fill) are deliberately **omitted** — remote command
execution is not safe to expose. This connector only reads.

## Security

- Endpoint is **bearer-protected** (`Authorization: Bearer <OP_MCP_BEARER>`).
  The server refuses to start if `OP_MCP_BEARER` or
  `OP_SERVICE_ACCOUNT_TOKEN` is unset — it never runs open.
- Secrets live only in the host environment (Fly secrets, etc.), never in the
  repo or image. `.env` is gitignored; only `.env.template` is tracked.
- `op_read` returns secret values by design — only reachable past the bearer gate.

## Usage hygiene (op_read transits the value into the calling surface)

Unlike the Mac `op_*` MCP (whose `op_read` returns only proof: length + last4), this
connector's `op_read` hands back the **raw value** — it must, because off-Mac surfaces
(claude.ai / iPhone) have no other way to use a secret. Consequence: the value enters that
surface's **conversation transcript** (which may later sync to the OneDrive/Obsidian backup). So:
- Use `op_health` / `op_list_vaults` / `op_list_items` for checks — they expose no values.
- Call `op_read` only when the surface genuinely needs the value in hand.
- To *run a command* that consumes a secret, prefer the Mac's `op_run` / `op_inject` (value
  never transits the chat). Aligns with the `secrets-as-references` rule.
- If a sensitive value did transit a transcript, rotate it.

## Local run + verify

```bash
cd connectors/op-mcp
npm install
npm run build

# Prove the SDK runs and the SA authenticates (reads no secret values):
OP_SERVICE_ACCOUNT_TOKEN="$(op read op://<vault>/claude-kit-op-mcp/service-account-token)" \
  npm run verify

# Run the HTTP server locally:
OP_SERVICE_ACCOUNT_TOKEN=... OP_MCP_BEARER="$(openssl rand -hex 32)" npm start
# Smoke test (in another shell), list tools:
curl -s localhost:3000/mcp -H 'content-type: application/json' \
  -H "authorization: Bearer $OP_MCP_BEARER" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | head
```

## Deploy + register (owner step)

Full turnkey runbook: **[DEPLOY.md](DEPLOY.md)** (canonical). Chosen path —
**Render** (free, no CLI; root `render.yaml` Blueprint builds the `Dockerfile`) +
**Cloudflare MCP portal** (OAuth front, because claude.ai's custom-connector UI
accepts only OAuth 2.1, not a static bearer). Claude Code + Cowork need only the
bearer header and work the moment the host is up. Fly.io stays a drop-in
alternative (`fly.toml`) if you ever want a no-cold-start host.

The goal: with the **Mac off**, call `op_read` from claude.ai
and confirm a secret resolves — see DEPLOY.md Step 6.
