---
name: benchmark
description: Use when measuring a performance baseline, detecting a regression before/after a change, or comparing alternatives by repeated timed runs. Covers ETL throughput, SQL Server query/load latency, or a web tool's page metrics.
---

# benchmark

Establish a measured baseline, then re-measure after a change to prove the delta with
numbers, not feel. Composes [`speed-by-default`](../../rules/global/speed-by-default.md).
For an iterative search across variants, use the **benchmark-optimization-loop** skill; to
act on results, the **performance-optimizer** agent.

## What to measure (owner's stack first)

| Surface | Metric | Target signal |
|---|---|---|
| Python ETL | wall time, rows/sec, peak memory | rows/sec rises, memory flat |
| SQL Server query | elapsed ms, logical reads, plan | reads drop, no scans |
| SQL Server load | rows/sec on insert, batch size | bulk path, not row-by-row |
| Web tool (occasional) | TTFB, LCP, JS bytes | TTFB < 800ms, LCP < 2.5s |

## Method

1. Fix the input shape and lock a correctness check that must stay green.
2. Run the baseline 3+ times; record median, not best case. Warm caches deliberately or note cold.
3. Make one change. Re-run identically.
4. Report before / after / delta in a table. Keep the raw numbers.

## Example (Python ETL load)

```python
import time
def timed(label, fn):
    t = time.perf_counter()
    rows = fn()
    dt = time.perf_counter() - t
    print(f"{label}: {rows:,} rows in {dt:.2f}s = {rows/dt:,.0f} rows/s")

timed("baseline executemany",      load_row_by_row)        # 5,000 rows in 41.2s = 121 rows/s
timed("fast_executemany + batch",  load_bulk_batched)      # 5,000 rows in 1.8s = 2,778 rows/s
```

```sql
-- SQL Server: measure reads + time, not wall clock alone
SET STATISTICS IO, TIME ON;
-- run the query; compare logical reads before/after an index
```

## Reporting

| Metric | Before | After | Delta | Verdict |
|---|---|---|---|---|
| Load rows/s | 121 | 2,778 | 23x | better |
| Logical reads | 84,210 | 312 | -99% | better |

Store baselines beside the code or in the repo so future runs compare against them, not
memory. A regression is a delta outside run-to-run noise, not a single slow sample.
