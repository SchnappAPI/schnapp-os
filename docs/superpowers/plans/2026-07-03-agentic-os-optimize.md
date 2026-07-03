# Agentic-OS optimize pass (navigability + loop hygiene) - Implementation Plan

**Goal:** Owner asked for a whole-repo optimize pass toward the target state: human-in-the-loop +
agentic OS hybrid, near-real-time self-improvement, nothing stale, per-directory orientation so an
agent pointed anywhere in the repo finds what it needs. Four parallel read-only audits
(navigability, freshness engine, learning loop, doc/state consistency) scoped this plan; the
consistency audit came back clean, so the work is the deltas below, strengthen-not-duplicate.

**Audit verdicts (2026-07-03):** consistency CLEAN (0 findings); learning loop LIVE (0-37 min
correction-to-rule latency, no silent drops); freshness engine strong on CI gates, gaps in
surfacing; navigation 7/27 dirs had orientation files. One live defect caught mid-audit: an audit
agent's task-notification (quoting the trigger regex) enqueued itself as a "correction", and the
archive held 6 machine-generated entries incl. a recursive queue-echo class.

**Constraints:** main-only (decisions/0016); commit/push per logical unit; box + PROGRESS line in
the same commit; writing-style.md; READMEs are orientation pointers, never restated mutable facts
(anti-stale).

---

## Tasks
- [x] T1. **Capture-nudge machine-prompt guards** - skip harness-generated prompts
  (`<task-notification>`/`<system-`/`<command-name>` prefixes), queue-echo (TSV shape in prompt,
  the meta-loop class), and >2000-char pastes; enqueue the prompt TEXT (jq extract, 1000-char cap)
  instead of the raw hook JSON envelope; re-check phrases against the text alone.
  `test-capture-enqueue.sh` 10->15 checks. Archive scrubbed to the 4 real corrections (6
  machine-generated entries removed so recurrence signatures stay honest).
- [ ] T2. **Loop visibility + freshness surfacing** - session-start gate gains `[learning]`
  pending-proposals section (open `learning-loop:` issues; the human-in-loop approvals could rot
  unseen); new `scripts/check-open-questions.sh` (+test) re-surfaces the resume-point handoff's
  "## Open ..." items as nightly Routine 5; nightly stale-facts sweep can now scan the real vault
  lane on CI via a `VAULT_READ_TOKEN`-gated checkout (SKIP stays honest without it).
- [ ] T3. **Navigation orientation files** - README.md for connectors/, decisions/, rules/,
  rules/modules/, docs/, docs/superpowers/, .claude/, scripts/, hooks/, .github/, templates/,
  scripts/tests/. Pointers + what-lives-here only; inventory stays in generated CATALOG.md; no
  per-directory CLAUDE.md (root CLAUDE.md + global lane already load; per-dir copies would drift).
  Fix README.md hardcoded current-plan pointer (rot trap).
- [ ] T4. **Vault memory refresh** - clear the `mac-connector-tooling.md` 7d+ review flag
  (re-verify against connectors/mac-mcp/server.py, bump `updated:`).
- [ ] T5. **Handoff 054 + close** - owner block for `VAULT_READ_TOKEN`; close this plan.

## Decisions
- READMEs not CLAUDE.md for reference directories: CLAUDE.md is for working-in-dir invariants,
  which the root file already covers; a README orients an arriving agent without joining the
  always-load layer.
- Recurrence alerting NOT rebuilt: learning-recurrence.sh already files gate-proposal issues
  (active, idempotent); the gap was owner visibility, closed by the session-gate `[learning]`
  section instead of a second alert channel.
- infra-health EXPECTED_AGENTS untouched: audit claim of missing agents was a misread; the list
  already covers memory-consolidation + vault-autocommit (verified live, all loaded + firing).

## Done when
All boxes flipped, 22/22 self-tests + freshness + writing-style + check-links green, CI green on
push, handoff written, owner block delivered for the one secret-gated step.
