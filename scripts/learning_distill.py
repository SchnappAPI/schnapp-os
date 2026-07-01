#!/usr/bin/env python3
"""learning_distill.py - Agent-SDK distillation step for the nightly learning loop.

Replaces the `claude -p --dangerously-skip-permissions` shell-out in learning-worker.sh with a
bounded, file-scoped Claude Agent SDK run (ADR 0016 / agentic-OS Phase 4). It reads the local
capture queue, has a headless Claude Agent SDK session distill+classify each correction
(learn-route), and EDITS the target .md in the working tree. It does NOT git/commit/push/gate;
learning-worker.sh does that deterministically around this call (the LLM never touches git).

Safety vs the old `claude -p --dangerously-skip-permissions`:
  - allowed_tools = file edits only (Read/Edit/Write/Grep/Glob). NO Bash/network/git.
  - max_turns bounded; per-run asyncio timeout; retry-once on transient failure.
  - On any hard failure -> non-zero exit (wrapper resets the tree + alerts + keeps the queue).
    NEVER exits 0 on a real failure (kills the old silent-exit-0 bug).
Auth (preserves ADR 0019): inherits CLAUDE_CODE_OAUTH_TOKEN (subscription) from the parent env the
  worker sets; ANTHROPIC_API_KEY must NOT be set (would bill the API).

Usage:  learning_distill.py [--dry-run]
Env:    LEARNING_QUEUE (default <repo>/scheduled-tasks/.learning-queue.tsv),
        LEARNING_DISTILL_MAX_TURNS (40), LEARNING_DISTILL_TIMEOUT_S (900),
        LEARNING_DISTILL_MODEL (optional; default = inherit the CLI default).
Exit:   0 = done (edits made or clean no-op); non-zero = failure (queue must be preserved).
"""
from __future__ import annotations

import asyncio
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]  # scripts/ -> repo root
# Treat an empty LEARNING_QUEUE as unset (`or`, not a plain get default): an empty-but-SET var would
# otherwise become Path("") -> "." -> not a file -> every capture silently skipped. Belt-and-suspenders
# for the worker's mktemp-guarded filter (learning-worker.sh); a missing var still uses the default.
QUEUE = Path(os.environ.get("LEARNING_QUEUE") or REPO_ROOT / "scheduled-tasks" / ".learning-queue.tsv")
MAX_TURNS = int(os.environ.get("LEARNING_DISTILL_MAX_TURNS", "40"))
TIMEOUT_S = int(os.environ.get("LEARNING_DISTILL_TIMEOUT_S", "900"))
MODEL = os.environ.get("LEARNING_DISTILL_MODEL") or None

# Mirrors the prompt the old `claude -p` used (learning-worker.sh heredoc), minus the captures.
SYSTEM_PROMPT = """You are the nightly learning worker for this repo (scheduled-tasks/memory-consolidation.md).

For each queued correction below: distill it to a reusable principle and classify it with the
learn-route procedure (.claude/skills/learn-route/SKILL.md):
  - behavioral / how-to-work principle -> sharpen the EXISTING rule in rules/global/
  - durable fact -> supersede in memory/ (one fact, one file; bump updated:, source: correction)
  - mechanical / already-covered / duplicate -> make NO change and say so

To propose a change: EDIT the target .md file in the working tree and BUMP its frontmatter updated:
to today's date. Do NOT create a branch, commit, open a PR, or run any git/shell command -- just leave
the edited .md in the working tree. The worker gates the diff and commits clean changes to main itself.

DEDUPE first: if the principle is already present in the target file (or anywhere under rules/memory),
make NO change. Keep each edit SMALL and IN-SCOPE -- only .md files under rules/ or
memory/. Never touch code, CI, or anything else."""


def log(msg: str) -> None:
    print(f"learning-distill: {msg}", flush=True)


def read_captures() -> str:
    if not QUEUE.is_file() or QUEUE.stat().st_size == 0:
        return ""
    return QUEUE.read_text(encoding="utf-8", errors="replace")


async def run_once(captures: str) -> bool:
    """One distillation pass. True on clean completion, False on a hard (is_error) failure."""
    from claude_agent_sdk import query, ClaudeAgentOptions

    options = ClaudeAgentOptions(
        system_prompt=SYSTEM_PROMPT,
        allowed_tools=["Read", "Edit", "Write", "Grep", "Glob"],
        disallowed_tools=["Bash"],
        permission_mode="acceptEdits",
        max_turns=MAX_TURNS,
        cwd=str(REPO_ROOT),
        model=MODEL,
    )
    prompt = f"Queued corrections:\n{captures}"

    result_is_error = None
    async for message in query(prompt=prompt, options=options):
        # Detect the terminal ResultMessage by class name (robust across SDK versions).
        if type(message).__name__ == "ResultMessage":
            result_is_error = bool(getattr(message, "is_error", False))
            log(f"result: is_error={result_is_error} "
                f"duration_ms={getattr(message, 'duration_ms', '?')} "
                f"num_turns={getattr(message, 'num_turns', '?')}")
    if result_is_error is None:
        log("ERROR: stream ended with no ResultMessage.")
        return False
    return not result_is_error


async def main_async() -> int:
    dry_run = "--dry-run" in sys.argv
    captures = read_captures()
    if not captures.strip():
        log("queue empty -- nothing to distill.")
        return 0
    n = len([ln for ln in captures.splitlines() if ln.strip()])
    log(f"distilling {n} capture(s) (max_turns={MAX_TURNS}, timeout={TIMEOUT_S}s, "
        f"tools=Read/Edit/Write/Grep/Glob, NO Bash).")
    if dry_run:
        log("--dry-run: skipping the SDK call (no edits, no network).")
        return 0

    try:
        import claude_agent_sdk  # noqa: F401  -- fail LOUD, never silent exit 0
    except ImportError as exc:
        log(f"ERROR: claude-agent-sdk not importable ({exc}). Install it for the worker's python.")
        return 3

    for attempt in (1, 2):
        try:
            if await asyncio.wait_for(run_once(captures), timeout=TIMEOUT_S):
                log("done -- distillation completed; working tree holds any proposed edits.")
                return 0
            log(f"attempt {attempt}: result was is_error.")
        except asyncio.TimeoutError:
            log(f"attempt {attempt}: TIMEOUT after {TIMEOUT_S}s.")
        except Exception as exc:  # noqa: BLE001 -- transient SDK/CLI failure, retry once
            log(f"attempt {attempt}: {type(exc).__name__}: {exc}")
        if attempt == 1:
            log("retrying once...")
    log("ERROR: distillation failed after retry. Exiting non-zero (queue preserved by the worker).")
    return 1


def main() -> int:
    try:
        return asyncio.run(main_async())
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
