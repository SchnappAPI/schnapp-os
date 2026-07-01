---
module: coding/error-handling
updated: 2026-06-03
---
# Error handling

- Fail loud, never silent. In scheduled or unattended jobs (GitHub Actions, LaunchAgents), a
  crash that alerts you beats a caught error that writes partial or empty data and hides it.
- Never write partial results on partial failure. A run either produces a complete, valid
  result or it errors out cleanly without writing.
- Log every error with enough context to diagnose without re-running: what failed, the
  inputs involved, and the source.
