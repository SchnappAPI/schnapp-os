# Agentic-OS Loops Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the two governing loops (freshness + learning) so schnapp-os self-corrects and accumulates knowledge instead of only detecting drift — the hard 80% that three prior rebuilds skipped.

**Architecture:** Four phased subsystems in the locked order (loops before features; the eval gate before any self-edit). Each phase follows the existing repo pattern: a deterministic detector script in `plugins/core/scripts/` with a co-located bash test, wired into the SessionStart gate and/or the nightly CI cron; the slow/fuzzy judgment work runs in an async `claude -p` worker that PROPOSES, never auto-rewrites, until the eval gate exists. Ground truth (git, the file on disk, a live probe) always beats stored belief.

**Tech Stack:** Bash hooks (return <1s), plain-bash test harness (no bats dependency), GitHub Actions cron (existing `scheduled-routines.yml`), Mac LaunchAgent → headless `claude -p` for judgment, markdown vault (`memory/`) as the substrate.

## Global Constraints
- Hooks must return in ~1s; heavy work (distill, eval) goes to an async worker, never inside a hook. (decision doc §7.8)
- Secrets stay references (`op://…`); never hardcode a resolved value in a committed hook/script. (rules/global/secrets-as-references)
- One fact, one file; supersede, never append; every fact carries `source:` + `updated:`. (memory/README.md)
- Detectors are deterministic and unit-tested in `plugins/core/scripts/`; reasoning stays the agent's. (existing pattern: `check-supersede-orphans.sh`)
- main-only for human work + PreToolUse force-push guard (decisions/0011 #9). **Open decision D1 below:** agent self-edits route through short-lived review branches/PRs — confirm this is the sanctioned exception.
- A learning loop without the eval gate learns confident junk — build the gate before letting the system edit its own rules. (decision doc §7.8)

## Open decisions to confirm before Phase 3
- **D1 (gate vs main-only):** Phase 3 routes agent self-edits to a branch + PR for review. 0011 #9 is "main only." Confirm: short-lived self-edit review branches are the sanctioned exception (humans still commit to main directly). Recommended: yes — §7.8 explicitly wants "git pull-request review for self-edits."
- **D2 (frontmatter schema):** the lane has two styles — top-level `source:`/`updated:` (memory/README schema) and nested under `metadata:` (harness auto-memory writes this; e.g. `credentials-state.md`). Phase 1's validator accepts BOTH (low churn). Confirm whether to later unify on one (separate cleanup, not blocking).

---

## File Structure (all four phases)

| File | Phase | Responsibility |
|---|---|---|
| `plugins/core/scripts/check-memory-frontmatter.sh` | 1 | Detector: fail if any fact file lacks `name`/`source`/ISO `updated`. |
| `tests/memory-frontmatter.test.sh` | 1 | Unit test for the detector (fixtures + exit-code asserts). |
| `memory/owner-working-preferences.md`, `memory/op-wrap-token-unquoted.md` | 1 | Backfill missing `source:`. |
| `.github/workflows/ci-lint.yml` | 1 | Run the detector on push/PR (fast gate, fails the build on violation). |
| `plugins/core/scripts/check-stale-facts.sh` | 2 | Detector: flag facts whose `updated:` is older than 7/30/90-day thresholds. |
| `tests/stale-facts.test.sh` | 2 | Unit test for the staleness detector. |
| `plugins/core/hooks/session-start-gate.sh` | 2 | Add a `[memory] stale facts` line (read-only flag). |
| `plugins/core/scripts/run-ci-routines.sh` (modify) | 2 | Add the staleness pass to the nightly read-only report. |
| `plugins/core/scripts/self-edit-stage.sh` | 3 | Wrap agent self-edits to memory/rules into a branch + PR (governance). |
| `plugins/core/skills/learn-route/SKILL.md` | 3 | Authored procedure: classify a capture → route → stage for review. |
| `scheduled-tasks/com.schnapp.memory-consolidation.plist` | 4 | LaunchAgent that runs the distill-and-route worker nightly. |
| `plugins/core/scripts/learning-worker.sh` | 4 | The async `claude -p` driver: distill captures → route → open PR via the gate. |

---

## Phase 1 — Provenance integrity + CI enforcement (FULL detail)

Makes the **Accurate** goal green: every fact is grounded with provenance, enforced by CI, not just by rule.

### Task 1: Frontmatter detector + unit test

**Files:**
- Create: `plugins/core/scripts/check-memory-frontmatter.sh`
- Test: `tests/memory-frontmatter.test.sh`

**Interfaces:**
- Produces: `check-memory-frontmatter.sh <memory-dir>` → prints one line per violation, exit 1 if any, exit 0 + summary if clean. Skips `MEMORY.md` and `README.md`. Accepts `source:`/`updated:`/`name:` at top level OR indented under `metadata:`.

- [ ] **Step 1: Write the failing test**
```bash
# tests/memory-frontmatter.test.sh
#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/plugins/core/scripts/check-memory-frontmatter.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got $1 want $2)"; fail=$((fail+1)); fi; }

# good (top-level)
printf -- '---\nname: a\nsource: a session\nupdated: 2026-06-27\n---\nbody\n' > "$tmp/good.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 0 "clean dir exits 0"

# good (nested metadata)
printf -- '---\nname: b\nmetadata:\n  source: a decision\n  updated: 2026-06-27\n---\nbody\n' > "$tmp/nested.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 0 "nested metadata accepted"

# missing source
printf -- '---\nname: c\nupdated: 2026-06-27\n---\nbody\n' > "$tmp/nosrc.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 1 "missing source fails"
rm "$tmp/nosrc.md"

# bad date
printf -- '---\nname: d\nsource: x\nupdated: June 2026\n---\nbody\n' > "$tmp/baddate.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 1 "non-ISO updated fails"
rm "$tmp/baddate.md"

# MEMORY.md/README.md ignored
printf -- 'no frontmatter\n' > "$tmp/MEMORY.md"
printf -- 'no frontmatter\n' > "$tmp/README.md"
bash "$SCRIPT" "$tmp" >/dev/null 2>&1; check "$?" 0 "index/readme skipped"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/memory-frontmatter.test.sh`
Expected: FAIL — script does not exist yet (non-zero exit, errors about missing file).

- [ ] **Step 3: Write minimal implementation**
```bash
# plugins/core/scripts/check-memory-frontmatter.sh
#!/usr/bin/env bash
# Fail if any memory fact file lacks provenance (name + source + ISO updated).
# Required by memory/README.md. Accepts keys top-level OR under a `metadata:` block.
set -uo pipefail
DIR="${1:-memory}"
fail=0; n=0
for f in "$DIR"/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in MEMORY.md|README.md) continue;; esac
  n=$((n+1))
  fm="$(awk 'NR==1 && $0!="---"{exit} NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$f")"
  if [ -z "$fm" ]; then echo "$base: no frontmatter block"; fail=1; continue; fi
  printf '%s\n' "$fm" | grep -qE '^[[:space:]]*name:'   || { echo "$base: missing 'name:'";   fail=1; }
  printf '%s\n' "$fm" | grep -qE '^[[:space:]]*source:' || { echo "$base: missing 'source:'"; fail=1; }
  upd="$(printf '%s\n' "$fm" | grep -E '^[[:space:]]*updated:' | head -1 | sed -E 's/.*updated:[[:space:]]*//; s/["'\'' ]//g')"
  if [ -z "$upd" ]; then echo "$base: missing 'updated:'"; fail=1
  elif ! printf '%s' "$upd" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then echo "$base: 'updated:' not ISO (got '$upd')"; fail=1; fi
done
[ "$fail" = 0 ] && echo "memory frontmatter OK ($n facts)"
exit "$fail"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/memory-frontmatter.test.sh`
Expected: PASS — `pass=5 fail=0`, exit 0.

- [ ] **Step 5: Commit**
```bash
git add plugins/core/scripts/check-memory-frontmatter.sh tests/memory-frontmatter.test.sh
git commit -m "feat: [meta] memory frontmatter provenance detector + test"
```

### Task 2: Backfill missing provenance so the live lane passes

**Files:**
- Modify: `memory/owner-working-preferences.md`, `memory/op-wrap-token-unquoted.md` (audit: missing `source:`)

- [ ] **Step 1: Run the detector against the real lane to list every violation**

Run: `bash plugins/core/scripts/check-memory-frontmatter.sh memory`
Expected: lists the files missing `source:` (≥ the two from the audit). Record the exact list — fix all, not just the two.

- [ ] **Step 2: Add `source:` (and `updated:` if absent) to each flagged file**

For each, add to its frontmatter (top-level or under existing `metadata:`, matching that file's style), e.g.:
```markdown
source: session 2026-06 (owner working session); originally undated
updated: 2026-06-27
```
Use a truthful source; if genuinely unknown, `source: pre-provenance backfill 2026-06-27`.

- [ ] **Step 3: Re-run the detector — expect clean**

Run: `bash plugins/core/scripts/check-memory-frontmatter.sh memory`
Expected: `memory frontmatter OK (N facts)`, exit 0.

- [ ] **Step 4: Commit**
```bash
git add memory/
git commit -m "fix: [meta] backfill missing source/updated provenance in memory lane"
```

### Task 3: Enforce in CI (push/PR fast gate)

**Files:**
- Create: `.github/workflows/ci-lint.yml`

- [ ] **Step 1: Write the workflow**
```yaml
name: ci-lint
on:
  push: { branches: [main] }
  pull_request:
jobs:
  memory-frontmatter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: memory frontmatter provenance
        run: bash plugins/core/scripts/check-memory-frontmatter.sh memory
```

- [ ] **Step 2: Verify locally that the job command passes on a clean lane**

Run: `bash plugins/core/scripts/check-memory-frontmatter.sh memory`
Expected: exit 0.

- [ ] **Step 3: Commit + push, confirm the Action goes green**
```bash
git add .github/workflows/ci-lint.yml
git commit -m "ci: [meta] enforce memory provenance on push/PR"
git push
```
Then: `gh run list --workflow=ci-lint.yml --limit 1` → expect `completed success`.

**Phase 1 done when:** detector + test committed, live lane passes, CI green. "Accurate" → ✅.

---

## Phase 2 — Reflective-but-safe freshness (scoped spec; promote to full plan when reached)

Makes the **Fresh** goal's *detect* half complete and read-only-safe (no auto-edit).

**Design:** `check-stale-facts.sh <dir>` reads each fact's `updated:`, computes age vs today (passed in as `$1`-style arg, since `date` in hooks is fine but keep it injectable for the test), and prints facts crossing 7/30/90-day thresholds with the age. Wired two places: (a) a new `[memory] stale facts` line in `session-start-gate.sh` (surfaced, never auto-fixed); (b) the nightly `run-ci-routines.sh` report. Reuses the frontmatter parser from Phase 1 (extract into a shared `lib-frontmatter.sh` sourced by both detectors — DRY).

**Tasks (outline):** (1) extract shared frontmatter parser + test; (2) `check-stale-facts.sh` + test; (3) wire into gate; (4) wire into nightly cron. Each TDD, same shape as Phase 1.

**Done when:** a fact older than 90 days shows up at SessionStart and in the nightly report; nothing is auto-edited.

---

## Phase 3 — The eval / promote gate (scoped spec; promote to full plan when reached)

The governance prerequisite. **Blocked on decision D1.**

**Design:** `self-edit-stage.sh` — when the learning loop (or the consolidation worker) wants to change a rule or supersede a fact, it does NOT commit to main. It creates a short-lived branch `self-edit/<date>-<slug>`, commits the proposed change, and opens a PR with the captured rationale (the correction, the source, what it supersedes). A human (or a future eval agent) approves → merge. The `learn-route` skill authors the classification (behavioral→rule, fact→memory-supersede, doc→fix) per `memory/README.md`, then calls the stager. The "eval" starts as human review; later an eval agent scores "did this rule/fact help?" before auto-approving low-risk edits.

**Tasks (outline):** (1) `self-edit-stage.sh` (branch+commit+`gh pr create`) + test against a throwaway repo fixture; (2) `learn-route` SKILL.md (the authored routing procedure, single source, references memory/README); (3) wire the capture-nudge to point at `learn-route` instead of inline routing; (4) document the D1 exception in decisions/ (a new ADR).

**Done when:** an agent-proposed memory supersede lands as a reviewable PR, not a direct main commit.

---

## Phase 4 — Learning-loop worker (scoped spec; promote to full plan when reached)

The 80%. **Blocked on Phase 3** (no auto-edit without the gate).

**Design:** install `scheduled-tasks/com.schnapp.memory-consolidation.plist` (the spec in `scheduled-tasks/memory-consolidation.md` already exists; it PROPOSES, asks-first). `learning-worker.sh` runs headless `claude -p` nightly: reads the session's captured corrections/observations (enqueued by the capture hooks), distills each to a reusable principle, classifies it (`learn-route`), and routes via the Phase 3 gate (opens PRs) — never writing memory/rules directly. Mechanical captures route deterministically; only genuinely fuzzy ones spend an LLM call (§7.8).

**Tasks (outline):** (1) capture enqueue — extend the Stop/SessionEnd hooks to append observations to a queue file; (2) `learning-worker.sh` distill+route driver; (3) the LaunchAgent plist + `launchctl` install + verify; (4) eval pass that scores whether a promoted rule was used in later sessions.

**Done when:** a correction made in one session becomes a reviewed, merged rule/fact change that the next session loads — without anyone remembering to do it. That is both loops firing.

---

## Self-Review
- **Spec coverage:** Phase 1 = step 1 (provenance/CI). Phase 2 = step 2 (reflective freshness). Phase 3 = step 3 (eval gate). Phase 4 = step 4 (learning loop). Orchestration (step 5) is out of scope here per 0011 #8 (deferred until both loops fire).
- **Placeholder scan:** Phase 1 is full code/tests/commands. Phases 2–4 are explicitly scoped specs to be promoted to full plans on arrival (the skill's multi-subsystem guidance) — not placeholders inside an executing phase.
- **Type/name consistency:** detector contract (`<dir>` arg, exit 1 on violation, skips MEMORY/README) is consistent across Phase 1 and the Phase 2 reuse; `learn-route` + `self-edit-stage.sh` referenced consistently in Phases 3–4.
