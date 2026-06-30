---
description: Generate or refresh a token-lean architecture map (codemap) of a repo — entry points, modules, data flow, and the pipeline/table topology — written as a generated doc. Architecture map only; to regenerate schema/env/route catalogs use /update-docs.
argument-hint: "[target-dir]"
---
# /update-codemaps

Produce a compact, token-lean map of a repo so a fresh session (or a subagent) can orient
without reading every file. For the owner's ETL repos the map's spine is the **data flow**:
source → script → table. A generated projection, not hand-maintained prose (see
[`global/anti-stale`](../rules/global/anti-stale.md)).

Steps Claude follows:

1. Resolve the target directory (argument, else the current repo root). For the owner's
   downstream ETL repos, not schnapp-os (which is a docs/config repo with no code graph —
   its catalog IS its map).
2. Scan structure without dumping it: top-level packages/dirs, entry points (`__main__`,
   CLI scripts, scheduled jobs), and the module each one calls.
3. Trace the data flow for each pipeline: **external source → extract script → transform →
   target table(s)**. Name the natural key and the schedule (cron / LaunchAgent) per pipeline.
4. Write `CODEMAP.md` (or refresh it) as a lean table/outline:
   - Entry points → what each runs.
   - Pipelines → source, script, target table, key, schedule.
   - Shared modules → one line each on responsibility.
   Keep it scannable; link to files by path, do not inline file contents.
5. Mark it `generated — do not edit`; note it is a projection of the code, refreshed by
   re-running this command.
6. Report what the map covers and any pipeline whose flow could not be traced (a gap to fix,
   not to guess).

Keep the whole map small enough to load cheaply — that is the point. If a repo is large,
map the topology and entry points, not every function.
