---
module: lang/python
paths:
  - "**/*.py"
updated: 2026-06-03
---
# Python naming (PEP 8)

| Element | Convention | Example |
|---|---|---|
| Variables, functions, methods | snake_case | game_count, fetch_player_props() |
| Booleans | snake_case with is_/has_/should_/can_ | is_valid, has_odds |
| Constants | UPPER_SNAKE_CASE | MAX_RETRIES, DB_PATH |
| Classes, exceptions | PascalCase (CapWords) | OddsLoader, StatcastPull |
| Modules / files | short snake_case, `.py` | mlb_pull.py, odds_sync.py |
| Packages / folders | short, lowercase, avoid underscores | nba, common |
| Private by convention | single leading underscore | _internal_cache |
| Test files (pytest) | `test_` prefix | test_odds_sync.py |

Critical: Python module filenames use underscores, never hyphens. `my_module.py` imports;
`my-module.py` is a syntax error on import.
