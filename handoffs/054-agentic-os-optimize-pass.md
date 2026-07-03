# Handoff 054: Agentic-OS optimize pass (navigability + loop hygiene)

Date: 2026-07-03. Surface: Claude Code (Mac). Prior: [053](053-concept-integration-and-full-eval.md).

## Goal
Owner asked for a whole-repo optimize pass toward: human-in-the-loop + agentic OS hybrid,
near-real-time self-improvement, nothing stale, CLAUDE.md/orientation everywhere needed, agent
navigability. Plan: [2026-07-03-agentic-os-optimize.md](../docs/superpowers/plans/2026-07-03-agentic-os-optimize.md) (CLOSED).

## Facts established
- Four parallel read-only audits scoped the work. Consistency audit: CLEAN (0 findings across
  links/CATALOG/wiring/templates/hygiene). Learning loop: LIVE end to end, 0-37 min
  correction-to-rule latency, no silent drops. Freshness: CI gates strong; surfacing gaps.
  Navigation: 7/27 dirs had orientation files.
- Two audit claims were WRONG and discarded after live verification: "3 LaunchAgents not loaded"
  (misread of `launchctl list`; all 3 loaded + firing - memory-consolidation had a live PID
  mid-audit) and "infra-health misses agents" (EXPECTED_AGENTS already lists them). Lesson:
  subagent findings get verified before action.
- Live defect caught mid-session: an audit agent's task-notification QUOTING the correction regex
  enqueued itself into the learning queue; archive held 6 machine-generated entries incl. a
  recursive queue-echo class (pasted queue contents re-matching). Distiller had correctly
  no-op'd them (gate held), but signatures/eval were polluted.
- 053 open items re-checked: vault process-inbox.yml GREEN (fixed 2026-07-02, live-verified run
  28628196945); Desktop OAuth textClipping already deleted. Both closed.

## Decisions + reasoning
- **No per-directory CLAUDE.md files**: root CLAUDE.md + the global lane already load; per-dir
  copies of invariants would drift. Orientation = README.md (pointer-style, no restated mutable
  facts). 12 added.
- **Recurrence alerting not rebuilt**: learning-recurrence.sh already files gate-proposal issues
  (active + idempotent). The real gap was owner VISIBILITY of pending proposals; closed in the
  session-start gate instead of a second alert channel.
- **Capture guards, not capture removal**: precision-over-recall philosophy kept; guards skip
  harness-generated prompts (`<task-notification>`/`<system-`/`<command-name>`), queue-echo TSV
  shape, >2000-char pastes; enqueue is the jq-extracted prompt text (1000-char cap), never the
  raw hook JSON envelope.

## Actions + outcomes
Commits cb8afb3 (T1+T2 files), 68c22c8 (T2 box), 68e392a (T3), vault 59730e1 (T4), + this (T5).
- T1 capture-nudge guards + `test-capture-enqueue.sh` 10->15 checks; archive scrubbed to the 4
  real corrections.
- T2 session-start gate `[learning]` pending-proposals section (open `learning-loop:` issues);
  new `scripts/check-open-questions.sh` (+8-check test) as nightly Routine 5 (immediately
  surfaced 053's 4 open items); `scheduled-routines.yml` vault checkout gated on
  `VAULT_READ_TOKEN` so nightly stale-facts scans the real lane (SKIP stays honest without it).
- T3 12 orientation READMEs; PLAN.md "Current:" rot trap removed; root README map completed.
- T4 `mac-connector-tooling` memory fact re-verified against server.py (write_text overwrite +
  `_no_op_identity_env` unchanged), `updated:` bumped, vault pushed.
Outcome: 22/22 self-tests, freshness + writing-style + check-links green, CI green, both repos
clean + pushed.

## Status + next steps
Plan CLOSED, all boxes flipped. Nightly routine now re-surfaces open owner items; session gate
now surfaces pending learning-loop proposals.

## Open questions / edge cases (owner-only)
1. **Set `VAULT_READ_TOKEN`** so the nightly stale-facts sweep scans the vault lane on CI:
   ```sh
   op read 'op://web-variables/GITHUB_PAT_VAULT_READ/credential' | gh secret set VAULT_READ_TOKEN --repo SchnappAPI/schnapp-os --body-file - \
     && gh workflow run scheduled-routines.yml --repo SchnappAPI/schnapp-os \
     && sleep 60 && gh run list --repo SchnappAPI/schnapp-os --workflow scheduled-routines.yml --limit 1
   ```
   If no vault-read PAT item exists yet, mint a fine-grained PAT (SchnappAPI/schnapp-vault,
   Contents: read) and store it at that reference first (`<FILL:op-item-name>` if you pick a
   different name).
2. **Other machines** still owe the one-time per-machine wires from 053/ADR 0031: the
   `context-discipline.md` `@import` line in `~/.claude/CLAUDE.md` + the user-scope
   capture-nudge/standing-rules hooks in `~/.claude/settings.json`.

## Copy-paste primer (new session)
Agentic-OS optimize pass CLOSED 2026-07-03 (plan docs/superpowers/plans/2026-07-03-agentic-os-optimize.md):
4-audit sweep (consistency CLEAN; loop LIVE 0-37min; two audit claims disproved live). Shipped:
capture-nudge machine-prompt guards + prompt-text enqueue (live-caught self-capture bug, archive
scrubbed), session-gate [learning] pending-proposals, check-open-questions.sh nightly Routine 5,
VAULT_READ_TOKEN-gated CI vault checkout for stale-facts, 12 orientation READMEs (no per-dir
CLAUDE.md by design), PLAN.md rot-trap fix, mac-connector-tooling fact re-verified. Owner-only:
handoff 054 §Open (VAULT_READ_TOKEN secret; per-machine wires). Resume point = this handoff.
