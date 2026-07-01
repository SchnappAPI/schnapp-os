---
module: lang/github-actions
paths:
  - "**/.github/workflows/*.{yml,yaml}"
updated: 2026-06-03
---
# GitHub Actions

- Workflow filenames: kebab-case with `.yml`: `sync-odds.yml`, `mlb-backfill.yml`.
- Job and step identifiers: kebab-case or snake_case, applied consistently.
- Secrets load via `1password/load-secrets-action`; do not reference `secrets.*` directly
  except the bootstrap `OP_SERVICE_ACCOUNT_TOKEN` and `GITHUB_TOKEN`.
