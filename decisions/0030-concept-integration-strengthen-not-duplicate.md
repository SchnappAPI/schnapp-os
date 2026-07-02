# 0030 - Concept integration: strengthen existing components, decline four forks

Date: 2026-07-02. Status: accepted.

## Context

The owner asked to work a set of external articles (`OneDrive/_RESOURCES/New Articles/NEW/`, 24
files on sycophancy, context engineering, and skill systems) into schnapp-os, and to optimize the
structure where warranted. Four reader agents extracted integration-ready concepts by theme; the
recommendations were reconciled against the live repo. Most concepts *validated* existing
architecture (lean always-load lane, `@import` propagation, handoff packet, vault wiki, gated
learning loop). The genuine gaps were narrow.

## Decision

Integrate by **strengthening existing components, not adding siblings** (anti-stale):

- Anti-sycophancy: `working-style.md` + `standing-rules.sh` gain a **pushback-lock** (no
  capitulation under pressure without new evidence), style-vs-substance, confidence calibration.
  `council` gains prescriptive persona backstories + prohibitions + non-smoothing synthesis + a
  known-bad-idea smoke test. `grill-me` gains force-rank / score / red-team / pre-mortem modes.
- Context: new 9th global rule `context-discipline.md` (in-session rot); handoff-contents six-field
  spec + handoff-vs-memory boundary in `memory-lane.md` + `handoffs/TEMPLATE.md`; `context-budget`
  gains in-session rot signals + a subtraction pass.
- Skills: new `rules/modules/activity/scaffolding-choice.md` (primitive decision tree, CLI>MCP);
  new `session-to-skill` skill (procedure extraction, the gap between `learn-route` corrections and
  `rules-distill` principles); framework §H reconciled with the subtraction principle; "a rule is
  not a changelog" added to anti-stale; a rollback drill added to framework §E.

## Forks declined (the load-bearing part)

1. **Path-triggered auto-injection of modules.** The articles push a `rules.yaml`/classifier that
   auto-loads modules by the touched file's `paths:` glob. This contradicts locked ADR 0011 #4
   (deliberately no composer; explicit `@import` for auditability). Kept manual `@import`; instead
   made the dead `paths:` frontmatter *honest* via `scripts/assemble-context.sh` (reports/tests what
   would load; never silently injects). Auto-injection is a fragile hook with real double-load risk
   for a benefit the harness already gives.
2. **A skill-chaining envelope contract** (JSON `{status,data,metadata,error}` + file-based
   pipeline state). schnapp-os skills are advisory (they shape reasoning), not callable functions;
   building a chaining substrate now is capability ahead of need (framework §H).
3. **RAG/vector layer and per-folder `manifest.json`.** The vault is far under wiki-scale (low
   hundreds of notes); plain file reads + `MEMORY.md`/`index.md` win (Karpathy-wiki). A manifest
   duplicates the generated CATALOG/`paths:` projection (anti-stale).
4. **A standalone `/gsd` command** (plan/execute/review in clean contexts). Overlaps the installed
   `superpowers` writing-plans/executing-plans. Folded its two net-new rules (review against the
   original requirements not the plan; restart at phase boundaries) into `context-discipline.md`.

## Consequence

Global rule set is 8 -> 9 (`context-discipline`); template + every machine's `~/.claude/CLAUDE.md`
updated in the same change (this Mac done; others owe the one-liner). `session-to-skill`'s autonomous
nightly lane is a TDD'd follow-up, not wired here. Structural: `assemble-context.sh` (Phase 4). Full
plan: `docs/superpowers/plans/2026-07-02-concept-integration.md`.
