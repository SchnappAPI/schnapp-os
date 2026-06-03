# Handoff 001 — Parts 2 and 3 (rules + surfaces)

Date: 2026-06-03

## Done and pushed
- Part 2.1: global rules (`plugins/core/rules/global/`, 6 files).
- Part 2.3: surface profiles (`surfaces/`, README + 5 profiles).
- Part 3.1/3.2: rule module gallery (`plugins/core/rules/modules/`, 17 modules) + presets.
- Part 3.3: `/new-project` composer command.
- Credentials: owner rotated the 1Password SA; `op`/`gh` work again (decisions/0001).

## Not yet done
- Part 2.2: create `~/.claude/CLAUDE.md` (@import global) + symlink `~/.claude/rules/global`
  to this repo. DEFERRED until Part 1 freeze, so it does not collide with active schnapp-kit.
- Part 3.4: verify path-scoped rules (Python rules absent when editing `.sql`). Needs the
  plugin installed or a symlink test.
- Part 1: freeze schnapp-kit (tag record-2026-06-03), disable it + triage the 19 plugins.
  NEEDS owner keep-set approval first.
- Stubs to fill when doing that work: tool/quickbase, tool/appfolio, activity/policy-procedure,
  activity/web-tool, activity/data-modeling, context/work, context/personal.

## Next session prompt
"Resume claude-kit PLAN.md. Read PROGRESS.md and handoffs/ first. Then do Part 1 (propose the
plugin keep-set for my approval, then freeze schnapp-kit and disable the rest), or Part 5
(memory both lanes), whichever I pick."

## References
PLAN.md, PROGRESS.md, decisions/0001, surfaces/README.md, rules/presets/presets.md.
