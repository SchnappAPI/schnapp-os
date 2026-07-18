#!/usr/bin/env python3
"""session_mine.py - Agent-SDK mining step for the auto-improvement lane (ADR 0037 P2).

Reads the fire-rate TSV (transcript-mine.py output) plus the raw transcript corpus and proposes
AT MOST ONE skill change per run: mint a new skill or sharpen an existing one, only when the same
non-obvious procedure recurs in >= 2 distinct sessions. It EDITS the working tree only:
  - the skill:      skills/<name>/SKILL.md (create or sharpen; frontmatter name + description)
  - the evidence:   scheduled-tasks/.mining-evidence.json - {"skill": "<name>", "evidence":
                    [{"transcript": "<abs path>", "quote": "<verbatim substring>"}, ...]}
The worker (session-mine-worker.sh) then VERIFIES every quote greps verbatim in its named
transcript (anti-hallucination), checks trigger-phrase collisions, regenerates the catalog
projections, and gates + commits deterministically. The LLM never touches git.

Safety mirrors learning_distill.py: file tools only (Read/Write/Edit/Grep/Glob, NO Bash),
writable roots = repo + read-only transcript corpus via add_dirs, bounded turns + timeout,
retry-once, non-zero exit on hard failure.

Usage:  session_mine.py [--dry-run]
Env:    MINING_TSV (fire-rate table path, required in live mode),
        MINING_TRANSCRIPT_ROOT (default ~/.claude/projects),
        MINING_MAX_TURNS (60), MINING_TIMEOUT_S (1200), MINING_MODEL (optional).
Exit:   0 = done (proposal written or clean no-proposal); non-zero = failure.
"""
from __future__ import annotations

import asyncio
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
TSV = os.environ.get("MINING_TSV") or ""
ROOT = Path(os.environ.get("MINING_TRANSCRIPT_ROOT")
            or Path.home() / ".claude" / "projects")
MAX_TURNS = int(os.environ.get("MINING_MAX_TURNS", "60"))
TIMEOUT_S = int(os.environ.get("MINING_TIMEOUT_S", "1200"))
MODEL = os.environ.get("MINING_MODEL") or None
EVIDENCE = REPO_ROOT / "scheduled-tasks" / ".mining-evidence.json"

SYSTEM_PROMPT = f"""You are the session-mining worker for the auto-improvement lane
(decisions/0037-auto-improvement-lane.md). Your job: find ONE recurring, non-obvious,
multi-step procedure in the owner's recent sessions that no existing skill covers, and
capture it as a skill - or make NO change if nothing clears the bar.

Inputs:
  - the fire-rate table below (which skills/agents/hooks actually fired, per session)
  - the transcript corpus at {ROOT} (JSONL; Read/Grep/Glob it, sample - do not read everything)
  - the existing skill catalog: skills/*/SKILL.md in this repo

The bar (ALL must hold - session-to-skill's identify step):
  1. The same procedure appears in >= 2 DISTINCT sessions (different .jsonl files).
  2. Multi-step and non-obvious (judgment calls involved), not a single tool call.
  3. Not already covered by an existing skill - if one nearly covers it, SHARPEN that skill
     instead of minting a sibling (one home, no overlap).
  4. Generalizable beyond the specific instances.

If a candidate clears the bar:
  - Write skills/<kebab-name>/SKILL.md (frontmatter: exactly `name` + a trigger-rich
    `description` that does not duplicate any other skill's trigger phrases; body: terse
    imperative, one screen, ends with a short "When NOT to use" pointing at the nearest
    sibling skills). Follow rules/global/writing-style.md. No em dashes.
  - Write {EVIDENCE} as JSON: {{"skill": "<name>", "evidence": [{{"transcript": "<abs path>",
    "quote": "<EXACT verbatim substring copied from that file, 30-200 chars>"}}, ...]}} with
    one entry per supporting session (>= 2, distinct transcript paths). Quotes must be
    copy-paste exact - the worker greps them and rejects the whole proposal on any miss.

If nothing clears the bar: write NOTHING and say so plainly. A run with no proposal is a
good run; a forced weak skill is the failure mode. Never touch git, code, CI, hooks, rules,
or anything outside skills/<name>/SKILL.md + the evidence file."""


def sdk_option_kwargs() -> dict:
    """Session options as a plain dict, SDK-free (pinned by test-session-mine-worker.sh)."""
    return dict(
        system_prompt=SYSTEM_PROMPT,
        allowed_tools=["Read", "Edit", "Write", "Grep", "Glob"],
        disallowed_tools=["Bash"],
        permission_mode="acceptEdits",
        max_turns=MAX_TURNS,
        cwd=str(REPO_ROOT),
        add_dirs=[str(ROOT)],
        model=MODEL,
    )


def log(msg: str) -> None:
    print(f"session-mine: {msg}", flush=True)


async def run_once(tsv_text: str) -> bool:
    from claude_agent_sdk import query, ClaudeAgentOptions

    options = ClaudeAgentOptions(**sdk_option_kwargs())
    prompt = f"Fire-rate table (transcript-mine.py):\n{tsv_text}"
    result_is_error = None
    async for message in query(prompt=prompt, options=options):
        if type(message).__name__ == "ResultMessage":
            result_is_error = bool(getattr(message, "is_error", False))
            log(f"result: is_error={result_is_error} "
                f"num_turns={getattr(message, 'num_turns', '?')}")
    if result_is_error is None:
        log("ERROR: stream ended with no ResultMessage.")
        return False
    return not result_is_error


async def main_async() -> int:
    if "--dry-run" in sys.argv:
        log("dry-run: no SDK call, no writes.")
        return 0
    if not TSV or not Path(TSV).is_file():
        log(f"ERROR: MINING_TSV missing or not a file: {TSV!r}")
        return 2
    tsv_text = Path(TSV).read_text(encoding="utf-8", errors="replace")
    for attempt in (1, 2):
        try:
            if await asyncio.wait_for(run_once(tsv_text), timeout=TIMEOUT_S):
                return 0
        except asyncio.TimeoutError:
            log(f"attempt {attempt} timed out after {TIMEOUT_S}s.")
        except Exception as exc:  # noqa: BLE001 - retry-once then fail loud
            log(f"attempt {attempt} failed: {exc}")
    log("ERROR: mining failed after retry.")
    return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main_async()))
