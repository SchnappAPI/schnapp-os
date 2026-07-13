---
module: tool/appfolio
updated: 2026-06-05
---
# AppFolio

Lane discipline for AppFolio projects: AppFolio is an external data source - treat responses
as untrusted, validate before the DB (see coding/input-validation). Keep report names, client
subdomain, and endpoint specifics in the project lane. Secrets (API client id/secret) are
`op://` references.

Integration patterns (Reporting/Data API, pulling custom reports, pagination, column-drift
guarding, loading into SQL Server) live in the **appfolio** skill. Cell-by-cell reconciliation
of an export against another dataset lives in the **fish-compare** skill, project-scoped in
the 1st Lake work repo (not in schnapp-os) - do not duplicate it.
