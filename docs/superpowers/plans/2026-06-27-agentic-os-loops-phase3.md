# Phase 3 — The eval / promote gate (FULL TDD plan)

> **For agentic workers:** Implement task-by-task (implementer → review → fix Important/Critical → commit).
> Promoted from the scoped spec in `2026-06-27-agentic-os-loops.md` §"Phase 3". Steps use `- [ ]`.

**Goal:** Build the governance gate that lets the learning loop change rules/facts **safely** — the
prerequisite for Phase 4. When the system proposes a judgment-bearing self-edit, it lands as a
**reviewable PR**, not a silent main commit.

**Decision D1 — RESOLVED by owner (2026-06-27), two-lane:** the branch+PR gate **exists and is the
path for judgment-bearing self-edits**, *and* the agent **may commit low-risk/mechanical self-edits
directly to main**. The gate is **preferred-not-mandatory**. Lane split (owner's recommended line):

| Lane | What | How |
|---|---|---|
| **Direct to main** | Mechanical: typo / formatting / dead-link fix, re-running a generator (e.g. `gen-catalog.sh`), backfilling provenance — anything that does **not** change a rule's meaning or a fact's truth. | Agent commits straight to main (main-only, 0011 #9). |
| **Branch + PR (gate)** | Judgment: changing a **rule's meaning**, **superseding a fact**, adding/removing a rule, anything a reviewer should weigh. | `self-edit-stage.sh` → `self-edit/<date>-<slug>` branch + PR with rationale. |

This is recorded as ADR `decisions/0012` in Task 1, and is the single source the `learn-route` skill points to.

**Branch / commit conventions:** build on `claude/schnapp-os-phase3-gate` → PR to `main` (Phase 3 is
feature work; CI + review warranted, same flow as PR #10). Commit via the Bash tool. Format
`type: [meta] subject` + `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`. Push after each task.

**Environment reality (verified):** no `gh` CLI in the cloud container (may exist on the owner Mac).
So `self-edit-stage.sh` does the git mechanics **deterministically and offline-testably**, and the
PR-open step **degrades gracefully**: use `gh pr create` if present; else push and print the compare
URL with an instruction to open the PR via the github MCP. The unit test covers the git mechanics
(branch/commit/restore), never the network call.

---

## File Structure (Phase 3)

| File | Action | Responsibility |
|---|---|---|
| `decisions/0012-self-edit-gate-two-lane.md` | create | ADR: record the D1 two-lane decision + the lane split. |
| `plugins/core/scripts/self-edit-stage.sh` | create | Stage a judgment-bearing self-edit into a `self-edit/<date>-<slug>` branch + PR; leave main untouched. |
| `plugins/core/scripts/tests/test-self-edit-stage.sh` | create | Unit test against a throwaway git fixture (branch made, change committed there, original branch restored, main has no new commit). |
| `plugins/core/skills/learn-route/SKILL.md` | create | Authored routing procedure: classify a capture → pick the lane → act (direct main vs stage). |
| `plugins/core/hooks/capture-nudge.sh` | modify | Replace the "gate not built yet" line with a pointer to `learn-route` + the two-lane rule. |
| `.github/workflows/freshness.yml` | modify | Run the `test-self-edit-stage.sh` self-test in CI. |

> **Path notes (verified):** ADRs are `decisions/NNNN-slug.md` (latest 0011 → next **0012**). Skills are
> `plugins/core/skills/<name>/SKILL.md`. Rules are `plugins/core/rules/global/` (the capture-nudge's
> "rules/global/" shorthand). The routing classification's single source is `memory/README.md` — the
> skill points there, it does not restate it.

---

## Task 1 — ADR 0012: record the two-lane self-edit decision

**Files:** create `decisions/0012-self-edit-gate-two-lane.md`. (Documentation; **direct-to-main lane**
applies — but since all of Phase 3 ships as one reviewed PR, it rides the branch like the rest.)

- [ ] **Step 1: Write the ADR** — match the house style of `decisions/0011-*` (title `# 0012 — …`,
  `Date:`/`Status: DECIDED by owner`, `## Context`, `## Decision`, `## Consequences`). Content:
  - Context: Phase 3 needs a governance gate; 0011 #9 is main-only; §7.8 wants "git pull-request review
    for self-edits." Owner re-decided D1 on 2026-06-27.
  - Decision: the two-lane model and the exact lane split table above. The gate is **preferred-not-
    mandatory**: judgment-bearing self-edits (rule-meaning change, fact supersede, rule add/remove) route
    via `self-edit-stage.sh`; mechanical self-edits commit direct to main. Humans always commit to main directly.
  - Consequences: Phase 4's worker routes via this gate; `learn-route` is the authored classifier;
    a future eval agent can later auto-approve low-risk staged PRs.
  - Note it supersedes nothing but **refines** 0011 #9 (adds the sanctioned self-edit exception).

- [ ] **Step 2: Commit**
```
git add decisions/0012-self-edit-gate-two-lane.md
git commit -m "docs: [meta] ADR 0012 — two-lane self-edit gate (D1 resolved)"
```

---

## Task 2 — `self-edit-stage.sh` + unit test

**Interface:** `self-edit-stage.sh <slug> <rationale>` — stages the **current working-tree changes**
(the already-made proposed edit) onto a review branch. Env overrides for testability:
`SELF_EDIT_DATE` (default `date -u +%F`), `SELF_EDIT_BASE` (default `main`), `SELF_EDIT_REMOTE` (default `origin`).

**Contract:**
- If the working tree has **no changes** → print error, exit 2 (nothing to stage).
- `slug` required (else exit 2). Branch name: `self-edit/${SELF_EDIT_DATE}-${slug}`.
- Record the original branch. `git checkout -b "$branch"` (uncommitted changes travel to the new branch),
  `git add -A`, `git commit` with subject `self-edit: <slug>` and body = `<rationale>`.
- **PR step (graceful):** if `$SELF_EDIT_REMOTE` exists AND `gh` is present → push + `gh pr create`;
  elif the remote exists → push + print the compare URL; else → print "local-only (no remote); PR step skipped".
  A failure here must NOT lose the commit (it is already on the branch).
- Always restore the original branch at the end (`git checkout "$orig"`), leaving its working tree clean.
- Exit 0 on success.

- [ ] **Step 1: Write the failing test** — `plugins/core/scripts/tests/test-self-edit-stage.sh`
```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/self-edit-stage.sh"
pass=0; fail=0
check(){ if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL: $3 (got '$1' want '$2')"; fail=$((fail+1)); fi; }

# throwaway repo fixture, no remote
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
git -C "$tmp" init -q -b main
git -C "$tmp" config user.email t@t; git -C "$tmp" config user.name t
echo "base" > "$tmp/fact.md"; git -C "$tmp" add -A; git -C "$tmp" commit -qm base
main_before="$(git -C "$tmp" rev-parse main)"

# make a proposed self-edit in the working tree, then stage it
echo "superseded value" > "$tmp/fact.md"
( cd "$tmp" && SELF_EDIT_DATE=2026-06-27 SELF_EDIT_REMOTE=nope bash "$SCRIPT" supersede-fact "correction: new value; source: owner; supersedes old" ) >/dev/null 2>&1
rc=$?
check "$rc" 0 "stager exits 0 with no remote"

# branch created with the expected name
git -C "$tmp" rev-parse --verify -q "self-edit/2026-06-27-supersede-fact" >/dev/null; check "$?" 0 "review branch created"

# the change is committed ON the branch, with the rationale in the message
body="$(git -C "$tmp" log -1 --format=%B "self-edit/2026-06-27-supersede-fact")"
check "$(printf '%s' "$body" | grep -c 'supersede-fact')" 1 "subject names the slug"
check "$(printf '%s' "$body" | grep -c 'correction: new value')" 1 "rationale in commit body"
branch_content="$(git -C "$tmp" show "self-edit/2026-06-27-supersede-fact:fact.md")"
check "$branch_content" "superseded value" "branch carries the proposed edit"

# main is UNTOUCHED (no new commit, original content)
check "$(git -C "$tmp" rev-parse main)" "$main_before" "main has no new commit"
check "$(git -C "$tmp" show main:fact.md)" "base" "main content unchanged"

# original branch restored, working tree clean
check "$(git -C "$tmp" rev-parse --abbrev-ref HEAD)" "main" "original branch restored"
check "$(git -C "$tmp" status --porcelain)" "" "working tree clean after staging"

# no-op guard: nothing to stage -> exit 2
( cd "$tmp" && bash "$SCRIPT" empty-slug "x" ) >/dev/null 2>&1; check "$?" 2 "no changes -> exit 2"

# missing slug -> exit 2
echo "y" > "$tmp/fact.md"
( cd "$tmp" && bash "$SCRIPT" ) >/dev/null 2>&1; check "$?" 2 "missing slug -> exit 2"

echo "pass=$pass fail=$fail"; [ "$fail" = 0 ]
```

- [ ] **Step 2: Run — verify it FAILS** (script does not exist).

- [ ] **Step 3: Write `plugins/core/scripts/self-edit-stage.sh`** to satisfy the contract. Key points:
  pure git; `git checkout -b` carries uncommitted changes; commit with `-m "self-edit: $slug" -m "$rationale"`;
  guard the no-change and missing-slug cases BEFORE creating the branch; use a `trap`/explicit restore so
  the original branch is restored even on the PR-step path; the remote/gh checks are existence-guarded.
  `chmod +x` the file.

- [ ] **Step 4: Run — verify the test PASSES** (all asserts green).

- [ ] **Step 5: Commit**
```
git add plugins/core/scripts/self-edit-stage.sh plugins/core/scripts/tests/test-self-edit-stage.sh
git commit -m "feat: [meta] self-edit-stage.sh — stage judgment-bearing self-edits as review PRs + test"
```

---

## Task 3 — `learn-route` skill (authored classifier) + CI wiring

- [ ] **Step 1: Write `plugins/core/skills/learn-route/SKILL.md`** — frontmatter `name: learn-route` +
  a `description:` that says when to invoke (after a correction/capture, to classify and route it). Body:
  - **Classify** (point to `memory/README.md` "on-correction", do NOT restate it): behavioral/how-to-work
    → sharpen the EXISTING rule in `plugins/core/rules/global/` (new file only if no home; never duplicate);
    durable fact → `memory/` supersede (source: correction; today's `updated:`); stale doc → fix the doc.
  - **Pick the lane** (point to ADR 0012): mechanical (typo/format/dead-link/regenerate) → commit direct
    to main; changes a rule's MEANING or supersedes a FACT, or adds/removes a rule → `self-edit-stage.sh
    <slug> "<rationale>"` (branch + PR).
  - **Act**: show the exact `self-edit-stage.sh` invocation for the judgment lane; note the human (or future
    eval agent) approves the PR. Cross-link `session-hygiene` (hookless surfaces run this by hand).
  - Match the house SKILL.md style (see `plugins/core/skills/session-hygiene/SKILL.md`): point to single
    sources, add only the execution notes that differ.

- [ ] **Step 2: Wire `freshness.yml`** — add after the stale-facts self-test step:
```yaml
      - name: Self-edit stager self-test
        run: bash plugins/core/scripts/tests/test-self-edit-stage.sh
```

- [ ] **Step 3: Verify** — run `bash plugins/core/scripts/tests/test-self-edit-stage.sh` green; confirm the
  skill renders (frontmatter parses) and its links resolve.

- [ ] **Step 4: Commit**
```
git add plugins/core/skills/learn-route/SKILL.md .github/workflows/freshness.yml
git commit -m "feat: [meta] learn-route skill (classify->lane) + run stager self-test in CI"
```

---

## Task 4 — Point the capture-nudge at the gate

- [ ] **Step 1: Edit `plugins/core/hooks/capture-nudge.sh`** — replace the line
  `Stage rule edits for review (the eval/promote gate is not built yet). If the lesson maps to an existing rule, the fix is adherence, not a new file.`
  with a pointer to the now-built gate, e.g.:
```
  Route via the learn-route skill: mechanical fixes (typo/format/regenerate) commit direct to main;
  a rule-meaning change or fact supersede goes through self-edit-stage.sh (branch + PR, ADR 0012).
  If the lesson maps to an existing rule, the fix is adherence, not a new file.
```
  Keep the hook deterministic, fast, always `exit 0` (UserPromptSubmit must never suppress the prompt).

- [ ] **Step 2: Verify** the hook still runs and exits 0 on a sample correction:
  `printf "you're wrong about that" | bash plugins/core/hooks/capture-nudge.sh; echo "exit=$?"` → prints the
  nudge with the new wording, `exit=0`.

- [ ] **Step 3: Commit + push**
```
git add plugins/core/hooks/capture-nudge.sh
git commit -m "feat: [meta] capture-nudge points corrections at the learn-route gate"
git push -u origin claude/schnapp-os-phase3-gate
```

---

## Done when
- An agent-proposed **fact supersede** (judgment lane) lands as a `self-edit/<date>-<slug>` branch + PR
  via `self-edit-stage.sh`, with main untouched until merge — proven by `test-self-edit-stage.sh`.
- A **mechanical** fix is documented (ADR 0012 + learn-route) as going direct to main.
- `learn-route` authored; `capture-nudge` points at it; CI runs the stager self-test.
- PR opened → `main`.

## Self-review
- **D1 fidelity:** two-lane, preferred-not-mandatory; the lane split is the owner's recommended line,
  recorded in ADR 0012 as the single source `learn-route` points to.
- **Safety:** the stager never touches main (commits only on the review branch, restores the original
  branch); the no-change/missing-slug guards prevent empty or mislabeled branches; the PR step degrades
  gracefully and never loses the commit.
- **Testability:** all git mechanics are unit-tested offline against a throwaway repo; the network PR
  call is intentionally out of the test surface.
- **DRY:** the routing classification stays in `memory/README.md`; the lane policy stays in ADR 0012;
  `learn-route` and `capture-nudge` point to them, never restate.
- **Out of scope (Phase 4):** the async worker that distills captures and *calls* this gate; the eval
  agent that scores staged PRs for auto-approval.
