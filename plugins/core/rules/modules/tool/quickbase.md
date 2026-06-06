---
module: tool/quickbase
updated: 2026-06-05
---
# Quickbase

Lane discipline for Quickbase projects: treat API responses as untrusted
(see coding/input-validation); keep table IDs (DBIDs), field IDs (FIDs), and app IDs in the
project lane, never here. Secrets (user token, realm) are `op://` references.

Integration patterns (JSON API, querying, pagination, rate limits, FID mapping, loading into
SQL Server) live in the **quickbase** skill — invoke it for the how-to, this module for the
always-on conventions.
