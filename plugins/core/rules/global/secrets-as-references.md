---
scope: global
updated: 2026-06-03
---
# Secrets are references, never values

- Never write a secret value into any tracked file (code, config, memory, docs, handoffs).
- Store the reference: an `op://vault/item/field` URI, the vault/item name, or which
  connector serves it. Values resolve at runtime via 1Password / MCP.
- New env vars appear in `.env.template` as `op://` URIs, never as literals.
- If you spot a hardcoded credential, stop and flag it. A public repo has leaked secrets
  before, so this rule is not optional.
