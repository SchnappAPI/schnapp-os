---
name: performance
description: Use when something is slow or must be proven fast - measuring a performance baseline, detecting a regression before/after a change, comparing alternatives by repeated timed runs, "this load is too slow", "speed up the backfill", "the pipeline is behind", a bulk ingest or table sync that drags, or a hot path where "p95 is too high", "the dashboard lags the source", or stale data is showing. Covers measure-first method, batch throughput, and hot-path tail latency; the performance-optimizer agent composes this skill after profiling.
---

# performance

Measure, then fix the right class of slow: batch throughput (backfills, bulk loads) or
hot-path tail latency (live feeds, dashboards). The mechanical primitives (read-once,
module cache, thread pool, set-based SQL, bulk insert, `fast_executemany`) live in
[speed-by-default](../../../rules/modules/coding/speed-by-default.md); this skill is the
measurement method and the diagnosis-and-ordering workflow. Build the pipeline with the
[etl-pipeline-build](../etl-pipeline-build/SKILL.md) skill; profile deeply with the
**performance-optimizer** agent.

## Measure first (always)

1. Fix the input shape and lock a correctness check that must stay green.
2. Run the baseline 3+ times; record median, not best case. Warm caches deliberately or note cold.
3. Make one change. Re-run identically.
4. Report before / after / delta in a table. Keep the raw numbers.

| Surface | Metric | Target signal |
|---|---|---|
| Python ETL | wall time, rows/sec, peak memory | rows/sec rises, memory flat |
| SQL Server query | elapsed ms, logical reads (`SET STATISTICS IO, TIME ON`), plan | reads drop, no scans |
| SQL Server load | rows/sec on insert, batch size | bulk path, not row-by-row |
| Web tool (occasional) | TTFB, LCP, JS bytes | TTFB < 800ms, LCP < 2.5s |

Store baselines beside the code so future runs compare against them, not memory. A
regression is a delta outside run-to-run noise, not a single slow sample.

## Batch throughput (backfill, bulk ingest, export, table sync)

Goal: faster *correct* data in the right table, with proof. A load can be "fast" and still
look behind if the live tail grows faster than the catch-up window, so measure each stage,
not the total: extract, transfer, transform, load, tail (new rows arriving mid-run).

- Move compute to the data: large joins/aggregates set-based in SQL Server, not row-by-row Python.
- Skip done work: a manifest or checkpoint marks processed files/partitions so reruns skip them.
- Batch small files, requests, and writes; bulk insert over per-row loops.
- Make writes idempotent (unique key + `MERGE`, or replaceable staging table) so a rerun is safe.
- Compare variants (batch size, worker count, set-based vs loop, staging shape); promote only
  the fastest one whose row counts and max timestamps still match the source, then codify it
  as a CLI / LaunchAgent / GitHub Actions job.

**Correctness gate** - report it and never call the run done until it passes: source rows vs
loaded rows, manifest match, table `max(updated)` vs source max, remaining tail, runtime.
Never delete raw data to make a metric look good; never skip a failed file silently; never
mix backfill progress with live-tail freshness.

## Hot path and tail latency (realtime dashboard, live feed, cache, queue)

Do not collapse everything into "fast". Track separately: p50/p95/p99 latency (tail is what
users feel), freshness age vs the source, throughput, queue depth, cache hit rate, provider
response time, and correctness under load. Map the path from source event to user-visible
state, measure each segment, then optimize in this order:

1. Remove unnecessary round trips.
2. Cache stable reads with a freshness timestamp, so a hit cannot hide stale data. For
   content-keyed file caches see
   [content-hash-cache](../../../rules/modules/coding/content-hash-cache.md).
3. Batch small calls and writes.
4. Move compute closer to the data or the user.
5. Split hot and cold paths so cheap reads do not wait behind heavy work.
6. Apply backpressure before the queue grows unbounded.
7. Use streaming only when it actually improves freshness.
8. Add canaries for stale data, degraded providers, and bad cache state.

Verify deployed surfaces with live readbacks (HTTP timing + headers, provider freshness
timestamp, the rendered UI), never a client label. Do not optimize latency by dropping
required validation; do not hide stale data behind a fast cache hit; keep secrets and
private payloads out of logs and benchmark artifacts.
