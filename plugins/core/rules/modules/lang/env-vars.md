---
module: lang/env-vars
paths:
  - "**/.env*"
  - "**/*.env"
  - "**/.github/workflows/*.{yml,yaml}"
updated: 2026-06-03
---
# Environment variables

- Always UPPER_SNAKE_CASE in all shells, `.env` files, and CI secrets:
  `SQL_PASSWORD`, `GITHUB_PAT`, `MAC_MCP_AUTH_TOKEN`.
- Values are never literals in tracked files. New vars appear in `.env.template` as
  `op://` URIs (see global rule `secrets-as-references`).
