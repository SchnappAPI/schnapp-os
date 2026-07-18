# Handoff 059: os skill library (15 skills for cheaper sessions)

Date: 2026-07-17. Surface: Code (Mac). Prior: [058](058-single-registrar-component-move.md).

## Goal
Build a complete skill library so Sonnet-class sessions and mid-level engineers can debug, extend,
validate, and eventually advance schnapp-os without the expert. Multi-agent workflows for authoring
and review; correctness over cost.

## Facts established
- Owner's hardest live problem: cross-surface second-brain enablement - self-improving, proactive
  (fixes things before the owner notices), remembers all context, auto-enabled on any surface.
- Audience for the library: cheaper sessions on hookless surfaces and fresh machines.
- Beyond-SOTA per owner: learning-loop quality, cross-surface consistency guarantees, staleness
  prevention, intent-reading, systems-thinking, objective-over-literal, never repeating an issue.
- Owner fears hallucinating agents, so scopes agents strictly; worries this caps capability.
  Treated as a research problem (graduated autonomy with measured trust gates):
  skills/os-research-frontier/SKILL.md F6.
- No unwritten discipline rules: owner confirmed ("I am not sure"); discovery found none.

## Decisions + reasoning
- New skills live at repo-root `skills/`, NOT `.claude/skills/` (task text said .claude/skills/;
  repo doctrine bans it per handoff 058 single registrar; owner delegated the call).
- 15 skills: os-change-control, os-debugging-playbook, os-failure-archaeology,
  os-architecture-contract, agentic-os-reference, os-config-and-flags, os-build-and-env,
  os-run-and-operate, os-diagnostics-and-tooling, os-validation-and-qa, os-docs-and-writing,
  os-cross-surface-campaign (THE campaign skill), os-proof-and-analysis-toolkit,
  os-research-frontier, os-research-methodology.
- One fact one home held: new skills reference canonical rules/ADRs, embed only homeless facts.

## Actions + outcomes
- Phase 1: 9-reader discovery workflow (10 agents, ~957k tokens) -> briefing; 5 owner questions.
- Phase 2: 15 author agents in parallel (~1.4M tokens), each ground-truth verifying every
  command/path/claim before writing. Also shipped
  skills/os-diagnostics-and-tooling/scripts/diagnose-all.sh (read-only check scoreboard).
- Phase 3: factual + doctrine + usability reviewers (~770k tokens) -> 36 findings (19
  blocking/important); fixer re-verified each and applied (2 partially disproved, documented).
  Notable catches: third generated doc surfaces/claude-ai-skills.md missing from checklists,
  performance-optimizer agent not read-only, infra-health cadence 30-min not daily, stale
  2026-07-07 CORE-change watermark (really 2026-07-13, 6f74078), op-wrap now strips surrounding
  double quotes (vault fact predated hardening).
- Landing: check-freshness.sh header comment fixed (stale two-doc list, source of a copied error),
  CATALOG.md + surfaces/claude-ai-skills.md + handoffs/README.md regenerated, gates + test suite
  run, pushed, shell/install.sh re-run to symlink.
- Vault: memory/op-wrap-token-unquoted.md superseded in place (wrapper hardening noted).

## Status + next steps
Landed on main. Next session: nothing owed for this initiative. Candidate follow-ups live inside
the skills themselves: os-cross-surface-campaign phases marked OPEN (web wiring verification is
the first), os-research-frontier F1-F6 first steps.

## Open questions / edge cases
- ADR 0033 web user-scope verification remains OPEN (owner paste + observe; exact block in
  skills/os-cross-surface-campaign/SKILL.md Phase 2).
- os-research-frontier is deliberately all candidate/open; nothing there is settled doctrine.

## Copy-paste primer (new session)
15 os-* skills (+ agentic-os-reference) landed at skills/ on main 2026-07-17: reviewed, fixed,
gates green, CATALOG regenerated, symlinked. Start any schnapp-os work by loading
os-change-control before landing changes and os-debugging-playbook on any known-symptom failure;
the campaign for cross-surface enablement is skills/os-cross-surface-campaign/SKILL.md, first
open step = ADR 0033 web wiring verification.
