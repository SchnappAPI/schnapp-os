# Handoff 041 — Step 3 DONE: the learning loop is LIVE on the Agent SDK

**Date:** 2026-06-30. **Surface:** Claude Code on the primary Mac (`~/code/schnapp-os`).
**Supersedes** handoff 040's "Step 3 DEFERRED" — Step 3 is now BUILT, VERIFIED, and LIVE on `main`.
**Resume point for:** the remaining substrate-rethink phases (P1/P2/P3). Step 3 needs nothing further.

---

## What shipped (all on `origin/main`)
- `49f79f6` **cutover** — `plugins/core/scripts/learning_distill.py` (bounded, file-scoped
  `claude-agent-sdk` app) replaces `printf … | claude -p --dangerously-skip-permissions` in
  `learning-worker.sh`. **ADR 0021**. `learning-gate.sh` + the `com.schnapp.memory-consolidation`
  LaunchAgent are UNCHANGED. Header comments refreshed to the file-scoped model.
- `005da67` **fix(security)** — the worker's auth line logged the **1Password SA token VALUE**
  (`OP_SA:${OP_SERVICE_ACCOUNT_TOKEN:+set}${OP_SERVICE_ACCOUNT_TOKEN:-UNSET}` — the `:-` arm emits the
  value when set → stdout → `memory-consolidation.log`). Fixed to presence-only (`set`/`UNSET`); the 1
  leaked log line scrubbed. **Owner DECLINED rotation 2026-06-30** (local-log[scrubbed]+transcript only =
  within the accepted-risk envelope; [[credentials-state]]).
- `5225bb6` / `71e6916` — memory records of the leak + the rotation decision.

## Verified, not assumed
- **Make-or-break auth:** subscription OAuth (`CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_API_KEY` unset)
  authenticates the SDK headless and edits a file, exit 0. ADR 0019 cost model intact.
- **Unit:** SDK API fields present; `--dry-run`/empty-queue plumbing; `shellcheck` CLEAN;
  `test-learning-worker.sh` 7/0 (even under `/bin/bash` 3.2).
- **e2e:** a controlled throwaway-queue run AND a REAL live LaunchAgent run both PASSED
  (`is_error=False`, deduped → no edit, archived, `last exit 0`, **no token re-leak**). The queue's real
  captures are drained; the loop is live on the SDK path; `infra-health` monitors the agent.

## Facts a fresh session needs
- **Venv:** `~/.venvs/learning-distill` (`claude-agent-sdk` 0.2.110). The worker auto-uses it
  (`LEARNING_DISTILL_PYTHON` override; PATH `python3` fallback). Outside the repo (nothing to gitignore).
- **Safety model:** file-scoping is by **tool type** (no Bash/git/network), NOT a path sandbox — with
  `acceptEdits` the model can write outside `cwd`. The guardrails are the system-prompt scope +
  `learning-gate.sh` + the worker's clean-`main` reset. See ADR 0021.
- **Incidental win:** the cutover deleted the em-dash-laden `PROMPT` heredoc that made the OLD worker
  `syntax error` under launchd's empty locale (bash 3.2). Current worker parses clean under empty locale.
  The codebase still uses em-dashes against the "no em dashes" rule — **optional style sweep, not a defect.**
- **Permissions (this session, owner request):** user-scope `~/.claude/settings.json` → `bypassPermissions`
  + broad allowlist + removed the `git push`/`launchctl kill` ask-prompts. **Machine-wide**: schnapp-os
  keeps its hooks (force-push guard, secret-scan), other repos have no prompt guard under bypass. Effective
  at next session start.
- **Worktree:** the session worktree `claude/quizzical-hugle-caf6a0` held only byte-identical duplicates of
  the cutover (branch had 0 commits ahead of `main`). Cleanup script: `~/cleanup-worktree.sh`.
- **Rollback (if ever):** revert the one `learning-worker.sh` block to the `claude -p` invocation + restore
  the PROMPT heredoc; `learning_distill.py` + the venv can stay inert. One commit.

## Next — substrate-rethink phases, NOT started
Per [docs/repo-review-2026-06-30-substrate-rethink.md](../docs/repo-review-2026-06-30-substrate-rethink.md):
- **P1 prune/dedup (low risk):** delete `surfaces/code-work-machines.md` (STUB), retire `check-op-refs.sh`
  (warn-only), merge `context/personal`+`context/work`, resolve the `schnapp-os-core` double-load, CI-enforce
  the memory frontmatter schema.
- **P2 GitHub official MCP swap:** parity PROVEN (40/43, superset). Owner-only legs: OAuth-consent the
  `api.githubcopilot.com/mcp` connector on Code/web/iPhone; check the SchnappAPI org "MCP servers in Copilot" policy.
- **P3 Obsidian OAuth→bearer:** auth-only, zero functionality loss. Owner-only: Cloudflare portal + re-auth the connector.

Live status is always [PLAN.md](../PLAN.md) / [PROGRESS.md](../PROGRESS.md), not this snapshot.
