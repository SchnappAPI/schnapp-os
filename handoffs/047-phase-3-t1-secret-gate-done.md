# Handoff 047 — Phase 3 T1 (malformed-secret byte-check gate) DONE + hardened; resume = Phase 3 T2-T4

**Date:** 2026-07-01. **Surface:** Claude Code on the Mac, Opus 4.8, subagent-driven.
**Status:** Streamline Phases 1, 2, 4 COMPLETE. **Phase 3 T1 done + adversarially hardened + shipped.**
T2-T4 remain (T2 is design-heavy: it rewires the autonomous self-editing loop).

## What Phase 3 T1 delivered (on `main`, CI green)
- **`scripts/check-secret-bytes.sh`** — a byte-check GATE for stored secrets. It validates a value's raw
  bytes WITHOUT ever printing the value, and fails CLOSED on: surrounding or embedded whitespace
  (including NBSP `0xC2A0` and U+2028/2029), wrapping OR single-sided quotes, truncation (`--min-len`),
  and prefix mismatch (`--expect-prefix`). Exit 1 = malformed, exit 2 = cannot-check (op absent / bad
  args), 0 = clean.
- **TDD, 33 assertions** including a value-leak guard, an inherited-`xtrace` leak regression, and a
  `--ref` path test with a throwaway fake `op` shim. CI self-test wired in `freshness.yml`.
- **`rotate-secret` SKILL** step 6 (Verify) now byte-checks the new ref.
- **Adversarial security review** caught and fixed a **Critical** (an inherited `SHELLOPTS=xtrace`
  traced the plaintext value to stderr) plus fail-open bypasses (non-numeric `--min-len`, NBSP
  whitespace, single-sided quotes, prefix-only value). All 5 attacks re-verified CLOSED by the
  controller before push. Commit `ec08400`.
- Gates the recurring malformed-secret class (spec §4.3, ADR 0019, [[malformed-stored-secret-401]]).

## Why the boundary is here (T1 shipped, T2-T4 handed off)
T2 modifies the AUTONOMOUS self-editing learning loop (`learning-worker`, which auto-commits to
`main`). It is Phase 3's design-heaviest and highest-stakes task and deserves fresh, careful design
attention rather than a tail-end build on a very long session. T1 (the byte-check gate) is a complete,
shippable increment: it IS "the recurring deterministic classes are gated", half of Phase 3's
deliverable. This is a quality boundary, not a blocker.

## Next: Phase 3 T2-T4 (all detailed to task level in the plan doc)
Read [the plan](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) Phase 3 +
[the spec](../docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md) §4.
- **T2 (design-heavy):** `learning-worker` counts error-class frequency over the capture archive; on
  >= 2 same-class, it DRAFTS a gate (a check, as a GitHub issue for owner approval) instead of another
  prose fact, and NEVER auto-lands the gate. Design the deterministic class signature + the archive
  count + the drafted-issue body. TDD with a seeded repeat class in dry-run (no real `gh`/network).
  Study `scripts/learning-worker.sh` + `scripts/learning_distill.py` + `scripts/learning-gate.sh` (the
  existing loop) first.
- **T3:** extend `last-verified` coverage (the mechanism already exists in `check-freshness.sh`) to
  deterministic docs whose accuracy tracks a checkable source (`credentials-map.md`,
  `connectors/*/README.md`, surface profiles). Prove a deliberately-stale fixture FAILS.
- **T4:** ADR `decisions/0026` (enforcement ladder + recurrence-escalation). Flip boxes; PROGRESS;
  final whole-branch review; handoff.

## Owner action outstanding (across the streamline; per-machine, low-risk; THIS Mac fully done)
On every OTHER machine: the Phase-2 flatten gate (handoff 045: `~/.claude/CLAUDE.md` rules/global
repoint, plugin uninstall, user-scope settings entries, plist re-render), the Phase-4 writing-style
`@import` line (handoff 046), and the vault `autoMemoryDirectory` one-liner.

## Follow-ups (NOT blocking)
- `ci-lint.yml` vestigial (runs `check-memory-frontmatter.sh memory` against a `memory/` dir Phase 1
  removed; 0 facts). `backup-archive.sh` `memory/` residue (cosmetic). (Phase 1) vault auto-commit;
  prune `~/code/obsidian-vault`.

## Operating flow (unchanged)
main-only, subagent-driven (`superpowers:subagent-driven-development`), commit + push each task from
the worktree (`git push origin HEAD:main`, rebase first), flip the plan-doc box + PROGRESS line in the
same push. Secrets are `op://` refs. Instruction files follow `rules/global/writing-style.md`. Live
status = [the plan doc](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) / [PROGRESS.md](../PROGRESS.md).
