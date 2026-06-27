# Phase 4 — Learning-loop worker (FULL TDD plan)

> **For agentic workers:** Implement task-by-task (implementer → review → fix → commit). Promoted from
> the scoped spec in `2026-06-27-agentic-os-loops.md` §"Phase 4". Steps use `- [ ]`.

**Goal — the payoff:** a correction made in one session becomes a **reviewed, merged** rule/fact change
that the next session loads — without anyone remembering to do it. That is both loops firing
(freshness from Phases 1–2; learning from Phases 3–4).

**Depends on Phase 3 (DONE):** the worker NEVER writes memory/rules directly — it routes every
judgment-bearing proposal through `self-edit-stage.sh` (the gate, ADR 0012), which opens a PR. Mechanical
captures route deterministically; only genuinely fuzzy ones spend an LLM call (decision doc §7.8).

**The loop, end to end:**
1. **Capture** (in-session, deterministic): when a correction lands, `capture-nudge.sh` already nudges the
   agent; Phase 4 also **enqueues** the correction to a local, git-ignored queue file.
2. **Distill + route** (nightly, async): a Mac LaunchAgent runs `learning-worker.sh` headless. It reads the
   queue, distills each capture to a reusable principle, classifies it via the `learn-route` procedure, and
   routes it: mechanical → (left for an interactive session); judgment → `self-edit-stage.sh` opens a PR.
3. **Review + merge** (human / future eval agent): the PR is reviewed and merged. Next session loads it.

**Build-here vs Mac-only (be explicit):** everything except live activation is built and unit-tested in this
repo. The **LaunchAgent activation on the production Mac** (`launchctl load`) and the **live `claude -p` run**
are consequential, owner-machine actions — they are a **separate, owner-confirmed step at the end**, executed
via the `Schnapp_Mac` MCP only after explicit approval. The worker ships with a fully-testable `--dry-run`
that exercises all logic with no `claude -p` call and no network.

**Branch / commit conventions:** build on `claude/schnapp-os-phase4-learning` → PR to `main`. Commit via the
Bash tool. Format `type: [meta] subject` + `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`. Push after each task.

---

## File Structure (Phase 4)

| File | Action | Responsibility |
|---|---|---|
| `plugins/core/hooks/capture-nudge.sh` | modify | Also append the matched correction to the local learning queue (in addition to the existing nudge). |
| `.gitignore` | modify | Ignore the local queue file (`scheduled-tasks/.learning-queue.tsv`). |
| `plugins/core/scripts/tests/test-capture-enqueue.sh` | create | Unit test: a correction enqueues one record; a non-correction enqueues nothing; always exit 0. |
| `plugins/core/scripts/learning-worker.sh` | create | The async driver: read queue → distill+classify+route via the gate → archive processed. `--dry-run` does it all minus the `claude -p` call. |
| `plugins/core/scripts/tests/test-learning-worker.sh` | create | Unit test of `--dry-run`: queue counted, nothing under memory/ or rules/ written, processed lines archived, empty queue handled. |
| `scheduled-tasks/com.schnapp.memory-consolidation.plist` | create | The LaunchAgent that runs the worker nightly (spec already in `scheduled-tasks/memory-consolidation.md`). |
| `scheduled-tasks/README.md` | modify | Document install/verify (`launchctl`) + the owner-confirmed activation boundary. |

> **Path/precedent notes (verified):** capture happens in `capture-nudge.sh` (UserPromptSubmit; it already
> has the correction regex + sees the prompt text). The gate is `plugins/core/scripts/self-edit-stage.sh`
> (Phase 3). The routing procedure is the `learn-route` skill (Phase 3). The nightly-worker spec is
> `scheduled-tasks/memory-consolidation.md` (asks-first, proposes-not-rewrites). The queue is git-ignored
> and local because raw corrections are noisy/sensitive — only the distilled, reviewed PR is durable.

---

## Task 1 — Capture enqueue (in-session, deterministic)

**Design:** when `capture-nudge.sh`'s correction regex matches, append one tab-separated record to
`$CLAUDE_PROJECT_DIR/scheduled-tasks/.learning-queue.tsv`:
`<ISO8601-UTC>\tcorrection\t<prompt text, newlines→spaces>`. The file is git-ignored (local work queue on
each machine; the worker reads it on the Mac). The hook stays deterministic, fast, and **always exits 0**
(UserPromptSubmit exit 2 would suppress the prompt — never do that). Enqueue must never fail the hook
(wrap in a guard; a write error is swallowed, the nudge still prints).

- [ ] **Step 1: Failing test** — `plugins/core/scripts/tests/test-capture-enqueue.sh`
```bash
#!/usr/bin/env bash
set -uo pipefail
HOOK="$(cd "$(dirname "$0")/../../hooks" && pwd)/capture-nudge.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/scheduled-tasks"
Q="$tmp/scheduled-tasks/.learning-queue.tsv"

# a correction enqueues exactly one record, tagged 'correction'
printf "you're wrong, the port is 1433" | CLAUDE_PROJECT_DIR="$tmp" bash "$HOOK" >/dev/null 2>&1
check "$?" 0 "hook exits 0 on correction"
check "$([ -f "$Q" ] && wc -l < "$Q" | tr -d ' ' || echo 0)" 1 "one queue record after a correction"
check "$(cut -f2 "$Q" | head -1)" "correction" "record tagged correction"
check "$(grep -c 'port is 1433' "$Q")" 1 "prompt text captured"

# a non-correction enqueues nothing
printf "please add a column to the report" | CLAUDE_PROJECT_DIR="$tmp" bash "$HOOK" >/dev/null 2>&1
check "$?" 0 "hook exits 0 on non-correction"
check "$(wc -l < "$Q" | tr -d ' ')" 1 "non-correction did not enqueue"

# newlines in the prompt are flattened to keep one record per line
printf "that's wrong\nline two" | CLAUDE_PROJECT_DIR="$tmp" bash "$HOOK" >/dev/null 2>&1
check "$(wc -l < "$Q" | tr -d ' ')" 2 "multiline correction is still one record"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
```

- [ ] **Step 2: Run — FAILS** (no enqueue yet).

- [ ] **Step 3: Implement** — in `capture-nudge.sh`, inside the existing `if` that matches the correction
  regex (right where it prints the nudge), add an enqueue block BEFORE/AFTER the heredoc:
```bash
  # Enqueue the correction for the nightly learning worker (local, git-ignored queue).
  # Best-effort: a write failure must never break the hook.
  q="${CLAUDE_PROJECT_DIR:-$PWD}/scheduled-tasks/.learning-queue.tsv"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  line="$(printf '%s' "$INPUT" | tr '\n\t' '  ')"
  { printf '%s\tcorrection\t%s\n' "$ts" "$line" >> "$q"; } 2>/dev/null || true
```
  Keep the nudge heredoc exactly as is. Confirm the hook still ends with `exit 0`.

- [ ] **Step 4: Gitignore the queue** — append to `.gitignore`:
```
# Local learning-loop capture queue (per-machine; distilled+reviewed output is what's durable)
scheduled-tasks/.learning-queue.tsv
```

- [ ] **Step 5: Run — PASSES.** Also: `printf "you're wrong" | bash plugins/core/hooks/capture-nudge.sh; echo "exit=$?"` still prints the nudge + `exit=0`, and `git status` does NOT show the queue file (ignored).

- [ ] **Step 6: Commit**
```
git add plugins/core/hooks/capture-nudge.sh .gitignore plugins/core/scripts/tests/test-capture-enqueue.sh
git commit -m "feat: [meta] capture-nudge enqueues corrections to a local learning queue + test"
```

---

## Task 2 — `learning-worker.sh` (distill → classify → route via the gate)

**Interface:** `learning-worker.sh [--dry-run]`. Reads the queue, processes each capture, archives processed
lines to `scheduled-tasks/.learning-queue.archive.tsv`, exits 0. Env: `LEARNING_QUEUE` (default
`scheduled-tasks/.learning-queue.tsv`), `LEARNING_ARCHIVE` (default alongside it).

**Contract:**
- Empty/missing queue → print `learning-worker: queue empty — nothing to consolidate`, exit 0.
- `--dry-run` → for each capture, print `would distill+route: <text>` and the lane it would take
  (mechanical vs judgment by a deterministic heuristic), **make NO `claude -p` call**, write NOTHING under
  `memory/` or `plugins/core/rules/`, but DO move processed lines to the archive. Exit 0.
- Live (no `--dry-run`): require the `claude` CLI; if absent, print a clear message and exit 0 (no-op, not a
  crash). When present, invoke `claude -p` with a prompt that (a) loads the `learn-route` procedure, (b)
  distills each queued capture to a reusable principle, (c) for judgment-bearing ones calls
  `self-edit-stage.sh <slug> "<rationale>"` to open a PR, (d) NEVER writes memory/rules directly. The worker
  is the *driver*; the LLM does the judgment. Processed lines archived after the run.
- Idempotent + safe: archiving (not deleting) processed lines means a capture is never silently lost; a
  re-run on an empty queue is a clean no-op.

- [ ] **Step 1: Failing test** — `plugins/core/scripts/tests/test-learning-worker.sh`
```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/learning-worker.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
Q="$tmp/q.tsv"; A="$tmp/q.archive.tsv"

# empty queue → clean no-op
out="$(LEARNING_QUEUE="$Q" LEARNING_ARCHIVE="$A" bash "$SCRIPT" --dry-run 2>&1)"; check "$?" 0 "empty queue exits 0"
check "$(printf '%s' "$out" | grep -c 'nothing to consolidate')" 1 "empty queue message"

# two captures → dry-run reports two, writes nothing to memory/rules, archives both
printf '2026-06-27T00:00:00Z\tcorrection\tthe port is 1433 not 1533\n' >  "$Q"
printf '2026-06-27T00:01:00Z\tcorrection\talways quote op refs with spaces\n' >> "$Q"
mem_before="$(ls -la "$tmp" | wc -l)"
out="$(LEARNING_QUEUE="$Q" LEARNING_ARCHIVE="$A" bash "$SCRIPT" --dry-run 2>&1)"; check "$?" 0 "dry-run exits 0"
check "$(printf '%s' "$out" | grep -c 'would distill+route')" 2 "dry-run reports both captures"
check "$([ -f "$A" ] && wc -l < "$A" | tr -d ' ' || echo 0)" 2 "both processed lines archived"
check "$([ -s "$Q" ] && echo nonempty || echo empty)" "empty" "queue drained after processing"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
```

- [ ] **Step 2: Run — FAILS.**
- [ ] **Step 3: Implement `learning-worker.sh`** to the contract (`chmod +x`). The mechanical-vs-judgment
  heuristic for `--dry-run`: treat a capture mentioning a concrete value/name (digits, `op://`, a path) as a
  fact-supersede (judgment); keep it simple and deterministic — it only labels the dry-run, the live LLM does
  the real classification. Guard the live `claude` call behind `command -v claude`.
- [ ] **Step 4: Run — PASSES.** Confirm a `--dry-run` against a seeded queue writes nothing under `memory/`
  or `plugins/core/rules/` (`git status` clean there).
- [ ] **Step 5: Commit**
```
git add plugins/core/scripts/learning-worker.sh plugins/core/scripts/tests/test-learning-worker.sh
git commit -m "feat: [meta] learning-worker.sh — distill+route captures via the gate (dry-run testable) + test"
```

---

## Task 3 — LaunchAgent plist + CI wiring + install docs (activation deferred)

- [ ] **Step 1: Write `scheduled-tasks/com.schnapp.memory-consolidation.plist`** — a standard LaunchAgent:
  `Label` = `com.schnapp.memory-consolidation`, `ProgramArguments` = the worker invocation
  (`/bin/bash <abs>/plugins/core/scripts/learning-worker.sh`), `StartCalendarInterval` nightly (an off-hour,
  e.g. 03:17), `StandardOutPath`/`StandardErrorPath` to a log under the user's Library/Logs, `RunAtLoad`
  false. Use a `__REPO__` placeholder for the absolute path that the install step substitutes (documented).
- [ ] **Step 2: Validate the plist is well-formed** (the test/CI step): `plutil -lint` on macOS; portable
  fallback `xmllint --noout`. Add to `.github/workflows/freshness.yml`:
```yaml
      - name: Capture-enqueue self-test
        run: bash plugins/core/scripts/tests/test-capture-enqueue.sh
      - name: Learning-worker self-test
        run: bash plugins/core/scripts/tests/test-learning-worker.sh
      - name: LaunchAgent plist is valid XML
        run: xmllint --noout scheduled-tasks/com.schnapp.memory-consolidation.plist
```
- [ ] **Step 3: Document install + the activation boundary** in `scheduled-tasks/README.md`: the exact
  `launchctl` steps (substitute `__REPO__`, `cp` to `~/Library/LaunchAgents/`, `launchctl load`), and a clear
  note that activation is **owner-confirmed** and runs on the production Mac — never auto-loaded by CI or a
  cloud session. Reference `memory-consolidation.md` for the asks-first policy.
- [ ] **Step 4: Verify** — `xmllint --noout scheduled-tasks/com.schnapp.memory-consolidation.plist`; all three
  new self-tests green.
- [ ] **Step 5: Commit + push**
```
git add scheduled-tasks/com.schnapp.memory-consolidation.plist scheduled-tasks/README.md .github/workflows/freshness.yml
git commit -m "feat: [meta] nightly learning-worker LaunchAgent plist + self-tests (activation owner-gated)"
git push -u origin claude/schnapp-os-phase4-learning
```

---

## Task 4 — (Deferred follow-up) eval pass: did a promoted rule get used?

The "eval" half — scoring whether a merged rule/fact actually helped in later sessions — is the fuzziest piece
and is **explicitly deferred** beyond this PR (it needs the loop to have run a while to have data). Captured
here as the next increment, NOT a blocker for Phase 4 "done":
- A `learning-eval.sh` that, for each rule promoted via a `self-edit/*` merge, checks whether it has been
  referenced since (grep session transcripts / later commits) and reports a simple used/unused signal — the
  input a future eval agent uses to auto-approve low-risk staged PRs.

---

## Done when (this PR)
- A correction enqueues to the local queue (Task 1 test).
- `learning-worker.sh --dry-run` reads the queue, routes nothing destructively, archives processed captures,
  and writes nothing under memory/rules (Task 2 test).
- The LaunchAgent plist is valid and documented; CI runs all three self-tests.
- PR opened → main.

## Done when (the loop actually fires — owner-confirmed, after merge)
- The LaunchAgent is installed on the Mac (via `Schnapp_Mac` MCP, after explicit owner OK), runs the worker
  nightly, and a real captured correction becomes a `self-edit/*` PR that a later session loads on merge.

## Self-review
- **Gate fidelity:** the worker only proposes — every judgment-bearing change goes through
  `self-edit-stage.sh` (Phase 3), never a direct memory/rules write. Mechanical captures are left for an
  interactive session, not auto-applied.
- **Safety:** the queue is git-ignored + local; processing archives (never deletes) captures; `--dry-run` and
  the `command -v claude` guard mean the testable path makes no LLM call and no network call; live activation
  on the production Mac is a separate, explicitly owner-confirmed step.
- **Determinism vs judgment:** the hook + worker scaffolding + archival are deterministic and unit-tested; only
  the distillation/classification is the LLM's, behind the gate.
- **Scope discipline:** the eval pass (Task 4) is deferred with a clear reason, not half-built inside the PR.
