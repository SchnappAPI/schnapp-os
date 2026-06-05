# 0006 — Finish sequence + a domain-first Capability layer

Date: 2026-06-05. Status: DECIDED (owner-confirmed).

## Context
Mid-build review: many `[~]` items, and the owner flagged "I do not see all the hooks/skills/agents/
commands I want." A 3-way parallel evaluation (rules-loading verification, claude-kit cohesion audit,
schnapp-kit inventory) produced three findings:

1. **Foundation is sound.** `.claude/rules/` auto-discovery AND `paths:` frontmatter scoping are NATIVE
   in current Claude Code (verified against code.claude.com/docs/en/memory.md + plugins-reference). The
   composition design (symlink modules into `<project>/.claude/rules/`, path-scoped) is valid — no
   architectural rework. Plugin components auto-discover by directory; manifest is metadata-only. So the
   pending verifies 2.4/3.4/5.6 are confirmations, not risk-gates.
2. **claude-kit is cohesive through Part 9** — no orphans, no dead files, no stale cross-refs; only the
   Part-10 plugin manifests and an `agents/` dir are absent (both expected).
3. **The real gap:** claude-kit has 3 skills / 1 command / 0 agents (all infrastructure). schnapp-kit
   (frozen at `~/code/schnapp-kit`, tag `record-2026-06-03`) has 134 skills / 39 agents / 59 commands /
   21 hooks. The plan NEVER had a phase to select + build the PRODUCTIVE capability layer.

## Decision
**A. A Capability layer is inserted as a phase BEFORE Part 10** (the productive teeth the plan lacked).
**Scope = DOMAIN-FIRST LEAN** (owner choice): build ONLY capabilities that (1) serve the owner's actual
platform — Python ETL → SQL Server 2022, GitHub Actions/LaunchAgents scheduling, Power Query M, sports
data, web tools, Quickbase, AppFolio, policy/procedure docs — AND (2) are not already provided by the
keep-set plugins (superpowers/caveman/plugin-dev/frontend-design), the available skills (anthropic-skills,
`data:*`, `design:*`, deep-research), or the MCP connectors. Anything that already exists is COMPOSED/
referenced, never rebuilt. The other ~120 schnapp-kit skills stay an ON-DEMAND archive, pulled only when
a real task needs one. Rationale: the owner fled schnapp-kit because of SPRAWL (19 plugins, ~4 overlapping
memory systems, ~4 review systems); bulk-migrating would recreate exactly that. Lean + non-duplicative is
the objective.

**B. Finish the agentic OS (Part 11) as the capstone** (owner choice: "don't skip anything"), but LAST —
after the foundation verifies, the capability layer, and surface wiring.

**C. Part numbers stay STABLE** (Part 10 = wire/package, Part 11 = agentic OS). Renumbering would ripple
"Part 10"/"Part 11" references across decisions/0005, surface profiles, settings.json, hooks.json, and
memory — the exact backtracking-staleness to avoid. The Capability layer is a lettered phase (C.0–C.3)
inserted before Part 10, not a renumber.

## Order (detail in PLAN.md "Finish sequence")
Foundation verify (2.4/3.4/5.6) → Capability layer (C.0 gap-inventory → C.1 build-gap → C.2 presets →
C.3 archive) → Part 10 (package + wire surfaces) → Part 11 (agentic OS) → final 14-point sweep. Build the
capability set BEFORE packaging so the plugin ships complete and the final verify runs once (no rework).

## Working-method note (owner asked me to improve + learn)
- Verify load-bearing ASSUMPTIONS first (the rules-loading mechanism) before building more on them.
- Evaluate the WHOLE system (parallel read-only agents returning conclusions), not one part at a time.
- Before restructuring anything other docs reference, check the blast radius and prefer stable
  identifiers (working-style.md "think in systems" already mandates this — applied here after catching a
  renumber that would have rippled).
