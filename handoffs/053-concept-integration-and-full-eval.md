# Handoff 053: NEW-folder concept integration + full repo eval/triage

Date: 2026-07-02. Surface: Claude Code (Mac). Prior: [052](052-streamline-closeout-audit.md).

## Goal
Work the "NEW folder" article concepts (sycophancy, context, skills) into schnapp-os, strengthening
existing structure over adding siblings; then completely evaluate the repo, triage every finding,
and leave a flawless system. Owner delegated all resolvable decisions (no asking).

## Facts established
- 24 articles in `OneDrive/_RESOURCES/New Articles/NEW/`, read via 4 parallel extractor agents,
  reconciled against the live repo (keep-by-default, respect locked ADRs 0011/0016).
- The repo is mature and internally consistent; the 6-dimension audit verdict was keep-by-default.
  Security audit CLEAN (zero P0/P1). Full test suite now 21/21. CI green on every push.
- Global rule set went 8 -> 9 (added `context-discipline`). This Mac's live `~/.claude/CLAUDE.md`
  was updated to import the 9th rule (verified 9 imports); OTHER machines still owe that one @import line.

## Decisions + reasoning
- **Strengthen, do not duplicate** (ADR [0030](../decisions/0030-concept-integration-strengthen-not-duplicate.md)):
  every technique mapped onto an existing rule/skill/hook.
- **Four forks declined** (ADR 0030): path-triggered auto-injection (contradicts locked ADR 0011 -
  built `assemble-context.sh` instead), skill-chaining envelope, RAG/manifest, standalone `/gsd`.
- **Gate the recurring broken-link class** (ADR 0026 logic): built `check-links.sh` + CI wiring after
  the audit found 3 more broken links (Phase-2 T3b had fixed 50).
- **Do NOT relocate the frozen snapshots** (AUDIT.md + dated `docs/*-2026-*.md`): overrode the audit's
  move rec because moving them a level deeper breaks 17 internal `../` links across frozen docs for
  cosmetic gain, they are the same frozen-history class as handoffs/decisions the repo keeps in place,
  and they are already excluded from both live gates. Added an AUDIT.md supersession banner instead.

## Actions + outcomes
Integration (commits 1d1a016, d931299, c94b911, 2684627): pushback-lock in working-style +
standing-rules hook; sharpened `council` (backstories/prohibitions/non-smoothing/known-bad test);
`grill-me` critique modes; new `context-discipline.md` (9th rule); handoff-contents 6-field spec +
`handoffs/TEMPLATE.md` + handoff-vs-memory boundary in memory-lane; `context-budget` rot signals +
subtraction pass; `scaffolding-choice.md` + `/do` primitive step; framework §H subtraction reconcile
+ §E rollback drill; anti-stale "rule is not a changelog"; new `session-to-skill` skill;
`assemble-context.sh` (+14-case test, CI).
Eval/triage (commits 24aaf03, 9108a2c, 6f6cf57, 7bee9a3, + this): fixed rule-count drift, 3 broken
links, the stale `memory/credentials-state` surface-link class, a miscited ADR; **fixed the MultiEdit
guard bypass** (secret-scan/lint gates were not routed MultiEdit writes); **fixed the #41 footgun**
(infra-health test filed a real GitHub issue -> added OPS_ALERT_DISABLE + test isolation; ran the
real probe green -> #41 auto-closed); `check-links.sh` gate; MCP-connector registry in CATALOG;
index-first SessionStart orientation; AUDIT.md banner; scan-secrets shellcheck-disable corrected.
Outcome: 21/21 tests, shellcheck clean (SC2001 style excepted), freshness+writing-style+check-links
green, CI green, both repos clean+pushed.

## Status + next steps
Concept-integration plan (`docs/superpowers/plans/2026-07-02-concept-integration.md`) CLOSED: all 5
phases done, all boxes flipped. Repo clean+pushed, CI green. Next session starts fresh.

## Open questions / edge cases (owner-only)
1. **Other machines** owe the one `@import ...context-discipline.md` line in their `~/.claude/CLAUDE.md`.
2. **Vault `process-inbox.yml` dead 17 days** (P0, in `SchnappAPI/schnapp-vault`, NOT schnapp-os):
   empty `ANTHROPIC_API_KEY` + `brain_agent.py` hardcodes a pre-migration OneDrive path; 2 Inbox files
   unprocessed since 2026-05-28; no alarm watches a failed vault workflow. DECIDE: retire the workflow,
   or fix the `_brain` path to repo-relative + set `ANTHROPIC_API_KEY` (op:// ref) as a vault secret.
3. **Desktop OAuth token** (from handoff 052, still open): `rm ~/Desktop/sk-ant-oat01-[REDACTED].textClipping`.
4. Accepted-cosmetic: 2 SC2001 style nits in `session-start-gate.sh` (echo|sed indent); leave.

## Copy-paste primer (new session)
Concept-integration + full-eval initiative CLOSED 2026-07-02 (plan doc
`docs/superpowers/plans/2026-07-02-concept-integration.md`, ADR 0030): NEW-folder sycophancy/context/
skills concepts integrated by strengthening existing rules/skills; 6-dimension audit run and triaged
in 4 commit batches (headline fixes: MultiEdit secret-scan bypass, infra-health #41 footgun, new
check-links gate, MCP-connector registry, 9th global rule context-discipline). 21/21 tests, CI green,
both repos clean. Owner-only follow-ups in handoff 053 §Open (vault process-inbox dead workflow;
per-machine ~/.claude 9th-rule @import; Desktop token rm). Resume point = this handoff.
