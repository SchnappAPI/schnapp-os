---
scope: global
updated: 2026-06-03
---
# Naming discipline (language-independent)

- Spell names out. Do not abbreviate: `galPerUnitPerDay` not `gpud`, `maxRetries` not `mxr`.
- Treat multi-letter acronyms as ordinary words in compound names: `HttpClient`,
  `ApiResponse`, `parseJson`, `load_csv_file`. Avoids `HTTPSConnection` vs `HttpsConnection`.
- No spaces, pause-hyphens, or special characters in identifiers or filenames, except where a
  language's filename convention calls for hyphens (see the language modules).
- Dates in filenames use ISO 8601: `YYYY-MM-DD` (e.g. `2026-06-03-backfill.parquet`).

Per-language casing and file rules live in `rules/modules/lang/` and load only for matching
files, so conventions never leak across languages.
