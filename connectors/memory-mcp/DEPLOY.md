# Deploy memory-mcp

**DONE + LIVE 2026-06-23**: origin `memory-mcp-rtad.onrender.com`, behind the shared Cloudflare portal
`mcp.schnapp.bet`. Verified from claude.ai web: `memory_health` authenticated, `memory_index` returned the
lane. Kept below as the reproducible runbook / re-deploy reference.

The cross-surface memory server. Hosted off-Mac (always-on) like `op-mcp`, so claude.ai / iPhone /
Cowork reach the same memory lane the Mac does. Steps tagged **🖐️ YOU** (a console only you can reach)
vs **🤖 / terminal** (runnable). Effects: a deployed Render service + a custom connector.

## 1. Mint the two secrets

**GitHub token** (`GITHUB_TOKEN`) - least privilege beats reuse:
- 🖐️ **Recommended:** github.com → Settings → Developer settings → **Fine-grained PAT** → repository
  access = *Only* `SchnappAPI/schnapp-os` → Repository permissions → **Contents: Read and write** →
  Metadata stays Read. Generate. Store in 1Password as a new item named `SCHNAPP_OS_PAT`, ref
  `op://web-variables/SCHNAPP_OS_PAT/token`. (That is the credential's name; the Render env var that
  HOLDS it stays `GITHUB_TOKEN` - the name the server code reads.)
- Or reuse the existing `op://web-variables/GITHUB_PAT/token` (broader scope - all repos/perms;
  simpler, but a bigger blast radius if the server is compromised). The map's `consumed_by` must then
  list memory-mcp so a `GITHUB_PAT` rotation updates it.

**Bearer gate** (`MEMORY_MCP_BEARER`) - generate and store without echoing:
```bash
val=$(openssl rand -hex 32)
op item create --category "API Credential" --title "MEMORY_MCP_BEARER" --vault web-variables "credential=$val"
unset val   # ref: op://web-variables/MEMORY_MCP_BEARER/credential
```

## 2. Deploy on Render (🖐️ YOU - no Render API key on the Mac)

- New **Web Service** from the `SchnappAPI/schnapp-os` repo, **Root Directory** `connectors/memory-mcp`,
  runtime **Docker** (the `Dockerfile` is self-contained).
- Environment variables:
  - `GITHUB_TOKEN` = the PAT value from step 1 (paste the value; Render env is the value boundary).
  - `MEMORY_MCP_BEARER` = the bearer value from step 1.
  - (optional) `MEMORY_REPO` / `MEMORY_BRANCH` / `MEMORY_DIR` - defaults `SchnappAPI/schnapp-os` / `main` / `memory`.
- Deploy. Note the service URL, e.g. `https://memory-mcp.onrender.com`.

## 3. Verify

```bash
curl -s https://<service>/health                       # {"status":"ok",...}
curl -s -X POST https://<service>/mcp \
  -H "Authorization: Bearer <MEMORY_MCP_BEARER>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'   # lists memory_* tools
# bogus bearer must return 401:
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://<service>/mcp -H "Authorization: Bearer nope" -d '{}'
```
Then call `memory_health` (via a connected client) → `{"authenticated":true,"memoryFileCount":N}`.

## 4. Register the connector

- **claude.ai / iPhone:** Settings → Connectors → Add custom connector → URL `https://<service>/mcp`.
  For OAuth, front it with the **Cloudflare One MCP portal** (same pattern as `op-mcp` →
  `mcp.schnapp.bet`) and set the portal's `Authorization: Bearer <MEMORY_MCP_BEARER>` custom header;
  clients then auth via the portal's OAuth. Direct-bearer clients pass the header themselves.
- **Claude Code / Cowork:** `claude mcp add --transport http memory https://<service>/mcp --header "Authorization: Bearer <MEMORY_MCP_BEARER>"`.

## 5. Record

Add a `memory-mcp` row to [credentials-map.md](../../credentials-map.md) `consumed_by` for both new
secrets (and append a changelog row), so `/rotate-secret` knows every leg. Update the connector
inventory wherever surfaces are tracked.

## Notes

- Each `memory_write` is **two commits** (the fact file, then the `MEMORY.md` index). A web/iPhone write
  lands on origin; the next Code-on-Mac session's freshness gate pulls it. Concurrent writes use the
  blob sha - a stale-sha conflict returns a clear "re-read and retry" error.
- Cold start: Render free tier sleeps when idle; the first call after idle can take ~50s. Expected.
