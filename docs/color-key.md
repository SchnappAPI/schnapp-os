# Color key - documentation ink legend

A universal 8-pen color scheme for hand-documenting repos, schemas, and architecture.
Color encodes the **functional role** a token plays, not what it is called. Roles recur
across every domain (a schema, a service, an API), so the same eight pens transfer instead
of running out on domain-specific nouns.

Core rule: **one pen = one role.** A sub-type *within* a role gets a prefix glyph, not a new
color.

## The map

Hex values approximate the physical pens on screen only; the pens are the source of truth.
Example tokens are real, drawn from `schnapp-bet` (see Provenance).

| Pen | Hex* | Role | In a schema / DB | In a repo / code |
|---|---|---|---|---|
| Black | `#1a1a1a` | Default / structure | table titles, prose, `-- notes` | `# comments`, docstrings, `README`/`PLAN.md` |
| Navy | `#1c2e5a` | Identity | `F·daily_grades`, `D·dim_date`, `grade_id (PK)` | `class OddsApiAuthError`, `grading.mlb_grade_props` |
| Royal | `#2f5fd0` | Reference | `event_id`, `game_id` (FK), `player_id → nba.players` | `from shared.db import`, `get_engine()`, `upsert()` |
| Light blue | `#6db8e8` | Type / metadata | `line_value DECIMAL(6,1)`, `grade FLOAT`, `date_key DATE`, `is_weekend BIT` | `MARKET_CONFIG` (dict), `price: int -> float` |
| Green | `#2f8f4e` | Input / source | `odds.player_props` (raw feed), `snap_ts`, `outcome_point` | env `ODDS_API_KEY`, `NBA_PROXY_URL`, `RUNNER_API_KEY` |
| Orange | `#e8842b` | Output / derived | `composite_grade`, `ev_pct`, `weighted_hit_rate` | `compute_composite()`, `ev()`, `_blended_hr_rate()` |
| Pink | `#e85b9c` | Note / annotation | grain: 1 row per prop per day; `ev = model_prob/implied - 1` | `# dedup: highest price`, `# dates in ET` |
| Red | `#d83a34` | Alert | `NOT NULL` (e.g. `event_id`); `teams_backup`, `daily_grades_archive` (deprecated) | `raise OddsApiAuthError`; `ODDS_API_KEY` = `op://` ref only |

## Rules

1. **Color marks the role, not the name.** Identity vs reference is the distinction the ink
   carries: `grade_id (PK)` is Navy, `event_id (FK)` is Royal, even though both are "an id
   column."
2. **Sub-type within a role = a prefix glyph, not a new color.** Fact and dimension tables
   are both Identity (Navy): write `F·daily_grades` and `D·dim_date`. The same trick covers
   any variant (one FK vs another, staging vs prod): the color says the role, a small mark
   says the flavor.

Mnemonic: three blues (Navy, Royal, Light) = structure. Warm (Green, Orange, Red) = flow and
state. Pink = your voice. Black = neutral default.

## Panobook transcription (first page)

Notebook: Studio Neat Panobook. Page 288 x 160 mm, 5 mm dot grid, 6 mm corner radius.
Theoretical field ~57 x 32 dot intervals; usable ~54 x 30 after outer and wire-o binding
margins (those offsets are not published and were not measured, so budget conservatively and
keep 2 columns clear on the bound edge).

Table footprint ~52 x 30 cells (~260 x 150 mm):

- Columns: swatch 2, color 5, role 7, schema examples 19, code examples 19. Vertical dividers
  at columns 9, 16, 35; table ends at column 54.
- Rows: title 2, header 2, eight role rows at 3 cells each (two example lines per side per
  column), rules footer 2. Total 30 rows.
- If the measured field is narrower than 54 columns, cut the two example columns evenly before
  touching the color/role columns.

## Provenance

- Schema tokens: live `schnapp-bet` SQL Server DB. Schemas `common`, `mlb`, `nba`, `nfl`,
  `odds`. `common.daily_grades` (fact), `common.dim_date` (dimension), `odds.player_props`
  (raw odds feed), and the `_archive` / `_backup` tables as real deprecated examples.
- Code tokens: `grading/mlb_grade_props.py`, `shared/db.py`, `shared/integrity.py`.
- `ev()` verified as `prob / implied - 1` in `grading/mlb_grade_props.py` (not inferred from
  column names).
- The `F·` / `D·` prefixes are the glyph convention applied to real fact/dimension tables.

## Verify before inking

- Confirm any `src` / `stg` source/staging naming if you use it; not verified against the DB.
- `web/` (Next.js / TypeScript) was not sampled. The code column is Python. Add a TypeScript
  variant (`middleware.ts`, `app/` routes, `lib/`) if the notebook will document the web app.

Sources verified 2026-07-07.
