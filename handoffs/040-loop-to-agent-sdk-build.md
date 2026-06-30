# Handoff 040 — Loop → Agent SDK build (Step 3 of the substrate rethink)

**Date:** 2026-06-30. **Surface:** Claude Code on the primary Mac (`~/code/schnapp-os`).
**Resume point for:** building the Agent-SDK distillation app that replaces `claude -p` in the
nightly learning loop. Steps 1–2 are DONE; this is the greenlit, designed-and-approved Step 3 build.

> This handoff is self-contained and embeds the full app source + the exact worker diff. A new
> session can execute it top-to-bottom. Canonical plan: [docs/repo-review-2026-06-30-substrate-rethink.md](../docs/repo-review-2026-06-30-substrate-rethink.md).

---

## 0. Where we are (state)

A substrate-rethink review (5-agent audit) produced [docs/repo-review-2026-06-30-substrate-rethink.md](../docs/repo-review-2026-06-30-substrate-rethink.md).
Owner decisions: **Loop→Agent SDK = GREENLIT**; GitHub + Obsidian swaps conditional on no-loss.
Execution has run one step at a time with owner OK gates.

**Done + pushed this session (main, CI green, 0 ahead/behind):**
- `62a837c` P0 defects (security: stripped hardcoded `runner-Lake4971` fallback in `connectors/mac-mcp/server.py:62`; 2 stale-status reconciles; 3 memory `scope:` fields)
- `a5f0476` silent-stop hardening (learning-worker red/green alerts; `render-health.yml` heartbeat for op-mcp+memory-mcp — verified live green)
- `2abeddd` the assessment doc
- `5eb069c` GitHub MCP parity PROVEN (40/43, superset, drops the portal hop) + brain-watcher catch + plugin version align
- `1ad4824` plugin.json description corrected to ADR-0011-#2 hook delivery
- `b99e66e` **Step 1 DONE** — restored `com.schnapp.brain-watcher` (owner `launchctl load`; verified healthy) + added it to `EXPECTED_AGENTS` in `check-infra-health.sh` (live probe shows 11/11 🟢)

**Step 2 DONE (verified, not assumed):** Agent SDK feature set confirmed against the authoritative
`claude-api` skill + the in-session `agent-sdk-dev` plugin. All grounding claims are real (scheduled
deployments, vault env-var secrets, memory stores, task budgets, self-hosted sandboxes). **Decision:
use the Agent SDK as a LIBRARY run by the existing LaunchAgent — NOT Managed-Agents cloud deployments**
(the learning-worker is Mac-coupled: local git-ignored queue + local repo + op-wrap secrets + git push
from the Mac; cloud would force the queue into the repo and re-add a Mac worker daemon anyway).

---

## 1. The task (greenlit + design approved)

Replace the fragile distillation step in the nightly learning loop:
`printf '%s' "$PROMPT" | claude -p --dangerously-skip-permissions` (unbounded turns, ALL tools incl
Bash, silent-exit-0 failure modes) → a **bounded, file-scoped Claude Agent SDK Python app**.

**Surgical swap — keep everything that works, change one block:**
- `learning-worker.sh` keeps ALL orchestration (queue check, auth resolution, clean-`main` sync, the
  `learning-gate.sh` call, commit, push, hold→issue, archive, the red/green `ops-alert` calls, dry-run).
  Only the distillation invocation changes.
- NEW `plugins/core/scripts/learning_distill.py` (full source in §4) — the Agent SDK app: file-edit
  tools only (`Read/Edit/Write/Grep/Glob`, **no Bash**), `permission_mode="acceptEdits"`, bounded
  `max_turns`, asyncio timeout, retry-once, reads `ResultMessage.is_error`, exits 0 on success /
  non-zero on failure, `--dry-run`, fail-loud import guard (NEVER silent exit 0).
- `learning-gate.sh` **UNCHANGED** (deterministic bash; junk still can't auto-land; exit 0 approve / 1 hold).
- LaunchAgent plist **UNCHANGED** (`com.schnapp.memory-consolidation` calls `learning-worker.sh`).
- New dependency: `claude-agent-sdk` installed for the worker's python (use a venv — see §5).

**Why this is safer than today:** file-only tools mean the model physically cannot run git/shell/network
(vs `--dangerously-skip-permissions` = all tools). Bounded turns + timeout + retry. The deterministic
wrapper does ALL git/gate/commit/push. Fully reversible (revert one block to `claude -p`).

---

## 2. Authoritative Agent SDK API facts (verified via WebFetch of code.claude.com/docs/en/agent-sdk/python)

- Package: **`claude-agent-sdk`** (`pip install claude-agent-sdk`). `from claude_agent_sdk import query, ClaudeAgentOptions`.
- `async for message in query(prompt=str, options=ClaudeAgentOptions): ...` — async iterator of Message objects.
- `ClaudeAgentOptions` fields used: `system_prompt`, `allowed_tools` (list of tool-name strings like
  `"Read"`,`"Edit"`,`"Write"`,`"Grep"`,`"Glob"`,`"Bash"`), `disallowed_tools`, `permission_mode`
  (`"default"`|`"acceptEdits"`|`"plan"`|`"dontAsk"`|`"bypassPermissions"`), `max_turns`, `cwd`, `model`,
  `env`, `cli_path`.
- **Auth (CRITICAL — preserves ADR 0019 cost model):** the SDK reads `CLAUDE_CODE_OAUTH_TOKEN` (also
  `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN`). The subscription OAuth token works → bills the
  subscription, **NOT** the API. **`ANTHROPIC_API_KEY` must NOT be set** in the worker env (it would
  win and bill the API). The worker's existing auth block (worker lines ~96-113) exports
  `CLAUDE_CODE_OAUTH_TOKEN` from `LEARNING_CLAUDE_TOKEN_REF` (op://) — keep it.
- The SDK **spawns the `claude` CLI** subprocess (must be on PATH — the Mac has it; the worker uses
  `claude -p` today). `ResultMessage` carries `is_error`, `result`, `duration_ms` (detect by class
  name to avoid import-path fragility across SDK versions — see source).

---

## 3. THE flagged caveat to PROVE before cutover (verify-before-betting)

That `claude-agent-sdk` accepts the **subscription `CLAUDE_CODE_OAUTH_TOKEN` headless** (no API key).
Very likely yes (same `claude` engine the worker already drives), but PROVE it, don't assume:

```bash
# On the Mac. Resolve the OAuth token the same way the worker does, then run a throwaway query
# with ONLY the OAuth token set (no API key) against a temp file; confirm it edits + exits 0.
REF="$(/usr/bin/grep -o 'op://[^<]*' ~/Library/LaunchAgents/com.schnapp.memory-consolidation.plist | head -1)"   # LEARNING_CLAUDE_TOKEN_REF
# (or read it from the repo plist template scheduled-tasks/com.schnapp.memory-consolidation.plist)
test -n "$REF" && echo "token ref: $REF"
# then in the venv (see §5): unset ANTHROPIC_API_KEY; export CLAUDE_CODE_OAUTH_TOKEN="$(op read "$REF")"
# and run a 1-capture distill against /tmp throwaway queue+target. Expect: file edited, exit 0.
```
If this FAILS (token rejected headless), STOP and reassess — the fallback is `ANTHROPIC_API_KEY` (bills
the API, owner decision required) or keep `claude -p`. **Do not cut over until this passes.**

---

## 4. FULL SOURCE — write this verbatim to `plugins/core/scripts/learning_distill.py`

```python
#!/usr/bin/env python3
"""learning_distill.py — Agent-SDK distillation step for the nightly learning loop.

Replaces the `claude -p --dangerously-skip-permissions` shell-out in learning-worker.sh with a
bounded, file-scoped Claude Agent SDK run (ADR 0016 / agentic-OS Phase 4). It reads the local
capture queue, has a headless Claude Agent SDK session distill+classify each correction
(learn-route), and EDITS the target .md in the working tree. It does NOT git/commit/push/gate —
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

REPO_ROOT = Path(__file__).resolve().parents[3]
QUEUE = Path(os.environ.get("LEARNING_QUEUE", REPO_ROOT / "scheduled-tasks" / ".learning-queue.tsv"))
MAX_TURNS = int(os.environ.get("LEARNING_DISTILL_MAX_TURNS", "40"))
TIMEOUT_S = int(os.environ.get("LEARNING_DISTILL_TIMEOUT_S", "900"))
MODEL = os.environ.get("LEARNING_DISTILL_MODEL") or None

# Mirrors the prompt the old `claude -p` used (learning-worker.sh heredoc), minus the captures.
SYSTEM_PROMPT = """You are the nightly learning worker for this repo (scheduled-tasks/memory-consolidation.md).

For each queued correction below: distill it to a reusable principle and classify it with the
learn-route procedure (plugins/core/skills/learn-route/SKILL.md):
  - behavioral / how-to-work principle -> sharpen the EXISTING rule in plugins/core/rules/global/
  - durable fact -> supersede in memory/ (one fact, one file; bump updated:, source: correction)
  - mechanical / already-covered / duplicate -> make NO change and say so

To propose a change: EDIT the target .md file in the working tree and BUMP its frontmatter updated:
to today's date. Do NOT create a branch, commit, open a PR, or run any git/shell command -- just leave
the edited .md in the working tree. The worker gates the diff and commits clean changes to main itself.

DEDUPE first: if the principle is already present in the target file (or anywhere under rules/memory),
make NO change. Keep each edit SMALL and IN-SCOPE -- only .md files under plugins/core/rules/ or
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
```

`chmod +x plugins/core/scripts/learning_distill.py`. (Python file → snake_case per naming-discipline.)

---

## 5. The exact `learning-worker.sh` edit (cutover — do LAST, after §3 + §6 pass)

`learning-worker.sh` already has the hardening from `a5f0476` (the `alert()` helper + red/green calls).
Two changes:

**(a) DELETE the now-unused PROMPT heredoc.** Remove the whole block that builds `PROMPT="$(cat <<PROMPT_EOF … PROMPT_EOF\n)"` (the `.py` reads the queue itself). Keep the `cd "$REPO_ROOT"` line and the auth-resolution block after it.

**(b) REPLACE the claude invocation.** Find this exact block (added in `a5f0476`):
```bash
echo "learning-worker: processing $(wc -l < "$Q" | tr -d ' ') capture(s) via claude -p ..."
# Full capability (owner directive): all tools incl. Bash, no permission prompts. The prompt steers
# it to edit-only and let the worker gate+commit; the gate is the default path, not a hard sandbox.
if ! printf '%s' "$PROMPT" | claude -p --dangerously-skip-permissions; then
  git reset -q --hard origin/main 2>/dev/null || true
  echo "learning-worker: ERROR — claude run failed; queue NOT drained (captures preserved)." >&2
  alert red learning-worker "Learning worker failed" "claude -p run failed; queue preserved, will retry"
  exit 1
fi
```
Replace with:
```bash
echo "learning-worker: processing $(wc -l < "$Q" | tr -d ' ') capture(s) via Agent SDK (learning_distill.py) ..."
# Bounded, file-scoped Agent SDK distillation (no Bash/git/network). The worker gates+commits the diff.
export LEARNING_QUEUE="$Q"
DISTILL_PY="$REPO_ROOT/plugins/core/scripts/learning_distill.py"
DISTILL_PYTHON="${LEARNING_DISTILL_PYTHON:-$HOME/.venvs/learning-distill/bin/python}"
[ -x "$DISTILL_PYTHON" ] || DISTILL_PYTHON="$(command -v python3)"
if ! "$DISTILL_PYTHON" "$DISTILL_PY"; then
  git reset -q --hard origin/main 2>/dev/null || true
  echo "learning-worker: ERROR — Agent SDK distillation failed; queue NOT drained (captures preserved)." >&2
  alert red learning-worker "Learning worker failed" "Agent SDK distillation failed; queue preserved, will retry"
  exit 1
fi
```
Everything after (gate/commit/push/hold-issue/archive/green-alert) is UNCHANGED.

**Venv (the new dependency).** `claude-agent-sdk` needs a python the LaunchAgent can use. The agent's
PATH is `/usr/local/bin:/usr/bin:/bin`; system/Homebrew python is likely PEP-668 externally-managed, so
use a dedicated venv:
```bash
/usr/local/bin/python3 -m venv ~/.venvs/learning-distill
~/.venvs/learning-distill/bin/pip install --upgrade pip claude-agent-sdk
~/.venvs/learning-distill/bin/python -c "import claude_agent_sdk, sys; print(claude_agent_sdk.__name__, sys.version)"
```
The worker auto-uses `~/.venvs/learning-distill/bin/python` (override via `LEARNING_DISTILL_PYTHON`),
falling back to PATH `python3`. The venv is OUTSIDE the repo → nothing to gitignore. Confirm the venv
python can still spawn the `claude` CLI (it's on the agent PATH).

---

## 6. Build + verify order (NOTHING touches the live worker until proven)

1. Write `learning_distill.py` (§4); `chmod +x`. Create the venv + install (§5).
2. **Prove headless subscription auth (§3)** — the make-or-break. Throwaway temp queue+target, only
   `CLAUDE_CODE_OAUTH_TOKEN` set, confirm edit + exit 0. Note duration/turns from the ResultMessage log.
3. `--dry-run` plumbing: `LEARNING_QUEUE=/tmp/empty ~/.venvs/learning-distill/bin/python plugins/core/scripts/learning_distill.py --dry-run` → exit 0, no SDK call.
4. Apply the worker edit (§5). `shellcheck plugins/core/scripts/learning-worker.sh` CLEAN (note: this
   Mac's `/bin/bash` is 3.2 + empty locale, so `bash -n` falsely chokes on em-dashes — use shellcheck,
   which is locale-independent; CI runs the tests on ubuntu bash 5).
5. `bash plugins/core/scripts/tests/test-learning-worker.sh` green (dry-run path unaffected).
6. **Live end-to-end (asks-first):** enqueue ONE benign capture into `.learning-queue.tsv`, run the
   worker live (not --dry-run), confirm: distill edits an in-scope .md → `learning-gate.sh` approves or
   holds → commit to main or files a review issue → archive drains the queue. Watch
   `~/Library/Logs/schnapp-os/memory-consolidation.log`.
7. **Cutover commit** (owner-gated — it changes the autonomous self-edit-to-main loop): commit
   `learning_distill.py` + the worker edit + a PROGRESS line, push. The next WatchPaths/30-min fire uses
   the SDK path. `infra-health` already monitors `com.schnapp.memory-consolidation`.

**Rollback:** revert the §5(b) block back to the `claude -p` invocation (and restore the PROMPT
heredoc) — one commit. The venv + `learning_distill.py` can stay (inert).

---

## 7. Gotchas / things that already bit

- **ADR 0019 cost model:** keep billing the SUBSCRIPTION. Ensure the launchd env has
  `CLAUDE_CODE_OAUTH_TOKEN` and **not** `ANTHROPIC_API_KEY` (check `launchctl print gui/$(id -u)/com.schnapp.memory-consolidation` env, and the worker's auth block prefix logic: `sk-ant-api*` → API key, else → OAuth token).
- **bash 3.2 + empty locale on this Mac** makes `bash -n` falsely fail on em-dash UTF-8 in `.sh` files.
  Use `shellcheck` (clean) + CI (ubuntu) for validation. The deployed scripts run fine under the Mac's
  real login-env bash.
- **The shellcheck-on-write hook** will lint `learning-worker.sh` on edit and BLOCK on info+ findings.
  `learning_distill.py` is python (not shell-linted by that hook).
- **op identity:** resolve the token via `op read` from a login shell context (op-wrap / `zsh -lic`),
  not a stripped subprocess.
- This session ran ON the Mac; a Code session in `~/code/schnapp-os` has Bash + repo + `op` + `claude`
  directly. An off-Mac session uses `mac-mcp` and the network allowlist (`mac-mcp.schnapp.bet`).

---

## 8. After this step (the rest of the approved plan — not this handoff's job)

From [docs/repo-review-2026-06-30-substrate-rethink.md](../docs/repo-review-2026-06-30-substrate-rethink.md):
- **GitHub → official MCP** (P2): parity PROVEN (40/43, superset, drops the portal hop + Mac host).
  Owner-conditional on no functionality loss (met). Owner-only legs: OAuth-consent the connector on
  Code/web/iPhone; check the SchnappAPI org "MCP servers in Copilot" policy.
- **Obsidian → bearer auth** (P3): auth-only swap (OAuth→bearer), zero functionality loss (keeps
  `inbox_drop`→brain-agent + all 7 tools). Owner-only: Cloudflare portal + re-auth the claude.ai connector.
- **Minor:** `plugin.json` Part-10 hook-delivery intent (corrected to current-state already; owner can
  confirm whether plugin-delivered hooks are still planned).
