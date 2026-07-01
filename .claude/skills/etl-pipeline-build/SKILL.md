---
name: etl-pipeline-build
description: Use when building or changing a Python ETL pipeline that loads SQL Server — extract from an API / file / vendor source, transform, and upsert into SQL Server 2022. Especially when it must run unattended (GitHub Actions or a Mac LaunchAgent), be idempotent and safely re-runnable, resolve secrets from 1Password, and load fast (fast_executemany, bulk insert).
---

# etl-pipeline-build

Build the owner's standard pipeline shape: **extract → validate → transform → idempotent
bulk upsert into SQL Server 2022**, scheduled and unattended. This skill is the workflow;
the conventions live in the rules it composes — do not restate them here.

Composes: [`activity/etl-pipeline`](../../../rules/modules/activity/etl-pipeline.md),
[`lang/python`](../../../rules/modules/lang/python.md),
[`lang/sql-server`](../../../rules/modules/lang/sql-server.md),
[`lang/env-vars`](../../../rules/modules/lang/env-vars.md),
[`global/speed-by-default`](../../../rules/global/speed-by-default.md),
[`global/secrets-as-references`](../../../rules/global/secrets-as-references.md).
For T-SQL specifics use the **sql-server-patterns** skill; for source-specific work use the
**quickbase** / **appfolio** skills.

## Non-negotiables (why this skill exists)

1. **Idempotent.** A re-run loads the same data once, never duplicates. Upsert on a real key
   (MERGE or staging-table swap), never blind `INSERT`.
2. **No partial writes.** Stage, validate, then commit in one transaction. A failed run
   leaves the target unchanged (see `coding/error-handling`).
3. **Validate at the boundary.** External data is untrusted; check shape/types/row counts
   before it reaches the DB (see `coding/input-validation`).
4. **Fast by default.** Bulk insert with `fast_executemany=True`; set-based SQL over loops.
5. **Secrets are `op://` references**, resolved at runtime — never literals in code or YAML.

## Workflow

1. **Contract first.** Identify source (endpoint/file), the natural key, target table
   (plural snake_case per `lang/sql-server`), and the schedule.
2. **Extract** with retries + timeouts; page fully; fail loud on non-2xx.
3. **Validate** row count, required columns, types; reject the batch on violation.
4. **Load** into a staging table, then MERGE / swap into the target in one transaction.
5. **Schedule** via GitHub Actions (cron) or a LaunchAgent; `op run` injects env.
6. **Account** for the run: rows extracted vs upserted, runtime; log it.

## Idempotent fast upsert (the load-bearing example)

```python
import os, pyodbc

# Secret resolves at runtime via 1Password (op run -- python load.py); never a literal.
conn = pyodbc.connect(os.environ["SQLSERVER_DSN"], autocommit=False)
cur = conn.cursor()
cur.fast_executemany = True  # the single biggest pyodbc ETL speedup

try:
    # 1. Stage the validated batch (temp table mirrors target columns).
    cur.execute("SELECT TOP 0 * INTO #stage FROM dbo.player_props;")
    cur.executemany(
        "INSERT INTO #stage (event_id, market, line, updated_at) VALUES (?,?,?,?)",
        rows,  # list[tuple] — already validated upstream
    )
    # 2. Set-based MERGE on the natural key = idempotent, no row-by-row round trips.
    cur.execute("""
        MERGE dbo.player_props AS t
        USING #stage AS s ON t.event_id = s.event_id AND t.market = s.market
        WHEN MATCHED AND (t.line <> s.line) THEN
            UPDATE SET t.line = s.line, t.updated_at = s.updated_at
        WHEN NOT MATCHED THEN
            INSERT (event_id, market, line, updated_at)
            VALUES (s.event_id, s.market, s.line, s.updated_at);
    """)
    conn.commit()           # 3. One transaction: all-or-nothing, no partial write.
except Exception:
    conn.rollback()         # target unchanged on any failure
    raise                   # fail loud — never swallow in an unattended run
```

## GitHub Actions schedule (secrets stay references)

```yaml
on:
  schedule: [{ cron: "0 11 * * *" }]   # 11:00 UTC daily
jobs:
  load:
    runs-on: ubuntu-latest             # or the self-hosted Mac runner
    steps:
      - uses: actions/checkout@v4
      - run: op run -- python load.py  # OP_SERVICE_ACCOUNT_TOKEN is the only repo secret
        env:
          OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
```

## Common mistakes

- Row-by-row `INSERT` in a Python loop → orders of magnitude slower. Stage + set-based MERGE.
- Forgetting `fast_executemany=True` → `executemany` sends one round trip per row.
- `DELETE` then `INSERT` without a transaction → a crash mid-run leaves the table empty.
- `TRUNCATE`/full reload when an upsert would do → loses history, not re-runnable mid-day.
- Secret literals in YAML or `.env` committed → use `op://` refs (secrets-as-references).
