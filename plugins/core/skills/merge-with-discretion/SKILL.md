---
name: merge-with-discretion
description: Use ONLY when a non-main branch exists (one created earlier with explicit owner approval) and it is time to decide whether and when to integrate it — e.g. the owner asks "is it time to merge?", "should this branch land?", "merge this when it's ready", or work on an approved branch is finishing. Judges readiness and timing, performs the merge, and explains the reasoning. Does nothing if the only branch is `main` (the default workflow) — there is nothing to merge.
---

# merge-with-discretion

The default workflow is **work on `main`, commit and push every change** (see
`plugins/core/rules/modules/lang/git.md` "Workflow"). Branches are rare and exist only with the
owner's explicit approval. This skill handles the uncommon moment when such a branch should be
integrated: it applies **discretion** (is it ready? is now the right time?), merges, and explains
why. The mechanics of finishing a branch are not restated here — defer to the git conventions and
the superpowers `finishing-a-development-branch` skill; this skill adds the judgment + explanation.

## 1. Precondition (check first)

- Confirm a branch other than `main` actually exists and is the one under discussion. If the only
  branch is `main`, **stop and say so**: nothing to merge; the default is work-on-main.
- Confirm the branch was created with explicit owner approval (per the git workflow). If it appears
  to have been created without approval, surface that before merging.

## 2. Readiness (don't merge on vibes)

Judge against evidence, not assumption (see
`plugins/core/rules/global/verify-before-asserting.md`):
- Work on the branch is complete (not mid-task), and scoped — no unrelated changes mixed in.
- Tests + build are green; CI passing if the repo runs it. State the actual result, not a guess.
- Reviewed (self-review at minimum; the superpowers `requesting-code-review` skill for anything
  substantial).
- Branch is pushed and not behind `main` (rebase/merge `main` in first if it is).

If any check fails, **do not merge** — report exactly what is blocking and stop.

## 3. Timing (the discretion)

Merge when it is green, reviewed, low-risk, and integrating now won't collide with other in-flight
work. Hold when a check is red, when it would land on top of unrelated unpushed work, or when the
owner wants to review first. When unsure whether the *timing* (not the readiness) is right, say what
you'd do and why, and let the owner confirm.

## 4. Merge + explain

- Integrate per the git conventions (fast-forward or `--no-ff` to `main`, push, delete the merged
  branch), or open a PR if review is wanted. Use the `finishing-a-development-branch` skill for the
  mechanics.
- Then **explain why**: the readiness evidence (tests/build/review state) and the timing rationale.
  Update `PROGRESS.md`/`decisions/` per keep-tracker-current.
