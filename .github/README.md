# .github/ - CI gates and Mac-independent crons

Each workflow's header comment is its contract. The split: push gates keep the repo honest;
crons watch what a sleeping Mac cannot.

- `freshness.yml` (push + PR) - the hard gate: regenerates CATALOG.md + handoffs/README.md and
  fails on drift, checks `last-verified:` docs, runs every `scripts/tests/*` self-test,
  check-links, secret scan, plist syntax.
- `ci-lint.yml` (push + PR) - writing-style gate (no em dashes in live files).
- `scheduled-routines.yml` (nightly cron) - read-only report: doc freshness, stray-branch sweep,
  vault stale-facts (needs `VAULT_READ_TOKEN` secret, else SKIP), learning-loop eval, open owner
  items from the live handoff. Logic in
  [scheduled-tasks/run-ci-routines.sh](../scheduled-tasks/run-ci-routines.sh).
- `mac-liveness.yml` (cron) - dead-man's-switch: proves the Mac platform is alive; issue on DOWN.
- `render-health.yml` (cron) - keep-warm + liveness for the Render-hosted connectors (op-mcp,
  memory-mcp); issue on DOWN.

Mac-side scheduled work (LaunchAgents) is specified in
[scheduled-tasks/](../scheduled-tasks/), not here.
