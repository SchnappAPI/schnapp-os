# Plan: portable shell (two live links, any repo, any surface)

Date: 2026-07-03. ADR: [0033](../../../decisions/0033-portable-shell-user-scope-wiring.md).
Resume point: handoffs/054. Success = Link A (schnapp-os -> every session, live read) and
Link B (every session <-> vault, round-trip) verified from a NON-schnapp-os repo.

- [x] T1 Verify capabilities (plugin snapshot semantics live-tested; user-scope hook reach
  live-tested; web scope semantics from docs) + write ADR 0033 + this plan.
- [x] T2 Build wiring: `hooks/global-session-gate.sh` (any-repo ff-only pull of both repos,
  offline-tolerant, skips inside schnapp-os, one-line injected status),
  `hooks/global-vault-push.sh` (SessionEnd: vault commit+push when dirty, vault only),
  plus `hooks/global-secret-scan.sh` + `hooks/global-force-push-guard.sh` (user-scope
  delivery wrappers for the two guards, self-skip inside schnapp-os), self-tests under
  `scripts/tests/`. Verify: 3 new tests (10+8+21 checks) + full suite green, shellcheck clean.
- [x] T3 Build shell: `shell/install.sh` (idempotent: renders `~/.claude/CLAUDE.md` from
  template, merges user-scope settings keys incl. hooks + `autoMemoryDirectory`, symlinks
  skills/agents/commands, prunes dead links, prints verify summary), `shell/web-setup.sh`
  (clone both repos + run installer in container), `shell/README.md` (pointer-style).
  Verify: dry-run mode output correct; installer re-run is a no-op second time.
- [x] T4 Install on this Mac + sweep the ripple: installer run live (5 hook events wired, 33
  components linked, CLAUDE.md rendered w/ 9 imports); stale `schnapp-os` marketplace
  registration + `~/.claude/plugins/cache/schnapp-os` remnants deleted (0024 leftover);
  `.claude/settings.json` `$comment`, `hooks/README.md`, root `CLAUDE.md` hooks bullet,
  `templates/README.md` + template header, `docs/memory-lane.md` (global vault push), root
  README map + install steps all updated; CATALOG regenerated. Verify: check-freshness,
  check-links (375), check-writing-style green.
- [~] T5 Live-verify both links from a non-schnapp-os repo. DONE on Mac: foreign-repo session
  advanced both clones' FETCH_HEAD (gate fired + pulled); vault fact `portable-shell-live`
  auto-committed AND pushed to GitHub by the foreign session's SessionEnd hook (round-trip
  verified, origin == local); all 9 rule imports + 33 symlinks resolve into the live clone.
  Duplicate-skill question RESOLVED (056 red-team session, an interactive schnapp-os session
  with both scopes live): the harness dedupes same-name skills across project + user scope -
  the skill list shows each schnapp-os skill exactly once. No action needed.
  REMAINS (owner leg, handoff 056 §Open): web env-setup paste + first-web-session check of
  user-scope honoring.
- [x] T6 Red-team pass (/critique-os, handoff 056). Live-verified findings -> fixed same
  session: gate pulls parallelized (4.4s -> 2.7s measured) + matcher widened to
  startup|resume|clear (installer migrates old wiring in place); gate now surfaces a stuck
  vault (dirty/unpushed backlog - SessionEnd failures were invisible) and AUTO-HEALS wiring
  drift by running the idempotent installer; vault-autocommit concurrent-run race reclassified
  as benign (index.lock loser was misreported as "pre-commit gate?", exit 2 -> now exit 0,
  race-tested); NEW guard leg: secret-scan wrapper at PreToolUse Bash scans command TEXT
  (heredoc/echo writes bypassed all Write/Edit hooks) with a --block-re fast path from the
  canonical registry (no-hit cost ~0.1s); vault pre-commit now runs the secret scan on staged
  files (the lane pushed to GitHub with ZERO value scanning) and the installer sets vault
  core.hooksPath (fresh clones committed UNGATED); installer settings write made atomic;
  subtracted: dead hooks/hooks.json tombstone, 2 orphan local worktrees + 2 empty remote
  claude/* branches; docs: env-var values-not-references exception documented in
  environment-and-access.md §1. Tests: +test-global-secret-scan (18), gate 14, autocommit 17,
  install 27; full shell suite + shellcheck green; installer re-run live on this Mac.
