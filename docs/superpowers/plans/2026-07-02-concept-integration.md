# Concept integration + full system eval - Implementation Plan

**Goal:** Work the "NEW folder" article concepts (sycophancy, context, skills) into schnapp-os,
strengthening existing components over adding siblings (anti-stale); then run a complete repo
evaluation, triage every finding, and fix on sight. Source articles:
`OneDrive-Schnapp/_RESOURCES/New Articles/NEW/` (24 files, read via 4 parallel extractor agents
2026-07-02).

**Method:** 4 reader agents extracted integration-ready concepts by theme. Recommendations were
reconciled against the live repo: keep-by-default, strengthen-not-duplicate, respect locked ADRs
(0011 no-composer, 0016 main-only). Net-new capability only where a genuine gap exists.

**Constraints (verbatim):** main-only + commit/push every logical unit; secrets are `op://` refs;
instruction files follow writing-style.md; ISO dates; no force-push; every state-changing commit
flips a box here + appends a PROGRESS.md line in the same commit.

---

## Phase 1 - Anti-sycophancy (sharpen, do not rebuild)
Existing: `working-style.md` no-sycophancy rule + `standing-rules.sh` every-message hook +
`council` (already independent subagents) + `grill-me`.

- [x] T1. **Pushback-lock** clause into `rules/global/working-style.md` + sync `hooks/standing-rules.sh`: do not reverse a correct assessment under mere pushback without new evidence; name the evidence; state uncertainty over false confidence; separate style (no flattery) from substance (say when genuinely correct, and why). *(done: working-style +3 bullets, standing-rules.sh clause (3) NO CAPITULATION)*
- [x] T2. **Sharpen `council`**: prescriptive persona backstories + prohibitions ("your job is not to be balanced"), non-smoothing synthesis, a known-bad-idea smoke test. *(done: backstories per voice, prohibitions in prompt shape, non-smoothing synthesis line, "Verify it works" smoke-test section)*
- [x] T3. **`grill-me` critique modes**: force-rank / 1-10-with-justification / red-team / pre-mortem, as selectable modes. *(done: "Critique modes" section)*

## Phase 2 - Context discipline (biggest gaps)
- [x] T1. New `rules/global/context-discipline.md` (9th global rule, lean): rot symptom self-check, compact 30-60min / restart at phase boundary, handoff triggers (20-40 turns / 30-50% window / phase boundary), signal-density > window-size, subagent-for-context-isolation, review-against-requirements-not-plan, per-step input audit; points at `context-budget` for diagnostics. Sync `templates/user-global-CLAUDE.md` (8->9) + this Mac's `~/.claude/CLAUDE.md`. *(done; CATALOG regenerated, 9 global rules; live ~/.claude/CLAUDE.md updated on this Mac; other machines owe the one-line @import - carried to handoff)*
- [x] T2. **Handoff quality spec**: 6-field template + include/exclude checklist in `docs/memory-lane.md`; new `handoffs/TEMPLATE.md`; document the handoff-vs-memory boundary. *(done; TEMPLATE.md not indexed - generator globs [0-9]*.md)*
- [x] T3. Extend `context-budget` skill: in-session rot signals (recall test, consistency check, token-spike) + the **subtraction pass** (three-questions rubric, appears-in-failures signal, recommend-removal) + an always-load token target. *(done; sections 5-6 + always-load target added)*

## Phase 3 - Skill-system discipline
- [ ] T1. New `rules/modules/activity/scaffolding-choice.md`: prompt/skill/module/hook/MCP/agent decision tree, MCP-~35x-cost + CLI-first, one-sentence-or-too-big. Extend `/do` step 1 (decide the primitive before routing). Regenerate CATALOG.
- [ ] T2. Reconcile framework §H "skill-ify repetition" with the **subtraction principle** (skill-ify only what clears the bar and does not overlap). Add "prompt is not a changelog" to `anti-stale.md`. Rollback-drill note in framework §E.
- [ ] T3. New `session-to-skill` skill (mine a transcript for a reusable multi-step procedure; the gap between `learn-route` corrections and `rules-distill` principles). ADR. Autonomous nightly lane = TDD'd follow-up (not wired here).

## Phase 4 - Structural fixes (from the agentic-context reader)
- [ ] T1. `scripts/assemble-context.sh`: given a path/task, print which rules/modules would load (consume the dead `paths:` frontmatter) + flag conflicts and the work/personal double-load. Wire into CI. TDD.
- [ ] T2. rules/ frontmatter: `updated:` on every global rule; extend the length/staleness posture to `rules/`. Index-first pointer in the SessionStart injection. Capability-registry gap (CATALOG omits MCP connectors) - decide extend-vs-defer.

## Phase 5 - Full evaluation + triage
- [ ] T1. Parallel read-only audits across dimensions (staleness/consistency, security/secrets, hooks/scripts correctness, docs/link integrity, skill/rule quality + overlap, automation/CI health). Rank findings by severity.
- [ ] T2. Triage: fix-on-sight the safe ones in-pass; flag owner-only (destructive/creds) with exact commands; write the eval report.
- [ ] T3. Finalize: regenerate CATALOG, ADRs for the forks decided, handoff, PROGRESS, push both repos, verify CI green.

## Decisions taken (recorded here, ADR'd in Phase 5)
- **Keep manual `@import`; do NOT build path-triggered auto-injection** (contradicts locked ADR 0011). Instead make `paths:` honest via the assemble-context harness (report/test, not silent load).
- **No skill-chaining envelope contract now** (most skills are advisory, not callable functions - building ahead of need).
- **No RAG/vector layer, no per-folder manifest.json** (vault is under wiki-scale; duplicates generated projections).
- **No standalone `/gsd` command** (overlaps superpowers writing/executing-plans); fold its two net-new rules (review-against-requirements; phase-boundary restart) into context-discipline.

## Done when
All three themes integrated with zero duplication and zero locked-ADR violations; the eval report
exists with every finding triaged (fixed or owner-flagged); CATALOG current; both repos clean +
pushed; CI green.
