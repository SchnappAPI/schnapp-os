---
name: data-throughput-accelerator
description: Use when a backfill, bulk ingest, export, warehouse load, manifest catch-up, or table sync needs to be much faster while data stays correct. Triggers on "this load is too slow", "speed up the backfill", "the pipeline is behind". Batch/throughput patterns (not hot-path latency - for a realtime/live feed see latency-critical-systems); the performance-optimizer agent composes this skill after profiling.
---

# data-throughput-accelerator

For when the bottleneck is moving, transforming, or landing lots of data. Goal:
faster *correct* data in the right table, with proof. The mechanical primitives
(read-once, module cache, thread pool, set-based SQL, bulk insert,
`fast_executemany`) live in [speed-by-default](../../../rules/global/speed-by-default.md);
this skill applies them to a throughput problem. Build the pipeline with the
`etl-pipeline-build` skill, time variants with the `benchmark` skill, profile
deeply with the `performance-optimizer` agent. See also
[../../rules/modules/activity/etl-pipeline.md](../../../rules/modules/activity/etl-pipeline.md).

## Separate the stages before optimizing

A load can be "fast" and still look behind if the live tail grows faster than
the catch-up window. Measure each stage, not the total:

| Stage | What to time |
|---|---|
| Extract | source read / API page latency |
| Transfer | network, file download |
| Transform | parse, reshape, dedupe |
| Load | insert/upsert into SQL Server |
| Tail | new rows arriving while the job runs |

## Fast-path heuristics

- Move compute to the data: do large joins/aggregates set-based in SQL Server, not row-by-row in Python.
- Skip done work: a manifest or checkpoint marks processed files/partitions so reruns don't redo them.
- Batch small files, requests, and writes; bulk insert over per-row loops.
- Make writes idempotent (unique key + `MERGE`, or replaceable staging table) so a rerun is safe.
- Keep raw, derived, and serving tables separately accountable.

## Workflow

1. Read source, target, and manifest contracts.
2. Measure the backlog: source rows/files, manifest rows, table rows, min/max timestamps.
3. Benchmark a sample (one variant) to get a baseline.
4. Compare variants: batch size, worker count, set-based SQL vs loop, staging shape, manifest method.
5. Promote only the fastest variant whose row counts and max timestamps still match the source.
6. Codify it as a CLI / LaunchAgent / GitHub Actions job.
7. Rerun the accounting after the codified path runs.

## Example: per-row loop to set-based upsert

```python
# slow: one round trip per row
for row in rows:
    cur.execute("INSERT INTO games VALUES (?,?,?)", row)

# fast: bulk into staging, then one set-based MERGE
cur.fast_executemany = True
cur.executemany("INSERT INTO games_stage VALUES (?,?,?)", rows)
cur.execute("""
    MERGE games AS t USING games_stage AS s ON t.game_id = s.game_id
    WHEN MATCHED THEN UPDATE SET t.score = s.score, t.updated = s.updated
    WHEN NOT MATCHED THEN INSERT (game_id, score, updated) VALUES (s.game_id, s.score, s.updated);
""")
```

## Correctness gate

Report a hard accounting block and never call the run done until it passes:

```text
Source rows: 9,683,598 | Loaded: 9,683,598 | Manifest rows match: yes
Table max(updated): 2026-06-05 03:14 == source max: 2026-06-05 03:14
Remaining tail: 24 rows at readback | Runtime: 38.7s
```

- Never delete raw data to make a metric look good.
- Never skip a failed file silently; record it and surface it.
- Never mix backfill progress with live-tail freshness.
