---
name: sql-server-patterns
description: Use when writing or reviewing T-SQL for SQL Server 2022 — upserts/MERGE, idempotent schema changes (CREATE OR ALTER, IF NOT EXISTS), indexing, rewriting cursor/row-by-row logic as set-based, bulk loads, transactions and TRY/CATCH, or SQL Server-specific features (STRING_SPLIT with ordinal, GENERATE_SERIES, JSON, window functions). This is the owner's database — do NOT apply Postgres/MySQL idioms (no SERIAL, no LIMIT, no ILIKE, no backticks).
---

# sql-server-patterns

T-SQL idioms for SQL Server 2022, the owner's database. Naming (plural snake_case tables,
the LOCKED special-case rules) lives in [`lang/sql-server`](../../rules/modules/lang/sql-server.md);
performance principles in [`global/speed-by-default`](../../rules/global/speed-by-default.md).
This skill is the dialect + pattern reference. For Python-side loading use the
**etl-pipeline-build** skill.

## Dialect guardrails (not Postgres/MySQL)

| Need | SQL Server | Not |
|---|---|---|
| Top N rows | `SELECT TOP (10) …` or `OFFSET/FETCH` | `LIMIT 10` |
| Identity column | `INT IDENTITY(1,1)` | `SERIAL` / `AUTO_INCREMENT` |
| String concat | `CONCAT(a,b)` or `+` | `\|\|` |
| Case-insensitive | depends on collation; `COLLATE` to force | `ILIKE` |
| Quote identifier | `[bracket]` | `` `backtick` `` |
| Current time (UTC) | `SYSUTCDATETIME()` | `NOW()` |
| Upsert | `MERGE` or staged update+insert | `INSERT … ON CONFLICT` |
| NULL-safe default | `ISNULL(x, d)` / `COALESCE` | `IFNULL` |

## Idempotent schema (re-runnable migrations)

```sql
-- Programmability: CREATE OR ALTER is idempotent for views/procs/functions/triggers.
CREATE OR ALTER VIEW dbo.v_active_props AS
SELECT event_id, market, line FROM dbo.player_props WHERE updated_at > DATEADD(day,-1,SYSUTCDATETIME());
GO
-- Tables/columns/indexes have no CREATE OR ALTER — guard with existence checks.
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='player_props' AND schema_id=SCHEMA_ID('dbo'))
    CREATE TABLE dbo.player_props (event_id INT NOT NULL, market VARCHAR(40) NOT NULL,
        line DECIMAL(6,2) NULL, updated_at DATETIME2 NOT NULL,
        CONSTRAINT pk_player_props PRIMARY KEY (event_id, market));
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='ix_player_props_updated')
    CREATE INDEX ix_player_props_updated ON dbo.player_props(updated_at);
```

## Set-based over row-by-row (the biggest SQL Server perf lever)

Cursors and `WHILE` loops are the most common slow pattern. Replace with a single set
operation; the engine parallelizes and avoids per-row round trips.

```sql
-- ❌ cursor: one statement per row
DECLARE c CURSOR FOR SELECT id FROM dbo.games; -- ... FETCH/UPDATE/loop
-- ✅ set-based: one statement, all rows
UPDATE g SET g.is_final = 1
FROM dbo.games g
WHERE g.status = 'closed' AND g.is_final = 0;
```

## Safe write pattern (TRY/CATCH + transaction)

```sql
BEGIN TRY
    BEGIN TRAN;
        MERGE dbo.player_props AS t
        USING #stage AS s ON t.event_id = s.event_id AND t.market = s.market
        WHEN MATCHED AND t.line <> s.line THEN UPDATE SET t.line = s.line, t.updated_at = s.updated_at
        WHEN NOT MATCHED THEN INSERT (event_id, market, line, updated_at)
            VALUES (s.event_id, s.market, s.line, s.updated_at);
    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;        -- no partial write
    THROW;                              -- re-raise; never swallow
END CATCH;
```

## SQL Server 2022 features worth reaching for

- `GENERATE_SERIES(1, @n)` — number/date spines without a tally table.
- `STRING_SPLIT(@csv, ',', 1)` — the `enable_ordinal` arg (2022+) preserves order.
- `DATE_BUCKET(day, 1, ts)` — time bucketing for aggregation.
- `JSON_VALUE` / `OPENJSON` — parse vendor JSON payloads into rows; pair with `WITH` schema.
- Windowed `SUM() OVER (PARTITION BY … ORDER BY …)` — running totals without self-joins.

## Common mistakes

- `MERGE` without a unique key on the `ON` clause → duplicate inserts or wrong updates.
- Parameter sniffing on a hot proc → consider `OPTION (RECOMPILE)` or `OPTIMIZE FOR`.
- Implicit conversion (e.g. `VARCHAR` column vs `NVARCHAR` literal) → silent index scan; match types.
- Building SQL by string concatenation with user input → injection; parameterize (`?` / `sp_executesql`).
- `SELECT *` into production loads → breaks on schema drift; name columns.
