# Handoff 025 — Part 11 (agentic-OS capstone) built

Date: 2026-06-16. Surface: Claude Code web remote container (shell + git + Mac/GitHub/obsidian/op/
cloudflare connectors). Status: COMPLETE, pushed to PR #1 (branch
`claude/claude-kit-session-plan-ygp2ad`). Continues handoff 024's plan, step 1 (Part 11 = authorable
here, blocks nothing).

## What was built (PLAN Part 11, all three → [x])

### 11.1 Scheduler — the self-running layer
- `scheduled-tasks/README.md` — the model: **safe (auto)** routines run unattended + report;
  **asks-first (queued)** routines detect-and-propose, never auto-mutate. Surface map (GitHub
  Actions cron for repo-only/Mac-independent; Mac LaunchAgent → `claude -p` for Mac/judgment).
  Results-to-repo; nothing auto-commits beyond a reviewed report path.
- Four routine specs: `doc-freshness-sweep.md`, `sync-unmerged-check.md` (both safe/CI),
  `memory-consolidation.md` (asks-first), `infra-health.md` (Mac-needed, read-only probe). The two
  Mac/judgment specs include the verbatim agent instructions a LaunchAgent's `claude -p` runs.
- `scheduled-tasks/run-ci-routines.sh` — single source for the two safe routines (freshness sweep =
  hard gate; sync/unmerged = informational table). Markdown to stdout; exit non-zero ONLY on
  freshness drift. Tested locally: exit 0, correctly listed this PR's branch as the 1 unmerged item.
- `.github/workflows/scheduled-routines.yml` — nightly cron (`17 8 * * *`) + `workflow_dispatch`;
  runs the bundle, tees the report to the Step Summary; `permissions: contents: read` (never commits).

### 11.2 `/do` orchestrator
- `plugins/core/commands/do.md` — classify the task → route to preset (`rules/presets/presets.md`) +
  skill/agent (`CATALOG.md`) + model tier → Plan-if-non-trivial → asks-first safety gate on
  data/money/production mutation → dispatch to the chosen worker → report. Composes existing pieces
  (presets, skills, agents, the Plan agent); reimplements nothing.

### 11.3 `status` control plane
- `plugins/core/skills/status/SKILL.md` — the cross-surface aggregate: git/unmerged, doc freshness,
  the nightly scheduled-routines run, memory, backup age, connector/service health, per-surface
  enablement. Probe-don't-assume; distinguishes WARN (real drift) from "couldn't read on this
  surface" with the fallback for each gap. Builds on `surface-check` (which is current-surface only);
  reuses the nightly routine's findings instead of re-deriving them. Read-only — points at the
  acting skill/command (`merge-with-discretion`, `/clean-gone`, infra-health), never mutates.

## Repo bookkeeping
- CATALOG regenerated → now **23 skills / 2 agents / 5 commands**. Freshness gate green after every
  edit (ran `check-freshness.sh`; CI `freshness.yml` will confirm on push).
- PLAN 11.1/11.2/11.3 → `[x]` with DONE annotations. PROGRESS appended (cont. 12).
- Final-verification #14 (agentic OS) substantially met: routines run on cron; `/do` dispatches;
  `status` shows whole-system state. Live exercise of `/do`+`status` is organic on next real use;
  the first scheduled cron fire (or a manual `workflow_dispatch`) confirms unattended run.

## What is still surface-gated (unchanged by this work — see handoff 024 for the full map)
- **10.1** (plugin install + hook de-dup) — needs an interactive **Mac Code** session (handoff 022).
  Cannot be driven from a shell. That session writes handoff **026**.
- **10.2** (enable skills/connectors, paste always-loaded block, connect Cowork) — owner UI action;
  depends on 10.1.
- **10.3** hook-dependent items (#2/#3/#11) close at the end of the 10.1 session; the plugin-
  independent items (#5/#9/#12/#13) were verified green this session.

## Notes / gotchas for the next session
- The scheduled-routines workflow is **read-only by design** (no `contents: write`). If a future
  routine should write a report back to the repo, that is a deliberate permission bump + a commit
  path to add — not an oversight.
- `/do` and `status` are plugin components: they become live `/`-invocable everywhere only once the
  plugin is installed (10.1). In this repo they are usable as files now.
- Numbering: 023 audit → 024 work-map → 025 (this) Part 11 → 026 reserved for the Mac-Code 022 run.
- Suggested next: merge PR #1 (or keep it as the session branch), then the Mac-Code 022 sitting (10.1)
  and the owner-UI pass (10.2). Part 11 needed nothing further from another surface.
