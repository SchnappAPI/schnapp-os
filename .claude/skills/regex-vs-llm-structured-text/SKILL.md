---
name: regex-vs-llm-structured-text
description: Use when parsing structured or semi-structured text (vendor reports, API JSON, CSV/fixed-width exports, PDF dumps) and deciding between deterministic parsing and an LLM, or when an all-LLM extraction is slow/costly/nondeterministic. Gives the decision table and the regex-first-with-LLM-fallback pattern.
---

# regex-vs-llm-structured-text

Default to deterministic parsing; reach for an LLM only where the input is genuinely
irregular. Deterministic parsing handles the bulk cheaply and reproducibly; reserve LLM
calls for the low-confidence tail. The cost/latency case for this is
[speed-by-default](../../../rules/global/speed-by-default.md); confirm the parse actually
matches the source before trusting it ([verify-before-asserting](../../../rules/global/verify-before-asserting.md)).

## Pick the tool

| Input characteristic | Use |
|---|---|
| Stable, repeating layout (CSV, fixed-width, consistent report rows) | `csv`/`pandas`, fixed-width slices - no regex needed |
| Well-formed JSON/XML from an API | Native parser + schema/dataclass; never regex structured markup |
| Mostly-regular text with a clear grammar (labeled fields, "Key: value" lines) | Regex with named groups |
| Same as above but a small irregular tail (typos, missing fields, merged rows) | Regex first, LLM only on the flagged minority |
| Free-form, highly variable, no reliable delimiters | LLM extraction directly |

Rule of thumb: if you can name the pattern, parse it deterministically. Send to an LLM
only the rows deterministic parsing could not place with confidence.

## Pattern: deterministic-first with LLM fallback

Owner stack: parsing a vendor box-score report into rows for a SQL Server load.

```python
import re
from dataclasses import dataclass

@dataclass(frozen=True)
class PlayerLine:
    player: str
    points: int
    rebounds: int
    confidence: float = 1.0

LINE = re.compile(
    r"^(?P<player>[A-Z][\w.'\- ]+?)\s+"
    r"(?P<points>\d+)\s+(?P<rebounds>\d+)\s*$"
)

def parse(report: str) -> tuple[list[PlayerLine], list[str]]:
    """Deterministic parse. Returns (clean rows, unparsed lines for LLM)."""
    rows, leftovers = [], []
    for line in report.splitlines():
        line = line.strip()
        if not line:
            continue
        m = LINE.match(line)
        if m:
            rows.append(PlayerLine(
                player=m["player"].strip(),
                points=int(m["points"]),
                rebounds=int(m["rebounds"]),
            ))
        else:
            leftovers.append(line)          # the irregular tail
    return rows, leftovers
```

Then escalate only `leftovers` to an LLM (cheapest model that works), validate its JSON
against the same `PlayerLine` shape, and tag those rows with a lower `confidence` so the
SQL Server load (or a review step) can treat them differently. Never mutate parsed rows in
place - return new instances from each step.

## Guardrails

- Quantify before optimizing: log deterministic hit rate and LLM-call count. If regex
  already clears ~98%, an all-LLM rewrite buys nothing but cost and nondeterminism.
- Validate LLM output against the same schema/dataclass as the deterministic path; a free
  text answer is not parsed data.
- Treat extraction confidence as a column, not a side channel: persist it so downstream SQL
  can filter or flag low-confidence rows.
- Test the irregular cases (missing field, merged row, encoding noise) first - they are
  where both regex and LLM break.

This is the extraction stage of the `etl-pipeline-build` skill; the load and SQL Server
shape belong there and in the `sql-server-patterns` skill.
