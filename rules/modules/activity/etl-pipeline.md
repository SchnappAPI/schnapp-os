---
module: activity/etl-pipeline
updated: 2026-06-03
---
# ETL pipeline work

Platform context: one-person data/analytics platform. Python ETL pipelines feed a local
SQL Server 2022 database, scheduled via GitHub Actions and Mac LaunchAgents. Power Query M
is prototyping only.

Compose with: `coding/error-handling`, `coding/input-validation`, `coding/design-defaults`,
`lang/python`, `lang/sql-server`, `coding/speed-by-default`.

- Unattended runs: fail loud, alert, never write partial data (see coding/error-handling).
- Validate every external source before it touches the DB (see coding/input-validation).
- Prefer set-based SQL and bulk inserts; cache expensive reads in-run (see speed-by-default).
- Do not unify sports/domains until the shared shape is real (see coding/design-defaults).
