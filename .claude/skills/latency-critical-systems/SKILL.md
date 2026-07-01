---
name: latency-critical-systems
description: Use when freshness and tail latency matter on a hot path - a realtime dashboard, live sports scoreboard, streaming feed, queue, cache, or API gateway. Triggers on "p95 is too high", "the dashboard lags the source", "stale data showing", "speed up the live feed". Hot-path / tail-latency patterns (not batch throughput - for a backfill or bulk load see data-throughput-accelerator).
---

# latency-critical-systems

For systems where the user cares about realtime behavior, freshness, and tail
latency, not just average throughput. Engineering-focused: this does not authorize
live trading or financial advice. The mechanical primitives (read-once, caching,
batching, thread pool) live in
[speed-by-default](../../../rules/global/speed-by-default.md); this skill is the
diagnosis-and-ordering workflow for a hot path. To cache a hot read use the
`content-hash-cache-pattern` skill; for bulk data, the
`data-throughput-accelerator` skill; time changes with the `benchmark` skill and
profile with the `performance-optimizer` agent.

## Split the metrics

Do not collapse everything into "fast." Track each separately:

| Metric | Why |
|---|---|
| p50 / p95 / p99 latency | tail is what users feel, not the mean |
| Freshness age | how old the visible data is vs the source |
| Throughput | requests or rows per second |
| Queue depth | early signal of backpressure |
| Cache hit rate | a miss may be the slow path |
| Provider response time | upstream is often the real cost |
| Correctness under load | fast and wrong is a regression |

## Map the hot path

Write the path from event to visible state, then measure each segment:

```text
source event -> provider API -> ingest worker -> queue -> cache -> route
            -> client -> browser render -> user-visible state
```

## Optimization order

1. Remove unnecessary round trips.
2. Cache stable reads with a freshness timestamp (so a hit can't hide stale data).
3. Batch small calls and writes.
4. Move compute closer to the data or the user.
5. Split hot and cold paths so cheap reads don't wait behind heavy work.
6. Apply backpressure before the queue grows unbounded.
7. Use streaming only when it actually improves freshness.
8. Add canaries for stale data, degraded providers, and bad cache state.

## Example: freshness-tagged cache read (live scoreboard)

```python
import time

CACHE_TTL = 5.0  # seconds; scoreboard tolerates 5s staleness

def get_scoreboard(cache: dict, fetch) -> dict:
    hit = cache.get("scoreboard")
    if hit and time.monotonic() - hit["fetched_at"] < CACHE_TTL:
        return {**hit["data"], "age_s": round(time.monotonic() - hit["fetched_at"], 1)}
    data = fetch()  # provider call only on miss/expiry
    cache["scoreboard"] = {"data": data, "fetched_at": time.monotonic()}
    return {**data, "age_s": 0.0}
```

The returned `age_s` is the freshness contract: a fast cache hit still tells the
caller how stale it is.

## Verify with live readbacks

When a surface is deployed, measure rather than assert: HTTP timing + response
headers, provider freshness timestamp, queue/job state, and a browser check for
the actual rendered UI.

- Do not optimize latency by dropping required validation.
- Do not hide stale data behind a fast cache hit.
- Do not claim millisecond behavior from a client label without measuring it.
- Keep secrets and private payloads out of logs and benchmark artifacts.
