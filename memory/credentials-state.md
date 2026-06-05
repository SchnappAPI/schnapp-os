---
name: credentials-state
metadata: 
  node_type: memory
  scope: global
  source: "decisions/0001, decisions/0004, handoffs/004"
  updated: 2026-06-05
  supersedes: ""
  originSessionId: 33c726f1-b86d-4a93-8586-061ec9ca3f3e
---

1Password Service Account was deleted, then **rotated** on 2026-06-03; `op whoami` and
`gh` work again on the Mac (and in-session). The SA token resolves `op://` references.

Off-Mac secret access is **LIVE (2026-06-05)**. The **op-mcp connector**
(`connectors/op-mcp/`) is deployed on **Render** at `https://op-mcp.onrender.com` (bearer-gated).
- **claude.ai + iPhone**: registered as a custom connector via a **Cloudflare MCP server portal**
  (`https://mcp.schnapp.bet/mcp`, Managed OAuth) — verified: `op_health` authenticates from
  claude.ai (Integration `claude-kit-op-mcp`, vault visible), Mac uninvolved.
- **Claude Code + Cowork**: point at `https://op-mcp.onrender.com/mcp` with the bearer header.
- The Mac `op_*` MCP tools remain the backup path. Full runbook: `connectors/op-mcp/DEPLOY.md`.

GitHub Actions: PAT widened to all repos 2026-06-03; `OP_SERVICE_ACCOUNT_TOKEN` secret now set
on all previously-tracked repos incl. `af-invoice-parser` + `af-query-api`. Two repos
(`DB_Storage`, `appfolio-marketing-project`) still lack it — never explicitly scoped; awaiting
owner decision before distributing the master token there.

References only — no token values live in any tracked file
([secrets-as-references](../plugins/core/rules/global/secrets-as-references.md)).
