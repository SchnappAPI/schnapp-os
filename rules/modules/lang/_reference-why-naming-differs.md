---
module: lang/_reference-why-naming-differs
composed: false
note: reference only - not composed into projects, not loaded as a rule
updated: 2026-06-03
---
# Why the naming rules differ (reference)

- PascalCase (classes/types) and UPPER_SNAKE_CASE (constants) are identical in Python and
  JavaScript. Only variable/function casing and file naming differ.
- Variables: Python snake_case; JavaScript camelCase.
- Files: Python requires underscores; JavaScript prefers hyphens.
- This is why JavaScript naming is scoped to JS/TS files only and never applied globally.
