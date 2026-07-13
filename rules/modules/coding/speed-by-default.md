---
module: coding/speed-by-default
updated: 2026-07-13
---
# Speed by default

General performance principles for data/ETL work; Python/SQL-specific, so it loads on demand
like the other coding modules. Project-specific instances (which table, which endpoint) live
in the project lane and link back here.

- Read once, pass the result. Do not re-read the same source twice in one run.
- Cache expensive reads within a single run using a module-level dict, not repeated queries.
- Use a thread pool (e.g. ThreadPoolExecutor) for concurrent I/O across independent endpoints.
- Prefer set-based SQL (a CTE) over Python iteration for aggregation or windowing.
- Bulk insert over row-by-row loops. Set `fast_executemany=True` on ODBC connections.
- Reach for these when doing similar work in any repo; adapt the specifics to the data.
