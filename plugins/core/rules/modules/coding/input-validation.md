---
module: coding/input-validation
updated: 2026-06-03
---
# Input validation at boundaries

- Validate all external data before it touches the database. External sources include
  AppFolio, Baseball Savant, FanGraphs, Statcast, and odds APIs.
- Treat every external response as untrusted. Check for nulls, schema drift, rate-limit
  responses, and HTML error pages returned where JSON was expected.
- Use schema-based validation (pydantic on the Python side) where it fits, and fail fast
  with a clear message when data does not match the expected shape.
