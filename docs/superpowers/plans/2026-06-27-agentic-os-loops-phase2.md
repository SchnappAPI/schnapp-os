# Phase 2 — Reflective-but-safe freshness (FULL TDD plan)

> **For agentic workers:** Implement task-by-task (superpowers:subagent-driven-development method
> — implementer → review → fix Important/Critical → commit). Steps use checkbox (`- [ ]`) syntax.
> Promoted from the scoped spec in `2026-06-27-agentic-os-loops.md` §"Phase 2".

**Goal:** Make the **Fresh** goal's *detect* half complete and read-only-safe. Flag memory facts
whose `updated:` crosses 7/30/90-day age thresholds, surfaced at SessionStart and in the nightly
report. **Nothing is auto-edited** — the agent decides what to refresh (supersede-not-append).

**Branch / commit conventions (from handoff 035, reconciled for this cloud session):**
- Build on `claude/schnapp-os-phase2-loops-5b7zfz` (holds Phase 1; `main` is behind). PR → main at the end.
- Commit via the Bash tool in this container. The only `PreToolUse` Bash hook is `no-force-push-guard.sh`
  (force-push only) — there is no commit-to-main guard here, and the Mac shell targets a different checkout.
- Commit format `type: [meta] subject` + trailer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Push after each task (the Stop push-gate expects HEAD pushed to origin).

**Why a shared lib (DRY):** Phase 1's `check-memory-frontmatter.sh` and Phase 2's `check-stale-facts.sh`
both parse the same two-style frontmatter (top-level OR nested under `metadata:`). Extract the parser
once into `lib-frontmatter.sh`, source it from both. The refactor must keep Phase 1's existing test green.

**Why pure-integer date math:** the detector runs in the SessionStart hook (owner Mac = BSD `date`)
AND in the nightly GitHub Actions cron (Linux = GNU `date`). `date -d`/`date -j` are not portable.
Use Howard Hinnant's `days_from_civil` algorithm (pure bash arithmetic) so age is deterministic and
unit-testable with an injected "today" — no `date` branching.

---

## File Structure (Phase 2)

| File | Action | Responsibility |
|---|---|---|
| `plugins/core/scripts/lib-frontmatter.sh` | create | Shared frontmatter helpers: `fm_block`, `fm_value`, `fm_has`. Sourced, not executed. |
| `plugins/core/scripts/tests/test-lib-frontmatter.sh` | create | Unit test for the lib (top-level + nested + absent fixtures). |
| `plugins/core/scripts/check-memory-frontmatter.sh` | modify | Source the lib instead of inlining the awk/grep parser. Behavior identical (Phase 1 test stays green). |
| `plugins/core/scripts/check-stale-facts.sh` | create | Detector: flag facts crossing 7/30/90-day `updated:` thresholds. Read-only, always exit 0. |
| `plugins/core/scripts/tests/test-stale-facts.sh` | create | Unit test for the staleness detector (injected today, tier + boundary asserts). |
| `plugins/core/hooks/session-start-gate.sh` | modify | Add a `[memory] stale facts` block (read-only flag). |
| `scheduled-tasks/run-ci-routines.sh` | modify | Add an informational "Memory freshness sweep" section. |
| `.github/workflows/freshness.yml` | modify | Run the two new self-tests (+ the Phase 1 detector test, guarding the refactor). |

> **Path notes (verified against the live repo, override the scoped spec's guesses):**
> tests live in `plugins/core/scripts/tests/test-*.sh` (not `tests/*.test.sh`); the nightly routine is
> `scheduled-tasks/run-ci-routines.sh` (not `plugins/core/scripts/`); unit tests run in `freshness.yml`
> (not `ci-lint.yml`). `check-stale-facts.sh` is a NEW name — `check-freshness.sh` already exists and is
> about *document* freshness (CATALOG regen + `last-verified:`), a different concern; do not touch it.

---

## Task 1 — Shared frontmatter lib + refactor Phase 1 detector

**Interfaces (`lib-frontmatter.sh`, sourced — defines functions, no side effects, no top-level work):**
- `fm_block <file>` → prints the frontmatter block (lines between the leading `---` and the next `---`);
  empty if the file has no leading `---`.
- `fm_value <file> <key>` → prints the trimmed value of `key:` matched top-level OR indented (first match
  wins). Strips surrounding whitespace and surrounding quotes only (NOT internal spaces, so multi-word
  `source:` survives). Empty if absent or value-empty.
- `fm_has <file> <key>` → exit 0 if `key:` present in the frontmatter, else 1.

- [ ] **Step 1: Write the failing lib test** — `plugins/core/scripts/tests/test-lib-frontmatter.sh`
```bash
#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/lib-frontmatter.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

printf -- '---\nname: a\nsource: a session\nupdated: 2026-06-27\n---\nbody: x\n' > "$tmp/top.md"
printf -- '---\nname: b\nmetadata:\n  source: a decision\n  updated: 2026-06-20\n---\nbody\n' > "$tmp/nested.md"
printf -- 'no frontmatter here\n' > "$tmp/none.md"

check "$(fm_value "$tmp/top.md" updated)" "2026-06-27" "top-level updated"
check "$(fm_value "$tmp/top.md" source)"  "a session"  "multi-word source survives"
check "$(fm_value "$tmp/nested.md" updated)" "2026-06-20" "nested updated"
check "$(fm_value "$tmp/top.md" missing)" "" "absent key empty"
check "$(fm_value "$tmp/none.md" updated)" "" "no-frontmatter empty"
if fm_has "$tmp/top.md" source; then check 0 0 "fm_has present"; else check 1 0 "fm_has present"; fi
if fm_has "$tmp/top.md" nope;   then check 1 0 "fm_has absent";  else check 0 0 "fm_has absent"; fi
check "$(fm_block "$tmp/none.md")" "" "fm_block on no-frontmatter is empty"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
```

- [ ] **Step 2: Run — verify it FAILS** (`bash plugins/core/scripts/tests/test-lib-frontmatter.sh`): lib does not exist yet.

- [ ] **Step 3: Write `plugins/core/scripts/lib-frontmatter.sh`**
```bash
#!/usr/bin/env bash
# lib-frontmatter.sh — shared YAML-frontmatter helpers for memory-lane detectors
# (check-memory-frontmatter.sh, check-stale-facts.sh). Sourced, not executed.
# Pure bash + awk (BSD + GNU). No side effects, no top-level work.

# fm_block <file> — frontmatter block: lines between the leading `---` and the next `---`.
fm_block() {
  awk 'NR==1 && $0!="---"{exit} NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$1"
}

# fm_value <file> <key> — trimmed value of `key:` (top-level OR indented; first match).
# Strips surrounding whitespace + surrounding quotes only (internal spaces preserved).
fm_value() {
  fm_block "$1" | grep -E "^[[:space:]]*$2:" | head -1 \
    | sed -E "s/^[[:space:]]*$2:[[:space:]]*//; s/[[:space:]]*$//; s/^[\"']//; s/[\"']$//"
}

# fm_has <file> <key> — exit 0 if `key:` present in frontmatter, else 1.
fm_has() {
  fm_block "$1" | grep -qE "^[[:space:]]*$2:"
}
```

- [ ] **Step 4: Run — verify the lib test PASSES.**

- [ ] **Step 5: Refactor `check-memory-frontmatter.sh` to source the lib** (behavior identical — Phase 1 test must stay green)
```bash
#!/usr/bin/env bash
# Fail if any memory fact file lacks provenance (name + source + ISO updated).
# Required by memory/README.md. Accepts keys top-level OR under a `metadata:` block.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib-frontmatter.sh"
DIR="${1:-memory}"
fail=0; n=0
for f in "$DIR"/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in MEMORY.md|README.md) continue;; esac
  n=$((n+1))
  if [ -z "$(fm_block "$f")" ]; then echo "$base: no frontmatter block"; fail=1; continue; fi
  fm_has "$f" name   || { echo "$base: missing 'name:'";   fail=1; }
  fm_has "$f" source || { echo "$base: missing 'source:'"; fail=1; }
  upd="$(fm_value "$f" updated)"
  if [ -z "$upd" ]; then echo "$base: missing 'updated:'"; fail=1
  elif ! printf '%s' "$upd" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then echo "$base: 'updated:' not ISO (got '$upd')"; fail=1; fi
done
[ "$fail" = 0 ] && echo "memory frontmatter OK ($n facts)"
exit "$fail"
```

- [ ] **Step 6: Run BOTH tests green** — `bash plugins/core/scripts/tests/test-lib-frontmatter.sh` AND
  `bash plugins/core/scripts/tests/test-memory-frontmatter.sh` (regression guard); plus
  `bash plugins/core/scripts/check-memory-frontmatter.sh memory` → still `memory frontmatter OK (N facts)`.

- [ ] **Step 7: Commit**
```
git add plugins/core/scripts/lib-frontmatter.sh \
        plugins/core/scripts/tests/test-lib-frontmatter.sh \
        plugins/core/scripts/check-memory-frontmatter.sh
git commit -m "refactor: [meta] extract shared lib-frontmatter.sh (DRY); detector sources it"
```

---

## Task 2 — `check-stale-facts.sh` staleness detector + test

**Interface:** `check-stale-facts.sh [dir] [today]` → for each fact (skips `MEMORY.md`/`README.md`)
prints one line per fact crossing a threshold, with tier + age + date; prints
`memory freshness OK (no facts older than 7d)` if none. **Always exit 0** (staleness is informational,
not a hard gate — surfacing is the point). `today` (ISO) is injectable; defaults to `date -u +%F`.
Tiers: age ≥90 → `STALE 90d+`; ≥30 → `aging 30d+`; ≥7 → `review 7d+`; <7 → not printed.

- [ ] **Step 1: Write the failing test** — `plugins/core/scripts/tests/test-stale-facts.sh`
```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-stale-facts.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }
mk(){ printf -- '---\nname: %s\nsource: t\nupdated: %s\n---\nbody\n' "$1" "$2" > "$tmp/$1.md"; }
T=2026-06-27

mk fresh 2026-06-25                                   # 2d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'fresh.md')" 0 "fresh (<7d) not flagged"; rm "$tmp/fresh.md"

mk wk 2026-06-18                                      # 9d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'wk.md: review 7d+')" 1 "7-day tier"; rm "$tmp/wk.md"

mk mo 2026-05-20                                      # 38d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'mo.md: aging 30d+')" 1 "30-day tier"; rm "$tmp/mo.md"

mk old 2026-01-01                                     # 177d  (the "done when" >90d condition)
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'old.md: STALE 90d+')" 1 "90-day tier"

mk b7 2026-06-20                                      # exactly 7d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'b7.md: review 7d+')" 1 "exactly 7d flagged"; rm "$tmp/b7.md"

mk b6 2026-06-21                                      # 6d
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'b6.md')" 0 "6d not flagged"; rm "$tmp/b6.md"

printf -- '---\nupdated: 2000-01-01\n---\n' > "$tmp/MEMORY.md"   # ancient but excluded
check "$(bash "$SCRIPT" "$tmp" "$T" | grep -c 'MEMORY.md')" 0 "MEMORY.md skipped"

bash "$SCRIPT" "$tmp" "$T" >/dev/null 2>&1; check "$?" 0 "always exits 0 (read-only)"

# empty/clean dir reports the OK line
e="$(mktemp -d)"; trap 'rm -rf "$tmp" "$e"' EXIT
check "$(bash "$SCRIPT" "$e" "$T" | grep -c 'memory freshness OK')" 1 "clean dir prints OK line"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
```

- [ ] **Step 2: Run — verify it FAILS** (script does not exist yet).

- [ ] **Step 3: Write `plugins/core/scripts/check-stale-facts.sh`**
```bash
#!/usr/bin/env bash
# check-stale-facts.sh — read-only memory freshness flag (agentic-OS loops Phase 2).
# Flags facts whose `updated:` crosses 7/30/90-day age thresholds vs today. READ-ONLY:
# prints flags, never edits, ALWAYS exits 0 (staleness is informational, not a hard gate —
# surfacing is the point; the agent decides what to refresh, supersede-not-append per memory/README.md).
#
# Usage: check-stale-facts.sh [dir] [today]
#   dir   — memory dir (default: memory). Skips MEMORY.md/README.md.
#   today — ISO date to measure against (default: date -u +%F). Injectable for tests.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib-frontmatter.sh"
DIR="${1:-memory}"
TODAY="${2:-$(date -u +%F)}"

# iso_to_days <YYYY-MM-DD> — days since the civil epoch (Hinnant days_from_civil).
# Pure integer arithmetic → portable across BSD/GNU, deterministic, unit-testable.
iso_to_days() {
  local y m d rest era yoe doy doe
  y=${1%%-*}; rest=${1#*-}; m=${rest%%-*}; d=${rest#*-}
  y=$((10#$y)); m=$((10#$m)); d=$((10#$d))
  (( m <= 2 )) && y=$(( y - 1 ))
  if (( y >= 0 )); then era=$(( y / 400 )); else era=$(( (y-399)/400 )); fi
  yoe=$(( y - era*400 ))
  if (( m > 2 )); then doy=$(( (153*(m-3)+2)/5 + d-1 )); else doy=$(( (153*(m+9)+2)/5 + d-1 )); fi
  doe=$(( yoe*365 + yoe/4 - yoe/100 + doy ))
  echo $(( era*146097 + doe - 719468 ))
}

t_today=$(iso_to_days "$TODAY")
flagged=0
for f in "$DIR"/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in MEMORY.md|README.md) continue;; esac
  upd="$(fm_value "$f" updated)"
  printf '%s' "$upd" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || continue  # malformed/missing dates are the frontmatter gate's job
  age=$(( t_today - $(iso_to_days "$upd") ))
  if   (( age >= 90 )); then tier="STALE 90d+"
  elif (( age >= 30 )); then tier="aging 30d+"
  elif (( age >=  7 )); then tier="review 7d+"
  else continue; fi
  echo "$base: $tier (${age}d, updated $upd)"
  flagged=$((flagged+1))
done
[ "$flagged" = 0 ] && echo "memory freshness OK (no facts older than 7d)"
exit 0
```

- [ ] **Step 4: Run — verify the test PASSES.** Then sanity-run against the live lane with the build date:
  `bash plugins/core/scripts/check-stale-facts.sh memory 2026-06-27` (expect the 3 facts ≥7d old to flag,
  none auto-edited).

- [ ] **Step 5: Commit**
```
git add plugins/core/scripts/check-stale-facts.sh plugins/core/scripts/tests/test-stale-facts.sh
git commit -m "feat: [meta] check-stale-facts.sh — read-only 7/30/90-day memory freshness flag + test"
```

---

## Task 3 — Wire into the SessionStart gate, the nightly routine, and CI

- [ ] **Step 1: `session-start-gate.sh`** — inside the `if [ -d "$MEM" ]` block, AFTER the supersede-orphans
  if/else and BEFORE its closing `fi`, add a read-only stale-facts flag:
```bash
  stale="$(bash "$REPO/plugins/core/scripts/check-stale-facts.sh" "$MEM" 2>/dev/null \
            | grep -v '^memory freshness OK')"
  if [ -n "$stale" ]; then
    echo "[memory] STALE FACTS — review/refresh (read-only flag; supersede-not-append):"
    printf '%s\n' "$stale" | sed 's/^/        - /'
  else
    echo "[memory] no stale facts (<7d)"
  fi
```

- [ ] **Step 2: `scheduled-tasks/run-ci-routines.sh`** — after Routine 2 (sync/unmerged), before the final
  `exit "$rc"`, add an informational sweep (does NOT touch `rc`):
```bash
# --- Routine 3: memory freshness sweep (informational) ---
echo "## Memory freshness sweep"
echo
echo '```'
bash plugins/core/scripts/check-stale-facts.sh memory 2>&1 || true
echo '```'
echo
echo "_Read-only: flags facts crossing 7/30/90-day \`updated:\` thresholds. Refresh via supersede"
echo "in an approved session — this routine never edits._"
echo
```

- [ ] **Step 3: `.github/workflows/freshness.yml`** — add self-test steps (after the supersede-orphan self-test):
```yaml
      - name: Frontmatter lib self-test
        run: bash plugins/core/scripts/tests/test-lib-frontmatter.sh

      - name: Memory frontmatter detector self-test
        run: bash plugins/core/scripts/tests/test-memory-frontmatter.sh

      - name: Stale-facts detector self-test
        run: bash plugins/core/scripts/tests/test-stale-facts.sh
```

- [ ] **Step 4: Verify locally**
  - `bash plugins/core/hooks/session-start-gate.sh` → shows a `[memory]` stale-facts line (the ≥7d facts), exits 0.
  - `bash scheduled-tasks/run-ci-routines.sh` → contains a "## Memory freshness sweep" section; overall exit
    unchanged (freshness gate still owns rc).
  - Re-run all four self-tests green.
  - Confirm NOTHING under `memory/` was modified (`git status` clean except the three wired files).

- [ ] **Step 5: Commit + push**
```
git add plugins/core/hooks/session-start-gate.sh scheduled-tasks/run-ci-routines.sh .github/workflows/freshness.yml
git commit -m "feat: [meta] surface stale facts at SessionStart + nightly report; run Phase 2 self-tests in CI"
git push -u origin claude/schnapp-os-phase2-loops-5b7zfz
```

---

## Done when
- A fact older than 90 days (test fixture, injected today) flags as `STALE 90d+` in the detector test;
  the live ≥7-day facts surface at SessionStart and in the nightly report.
- Nothing under `memory/` is auto-edited (read-only).
- All four self-tests pass locally and in `freshness.yml` (CI green).
- PR opened → `main`.

## Self-review
- **Spec coverage:** scoped-spec tasks (1) shared parser, (2) stale detector, (3) gate wiring,
  (4) nightly wiring — all covered; CI self-tests added so the lib refactor + new detector cannot regress.
- **DRY:** both detectors source `lib-frontmatter.sh`; the Phase 1 test stays green as the refactor guard.
- **Safety:** detector always exits 0; nightly sweep is informational (does not change `rc`); no `memory/` writes.
- **Portability:** date math is pure integer (no `date -d`/`-j`), so SessionStart (BSD) and cron (GNU) agree.
