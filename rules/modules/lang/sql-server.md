---
module: lang/sql-server
paths:
  - "**/*.sql"
updated: 2026-06-03
---
# SQL Server (T-SQL) naming

## Objects
| Element | Convention | Example |
|---|---|---|
| Schemas, columns | snake_case | game_count |
| Reserved keywords | UPPERCASE | SELECT, FROM, JOIN, WHERE |
| Aliases | short lowercase | p, o |

## Table naming (LOCKED — plural by default)
Tables are plural snake_case; a table names the collection it holds: players, teams, games,
batting_stats, player_props, game_lines, snap_counts, discovered_events.

The following are NOT exceptions; they ARE the rule applied to special cases. Anything
matching one is correct as written:

1. **Mass / uncountable nouns** keep their singular form (no plural): config, performance,
   history, calibration, charting, quarantine. E.g. demo_config, model_performance,
   calibration_history, grade_calibration, ftn_charting, ingest_quarantine.
2. **Single-instance / utility / diagnostic** tables (one bounded thing, not a growing
   collection) are singular: schedule, market_probe, game_supplemental.
3. **Role-suffixed** tables use a fixed singular suffix naming the artifact:
   - `_map` crosswalk/lookup: player_map, team_map, event_game_map
   - `_log` append-only event log: data_completeness_log
   - `_archive` retained historical copy: daily_grades_archive (use `_archive`, never `_backup`)
4. **Dimensional** tables use `dim_` prefix, singular grain (Kimball): dim_date.
5. **Vendor mirror** tables preserve the source system's exact names verbatim: pff_dim_games,
   pff_fantasy_passing.

Idioms that are neither singular nor plural stay as the idiom: play_by_play,
career_batter_vs_pitcher.

Grandfathered (documented, not renamed): common.teams_backup predates the `_archive` rule.
Leave it; apply `_archive` going forward.
