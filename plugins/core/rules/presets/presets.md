---
updated: 2026-06-03
---
# Rule presets

A preset is a named list of modules applied in one choice by `/new-project`. Global rules
always apply and are not listed. You can add or remove any module after applying a preset.

| Preset | Modules |
|---|---|
| work-etl-sql | coding/*, lang/python, lang/sql-server, lang/env-vars, lang/git, lang/github-actions, activity/etl-pipeline, context/work |
| personal-sports-etl | coding/*, lang/python, lang/sql-server, lang/env-vars, lang/git, lang/github-actions, activity/etl-pipeline, context/personal |
| policy-procedure | activity/policy-procedure, context/work |
| web-tool | coding/*, lang/typescript, lang/git, activity/web-tool |
| quickbase | tool/quickbase, context/work |

```yaml
# machine-readable (consumed by /new-project)
presets:
  work-etl-sql:    [coding/error-handling, coding/input-validation, coding/design-defaults, lang/python, lang/sql-server, lang/env-vars, lang/git, lang/github-actions, activity/etl-pipeline, context/work]
  personal-sports-etl: [coding/error-handling, coding/input-validation, coding/design-defaults, lang/python, lang/sql-server, lang/env-vars, lang/git, lang/github-actions, activity/etl-pipeline, context/personal]
  policy-procedure: [activity/policy-procedure, context/work]
  web-tool:        [coding/error-handling, coding/input-validation, coding/design-defaults, lang/typescript, lang/git, activity/web-tool]
  quickbase:       [tool/quickbase, context/work]
```
