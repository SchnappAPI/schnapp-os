---
name: benchmark-optimization-loop
description: Use when asked to make something faster, try many variants, or pick the best implementation by repeated measured tests. Turns "make it 20x faster" into a bounded, measured search with a correctness gate.
---

# benchmark-optimization-loop

Turn an open-ended speed goal into a bounded loop that actually improves the system and
proves it. Composes [`speed-by-default`](../../rules/global/speed-by-default.md) and the
**benchmark** skill for measurement.

## Required before optimizing

Do not start until all five exist:

- the operation being optimized;
- a correctness gate that must stay green (test, row count, checksum);
- the metric: wall time, p95 latency, rows/sec, cost/run, memory, error rate;
- the current baseline number;
- the budget: max variants, max time, max spend.

Keep an ambitious target, but make the loop bounded and measurable.

## Loop

1. Measure the baseline.
2. Find the bottleneck from evidence (profile / `STATISTICS IO`), not a guess.
3. Generate variants that each test one hypothesis.
4. Run every variant on the same input shape.
5. Reject any variant that fails correctness, safety, or reproducibility.
6. Promote the fastest safe variant.
7. Codify the winner in a script, config, or test so it sticks.
8. Re-run baseline and winner to confirm the delta.

## Variant ledger

```text
variant         | hypothesis          | metric    | correct? | notes
baseline        | row-by-row insert   | 121 r/s   | yes      | stable
batch-1000      | fewer round trips   | 2,778 r/s | yes      | winner
fast_exec+stage | bulk into staging   | 9,400 r/s | yes      | winner, needs MERGE
parallel-8      | 8 writer threads    | 6,100 r/s | no       | deadlocks on target
```

## Recursive / repeated search

- Persist every run to the ledger.
- Compare each variant against the prior accepted winner, not just the previous run.
- Keep a holdout or replay check so a "win" isn't overfit.
- Stop when improvement is within noise, correctness fails, or the budget is hit.
- Say "best measured safe variant", not "optimal", unless the search was exhaustive.

## Promotion gate

A variant becomes the new default only when: correctness passes, the delta is repeated or
explained, rollback is obvious, the change lives in source control, and the summary carries
the exact commands and numbers. Hand off to the **performance-optimizer** agent for deeper
profiling.
