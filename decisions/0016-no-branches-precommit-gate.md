# 0016 — No branches: everything to main; autonomous self-edits via a pre-commit gate

Date: 2026-06-27. Status: DECIDED by owner.

## Context
The build used short-lived feature branches + PRs (for CI + a review surface), and the learning
loop's self-edit gate (ADR 0012/0013) routed agent rule/fact changes through `self-edit/*` branches +
PRs vetted by `self-edit-gate.yml`. The owner re-decided: **"no branches and everything be committed
to main."** This makes 0011 #9 (main-only) absolute and refines 0012/0013 (which had made self-edits
the sanctioned branch exception) and 0015 (standing authority + the self-edit carve-out).

## Decision
1. **No branches.** All work — directed and agent — commits straight to `main`; no feature branches,
   no PRs. Run tests + a local review pass before pushing; CI runs on the push to main.
2. **Autonomous self-edits use a PRE-COMMIT gate, not branch+PR.** The nightly `learning-worker.sh`
   has `claude -p` (Read/Edit/Write only — **no Bash, no git**) WRITE a proposed rule/fact edit to the
   working tree. The worker then runs `learning-gate.sh` on the diff:
   - **APPROVE** (in-scope `.md` under rules/memory, small, `updated:` bumped, non-duplicate,
     non-symlink, non-binary) → commit and **push to `main`** directly.
   - **HOLD** → discard the working-tree change (nothing reaches main) and open a GitHub **issue** with
     the proposed diff + the gate's reasons, for human review. Issues are not branches.
3. **Retired** (deleted, per anti-stale "remove the old"): `self-edit-stage.sh`,
   `.github/workflows/self-edit-gate.yml`, and `tests/test-self-edit-stage.sh`. `learning-gate.sh` is
   **kept** — it is the vet, now run pre-commit by the worker instead of on a PR.

## Why this is safe without branches
- The same conservative gate decides what lands — only now BEFORE the commit, not on a PR. The gate
  is hardened against scope / symlink / non-`.md` / provenance-spoof / binary / duplicate bypasses
  (20/20 tests). Junk never reaches main; held proposals surface as issues, not silent drops.
- `claude -p` gets Read/Edit/Write only (no Bash), so the headless session can edit `.md` files but
  cannot run git or arbitrary commands; the worker performs all git.
- Held captures are still archived (never lost) and recorded as a review issue.

## Consequences
- Branch sprawl + merge friction are gone; the nightly loop lands clean rules autonomously and routes
  anything questionable to a review issue.
- Trade-off vs the PR gate: a held proposal is an issue (no inline-diff review UI, no CI on the
  proposal itself). Accepted per the owner's no-branches preference.
- Live policy; 0012/0013/0015 remain as the rationale record they refine. In-session corrections:
  edit the rule/fact + commit straight to main (the owner is the real-time reviewer).
