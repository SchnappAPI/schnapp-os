---
name: cost-aware-llm-pipeline
description: Use when building a Python pipeline that calls an LLM API over a batch: routing tasks to the cheapest sufficient model, tracking spend against a budget, retrying only transient errors, and caching long prompts.
---

# cost-aware-llm-pipeline

Control LLM API cost without losing quality on hard items. Four composable techniques:
route by complexity, track spend, retry narrowly, cache prompts. For the API itself, the
`claude-api` skill carries current model IDs and caching syntax; consult it rather than
trusting the IDs below.

## 1. Route by complexity

Cheap model for simple items, expensive only when a threshold is crossed.

```python
def select_model(text_length: int, item_count: int, force: str | None = None) -> str:
    if force:
        return force
    if text_length >= 10_000 or item_count >= 30:
        return MODEL_BIG      # complex
    return MODEL_SMALL        # ~3-4x cheaper
```

## 2. Track spend (immutable)

Each call returns a new tracker; never mutate. Easier to audit and reason about.

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class CostTracker:
    budget_limit: float = 1.00
    total_cost: float = 0.0

    def add(self, cost_usd: float) -> "CostTracker":
        return CostTracker(self.budget_limit, self.total_cost + cost_usd)

    @property
    def over_budget(self) -> bool:
        return self.total_cost > self.budget_limit
```

## 3. Retry only transient errors

```python
RETRYABLE = (APIConnectionError, RateLimitError, InternalServerError)

def call_with_retry(fn, max_retries=3):
    for attempt in range(max_retries):
        try:
            return fn()
        except RETRYABLE:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)        # backoff
    # auth / bad-request errors are never caught: fail fast
```

## 4. Cache long prompts

Mark the stable system prompt cached; keep the variable input uncached.

```python
content = [
    {"type": "text", "text": system_prompt, "cache_control": {"type": "ephemeral"}},
    {"type": "text", "text": user_input},
]
```

## Practices

- Default to the cheapest model; escalate only when a threshold trips.
- Set the budget before the batch runs; fail early instead of overspending.
- Log every model-selection decision so thresholds can be tuned on real data.
- Cache system prompts over ~1024 tokens: saves cost and latency.
- Never retry auth or validation errors; only network / rate-limit / server errors.

## Anti-patterns

- One expensive model for every item.
- Retrying all errors (burns budget on permanent failures).
- Mutating the cost tracker (hard to audit).
- Hardcoding model IDs across files instead of constants from the `claude-api` skill.
