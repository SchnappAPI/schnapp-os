# 0021 — Learning-loop distillation runs on the file-scoped Claude Agent SDK, not `claude -p`

Date: 2026-06-30. Status: DECIDED (substrate-rethink P3; refines ADR 0016; preserves ADR 0019).

## Context
The nightly learning-worker distilled queued corrections by shelling out to
`printf '%s' "$PROMPT" | claude -p --dangerously-skip-permissions`: unbounded turns, ALL tools (incl.
Bash), and a silent `exit 0` when `claude` was missing or a run half-failed. Three of five agents in the
2026-06-30 substrate-rethink audit flagged it as the system's biggest fragility
([docs/repo-review-2026-06-30-substrate-rethink.md](../docs/repo-review-2026-06-30-substrate-rethink.md)).
The Claude Agent SDK is the off-the-shelf primitive for bounded, error-handled headless loops.

## Decision
The distillation step is a bounded, file-scoped Claude Agent SDK app
(`plugins/core/scripts/learning_distill.py`, package `claude-agent-sdk`):
- **Tools:** `allowed_tools=[Read, Edit, Write, Grep, Glob]`, `disallowed_tools=[Bash]`,
  `permission_mode="acceptEdits"`. No Bash/git/network — the LLM cannot run shell, git, or hooks.
- **Bounded:** `max_turns` (40), per-run asyncio timeout (900s), retry-once on transient failure.
- **Fail-loud:** reads `ResultMessage.is_error`; non-zero exit on any hard failure or missing-SDK import.
  Never exits 0 on a real failure (kills the old silent-exit-0 bug).
- **Auth (preserves ADR 0019):** inherits the subscription `CLAUDE_CODE_OAUTH_TOKEN` from the worker env;
  `ANTHROPIC_API_KEY` must NOT be set. PROVEN headless before cutover (an OAuth-only SDK run edited a file,
  exit 0, `is_error=False`, API key unset).
- The deterministic `learning-worker.sh` is UNCHANGED in role: it does ALL git/sync/commit/push/gate/archive
  around the call. `learning-gate.sh` and the `com.schnapp.memory-consolidation` LaunchAgent are UNCHANGED.

## Consequences
- The 3am bot gains retries, bounded iteration, timeouts, and real error propagation; failures alert
  (red/green via `ops-alert.sh`) instead of silently swallowing.
- **File-scoping is by tool-type, NOT a path sandbox.** With `acceptEdits` the model can write a `.md`
  outside `cwd` (verified in the auth proof: it wrote an absolute path under `$HOME`). What keeps edits
  in-scope is the system-prompt scoping (rules/ + memory/ only), `learning-gate.sh`, and the worker's
  clean-`main` reset that discards anything the gate holds. Strictly safer than the old all-tools
  `--dangerously-skip-permissions` run, but not a hard filesystem jail.
- New dependency: `claude-agent-sdk` in a dedicated venv `~/.venvs/learning-distill` (outside the repo;
  nothing to gitignore). The worker auto-uses it (`LEARNING_DISTILL_PYTHON` override; PATH `python3`
  fallback). The SDK spawns the `claude` CLI, which must stay on the launchd PATH.
- **Reversible:** revert the one `learning-worker.sh` block to the `claude -p` invocation (+ restore the
  PROMPT heredoc); `learning_distill.py` + the venv can remain inert. Rollback is one commit.
- Granting the bot broader tools (Bash/git/network) later = set `permission_mode="bypassPermissions"` +
  widen `allowed_tools` — explicitly the old dangerous unattended posture. Requires an owner decision and a
  superseding ADR; "deny / allow-once / allow-for-session" prompting is an interactive-only mechanism and
  cannot gate an unattended run.
