---
name: credentials-state
scope: global
source: decisions/0001, decisions/0004, handoffs/004
updated: 2026-06-03
supersedes: ""
---
1Password Service Account was deleted, then **rotated** on 2026-06-03; `op whoami` and
`gh` work again on the Mac (and in-session). The SA token resolves `op://` references.

Cross-surface plan: off-Mac surfaces (claude.ai, iPhone) get secrets via the **op-mcp
connector** (`connectors/op-mcp/`, built + verified; deploy owner-gated — see
[[connector-state]] / handoffs/004). The Mac `op_*` MCP tools remain the backup path.

GitHub Actions: `OP_SERVICE_ACCOUNT_TOKEN` secret is set on 8/10 SchnappAPI repos; 2
(`af-invoice-parser`, `af-query-api`) pending a wider fine-grained PAT.

References only — no token values live in any tracked file
([secrets-as-references](../plugins/core/rules/global/secrets-as-references.md)).
